---@diagnostic disable: unused-local

local tinest = require("tinest")
local sandbox_global_completion = requ
local S = tinest.schema
local T = require("tinest.types")
local json_value = tinest.json.null
local json_value_is_null = tinest.json.is_null(json_value)
local magic_json_null = NULL

local Status, status = S.literal_enum(T.Status, {
  active = "active",
  completed = "completed",
})

local Input = S.object(T.Input, {
  profile = S.object({
    name = S.string(),
    line = S.optional(S.integer({minimum = 1})),
  }),
  tags = S.array(S.string()),
  labels = S.map(S.string()),
  status = Status,
})

local Output = S.object(T.Output, {
  text = S.string(),
  truncated = S.boolean(),
})

local TemplatePayload = S.object(T.TemplatePayload, {
  server = S.string(),
})

local read_file = tinest.tool.function_(
  {
    id = "read_file",
    description = "Read bounded UTF-8 text.",
    uses = {tinest.host.workspace.read_text},
  },
  Input,
  Output,
  function(args, context)
    local profile_name = args.profile.name
    local maybe_line = args.profile.line
    local first_tag = args.tags[1]
    local primary_label = args.labels.primary
    local is_completed = args.status == status.completed
    local result = tinest.host.workspace.read_text(
      {path = profile_name, offset = maybe_line, limit = 20}
    )
    return {text = profile_name, truncated = false}
  end
)

local state_cell = tinest.state.cell(
  {scope = tinest.state.scope.session, key = "typed"},
  Input
)

local existing = state_cell:read()
local transaction_revision = 0
if existing.found then
  local persisted_name = existing.value.profile.name
  transaction_revision = existing.revision
end
local transaction_result = state_cell:transaction({{
  key = "typed",
  expected_revision = transaction_revision,
  value = {
    profile = {name = "Ada"},
    tags = {"typed"},
    labels = {primary = "state"},
    status = status.completed,
  },
}})
if transaction_result.typed.found then
  local transaction_name = transaction_result.typed.value.profile.name
end

local card = tinest.ui.contribution(
  {id = "card", slot = tinest.ui.slot.timeline},
  Input,
  function(value)
    local name = value.profile.name
    return tinest.ui.text({text = name})
  end
)

local spec_scheduled = tinest.scheduler.handler(
  {
    id = "resume",
    required_capabilities = {tinest.capability.scheduler.manage},
    metadata = {label = "Resume"},
  },
  Input,
  function(payload)
    local name = payload.profile.name
    local missing = payload.missing_scheduled_field
    return state_cell:compare_and_set(0, payload)
  end
)

local ActionPayload = S.object(T.ActionPayload, {
  item_id = S.string(),
})

local spec_action = tinest.ui.action({
  id = "typed-action",
  required_capabilities = {tinest.capability.ui.publish},
  metadata = {label = "Typed action"},
}, ActionPayload, function(data)
  local item_id = data.item_id
  return item_id
end)

local valid_button = tinest.ui.button({
  label = "Open",
  action = spec_action,
  data = {item_id = "item-1"},
})
local spec_ui = tinest.ui.contribution({
  id = "typed-card",
  slot = tinest.ui.slot.timeline,
  required_capabilities = {tinest.capability.ui.publish},
  metadata = {snapshot = true},
}, ActionPayload, function(data)
  return tinest.ui.section({children = {
    tinest.ui.text({text = data.item_id}),
    valid_button,
  }})
end)

local spec_tool = tinest.tool.function_({
  id = "spec-tool",
  name = "spec_tool",
  description = "Exercise ToolSpec completion.",
  uses = {tinest.host.workspace.read_text},
  effects = {tinest.effect.filesystem.read},
  required_capabilities = {tinest.capability.workspace.read},
  presentation = {ui = spec_ui},
}, Input, Output, function(args)
  return {text = args.profile.name, truncated = false}
end)

local spec_driver = tinest.driver.define({
  id = "spec-driver",
  required_capabilities = {tinest.capability.model.call},
  required_model_capabilities = {tinest.model.capability.streaming},
  metadata = {name = "Spec driver"},
}, function(_arguments)
  return {tool_rounds = 0}
end)

local attach_hook = tinest.hook.agent_attach({
  id = "attach",
  required_capabilities = {tinest.capability.state.read},
  metadata = {label = "Attach"},
}, function(attach_context)
  local attach_agent_id = attach_context.agent_id
  local attach_lifecycle = attach_context.lifecycle
  local attach_session_id = attach_context.payload.session_id
  local attach_missing = attach_context.missing_attach
  return {agent_id = attach_agent_id}
end)

