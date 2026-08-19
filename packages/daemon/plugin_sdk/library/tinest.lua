---@meta tinest

local runtime_host_key = string.char(104, 111, 115, 116)
local runtime_assets_key = string.char(97, 115, 115, 101, 116, 115)
local runtime_tools_key = string.char(116, 111, 111, 108, 115)
local runtime_store_key = string.char(115, 116, 111, 114, 101)
local runtime_load_key = string.char(108, 111, 97, 100)
local runtime_all_tools_key = string.char(
  65, 76, 76, 95, 84, 79, 79, 76, 83
)
local runtime_spawn_key = string.char(115, 112, 97, 119, 110)
local runtime_await_key = string.char(97, 119, 97, 105, 116)
local runtime_await_all_key = string.char(97, 119, 97, 105, 116, 95, 97, 108, 108)
local runtime_text_key = string.char(116, 101, 120, 116)
local runtime_image_key = string.char(105, 109, 97, 103, 101)
local runtime_audio_key = string.char(97, 117, 100, 105, 111)
local runtime_generated_image_key = string.char(
  103, 101, 110, 101, 114, 97, 116, 101, 100, 95, 105, 109, 97, 103, 101
)
local runtime_notify_key = string.char(110, 111, 116, 105, 102, 121)
local runtime_yield_control_key = string.char(
  121, 105, 101, 108, 100, 95, 99, 111, 110, 116, 114, 111, 108
)
local runtime_exit_key = string.char(101, 120, 105, 116)
local runtime_set_timeout_key = string.char(
  115, 101, 116, 95, 116, 105, 109, 101, 111, 117, 116
)
local runtime_clear_timeout_key = string.char(
  99, 108, 101, 97, 114, 95, 116, 105, 109, 101, 111, 117, 116
)
local runtime_global_environment_key = string.char(95, 71)
local runtime_json_null_key = string.char(78, 85, 76, 76)
local runtime_host = _ENV[runtime_host_key]
local runtime_assets = _ENV[runtime_assets_key]
local runtime_json_null = _ENV[runtime_json_null_key]
for _, key in ipairs({
  runtime_host_key,
  runtime_assets_key,
  runtime_tools_key,
  runtime_store_key,
  runtime_load_key,
  runtime_all_tools_key,
  runtime_spawn_key,
  runtime_await_key,
  runtime_await_all_key,
  runtime_text_key,
  runtime_image_key,
  runtime_audio_key,
  runtime_generated_image_key,
  runtime_notify_key,
  runtime_yield_control_key,
  runtime_exit_key,
  runtime_set_timeout_key,
  runtime_clear_timeout_key,
  runtime_global_environment_key,
  runtime_json_null_key,
}) do
  _ENV[key] = nil
end
local plugin_identity = nil
local definition_created = false
local references = {}
local bound_handlers = {}
local private_reference_id = 0
local active_dynamic_token = nil
local type_tokens_installed = false

local function fail(message, level)
  error(message, (level or 1) + 1)
end

local function expect_table(value, label, level)
  if type(value) ~= "table" or value == runtime_json_null then
    fail(label .. " must be a table", level or 2)
  end
  return value
end

local function expect_id(value, label, level)
  if type(value) ~= "string" or
      not value:match("^[a-z][a-z0-9_-]*$") then
    fail(label .. " must be a lowercase local ID", level or 2)
  end
  return value
end

