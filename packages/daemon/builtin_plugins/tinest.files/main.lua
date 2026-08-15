local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")
local gitignore = require("gitignore")

local ImageDetail, image_detail = S.enum(T.ImageDetail, {"high", "original"})

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

local function format_entries(value)
  local entries = value.entries or value
  local lines = {}
  for _, entry in ipairs(entries or {}) do
    local path = tostring(entry.path or entry.name or "")
    if entry.type == "directory" then path = path .. "/" end
    lines[#lines + 1] = path
  end
  return {
    output = table.concat(lines, "\n"),
    structured_content = value,
  }
end

local list_directory = tinest.tool.function_({
  id = "list_directory",
  name = "list_directory",
  description = "List entries below a workspace directory.",
  uses = {tinest.host.workspace.list, tinest.host.workspace.walk},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "filesystem",
    glyph = "list",
    label = "List directory",
    summary_argument = "path",
  },
}, S.object(T.ListDirectoryInput, {
  path = S.string(),
  recursive = S.optional(S.boolean()),
}), nil, function(arguments)
  if arguments.recursive == true then
    return format_entries(tinest.result.unwrap(
      tinest.host.workspace.walk({path = arguments.path})
    ))
  end
  return format_entries(tinest.result.unwrap(
    tinest.host.workspace.list({path = arguments.path})
  ))
end)

local read_file_input = S.object(T.ReadFileInput, {
  path = S.string(),
  line = S.optional(S.integer({minimum = 1})),
  limit = S.optional(S.integer({minimum = 1})),
})

local read_file = tinest.tool.function_({
  id = "read_file",
  name = "read_file",
  description = "Read a bounded UTF-8 workspace file range.",
  uses = {tinest.host.workspace.read_text},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "filesystem",
    glyph = "read",
    label = "Read file",
    summary_argument = "path",
  },
}, read_file_input, nil, function(arguments)
  local value = tinest.result.unwrap(tinest.host.workspace.read_text({
    path = arguments.path,
    offset = (arguments.line or 1) - 1,
    limit = arguments.limit or 2000,
  }))
  return {
    text = value.text,
    offset = value.offset,
    next_offset = value.next_offset,
    total_lines = value.total_lines,
    eof = value.eof,
    output = value.text,
  }
end)

local function matches(text, query, case_sensitive)
  if case_sensitive then return string.find(text, query, 1, true) ~= nil end
  return string.find(string.lower(text), string.lower(query), 1, true) ~= nil
end

local function read_all_text(path)
  local chunks = {}
  local offset = 0
  while true do
    local value = tinest.result.unwrap(tinest.host.workspace.read_text({
      path = path,
      offset = offset,
      limit = 2000,
    }))
    chunks[#chunks + 1] = value.text or ""
    if value.eof == true or value.next_offset == nil then break end
    offset = value.next_offset
  end
  return table.concat(chunks, "\n")
end

local search_text = tinest.tool.function_({
  id = "search_text",
  name = "search_text",
  description = "Search workspace text without escaping the workspace.",
  uses = {tinest.host.workspace.walk, tinest.host.workspace.read_text},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "filesystem",
    glyph = "search",
    label = "Search text",
    summary_argument = "query",
  },
}, S.object(T.SearchTextInput, {
  query = S.string(),
  path = S.optional(S.string()),
  case_sensitive = S.optional(S.boolean()),
  include_ignored = S.optional(S.boolean()),
}), nil, function(arguments)
  local search_root = arguments.path or "."
  local walked = tinest.result.unwrap(tinest.host.workspace.walk({
    path = search_root,
    files_only = true,
  }))
  local entries = walked.entries or walked
  local sources = gitignore.sources(entries, read_all_text, search_root)
  local results = {}
  for _, entry in ipairs(entries or {}) do
    local path = entry.path
    if path ~= nil and entry.type == "file" and gitignore.is_visible(
        sources,
        path,
        false,
        arguments.include_ignored == true
      ) then
      local ok, text = pcall(read_all_text, path)
      if type(text) == "string" then
        local line_number = 0
        for line in (text .. "\n"):gmatch("(.-)\n") do
          line_number = line_number + 1
          if matches(line, arguments.query, arguments.case_sensitive == true) then
            results[#results + 1] = {
              path = path,
              line = line_number,
              text = line,
            }
          end
        end
      end
    end
  end
  local lines = {}
  for _, result in ipairs(results) do
    lines[#lines + 1] = result.path .. ":" .. result.line .. ":" .. result.text
  end
  return {
    output = table.concat(lines, "\n"),
    structured_content = {matches = results, truncated = walked.truncated == true},
  }
end)

local glob = tinest.tool.function_({
  id = "glob",
  name = "glob",
  description = "Resolve a workspace-relative glob pattern.",
  uses = {tinest.host.workspace.walk, tinest.host.workspace.read_text},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "filesystem",
    glyph = "search",
    label = "Glob",
    summary_argument = "pattern",
  },
}, S.object(T.GlobInput, {
  pattern = S.string(),
  path = S.optional(S.string()),
  include_ignored = S.optional(S.boolean()),
}), nil, function(arguments)
  local search_root = arguments.path or "."
  local walked = tinest.result.unwrap(
    tinest.host.workspace.walk({path = search_root})
  )
  local entries = walked.entries or walked
  local sources = gitignore.sources(entries, read_all_text, search_root)
  local matches = {}
  for _, entry in ipairs(entries or {}) do
    local path = entry.path
    local relative = gitignore.relative_to(path, search_root)
    if entry.type == "file" and relative ~= nil and gitignore.is_visible(
        sources,
        path,
        false,
        arguments.include_ignored == true
      ) and gitignore.glob_matches(arguments.pattern, relative) then
      matches[#matches + 1] = path
    end
  end
  table.sort(matches)
  return {
    output = table.concat(matches, "\n"),
    structured_content = {paths = matches, truncated = walked.truncated == true},
  }
end)

local view_image = tinest.tool.function_({
  id = "view_image",
  name = "view_image",
  description = "Open a workspace image through an opaque host resource.",
  uses = {tinest.host.workspace.stat, tinest.host.workspace.read_blob},
  effects = common.effects,
  required_capabilities = common.required_capabilities,
  presentation = {
    ui = tool_card,
    group = "filesystem",
    glyph = "image",
    kind = "image",
    label = "View image",
    summary_argument = "path",
  },
}, S.object(T.ViewImageInput, {
  path = S.string(),
  detail = S.optional(ImageDetail),
}), nil, function(arguments)
  local stat = tinest.result.unwrap(
    tinest.host.workspace.stat({path = arguments.path})
  )
  local blob = tinest.result.unwrap(
    tinest.host.workspace.read_blob({
      path = arguments.path,
      image_detail = arguments.detail or image_detail.high,
    })
  )
  return {
    output = arguments.path,
    structured_content = {
      detail = arguments.detail or image_detail.high,
      stat = stat,
    },
    resources = {blob},
  }
end)

return tinest.plugin.define({
  tools = {list_directory, read_file, search_text, glob, view_image},
  ui = {tool_card},
})
