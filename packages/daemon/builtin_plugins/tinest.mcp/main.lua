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

local paging = S.object(T.PagingInput, {
  server = S.optional(S.string()),
  cursor = S.optional(S.string()),
})

local list_resources = tinest.tool.function_({
  id = "list_resources",
  name = "list_mcp_resources",
  description = "List resources published by connected MCP servers.",
  uses = {tinest.host.mcp.list_resources},
  effects = {tinest.effect.mcp.read},
  required_capabilities = {tinest.capability.mcp.read},
  presentation = {
    ui = tool_card,
    group = "mcp",
    glyph = "resource",
    label = "List MCP resources",
    summary_argument = "server",
  },
}, paging, nil, function(arguments)
  return tinest.result.unwrap(tinest.host.mcp.list_resources({
    server = arguments.server,
    cursor = arguments.cursor,
  }))
end)

local list_resource_templates = tinest.tool.function_({
  id = "list_resource_templates",
  name = "list_mcp_resource_templates",
  description = "List parameterized resource templates from MCP servers.",
  uses = {tinest.host.mcp.list_resource_templates},
  effects = {tinest.effect.mcp.read},
  required_capabilities = {tinest.capability.mcp.read},
  presentation = {
    ui = tool_card,
    group = "mcp",
    glyph = "resource",
    label = "List MCP resource templates",
    summary_argument = "server",
  },
}, paging, nil, function(arguments)
  return tinest.result.unwrap(
    tinest.host.mcp.list_resource_templates({
      server = arguments.server,
      cursor = arguments.cursor,
    })
  )
end)

local read_resource = tinest.tool.function_({
  id = "read_resource",
  name = "read_mcp_resource",
  description = "Read one concrete resource from an MCP server.",
  uses = {tinest.host.mcp.read_resource},
  effects = {tinest.effect.mcp.read},
  required_capabilities = {tinest.capability.mcp.read},
  presentation = {
    ui = tool_card,
    group = "mcp",
    glyph = "resource",
    label = "Read MCP resource",
    summary_argument = "uri",
  },
}, S.object(T.ReadResourceInput, {
  server = S.string(),
  uri = S.string(),
}), nil,
function(arguments)
  return tinest.result.unwrap(tinest.host.mcp.read_resource({
    server = arguments.server,
    uri = arguments.uri,
  }))
end)

local DynamicPayload = S.object(T.DynamicPayload, {
  server = S.string(),
  name = S.string(),
})

local tool_bridge = tinest.tool.template({
  id = "tool_bridge",
  uses = {tinest.host.mcp.invoke_tool},
  effects = {tinest.effect.mcp.invoke},
  required_capabilities = {tinest.capability.mcp.invoke},
}, DynamicPayload, S.map(S.any()), nil, function(arguments, payload)
  return tinest.result.unwrap(tinest.host.mcp.invoke_tool({
    server = payload.server,
    name = payload.name,
    arguments = arguments,
  }))
end)

local function safe_id(value)
  local normalized = string.lower(tostring(value or "")):gsub("[^a-z0-9_]", "_")
  if normalized == "" or not normalized:match("^[a-z]") then
    normalized = "tool_" .. normalized
  end
  return string.sub(normalized, 1, 96)
end

local tool_search = tinest.tool.deferred({
  id = "tool_search",
  name = "tool_search_mcp",
  description = "Discover connected MCP tools and surface typed dynamic contributions.",
  uses = {tinest.host.mcp.catalog_tools},
  effects = {tinest.effect.mcp.read, tinest.effect.tools.list},
  required_capabilities = {
    tinest.capability.mcp.read,
    tinest.capability.tools.list,
  },
  presentation = {
    ui = tool_card,
    group = "mcp",
    glyph = "resource",
    label = "Search MCP tools",
    summary_argument = "query",
    deferred_search = true,
  },
}, S.object(T.ToolSearchInput, {
  query = S.string(),
  limit = S.optional(S.integer({minimum = 1, maximum = 25})),
}), nil, function(arguments)
  if arguments.query == "" then error("query must be a non-empty string") end
  local catalog = tinest.result.unwrap(tinest.host.mcp.catalog_tools({}))
  local query = string.lower(arguments.query)
  local limit = math.max(1, math.min(arguments.limit or 8, 25))
  local refs, tools = {}, {}
  for _, descriptor in ipairs(catalog.tools or {}) do
    local searchable = string.lower(
      tostring(descriptor.server or "") .. " " ..
      tostring(descriptor.name or "") .. " " ..
      tostring(descriptor.title or "") .. " " ..
      tostring(descriptor.description or "")
    )
    if #refs < limit and string.find(searchable, query, 1, true) ~= nil then
      local name = "mcp__" .. tostring(descriptor.server) .. "__" ..
        tostring(descriptor.name)
      local ref = tinest.tool.dynamic_from(tool_bridge, {
        id = "mcp_" .. safe_id(descriptor.server) .. "_" .. safe_id(descriptor.name),
        name = name,
        description = descriptor.description or descriptor.title or name,
        kind = tinest.tool.kind.function_,
        input_schema = descriptor.inputSchema or {
          type = "object", properties = {}, additionalProperties = true,
        },
        output_schema = descriptor.outputSchema or {},
        presentation = {
          ui = tool_card,
          group = "mcp",
          glyph = "resource",
          label = descriptor.title or descriptor.name or name,
          approval_preview = tostring(descriptor.server) .. "." ..
            tostring(descriptor.name),
        },
      }, {server = descriptor.server, name = descriptor.name})
      refs[#refs + 1] = ref
      tools[#tools + 1] = {
        type = "function",
        name = name,
        description = descriptor.description or descriptor.title or name,
        parameters = descriptor.inputSchema or {},
        output_schema = descriptor.outputSchema,
      }
    end
  end
  tinest.tools.surface(refs)
  return {tools = tools}
end)

return tinest.plugin.define({
  tools = {
    list_resources,
    list_resource_templates,
    read_resource,
    tool_search,
  },
  templates = {tool_bridge},
  ui = {tool_card},
})
