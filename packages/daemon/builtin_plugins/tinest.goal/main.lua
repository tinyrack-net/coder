local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

local GoalStatus, goal_status_code = S.enum(T.GoalStatus, {
  "active", "complete", "blocked", "budget_limited",
})
local UpdateGoalStatus, update_goal_status = S.enum(T.UpdateGoalStatus, {
  "complete", "blocked",
})

local goal_schema = S.object(T.GoalState, {
  objective = S.string(),
  token_budget = S.optional(S.integer({minimum = 1})),
  status = GoalStatus,
  tokens_used = S.integer({minimum = 0}),
  time_used_seconds = S.number({minimum = 0}),
  turns = S.integer({minimum = 0}),
})
local goal_state = tinest.state.cell({
  scope = tinest.state.scope.session,
  key = "goal",
}, goal_schema)

local function read_goal()
  local current = goal_state:read()
  if not current.found then return nil end
  return current
end

local function write_goal(current, goal)
  return goal_state:compare_and_set(current.revision, goal)
end

local function render(template, values)
  return string.gsub(template, "{{([a-z_]+)}}", function(key)
    return tostring(values[key] or "")
  end)
end

local refresh = tinest.ui.action({
  id = "refresh",
  required_capabilities = {tinest.capability.state.read},
}, S.any(), function(_arguments)
  return goal_state:read()
end)

local goal_tool = tinest.ui.contribution({
  id = "goal_tool",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  return tinest.ui.tool_document(arguments)
end)

local function status_document()
  local goal = read_goal()
  local status = "inactive"
  if goal ~= nil then
    status = tostring(goal.value.status or status)
  end
  return tinest.ui.badge({id = "goal-status", text = status})
end

local goal_status = tinest.ui.contribution({
  id = "goal_status",
  slot = tinest.ui.slot.conversation_status,
  required_capabilities = {tinest.capability.state.read},
  metadata = {snapshot = true},
}, S.any(), function(_arguments)
  return status_document()
end)

local goal_timeline = tinest.ui.contribution({
  id = "goal_timeline",
  slot = tinest.ui.slot.timeline,
  required_capabilities = {tinest.capability.state.read},
  metadata = {snapshot = true},
}, S.any(), function(_arguments)
  return status_document()
end)

local goal_dialog = tinest.ui.contribution({
  id = "goal_dialog",
  slot = tinest.ui.slot.dialog,
  required_capabilities = {tinest.capability.state.read},
}, S.any(), function(_arguments)
  local goal = read_goal()
  local objective = "No active goal."
  if goal ~= nil then
    objective = tostring(goal.value.objective or objective)
  end
  return tinest.ui.section({
    id = "goal-dialog",
    children = {
      tinest.ui.markdown({text = objective}),
      tinest.ui.button({label = "Refresh", action = refresh}),
    },
  })
end)

local create_goal = tinest.tool.function_({
  id = "create_goal",
  name = "create_goal",
  description = "Create the one active goal for this session.",
  effects = {
    tinest.effect.state.write,
    tinest.effect.scheduler.enqueue,
    tinest.effect.ui.dialog,
  },
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
    tinest.capability.scheduler.manage,
    tinest.capability.ui.publish,
  },
  presentation = {
    ui = goal_tool,
    group = "session",
    glyph = "edit",
    label = "Create goal",
    summary_argument = "objective",
  },
}, S.object(T.CreateGoalInput, {
  objective = S.string(),
  token_budget = S.optional(S.integer({minimum = 1})),
}), nil, function(arguments)
  if arguments.objective == "" then
    error("objective must be a non-empty string")
  end
  local current = read_goal()
  local revision = 0
  if current ~= nil then
    if current.value.status ~= goal_status_code.complete then
      error("cannot replace an unfinished goal")
    end
    revision = current.revision
  end
  local stored = goal_state:compare_and_set(
    revision,
    {
      objective = arguments.objective,
      token_budget = arguments.token_budget,
      status = goal_status_code.active,
      tokens_used = 0,
      time_used_seconds = 0,
      turns = 0,
    }
  )
  tinest.ui.dialog(goal_dialog, stored)
  return stored
end)

