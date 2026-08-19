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

local stopwords = {}
for _, word in ipairs({
  "a", "an", "and", "are", "as", "at", "be", "but", "by", "for",
  "from", "in", "into", "is", "it", "of", "on", "or", "that", "the",
  "this", "to", "with",
}) do
  stopwords[word] = true
end

local function tokenize(text)
  local terms = {}
  local buffer = ""
  local function flush()
    if buffer == "" then return end
    local term = string.lower(buffer)
    buffer = ""
    if #term >= 2 and not stopwords[term] then terms[#terms + 1] = term end
  end
  for index = 1, #text do
    local character = string.sub(text, index, index)
    local byte = string.byte(character)
    local upper = byte >= 65 and byte <= 90
    local lower = byte >= 97 and byte <= 122
    local digit = byte >= 48 and byte <= 57
    if not upper and not lower and not digit then
      flush()
    else
      if upper and buffer ~= "" then
        local previous = string.byte(string.sub(buffer, #buffer, #buffer))
        if previous >= 97 and previous <= 122 then flush() end
      end
      buffer = buffer .. character
    end
  end
  flush()
  return terms
end

local function search_document(descriptor)
  local terms = {}
  local function add(text)
    for _, term in ipairs(tokenize(tostring(text or ""))) do
      if #terms >= 2000 then return end
      terms[#terms + 1] = term
    end
  end
  local function walk(node, depth)
    if depth > 8 or #terms >= 2000 or type(node) ~= "table" then return end
    if type(node.description) == "string" then add(node.description) end
    if type(node.properties) == "table" then
      for name, child in pairs(node.properties) do
        add(name)
        walk(child, depth + 1)
      end
    end
    walk(node.items, depth + 1)
    walk(node.anyOf, depth + 1)
    walk(node.oneOf, depth + 1)
    for index, child in ipairs(node) do
      if index > 0 then walk(child, depth + 1) end
    end
  end
  add(descriptor.name)
  add(descriptor.description)
  walk(descriptor.input_schema, 0)
  return terms
end

local function rank(descriptors, query, limit)
  local query_terms = tokenize(query)
  if #query_terms == 0 then return {} end
  local documents = {}
  local counts = {}
  local total_length = 0
  for index, descriptor in ipairs(descriptors) do
    local terms = search_document(descriptor)
    local frequencies = {}
    for _, term in ipairs(terms) do
      frequencies[term] = (frequencies[term] or 0) + 1
    end
    for term, _ in pairs(frequencies) do counts[term] = (counts[term] or 0) + 1 end
    documents[index] = {descriptor = descriptor, frequencies = frequencies, length = #terms}
    total_length = total_length + #terms
  end
  local average = #documents == 0 and 0 or total_length / #documents
  local scored = {}
  for _, document in ipairs(documents) do
    local score = 0
    for _, term in ipairs(query_terms) do
      local frequency = document.frequencies[term]
      if frequency ~= nil then
        local count = counts[term] or 0
        local idf = math.log(1 + (#documents - count + 0.5) / (count + 0.5))
        local normalized = average == 0 and 0 or document.length / average
        score = score + idf * (frequency * 2.2) /
          (frequency + 1.2 * (0.25 + 0.75 * normalized))
      end
    end
    if score > 0 then
      scored[#scored + 1] = {descriptor = document.descriptor, score = score}
    end
  end
  table.sort(scored, function(left, right)
    if left.score ~= right.score then return left.score > right.score end
    return left.descriptor.name < right.descriptor.name
  end)
  local result = {}
  for index = 1, math.min(limit, #scored) do
    result[#result + 1] = scored[index].descriptor
  end
  return result
end

local function public_descriptor(descriptor)
  return {
    type = "function",
    canonical_name = descriptor.id,
    name = descriptor.name,
    description = descriptor.description,
    parameters = descriptor.input_schema,
    strict = true,
    output_schema = descriptor.output_schema,
  }
end

local tool_search = tinest.tool.deferred({
  id = "tool_search",
  name = "tool_search",
  description = "Search deferred tools selected by the Agent and surface matching contributions.",
  effects = {tinest.effect.tools.list},
  required_capabilities = {tinest.capability.tools.list},
  presentation = {
    ui = tool_card,
    group = "session",
    glyph = "tools",
    label = "Search tools",
    summary_argument = "query",
    deferred_search = true,
  },
}, S.object(T.ToolSearchInput, {
  query = S.string({
    description = "Desired capability in prose or keywords.",
  }),
  limit = S.optional(S.integer({minimum = 1})),
}), nil, function(arguments)
  if arguments.query == "" then error("query must be a non-empty string") end
  local deferred = {}
  for _, descriptor in ipairs(tinest.tools.list()) do
    if descriptor.exposure == tinest.tool.exposure.deferred and
        descriptor.surfaced ~= true then
      deferred[#deferred + 1] = descriptor
    end
  end
  local limit = math.max(1, math.min(arguments.limit or 8, 25))
  local matches = rank(deferred, arguments.query, limit)
  local refs = {}
  local tools = {}
  for _, descriptor in ipairs(matches) do
    refs[#refs + 1] = descriptor.ref
    tools[#tools + 1] = public_descriptor(descriptor)
  end
  tinest.tools.surface(refs)
  return {tools = tools}
end)

return tinest.plugin.define({tools = {tool_search}, ui = {tool_card}})
