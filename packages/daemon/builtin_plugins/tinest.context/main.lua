local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

local tool_card = tinest.ui.contribution({
  id = "context_tool",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  return tinest.ui.tool_document(arguments)
end)

local context_status = tinest.ui.contribution({
  id = "context_status",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  local value = type(arguments) == "table" and arguments or {}
  local compacting = value.action == "compact_context"
  return tinest.ui.alert({
    id = "context-status",
    title = compacting and "Compacting context" or "New context",
    description = compacting and
      "The Agent driver is summarizing and replacing its model history." or
      "The Agent driver retired the previous model history.",
  })
end)

local get_context_remaining = tinest.tool.function_({
  id = "get_context_remaining",
  name = "get_context_remaining",
  description = "Get remaining tokens in the current context window.",
  effects = {tinest.effect.context.read},
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "context",
    label = "Context remaining",
  },
}, S.object(T.ContextRemainingInput, {}), nil,
function(_arguments, tool_context)
  local context = type(tool_context.context) == "table" and
    tool_context.context or {}
  local window = tonumber(context.window_tokens)
  local used = tonumber(context.used_tokens) or 0
  local remaining = window and math.max(0, window - used) or nil
  return {
    output = remaining and tostring(remaining) .. " tokens remaining." or
      "The current model does not report a context window.",
    structured_content = {
      context = {
        window_tokens = window,
        used_tokens = used,
        remaining_tokens = remaining,
      },
    },
  }
end)

local function request_context(action, arguments)
  local value = {action = action, instructions = arguments.instructions}
  local label = action == "new_context" and
    "Starting a new context window." or
    "Compacting the current context window."
  tinest.ui.timeline(context_status, value, {snapshot = true})
  return {
    output = label,
    structured_content = {driver_action = value},
    _meta = {driver_action = value},
  }
end

local new_context = tinest.tool.function_({
  id = "new_context",
  name = "new_context",
  description = "Request a fresh context window without changing environment state.",
  effects = {tinest.effect.context.reset, tinest.effect.ui.timeline},
  required_capabilities = {tinest.capability.ui.publish},
  presentation = {
    ui = context_status,
    group = "session",
    glyph = "context",
    label = "New context",
  },
}, S.object(T.NewContextInput, {}), nil, function(arguments)
  return request_context("new_context", arguments)
end)

local compact_context = tinest.tool.function_({
  id = "compact_context",
  name = "compact_context",
  description = "Request driver-owned context compaction at the next safe boundary.",
  effects = {tinest.effect.context.compact, tinest.effect.ui.timeline},
  required_capabilities = {tinest.capability.ui.publish},
  presentation = {
    ui = context_status,
    group = "session",
    glyph = "context",
    label = "Compact context",
  },
}, S.object(T.CompactContextInput, {
  instructions = S.optional(S.string()),
}), nil,
function(arguments)
  return request_context("compact_context", arguments)
end)

return tinest.plugin.define({
  tools = {get_context_remaining, new_context, compact_context},
  ui = {tool_card, context_status},
})
