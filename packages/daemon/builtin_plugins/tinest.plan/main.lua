local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

local PlanStatus, plan_status = S.enum(T.PlanStatus, {
  "pending", "in_progress", "completed",
})
local plan_item = S.object(T.PlanItem, {
  step = S.string(),
  status = PlanStatus,
})
local plan_value = S.object(T.PlanValue, {
  explanation = S.optional(S.string()),
  plan = S.array(plan_item),
})
local plan_state = tinest.state.cell({
  scope = tinest.state.scope.session,
  key = "plan",
}, plan_value)

local refresh = tinest.ui.action({
  id = "refresh",
  required_capabilities = {tinest.capability.state.read},
}, S.any(), function(_arguments)
  return plan_state:read()
end)

local function plan_markdown(entry)
  if entry == nil or entry.found ~= true or entry.value == nil then
    return "No plan yet."
  end
  local plan = entry.value
  local lines = {"# Plan"}
  if type(plan.explanation) == "string" and plan.explanation ~= "" then
    table.insert(lines, plan.explanation)
  end
  for _, item in ipairs(plan.plan or {}) do
    local marker = item.status == plan_status.completed and "x" or " "
    table.insert(lines, "- [" .. marker .. "] " .. tostring(item.step or ""))
  end
  return table.concat(lines, "\n\n")
end

local plan_card = tinest.ui.contribution({
  id = "plan_card",
  slot = tinest.ui.slot.timeline,
  required_capabilities = {tinest.capability.state.read},
  metadata = {snapshot = true},
}, S.any(), function(_arguments)
  return tinest.ui.section({
    id = "plan",
    children = {
      tinest.ui.markdown({text = plan_markdown(plan_state:read())}),
      tinest.ui.button({label = "Refresh", action = refresh}),
    },
  })
end)

local mode = tinest.session.control({
  id = "mode",
  metadata = {label = "Plan", default = false},
}, S.boolean(), function(arguments)
  return arguments.value == true
end)

local before_turn = tinest.hook.before_turn({
  id = "before-turn",
  metadata = {ordered_data = "plan_prompt"},
}, function(arguments)
  if mode:get(arguments.session_controls) ~= true then return {} end
  return {
    prompt = tinest.assets.read("prompts/plan_mode.md"),
    capability_limit = {
      tinest.capability.workspace.read,
      tinest.capability.state.read,
    },
  }
end)

local update_plan = tinest.tool.function_({
  id = "update_plan",
  name = "update_plan",
  description = "Atomically replace the current session plan.",
  effects = {tinest.effect.state.write, tinest.effect.ui.timeline},
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
    tinest.capability.ui.publish,
  },
  presentation = {
    ui = plan_card,
    group = "session",
    glyph = "edit",
    label = "Update plan",
  },
}, plan_value, nil, function(arguments)
  local current = plan_state:read()
  local value = plan_state:compare_and_set(
    current.found and current.revision or 0,
    {explanation = arguments.explanation, plan = arguments.plan}
  )
  tinest.ui.timeline(plan_card, value, {snapshot = true})
  return value
end)

return tinest.plugin.define({
  tools = {update_plan},
  hooks = {before_turn},
  session_controls = {mode},
  ui = {plan_card},
  actions = {refresh},
})
