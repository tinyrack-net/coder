local tinest = require("tinest")
local S = tinest.schema

local tool_card = tinest.ui.contribution({
  id = "tool",
  slot = tinest.ui.slot.timeline,
  metadata = {snapshot = true},
}, S.any(), function(arguments)
  return tinest.ui.tool_document(arguments)
end)

local function starts_with(value, prefix)
  return string.sub(value, 1, #prefix) == prefix
end

local function lines(source)
  source = string.gsub(source, "\r\n", "\n")
  local result = {}
  local from = 1
  while true do
    local at = string.find(source, "\n", from, true)
    if at == nil then
      result[#result + 1] = string.sub(source, from)
      return result
    end
    result[#result + 1] = string.sub(source, from, at - 1)
    from = at + 1
  end
end

local function parse(source)
  local input = lines(source)
  if input[1] ~= "*** Begin Patch" then
    error("Patch must start with *** Begin Patch.")
  end
  local operations = {}
  local index = 2
  while index <= #input and input[index] ~= "*** End Patch" do
    local header = input[index]
    if starts_with(header, "*** Add File: ") then
      local path = string.match(
        string.sub(header, #"*** Add File: " + 1), "^%s*(.-)%s*$"
      )
      index = index + 1
      local content = {}
      while index <= #input and not starts_with(input[index], "*** ") do
        if not starts_with(input[index], "+") then
          error("Add-file lines must start with +: " .. input[index])
        end
        content[#content + 1] = string.sub(input[index], 2)
        index = index + 1
      end
      operations[#operations + 1] = {
        kind = "add", path = path, content = table.concat(content, "\n"),
      }
    elseif starts_with(header, "*** Delete File: ") then
      operations[#operations + 1] = {
        kind = "delete",
        path = string.match(
          string.sub(header, #"*** Delete File: " + 1), "^%s*(.-)%s*$"
        ),
      }
      index = index + 1
    elseif starts_with(header, "*** Update File: ") then
      local operation = {
        kind = "update",
        path = string.match(
          string.sub(header, #"*** Update File: " + 1), "^%s*(.-)%s*$"
        ),
        chunks = {},
      }
      index = index + 1
      if index <= #input and starts_with(input[index], "*** Move to: ") then
        operation.move_to = string.match(
          string.sub(input[index], #"*** Move to: " + 1), "^%s*(.-)%s*$"
        )
        index = index + 1
      end
      while index <= #input and not starts_with(input[index], "*** ") do
        if not starts_with(input[index], "@@") then
          error("Expected an @@ update section.")
        end
        index = index + 1
        local body = {}
        while index <= #input and not starts_with(input[index], "@@") and
            not starts_with(input[index], "*** ") do
          local line = input[index]
          if line == "" and index == #input then break end
          local marker = string.sub(line, 1, 1)
          if line == "" or (marker ~= " " and marker ~= "+" and marker ~= "-") then
            error("Invalid update line: " .. line)
          end
          body[#body + 1] = line
          index = index + 1
        end
        operation.chunks[#operation.chunks + 1] = body
      end
      if #operation.chunks == 0 and operation.move_to == nil then
        error("Update for " .. operation.path .. " contains no sections.")
      end
      operations[#operations + 1] = operation
    else
      error("Unknown patch operation: " .. header)
    end
  end
  if index > #input or input[index] ~= "*** End Patch" then
    error("Patch must end with *** End Patch.")
  end
  if #operations == 0 then error("Patch contains no operations.") end
  for trailing = index + 1, #input do
    if input[trailing] ~= "" then
      error("Unexpected content after *** End Patch.")
    end
  end
  return operations
end

local function read_text(path)
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

local function find(source, pattern, start)
  if #pattern == 0 then return start end
  for at = start, #source - #pattern + 1 do
    local matched = true
    for offset = 1, #pattern do
      if source[at + offset - 1] ~= pattern[offset] then
        matched = false
        break
      end
    end
    if matched then return at end
  end
  return nil
end

local function apply_chunks(operation, original)
  local source = lines(original)
  if source[#source] == "" then table.remove(source) end
  local search_from = 1
  for _, chunk in ipairs(operation.chunks) do
    local before = {}
    local after = {}
    for _, line in ipairs(chunk) do
      local marker = string.sub(line, 1, 1)
      if marker == " " or marker == "-" then
        before[#before + 1] = string.sub(line, 2)
      end
      if marker == " " or marker == "+" then
        after[#after + 1] = string.sub(line, 2)
      end
    end
    local at = find(source, before, search_from)
    if at == nil then
      error("Patch context mismatch in " .. operation.path .. ".")
    end
    for _ = 1, #before do table.remove(source, at) end
    for offset, line in ipairs(after) do
      table.insert(source, at + offset - 1, line)
    end
    search_from = at + #after
  end
  return table.concat(source, "\n") .. "\n"
end

local function exists(path)
  local ok, value = pcall(function()
    return tinest.result.unwrap(
      tinest.host.workspace.stat({path = path})
    )
  end)
  return ok and value or nil
end

local function plan_patch(source)
  local changes = {}
  for _, operation in ipairs(parse(source)) do
    if operation.kind == "add" then
      if exists(operation.path) ~= nil then
        error("Cannot add an existing file: " .. operation.path)
      end
      changes[#changes + 1] = {
        kind = "write",
        path = operation.path,
        content = operation.content == "" and "" or operation.content .. "\n",
      }
    elseif operation.kind == "delete" then
      if exists(operation.path) == nil then
        error("Cannot delete a missing file: " .. operation.path)
      end
      changes[#changes + 1] = {kind = "delete", path = operation.path}
    else
      if exists(operation.path) == nil then
        error("Cannot update a missing file: " .. operation.path)
      end
      local original = read_text(operation.path)
      local content = apply_chunks(operation, original)
      changes[#changes + 1] = {
        kind = "write", path = operation.path, content = content,
      }
      if operation.move_to ~= nil then
        if exists(operation.move_to) ~= nil then
          error("Cannot move onto an existing file: " .. operation.move_to)
        end
        changes[#changes + 1] = {
          kind = "move", from = operation.path, to = operation.move_to,
        }
      end
    end
  end
  return changes
end

local apply_patch = tinest.tool.freeform({
  id = "apply_patch",
  name = "apply_patch",
  description = tinest.assets.read("prompts/apply_patch.md"),
  uses = {
    tinest.host.workspace.stat,
    tinest.host.workspace.read_text,
    tinest.host.workspace.transaction,
  },
  effects = {tinest.effect.filesystem.write},
  required_capabilities = {tinest.capability.workspace.patch},
  presentation = {
    ui = tool_card,
    group = "editing",
    glyph = "edit",
    label = "Apply patch",
    format = {
      type = "grammar",
      syntax = "lark",
      definition = "start: patch\npatch: /(.|\\n)+/",
    },
  },
}, S.string(), nil, function(source)
  local operations = plan_patch(source)
  local result = tinest.result.unwrap(
    tinest.host.workspace.transaction({operations = operations})
  )
  return {
    output = tostring(#operations) .. " filesystem operations applied.",
    structured_content = {
      changed_files = #parse(source),
      applied = result.applied,
    },
  }
end)

return tinest.plugin.define({tools = {apply_patch}, ui = {tool_card}})
