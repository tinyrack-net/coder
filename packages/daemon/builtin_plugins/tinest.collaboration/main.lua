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

-- Strings this surface owns. The host tells it the reader's language; only the
-- status words are host-drawn, because those are a meaning the host resolves.
local strings = {
  en = {
    one = "1 subagent",
    other = "%d subagents",
    running = "%d running",
    blocked = "%d to approve",
  },
  ko = {
    other = "서브 에이전트 %d개",
    running = "%d개 실행 중",
    blocked = "%d개 승인 필요",
  },
  ja = {
    other = "サブエージェント %d 個",
    running = "%d 個実行中",
    blocked = "%d 個が承認待ち",
  },
}

--- Reads the base language of a BCP 47 tag, falling back to English.
local function table_for(locale)
  local tag = tostring(locale or "en")
  local base = tag:match("^([%a]+)") or "en"
  return strings[base:lower()] or strings.en
end

--- Korean and Japanese have one form; English has two.
local function count_text(words, count)
  if count == 1 and words.one ~= nil then return words.one end
  return string.format(words.other, count)
end

local agent_status = tinest.ui.contribution({
  id = "agent_status",
  slot = tinest.ui.slot.composer_drawer,
  uses = {tinest.host.collaboration.list_agents},
  required_capabilities = {
    tinest.capability.collaboration.list,
    tinest.capability.ui.publish,
  },
  depends_on = {tinest.ui.dependency.session_tree},
  metadata = {snapshot = true},
}, S.any(), function(_arguments, context)
  -- A subagent's own pane is read-only and has no tree of its own to show.
  if context.readOnly == true then
    return tinest.ui.section({id = "collaboration-status", children = {}})
  end
  local response = tinest.result.unwrap(
    tinest.host.collaboration.list_agents({})
  )
  local agents = response.agents or response
  local words = table_for(context.locale)

  -- The host answers with the caller's whole tree, and its root is the very
  -- session this drawer sits under. Listing it would put a "/root" row beside
  -- the composer of every conversation, including the ones that never spawn a
  -- subagent at all; only the subagents belong on this surface.
  local items_by_parent = {}
  local total, running, blocked = 0, 0, 0
  local root_session_id = ""
  for _, agent in ipairs(agents or {}) do
    local name = tostring(agent.agent_name or "")
    if name == root_path then
      root_session_id = tostring(agent.session_id or "")
    end
    if name ~= "" and name ~= root_path then
      total = total + 1
      local lifecycle = tostring(agent.agent_status or "")
      local session = tostring(agent.session_status or "")
      local status
      if session == "waiting_for_approval" then
        status = "blocked"
        blocked = blocked + 1
      elseif lifecycle == "pending_init" then
        status = "pending"
        running = running + 1
      elseif lifecycle == "running" then
        status = "running"
        running = running + 1
      elseif lifecycle == "interrupted" then
        status = "paused"
      elseif lifecycle == "errored" then
        status = "failed"
      else
        status = "done"
      end
      local parent = tostring(agent.parent_session_id or "")
      items_by_parent[parent] = items_by_parent[parent] or {}
      local siblings = items_by_parent[parent]
      siblings[#siblings + 1] = {
        session_id = tostring(agent.session_id or ""),
        label = tostring(agent.task_name or agent.title or name),
        description = name,
        status = status,
      }
    end
  end

  if total == 0 then
    return tinest.ui.section({id = "collaboration-status", children = {}})
  end

  -- Nesting is expressed by nesting: the host owns the indentation, so a
  -- deeper tree needs nothing new here.
  local build
  build = function(parent_id)
    local nodes = {}
    for _, item in ipairs(items_by_parent[parent_id] or {}) do
      nodes[#nodes + 1] = tinest.ui.tree_item({
        label = item.label,
        description = item.description,
        status = item.status,
        onActivate = tinest.ui.open_session(item.session_id),
        children = build(item.session_id),
      })
    end
    return nodes
  end

  local summary = {}
  if running > 0 then
    summary[#summary + 1] = tinest.ui.badge({
      text = string.format(words.running, running),
      variant = "info",
    })
  end
  -- The rows are hidden while the drawer is collapsed, so a tree parked on an
  -- approval has to say so on the summary itself.
  if blocked > 0 then
    summary[#summary + 1] = tinest.ui.badge({
      text = string.format(words.blocked, blocked),
      variant = "warning",
    })
  end

  return tinest.ui.disclosure({
    title = count_text(words, total),
    summary = summary,
    children = {tinest.ui.tree({children = build(root_session_id)})},
  })
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
  description = "Wait for agent activity, user input, or a timeout. Returns " ..
    "the inter-agent messages the wait ended on.",
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
