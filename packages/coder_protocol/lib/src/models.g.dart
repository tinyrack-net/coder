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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$WorkspaceDtoToJson(_WorkspaceDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rootPath': instance.rootPath,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_AgentDto _$AgentDtoFromJson(Map<String, dynamic> json) => _AgentDto(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  title: json['title'] as String,
  providerId: json['providerId'] as String,
  model: json['model'] as String,
  reasoningEffort: json['reasoningEffort'] as String? ?? 'medium',
  status: $enumDecode(_$AgentStatusEnumMap, json['status']),
  permissionMode: $enumDecode(_$PermissionModeEnumMap, json['permissionMode']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  activeTurnId: json['activeTurnId'] as String?,
  lastError: json['lastError'] as String?,
);

Map<String, dynamic> _$AgentDtoToJson(_AgentDto instance) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'title': instance.title,
  'providerId': instance.providerId,
  'model': instance.model,
  'reasoningEffort': instance.reasoningEffort,
  'status': _$AgentStatusEnumMap[instance.status]!,
  'permissionMode': _$PermissionModeEnumMap[instance.permissionMode]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
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
  CapabilitySource.preset: 'preset',
  CapabilitySource.diagnostic: 'diagnostic',
  CapabilitySource.manual: 'manual',
};

_ApiProviderDto _$ApiProviderDtoFromJson(Map<String, dynamic> json) =>
    _ApiProviderDto(
      id: json['id'] as String,
      name: json['name'] as String,
      presetId: json['presetId'] as String,
      baseUrl: json['baseUrl'] as String,
      transport: $enumDecode(_$ApiTransportEnumMap, json['transport']),
      credentialSource: $enumDecode(
        _$CredentialSourceEnumMap,
        json['credentialSource'],
      ),
      credentialConfigured: json['credentialConfigured'] as bool,
      enabled: json['enabled'] as bool,
      strictToolSchema: json['strictToolSchema'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      environmentVariable: json['environmentVariable'] as String?,
      defaultModelId: json['defaultModelId'] as String?,
      visibleModelIds:
          (json['visibleModelIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ApiProviderDtoToJson(_ApiProviderDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'presetId': instance.presetId,
      'baseUrl': instance.baseUrl,
      'transport': _$ApiTransportEnumMap[instance.transport]!,
      'credentialSource': _$CredentialSourceEnumMap[instance.credentialSource]!,
      'credentialConfigured': instance.credentialConfigured,
      'enabled': instance.enabled,
      'strictToolSchema': instance.strictToolSchema,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'environmentVariable': instance.environmentVariable,
      'defaultModelId': instance.defaultModelId,
      'visibleModelIds': instance.visibleModelIds,
    };

const _$ApiTransportEnumMap = {
  ApiTransport.responses: 'responses',
  ApiTransport.chatCompletions: 'chatCompletions',
};

const _$CredentialSourceEnumMap = {
  CredentialSource.none: 'none',
  CredentialSource.stored: 'stored',
  CredentialSource.environment: 'environment',
};

_ProviderPresetDto _$ProviderPresetDtoFromJson(Map<String, dynamic> json) =>
    _ProviderPresetDto(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultBaseUrl: json['defaultBaseUrl'] as String,
      defaultTransport: $enumDecode(
        _$ApiTransportEnumMap,
        json['defaultTransport'],
      ),
      defaultCredentialSource: $enumDecode(
        _$CredentialSourceEnumMap,
        json['defaultCredentialSource'],
      ),
      strictToolSchema: json['strictToolSchema'] as bool,
      defaultEnvironmentVariable: json['defaultEnvironmentVariable'] as String?,
      defaultModelId: json['defaultModelId'] as String?,
      modelIds:
          (json['modelIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ProviderPresetDtoToJson(_ProviderPresetDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'defaultBaseUrl': instance.defaultBaseUrl,
      'defaultTransport': _$ApiTransportEnumMap[instance.defaultTransport]!,
      'defaultCredentialSource':
          _$CredentialSourceEnumMap[instance.defaultCredentialSource]!,
      'strictToolSchema': instance.strictToolSchema,
      'defaultEnvironmentVariable': instance.defaultEnvironmentVariable,
      'defaultModelId': instance.defaultModelId,
      'modelIds': instance.modelIds,
    };

_ProviderModelDto _$ProviderModelDtoFromJson(Map<String, dynamic> json) =>
    _ProviderModelDto(
      providerId: json['providerId'] as String,
      id: json['id'] as String,
      label: json['label'] as String,
      source: $enumDecode(_$ProviderModelSourceEnumMap, json['source']),
      capabilities: ModelCapabilitiesDto.fromJson(
        json['capabilities'] as Map<String, dynamic>,
      ),
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
      'providerId': instance.providerId,
      'id': instance.id,
      'label': instance.label,
      'source': _$ProviderModelSourceEnumMap[instance.source]!,
      'capabilities': instance.capabilities,
      'diagnosticStatus': _$DiagnosticStatusEnumMap[instance.diagnosticStatus]!,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'diagnosticError': instance.diagnosticError,
    };

const _$ProviderModelSourceEnumMap = {
  ProviderModelSource.preset: 'preset',
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
      providers: (json['providers'] as List<dynamic>)
          .map((e) => ApiProviderDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      presets: (json['presets'] as List<dynamic>)
          .map((e) => ProviderPresetDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultProviderId: json['defaultProviderId'] as String?,
    );

Map<String, dynamic> _$ProviderCatalogDtoToJson(_ProviderCatalogDto instance) =>
    <String, dynamic>{
      'providers': instance.providers,
      'presets': instance.presets,
      'defaultProviderId': instance.defaultProviderId,
    };

_ProviderDiagnosticDto _$ProviderDiagnosticDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDiagnosticDto(
  providerId: json['providerId'] as String,
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
  'providerId': instance.providerId,
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
