// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
    );

Map<String, dynamic> _$GitBranchDtoToJson(_GitBranchDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'current': instance.current,
      'checkedOut': instance.checkedOut,
    };

_AgentDto _$AgentDtoFromJson(Map<String, dynamic> json) => _AgentDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  providerConnectionId: json['providerConnectionId'] as String,
  model: json['model'] as String,
  status: $enumDecode(_$AgentStatusEnumMap, json['status']),
  permissionMode: $enumDecode(_$PermissionModeEnumMap, json['permissionMode']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  reasoningEffort: json['reasoningEffort'] as String? ?? 'medium',
  activeTurnId: json['activeTurnId'] as String?,
  lastError: json['lastError'] as String?,
);

Map<String, dynamic> _$AgentDtoToJson(_AgentDto instance) => <String, dynamic>{
  'id': instance.id,
  'worktreeId': instance.worktreeId,
  'title': instance.title,
  'providerConnectionId': instance.providerConnectionId,
  'model': instance.model,
  'status': _$AgentStatusEnumMap[instance.status]!,
  'permissionMode': _$PermissionModeEnumMap[instance.permissionMode]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'reasoningEffort': instance.reasoningEffort,
  'activeTurnId': instance.activeTurnId,
  'lastError': instance.lastError,
};

const _$AgentStatusEnumMap = {
  AgentStatus.initializing: 'initializing',
  AgentStatus.idle: 'idle',
  AgentStatus.running: 'running',
  AgentStatus.waitingForApproval: 'waitingForApproval',
  AgentStatus.failed: 'failed',
  AgentStatus.closed: 'closed',
};

const _$PermissionModeEnumMap = {
  PermissionMode.readOnly: 'readOnly',
  PermissionMode.ask: 'ask',
  PermissionMode.workspaceWrite: 'workspaceWrite',
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
  isDefault: json['isDefault'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  defaultModelId: json['defaultModelId'] as String?,
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
  'isDefault': instance.isDefault,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'defaultModelId': instance.defaultModelId,
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
      agentId: json['agentId'] as String,
      sequence: (json['sequence'] as num).toInt(),
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      turnId: json['turnId'] as String?,
    );

Map<String, dynamic> _$TimelineEventDtoToJson(_TimelineEventDto instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'sequence': instance.sequence,
      'type': instance.type,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'turnId': instance.turnId,
    };

_ApprovalRequestDto _$ApprovalRequestDtoFromJson(Map<String, dynamic> json) =>
    _ApprovalRequestDto(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
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
      'agentId': instance.agentId,
      'turnId': instance.turnId,
      'toolCallId': instance.toolCallId,
      'toolName': instance.toolName,
      'risk': _$ToolRiskEnumMap[instance.risk]!,
      'arguments': instance.arguments,
      'status': _$ApprovalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'preview': instance.preview,
    };

const _$ToolRiskEnumMap = {
  ToolRisk.read: 'read',
  ToolRisk.write: 'write',
  ToolRisk.command: 'command',
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