local before_turn_hook = tinest.hook.before_turn({
  id = "typed-before-turn",
  metadata = {ordered_data = "typed"},
}, function(before_context)
  local before_turn_id = before_context.turn_id
  local before_prompt = before_context.prompt
  local before_internal = before_context.internal
  local before_settings = before_context.settings
  local before_missing = before_context.missing_before_turn
  return {prompt = before_prompt, turn_id = before_turn_id}
end)

local after_model_hook = tinest.hook.after_model({
  id = "typed-after-model",
}, function(after_model_context)
  local after_model_input_tokens = after_model_context.usage.inputTokens
  local after_model_elapsed = after_model_context.elapsed_seconds
  local after_model_blocks = after_model_context.payload.blocks
  local after_model_missing = after_model_context.missing_after_model
  return {tokens = after_model_input_tokens, elapsed = after_model_elapsed}
end)

local after_tool_hook = tinest.hook.after_tool({
  id = "typed-after-tool",
}, function(after_tool_context)
  local after_tool_call_id = after_tool_context.call_id
  local after_tool_error = after_tool_context.is_error
  local after_tool_missing = after_tool_context.missing_after_tool
  return {call_id = after_tool_call_id, is_error = after_tool_error}
end)

local after_turn_hook = tinest.hook.after_turn({
  id = "typed-after-turn",
}, function(after_turn_context)
  local after_turn_id = after_turn_context.turn_id
  local after_turn_rounds = after_turn_context.tool_rounds
  local after_turn_missing = after_turn_context.missing_after_turn
  return {turn_id = after_turn_id, tool_rounds = after_turn_rounds}
end)

local ui_action_hook = tinest.hook.ui_action({
  id = "typed-ui-action",
}, function(ui_action_context)
  local ui_action_id = ui_action_context.action.actionId
  local ui_document_slot = ui_action_context.document.slot
  local ui_action_settings = ui_action_context.settings
  local ui_action_missing = ui_action_context.missing_ui_action
  return {action_id = ui_action_id, slot = ui_document_slot}
end)

local ControlValue = S.object(T.ControlValue, {
  enabled = S.boolean(),
})

local spec_control = tinest.session.control({
  id = "typed-control",
  required_capabilities = {tinest.capability.state.write},
  metadata = {label = "Typed control", default = {enabled = false}},
}, ControlValue, function(control_context)
  local proposed_enabled = control_context.value.enabled
  local current_enabled = control_context.current_value.enabled
  local control_settings = control_context.settings
  local control_missing = control_context.missing_session_control
  return {enabled = proposed_enabled and not current_enabled}
end)

local bad_return = tinest.tool.function_(
  {id = "bad_return"},
  Input,
  Output,
  function(args)
    return {text = 42, truncated = "no"}
  end
)

local template = tinest.tool.template(
  {id = "remote"},
  TemplatePayload,
  Input,
  Output,
  function(args, payload, context)
    local name = args.profile.name
    local server = payload.server
    return {text = server .. ":" .. name, truncated = false}
  end
)

local dynamic = tinest.tool.dynamic(
  {id = "ephemeral"},
  Input,
  Output,
  function(args, context)
    local name = args.profile.name
    return {text = name, truncated = false}
  end
)

local from_template = tinest.tool.dynamic_from(
  template,
  {id = "from_template", name = "from_template"},
  {server = "mcp"}
)

local function dynamic_surface()
  tinest.tools.surface({dynamic, from_template})
  return tinest.tools.invoke(dynamic, {
    profile = {name = "file"},
    tags = {},
    labels = {},
    status = "active",
  })
end

local ToolSnapshot = S.object(T.ToolSnapshot, {
  output = S.string(),
})

local tool_card = tinest.ui.contribution(
  {id = "tool_card", slot = tinest.ui.slot.timeline},
  ToolSnapshot,
  function(snapshot)
    local output = snapshot.output
    return tinest.ui.code({code = output, wrap = true})
  end
)

local function inspect_model(tool_descriptor)
  local stream = tinest.model.open(
    {
      blocks = {{role = tinest.model.role.developer, content = "Be concise."}},
      history = {},
      tools = {tool_descriptor},
    }
  )
  local next_event = tinest.model.next(stream)
  if not next_event.done and next_event.value then
    local event = next_event.value
    if event.type == "text" then
      local delta = event.delta
    elseif event.type == "usage" then
      local input_tokens = event.inputTokens
    elseif event.type == "tool_call" then
      local selected_ref = event.tool_ref
    end
  end
  tinest.model.close(stream)