local get_goal = tinest.tool.function_({
  id = "get_goal",
  name = "get_goal",
  description = "Read the active goal and its usage accounting.",
  effects = {tinest.effect.state.read},
  required_capabilities = {tinest.capability.state.read},
  presentation = {
    ui = goal_tool,
    group = "session",
    glyph = "read",
    label = "Get goal",
  },
}, S.object(T.GetGoalInput, {}), nil, function(_arguments)
  return read_goal()
end)

local update_goal = tinest.tool.function_({
  id = "update_goal",
  name = "update_goal",
  description = "Complete or block the active goal using the goal lifecycle contract.",
  effects = {
    tinest.effect.state.write,
    tinest.effect.scheduler.enqueue,
    tinest.effect.ui.timeline,
  },
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
    tinest.capability.scheduler.manage,
    tinest.capability.ui.publish,
  },
  presentation = {
    ui = goal_timeline,
    group = "session",
    glyph = "edit",
    label = "Update goal",
    summary_argument = "status",
  },
}, S.object(T.UpdateGoalInput, {status = UpdateGoalStatus}), nil,
function(arguments)
  local current = read_goal()
  if current == nil then error("goal does not exist") end
  local goal = current.value
  if arguments.status == update_goal_status.blocked and
      (goal.turns or 0) < 3 then
    error("a goal may be blocked only after three continuation turns")
  end
  goal.status = arguments.status
  local stored = write_goal(current, goal)
  tinest.ui.timeline(goal_timeline, stored, {snapshot = true})
  return stored
end)

local before_turn = tinest.hook.before_turn({
  id = "before-turn",
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
  },
}, function(arguments)
  local current = read_goal()
  if current == nil or current.value.status ~= goal_status_code.active then
    return {}
  end
  local goal = current.value
  if arguments.internal == true then
    goal.turns = (goal.turns or 0) + 1
    current = write_goal(current, goal)
    goal = current.value
  end
  local budget = goal.token_budget == nil and "unbounded" or goal.token_budget
  local remaining = goal.token_budget == nil and "unbounded" or
    math.max(0, goal.token_budget - (goal.tokens_used or 0))
  return {
    prompt = render(tinest.assets.read("prompts/continuation.md"), {
      objective = goal.objective,
      tokens_used = goal.tokens_used or 0,
      token_budget = budget,
      remaining_tokens = remaining,
      continuation_turns = goal.turns or 0,
    }),
  }
end)

local after_model = tinest.hook.after_model({
  id = "after-model",
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
  },
}, function(arguments)
  local current = read_goal()
  if current == nil or current.value.status ~= goal_status_code.active then
    return {}
  end
  local usage = arguments.usage or {}
  local input = (usage.inputTokens or 0) - (usage.cachedInputTokens or 0)
  if input < 0 then input = 0 end
  local output = usage.outputTokens or 0
  if output < 0 then output = 0 end
  local delta = input + output
  if delta == 0 then delta = usage.totalTokens or 0 end
  local elapsed = arguments.elapsed_seconds or 0
  if elapsed < 0 then elapsed = 0 end
  if delta == 0 and elapsed == 0 then return {} end
  local goal = current.value
  goal.tokens_used = (goal.tokens_used or 0) + delta
  goal.time_used_seconds = (goal.time_used_seconds or 0) + elapsed
  if goal.token_budget ~= nil and goal.tokens_used >= goal.token_budget then
    goal.status = goal_status_code.budget_limited
  end
  return write_goal(current, goal)
end)

local scheduled = tinest.scheduler.handler({
  id = "scheduled",
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.scheduler.manage,
  },
}, S.map(S.any()), function(arguments)
  return {continue = true, payload = arguments}
end)

local after_turn = tinest.hook.after_turn({
  id = "after-turn",
  required_capabilities = {
    tinest.capability.state.read,
    tinest.capability.state.write,
    tinest.capability.scheduler.manage,
  },
}, function(arguments)
  local current = read_goal()
  if current == nil or current.value.status ~= goal_status_code.active then
    return {}
  end
  return tinest.scheduler.continue_after_turn(
    scheduled,
    {reason = "goal_active"}
  )
end)

return tinest.plugin.define({
  tools = {create_goal, get_goal, update_goal},
  hooks = {before_turn, after_model, scheduled, after_turn},
  ui = {goal_tool, goal_status, goal_timeline, goal_dialog},
  actions = {refresh},
})
