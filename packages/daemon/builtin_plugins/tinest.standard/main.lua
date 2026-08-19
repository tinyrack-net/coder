local tinest = require("tinest")
local S = tinest.schema

local driver_context = tinest.state.cell({
  scope = tinest.state.scope.session,
  key = "driver_context",
}, S.any())

local function append(target, value)
  target[#target + 1] = value
end

local function copy(items)
  local result = {}
  for _, item in ipairs(items or {}) do append(result, item) end
  return result
end

local function prompt_blocks(arguments)
  local result = {
    {
      role = tinest.model.role.system,
      content = tinest.assets.read("prompts/default.md"),
    },
  }
  local extension_data = arguments.extension_data or {}
  local host_policy = extension_data.host_policy
  if type(host_policy) == "table" and
      type(host_policy.permission_mode) == "string" then
    local mode = host_policy.permission_mode
    if mode == "readOnly" or mode == "ask" or
        mode == "workspaceWrite" or mode == "fullAccess" then
      local policy = tinest.assets.read("prompts/permissions/" .. mode .. ".md")
      policy = policy:gsub(
        "{{workspace_root}}",
        tostring(host_policy.workspace_root or "")
      )
      append(result, {role = tinest.model.role.system, content = policy})
    end
  end
  if type(arguments.project_document) == "string" and
      arguments.project_document ~= "" then
    append(result, {
      role = tinest.model.role.system,
      content = arguments.project_document,
    })
  end
  for _, extension in ipairs(arguments.extensions or {}) do
    if type(extension) == "table" and type(extension.prompt) == "string" then
      append(result, {
        role = tinest.model.role.system,
        content = extension.prompt,
      })
    end
  end
  if type(arguments.agent_prompt) == "string" and
      arguments.agent_prompt ~= "" then
    append(result, {
      role = tinest.model.role.system,
      content = arguments.agent_prompt,
    })
  end
  return result
end

local function read_driver_context(fallback)
  local entry = driver_context:read()
  if entry.found and type(entry.value) == "table" and
      type(entry.value.history) == "table" then
    return entry, copy(entry.value.history)
  end
  return entry, copy(fallback)
end

local function save_driver_context(entry, history, usage, reason)
  local expected_revision = 0
  if type(entry) == "table" and type(entry.revision) == "number" then
    expected_revision = entry.revision
  end
  return driver_context:compare_and_set(
    expected_revision,
    {
      history = history,
      usage = usage or {},
      reason = reason,
    }
  )
end

local function model_response(request)
  local stream = tinest.model.open(request)
  local assistant = nil
  local calls = {}
  local usage = {}
  local failure = nil
  while true do
    local next_event = tinest.model.next(stream)
    if next_event.done then break end
    local event = next_event.value
    if type(event) == "table" then
      if event.type == "tool_call" then append(calls, event) end
      if event.type == "usage" then usage = event end
      if event.type == "completion" then
        assistant = event.assistant
        usage = event.usage or usage
      end
      if event.type == "error" then failure = event end
    end
  end
  tinest.model.close(stream)
  return assistant, calls, usage, failure
end

local function trim_front_safely(history)
  if #history == 0 then return false end
  table.remove(history, 1)
  while #history > 0 and history[1].type == "toolResult" do
    table.remove(history, 1)
  end
  return true
end

local function compaction_instructions(instructions)
  local suffix = type(instructions) == "string" and instructions or ""
  return [[
Summarize the conversation for a replacement model context. Preserve active
requirements, decisions, unfinished work, concrete paths, commands, failures,
and next steps. Return only the handoff summary. Do not invoke any tool.]] ..
    (suffix ~= "" and "\n\nAdditional instructions: " .. suffix or "")
end

local function compact_history(history, instructions)
  local summary_history = copy(history)
  while true do
    local assistant, _, _, failure = model_response({
      blocks = {{
        role = tinest.model.role.system,
        content = compaction_instructions(instructions),
      }},
      history = summary_history,
      tools = {},
      persist_completion = false,
    })
    if failure == nil then
      local summary = type(assistant) == "table" and assistant.text or ""
      if type(summary) ~= "string" or summary == "" then
        summary = "(no summary available)"
      end
      return {
        {type = "user", text = "Context summary:\n" .. summary},
      }
    end
    if failure.code ~= "context_overflow" or
        not trim_front_safely(summary_history) then
      error(failure.message or "context compaction failed")
    end
  end
end

local function should_auto_compact(arguments, usage)
  local context = type(arguments.context) == "table" and arguments.context or {}
  local window = tonumber(context.window_tokens)
  local used = type(usage) == "table" and
    tonumber(usage.totalTokens) or nil
  if used == nil or used <= 0 then
    used = (tonumber(usage.inputTokens) or 0) +
      (tonumber(usage.outputTokens) or 0)
  end
  return window ~= nil and window > 0 and used >= window * 0.9
end

local function action_from(result)
  if type(result) ~= "table" then return nil end
  local action = type(result._meta) == "table" and
    result._meta.driver_action or nil
  if action == nil and type(result.value) == "table" then
    local nested = result.value
    action = type(nested._meta) == "table" and
      nested._meta.driver_action or nil
    if action == nil and type(nested.structured_content) == "table" then
      action = nested.structured_content.driver_action
    end
  end
  if action == nil and type(result.structured_content) == "table" then
    action = result.structured_content.driver_action
  end
  return type(action) == "table" and action or nil
end

local function run(arguments)
  local context_entry, history = read_driver_context(arguments.history or {})
  for _, item in ipairs(arguments.turn_inputs or {}) do
    append(history, item)
  end
  if arguments.internal ~= true then
    append(history, {
      type = "user",
      text = arguments.prompt or "",
      attachments = arguments.attachments or {},
    })
  end
  local rounds = 0
  local overflow_retried = false
  while true do
    local selected_descriptors = tinest.tools.list()
    local tool_descriptors = {}
    local tools_by_name = {}
    for _, descriptor in ipairs(selected_descriptors) do
      if descriptor.exposure ~= tinest.tool.exposure.deferred or
          descriptor.surfaced == true then
        append(tool_descriptors, descriptor)
        tools_by_name[descriptor.name] = descriptor
      end
    end
    local assistant, calls, usage, failure = model_response({
      blocks = prompt_blocks(arguments),
      history = history,
      tools = tool_descriptors,
    })
    if failure ~= nil then
      if failure.code ~= "context_overflow" or overflow_retried then
        error(failure.message or "model request failed")
      end
      overflow_retried = true
      history = compact_history(history, "Recover from provider context overflow.")
      context_entry = save_driver_context(
        context_entry, history, {}, "overflow_compaction"
      )
    else
      if type(assistant) ~= "table" then
        error("model stream ended without completion")
      end
      append(history, assistant)
      if #calls == 0 then
        local reason = "completion"
        if should_auto_compact(arguments, usage) then
          history = compact_history(
            history,
            "The model context reached the driver's compaction threshold."
          )
          reason = "automatic_compaction"
        end
        context_entry = save_driver_context(
          context_entry, history, usage, reason
        )
        return {tool_rounds = rounds}
      end

      rounds = rounds + 1
      local round_history = {assistant}
      local requested_action = nil
      for _, call in ipairs(calls) do
        local descriptor = tools_by_name[call.name]
        local tool_ref = call.tool_ref or (descriptor and descriptor.ref)
        local result
        if descriptor == nil or tool_ref == nil then
          result = {output = "Unknown tool: " .. tostring(call.name), is_error = true}
        else
          local ok, value = pcall(
            tinest.tools.invoke,
            tool_ref,
            tinest.tools.model_input(call, descriptor),
            {call_id = call.call_id}
          )
          result = ok and value or {output = tostring(value), is_error = true}
        end
        local tool_result = {
          type = "toolResult",
          callId = call.call_id,
          output = tostring(result.output or ""),
          toolKind = tinest.tool.kind.function_,
          isError = result.is_error == true,
          structuredContent = result.structured_content,
          content = result.content,
          meta = result._meta,
        }
        append(history, tool_result)
        append(round_history, tool_result)
        if type(result.context_images) == "table" and
            #result.context_images > 0 then
          local image_context = {
            type = "user",
            text = "",
            attachments = result.context_images,
          }
          append(history, image_context)
          append(round_history, image_context)
        end
        requested_action = requested_action or action_from(result)
      end

      if requested_action ~= nil and
          requested_action.action == "new_context" then
        history = round_history
        context_entry = save_driver_context(
          context_entry, history, usage, "new_context"
        )
      elseif requested_action ~= nil and
          requested_action.action == "compact_context" then
        history = compact_history(history, requested_action.instructions)
        context_entry = save_driver_context(
          context_entry, history, usage, "explicit_compaction"
        )
      else
        context_entry = save_driver_context(context_entry, history, usage, "tool_round")
      end
    end
  end
end

local driver = tinest.driver.define({
  id = "driver",
  required_capabilities = {
    tinest.capability.model.call,
    tinest.capability.tools.list,
    tinest.capability.tools.invoke,
    tinest.capability.state.read,
    tinest.capability.state.write,
  },
  required_model_capabilities = {
    tinest.model.capability.streaming,
  },
  metadata = {
    name = "Standard driver",
    supports_native_tools = true,
    supports_text_tools = true,
    supports_multiple_model_requests = true,
    owns_context = true,
  },
}, run)

return tinest.plugin.define({driver = driver})
