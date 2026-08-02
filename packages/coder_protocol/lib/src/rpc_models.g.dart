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
  providerId: json['providerId'] as String,
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
  'providerId': instance.providerId,
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
  providerId: json['providerId'] as String,
  model: json['model'] as String,
  reasoningEffort: json['reasoningEffort'] as String,
);

Map<String, dynamic> _$AgentConfigurationUpdateParamsDtoToJson(
  _AgentConfigurationUpdateParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'providerId': instance.providerId,
  'model': instance.model,
  'reasoningEffort': instance.reasoningEffort,
};

_ProviderUpsertParamsDto _$ProviderUpsertParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderUpsertParamsDto(
  provider: ApiProviderDto.fromJson(json['provider'] as Map<String, dynamic>),
  makeDefault: json['makeDefault'] as bool,
);

Map<String, dynamic> _$ProviderUpsertParamsDtoToJson(
  _ProviderUpsertParamsDto instance,
) => <String, dynamic>{
  'provider': instance.provider,
  'makeDefault': instance.makeDefault,
};

_ProviderIdParamsDto _$ProviderIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _ProviderIdParamsDto(providerId: json['providerId'] as String);

Map<String, dynamic> _$ProviderIdParamsDtoToJson(
  _ProviderIdParamsDto instance,
) => <String, dynamic>{'providerId': instance.providerId};

_ProviderModelParamsDto _$ProviderModelParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderModelParamsDto(
  providerId: json['providerId'] as String,
  modelId: json['modelId'] as String,
);

Map<String, dynamic> _$ProviderModelParamsDtoToJson(
  _ProviderModelParamsDto instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
  'modelId': instance.modelId,
};

_ProviderModelUpsertParamsDto _$ProviderModelUpsertParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderModelUpsertParamsDto(
  model: ProviderModelDto.fromJson(json['model'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProviderModelUpsertParamsDtoToJson(
  _ProviderModelUpsertParamsDto instance,
) => <String, dynamic>{'model': instance.model};

_ProviderCredentialSetParamsDto _$ProviderCredentialSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderCredentialSetParamsDto(
  providerId: json['providerId'] as String,
  apiKey: json['apiKey'] as String,
);

Map<String, dynamic> _$ProviderCredentialSetParamsDtoToJson(
  _ProviderCredentialSetParamsDto instance,
) => <String, dynamic>{
  'providerId': instance.providerId,
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

_ProviderResultDto _$ProviderResultDtoFromJson(Map<String, dynamic> json) =>
    _ProviderResultDto(
      provider: ApiProviderDto.fromJson(
        json['provider'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ProviderResultDtoToJson(_ProviderResultDto instance) =>
    <String, dynamic>{'provider': instance.provider};

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

_ProviderModelResultDto _$ProviderModelResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderModelResultDto(
  model: ProviderModelDto.fromJson(json['model'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ProviderModelResultDtoToJson(
  _ProviderModelResultDto instance,
) => <String, dynamic>{'model': instance.model};

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
