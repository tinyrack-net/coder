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

local common = {
  effects = {tinest.effect.filesystem.read},
  required_capabilities = {tinest.capability.workspace.read},
}

local function catalog()
  local result = tinest.result.unwrap(tinest.host.skills.list({}))
  local skills = result.skills or {}
  table.sort(skills, function(left, right)
    return tostring(left.name or "") < tostring(right.name or "")
  end)
  return skills
end

local before_turn = tinest.hook.before_turn({
  id = "prompt",
  uses = {tinest.host.skills.list},
  required_capabilities = {tinest.capability.workspace.read},
  metadata = {ordered_data = "skill_prompt"},
}, function(_arguments)
  local result = tinest.result.unwrap(tinest.host.skills.list({}))
  local implicit = result.implicit_skills or {}
  table.sort(implicit, function(left, right)
    return tostring(left.name or "") < tostring(right.name or "")
  end)
  if #implicit == 0 then return {} end
  local lines = {"## Implicit skills"}
  for _, skill in ipairs(implicit) do
    lines[#lines + 1] = "### " .. tostring(skill.name or "")
    lines[#lines + 1] = tostring(skill.instructions or "")
  end
  return {prompt = table.concat(lines, "\n\n")}
end)

local function cursor_offset(cursor, prefix, count)
  if cursor == nil then return 0 end
  if type(cursor) ~= "string" then error("skill cursor is invalid") end
  local raw = cursor
  if prefix ~= nil then
    if string.sub(raw, 1, #prefix) ~= prefix then
      error("skill cursor is invalid")
    end
    raw = string.sub(raw, #prefix + 1)
  end
  local offset = tonumber(raw)
  if offset == nil or offset < 0 or offset > count or
      math.floor(offset) ~= offset then
    error("skill cursor is invalid")
  end
  return offset
end

local function slice(values, start_index, size)
  local result = {}
  local finish = math.min(#values, start_index + size)
  for index = start_index + 1, finish do
    result[#result + 1] = values[index]
  end
  return result, finish
end

local list_skills = tinest.tool.function_({
  id = "list_skills",
  name = "list_skills",
  description = "List legacy workspace skill summaries one page at a time.",
  uses = {tinest.host.skills.list},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "resource",
    label = "List skills",
  },
}, S.object(T.ListSkillsInput, {
  cursor = S.optional(S.string()),
}), nil, function(arguments)
  local skills = catalog()
  local start = cursor_offset(arguments.cursor, nil, #skills)
  local page, finish = slice(skills, start, 50)
  local result = {
    skills = page,
    total = #skills,
    nextCursor = finish < #skills and tostring(finish) or nil,
  }
  local lines = {}
  for _, summary in ipairs(page) do
    lines[#lines + 1] = tostring(summary.name or "") .. ": " ..
      tostring(summary.description or "")
  end
  return {
    output = table.concat(lines, "\n"),
    structured_content = result,
  }
end)

local skill = tinest.tool.function_({
  id = "skill",
  name = "skill",
  description = "Load one legacy skill document or bundled resource.",
  uses = {tinest.host.skills.read},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "resource",
    label = "Read skill",
    summary_argument = "name",
  },
}, S.object(T.SkillInput, {
  name = S.string(),
  resource = S.optional(S.string()),
}), nil, function(arguments)
  return tinest.result.unwrap(tinest.host.skills.read({
    name = arguments.name,
    resource = arguments.resource,
  }))
end)

local AuthorityKind, authority_kind = S.enum(T.AuthorityKind, {"executor"})
local authority = S.object(T.Authority, {
  kind = AuthorityKind,
  id = S.optional(S.string()),
})

local list = tinest.tool.function_({
  id = "list",
  name = "skills__list",
  description = "List authority-owned skills using the modern skill protocol.",
  uses = {tinest.host.skills.list},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "resource",
    label = "List skills",
    namespace = "skills",
    member = "list",
  },
}, S.object(T.SkillsListInput, {
  authority = authority,
  cursor = S.optional(S.string()),
}), nil, function(arguments)
  if arguments.authority.kind ~= authority_kind.executor then
    error("unsupported skill authority")
  end
  local skills = catalog()
  local start = cursor_offset(arguments.cursor, "local:", #skills)
  local page, finish = slice(skills, start, 20)
  local result = {}
  for _, summary in ipairs(page) do
    result[#result + 1] = {
      authority = {kind = authority_kind.executor, id = "local"},
      package = summary.name,
      name = summary.name,
      description = summary.description,
      main_resource = "SKILL.md",
    }
  end
  return {
    skills = result,
    warnings = {},
    next_cursor = finish < #skills and "local:" .. tostring(finish) or nil,
  }
end)

local read = tinest.tool.function_({
  id = "read",
  name = "skills__read",
  description = "Read a paged authority-owned skill resource.",
  uses = {tinest.host.skills.read},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "resource",
    label = "Read skill",
    summary_argument = "resource",
    namespace = "skills",
    member = "read",
  },
}, S.object(T.SkillsReadInput, {
  authority = authority,
  package = S.string(),
  resource = S.string(),
  cursor = S.optional(S.string()),
}), nil, function(arguments)
  if arguments.authority.kind ~= authority_kind.executor or
      arguments.authority.id ~= "local" then
    error("skill package is not available from the requested authority")
  end
  local loaded
  if arguments.resource == "SKILL.md" then
    loaded = tinest.result.unwrap(
      tinest.host.skills.read({name = arguments.package})
    )
  else
    loaded = tinest.result.unwrap(tinest.host.skills.read({
      name = arguments.package,
      resource = arguments.resource,
    }))
  end
  local contents = arguments.resource == "SKILL.md" and
    loaded.instructions or loaded.contents
  contents = tostring(contents or "")
  local start = cursor_offset(arguments.cursor, "local:", #contents)
  local finish = math.min(#contents, start + 256 * 1024)
  return {
    resource = arguments.resource,
    contents = string.sub(contents, start + 1, finish),
    next_cursor = finish < #contents and "local:" .. tostring(finish) or nil,
  }
end)

return tinest.plugin.define({
  tools = {list_skills, skill, list, read},
  hooks = {before_turn},
  ui = {tool_card},
})
