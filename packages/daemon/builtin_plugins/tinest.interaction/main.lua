local tinest = require("tinest")
local S = tinest.schema
local T = require("tinest.types")

local option = S.object(T.QuestionOption, {
  label = S.string(),
  description = S.string(),
})
local question = S.object(T.UserQuestion, {
  id = S.string(),
  header = S.string(),
  question = S.string(),
  options = S.array(option),
})

local request_user_input = tinest.tool.function_({
  id = "request_user_input",
  name = "request_user_input",
  description = "Ask up to three structured questions and wait for answers.",
  uses = {tinest.host.interaction.request_user_input},
  effects = {tinest.effect.interaction.request},
  required_capabilities = {tinest.capability.interaction.request},
  presentation = {
    group = "session",
    glyph = "ask",
    label = "Request user input",
    timeline = "question",
  },
}, S.object(T.RequestUserInput, {
  questions = S.array(question),
}), nil, function(arguments)
  if #arguments.questions < 1 or #arguments.questions > 3 then
    error("Ask between 1 and 3 questions.")
  end
  local ids = {}
  for _, item in ipairs(arguments.questions) do
    if item.id == "" then error("Every question needs a non-empty id.") end
    if ids[item.id] then error("Duplicate question id " .. item.id .. ".") end
    ids[item.id] = true
    if #item.header < 1 or #item.header > 12 then
      error("Question headers must contain 1 to 12 characters.")
    end
    if item.question == "" then error("Question text cannot be empty.") end
    if #item.options < 2 or #item.options > 3 then
      error("Each question needs 2 to 3 options.")
    end
    for _, option in ipairs(item.options) do
      if option.label == "" then error("Option labels cannot be empty.") end
    end
  end
  local questions = {}
  for _, item in ipairs(arguments.questions) do
    local options = {}
    for _, item_option in ipairs(item.options) do
      options[#options + 1] = {
        label = item_option.label,
        description = item_option.description,
      }
    end
    questions[#questions + 1] = {
      id = item.id,
      header = item.header,
      question = item.question,
      options = options,
    }
  end
  return tinest.result.unwrap(
    tinest.host.interaction.request_user_input({questions = questions})
  )
end)

return tinest.plugin.define({tools = {request_user_input}})
