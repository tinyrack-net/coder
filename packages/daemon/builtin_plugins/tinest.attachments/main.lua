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

local attach_file = tinest.tool.function_({
  id = "attach_file",
  name = "attach_file",
  description = "Attach a regular workspace file to the conversation.",
  uses = {tinest.host.attachment.publish},
  effects = {
    tinest.effect.filesystem.read,
    tinest.effect.attachment.write,
  },
  required_capabilities = {
    tinest.capability.workspace.read,
    tinest.capability.attachment.publish,
  },
  presentation = {
    group = "attachments",
    glyph = "read",
    label = "Attach file",
    summary_argument = "path",
    timeline = "suppressed",
  },
}, S.object(T.AttachFileInput, {path = S.string()}), nil, function(arguments)
  return tinest.result.unwrap(tinest.host.attachment.publish({
    path = arguments.path,
  }))
end)

local read_attachment = tinest.tool.function_({
  id = "read_attachment",
  name = "read_attachment",
  description = "Read validated metadata for a session-owned attachment.",
  uses = {tinest.host.attachment.read},
  effects = {tinest.effect.attachment.read},
  required_capabilities = {tinest.capability.attachment.read},
  presentation = {
    ui = tool_card,
    group = "attachments",
    glyph = "read",
    label = "Read attachment",
    summary_argument = "id",
  },
}, S.object(T.ReadAttachmentInput, {id = S.string()}), nil, function(arguments)
  return tinest.result.unwrap(tinest.host.attachment.read({
    id = arguments.id,
  }))
end)

return tinest.plugin.define({
  tools = {attach_file, read_attachment},
  ui = {tool_card},
})
