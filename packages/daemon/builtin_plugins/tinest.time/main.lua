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

local current_time = tinest.tool.function_({
  id = "current_time",
  name = "clock__curr_time",
  description = "Return the current UTC time.",
  uses = {tinest.host.clock.current_time},
  effects = {tinest.effect.clock.read},
  required_capabilities = {tinest.capability.clock.read},
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "clock",
    label = "Current time",
    namespace = "clock",
    member = "curr_time",
  },
}, S.object(T.CurrentTimeInput, {}), nil, function(arguments)
  return tinest.result.unwrap(tinest.host.clock.current_time({}))
end)

local sleep = tinest.tool.function_({
  id = "sleep",
  name = "clock__sleep",
  description = "Wait until a duration elapses or new input arrives.",
  uses = {tinest.host.clock.sleep},
  effects = {tinest.effect.clock.sleep},
  required_capabilities = {tinest.capability.clock.sleep},
  presentation = {
    group = "session",
    glyph = "clock",
    label = "Sleep",
    namespace = "clock",
    member = "sleep",
    timeline = "sleep",
  },
}, S.object(T.SleepInput, {
  duration_ms = S.integer({minimum = 1}),
}), nil,
function(arguments)
  if arguments.duration_ms > 43200000 then
    error("duration_ms must be between 1 and 43200000")
  end
  return tinest.result.unwrap(tinest.host.clock.sleep({
    duration_ms = arguments.duration_ms,
  }))
end)

return tinest.plugin.define({
  tools = {current_time, sleep},
  ui = {tool_card},
})
