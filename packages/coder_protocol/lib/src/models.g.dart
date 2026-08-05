// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttachmentDto _$AttachmentDtoFromJson(Map<String, dynamic> json) =>
    _AttachmentDto(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      byteSize: (json['byteSize'] as num).toInt(),
      kind: $enumDecode(_$AttachmentKindEnumMap, json['kind']),
      sha256: json['sha256'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AttachmentDtoToJson(_AttachmentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'byteSize': instance.byteSize,
      'kind': _$AttachmentKindEnumMap[instance.kind]!,
      'sha256': instance.sha256,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$AttachmentKindEnumMap = {
  AttachmentKind.image: 'image',
  AttachmentKind.file: 'file',
};

_WorkspaceDto _$WorkspaceDtoFromJson(Map<String, dynamic> json) =>
    _WorkspaceDto(
      id: json['id'] as String,
      name: json['name'] as String,
      rootPath: json['rootPath'] as String,
      kind: $enumDecode(_$WorkspaceKindEnumMap, json['kind']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WorkspaceDtoToJson(_WorkspaceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rootPath': instance.rootPath,
      'kind': _$WorkspaceKindEnumMap[instance.kind]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$WorkspaceKindEnumMap = {
  WorkspaceKind.git: 'git',
  WorkspaceKind.directory: 'directory',
};

_WorktreeDto _$WorktreeDtoFromJson(Map<String, dynamic> json) => _WorktreeDto(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  kind: $enumDecode(_$WorktreeKindEnumMap, json['kind']),
  isCoderOwned: json['isCoderOwned'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  branch: json['branch'] as String?,
  head: json['head'] as String?,
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
);

Map<String, dynamic> _$WorktreeDtoToJson(_WorktreeDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workspaceId': instance.workspaceId,
      'name': instance.name,
      'path': instance.path,
      'kind': _$WorktreeKindEnumMap[instance.kind]!,
      'isCoderOwned': instance.isCoderOwned,
      'createdAt': instance.createdAt.toIso8601String(),
      'branch': instance.branch,
      'head': instance.head,
      'archivedAt': instance.archivedAt?.toIso8601String(),
    };

const _$WorktreeKindEnumMap = {
  WorktreeKind.checkout: 'checkout',
  WorktreeKind.managed: 'managed',
  WorktreeKind.external: 'external',
  WorktreeKind.directory: 'directory',
};

_WorkspaceCatalogDto _$WorkspaceCatalogDtoFromJson(Map<String, dynamic> json) =>
    _WorkspaceCatalogDto(
      workspaces: (json['workspaces'] as List<dynamic>)
          .map((e) => WorkspaceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      worktrees: (json['worktrees'] as List<dynamic>)
          .map((e) => WorktreeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkspaceCatalogDtoToJson(
  _WorkspaceCatalogDto instance,
) => <String, dynamic>{
  'workspaces': instance.workspaces,
  'worktrees': instance.worktrees,
};

_WorktreeArchivePreviewDto _$WorktreeArchivePreviewDtoFromJson(
  Map<String, dynamic> json,
) => _WorktreeArchivePreviewDto(
  worktreeId: json['worktreeId'] as String,
  dirty: json['dirty'] as bool,
  unpushedCommitCount: (json['unpushedCommitCount'] as num).toInt(),
  runningSessionCount: (json['runningSessionCount'] as num).toInt(),
  removesDirectory: json['removesDirectory'] as bool,
);

Map<String, dynamic> _$WorktreeArchivePreviewDtoToJson(
  _WorktreeArchivePreviewDto instance,
) => <String, dynamic>{
  'worktreeId': instance.worktreeId,
  'dirty': instance.dirty,
  'unpushedCommitCount': instance.unpushedCommitCount,
  'runningSessionCount': instance.runningSessionCount,
  'removesDirectory': instance.removesDirectory,
};

_ProjectSettingsDto _$ProjectSettingsDtoFromJson(Map<String, dynamic> json) =>
    _ProjectSettingsDto(
      setup:
          (json['setup'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      teardown:
          (json['teardown'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ProjectSettingsDtoToJson(_ProjectSettingsDto instance) =>
    <String, dynamic>{'setup': instance.setup, 'teardown': instance.teardown};

_WorktreeHookRunDto _$WorktreeHookRunDtoFromJson(Map<String, dynamic> json) =>
    _WorktreeHookRunDto(
      phase: $enumDecode(_$WorktreeHookPhaseEnumMap, json['phase']),
      command: json['command'] as String,
      exitCode: (json['exitCode'] as num).toInt(),
      stdout: json['stdout'] as String,
      stderr: json['stderr'] as String,
    );

Map<String, dynamic> _$WorktreeHookRunDtoToJson(_WorktreeHookRunDto instance) =>
    <String, dynamic>{
      'phase': _$WorktreeHookPhaseEnumMap[instance.phase]!,
      'command': instance.command,
      'exitCode': instance.exitCode,
      'stdout': instance.stdout,
      'stderr': instance.stderr,
    };

const _$WorktreeHookPhaseEnumMap = {
  WorktreeHookPhase.setup: 'setup',
  WorktreeHookPhase.teardown: 'teardown',
};

_DirectorySuggestionDto _$DirectorySuggestionDtoFromJson(
  Map<String, dynamic> json,
) => _DirectorySuggestionDto(
  path: json['path'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$DirectorySuggestionDtoToJson(
  _DirectorySuggestionDto instance,
) => <String, dynamic>{'path': instance.path, 'name': instance.name};

_GitBranchDto _$GitBranchDtoFromJson(Map<String, dynamic> json) =>
    _GitBranchDto(
      name: json['name'] as String,
      current: json['current'] as bool,
      checkedOut: json['checkedOut'] as bool,
      isRemote: json['isRemote'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$GitBranchDtoToJson(_GitBranchDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'current': instance.current,
      'checkedOut': instance.checkedOut,
      'isRemote': instance.isRemote,
      'isDefault': instance.isDefault,
    };

_AgentModelSelectionDto _$AgentModelSelectionDtoFromJson(
  Map<String, dynamic> json,
) => _AgentModelSelectionDto(
  source: $enumDecode(_$AgentModelSourceEnumMap, json['source']),
  providerConnectionId: json['providerConnectionId'] as String?,
  modelId: json['modelId'] as String?,
);

Map<String, dynamic> _$AgentModelSelectionDtoToJson(
  _AgentModelSelectionDto instance,
) => <String, dynamic>{
  'source': _$AgentModelSourceEnumMap[instance.source]!,
  'providerConnectionId': instance.providerConnectionId,
  'modelId': instance.modelId,
};

const _$AgentModelSourceEnumMap = {
  AgentModelSource.session: 'session',
  AgentModelSource.fixed: 'fixed',
};

_AgentDefinitionDiagnosticDto _$AgentDefinitionDiagnosticDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionDiagnosticDto(
  code: json['code'] as String,
  message: json['message'] as String,
  line: (json['line'] as num?)?.toInt(),
  column: (json['column'] as num?)?.toInt(),
);

Map<String, dynamic> _$AgentDefinitionDiagnosticDtoToJson(
  _AgentDefinitionDiagnosticDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'message': instance.message,
  'line': instance.line,
  'column': instance.column,
};

_AgentDefinitionDto _$AgentDefinitionDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  mode: $enumDecode(_$AgentModeEnumMap, json['mode']),
  promptEnabled: json['promptEnabled'] as bool,
  systemPrompt: json['systemPrompt'] as String,
  model: AgentModelSelectionDto.fromJson(json['model'] as Map<String, dynamic>),
  reasoningEffort: json['reasoningEffort'] as String,
  permissionMode: $enumDecode(_$PermissionModeEnumMap, json['permissionMode']),
  toolIds: (json['toolIds'] as List<dynamic>).map((e) => e as String).toList(),
  callableAgentIds: (json['callableAgentIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  contentHash: json['contentHash'] as String,
  sourcePath: json['sourcePath'] as String,
  isBuiltIn: json['isBuiltIn'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  isStale: json['isStale'] as bool? ?? false,
  diagnostics:
      (json['diagnostics'] as List<dynamic>?)
          ?.map(
            (e) => AgentDefinitionDiagnosticDto.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <AgentDefinitionDiagnosticDto>[],
);

Map<String, dynamic> _$AgentDefinitionDtoToJson(_AgentDefinitionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'mode': _$AgentModeEnumMap[instance.mode]!,
      'promptEnabled': instance.promptEnabled,
      'systemPrompt': instance.systemPrompt,
      'model': instance.model,
      'reasoningEffort': instance.reasoningEffort,
      'permissionMode': _$PermissionModeEnumMap[instance.permissionMode]!,
      'toolIds': instance.toolIds,
      'callableAgentIds': instance.callableAgentIds,
      'contentHash': instance.contentHash,
      'sourcePath': instance.sourcePath,
      'isBuiltIn': instance.isBuiltIn,
      'isArchived': instance.isArchived,
      'isStale': instance.isStale,
      'diagnostics': instance.diagnostics,
    };

const _$AgentModeEnumMap = {
  AgentMode.primary: 'primary',
  AgentMode.subagent: 'subagent',
};

const _$PermissionModeEnumMap = {
  PermissionMode.readOnly: 'readOnly',
  PermissionMode.ask: 'ask',
  PermissionMode.workspaceWrite: 'workspaceWrite',
};

_AgentToolDefinitionDto _$AgentToolDefinitionDtoFromJson(
  Map<String, dynamic> json,
) => _AgentToolDefinitionDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  risk: $enumDecode(_$ToolRiskEnumMap, json['risk']),
  available: json['available'] as bool? ?? true,
  alwaysOn: json['alwaysOn'] as bool? ?? false,
);

Map<String, dynamic> _$AgentToolDefinitionDtoToJson(
  _AgentToolDefinitionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'risk': _$ToolRiskEnumMap[instance.risk]!,
  'available': instance.available,
  'alwaysOn': instance.alwaysOn,
};

const _$ToolRiskEnumMap = {
  ToolRisk.read: 'read',
  ToolRisk.write: 'write',
  ToolRisk.command: 'command',
  ToolRisk.dangerous: 'dangerous',
};

_McpServerConfigDto _$McpServerConfigDtoFromJson(Map<String, dynamic> json) =>
    _McpServerConfigDto(
      id: json['id'] as String,
      transport: $enumDecode(_$McpTransportKindEnumMap, json['transport']),
      enabled: json['enabled'] as bool? ?? true,
      command: json['command'] as String?,
      args:
          (json['args'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      env:
          (json['env'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      cwd: json['cwd'] as String?,
      url: json['url'] as String?,
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
    );

Map<String, dynamic> _$McpServerConfigDtoToJson(_McpServerConfigDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transport': _$McpTransportKindEnumMap[instance.transport]!,
      'enabled': instance.enabled,
      'command': instance.command,
      'args': instance.args,
      'env': instance.env,
      'cwd': instance.cwd,
      'url': instance.url,
      'headers': instance.headers,
    };

const _$McpTransportKindEnumMap = {
  McpTransportKind.stdio: 'stdio',
  McpTransportKind.http: 'http',
};

_McpToolSummaryDto _$McpToolSummaryDtoFromJson(Map<String, dynamic> json) =>
    _McpToolSummaryDto(
      toolId: json['toolId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$McpToolSummaryDtoToJson(_McpToolSummaryDto instance) =>
    <String, dynamic>{
      'toolId': instance.toolId,
      'name': instance.name,
      'description': instance.description,
      'title': instance.title,
    };

_McpServerStateDto _$McpServerStateDtoFromJson(
  Map<String, dynamic> json,
) => _McpServerStateDto(
  config: McpServerConfigDto.fromJson(json['config'] as Map<String, dynamic>),
  status: $enumDecode(_$McpServerStatusEnumMap, json['status']),
  scope: $enumDecode(_$McpConfigScopeEnumMap, json['scope']),
  sourcePath: json['sourcePath'] as String,
  shadowed: json['shadowed'] as bool? ?? false,
  protocolVersion: json['protocolVersion'] as String?,
  serverName: json['serverName'] as String?,
  serverVersion: json['serverVersion'] as String?,
  tools:
      (json['tools'] as List<dynamic>?)
          ?.map((e) => McpToolSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <McpToolSummaryDto>[],
  error: json['error'] as String?,
  diagnostics:
      (json['diagnostics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  lastConnectedAt: json['lastConnectedAt'] == null
      ? null
      : DateTime.parse(json['lastConnectedAt'] as String),
  nextRetryAt: json['nextRetryAt'] == null
      ? null
      : DateTime.parse(json['nextRetryAt'] as String),
  attempt: (json['attempt'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$McpServerStateDtoToJson(_McpServerStateDto instance) =>
    <String, dynamic>{
      'config': instance.config,
      'status': _$McpServerStatusEnumMap[instance.status]!,
      'scope': _$McpConfigScopeEnumMap[instance.scope]!,
      'sourcePath': instance.sourcePath,
      'shadowed': instance.shadowed,
      'protocolVersion': instance.protocolVersion,
      'serverName': instance.serverName,
      'serverVersion': instance.serverVersion,
      'tools': instance.tools,
      'error': instance.error,
      'diagnostics': instance.diagnostics,
      'lastConnectedAt': instance.lastConnectedAt?.toIso8601String(),
      'nextRetryAt': instance.nextRetryAt?.toIso8601String(),
      'attempt': instance.attempt,
    };

const _$McpServerStatusEnumMap = {
  McpServerStatus.disabled: 'disabled',
  McpServerStatus.connecting: 'connecting',
  McpServerStatus.ready: 'ready',
  McpServerStatus.failed: 'failed',
};

const _$McpConfigScopeEnumMap = {
  McpConfigScope.user: 'user',
  McpConfigScope.project: 'project',
};

_SkillDiagnosticDto _$SkillDiagnosticDtoFromJson(Map<String, dynamic> json) =>
    _SkillDiagnosticDto(
      code: json['code'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$SkillDiagnosticDtoToJson(_SkillDiagnosticDto instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};

_SkillResourceDto _$SkillResourceDtoFromJson(Map<String, dynamic> json) =>
    _SkillResourceDto(
      path: json['path'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
    );

Map<String, dynamic> _$SkillResourceDtoToJson(_SkillResourceDto instance) =>
    <String, dynamic>{'path': instance.path, 'sizeBytes': instance.sizeBytes};

_SkillDto _$SkillDtoFromJson(Map<String, dynamic> json) => _SkillDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  source: $enumDecode(_$SkillSourceEnumMap, json['source']),
  sourcePath: json['sourcePath'] as String,
  contentHash: json['contentHash'] as String,
  body: json['body'] as String,
  resources:
      (json['resources'] as List<dynamic>?)
          ?.map((e) => SkillResourceDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SkillResourceDto>[],
  isEnabled: json['isEnabled'] as bool? ?? true,
  isMandatory: json['isMandatory'] as bool? ?? false,
  isEditable: json['isEditable'] as bool? ?? false,
  isShadowed: json['isShadowed'] as bool? ?? false,
  isStale: json['isStale'] as bool? ?? false,
  diagnostics:
      (json['diagnostics'] as List<dynamic>?)
          ?.map((e) => SkillDiagnosticDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SkillDiagnosticDto>[],
);

Map<String, dynamic> _$SkillDtoToJson(_SkillDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'source': _$SkillSourceEnumMap[instance.source]!,
  'sourcePath': instance.sourcePath,
  'contentHash': instance.contentHash,
  'body': instance.body,
  'resources': instance.resources,
  'isEnabled': instance.isEnabled,
  'isMandatory': instance.isMandatory,
  'isEditable': instance.isEditable,
  'isShadowed': instance.isShadowed,
  'isStale': instance.isStale,
  'diagnostics': instance.diagnostics,
};

const _$SkillSourceEnumMap = {
  SkillSource.builtIn: 'builtIn',
  SkillSource.userHome: 'userHome',
  SkillSource.config: 'config',
  SkillSource.project: 'project',
};

_SessionModelSelectionDto _$SessionModelSelectionDtoFromJson(
  Map<String, dynamic> json,
) => _SessionModelSelectionDto(
  providerConnectionId: json['providerConnectionId'] as String,
  modelId: json['modelId'] as String,
);

Map<String, dynamic> _$SessionModelSelectionDtoToJson(
  _SessionModelSelectionDto instance,
) => <String, dynamic>{
  'providerConnectionId': instance.providerConnectionId,
  'modelId': instance.modelId,
};

_SessionDto _$SessionDtoFromJson(Map<String, dynamic> json) => _SessionDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  agentDefinitionId: json['agentDefinitionId'] as String,
  origin: $enumDecode(_$SessionOriginEnumMap, json['origin']),
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  mode:
      $enumDecodeNullable(_$SessionModeEnumMap, json['mode']) ??
      SessionMode.normal,
  model: json['model'] == null
      ? null
      : SessionModelSelectionDto.fromJson(
          json['model'] as Map<String, dynamic>,
        ),
  parentSessionId: json['parentSessionId'] as String?,
  activeTurnId: json['activeTurnId'] as String?,
  lastError: json['lastError'] as String?,
);

Map<String, dynamic> _$SessionDtoToJson(_SessionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'worktreeId': instance.worktreeId,
      'title': instance.title,
      'agentDefinitionId': instance.agentDefinitionId,
      'origin': _$SessionOriginEnumMap[instance.origin]!,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'mode': _$SessionModeEnumMap[instance.mode]!,
      'model': instance.model,
      'parentSessionId': instance.parentSessionId,
      'activeTurnId': instance.activeTurnId,
      'lastError': instance.lastError,
    };

const _$SessionOriginEnumMap = {
  SessionOrigin.manual: 'manual',
  SessionOrigin.delegated: 'delegated',
};

const _$SessionStatusEnumMap = {
  SessionStatus.initializing: 'initializing',
  SessionStatus.idle: 'idle',
  SessionStatus.running: 'running',
  SessionStatus.waitingForApproval: 'waitingForApproval',
  SessionStatus.waitingForSubagent: 'waitingForSubagent',
  SessionStatus.failed: 'failed',
  SessionStatus.closed: 'closed',
};

const _$SessionModeEnumMap = {
  SessionMode.plan: 'plan',
  SessionMode.normal: 'normal',
};

_ModelCapabilitiesDto _$ModelCapabilitiesDtoFromJson(
  Map<String, dynamic> json,
) => _ModelCapabilitiesDto(
  streaming:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['streaming']) ??
      CapabilitySupport.unknown,
  toolCalling:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['toolCalling']) ??
      CapabilitySupport.unknown,
  reasoningEffort:
      $enumDecodeNullable(
        _$CapabilitySupportEnumMap,
        json['reasoningEffort'],
      ) ??
      CapabilitySupport.unknown,
  imageInput:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['imageInput']) ??
      CapabilitySupport.unknown,
  fileInput:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['fileInput']) ??
      CapabilitySupport.unknown,
  supportedReasoningEfforts:
      (json['supportedReasoningEfforts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  source:
      $enumDecodeNullable(_$CapabilitySourceEnumMap, json['source']) ??
      CapabilitySource.unknown,
);

Map<String, dynamic> _$ModelCapabilitiesDtoToJson(
  _ModelCapabilitiesDto instance,
) => <String, dynamic>{
  'streaming': _$CapabilitySupportEnumMap[instance.streaming]!,
  'toolCalling': _$CapabilitySupportEnumMap[instance.toolCalling]!,
  'reasoningEffort': _$CapabilitySupportEnumMap[instance.reasoningEffort]!,
  'imageInput': _$CapabilitySupportEnumMap[instance.imageInput]!,
  'fileInput': _$CapabilitySupportEnumMap[instance.fileInput]!,
  'supportedReasoningEfforts': instance.supportedReasoningEfforts,
  'source': _$CapabilitySourceEnumMap[instance.source]!,
};

const _$CapabilitySupportEnumMap = {
  CapabilitySupport.unknown: 'unknown',
  CapabilitySupport.supported: 'supported',
  CapabilitySupport.unsupported: 'unsupported',
};

const _$CapabilitySourceEnumMap = {
  CapabilitySource.unknown: 'unknown',
  CapabilitySource.bundled: 'bundled',
  CapabilitySource.refreshed: 'refreshed',
  CapabilitySource.diagnostic: 'diagnostic',
  CapabilitySource.manual: 'manual',
};

_ModelPricingDto _$ModelPricingDtoFromJson(Map<String, dynamic> json) =>
    _ModelPricingDto(
      input: (json['input'] as num?)?.toDouble(),
      output: (json['output'] as num?)?.toDouble(),
      cacheRead: (json['cacheRead'] as num?)?.toDouble(),
      cacheWrite: (json['cacheWrite'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ModelPricingDtoToJson(_ModelPricingDto instance) =>
    <String, dynamic>{
      'input': instance.input,
      'output': instance.output,
      'cacheRead': instance.cacheRead,
      'cacheWrite': instance.cacheWrite,
    };

_ModelLimitsDto _$ModelLimitsDtoFromJson(Map<String, dynamic> json) =>
    _ModelLimitsDto(
      context: (json['context'] as num?)?.toInt(),
      input: (json['input'] as num?)?.toInt(),
      output: (json['output'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ModelLimitsDtoToJson(_ModelLimitsDto instance) =>
    <String, dynamic>{
      'context': instance.context,
      'input': instance.input,
      'output': instance.output,
    };

_ProviderAuthMethodDto _$ProviderAuthMethodDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthMethodDto(
  id: json['id'] as String,
  label: json['label'] as String,
  kind: $enumDecode(_$ProviderAuthKindEnumMap, json['kind']),
  flow: $enumDecode(_$ProviderAuthFlowEnumMap, json['flow']),
  experimental: json['experimental'] as bool? ?? false,
);

Map<String, dynamic> _$ProviderAuthMethodDtoToJson(
  _ProviderAuthMethodDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'kind': _$ProviderAuthKindEnumMap[instance.kind]!,
  'flow': _$ProviderAuthFlowEnumMap[instance.flow]!,
  'experimental': instance.experimental,
};

const _$ProviderAuthKindEnumMap = {
  ProviderAuthKind.apiKey: 'apiKey',
  ProviderAuthKind.oauth: 'oauth',
  ProviderAuthKind.none: 'none',
};

const _$ProviderAuthFlowEnumMap = {
  ProviderAuthFlow.apiKey: 'apiKey',
  ProviderAuthFlow.oauthBrowser: 'oauthBrowser',
  ProviderAuthFlow.oauthDevice: 'oauthDevice',
  ProviderAuthFlow.none: 'none',
};

_ProviderDefinitionDto _$ProviderDefinitionDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDefinitionDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  authMethods: (json['authMethods'] as List<dynamic>)
      .map((e) => ProviderAuthMethodDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendedModelIds:
      (json['recommendedModelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  local: json['local'] as bool? ?? false,
  experimental: json['experimental'] as bool? ?? false,
  documentationUrl: json['documentationUrl'] as String?,
);

Map<String, dynamic> _$ProviderDefinitionDtoToJson(
  _ProviderDefinitionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'authMethods': instance.authMethods,
  'recommendedModelIds': instance.recommendedModelIds,
  'local': instance.local,
  'experimental': instance.experimental,
  'documentationUrl': instance.documentationUrl,
};

_CustomProviderConfigDto _$CustomProviderConfigDtoFromJson(
  Map<String, dynamic> json,
) => _CustomProviderConfigDto(
  name: json['name'] as String,
  baseUrl: json['baseUrl'] as String,
  apiFormat: $enumDecode(_$ProviderApiFormatEnumMap, json['apiFormat']),
  authenticationRequired: json['authenticationRequired'] as bool,
  strictToolSchema: json['strictToolSchema'] as bool? ?? false,
  manualModelIds:
      (json['manualModelIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$CustomProviderConfigDtoToJson(
  _CustomProviderConfigDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'baseUrl': instance.baseUrl,
  'apiFormat': _$ProviderApiFormatEnumMap[instance.apiFormat]!,
  'authenticationRequired': instance.authenticationRequired,
  'strictToolSchema': instance.strictToolSchema,
  'manualModelIds': instance.manualModelIds,
};

const _$ProviderApiFormatEnumMap = {
  ProviderApiFormat.responses: 'responses',
  ProviderApiFormat.chatCompletions: 'chatCompletions',
};

_ProviderConnectionDto _$ProviderConnectionDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectionDto(
  id: json['id'] as String,
  definitionId: json['definitionId'] as String,
  displayName: json['displayName'] as String,
  status: $enumDecode(_$ProviderConnectionStatusEnumMap, json['status']),
  authKind: $enumDecode(_$ProviderAuthKindEnumMap, json['authKind']),
  credentialOrigin: $enumDecode(
    _$ProviderCredentialOriginEnumMap,
    json['credentialOrigin'],
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  error: json['error'] as String?,
  customConfig: json['customConfig'] == null
      ? null
      : CustomProviderConfigDto.fromJson(
          json['customConfig'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ProviderConnectionDtoToJson(
  _ProviderConnectionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'definitionId': instance.definitionId,
  'displayName': instance.displayName,
  'status': _$ProviderConnectionStatusEnumMap[instance.status]!,
  'authKind': _$ProviderAuthKindEnumMap[instance.authKind]!,
  'credentialOrigin':
      _$ProviderCredentialOriginEnumMap[instance.credentialOrigin]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'error': instance.error,
  'customConfig': instance.customConfig,
};

const _$ProviderConnectionStatusEnumMap = {
  ProviderConnectionStatus.connecting: 'connecting',
  ProviderConnectionStatus.connected: 'connected',
  ProviderConnectionStatus.degraded: 'degraded',
  ProviderConnectionStatus.error: 'error',
  ProviderConnectionStatus.reauthRequired: 'reauthRequired',
  ProviderConnectionStatus.disconnected: 'disconnected',
};

const _$ProviderCredentialOriginEnumMap = {
  ProviderCredentialOrigin.stored: 'stored',
  ProviderCredentialOrigin.environment: 'environment',
  ProviderCredentialOrigin.oauth: 'oauth',
  ProviderCredentialOrigin.none: 'none',
};

_ProviderAuthAttemptDto _$ProviderAuthAttemptDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthAttemptDto(
  id: json['id'] as String,
  definitionId: json['definitionId'] as String,
  methodId: json['methodId'] as String,
  status: $enumDecode(_$ProviderAuthAttemptStatusEnumMap, json['status']),
  authorizationUrl: json['authorizationUrl'] as String?,
  userCode: json['userCode'] as String?,
  instructions: json['instructions'] as String?,
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ProviderAuthAttemptDtoToJson(
  _ProviderAuthAttemptDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'definitionId': instance.definitionId,
  'methodId': instance.methodId,
  'status': _$ProviderAuthAttemptStatusEnumMap[instance.status]!,
  'authorizationUrl': instance.authorizationUrl,
  'userCode': instance.userCode,
  'instructions': instance.instructions,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'error': instance.error,
};

const _$ProviderAuthAttemptStatusEnumMap = {
  ProviderAuthAttemptStatus.pending: 'pending',
  ProviderAuthAttemptStatus.awaitingUser: 'awaitingUser',
  ProviderAuthAttemptStatus.exchanging: 'exchanging',
  ProviderAuthAttemptStatus.succeeded: 'succeeded',
  ProviderAuthAttemptStatus.failed: 'failed',
  ProviderAuthAttemptStatus.cancelled: 'cancelled',
  ProviderAuthAttemptStatus.expired: 'expired',
};

_ProviderModelDto _$ProviderModelDtoFromJson(Map<String, dynamic> json) =>
    _ProviderModelDto(
      connectionId: json['connectionId'] as String,
      id: json['id'] as String,
      label: json['label'] as String,
      source: $enumDecode(_$ProviderModelSourceEnumMap, json['source']),
      capabilities: ModelCapabilitiesDto.fromJson(
        json['capabilities'] as Map<String, dynamic>,
      ),
      pricing: json['pricing'] == null
          ? null
          : ModelPricingDto.fromJson(json['pricing'] as Map<String, dynamic>),
      limits: json['limits'] == null
          ? null
          : ModelLimitsDto.fromJson(json['limits'] as Map<String, dynamic>),
      diagnosticStatus:
          $enumDecodeNullable(
            _$DiagnosticStatusEnumMap,
            json['diagnosticStatus'],
          ) ??
          DiagnosticStatus.unknown,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      diagnosticError: json['diagnosticError'] as String?,
    );

Map<String, dynamic> _$ProviderModelDtoToJson(_ProviderModelDto instance) =>
    <String, dynamic>{
      'connectionId': instance.connectionId,
      'id': instance.id,
      'label': instance.label,
      'source': _$ProviderModelSourceEnumMap[instance.source]!,
      'capabilities': instance.capabilities,
      'pricing': instance.pricing,
      'limits': instance.limits,
      'diagnosticStatus': _$DiagnosticStatusEnumMap[instance.diagnosticStatus]!,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'diagnosticError': instance.diagnosticError,
    };

const _$ProviderModelSourceEnumMap = {
  ProviderModelSource.bundled: 'bundled',
  ProviderModelSource.refreshed: 'refreshed',
  ProviderModelSource.discovered: 'discovered',
  ProviderModelSource.manual: 'manual',
};

const _$DiagnosticStatusEnumMap = {
  DiagnosticStatus.unknown: 'unknown',
  DiagnosticStatus.verified: 'verified',
  DiagnosticStatus.failed: 'failed',
};

_ProviderCatalogDto _$ProviderCatalogDtoFromJson(Map<String, dynamic> json) =>
    _ProviderCatalogDto(
      definitions: (json['definitions'] as List<dynamic>)
          .map((e) => ProviderDefinitionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      source: $enumDecode(_$ProviderCatalogSourceEnumMap, json['source']),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProviderCatalogDtoToJson(_ProviderCatalogDto instance) =>
    <String, dynamic>{
      'definitions': instance.definitions,
      'source': _$ProviderCatalogSourceEnumMap[instance.source]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProviderCatalogSourceEnumMap = {
  ProviderCatalogSource.bundled: 'bundled',
  ProviderCatalogSource.refreshed: 'refreshed',
};

_ProviderDiagnosticDto _$ProviderDiagnosticDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDiagnosticDto(
  connectionId: json['connectionId'] as String,
  model: json['model'] as String,
  status: $enumDecode(_$DiagnosticStatusEnumMap, json['status']),
  endpointReachable: json['endpointReachable'] as bool,
  streaming: json['streaming'] as bool,
  toolCalling: json['toolCalling'] as bool,
  checkedAt: DateTime.parse(json['checkedAt'] as String),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ProviderDiagnosticDtoToJson(
  _ProviderDiagnosticDto instance,
) => <String, dynamic>{
  'connectionId': instance.connectionId,
  'model': instance.model,
  'status': _$DiagnosticStatusEnumMap[instance.status]!,
  'endpointReachable': instance.endpointReachable,
  'streaming': instance.streaming,
  'toolCalling': instance.toolCalling,
  'checkedAt': instance.checkedAt.toIso8601String(),
  'error': instance.error,
};

_TimelineEventDto _$TimelineEventDtoFromJson(Map<String, dynamic> json) =>
    _TimelineEventDto(
      sessionId: json['sessionId'] as String,
      sequence: (json['sequence'] as num).toInt(),
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      turnId: json['turnId'] as String?,
    );

Map<String, dynamic> _$TimelineEventDtoToJson(_TimelineEventDto instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'sequence': instance.sequence,
      'type': instance.type,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'turnId': instance.turnId,
    };

_ApprovalRequestDto _$ApprovalRequestDtoFromJson(Map<String, dynamic> json) =>
    _ApprovalRequestDto(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      turnId: json['turnId'] as String,
      toolCallId: json['toolCallId'] as String,
      toolName: json['toolName'] as String,
      risk: $enumDecode(_$ToolRiskEnumMap, json['risk']),
      arguments: json['arguments'] as Map<String, dynamic>,
      status: $enumDecode(_$ApprovalStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      preview: json['preview'] as String?,
    );

Map<String, dynamic> _$ApprovalRequestDtoToJson(_ApprovalRequestDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'turnId': instance.turnId,
      'toolCallId': instance.toolCallId,
      'toolName': instance.toolName,
      'risk': _$ToolRiskEnumMap[instance.risk]!,
      'arguments': instance.arguments,
      'status': _$ApprovalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'preview': instance.preview,
    };

const _$ApprovalStatusEnumMap = {
  ApprovalStatus.pending: 'pending',
  ApprovalStatus.approved: 'approved',
  ApprovalStatus.denied: 'denied',
  ApprovalStatus.cancelled: 'cancelled',
};

_ServerInfoDto _$ServerInfoDtoFromJson(Map<String, dynamic> json) =>
    _ServerInfoDto(
      serverId: json['serverId'] as String,
      version: json['version'] as String,
      protocolVersion: (json['protocolVersion'] as num).toInt(),
      features: Map<String, bool>.from(json['features'] as Map),
    );

Map<String, dynamic> _$ServerInfoDtoToJson(_ServerInfoDto instance) =>
    <String, dynamic>{
      'serverId': instance.serverId,
      'version': instance.version,
      'protocolVersion': instance.protocolVersion,
      'features': instance.features,
    };

_RpcErrorDto _$RpcErrorDtoFromJson(Map<String, dynamic> json) => _RpcErrorDto(
  code: json['code'] as String,
  message: json['message'] as String,
  retryable: json['retryable'] as bool,
  details: json['details'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RpcErrorDtoToJson(_RpcErrorDto instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'retryable': instance.retryable,
      'details': instance.details,
    };
