local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

-- Canonical collaboration path of every tree root, as the host reports it.
local root_path = "/root"

local tool_card = tinest.ui.contribution({
  id = "tool",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  return tinest.ui.tool_document(arguments)
end)

local agent_status = tinest.ui.contribution({
  id = "agent_status",
  slot = tinest.ui.slot.conversation_status,
  uses = {tinest.host.collaboration.list_agents},
  required_capabilities = {
    tinest.capability.collaboration.list,
    tinest.capability.ui.publish,
  },
  metadata = {snapshot = true, label = "Subagents"},
}, S.any(), function(_arguments)
  local response = tinest.result.unwrap(
    tinest.host.collaboration.list_agents({})
  )
  local agents = response.agents or response
  local children = {}
  for _, agent in ipairs(agents or {}) do
    local name = tostring(agent.agent_name or "")
    -- The host answers with the caller's whole tree, and its root is the very
    -- session this panel sits under. Listing it would put a "/root" row beside
    -- the composer of every conversation, including the ones that never spawn
    -- a subagent at all; only the subagents belong on this surface.
    if name ~= "" and name ~= root_path then
      children[#children + 1] = tinest.ui.row({
        children = {
          tinest.ui.text({text = name}),
          tinest.ui.badge({
            text = tostring(agent.agent_status or "unknown"),
          }),
        },
      })
    end
  end
  return tinest.ui.section({id = "collaboration-status", children = children})
end)

local before_turn = tinest.hook.before_turn({
  id = "prompt",
  metadata = {ordered_data = "collaboration_prompt"},
}, function(arguments)
  local extension_data = arguments.extension_data or {}
  local collaboration = extension_data.collaboration
  if type(collaboration) ~= "table" then return {} end

  local path = tostring(collaboration.path or root_path)
  local is_root = collaboration.is_root == true
  local identity
  local role
  if is_root then
    identity = "You are the root agent at path `" .. path ..
      "` of a collaboration tree."
    role = tinest.assets.read("prompts/orchestrator.md")
  else
    identity = "You are subagent `" .. path .. "`. Your final response of " ..
      "each turn is delivered to your parent as a FINAL_ANSWER message; " ..
      "make it self-contained."
    role = tinest.assets.read("prompts/subagent.md")
  end
  local concurrent = tostring(collaboration.max_concurrent_turns or 1)
  return {
    prompt = table.concat({
      tinest.assets.read("prompts/common.md"),
      identity,
      "At most " .. concurrent .. " subagent turns run concurrently per tree.",
      role,
    }, "\n\n"),
  }
end)

local optional_string = S.optional(S.string())
local spawn_agent = tinest.tool.function_({
  id = "spawn_agent",
  name = "spawn_agent",
  description = "Spawn a subagent that works asynchronously on a task.",
  uses = {tinest.host.collaboration.spawn_agent},
  effects = {tinest.effect.collaboration.spawn},
  required_capabilities = {tinest.capability.collaboration.spawn},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "Spawn agent",
    summary_argument = "task_name",
  },
}, S.object(T.SpawnAgentInput, {
  task_name = S.string({
    description = "Unique sibling name using lowercase letters, digits, and underscores.",
  }),
  message = S.string(),
  agent_type = optional_string,
  fork_turns = optional_string,
  model = optional_string,
  reasoning_effort = optional_string,
  service_tier = optional_string,
}), nil, function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.spawn_agent({
      task_name = arguments.task_name,
      message = arguments.message,
      agent_type = arguments.agent_type,
      fork_turns = arguments.fork_turns,
      model = arguments.model,
      reasoning_effort = arguments.reasoning_effort,
      service_tier = arguments.service_tier,
    })
  )
end)

local target_message = S.object(T.TargetMessage, {
  target = S.string(),
  message = S.string(),
})
local send_message = tinest.tool.function_({
  id = "send_message",
  name = "send_message",
  description = "Queue a message for another agent without starting a turn.",
  uses = {tinest.host.collaboration.send_message},
  effects = {tinest.effect.collaboration.message},
  required_capabilities = {tinest.capability.collaboration.message},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "Send message",
    summary_argument = "target",
  },
}, target_message, nil, function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.send_message({
      target = arguments.target,
      message = arguments.message,
    })
  )
end)

local followup_task = tinest.tool.function_({
  id = "followup_task",
  name = "followup_task",
  description = "Send a follow-up task and resume an idle subagent.",
  uses = {tinest.host.collaboration.followup_task},
  effects = {tinest.effect.collaboration.message},
  required_capabilities = {tinest.capability.collaboration.message},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "Follow up task",
    summary_argument = "target",
  },
}, target_message, nil, function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.followup_task({
      target = arguments.target,
      message = arguments.message,
    })
  )
end)

local wait_agent = tinest.tool.function_({
  id = "wait_agent",
  name = "wait_agent",
  description = "Wait for agent activity, user input, or a timeout.",
  uses = {tinest.host.collaboration.wait_agent},
  effects = {tinest.effect.collaboration.wait},
  required_capabilities = {tinest.capability.collaboration.wait},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "Wait for agent",
  },
}, S.object(T.WaitAgentInput, {
  timeout_ms = S.optional(S.number()),
}), nil, function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.wait_agent({
      timeout_ms = arguments.timeout_ms,
    })
  )
end)

local interrupt_agent = tinest.tool.function_({
  id = "interrupt_agent",
  name = "interrupt_agent",
  description = "Interrupt the running turn of one subagent.",
  uses = {tinest.host.collaboration.interrupt_agent},
  effects = {tinest.effect.collaboration.interrupt},
  required_capabilities = {tinest.capability.collaboration.interrupt},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "Interrupt agent",
    summary_argument = "target",
  },
}, S.object(T.InterruptAgentInput, {target = S.string()}), nil,
function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.interrupt_agent({
      target = arguments.target,
    })
  )
end)

local list_agents = tinest.tool.function_({
  id = "list_agents",
  name = "list_agents",
  description = "List agents in the caller's collaboration tree.",
  uses = {tinest.host.collaboration.list_agents},
  effects = {tinest.effect.collaboration.list},
  required_capabilities = {tinest.capability.collaboration.list},
  presentation = {
    ui = tool_card,
    group = "collaboration",
    glyph = "delegate",
    label = "List agents",
    summary_argument = "path_prefix",
  },
}, S.object(T.ListAgentsInput, {path_prefix = optional_string}), nil,
function(arguments)
  return tinest.result.unwrap(
    tinest.host.collaboration.list_agents({
      path_prefix = arguments.path_prefix,
    })
  )
end)

return tinest.plugin.define({
  hooks = {before_turn},
  tools = {
    spawn_agent,
    send_message,
    followup_task,
    wait_agent,
    interrupt_agent,
    list_agents,
  },
  ui = {tool_card, agent_status},
})
