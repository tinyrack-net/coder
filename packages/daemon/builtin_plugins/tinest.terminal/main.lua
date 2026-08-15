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

local exec_output = S.object(T.ExecCommandOutput, {
  output = S.string(),
  running = S.boolean(),
  exit_code = S.optional(S.integer()),
  wall_time_ms = S.integer(),
  truncated = S.optional(S.boolean()),
  session_id = S.optional(S.integer()),
})

local process_read_output = S.object(T.WriteStdinOutput, {
  output = S.string(),
  running = S.boolean(),
  exit_code = S.optional(S.integer()),
  wall_time_ms = S.integer(),
})

local exec_command = tinest.tool.function_({
  id = "exec_command",
  name = "exec_command",
  description = "Run a shell command and optionally retain its session.",
  uses = {tinest.host.process.start, tinest.host.process.read},
  effects = {tinest.effect.process.command},
  required_capabilities = {tinest.capability.process.execute},
  presentation = {
    ui = tool_card,
    group = "execution",
    glyph = "run",
    label = "Execute command",
    summary_argument = "cmd",
    approval_preview = "cmd",
  },
}, S.object(T.ExecCommandInput, {
  cmd = S.string(),
  workdir = S.optional(S.string()),
  tty = S.optional(S.boolean()),
  shell = S.optional(S.string()),
  login = S.optional(S.boolean()),
  yield_time_ms = S.optional(S.integer()),
  max_output_tokens = S.optional(S.integer()),
}), exec_output, function(arguments)
  local started = tinest.result.unwrap(tinest.host.process.start({
    command = arguments.cmd,
    workdir = arguments.workdir,
    tty = arguments.tty == true,
    shell = arguments.shell,
    login = arguments.login,
  }))
  local result = tinest.result.unwrap(tinest.host.process.read({
    handle = started.handle,
    yield_time_ms = arguments.yield_time_ms or 10000,
  }))
  local maximum = (arguments.max_output_tokens or 10000) * 4
  local output = result.output
  local truncated = false
  if type(result.output) == "string" and #result.output > maximum then
    output = string.sub(result.output, 1, maximum)
    truncated = true
  end
  return tinest.result.value({
    output = output,
    running = result.running,
    exit_code = result.exit_code,
    wall_time_ms = result.wall_time_ms,
    truncated = truncated and true or nil,
    session_id = result.running and started.handle or nil,
  })
end)

local write_stdin = tinest.tool.function_({
  id = "write_stdin",
  name = "write_stdin",
  description = "Write or poll an approved live command session.",
  uses = {tinest.host.process.write, tinest.host.process.read},
  effects = {tinest.effect.process.write},
  required_capabilities = {tinest.capability.process.write},
  presentation = {
    ui = tool_card,
    group = "execution",
    glyph = "run",
    label = "Write stdin",
    requires = {exec_command},
  },
}, S.object(T.WriteStdinInput, {
  session_id = S.integer(),
  chars = S.optional(S.string()),
  yield_time_ms = S.optional(S.integer()),
  max_output_tokens = S.optional(S.integer()),
}), process_read_output, function(arguments)
  if arguments.chars ~= nil and arguments.chars ~= "" then
    tinest.result.unwrap(tinest.host.process.write({
      handle = arguments.session_id,
      chars = arguments.chars,
    }))
  end
  return tinest.result.value(
    tinest.result.unwrap(tinest.host.process.read({
      handle = arguments.session_id,
      yield_time_ms = arguments.yield_time_ms or 10000,
    }))
  )
end)

return tinest.plugin.define({
  tools = {exec_command, write_stdin},
  ui = {tool_card},
})