end

local invalid_ui = tinest.ui.text({text = 42})
local incomplete_code = tinest.ui.code({})
local invalid_model = tinest.model.open({
  blocks = {{role = tinest.model.role.user, content = 42}},
  history = {},
  tools = {},
})

local bad_host_argument = tinest.host.workspace.read_text({path = 42})
local missing_status = status.missing
local bad_process = tinest.host.process.start({command = 42})
local bad_attachment = tinest.host.attachment.publish({path = 42})
local bad_interaction = tinest.host.interaction.request_user_input({questions = "bad"})
local bad_clock = tinest.host.clock.sleep({duration_ms = "bad"})
local bad_skill = tinest.host.skills.read({name = 42})
local bad_mcp = tinest.host.mcp.read_resource({server = 42, uri = "uri"})
local bad_collaboration = tinest.host.collaboration.send_message({
  target = 42,
  message = "hello",
})
local bad_lua = tinest.host.lua.start({source = 42})
local bad_network = tinest.host.network.request({url = 42})
local bad_secret = tinest.host.secret.get({name = 42})

local function inspect_host_outputs()
  local stat = tinest.result.unwrap(tinest.host.workspace.stat({path = "."}))
  local entity_type = stat.type
  local listing = tinest.result.unwrap(tinest.host.workspace.list({path = "."}))
  local listed_name = listing.entries[1].name
  local blob = tinest.result.unwrap(tinest.host.workspace.read_blob({path = "image.png"}))
  local blob_mime = blob.mime_type
  local walked = tinest.result.unwrap(tinest.host.workspace.walk({path = "."}))
  local walk_truncated = walked.truncated
  local transaction = tinest.result.unwrap(tinest.host.workspace.transaction({
    operations = {{kind = "write", path = "out.txt", content = "ok"}},
  }))
  local applied_kind = transaction.applied[1].kind

  local process = tinest.result.unwrap(tinest.host.process.start({command = "run"}))
  local process_handle = process.handle
  local chunk = tinest.result.unwrap(tinest.host.process.read({handle = process_handle}))
  local wall_time = chunk.wall_time_ms
  local written = tinest.result.unwrap(tinest.host.process.write({
    handle = process_handle,
    chars = "input",
  })).written
  local interrupted = tinest.result.unwrap(
    tinest.host.process.interrupt({handle = process_handle})
  ).interrupted
  local terminated = tinest.result.unwrap(
    tinest.host.process.terminate({handle = process_handle})
  ).terminated

  local attachment = tinest.result.unwrap(
    tinest.host.attachment.publish({path = "out.txt"})
  )
  local attachment_mime = attachment.mime_type
  local interaction = tinest.result.unwrap(
    tinest.host.interaction.request_user_input({questions = {{
      id = "format",
      header = "Format",
      question = "Which format?",
      options = {{label = "Text", description = "Plain text"}},
    }}})
  )
  local answer_text = interaction.answers[1].answer
  local clock = tinest.result.unwrap(tinest.host.clock.current_time({}))
  local utc = clock.utc
  local slept = tinest.result.unwrap(tinest.host.clock.sleep({duration_ms = 1}))
  local sleep_outcome = slept.outcome

  local skills = tinest.result.unwrap(tinest.host.skills.list({}))
  local skill_name = skills.skills[1].name
  local skill = tinest.result.unwrap(tinest.host.skills.read({name = skill_name}))
  local read_skill_name = skill.name

  local resources = tinest.result.unwrap(tinest.host.mcp.list_resources({}))
  local resource_uri = resources.resources[1].uri
  local templates = tinest.result.unwrap(
    tinest.host.mcp.list_resource_templates({})
  )
  local template_uri = templates.resourceTemplates[1].uriTemplate
  local resource = tinest.result.unwrap(
    tinest.host.mcp.read_resource({server = "docs", uri = resource_uri})
  )
  local content_uri = resource.contents[1].uri
  local catalog = tinest.result.unwrap(tinest.host.mcp.catalog_tools({}))
  local remote_tool_name = catalog.tools[1].name
  local invoked = tinest.result.unwrap(tinest.host.mcp.invoke_tool({
    server = "docs",
    name = remote_tool_name,
    arguments = {},
  }))
  local remote_error = invoked.isError

  local spawned = tinest.result.unwrap(tinest.host.collaboration.spawn_agent({
    task_name = "reader",
    message = "Read it",
  }))
  local task_name = spawned.task_name
  local queued = tinest.result.unwrap(tinest.host.collaboration.send_message({
    target = task_name,
    message = "Continue",
  })).queued
  local delivery = tinest.result.unwrap(tinest.host.collaboration.followup_task({
    target = task_name,
    message = "Finish",
  })).delivery
  local waited = tinest.result.unwrap(tinest.host.collaboration.wait_agent({}))
  local wait_outcome = waited.outcome
  local previous_status = tinest.result.unwrap(
    tinest.host.collaboration.interrupt_agent({target = task_name})
  ).previous_status
  local agents = tinest.result.unwrap(tinest.host.collaboration.list_agents({}))
  local agent_status = agents.agents[1].agent_status

  local lua_chunk = tinest.result.unwrap(tinest.host.lua.start({source = "return 1"}))
  local lua_handle = lua_chunk.handle
  local lua_output = tinest.result.unwrap(
    tinest.host.lua.read({handle = lua_handle})
  ).output
  local lua_terminated = tinest.result.unwrap(
    tinest.host.lua.terminate({handle = lua_handle})
  ).terminated

  local response = tinest.result.unwrap(
    tinest.host.network.request({url = "https://example.test"})
  )
  local response_base64 = response.body_base64
  local secret = tinest.result.unwrap(tinest.host.secret.get({name = "TOKEN"}))
  if secret.found then
    local secret_value = secret.value
  end
