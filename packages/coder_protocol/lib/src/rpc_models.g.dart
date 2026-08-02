// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rpc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelloParamsDto _$HelloParamsDtoFromJson(Map<String, dynamic> json) =>
    _HelloParamsDto(
      clientId: json['clientId'] as String,
      clientKind: json['clientKind'] as String,
      protocolVersion: (json['protocolVersion'] as num).toInt(),
      capabilities: Map<String, bool>.from(json['capabilities'] as Map),
    );

Map<String, dynamic> _$HelloParamsDtoToJson(_HelloParamsDto instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientKind': instance.clientKind,
      'protocolVersion': instance.protocolVersion,
      'capabilities': instance.capabilities,
    };

_WorkspaceRegisterParamsDto _$WorkspaceRegisterParamsDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceRegisterParamsDto(
  id: json['id'] as String,
  rootPath: json['rootPath'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$WorkspaceRegisterParamsDtoToJson(
  _WorkspaceRegisterParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'rootPath': instance.rootPath,
  'name': instance.name,
};

_AgentListParamsDto _$AgentListParamsDtoFromJson(Map<String, dynamic> json) =>
    _AgentListParamsDto(workspaceId: json['workspaceId'] as String?);

Map<String, dynamic> _$AgentListParamsDtoToJson(_AgentListParamsDto instance) =>
    <String, dynamic>{'workspaceId': instance.workspaceId};

_AgentCreateParamsDto _$AgentCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentCreateParamsDto(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  title: json['title'] as String,
  providerConnectionId: json['providerConnectionId'] as String,
  model: json['model'] as String,
  reasoningEffort: json['reasoningEffort'] as String,
  permissionMode: $enumDecode(_$PermissionModeEnumMap, json['permissionMode']),
);

Map<String, dynamic> _$AgentCreateParamsDtoToJson(
  _AgentCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'title': instance.title,
  'providerConnectionId': instance.providerConnectionId,
  'model': instance.model,
  'reasoningEffort': instance.reasoningEffort,
  'permissionMode': _$PermissionModeEnumMap[instance.permissionMode]!,
};

const _$PermissionModeEnumMap = {
  PermissionMode.readOnly: 'readOnly',
  PermissionMode.ask: 'ask',
  PermissionMode.workspaceWrite: 'workspaceWrite',
};

_AgentConfigurationUpdateParamsDto _$AgentConfigurationUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentConfigurationUpdateParamsDto(
  agentId: json['agentId'] as String,
  providerConnectionId: json['providerConnectionId'] as String,
  model: json['model'] as String,
  reasoningEffort: json['reasoningEffort'] as String,
);

Map<String, dynamic> _$AgentConfigurationUpdateParamsDtoToJson(
  _AgentConfigurationUpdateParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'providerConnectionId': instance.providerConnectionId,
  'model': instance.model,
  'reasoningEffort': instance.reasoningEffort,
};

_ProviderConnectApiKeyParamsDto _$ProviderConnectApiKeyParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectApiKeyParamsDto(
  definitionId: json['definitionId'] as String,
  apiKey: json['apiKey'] as String,
  makeDefault: json['makeDefault'] as bool,
);

Map<String, dynamic> _$ProviderConnectApiKeyParamsDtoToJson(
  _ProviderConnectApiKeyParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'apiKey': instance.apiKey,
  'makeDefault': instance.makeDefault,
};

_ProviderConnectNoneParamsDto _$ProviderConnectNoneParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectNoneParamsDto(
  definitionId: json['definitionId'] as String,
  makeDefault: json['makeDefault'] as bool,
);

Map<String, dynamic> _$ProviderConnectNoneParamsDtoToJson(
  _ProviderConnectNoneParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'makeDefault': instance.makeDefault,
};

_ProviderConnectionIdParamsDto _$ProviderConnectionIdParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectionIdParamsDto(
  connectionId: json['connectionId'] as String,
);

Map<String, dynamic> _$ProviderConnectionIdParamsDtoToJson(
  _ProviderConnectionIdParamsDto instance,
) => <String, dynamic>{'connectionId': instance.connectionId};

_ProviderModelParamsDto _$ProviderModelParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderModelParamsDto(
  connectionId: json['connectionId'] as String,
  modelId: json['modelId'] as String,
);

Map<String, dynamic> _$ProviderModelParamsDtoToJson(
  _ProviderModelParamsDto instance,
) => <String, dynamic>{
  'connectionId': instance.connectionId,
  'modelId': instance.modelId,
};

_ProviderAuthStartParamsDto _$ProviderAuthStartParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthStartParamsDto(
  definitionId: json['definitionId'] as String,
  methodId: json['methodId'] as String,
  makeDefault: json['makeDefault'] as bool,
);

Map<String, dynamic> _$ProviderAuthStartParamsDtoToJson(
  _ProviderAuthStartParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'methodId': instance.methodId,
  'makeDefault': instance.makeDefault,
};

_ProviderAuthAttemptParamsDto _$ProviderAuthAttemptParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthAttemptParamsDto(attemptId: json['attemptId'] as String);

Map<String, dynamic> _$ProviderAuthAttemptParamsDtoToJson(
  _ProviderAuthAttemptParamsDto instance,
) => <String, dynamic>{'attemptId': instance.attemptId};

_ProviderDefaultSetParamsDto _$ProviderDefaultSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDefaultSetParamsDto(connectionId: json['connectionId'] as String);

Map<String, dynamic> _$ProviderDefaultSetParamsDtoToJson(
  _ProviderDefaultSetParamsDto instance,
) => <String, dynamic>{'connectionId': instance.connectionId};

_ProviderDefaultModelSetParamsDto _$ProviderDefaultModelSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDefaultModelSetParamsDto(
  connectionId: json['connectionId'] as String,
  modelId: json['modelId'] as String,
);

Map<String, dynamic> _$ProviderDefaultModelSetParamsDtoToJson(
  _ProviderDefaultModelSetParamsDto instance,
) => <String, dynamic>{
  'connectionId': instance.connectionId,
  'modelId': instance.modelId,
};

_ProviderCustomCreateParamsDto _$ProviderCustomCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderCustomCreateParamsDto(
  id: json['id'] as String,
  config: CustomProviderConfigDto.fromJson(
    json['config'] as Map<String, dynamic>,
  ),
  makeDefault: json['makeDefault'] as bool,
  apiKey: json['apiKey'] as String?,
);

Map<String, dynamic> _$ProviderCustomCreateParamsDtoToJson(
  _ProviderCustomCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'config': instance.config,
  'makeDefault': instance.makeDefault,
  'apiKey': instance.apiKey,
};

_ProviderCustomUpdateParamsDto _$ProviderCustomUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderCustomUpdateParamsDto(
  connectionId: json['connectionId'] as String,
  config: CustomProviderConfigDto.fromJson(
    json['config'] as Map<String, dynamic>,
  ),
  apiKey: json['apiKey'] as String?,
);

Map<String, dynamic> _$ProviderCustomUpdateParamsDtoToJson(
  _ProviderCustomUpdateParamsDto instance,
) => <String, dynamic>{
  'connectionId': instance.connectionId,
  'config': instance.config,
  'apiKey': instance.apiKey,
};

_TurnStartParamsDto _$TurnStartParamsDtoFromJson(Map<String, dynamic> json) =>
    _TurnStartParamsDto(
      agentId: json['agentId'] as String,
      turnId: json['turnId'] as String,
      prompt: json['prompt'] as String,
    );

Map<String, dynamic> _$TurnStartParamsDtoToJson(_TurnStartParamsDto instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'turnId': instance.turnId,
      'prompt': instance.prompt,
    };

_AgentIdParamsDto _$AgentIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _AgentIdParamsDto(agentId: json['agentId'] as String);

Map<String, dynamic> _$AgentIdParamsDtoToJson(_AgentIdParamsDto instance) =>
    <String, dynamic>{'agentId': instance.agentId};

_ApprovalResolveParamsDto _$ApprovalResolveParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ApprovalResolveParamsDto(
  approvalId: json['approvalId'] as String,
  approved: json['approved'] as bool,
);

Map<String, dynamic> _$ApprovalResolveParamsDtoToJson(
  _ApprovalResolveParamsDto instance,
) => <String, dynamic>{
  'approvalId': instance.approvalId,
  'approved': instance.approved,
};

_TimelineSubscribeParamsDto _$TimelineSubscribeParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TimelineSubscribeParamsDto(
  agentId: json['agentId'] as String,
  afterSequence: (json['afterSequence'] as num).toInt(),
);

Map<String, dynamic> _$TimelineSubscribeParamsDtoToJson(
  _TimelineSubscribeParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'afterSequence': instance.afterSequence,
};

_WorkspaceListResultDto _$WorkspaceListResultDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceListResultDto(
  workspaces: (json['workspaces'] as List<dynamic>)
      .map((e) => WorkspaceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorkspaceListResultDtoToJson(
  _WorkspaceListResultDto instance,
) => <String, dynamic>{'workspaces': instance.workspaces};

_WorkspaceResultDto _$WorkspaceResultDtoFromJson(Map<String, dynamic> json) =>
    _WorkspaceResultDto(
      workspace: WorkspaceDto.fromJson(
        json['workspace'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$WorkspaceResultDtoToJson(_WorkspaceResultDto instance) =>
    <String, dynamic>{'workspace': instance.workspace};

_AgentListResultDto _$AgentListResultDtoFromJson(Map<String, dynamic> json) =>
    _AgentListResultDto(
      agents: (json['agents'] as List<dynamic>)
          .map((e) => AgentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AgentListResultDtoToJson(_AgentListResultDto instance) =>
    <String, dynamic>{'agents': instance.agents};

_AgentResultDto _$AgentResultDtoFromJson(Map<String, dynamic> json) =>
    _AgentResultDto(
      agent: AgentDto.fromJson(json['agent'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AgentResultDtoToJson(_AgentResultDto instance) =>
    <String, dynamic>{'agent': instance.agent};

_ProviderCatalogResultDto _$ProviderCatalogResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderCatalogResultDto(
  catalog: ProviderCatalogDto.fromJson(json['catalog'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProviderCatalogResultDtoToJson(
  _ProviderCatalogResultDto instance,
) => <String, dynamic>{'catalog': instance.catalog};

_ProviderConnectionsResultDto _$ProviderConnectionsResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectionsResultDto(
  connections: (json['connections'] as List<dynamic>)
      .map((e) => ProviderConnectionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProviderConnectionsResultDtoToJson(
  _ProviderConnectionsResultDto instance,
) => <String, dynamic>{'connections': instance.connections};

_ProviderConnectionResultDto _$ProviderConnectionResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectionResultDto(
  connection: ProviderConnectionDto.fromJson(
    json['connection'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProviderConnectionResultDtoToJson(
  _ProviderConnectionResultDto instance,
) => <String, dynamic>{'connection': instance.connection};

_ProviderModelsResultDto _$ProviderModelsResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderModelsResultDto(
  models: (json['models'] as List<dynamic>)
      .map((e) => ProviderModelDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProviderModelsResultDtoToJson(
  _ProviderModelsResultDto instance,
) => <String, dynamic>{'models': instance.models};

_ProviderAuthAttemptResultDto _$ProviderAuthAttemptResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthAttemptResultDto(
  attempt: ProviderAuthAttemptDto.fromJson(
    json['attempt'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProviderAuthAttemptResultDtoToJson(
  _ProviderAuthAttemptResultDto instance,
) => <String, dynamic>{'attempt': instance.attempt};

_ProviderDiagnosticResultDto _$ProviderDiagnosticResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderDiagnosticResultDto(
  diagnostic: ProviderDiagnosticDto.fromJson(
    json['diagnostic'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProviderDiagnosticResultDtoToJson(
  _ProviderDiagnosticResultDto instance,
) => <String, dynamic>{'diagnostic': instance.diagnostic};

_TurnStartResultDto _$TurnStartResultDtoFromJson(Map<String, dynamic> json) =>
    _TurnStartResultDto(created: json['created'] as bool);

Map<String, dynamic> _$TurnStartResultDtoToJson(_TurnStartResultDto instance) =>
    <String, dynamic>{'created': instance.created};

_ApprovalResultDto _$ApprovalResultDtoFromJson(Map<String, dynamic> json) =>
    _ApprovalResultDto(
      approval: ApprovalRequestDto.fromJson(
        json['approval'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ApprovalResultDtoToJson(_ApprovalResultDto instance) =>
    <String, dynamic>{'approval': instance.approval};

_TimelineResultDto _$TimelineResultDtoFromJson(Map<String, dynamic> json) =>
    _TimelineResultDto(
      events: (json['events'] as List<dynamic>)
          .map((e) => TimelineEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TimelineResultDtoToJson(_TimelineResultDto instance) =>
    <String, dynamic>{'events': instance.events};
