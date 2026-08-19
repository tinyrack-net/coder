local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

local tool_card = tinest.ui.contribution({
  id = "tool",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  return tinest.ui.tool_document(arguments)
end)

local function append(target, value)
  target[#target + 1] = value
end

local function code_tools(exec_definition, wait_definition)
  local result = {}
  local descriptors = tinest.tools.list()
  local exec_descriptor = tinest.tools.resolve(exec_definition, descriptors)
  local wait_descriptor = tinest.tools.resolve(wait_definition, descriptors)
  for _, descriptor in ipairs({exec_descriptor, wait_descriptor}) do
    if descriptor ~= nil and
        (descriptor.exposure ~= tinest.tool.exposure.deferred or
          descriptor.surfaced == true) then
      append(result, descriptor)
    end
  end
  return result
end

local function prompt_blocks(arguments)
  local result = {
    {
      role = tinest.model.role.system,
      content = tinest.assets.read("prompts/default.md"),
    },
  }
  if type(arguments.project_document) == "string" and
      arguments.project_document ~= "" then
    append(result, {
      role = tinest.model.role.developer,
      content = arguments.project_document,
    })
  end
  for _, extension in ipairs(arguments.extensions or {}) do
    if type(extension) == "table" and type(extension.prompt) == "string" then
      append(result, {
        role = tinest.model.role.developer,
        content = extension.prompt,
      })
    end
  end
  if type(arguments.agent_prompt) == "string" and
      arguments.agent_prompt ~= "" then
    append(result, {
      role = tinest.model.role.developer,
      content = arguments.agent_prompt,
    })
  end
  return result
end

local function run(arguments, exec_definition, wait_definition)
  local history = arguments.history or {}
  if arguments.internal ~= true then
    append(history, {
      type = "user",
      text = arguments.prompt or "",
      attachments = arguments.attachments or {},
    })
  end
  local descriptors = code_tools(exec_definition, wait_definition)
  local by_name = {}
  for _, descriptor in ipairs(descriptors) do by_name[descriptor.name] = descriptor end
  local rounds = 0
  while true do
    local stream = tinest.model.open({
      blocks = prompt_blocks(arguments),
      history = history,
      tools = descriptors,
    })
    local assistant = nil
    local calls = {}
    while true do
      local next_event = tinest.model.next(stream)
      if next_event.done then break end
      local event = next_event.value
      if event.type == "tool_call" then append(calls, event) end
      if event.type == "completion" then assistant = event.assistant end
    end
    tinest.model.close(stream)
    if assistant == nil then error("model stream ended without completion") end
    append(history, assistant)
    if #calls == 0 then return {tool_rounds = rounds} end
    rounds = rounds + 1
    for _, call in ipairs(calls) do
      local descriptor = by_name[call.name]
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
      append(history, {
        type = "toolResult",
        callId = call.call_id,
        output = tostring(result.output or ""),
        toolKind = tinest.tool.kind.function_,
        isError = result.is_error == true,
        content = result.content or {},
        structuredContent = result.structured_content,
        meta = result._meta or {},
      })
    end
  end
end

local function exec(arguments, exec_definition, wait_definition)
  local nested = {}
  for _, descriptor in ipairs(tinest.tools.list()) do
    if not tinest.tools.is_selected(descriptor.ref, exec_definition) and
        not tinest.tools.is_selected(descriptor.ref, wait_definition) then
      append(nested, descriptor.ref)
    end
  end
  return tinest.result.unwrap(tinest.host.lua.start({
    source = arguments.source or "",
    tools = nested,
  }))
end

local function wait(arguments)
  if arguments.terminate == true then
    return tinest.result.unwrap(
      tinest.host.lua.terminate({handle = arguments.cell_id})
    )
  end
  return tinest.result.unwrap(tinest.host.lua.read({
    handle = arguments.cell_id,
    yield_time_ms = arguments.yield_time_ms,
  }))
end

local exec_tool
local wait_tool

exec_tool = tinest.tool.function_({
  id = "exec",
  name = "exec",
  description = "Run sandboxed Lua to orchestrate the selected nested tools.",
  uses = {tinest.host.lua.start},
  effects = {tinest.effect.process.command},
  required_capabilities = {
    tinest.capability.process.execute,
    tinest.capability.tools.list,
    tinest.capability.tools.invoke,
  },
  presentation = {
    ui = tool_card,
    group = "execution",
    glyph = "run",
    label = "Run Lua",
    nested = false,
  },
}, S.object(T.ExecInput, {source = S.string()}), nil, function(arguments)
  return exec(arguments, exec_tool, wait_tool)
end)

wait_tool = tinest.tool.function_({
  id = "wait",
  name = "wait",
  description = "Wait for or terminate a running Lua cell.",
  uses = {tinest.host.lua.read, tinest.host.lua.terminate},
  effects = {tinest.effect.process.command},
  required_capabilities = {tinest.capability.process.execute},
  presentation = {
    ui = tool_card,
    group = "execution",
    glyph = "run",
    label = "Wait for Lua",
    nested = false,
  },
}, S.object(T.WaitInput, {
  cell_id = S.string(),
  yield_time_ms = S.optional(S.integer()),
  max_tokens = S.optional(S.integer()),
  terminate = S.optional(S.boolean()),
}), nil, wait)

local driver = tinest.driver.define({
  id = "driver",
  required_capabilities = {
    tinest.capability.model.call,
    tinest.capability.tools.list,
    tinest.capability.tools.invoke,
  },
  required_model_capabilities = {
    tinest.model.capability.streaming,
    tinest.model.capability.role.system,
    tinest.model.capability.role.developer,
  },
  metadata = {
    name = "Lua code driver",
    supports_native_tools = true,
    supports_text_tools = false,
    supports_multiple_model_requests = true,
  },
}, function(arguments)
  return run(arguments, exec_tool, wait_tool)
end)

return tinest.plugin.define({
  driver = driver,
  tools = {exec_tool, wait_tool},
  ui = {tool_card},
})