end

local bad_transaction = tinest.host.workspace.transaction({mutations = {}})
local bad_process_handle = tinest.host.process.read({handle = "wrong"})
local bad_clock_input = tinest.host.clock.current_time("+09:00")

local strict_read = tinest.tool.function_(
  {id = "strict_read"},
  Input,
  Output,
  function(args)
    local missing = args.profile.nonexistent
    return {text = args.profile.name, truncated = false}
  end
)

local function unavailable_sandbox_globals()
  io.open("secret")
  os.execute("echo unsafe")
  package.loadlib("unsafe", "unsafe")
  debug.traceback()
  host.call("unsafe", {})
  assets.read("unsafe")
  tools.invoke("unsafe", {})
  store("unsafe", true)
  load("unsafe")
  loadfile("unsafe")
  dofile("unsafe")
  collectgarbage("collect")
  rawget({}, "unsafe")
  setmetatable({}, {})
  coroutine.create(function() end)
  spawn(function() end)
  await(nil)
  text("unsafe")
  set_timeout(function() end, 1)
  local raw_tools = ALL_TOOLS
end

local completion_tool = tinest.tool.function_({}, Input, Output, function(args)
  return {text = args.profile.name, truncated = false}
end)
local completion_driver = tinest.driver.define({}, function()
  return {tool_rounds = 0}
end)
local completion_hook = tinest.hook.agent_attach({}, function()
  return {}
end)
local completion_control = tinest.session.control({}, ControlValue, function(context)
  return context.value
end)
local completion_ui = tinest.ui.contribution({}, ActionPayload, function(data)
  return tinest.ui.text({text = data.item_id})
end)
local completion_action = tinest.ui.action({}, ActionPayload, function(data)
  return data.item_id
end)
local completion_scheduled = tinest.scheduler.handler({}, Input, function(payload)
  return payload
end)
local completion_definition = tinest.plugin.define({})
local invalid_spec_literals = tinest.tool.function_({
  id = "invalid-spec-literals",
  effects = {"not.an.effect"},
  required_capabilities = {"not.a.capability"},
}, Input, Output, function(args)
  return {text = args.profile.name, truncated = false}
end)
local invalid_model_capability = tinest.driver.define({
  id = "invalid-model-capability",
  required_model_capabilities = {"not.a.model.capability"},
}, function()
  return {tool_rounds = 0}
end)
local model_role_capability = tinest.model.capability.role.system

return tinest.plugin.define({
  driver = spec_driver,
  tools = {read_file, bad_return, strict_read, spec_tool},
  templates = {template},
  session_controls = {spec_control},
  ui = {card, tool_card, spec_ui},
  actions = {spec_action},
  hooks = {
    spec_scheduled,
    attach_hook,
    before_turn_hook,
    after_model_hook,
    after_tool_hook,
    after_turn_hook,
    ui_action_hook,
  },
})