local function sorted_set(values, label)
  if values == nil then return {} end
  expect_table(values, label, 3)
  local seen, result = {}, {}
  for index, value in ipairs(values) do
    if type(value) ~= "string" or value == "" then
      fail(label .. "[" .. index .. "] must be a non-empty string", 3)
    end
    if seen[value] then fail(label .. " contains duplicate " .. value, 3) end
    seen[value] = true
    result[#result + 1] = value
  end
  table.sort(result)
  return result
end

local function union(left, right)
  local seen, result = {}, {}
  for _, values in ipairs({left or {}, right or {}}) do
    for _, value in ipairs(values) do
      if not seen[value] then
        seen[value] = true
        result[#result + 1] = value
      end
    end
  end
  table.sort(result)
  return result
end

local function make_ref(metadata, methods)
  private_reference_id = private_reference_id + 1
  metadata.private_id = private_reference_id
  local value = {__tinest_opaque = function() end}
  references[value] = metadata
  for key, item in pairs(methods or {}) do value[key] = item end
  return value
end

local function require_ref(value, kind, label, level)
  local metadata = references[value]
  if metadata == nil or (kind ~= nil and metadata.kind ~= kind) then
    fail(label .. " must be a Tinest " .. (kind or "reference"), level or 2)
  end
  return metadata
end

local function copy_json(value, seen)
  if value == runtime_json_null then return value end
  local metadata = references[value]
  if metadata ~= nil then
    fail("Tinest references are not JSON-compatible", 3)
  end
  local kind = type(value)
  if kind == "nil" or kind == "boolean" or kind == "string" or
      kind == "number" then return value end
  if kind ~= "table" then fail(kind .. " is not JSON-compatible", 3) end
  seen = seen or {}
  if seen[value] then fail("cyclic values are not JSON-compatible", 3) end
  seen[value] = true
  local result = {}
  for key, item in pairs(value) do
    if type(key) ~= "string" and type(key) ~= "number" then
      fail("JSON-compatible table keys must be strings or array indices", 3)
    end
    result[key] = copy_json(item, seen)
  end
  seen[value] = nil
  return result
end

local function copy_registration(value, seen)
  if value == runtime_json_null then return value end
  local metadata = references[value]
  if metadata ~= nil then
    if metadata.kind ~= "ui" and metadata.kind ~= "action" and
        metadata.kind ~= "tool" then
      fail("this Tinest reference is not valid registration metadata", 3)
    end
    return {__tinest_ref = metadata.kind, id = metadata.id}
  end
  local kind = type(value)
  if kind == "nil" or kind == "boolean" or kind == "string" or
      kind == "number" then return value end
  if kind ~= "table" then fail(kind .. " is not registration metadata", 3) end
  seen = seen or {}
  if seen[value] then fail("cyclic registration metadata is invalid", 3) end
  seen[value] = true
  local result = {}
  for key, item in pairs(value) do
    if type(key) ~= "string" and type(key) ~= "number" then
      fail("registration metadata keys must be strings or array indices", 3)
    end
    result[key] = copy_registration(item, seen)
  end
  seen[value] = nil
  return result
end

local function reject_reference_result(value, seen)
  if references[value] ~= nil then
    fail("Tinest references cannot be returned or persisted", 3)
  end
  if type(value) ~= "table" then return end
  seen = seen or {}
  if seen[value] then return end
  seen[value] = true
  for key, item in pairs(value) do
    reject_reference_result(key, seen)
    reject_reference_result(item, seen)
  end
end

local function error_message(result)
  local value = type(result) == "table" and
    (result.error or result.value or result.output or result.message) or result
  if type(value) == "table" then
    value = value.message or value.code or value.output or value.value
  end
  if type(value) == "table" or value == nil then return "Tinest host call failed" end
  return tostring(value)
end

local function checked_call(name, arguments)
  local result = runtime_host.call(name, arguments or {})
  if type(result) == "table" and
      (result.ok == false or result.is_error == true) then
    fail(error_message(result), 2)
  end
  if type(result) == "table" and result.ok == true then return result.value end
  -- The native Lua host adds opaque resource descriptors beside the original
  -- value. They are tracked out-of-band by the host and must not change the
  -- public result shape observed by typed plugin code.
  if type(result) == "table" and result.is_error == false and
      type(result.attachments) == "table" then
    return result.value
  end
  return result
end

---@class (exact) tinest.ToolExecutionContext
---@field window_tokens? integer
---@field usage tinest.ModelUsage
---@field used_tokens integer
---@field remaining_tokens? integer

---@class (exact) tinest.ToolContext
---@field call_id? string
---@field context? tinest.ToolExecutionContext
---@field settings? table<string, any>

---@class tinest.HostError
---@field code string
---@field message string
---@field retryable boolean
---@field details? any

---@class tinest.HostSuccess<T>
---@field ok true
---@field value T

---@class tinest.HostFailure
---@field ok false
---@field error tinest.HostError

---@alias tinest.HostResult<T> tinest.HostSuccess<T>|tinest.HostFailure

---@class (exact) tinest.WorkspaceStatInput
---@field path string

---@alias tinest.WorkspaceEntityType 'file'|'directory'|'link'|'other'

---@class (exact) tinest.WorkspaceStatOutput
---@field path string
---@field type tinest.WorkspaceEntityType
---@field size_bytes integer
---@field modified_at string

---@class (exact) tinest.WorkspaceListInput
---@field path string

---@class (exact) tinest.WorkspaceListEntry
---@field name string
---@field path string
---@field type tinest.WorkspaceEntityType
---@field size_bytes? integer

---@class (exact) tinest.WorkspaceListOutput
---@field entries tinest.WorkspaceListEntry[]

---@class (exact) tinest.WorkspaceReadTextInput
---@field path string
---@field offset? integer
---@field limit? integer

---@class (exact) tinest.WorkspaceReadTextOutput
---@field text string
---@field offset integer
---@field next_offset? integer
---@field total_lines integer
---@field eof boolean

---@class (exact) tinest.WorkspaceReadBlobInput
---@field path string
---@field image_detail? 'high'|'original'

---@class (exact) tinest.WorkspaceReadBlobOutput
---@field path string
---@field mime_type string
---@field byte_size integer

---@class (exact) tinest.WorkspaceWalkInput
---@field path? string

---@class (exact) tinest.WorkspaceWalkEntry
---@field path string
---@field type tinest.WorkspaceEntityType
---@field size_bytes? integer

---@class (exact) tinest.WorkspaceWalkOutput
---@field entries tinest.WorkspaceWalkEntry[]
---@field truncated boolean

---@class (exact) tinest.WorkspaceMutation
---@field kind 'write'|'delete'
---@field path string
---@field content? string
---@field expected_sha256? string

---@class (exact) tinest.WorkspaceTransactionInput
---@field operations tinest.WorkspaceMutation[]

---@class (exact) tinest.WorkspaceAppliedMutation
---@field kind 'write'|'delete'
---@field path string

---@class (exact) tinest.WorkspaceTransactionOutput
---@field applied tinest.WorkspaceAppliedMutation[]

---@class (exact) tinest.NetworkRequestInput
---@field url string
---@field method? string
---@field headers? table<string, string>
---@field body? string
---@field body_base64? string
---@field timeout_ms? integer
---@field max_response_bytes? integer

---@class (exact) tinest.NetworkResponse
---@field status integer
---@field headers table<string, string[]>
---@field body_base64 string
---@field body? string

---@class (exact) tinest.SecretGetInput
---@field name string

---@class (exact) tinest.SecretValue
---@field found true
---@field value string

---@class (exact) tinest.SecretMissing
---@field found false

---@alias tinest.SecretEnvelope tinest.SecretValue|tinest.SecretMissing

---@class (exact) tinest.ProcessStartInput
---@field command string
---@field workdir? string
---@field tty? boolean
---@field shell? string
---@field login? boolean

---@class (exact) tinest.ProcessHandle
---@field handle integer

---@class (exact) tinest.ProcessReadInput
---@field handle integer
---@field yield_time_ms? integer

---@class (exact) tinest.ProcessReadOutput
---@field output string
---@field running boolean
---@field exit_code? integer
---@field wall_time_ms integer

---@class (exact) tinest.ProcessWriteInput
---@field handle integer
---@field chars string

---@class (exact) tinest.ProcessWrittenOutput
---@field written true

---@class (exact) tinest.ProcessInterruptedOutput
---@field interrupted true

---@class (exact) tinest.ProcessTerminatedOutput
---@field terminated true

---@class (exact) tinest.AttachmentPublishInput
---@field path string

---@class (exact) tinest.AttachmentReadInput
---@field id string

---@class (exact) tinest.AttachmentEnvelope
---@field id string
---@field file_name string
---@field mime_type string
---@field byte_size integer
---@field sha256? string

---@class (exact) tinest.InteractionOption
---@field label string
---@field description string

---@class (exact) tinest.InteractionQuestion
---@field id string
---@field header string
---@field question string
---@field options tinest.InteractionOption[]

---@class (exact) tinest.InteractionRequestInput
---@field questions tinest.InteractionQuestion[]

---@class (exact) tinest.InteractionAnswer
---@field question_id string
---@field answer string
---@field free_form boolean

---@class (exact) tinest.InteractionRequestOutput
---@field answers tinest.InteractionAnswer[]

---@class (exact) tinest.ClockCurrentTimeInput

---@class (exact) tinest.ClockCurrentTimeOutput
---@field utc string

---@class (exact) tinest.ClockSleepInput
---@field duration_ms integer

---@class (exact) tinest.ClockSleepOutput
---@field outcome 'elapsed'|'interrupted'
---@field elapsed_ms integer

---@class (exact) tinest.SkillListInput

---@class (exact) tinest.SkillSummary
---@field name string
---@field description string

---@class (exact) tinest.ImplicitSkillDocument
---@field name string
---@field instructions string

---@class (exact) tinest.SkillListOutput
---@field skills tinest.SkillSummary[]
---@field implicit_skills tinest.ImplicitSkillDocument[]

---@class (exact) tinest.SkillReadInput
---@field name string
---@field resource? string

---@class (exact) tinest.SkillResource
---@field path string
---@field size_bytes integer

---@class (exact) tinest.SkillDocumentOutput
---@field name string
---@field description string
---@field instructions string
---@field resources tinest.SkillResource[]

---@class (exact) tinest.SkillResourceOutput
---@field name string
---@field resource string
---@field contents string

---@alias tinest.SkillReadOutput tinest.SkillDocumentOutput|tinest.SkillResourceOutput

---@class (exact) tinest.McpPageInput
---@field server? string
---@field cursor? string

---@class (exact) tinest.McpReadResourceInput
---@field server string
---@field uri string

---@class (exact) tinest.McpCatalogToolsInput
---@field server? string

---@class (exact) tinest.McpInvokeToolInput
---@field server string
---@field name string
---@field arguments table<string, any>

---@class (exact) tinest.McpResource
---@field server string
---@field uri string
---@field name? string
---@field title? string
---@field description? string
---@field mimeType? string
---@field size? integer
---@field annotations? table<string, any>
---@field _meta? table<string, any>

---@class (exact) tinest.McpListResourcesOutput
---@field resources tinest.McpResource[]
---@field nextCursor? string

---@class (exact) tinest.McpResourceTemplate
---@field server string
---@field uriTemplate string
---@field name? string
---@field title? string
---@field description? string
---@field mimeType? string
---@field annotations? table<string, any>
---@field _meta? table<string, any>

---@class (exact) tinest.McpListResourceTemplatesOutput
---@field resourceTemplates tinest.McpResourceTemplate[]
---@field nextCursor? string

---@class (exact) tinest.McpResourceContents
---@field uri string
---@field mimeType? string
---@field text? string
---@field blob? string
---@field _meta? table<string, any>

---@class (exact) tinest.McpReadResourceOutput
---@field contents tinest.McpResourceContents[]

---@class (exact) tinest.McpTool
---@field server string
---@field name string
---@field title? string
---@field description? string
---@field inputSchema? table<string, any>
---@field outputSchema? table<string, any>
---@field annotations? table<string, any>

---@class (exact) tinest.McpCatalogToolsOutput
---@field tools tinest.McpTool[]

---@class (exact) tinest.McpInvokeToolOutput
---@field content table[]
---@field structuredContent? any
---@field isError boolean
---@field _meta? table<string, any>

---@class (exact) tinest.CollaborationTargetInput
---@field target string

---@class (exact) tinest.CollaborationMessageInput: tinest.CollaborationTargetInput
---@field message string

---@class (exact) tinest.CollaborationSpawnInput
---@field task_name string
---@field message string
---@field agent_type? string
---@field fork_turns? string
---@field model? string
---@field reasoning_effort? string
---@field service_tier? string

---@class (exact) tinest.CollaborationWaitInput
---@field timeout_ms? number

---@class (exact) tinest.CollaborationListInput
---@field path_prefix? string

---@class (exact) tinest.CollaborationSpawnOutput
---@field task_name string

---@class (exact) tinest.CollaborationQueuedOutput
---@field queued true

---@class (exact) tinest.CollaborationFollowupOutput
---@field delivery 'triggered'|'queued'

---@class (exact) tinest.CollaborationWaitOutput
---@field outcome string
---@field timed_out boolean

---@alias tinest.CollaborationAgentStatus 'pending_init'|'running'|'interrupted'|'completed'|'errored'

---@class (exact) tinest.CollaborationInterruptOutput
---@field previous_status tinest.CollaborationAgentStatus

---@class (exact) tinest.CollaborationAgent
---@field agent_name string
---@field agent_status tinest.CollaborationAgentStatus

---@class (exact) tinest.CollaborationListOutput
---@field agents tinest.CollaborationAgent[]

---@class (exact) tinest.LuaStartInput
---@field source string
---@field tools? tinest.ToolRef<any, any>[]
---@field yield_time_ms? integer
---@field max_output_tokens? integer

---@class (exact) tinest.LuaReadInput
---@field handle string
---@field yield_time_ms? integer
---@field max_output_tokens? integer

---@class (exact) tinest.LuaTerminateInput
---@field handle string
---@field yield_time_ms? integer
---@field max_output_tokens? integer

---@class (exact) tinest.LuaChunkOutput
---@field handle string
---@field output string
---@field running boolean
---@field terminated boolean
---@field error? string

---@class (exact) tinest.HostApi
---@field workspace tinest.HostWorkspaceApi
---@field process tinest.HostProcessApi
---@field attachment tinest.HostAttachmentApi
---@field interaction tinest.HostInteractionApi
---@field mcp tinest.HostMcpApi
---@field collaboration tinest.HostCollaborationApi
---@field clock tinest.HostClockApi
---@field skills tinest.HostSkillsApi
---@field network tinest.HostNetworkApi
---@field secret tinest.HostSecretApi
---@field lua tinest.HostLuaApi

---@class tinest.ToolRef<I, O>: table
---@field private __tinest_tool_ref never
---@field private __tinest_tool_input I
---@field private __tinest_tool_output O

---@class tinest.ToolTemplateRef<I, O, P>: table
---@field private __tinest_tool_template_ref never
---@field private __tinest_template_input I
---@field private __tinest_template_output O
---@field private __tinest_template_payload P

---@class tinest.DriverRef: table
---@field private __tinest_driver_ref never

---@class tinest.HookRef<C>: table
---@field private __tinest_hook_ref never
---@field private __tinest_hook_context C
---@field private __tinest_hook_invariant fun(value: C): C

---@class tinest.ScheduledHandlerRef<P>: tinest.HookRef<P>
---@field private __tinest_scheduled_handler_ref never
---@field private __tinest_scheduled_payload P
---@field private __tinest_scheduled_invariant fun(value: P): P

---@class tinest.UiContributionRef<T>: table
---@field private __tinest_ui_ref never
---@field private __tinest_ui_input T

---@class tinest.UiActionRef<T>: table
---@field private __tinest_action_ref never
---@field private __tinest_action_payload T
---@field private __tinest_action_invariant fun(value: T): T

---@class tinest.SessionControlRef<T>: table
---@field private __tinest_control_ref never
---@field get fun(self: tinest.SessionControlRef<T>, values: table<string, any>): T

---@class tinest.DefinitionRef: table
---@field private __tinest_definition_ref never

---@class tinest.ToolDescriptor<I, O>
---@field id string
---@field name string
---@field description string
---@field kind string
---@field ref tinest.ToolRef<I, O>
---@field input_schema table
---@field output_schema? table
---@field exposure 'advertised'|'deferred'
---@field surfaced boolean
---@field presentation? table

---@class tinest.ModelRoleBlock
---@field role 'system'|'user'|'assistant'
---@field content string

---@class tinest.ModelUsage
---@field inputTokens integer
---@field cachedInputTokens integer
---@field outputTokens integer
---@field reasoningTokens integer
---@field totalTokens integer

---@class tinest.ModelUserItem
---@field type 'user'
---@field text string
---@field attachments? table[]

---@class tinest.ModelAssistantItem
---@field type 'assistant'
---@field text string
---@field toolCalls table[]
---@field opaqueItems table[]

---@class tinest.ModelToolResultItem
---@field type 'toolResult'
---@field callId string
---@field output string
---@field toolKind 'function'
---@field isError boolean
---@field content? table[]
---@field structuredContent? any
---@field meta? table<string, any>

---@alias tinest.ModelHistoryItem tinest.ModelUserItem|tinest.ModelAssistantItem|tinest.ModelToolResultItem

---@class (exact) tinest.ModelRequest
---@field blocks tinest.ModelRoleBlock[]
---@field history tinest.ModelHistoryItem[]
---@field tools tinest.ToolDescriptor<any, any>[]
---@field force_tool_name? string
---@field persist_completion? boolean

---@class tinest.ModelStreamRef: table
---@field private __tinest_model_stream_ref never

---@class tinest.ModelTextEvent
---@field type 'text'
---@field delta string

---@class tinest.ModelReasoningEvent
---@field type 'reasoning'
---@field delta string

---@class tinest.ModelToolCallEvent
---@field type 'tool_call'
---@field call_id string
---@field name string
---@field arguments table<string, any>
---@field tool_ref? tinest.ToolRef<any, any>

---@class tinest.ModelUsageEvent: tinest.ModelUsage
---@field type 'usage'

---@class tinest.ModelCompletionEvent
---@field type 'completion'
---@field assistant tinest.ModelAssistantItem
---@field usage tinest.ModelUsage

---@class tinest.ModelErrorEvent
---@field type 'error'
---@field code 'cancelled'|'context_overflow'|'model_host_error'|string
---@field message string

---@alias tinest.ModelEvent tinest.ModelTextEvent|tinest.ModelReasoningEvent|tinest.ModelToolCallEvent|tinest.ModelUsageEvent|tinest.ModelCompletionEvent|tinest.ModelErrorEvent

---@class tinest.StreamNext<T>
---@field done boolean
---@field value? T

---@alias tinest.HostPrimitiveRef function
---@alias tinest.UiSlot 'agentSettings'|'composerControl'|'conversationStatus'|'timeline'|'dialog'|'toast'
---@alias tinest.Capability 'model.call'|'tools.list'|'tools.invoke'|'state.read'|'state.write'|'scheduler.manage'|'ui.publish'|'workspace.read'|'workspace.patch'|'process.execute'|'process.write'|'attachment.publish'|'attachment.read'|'interaction.request'|'clock.read'|'clock.sleep'|'mcp.read'|'mcp.invoke'|'network.access'|'secret.access'|'collaboration.spawn'|'collaboration.message'|'collaboration.wait'|'collaboration.interrupt'|'collaboration.list'
---@alias tinest.Effect 'filesystem.read'|'filesystem.write'|'process.command'|'process.write'|'network.request'|'state.read'|'state.write'|'scheduler.enqueue'|'ui.publish'|'ui.timeline'|'ui.dialog'|'attachment.read'|'attachment.write'|'interaction.request'|'clock.read'|'clock.sleep'|'mcp.read'|'mcp.invoke'|'collaboration.spawn'|'collaboration.message'|'collaboration.wait'|'collaboration.interrupt'|'collaboration.list'|'model.call'|'tools.list'|'tools.invoke'|'context.read'|'context.reset'|'context.compact'
---@alias tinest.ModelCapability 'streaming'|'function_tools'|'deferred_tools'|'media'|'image_input'|'file_input'

---@class (exact) tinest.CapabilityApi
---@field model {call: 'model.call'}
---@field tools {list: 'tools.list', invoke: 'tools.invoke'}
---@field state {read: 'state.read', write: 'state.write'}
---@field scheduler {manage: 'scheduler.manage'}
---@field ui {publish: 'ui.publish'}
---@field workspace {read: 'workspace.read', patch: 'workspace.patch'}
---@field process {execute: 'process.execute', write: 'process.write'}
---@field attachment {publish: 'attachment.publish', read: 'attachment.read'}
---@field interaction {request: 'interaction.request'}
---@field clock {read: 'clock.read', sleep: 'clock.sleep'}
---@field mcp {read: 'mcp.read', invoke: 'mcp.invoke'}
---@field network {access: 'network.access'}
---@field secret {access: 'secret.access'}
---@field collaboration {spawn: 'collaboration.spawn', message: 'collaboration.message', wait: 'collaboration.wait', interrupt: 'collaboration.interrupt', list: 'collaboration.list'}

---@class (exact) tinest.EffectApi
---@field filesystem {read: 'filesystem.read', write: 'filesystem.write'}
---@field process {command: 'process.command', write: 'process.write'}
---@field network {request: 'network.request'}
---@field state {read: 'state.read', write: 'state.write'}
---@field scheduler {enqueue: 'scheduler.enqueue'}
---@field ui {publish: 'ui.publish', timeline: 'ui.timeline', dialog: 'ui.dialog'}
---@field attachment {read: 'attachment.read', write: 'attachment.write'}
---@field interaction {request: 'interaction.request'}
---@field clock {read: 'clock.read', sleep: 'clock.sleep'}
---@field mcp {read: 'mcp.read', invoke: 'mcp.invoke'}
---@field collaboration {spawn: 'collaboration.spawn', message: 'collaboration.message', wait: 'collaboration.wait', interrupt: 'collaboration.interrupt', list: 'collaboration.list'}
---@field model {call: 'model.call'}
---@field tools {list: 'tools.list', invoke: 'tools.invoke'}
---@field context {read: 'context.read', reset: 'context.reset', compact: 'context.compact'}

---@class (exact) tinest.ModelCapabilityApi
---@field streaming 'streaming'
---@field function_tools 'function_tools'
---@field deferred_tools 'deferred_tools'
---@field media 'media'
---@field image_input 'image_input'
---@field file_input 'file_input'

---@class (exact) tinest.ToolSpec
---@field id string
---@field name? string
---@field description? string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field presentation? table<string, any>

---@class (exact) tinest.DynamicToolSpec
---@field id string
---@field name? string
---@field description? string
---@field kind? 'function'|'deferred'
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field presentation? table<string, any>

---@alias tinest.ToolTemplateSpec tinest.ToolSpec

---@class (exact) tinest.DriverSpec
---@field id string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field required_model_capabilities? tinest.ModelCapability[]
---@field metadata? table<string, any>

---@class (exact) tinest.HookSpec
---@field id string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field metadata? table<string, any>

---@class (exact) tinest.SessionControlMetadata
---@field default any
---@field label? string
---@field description? string

---@class (exact) tinest.SessionControlSpec
---@field id string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field metadata tinest.SessionControlMetadata

---@class (exact) tinest.UiContributionSpec
---@field id string
---@field slot tinest.UiSlot
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field metadata? table<string, any>

---@class (exact) tinest.UiActionSpec
---@field id string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field metadata? table<string, any>

---@class (exact) tinest.ScheduledHandlerSpec
---@field id string
---@field uses? tinest.HostPrimitiveRef[]
---@field effects? tinest.Effect[]
---@field required_capabilities? tinest.Capability[]
---@field metadata? table<string, any>

---@class (exact) tinest.PluginDefinition
---@field driver? tinest.DriverRef
---@field tools? tinest.ToolRef<any, any>[]
---@field templates? tinest.ToolTemplateRef<any, any, any>[]
---@field hooks? tinest.HookRef<any>[]
---@field session_controls? tinest.SessionControlRef<any>[]
---@field ui? tinest.UiContributionRef<any>[]
---@field actions? tinest.UiActionRef<any>[]

---@class (exact) tinest.AgentAttachPayload
---@field lifecycle 'agent_attach'
---@field agent_id string
---@field session_id string
---@field workspace_id? string

---@class (exact) tinest.AgentAttachContext: tinest.AgentAttachPayload
---@field payload tinest.AgentAttachPayload
---@field settings table<string, any>

---@class (exact) tinest.AgentDetachPayload
---@field lifecycle 'agent_detach'
---@field agent_id string
---@field session_id string
---@field workspace_id? string

---@class (exact) tinest.AgentDetachContext: tinest.AgentDetachPayload
---@field payload tinest.AgentDetachPayload
---@field settings table<string, any>

---@class (exact) tinest.SessionOpenPayload
---@field lifecycle 'session_open'
---@field agent_id string
---@field session_id string
---@field workspace_id? string

---@class (exact) tinest.SessionOpenContext: tinest.SessionOpenPayload
---@field payload tinest.SessionOpenPayload
---@field settings table<string, any>

---@class (exact) tinest.SessionClosePayload
---@field lifecycle 'session_close'
---@field agent_id string
---@field session_id string
---@field workspace_id? string

---@class (exact) tinest.SessionCloseContext: tinest.SessionClosePayload
---@field payload tinest.SessionClosePayload
---@field settings table<string, any>

---@class (exact) tinest.BeforeTurnPayload
---@field turn_id string
---@field prompt string
---@field internal boolean
---@field extension_data table<string, any>

---@class (exact) tinest.BeforeTurnContext: tinest.BeforeTurnPayload
---@field payload tinest.BeforeTurnPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.BeforeModelContext: tinest.ModelRequest
---@field payload tinest.ModelRequest
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.AfterModelPayload: tinest.ModelRequest
---@field usage tinest.ModelUsage
---@field elapsed_seconds integer

---@class (exact) tinest.AfterModelContext: tinest.AfterModelPayload
---@field payload tinest.AfterModelPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.BeforeToolPayload
---@field id string
---@field call_id string
---@field arguments any

---@class (exact) tinest.BeforeToolContext: tinest.BeforeToolPayload
---@field payload tinest.BeforeToolPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.AfterToolPayload
---@field id string
---@field call_id string
---@field is_error boolean

---@class (exact) tinest.AfterToolContext: tinest.AfterToolPayload
---@field payload tinest.AfterToolPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.AfterTurnPayload
---@field turn_id string
---@field tool_rounds integer
---@field internal boolean

---@class (exact) tinest.AfterTurnContext: tinest.AfterTurnPayload
---@field payload tinest.AfterTurnPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.CancelPayload
---@field turn_id string
---@field reason string

---@class (exact) tinest.CancelContext: tinest.CancelPayload
---@field payload tinest.CancelPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.ErrorPayload
---@field turn_id string
---@field error string

---@class (exact) tinest.ErrorContext: tinest.ErrorPayload
---@field payload tinest.ErrorPayload
---@field session_controls table<string, any>
---@field settings table<string, any>

---@class (exact) tinest.PluginUiDocument
---@field id string
---@field pluginId string
---@field revisionHash string
---@field slot tinest.UiSlot
---@field root table<string, any>

---@class (exact) tinest.PluginUiAction
---@field documentId string
---@field actionId string
---@field data any

---@class (exact) tinest.UiActionHookPayload
---@field event 'ui_action'
---@field agent_id string
---@field session_id? string
---@field workspace_id? string
---@field context table<string, any>
---@field document tinest.PluginUiDocument
---@field action tinest.PluginUiAction

---@class (exact) tinest.UiActionHookContext: tinest.UiActionHookPayload
---@field payload tinest.UiActionHookPayload
---@field settings table<string, any>

---@class (exact) tinest.SessionControlContext<T>
---@field agent_id string
---@field session_id string
---@field workspace_id string
---@field plugin_id string
---@field contribution_id string
---@field value T
---@field current_value T
---@field settings table<string, any>

---@class tinest.ToolUiSnapshot
---@field tool_id string
---@field tool_name string
---@field label? string
---@field arguments table<string, any>
---@field arguments_json string
---@field output string
---@field is_error boolean
---@field structured_content? any
---@field meta? table<string, any>

---@class tinest.UiSectionProperties
---@field title? string
---@field description? string
---@field children tinest.UiNode[]

---@class tinest.UiRowProperties
---@field children tinest.UiNode[]

---@class tinest.UiTextProperties
---@field text string
---@field variant? 'body'|'bodySm'|'caption'|'code'|'headingSm'|'headingMd'|'headingLg'|'label'
---@field color? 'default'|'muted'|'primary'|'info'|'success'|'warning'|'danger'

---@class tinest.UiMarkdownProperties
---@field text string

---@class tinest.UiCodeProperties
---@field code string
---@field language? string
---@field wrap? boolean

---@class tinest.UiAlertProperties
---@field title string
---@field description? string
---@field variant? 'neutral'|'info'|'success'|'warning'|'danger'

---@class tinest.UiBadgeProperties
---@field text string
---@field variant? 'neutral'|'info'|'success'|'warning'|'danger'

---@class tinest.UiProgressProperties
---@field label? string
---@field value? number
---@field min? number
---@field max? number
---@field variant? 'neutral'|'info'|'success'|'warning'|'danger'

---@class tinest.UiDisclosureProperties
---@field title string
---@field open? boolean
---@field children tinest.UiNode[]

---@class tinest.UiFieldProperties
---@field id string
---@field label? string
---@field description? string
---@field placeholder? string
---@field disabled? boolean
---@field readOnly? boolean
---@field value? string

---@class tinest.UiButtonProperties<D>
---@field label string
---@field action tinest.UiActionRef<D>
---@field loadingLabel? string
---@field intent? 'neutral'|'primary'|'info'|'success'|'warning'|'danger'
---@field appearance? 'solid'|'outline'|'ghost'
---@field data? D

---@class tinest.UiSwitchProperties<D>
---@field id string
---@field label? string
---@field description? string
---@field action? tinest.UiActionRef<D>
---@field disabled? boolean
---@field readOnly? boolean
---@field value boolean
---@field data? D

---@class tinest.UiSelectOption
---@field value string
---@field label string
---@field enabled? boolean

---@class tinest.UiSelectProperties<D>
---@field id string
---@field label? string
---@field description? string
---@field placeholder? string
---@field action? tinest.UiActionRef<D>
---@field disabled? boolean
---@field readOnly? boolean
---@field value? string
---@field options tinest.UiSelectOption[]
---@field data? D

---@class tinest.UiNode
---@field private __tinest_ui_node_ref never

---@class tinest.JsonNull
---@field private __tinest_json_null never

---@class (exact) tinest.JsonApi
---@field null tinest.JsonNull
---@field is_null fun(value: any): boolean

---@class tinest.ToolsApi
---@field model_input fun(call: tinest.ModelToolCallEvent, descriptor?: tinest.ToolDescriptor<any, any>): any

---@class (exact) tinest.UiSlotApi
---@field agent_settings 'agentSettings'
---@field composer_control 'composerControl'
---@field conversation_status 'conversationStatus'
---@field timeline 'timeline'
---@field dialog 'dialog'
---@field toast 'toast'

---@class tinest.HookApi
---@field agent_attach fun(spec: tinest.HookSpec, callback: fun(context: tinest.AgentAttachContext): any): tinest.HookRef<tinest.AgentAttachContext>
---@field agent_detach fun(spec: tinest.HookSpec, callback: fun(context: tinest.AgentDetachContext): any): tinest.HookRef<tinest.AgentDetachContext>
---@field session_open fun(spec: tinest.HookSpec, callback: fun(context: tinest.SessionOpenContext): any): tinest.HookRef<tinest.SessionOpenContext>
---@field session_close fun(spec: tinest.HookSpec, callback: fun(context: tinest.SessionCloseContext): any): tinest.HookRef<tinest.SessionCloseContext>
---@field before_turn fun(spec: tinest.HookSpec, callback: fun(context: tinest.BeforeTurnContext): any): tinest.HookRef<tinest.BeforeTurnContext>
---@field before_model fun(spec: tinest.HookSpec, callback: fun(context: tinest.BeforeModelContext): any): tinest.HookRef<tinest.BeforeModelContext>
---@field after_model fun(spec: tinest.HookSpec, callback: fun(context: tinest.AfterModelContext): any): tinest.HookRef<tinest.AfterModelContext>
---@field before_tool fun(spec: tinest.HookSpec, callback: fun(context: tinest.BeforeToolContext): any): tinest.HookRef<tinest.BeforeToolContext>
---@field after_tool fun(spec: tinest.HookSpec, callback: fun(context: tinest.AfterToolContext): any): tinest.HookRef<tinest.AfterToolContext>
---@field after_turn fun(spec: tinest.HookSpec, callback: fun(context: tinest.AfterTurnContext): any): tinest.HookRef<tinest.AfterTurnContext>
---@field cancel fun(spec: tinest.HookSpec, callback: fun(context: tinest.CancelContext): any): tinest.HookRef<tinest.CancelContext>
---@field error fun(spec: tinest.HookSpec, callback: fun(context: tinest.ErrorContext): any): tinest.HookRef<tinest.ErrorContext>
---@field scheduled fun(spec: tinest.HookSpec, callback: fun(arguments: table<string, any>): any): tinest.HookRef<table<string, any>>
---@field ui_action fun(spec: tinest.HookSpec, callback: fun(context: tinest.UiActionHookContext): any): tinest.HookRef<tinest.UiActionHookContext>

---@class tinest.UiApi
---@field slot tinest.UiSlotApi
---@field section fun(properties: tinest.UiSectionProperties): tinest.UiNode
---@field row fun(properties: tinest.UiRowProperties): tinest.UiNode
---@field text fun(properties: tinest.UiTextProperties): tinest.UiNode
---@field markdown fun(properties: tinest.UiMarkdownProperties): tinest.UiNode
---@field code fun(properties: tinest.UiCodeProperties): tinest.UiNode
---@field diff fun(properties: tinest.UiCodeProperties): tinest.UiNode
---@field alert fun(properties: tinest.UiAlertProperties): tinest.UiNode
---@field badge fun(properties: tinest.UiBadgeProperties): tinest.UiNode
---@field progress fun(properties: tinest.UiProgressProperties): tinest.UiNode
---@field disclosure fun(properties: tinest.UiDisclosureProperties): tinest.UiNode
---@field field fun(properties: tinest.UiFieldProperties): tinest.UiNode
---@field document fun(node: tinest.UiNode): tinest.UiNode

---@class tinest.StateEntry<T>
---@field revision integer
---@field value T

---@class tinest.StateFound<T>: tinest.StateEntry<T>
---@field found true

---@class tinest.StateMissing
---@field found false

---@alias tinest.StateRead<T> tinest.StateFound<T>|tinest.StateMissing

---@class tinest.StateCellRef<T>: table
---@field read fun(self: tinest.StateCellRef<T>): tinest.StateRead<T>
---@field compare_and_set fun(self: tinest.StateCellRef<T>, expected_revision: integer, value: T): tinest.StateEntry<T>
---@field transaction fun(self: tinest.StateCellRef<T>, operations: tinest.StateMutation<T>[]): table<string, tinest.StateEntry<T>>
---@field remove fun(self: tinest.StateCellRef<T>, expected_revision?: integer): table<string, tinest.StateEntry<T>>

---@class tinest.StatePutMutation<T>
---@field key string
---@field expected_revision? integer
---@field value T
---@field remove? false

---@class tinest.StateRemoveMutation
---@field key string
---@field expected_revision? integer
---@field remove true

---@alias tinest.StateMutation<T> tinest.StatePutMutation<T>|tinest.StateRemoveMutation

---@class tinest.Schema<T>: table
---@field private __tinest_schema_ref never

---@class tinest.TypeToken<T>: table
---@field private __tinest_type_token_ref never

---@class tinest.EnumTypeToken<T, C>: tinest.TypeToken<T>
---@field private __tinest_enum_type_token_ref never

-- Schema builders return sealed runtime references. Their generic type is a
-- phantom decoded value supplied by generated, editor-only tinest.types
-- definitions. No type token or schema ref is JSON-serializable.

local schema = {}

local function schema_ref(document, optional)
  return make_ref({kind = "schema", schema = document, optional = optional == true})
end

local function schema_metadata(value, label)
  return require_ref(value, "schema", label, 3)
end

---@return tinest.Schema<string>
function schema.string(options)
  local result = {type = "string"}
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@return tinest.Schema<integer>
function schema.integer(options)
  local result = {type = "integer"}
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@return tinest.Schema<number>
function schema.number(options)
  local result = {type = "number"}
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@return tinest.Schema<boolean>
function schema.boolean(options)
  local result = {type = "boolean"}
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@return tinest.Schema<any>
function schema.any() return schema_ref({}) end

---@generic T
---@param item tinest.Schema<T>
---@return tinest.Schema<T[]>
function schema.array(item, options)
  local result = {type = "array", items = schema_metadata(item, "item").schema}
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@generic T
---@param item tinest.Schema<T>
---@return tinest.Schema<table<string, T>>
function schema.map(item, options)
  local result = {
    type = "object",
    additionalProperties = schema_metadata(item, "item").schema,
  }
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@generic T
---@param item tinest.Schema<T>
---@return tinest.Schema<T?>
function schema.optional(item)
  local metadata = schema_metadata(item, "item")
  return schema_ref(metadata.schema, true)
end

---@generic T, F: table
---@param token tinest.TypeToken<T>
---@param fields F
---@param options? table
---@return tinest.Schema<T>
---@overload fun<F: table>(fields: F, options?: table): tinest.Schema<table>
function schema.object(token, fields, options)
  if fields == nil then
    fields, options, token = token, options, nil
  else
    require_ref(token, "type_token", "object type token", 2)
  end
  expect_table(fields, "fields", 2)
  local properties, required = {}, {}
  for key, field in pairs(fields) do
    if type(key) ~= "string" then fail("schema field names must be strings", 2) end
    local metadata = schema_metadata(field, "field " .. key)
    properties[key] = metadata.schema
    if not metadata.optional then required[#required + 1] = key end
  end
  table.sort(required)
  local result = {
    type = "object",
    properties = properties,
    required = required,
    additionalProperties = false,
  }
  for key, value in pairs(options or {}) do result[key] = copy_json(value) end
  return schema_ref(result)
end

---@generic T, C
---@param token tinest.EnumTypeToken<T, C>
---@param values string[]
---@return tinest.Schema<T>
---@return C
---@overload fun(values: string[]): tinest.Schema<string>, table<string, string>
function schema.enum(token, values)
  if values == nil then
    values, token = token, nil
  else
    require_ref(token, "type_token", "enum type token", 2)
  end
  local ordered = sorted_set(values, "enum values")
  local constants = {}
  for _, value in ipairs(ordered) do
    if not value:match("^[a-z][a-z0-9_]*$") then
      fail("enum values used as code refs must be lowercase identifiers", 2)
    end
    constants[value] = value
  end
  return schema_ref({type = "string", enum = ordered}), constants
end

---@generic T, C: table
---@param token tinest.EnumTypeToken<T, C>
---@param values C
---@return tinest.Schema<T>
---@return C
---@overload fun<C: table>(values: C): tinest.Schema<string>, C
function schema.literal_enum(token, values)
  if values == nil then
    values, token = token, nil
  else
    require_ref(token, "type_token", "literal enum type token", 2)
  end
  expect_table(values, "literal enum values", 2)
  local ordered, constants, seen = {}, {}, {}
  for key, value in pairs(values) do
    if type(key) ~= "string" or
        not key:match("^[a-z][a-z0-9_]*$") then
      fail("literal enum keys must be lowercase identifiers", 2)
    end
    if type(value) ~= "string" or value == "" then
      fail("literal enum values must be non-empty strings", 2)
    end
    if seen[value] then
      fail("literal enum contains duplicate value " .. value, 2)
    end
    seen[value] = true
    ordered[#ordered + 1] = value
    constants[key] = value
  end
  if #ordered == 0 then
    fail("schema.literal_enum requires at least one value", 2)
  end
  table.sort(ordered)
  return schema_ref({type = "string", enum = ordered}), constants
end

---@generic T
---@param token tinest.TypeToken<T>
---@param document table
---@return tinest.Schema<T>
---@overload fun(document: table): tinest.Schema<any>
function schema.raw(token, document)
  if document == nil then
    document, token = token, nil
  else
    require_ref(token, "type_token", "raw schema type token", 2)
  end
  return schema_ref(copy_json(expect_table(document, "raw schema", 2)))
end

local function binding_key(kind, id, lifecycle)
  if lifecycle ~= nil then
    return "__tinest." .. kind .. "." .. lifecycle .. "." .. id
  end
  return "__tinest." .. kind .. "." .. id
end

local function ui_callback_result(value)
  local metadata = references[value]
  if metadata ~= nil then
    if metadata.kind ~= "ui_node" then
      fail("UI contribution must return a Tinest UI node", 3)
    end
    local action_ids = {}
    for action_id, _ in pairs(metadata.actions or {}) do
      action_ids[#action_ids + 1] = action_id
    end
    table.sort(action_ids)
    return {
      __tinest_ui_document = "constructor",
      root = copy_json(metadata.wire),
      actions = action_ids,
    }
  end
  reject_reference_result(value)
  fail("UI contribution must return a Tinest UI node", 3)
end

local function contribution(kind, spec, callback, extras)
  spec = expect_table(spec, kind .. " spec", 3)
  if spec.handler ~= nil or spec.binding ~= nil or
      spec.declared_operations ~= nil then
    fail(
      "handler, binding, and declared_operations are SDK-owned; " ..
        "pass Lua functions and primitive refs in uses",
      3
    )
  end
  if type(callback) ~= "function" then fail(kind .. " callback must be a function", 3) end
  local id = expect_id(spec.id, kind .. " id", 3)
  local lifecycle = extras and extras.lifecycle or nil
  local key = binding_key(kind, id, lifecycle)
  if bound_handlers[key] ~= nil then fail("duplicate Tinest binding: " .. key, 3) end
  bound_handlers[key] = function(arguments)
    local result = callback(arguments)
    if extras ~= nil and extras.result_kind == "ui_document" then
      return ui_callback_result(result)
    end
    reject_reference_result(result)
    return result
  end

  local use_capabilities, use_effects, use_operations = {}, {}, {}
  for index, used in ipairs(spec.uses or {}) do
    local metadata = references[used]
    if metadata == nil or metadata.kind ~= "primitive" then
      fail("uses[" .. index .. "] must be a Tinest primitive reference", 3)
    end
    use_operations[#use_operations + 1] = metadata.id
    use_capabilities = union(use_capabilities, metadata.capabilities)
    use_effects = union(use_effects, metadata.effects)
  end
  local required = union(
    sorted_set(spec.required_capabilities, "required_capabilities"),
    use_capabilities
  )
  local effects = union(sorted_set(spec.effects, "effects"), use_effects)
  local wire = {
    id = id,
    binding = {kind = kind, id = id, key = key},
    required_capabilities = required,
    declared_operations = union({}, use_operations),
  }
  if #effects > 0 then wire.effects = effects end
  for key_name, value in pairs(spec) do
    if key_name ~= "id" and key_name ~= "uses" and key_name ~= "effects" and
        key_name ~= "required_capabilities" and
        key_name ~= "declared_operations" then
      wire[key_name] = copy_registration(value)
    end
  end
  for key_name, value in pairs(extras or {}) do
    if key_name ~= "lifecycle" and key_name ~= "result_kind" then
      wire[key_name] = copy_json(value)
    end
  end
  return make_ref({kind = kind, id = id, lifecycle = lifecycle, wire = wire})
end

local selected_tools_by_name = {}
local surfaced_dynamic_by_id = {}
local selected_tool_generation = 1

local function primitive_arguments(arguments)
  local encoded = copy_json(arguments or {})
  if type(encoded) ~= "table" then
    fail("host primitive arguments must be a table", 3)
  end
  -- This field belongs exclusively to the SDK. A plugin cannot smuggle a
  -- dynamic grant token into a primitive call outside the callback that the
  -- corresponding surfaced ToolRef owns.
  encoded._tinest_dynamic_token = active_dynamic_token
  return encoded
end

local function primitive(name, capabilities, effects, stream)
  local callback
  if stream then
    callback = function(arguments)
      return runtime_host.open(name, primitive_arguments(arguments))
    end
  else
    callback = function(arguments)
      local encoded = primitive_arguments(arguments)
      if name == "host.lua.start" and type(arguments) == "table" and
          type(arguments.tools) == "table" then
        encoded.tools = {}
        for index, tool_ref in ipairs(arguments.tools) do
          local selected = require_ref(
            tool_ref, "selected_tool", "tools[" .. index .. "]", 2
          )
          if selected.generation ~= selected_tool_generation then
            fail("tool reference is stale for Lua execution", 2)
          end
          encoded.tools[index] = selected.id
        end
      end
      return runtime_host.call(name, encoded)
    end
  end
  references[callback] = {
    kind = "primitive",
    id = name,
    capabilities = capabilities or {},
    effects = effects or {},
  }
  return callback
end

---@type tinest.HookApi
local hook_api = {}
---@type tinest.UiApi
local ui_api = {slot = {
  agent_settings = "agentSettings",
  composer_control = "composerControl",
  conversation_status = "conversationStatus",
  timeline = "timeline",
  dialog = "dialog",
  toast = "toast",
}}

---@type tinest.ModelCapabilityApi
local model_capability_api = {
  streaming = "streaming",
  function_tools = "function_tools",
  deferred_tools = "deferred_tools",
  media = "media",
  image_input = "image_input",
  file_input = "file_input",
}

---@type tinest.CapabilityApi
local capability_api = {
  model = {call = "model.call"},
  tools = {list = "tools.list", invoke = "tools.invoke"},
  state = {read = "state.read", write = "state.write"},
  scheduler = {manage = "scheduler.manage"},
  ui = {publish = "ui.publish"},
  workspace = {read = "workspace.read", patch = "workspace.patch"},
  process = {execute = "process.execute", write = "process.write"},
  attachment = {publish = "attachment.publish", read = "attachment.read"},
  interaction = {request = "interaction.request"},
  clock = {read = "clock.read", sleep = "clock.sleep"},
  mcp = {read = "mcp.read", invoke = "mcp.invoke"},
  network = {access = "network.access"},
  secret = {access = "secret.access"},
  collaboration = {
    spawn = "collaboration.spawn", message = "collaboration.message",
    wait = "collaboration.wait", interrupt = "collaboration.interrupt",
    list = "collaboration.list",
  },
}

---@type tinest.EffectApi
local effect_api = {
  filesystem = {read = "filesystem.read", write = "filesystem.write"},
  process = {command = "process.command", write = "process.write"},
  network = {request = "network.request"},
  state = {read = "state.read", write = "state.write"},
  scheduler = {enqueue = "scheduler.enqueue"},
  ui = {
    publish = "ui.publish", timeline = "ui.timeline", dialog = "ui.dialog",
  },
  attachment = {read = "attachment.read", write = "attachment.write"},
  interaction = {request = "interaction.request"},
  clock = {read = "clock.read", sleep = "clock.sleep"},
  mcp = {read = "mcp.read", invoke = "mcp.invoke"},
  collaboration = {
    spawn = "collaboration.spawn", message = "collaboration.message",
    wait = "collaboration.wait", interrupt = "collaboration.interrupt",
    list = "collaboration.list",
  },
  model = {call = "model.call"},
  tools = {list = "tools.list", invoke = "tools.invoke"},
  context = {
    read = "context.read", reset = "context.reset", compact = "context.compact",
  },
}

---@type tinest.HostApi
local host_api = {workspace = {}, process = {}, attachment = {},
  interaction = {}, mcp = {}, collaboration = {}, clock = {}, skills = {},
  network = {}, secret = {}, lua = {}}

---@type tinest.JsonApi
local json_api = {
  null = runtime_json_null,
  is_null = function(value) return value == runtime_json_null end,
}

---@type tinest.ToolsApi
local tools_api = {}

local tinest = {
  plugin = {},
  schema = schema,
  tool = {
    kind = {function_ = "function", deferred = "deferred"},
    exposure = {advertised = "advertised", deferred = "deferred"},
  },
  driver = {},
  hook = hook_api,
  session = {},
  model = {
    role = {system = "system", user = "user", assistant = "assistant"},
    capability = model_capability_api,
  },
  tools = tools_api,
  state = {scope = {plugin = "plugin", agent = "agent", session = "session", workspace = "workspace"}},
  scheduler = {},
  ui = ui_api,
  result = {},
  json = json_api,
  assets = {},
  host = host_api,
  capability = capability_api,
  effect = effect_api,
  status = {active = "active", complete = "complete", blocked = "blocked", budget_limited = "budget_limited"},
}

function tinest.__set_identity(value)
  if plugin_identity ~= nil then fail("plugin identity is already pinned", 2) end
  if type(value) ~= "string" or value == "" then fail("invalid plugin identity", 2) end
  plugin_identity = value
end

-- Called exactly once by the revision-specific tinest.types module before the
-- plugin entrypoint is evaluated. The module deletes this private installer
-- from the public table before author code can run.
function tinest.__install_type_tokens(names)
  if plugin_identity == nil then fail("plugin identity is not pinned", 2) end
  if type_tokens_installed then fail("type tokens are already installed", 2) end
  type_tokens_installed = true
  names = expect_table(names, "type token names", 2)
  local result, seen = {}, {}
  for _, name in ipairs(names) do
    if type(name) ~= "string" or
        not name:match("^[A-Z][A-Za-z0-9_]*$") then
      fail("type token names must be PascalCase identifiers", 2)
    end
    if seen[name] then fail("duplicate type token " .. name, 2) end
    seen[name] = true
    result[name] = make_ref({
      kind = "type_token",
      id = name,
      plugin = plugin_identity,
    })
  end
  return result
end

local function qualified(id)
  if plugin_identity == nil then fail("plugin identity is not pinned", 3) end
  return plugin_identity .. "/" .. id
end

local function schema_document(value, label)
  return copy_json(schema_metadata(value, label).schema)
end

local function invocation_arguments(value)
  if type(value) ~= "table" then return value, {} end
  local arguments, context = {}, {}
  for key, item in pairs(value) do
    if key == "_tinest" then
      if type(item) == "table" then context = copy_json(item) end
    else
      arguments[key] = item
    end
  end
  return arguments, context
end

local function tool_constructor(kind, spec, input, output, callback)
  local extras = {kind = kind, input_schema = schema_document(input, "input schema")}
  if output ~= nil then extras.output_schema = schema_document(output, "output schema") end
  local run = function(arguments)
    local public, context = invocation_arguments(arguments)
    return callback(public, context)
  end
  return contribution("tool", spec, run, extras)
end

---@generic I, O
---@param spec tinest.ToolSpec
---@param input tinest.Schema<I>
---@param output tinest.Schema<O>?
---@param callback fun(arguments: I, context: tinest.ToolContext): O|tinest.ToolValue<O>
---@return tinest.ToolRef<I, O>
function tinest.tool.function_(spec, input, output, callback)
  return tool_constructor("function", spec, input, output, callback)
end
---@generic I, O
---@param spec tinest.ToolSpec
---@param input tinest.Schema<I>
---@param output tinest.Schema<O>?
---@param callback fun(arguments: I, context: tinest.ToolContext): O|tinest.ToolValue<O>
---@return tinest.ToolRef<I, O>
function tinest.tool.deferred(spec, input, output, callback)
  return tool_constructor("deferred", spec, input, output, callback)
end

---@generic I, O, P
---@param spec tinest.ToolTemplateSpec
---@param payload tinest.Schema<P>
---@param input tinest.Schema<I>
---@param output tinest.Schema<O>?
---@param callback fun(arguments: I, payload: P, context: tinest.ToolContext): O|tinest.ToolValue<O>
---@return tinest.ToolTemplateRef<I, O, P>
function tinest.tool.template(spec, payload, input, output, callback)
  local extras = {
    kind = "template",
    payload_schema = schema_document(payload, "template payload schema"),
    input_schema = schema_document(input, "template input schema"),
  }
  if output ~= nil then
    extras.output_schema = schema_document(output, "template output schema")
  end
  local run = function(arguments)
    local wire = expect_table(arguments, "template invocation", 2)
    local public, context = invocation_arguments(wire.arguments or {})
    return callback(public, copy_json(wire.payload or {}), context)
  end
  return contribution("tool_template", spec, run, extras)
end

local function dynamic_metadata(spec, input, output, callback)
  spec = expect_table(spec, "dynamic tool spec", 3)
  if spec.declared_operations ~= nil then
    fail(
      "declared_operations is SDK-owned; pass primitive refs in uses",
      3
    )
  end
  if type(callback) ~= "function" then
    fail("dynamic tool callback must be a function", 3)
  end
  local id = expect_id(spec.id, "dynamic tool id", 3)
  local use_capabilities, use_effects, use_operations = {}, {}, {}
  for index, used in ipairs(spec.uses or {}) do
    local metadata = references[used]
    if metadata == nil or metadata.kind ~= "primitive" then
      fail("uses[" .. index .. "] must be a Tinest primitive reference", 3)
    end
    use_operations[#use_operations + 1] = metadata.id
    use_capabilities = union(use_capabilities, metadata.capabilities)
    use_effects = union(use_effects, metadata.effects)
  end
  local wire = {
    id = id,
    name = spec.name or id,
    description = spec.description or spec.name or id,
    kind = spec.kind or "function",
    input_schema = schema_document(input, "dynamic input schema"),
    required_capabilities = union(
      sorted_set(spec.required_capabilities, "required_capabilities"),
      use_capabilities
    ),
    declared_operations = union({}, use_operations),
    effects = union(sorted_set(spec.effects, "effects"), use_effects),
  }
  if output ~= nil then
    wire.output_schema = schema_document(output, "dynamic output schema")
  end
  for key, value in pairs(spec) do
    if key ~= "id" and key ~= "name" and key ~= "description" and
        key ~= "kind" and key ~= "uses" and key ~= "effects" and
        key ~= "required_capabilities" and key ~= "declared_operations" then
      wire[key] = copy_registration(value)
    end
  end
  return wire, callback
end

---@generic I, O
---@param spec tinest.DynamicToolSpec
---@param input tinest.Schema<I>
---@param output tinest.Schema<O>?
---@param callback fun(arguments: I, context: tinest.ToolContext): O|tinest.ToolValue<O>
---@return tinest.ToolRef<I, O>
function tinest.tool.dynamic(spec, input, output, callback)
  local wire, run = dynamic_metadata(spec, input, output, callback)
  return make_ref({kind = "dynamic_tool", wire = wire, callback = run})
end

---@generic I, O, P
---@param template_ref tinest.ToolTemplateRef<I, O, P>
---@param spec tinest.DynamicToolSpec
---@param payload P
---@return tinest.ToolRef<I, O>
function tinest.tool.dynamic_from(template_ref, spec, payload)
  local template = references[template_ref]
  if template == nil or
      (template.kind ~= "selected_template" and
       template.kind ~= "tool_template") then
    fail("template_ref must be a selected Tinest ToolTemplateRef", 2)
  end
  local wire = expect_table(spec, "dynamic tool spec", 2)
  local input = schema.raw(wire.input_schema or {})
  local output = nil
  if wire.output_schema ~= nil then
    output = schema.raw(wire.output_schema)
  end
  local normalized = dynamic_metadata(wire, input, output, function() end)
  normalized.template_id = template.kind == "selected_template" and
    template.id or qualified(template.id)
  normalized.template_generation = template.generation
  normalized.payload = copy_json(payload)
  return make_ref({kind = "dynamic_from", wire = normalized})
end

---@param spec tinest.DriverSpec
---@param callback fun(arguments: table): table
---@return tinest.DriverRef
function tinest.driver.define(spec, callback)
  return contribution("driver", spec, callback)
end

local lifecycle_names = {
  "agent_attach", "agent_detach", "session_open", "session_close",
  "before_turn", "before_model", "after_model", "before_tool", "after_tool",
  "after_turn", "cancel", "error", "scheduled", "ui_action",
}
for _, lifecycle in ipairs(lifecycle_names) do
  tinest.hook[lifecycle] = function(spec, callback)
    return contribution("hook", spec, callback, {lifecycle = lifecycle})
  end
end

---@generic T
---@param spec tinest.SessionControlSpec
---@param value_schema tinest.Schema<T>
---@param callback fun(context: tinest.SessionControlContext<T>): T
---@return tinest.SessionControlRef<T>
function tinest.session.control(spec, value_schema, callback)
  local control_ref = contribution("session_control", spec, callback, {
    schema = schema_document(value_schema, "session control schema"),
  })
  function control_ref.get(self, values)
    local control = require_ref(self, "session_control", "session control", 2)
    values = expect_table(values or {}, "session control values", 2)
    local value = values[qualified(control.id)]
    if value ~= nil then return value end
    local metadata = control.wire.metadata
    if type(metadata) == "table" and metadata.default ~= nil then
      return copy_json(metadata.default)
    end
    return nil
  end
  return control_ref
end

---@generic T
---@param spec tinest.UiContributionSpec
---@param input_schema tinest.Schema<T>
---@param callback fun(arguments: T): tinest.UiNode
---@return tinest.UiContributionRef<T>
function tinest.ui.contribution(spec, input_schema, callback)
  local run = function(arguments)
    arguments = expect_table(arguments, "UI callback input", 2)
    if arguments.__tinest_callback_value ~= true then
      fail("UI callback input was not supplied by the Tinest host", 2)
    end
    return callback(arguments.value)
  end
  return contribution("ui", spec, run, {
    input_schema = schema_document(input_schema, "UI contribution input schema"),
    result_kind = "ui_document",
  })
end

---@generic T
---@param spec tinest.UiActionSpec
---@param payload_schema tinest.Schema<T>
---@param callback fun(arguments: T): any
---@return tinest.UiActionRef<T>
function tinest.ui.action(spec, payload_schema, callback)
  local run = function(arguments)
    arguments = expect_table(arguments, "UI action payload", 2)
    if arguments.__tinest_callback_value ~= true then
      fail("UI action payload was not supplied by the Tinest host", 2)
    end
    return callback(arguments.value)
  end
  return contribution("action", spec, run, {
    lifecycle = "ui_action",
    payload_schema = schema_document(payload_schema, "UI action payload schema"),
  })
end

local node_kinds = {
  "section", "row", "text", "markdown", "code", "diff", "alert", "badge",
  "progress", "disclosure", "field", "button", "switch", "select",
}

local action_node_kinds = {button = true, switch = true, select = true}

local function copy_ui_value(value, actions, seen)
  local metadata = references[value]
  if metadata ~= nil then
    if metadata.kind ~= "ui_node" then
      fail("UI properties may contain only Tinest UI node references", 3)
    end
    for action_id, _ in pairs(metadata.actions or {}) do
      actions[action_id] = true
    end
    return copy_json(metadata.wire)
  end
  local kind = type(value)
  if kind == "nil" or kind == "boolean" or kind == "string" or
      kind == "number" then return value end
  if kind ~= "table" then fail(kind .. " is not valid UI data", 3) end
  seen = seen or {}
  if seen[value] then fail("cyclic UI data is invalid", 3) end
  seen[value] = true
  local result = {}
  for key, item in pairs(value) do
    if type(key) ~= "string" and type(key) ~= "number" then
      fail("UI data keys must be strings or array indices", 3)
    end
    result[key] = copy_ui_value(item, actions, seen)
  end
  seen[value] = nil
  return result
end

local function ui_node(node_kind, properties)
  properties = expect_table(properties or {}, node_kind .. " properties", 2)
  if properties.type ~= nil then fail("UI node type is constructor-owned", 2) end
  if properties.actionId ~= nil then fail("UI actionId is SDK-owned", 2) end
  if properties.action ~= nil and not action_node_kinds[node_kind] then
    fail(node_kind .. " does not accept a UI action", 2)
  end
  local result, actions = {}, {}
  for key, value in pairs(properties) do
    if key ~= "action" then result[key] = copy_ui_value(value, actions) end
  end
  result.type = node_kind
  if properties.action ~= nil then
    local action = require_ref(
      properties.action, "action", node_kind .. " action", 2
    )
    local action_id = qualified(action.id)
    result.actionId = action_id
    actions[action_id] = true
  end
  return make_ref({kind = "ui_node", wire = result, actions = actions})
end

for _, node_kind in ipairs(node_kinds) do
  if not action_node_kinds[node_kind] then
    tinest.ui[node_kind] = function(properties)
      return ui_node(node_kind, properties)
    end
  end
end

---@generic D
---@param properties tinest.UiButtonProperties<D>
---@return tinest.UiNode
function tinest.ui.button(properties) return ui_node("button", properties) end

---@generic D
---@param properties tinest.UiSwitchProperties<D>
---@return tinest.UiNode
function tinest.ui.switch(properties) return ui_node("switch", properties) end

---@generic D
---@param properties tinest.UiSelectProperties<D>
---@return tinest.UiNode
function tinest.ui.select(properties) return ui_node("select", properties) end

function tinest.ui.tool_document(arguments)
  local value = type(arguments) == "table" and arguments or {}
  if type(value) ~= "table" then value = {} end
  local label = tostring(value.label or value.tool_name or value.tool_id or "Tool")
  local request = tostring(value.arguments_json or "{}")
  local output = tostring(value.output or "")
  if output == "" then output = "(no output)" end
  return tinest.ui.disclosure({
    title = label,
    children = {
      tinest.ui.code({code = request, language = "json", wrap = true}),
      tinest.ui.code({code = output, wrap = true}),
    },
  })
end

local function publish_ui(operation, contribution_ref, value, options)
  local contribution = require_ref(
    contribution_ref, "ui", "UI contribution", 3
  )
  options = options or {}
  return checked_call("ui." .. operation, {
    contribution_id = qualified(contribution.id),
    value = copy_json(value),
    snapshot = options.snapshot,
  })
end
function tinest.ui.timeline(ref, value, options) return publish_ui("timeline", ref, value, options) end
function tinest.ui.status(ref, value, options) return publish_ui("status", ref, value, options) end
function tinest.ui.dialog(ref, value, options) return publish_ui("dialog", ref, value, options) end
function tinest.ui.toast(ref, value, options) return publish_ui("toast", ref, value, options) end
function tinest.ui.document(node)
  require_ref(node, "ui_node", "UI document", 2)
  return node
end

---@generic T
---@param spec {scope: string, key: string}
---@param value_schema tinest.Schema<T>
---@return tinest.StateCellRef<T>
function tinest.state.cell(spec, value_schema)
  spec = expect_table(spec, "state cell spec", 2)
  if type(spec.scope) ~= "string" or type(spec.key) ~= "string" or spec.key == "" then
    fail("state cell requires scope and key", 2)
  end
  local metadata = {
    kind = "state_cell",
    id = spec.scope .. ":" .. spec.key,
    scope = spec.scope,
    key = spec.key,
    schema = schema_document(value_schema, "state cell schema"),
  }
  local methods = {}
  function methods.read(self)
    local cell = require_ref(self, "state_cell", "state cell", 2)
    return checked_call("state.read", {
      scope = cell.scope, key = cell.key, schema = cell.schema,
    })
  end
  function methods.compare_and_set(self, expected_revision, value)
    local cell = require_ref(self, "state_cell", "state cell", 2)
    return checked_call("state.compare_and_set", {
      scope = cell.scope, key = cell.key, expected_revision = expected_revision,
      value = copy_json(value), schema = cell.schema,
    })
  end
  function methods.transaction(self, operations)
    local cell = require_ref(self, "state_cell", "state cell", 2)
    return checked_call("state.transaction", {
      scope = cell.scope, mutations = copy_json(operations),
      schema = cell.schema,
    })
  end
  function methods.remove(self, expected_revision)
    local cell = require_ref(self, "state_cell", "state cell", 2)
    return checked_call("state.remove", {
      scope = cell.scope, key = cell.key, expected_revision = expected_revision,
    })
  end
  return make_ref(metadata, methods)
end

---@generic T
---@param spec tinest.ScheduledHandlerSpec
---@param payload_schema tinest.Schema<T>?
---@param callback fun(payload: T): any
---@return tinest.ScheduledHandlerRef<T>
function tinest.scheduler.handler(spec, payload_schema, callback)
  local extras = {lifecycle = "scheduled"}
  if payload_schema ~= nil then
    extras.payload_schema = schema_document(payload_schema, "scheduled payload schema")
  end
  return contribution("hook", spec, callback, extras)
end

---@class (exact) tinest.ScheduleOptions
---@field delay_ms? integer
---@field job_id? string

local function schedule(operation, handler_ref, payload, options)
  local handler = require_ref(handler_ref, "hook", "scheduled handler", 3)
  if handler.lifecycle ~= "scheduled" then fail("handler is not scheduled", 3) end
  options = options or {}
  return checked_call("scheduler." .. operation, {
    binding_id = handler.id,
    payload = copy_json(payload or {}),
    delay_ms = options.delay_ms,
    job_id = options.job_id,
  })
end
---@generic P
---@param ref tinest.ScheduledHandlerRef<P>
---@param payload P
---@param options? tinest.ScheduleOptions
function tinest.scheduler.schedule(ref, payload, options)
  return schedule("schedule", ref, payload, options)
end
---@generic P
---@param ref tinest.ScheduledHandlerRef<P>
---@param payload P
---@param options? tinest.ScheduleOptions
function tinest.scheduler.continue_after_turn(ref, payload, options)
  return schedule("continue_after_turn", ref, payload, options)
end
function tinest.scheduler.cancel(job_id)
  return checked_call("scheduler.cancel", {id = job_id})
end

---@generic T
---@param result tinest.HostResult<T>|T
---@return T
function tinest.result.unwrap(result)
  if type(result) ~= "table" then return result end
  if result.ok == true then return result.value end
  if result.ok == false or result.is_error == true then fail(error_message(result), 2) end
  return result
end

---@class (exact) tinest.ToolValue<T>
---@field value T

---Keeps a structured tool value distinct from the optional result envelope.
---@generic T
---@param value T
---@return tinest.ToolValue<T>
function tinest.result.value(value)
  reject_reference_result(value)
  return {__tinest_tool_value = true, value = copy_json(value)}
end

function tinest.assets.read(path) return runtime_assets.read(path) end

---@param request tinest.ModelRequest
---@return tinest.ModelStreamRef
function tinest.model.open(request)
  request = expect_table(request or {}, "model request", 2)
  local encoded = {}
  for key, value in pairs(request) do
    if key ~= "tools" then encoded[key] = copy_json(value) end
  end
  encoded.tools = {}
  for index, descriptor in ipairs(request.tools or {}) do
    local wire = {}
    for key, value in pairs(descriptor) do
      if key ~= "ref" and string.sub(key, 1, 9) ~= "_tinest_" then
        wire[key] = copy_json(value)
      end
    end
    encoded.tools[index] = wire
  end
  return runtime_host.open("model.open", encoded)
end
references[tinest.model.open] = {kind="primitive", id="model.open", capabilities={"model.call"}, effects={}}
---@param handle tinest.ModelStreamRef
---@return tinest.StreamNext<tinest.ModelEvent>
function tinest.model.next(handle)
  local next_value = runtime_host.next(handle)
  local event = type(next_value) == "table" and next_value.value or nil
  if type(event) == "table" and event.type == "tool_call" then
    event.tool_ref = selected_tools_by_name[event.name]
  end
  return next_value
end
---@param handle tinest.ModelStreamRef
function tinest.model.close(handle) return runtime_host.close(handle) end
references[tinest.model.next] = {kind="primitive", id="model.next", capabilities={"model.call"}, effects={}}
references[tinest.model.close] = {kind="primitive", id="model.close", capabilities={"model.call"}, effects={}}

local function model_schema_has_type(schema, expected)
  if type(schema) ~= "table" or schema == runtime_json_null then return false end
  local declared = schema.type
  if declared == expected then return true end
  if type(declared) ~= "table" or declared == runtime_json_null then return false end
  for _, value in ipairs(declared) do
    if value == expected then return true end
  end
  return false
end

local function model_schema_allows_null(schema)
  if type(schema) ~= "table" or schema == runtime_json_null then return true end
  if schema.type ~= nil and not model_schema_has_type(schema, "null") then
    return false
  end
  local enum = schema.enum
  if type(enum) == "table" and enum ~= runtime_json_null then
    for _, candidate in ipairs(enum) do
      if candidate == runtime_json_null then return true end
    end
    return false
  end
  return true
end

local function canonical_model_json_value(value, schema)
  if value == runtime_json_null or type(value) ~= "table" then return value end
  if type(schema) ~= "table" or schema == runtime_json_null then return value end
  if model_schema_has_type(schema, "object") or
      type(schema.properties) == "table" then
    local required = {}
    for _, key in ipairs(schema.required or {}) do required[key] = true end
    local properties = type(schema.properties) == "table" and
      schema.properties or {}
    local additional = schema.additionalProperties
    local result = {}
    for key, item in pairs(value) do
      local property_schema = properties[key]
      if property_schema == nil and type(additional) == "table" and
          additional ~= runtime_json_null then
        property_schema = additional
      end
      if not (item == runtime_json_null and required[key] ~= true and
          not model_schema_allows_null(property_schema)) then
        result[key] = canonical_model_json_value(item, property_schema)
      end
    end
    return result
  end
  if model_schema_has_type(schema, "array") then
    local result = {}
    for index, item in ipairs(value) do
      result[index] = canonical_model_json_value(item, schema.items)
    end
    return result
  end
  return value
end

---Canonicalizes provider model arguments against the selected tool schema.
---Optional object fields whose schemas reject JSON null are omitted, while
---required fields, nullable fields, and array nulls are kept.
---@param call tinest.ModelToolCallEvent
---@param descriptor? tinest.ToolDescriptor<any, any>
---@return any
function tinest.tools.model_input(call, descriptor)
  if type(call) ~= "table" or call == runtime_json_null or
      type(call.arguments) ~= "table" or call.arguments == runtime_json_null then
    return {}
  end
  return canonical_model_json_value(
    call.arguments,
    descriptor and descriptor.input_schema or nil
  )
end

---@return tinest.ToolDescriptor<any, any>[]
function tinest.tools.list(arguments)
  local descriptors = checked_call("tools.list", copy_json(arguments or {}))
  for _, descriptor in ipairs(descriptors or {}) do
    local owner = surfaced_dynamic_by_id[descriptor.id]
    local reference_kind, ref
    if owner ~= nil and owner.metadata.token == descriptor._tinest_token then
      ref = owner.ref
      owner.metadata.name = descriptor.name
      owner.metadata.generation = selected_tool_generation
      reference_kind = owner.metadata.kind
    else
      reference_kind = descriptor._tinest_template == true and
        "selected_template" or "selected_tool"
      ref = make_ref({
        kind = reference_kind,
        id = descriptor.id,
        name = descriptor.name,
        generation = selected_tool_generation,
        token = descriptor._tinest_token,
      })
    end
    descriptor.ref = ref
    descriptor._tinest_token = nil
    descriptor._tinest_template = nil
    if reference_kind == "selected_tool" or
        reference_kind == "dynamic_tool" or
        reference_kind == "dynamic_from" then
      selected_tools_by_name[descriptor.name] = ref
    end
  end
  return descriptors
end
references[tinest.tools.list] = {kind="primitive", id="tools.list", capabilities={"tools.list"}, effects={}}

---@generic I, O
---@param tool_ref tinest.ToolRef<I, O>
---@param arguments I
---@param options? {call_id?: string}
---@return O
function tinest.tools.invoke(tool_ref, arguments, options)
  local selected = references[tool_ref]
  if selected == nil or
      (selected.kind ~= "selected_tool" and
       selected.kind ~= "dynamic_tool" and
       selected.kind ~= "dynamic_from") then
    fail("tool must be a selected Tinest ToolRef", 2)
  end
  if selected.generation ~= selected_tool_generation then
    fail("tool reference is stale for the current selected surface", 2)
  end
  options = options or {}
  if selected.kind == "dynamic_tool" then
    if type(selected.token) ~= "string" or selected.token == "" then
      fail("dynamic tool must be surfaced before invocation", 2)
    end
    local public = copy_json(arguments)
    local begun = checked_call("tools.dynamic_begin", {
      id = selected.id,
      token = selected.token,
      arguments = public,
      call_id = options.call_id,
    })
    if type(begun) ~= "table" then
      fail("dynamic tool begin returned an invalid result", 2)
    end
    if begun.execute == false then
      return begun.result
    end
    if begun.execute ~= true or type(begun.call_id) ~= "string" then
      fail("dynamic tool begin did not return an invocation ID", 2)
    end
    local previous_dynamic_token = active_dynamic_token
    active_dynamic_token = selected.token
    local callback_context = copy_json(begun.context or {})
    callback_context.call_id = begun.call_id
    callback_context.dynamic = true
    local result = table.pack(pcall(
      selected.callback, public, callback_context
    ))
    active_dynamic_token = previous_dynamic_token
    local completion
    if result[1] then
      completion = checked_call("tools.dynamic_end", {
        id = selected.id,
        token = selected.token,
        call_id = begun.call_id,
        result = result[2],
      })
    else
      completion = checked_call("tools.dynamic_end", {
        id = selected.id,
        token = selected.token,
        call_id = begun.call_id,
        error = tostring(result[2]),
      })
    end
    return completion
  end
  return checked_call("tools.invoke", {
    id = selected.id,
    token = selected.token,
    arguments = copy_json(arguments),
    call_id = options.call_id,
  })
end
references[tinest.tools.invoke] = {kind="primitive", id="tools.invoke", capabilities={"tools.invoke"}, effects={}}

---@param tool_refs tinest.ToolRef<any, any>[]
---@return table
function tinest.tools.surface(tool_refs)
  local ids, dynamic = {}, {}
  for index, tool_ref in ipairs(tool_refs or {}) do
    local selected = references[tool_ref]
    if selected == nil then
      fail("tools[" .. index .. "] must be a Tinest ToolRef", 2)
    end
    if selected.kind == "selected_tool" then
      if selected.generation ~= selected_tool_generation then
        fail("tool reference is stale for the current selected surface", 2)
      end
      ids[#ids + 1] = selected.id
    elseif selected.kind == "dynamic_tool" or
        selected.kind == "dynamic_from" then
      if selected.generation ~= nil and
          selected.generation ~= selected_tool_generation then
        fail("dynamic tool reference is stale", 2)
      end
      dynamic[#dynamic + 1] = {
        mode = selected.kind == "dynamic_from" and "from_template" or "ephemeral",
        private_ref_id = selected.private_id,
        spec = copy_registration(selected.wire),
      }
    else
      fail("tools[" .. index .. "] is not surfaceable", 2)
    end
  end
  local result = checked_call("tools.surface", {ids = ids, dynamic = dynamic})
  local refs_by_private_id = {}
  for _, tool_ref in ipairs(tool_refs or {}) do
    local selected = references[tool_ref]
    if selected.kind == "dynamic_tool" or selected.kind == "dynamic_from" then
      refs_by_private_id[tostring(selected.private_id)] = {
        ref = tool_ref,
        metadata = selected,
      }
    end
  end
  for _, descriptor in ipairs(result.tools or {}) do
    local private_id = tostring(descriptor._tinest_private_ref_id or "")
    local owner = refs_by_private_id[private_id]
    if owner ~= nil then
      local contribution_id = descriptor.canonical_name
      if type(contribution_id) ~= "string" or contribution_id == "" then
        fail("surfaced dynamic tool is missing its canonical name", 2)
      end
      owner.metadata.id = contribution_id
      owner.metadata.name = descriptor.name
      owner.metadata.token = descriptor._tinest_token
      owner.metadata.generation = selected_tool_generation
      surfaced_dynamic_by_id[contribution_id] = owner
      descriptor.ref = owner.ref
      descriptor._tinest_private_ref_id = nil
      descriptor._tinest_token = nil
      selected_tools_by_name[descriptor.name] = owner.ref
    end
  end
  return result
end
references[tinest.tools.surface] = {kind="primitive", id="tools.surface", capabilities={"tools.list"}, effects={}}

---@generic I, O
---@param selected_ref tinest.ToolRef<I, O>
---@param definition_ref tinest.ToolRef<I, O>
---@return boolean
function tinest.tools.is_selected(selected_ref, definition_ref)
  local selected = require_ref(selected_ref, "selected_tool", "selected tool", 2)
  local definition = require_ref(definition_ref, "tool", "tool definition", 2)
  if selected.generation ~= selected_tool_generation then
    fail("tool reference is stale for the current selected surface", 2)
  end
  return selected.id == qualified(definition.id)
end

---@generic I, O
---@param definition_ref tinest.ToolRef<I, O>
---@param descriptors tinest.ToolDescriptor<any, any>[]
---@return tinest.ToolDescriptor<I, O>?
function tinest.tools.resolve(definition_ref, descriptors)
  require_ref(definition_ref, "tool", "tool definition", 2)
  for _, descriptor in ipairs(descriptors or {}) do
    if type(descriptor) == "table" and descriptor.ref ~= nil and
        tinest.tools.is_selected(descriptor.ref, definition_ref) then
      return descriptor
    end
  end
  return nil
end

local function install_primitive(scope, member, capability, effect, stream)
  tinest.host[scope][member] = primitive(
    "host." .. scope .. "." .. member,
    capability == nil and {} or {capability},
    effect == nil and {} or {effect},
    stream == true
  )
end

require("tinest.host_primitives")(tinest, install_primitive, references)

local function definition_item(value, expected, label)
  return copy_json(require_ref(value, expected, label, 3).wire)
end

local function definition_items(values, expected, label)
  local result = {}
  for index, value in ipairs(values or {}) do
    result[index] = definition_item(value, expected, label .. "[" .. index .. "]")
  end
  return result
end

---@param spec tinest.PluginDefinition
---@return tinest.DefinitionRef
function tinest.plugin.define(spec)
  if definition_created then fail("tinest.plugin.define may be called once", 2) end
  definition_created = true
  spec = expect_table(spec, "plugin definition", 2)
  local wire = {
    tools = definition_items(spec.tools, "tool", "tools"),
    templates = definition_items(spec.templates, "tool_template", "templates"),
    session_controls = definition_items(spec.session_controls, "session_control", "session_controls"),
    ui = definition_items(spec.ui, "ui", "ui"),
    ui_actions = definition_items(spec.actions, "action", "actions"),
    hooks = {},
  }
  if spec.driver ~= nil then wire.driver = definition_item(spec.driver, "driver", "driver") end
  for index, hook_ref in ipairs(spec.hooks or {}) do
    local hook = require_ref(hook_ref, "hook", "hooks[" .. index .. "]", 2)
    if wire.hooks[hook.lifecycle] ~= nil then
      fail("duplicate lifecycle hook: " .. hook.lifecycle, 2)
    end
    wire.hooks[hook.lifecycle] = copy_json(hook.wire)
  end
  return make_ref({kind = "definition", id = "definition", wire = wire})
end

function tinest.__entrypoint(definition)
  local metadata = require_ref(definition, "definition", "plugin entrypoint return", 2)
  local exported = {}
  for key, callback in pairs(bound_handlers) do exported[key] = callback end
  exported.define = function(_arguments)
    return {api = 5, spec = copy_json(metadata.wire)}
  end
  return exported
end

return tinest
