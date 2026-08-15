local gitignore = {}

local function normalize(path)
  local value = tostring(path or ""):gsub("\\\\", "/")
  value = value:gsub("^%./", ""):gsub("/+$", "")
  if value == "." then return "" end
  return value
end

local function strip_trailing_spaces(line)
  local finish = #line
  while finish > 0 do
    local char = line:sub(finish, finish)
    if char ~= " " and char ~= "\t" then break end
    local backslashes = 0
    local cursor = finish - 1
    while cursor > 0 and line:sub(cursor, cursor) == "\\" do
      backslashes = backslashes + 1
      cursor = cursor - 1
    end
    if backslashes % 2 == 1 then break end
    finish = finish - 1
  end
  return line:sub(1, finish)
end

local function class_end(pattern, start)
  local cursor = start + 1
  local first = pattern:sub(cursor, cursor)
  if first == "!" or first == "^" then cursor = cursor + 1 end
  if pattern:sub(cursor, cursor) == "]" then cursor = cursor + 1 end
  while cursor <= #pattern do
    local char = pattern:sub(cursor, cursor)
    if char == "\\" then
      cursor = cursor + 2
    elseif char == "]" then
      return cursor
    else
      cursor = cursor + 1
    end
  end
  return nil
end

local function parse_class(pattern, start, finish)
  local cursor = start + 1
  local first = pattern:sub(cursor, cursor)
  local negated = first == "!" or first == "^"
  if negated then cursor = cursor + 1 end
  local characters = {}
  while cursor < finish do
    local char = pattern:sub(cursor, cursor)
    if char == "\\" and cursor + 1 < finish then
      cursor = cursor + 1
      char = pattern:sub(cursor, cursor)
    end
    characters[#characters + 1] = char
    cursor = cursor + 1
  end
  return {kind = "class", negated = negated, characters = characters}
end

local function tokenize(pattern)
  local tokens = {}
  local cursor = 1
  while cursor <= #pattern do
    local char = pattern:sub(cursor, cursor)
    if char == "\\" then
      if cursor < #pattern then
        cursor = cursor + 1
        char = pattern:sub(cursor, cursor)
      end
      tokens[#tokens + 1] = {kind = "literal", value = char}
      cursor = cursor + 1
    elseif char == "*" then
      local double = pattern:sub(cursor + 1, cursor + 1) == "*"
      if double and cursor + 1 == #pattern then
        tokens[#tokens + 1] = {kind = "double_star_end"}
        cursor = cursor + 2
      elseif double and pattern:sub(cursor + 2, cursor + 2) == "/" then
        tokens[#tokens + 1] = {kind = "double_star_directories"}
        cursor = cursor + 3
      else
        tokens[#tokens + 1] = {kind = "star"}
        cursor = cursor + (double and 2 or 1)
      end
    elseif char == "?" then
      tokens[#tokens + 1] = {kind = "question"}
      cursor = cursor + 1
    elseif char == "[" then
      local finish = class_end(pattern, cursor)
      if finish == nil then
        tokens[#tokens + 1] = {kind = "literal", value = char}
        cursor = cursor + 1
      else
        tokens[#tokens + 1] = parse_class(pattern, cursor, finish)
        cursor = finish + 1
      end
    else
      tokens[#tokens + 1] = {kind = "literal", value = char}
      cursor = cursor + 1
    end
  end
  return tokens
end

local function class_contains(token, char)
  if char == "" or char == "/" then return false end
  local matched = false
  local cursor = 1
  while cursor <= #token.characters do
    local first = token.characters[cursor]
    if cursor + 2 <= #token.characters and
        token.characters[cursor + 1] == "-" then
      local last = token.characters[cursor + 2]
      if first <= char and char <= last then matched = true end
      cursor = cursor + 3
    else
      if first == char then matched = true end
      cursor = cursor + 1
    end
  end
  return token.negated and not matched or (not token.negated and matched)
end

local function tokens_match(tokens, path)
  local memo = {}
  local function visit(token_index, path_index)
    local key = token_index .. ":" .. path_index
    if memo[key] ~= nil then return memo[key] end
    local token = tokens[token_index]
    if token == nil then
      local complete = path_index > #path
      memo[key] = complete
      return complete
    end

    local matched = false
    if token.kind == "literal" then
      matched = path:sub(path_index, path_index) == token.value and
        visit(token_index + 1, path_index + 1)
    elseif token.kind == "question" then
      local char = path:sub(path_index, path_index)
      matched = char ~= "" and char ~= "/" and
        visit(token_index + 1, path_index + 1)
    elseif token.kind == "class" then
      matched = class_contains(token, path:sub(path_index, path_index)) and
        visit(token_index + 1, path_index + 1)
    elseif token.kind == "star" then
      matched = visit(token_index + 1, path_index)
      local cursor = path_index
      while not matched and cursor <= #path and
          path:sub(cursor, cursor) ~= "/" do
        cursor = cursor + 1
        matched = visit(token_index + 1, cursor)
      end
    elseif token.kind == "double_star_directories" then
      matched = visit(token_index + 1, path_index)
      local cursor = path_index
      while not matched do
        local slash = path:find("/", cursor, true)
        if slash == nil then break end
        matched = visit(token_index + 1, slash + 1)
        cursor = slash + 1
      end
    elseif token.kind == "double_star_end" then
      matched = true
    end
    memo[key] = matched
    return matched
  end
  return visit(1, 1)
end

local function compile_pattern(body)
  local anchored = body:sub(1, math.max(0, #body - 1)):find("/", 1, true) ~= nil
  if body:sub(1, 1) == "/" then body = body:sub(2) end
  return {anchored = anchored, tokens = tokenize(body)}
end

local function pattern_matches(pattern, path)
  if pattern.anchored then return tokens_match(pattern.tokens, path) end
  if tokens_match(pattern.tokens, path) then return true end
  local cursor = 1
  while true do
    local slash = path:find("/", cursor, true)
    if slash == nil then return false end
    if tokens_match(pattern.tokens, path:sub(slash + 1)) then return true end
    cursor = slash + 1
  end
end

local function parse_pattern(raw)
  local body = strip_trailing_spaces(raw:gsub("\r$", ""))
  if body == "" or body:sub(1, 1) == "#" then return nil end
  if body:sub(1, 2) == "\\#" then body = body:sub(2) end

  local negated = false
  if body:sub(1, 1) == "!" then
    negated = true
    body = body:sub(2)
  elseif body:sub(1, 2) == "\\!" then
    body = body:sub(2)
  end
  if body == "" then return nil end

  local directory_only = false
  if body:sub(-1) == "/" and body:sub(-2) ~= "\\/" then
    directory_only = true
    body = body:sub(1, -2)
  end
  if body == "" then return nil end
  return {
    negated = negated,
    directory_only = directory_only,
    compiled = compile_pattern(body),
  }
end

local function parse_source(base_path, contents, precedence)
  local patterns = {}
  for line in (contents .. "\n"):gmatch("(.-)\n") do
    local pattern = parse_pattern(line)
    if pattern ~= nil then patterns[#patterns + 1] = pattern end
  end
  return {
    base_path = normalize(base_path),
    patterns = patterns,
    precedence = precedence,
  }
end

local function scoped_path(source, path)
  if source.base_path == "" then return path end
  local prefix = source.base_path .. "/"
  if path:sub(1, #prefix) ~= prefix then return nil end
  return path:sub(#prefix + 1)
end

local function source_verdict(source, path, is_directory)
  local scoped = scoped_path(source, path)
  if scoped == nil then return nil end
  local decision = nil
  for _, pattern in ipairs(source.patterns) do
    if (not pattern.directory_only or is_directory) and
        pattern_matches(pattern.compiled, scoped) then
      decision = not pattern.negated
    end
  end
  return decision
end

local function is_ignored(sources, path, is_directory)
  local ignored = false
  for _, source in ipairs(sources) do
    local verdict = source_verdict(source, path, is_directory)
    if verdict ~= nil then ignored = verdict end
  end
  return ignored
end

local function safe_read(read_text, path)
  local ok, contents = pcall(read_text, path)
  if not ok or type(contents) ~= "string" then return nil end
  return contents
end

local function depth(path)
  if path == "" then return 0 end
  local count = 1
  for _ in path:gmatch("/") do count = count + 1 end
  return count
end

function gitignore.sources(entries, read_text, start_path)
  local sources = {}
  local loaded = {}
  local function add(path, base_path, precedence)
    path = normalize(path)
    if loaded[path] then return end
    loaded[path] = true
    local contents = safe_read(read_text, path)
    if contents ~= nil then
      sources[#sources + 1] = parse_source(base_path, contents, precedence)
    end
  end

  add(".git/info/exclude", "", -1)
  add(".gitignore", "", 0)

  local start = normalize(start_path)
  local ancestor = ""
  for segment in start:gmatch("[^/]+") do
    ancestor = ancestor == "" and segment or ancestor .. "/" .. segment
    add(ancestor .. "/.gitignore", ancestor, depth(ancestor))
  end

  for _, entry in ipairs(entries or {}) do
    local path = normalize(entry.path or entry.name)
    if path == ".gitignore" then
      add(path, "", 0)
    elseif path:sub(-11) == "/.gitignore" and
        path:sub(1, 5) ~= ".git/" and
        not path:find("/.git/", 1, true) then
      local base_path = path:sub(1, -12)
      add(path, base_path, depth(base_path))
    end
  end

  table.sort(sources, function(left, right)
    if left.precedence ~= right.precedence then
      return left.precedence < right.precedence
    end
    return left.base_path < right.base_path
  end)
  return sources
end

local function is_git_metadata(path)
  return path == ".git" or path:sub(1, 5) == ".git/" or
    path:find("/.git/", 1, true) ~= nil or path:sub(-5) == "/.git"
end

function gitignore.is_visible(sources, raw_path, is_directory, include_ignored)
  local path = normalize(raw_path)
  if path == "" or is_git_metadata(path) then return false end
  if include_ignored then return true end

  local segments = {}
  for segment in path:gmatch("[^/]+") do segments[#segments + 1] = segment end
  local ancestor = ""
  local ancestor_count = is_directory and #segments or #segments - 1
  for index = 1, ancestor_count do
    ancestor = ancestor == "" and segments[index] or
      ancestor .. "/" .. segments[index]
    if is_ignored(sources, ancestor, true) then return false end
  end
  if is_directory then return true end
  return not is_ignored(sources, path, false)
end

function gitignore.glob_matches(pattern, path)
  return pattern_matches({anchored = true, tokens = tokenize(pattern)}, path)
end

function gitignore.relative_to(path, base_path)
  local normalized_path = normalize(path)
  local base = normalize(base_path)
  if base == "" then return normalized_path end
  local prefix = base .. "/"
  if normalized_path:sub(1, #prefix) ~= prefix then return nil end
  return normalized_path:sub(#prefix + 1)
end

return gitignore
