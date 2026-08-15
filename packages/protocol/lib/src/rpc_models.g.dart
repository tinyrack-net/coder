// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=3.12

part of 'rpc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HelloParamsDto _$HelloParamsDtoFromJson(Map<String, dynamic> json) =>
    _HelloParamsDto(
      clientId: json['clientId'] as String,
      clientKind: json['clientKind'] as String,
      protocolMajor: (json['protocolMajor'] as num).toInt(),
      capabilities: Map<String, bool>.from(json['capabilities'] as Map),
      protocolRevision:
          (json['protocolRevision'] as num?)?.toInt() ?? tinestProtocolRevision,
      clientVersion: json['clientVersion'] as String? ?? 'unknown',
    );

Map<String, dynamic> _$HelloParamsDtoToJson(_HelloParamsDto instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientKind': instance.clientKind,
      'protocolMajor': instance.protocolMajor,
      'capabilities': instance.capabilities,
      'protocolRevision': instance.protocolRevision,
      'clientVersion': instance.clientVersion,
    };

_WorkspaceRegisterParamsDto _$WorkspaceRegisterParamsDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceRegisterParamsDto(
  workspaceId: json['workspaceId'] as String,
  checkoutId: json['checkoutId'] as String,
  rootPath: json['rootPath'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$WorkspaceRegisterParamsDtoToJson(
  _WorkspaceRegisterParamsDto instance,
) => <String, dynamic>{
  'workspaceId': instance.workspaceId,
  'checkoutId': instance.checkoutId,
  'rootPath': instance.rootPath,
  'name': instance.name,
};

_WorkspaceIdParamsDto _$WorkspaceIdParamsDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceIdParamsDto(workspaceId: json['workspaceId'] as String);

Map<String, dynamic> _$WorkspaceIdParamsDtoToJson(
  _WorkspaceIdParamsDto instance,
) => <String, dynamic>{'workspaceId': instance.workspaceId};

_DirectorySuggestParamsDto _$DirectorySuggestParamsDtoFromJson(
  Map<String, dynamic> json,
) => _DirectorySuggestParamsDto(
  query: json['query'] as String,
  limit: (json['limit'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$DirectorySuggestParamsDtoToJson(
  _DirectorySuggestParamsDto instance,
) => <String, dynamic>{'query': instance.query, 'limit': instance.limit};

_FileSearchParamsDto _$FileSearchParamsDtoFromJson(Map<String, dynamic> json) =>
    _FileSearchParamsDto(
      worktreeId: json['worktreeId'] as String,
      query: json['query'] as String,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
    );

Map<String, dynamic> _$FileSearchParamsDtoToJson(
  _FileSearchParamsDto instance,
) => <String, dynamic>{
  'worktreeId': instance.worktreeId,
  'query': instance.query,
  'limit': instance.limit,
};

_CommandListParamsDto _$CommandListParamsDtoFromJson(
  Map<String, dynamic> json,
) => _CommandListParamsDto(workspaceId: json['workspaceId'] as String?);

Map<String, dynamic> _$CommandListParamsDtoToJson(
  _CommandListParamsDto instance,
) => <String, dynamic>{'workspaceId': instance.workspaceId};

_GitBranchesListParamsDto _$GitBranchesListParamsDtoFromJson(
  Map<String, dynamic> json,
) => _GitBranchesListParamsDto(workspaceId: json['workspaceId'] as String);

Map<String, dynamic> _$GitBranchesListParamsDtoToJson(
  _GitBranchesListParamsDto instance,
) => <String, dynamic>{'workspaceId': instance.workspaceId};

_WorktreeCreateParamsDto _$WorktreeCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _WorktreeCreateParamsDto(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  mode: $enumDecode(_$WorktreeCreateModeEnumMap, json['mode']),
  branchName: json['branchName'] as String,
  baseBranch: json['baseBranch'] as String?,
  branchNaming:
      $enumDecodeNullable(
        _$WorktreeBranchNamingEnumMap,
        json['branchNaming'],
      ) ??
      WorktreeBranchNaming.exact,
);

Map<String, dynamic> _$WorktreeCreateParamsDtoToJson(
  _WorktreeCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'mode': _$WorktreeCreateModeEnumMap[instance.mode]!,
  'branchName': instance.branchName,
  'baseBranch': instance.baseBranch,
  'branchNaming': _$WorktreeBranchNamingEnumMap[instance.branchNaming]!,
};

const _$WorktreeCreateModeEnumMap = {
  WorktreeCreateMode.newBranch: 'newBranch',
  WorktreeCreateMode.existingBranch: 'existingBranch',
};

const _$WorktreeBranchNamingEnumMap = {
  WorktreeBranchNaming.exact: 'exact',
  WorktreeBranchNaming.derive: 'derive',
};

_WorktreeIdParamsDto _$WorktreeIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _WorktreeIdParamsDto(worktreeId: json['worktreeId'] as String);

Map<String, dynamic> _$WorktreeIdParamsDtoToJson(
  _WorktreeIdParamsDto instance,
) => <String, dynamic>{'worktreeId': instance.worktreeId};

_WorktreeArchiveParamsDto _$WorktreeArchiveParamsDtoFromJson(
  Map<String, dynamic> json,
) => _WorktreeArchiveParamsDto(
  worktreeId: json['worktreeId'] as String,
  force: json['force'] as bool,
);

Map<String, dynamic> _$WorktreeArchiveParamsDtoToJson(
  _WorktreeArchiveParamsDto instance,
) => <String, dynamic>{
  'worktreeId': instance.worktreeId,
  'force': instance.force,
};

_SessionListParamsDto _$SessionListParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionListParamsDto(worktreeId: json['worktreeId'] as String?);

Map<String, dynamic> _$SessionListParamsDtoToJson(
  _SessionListParamsDto instance,
) => <String, dynamic>{'worktreeId': instance.worktreeId};

_SessionSubagentListParamsDto _$SessionSubagentListParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionSubagentListParamsDto(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$SessionSubagentListParamsDtoToJson(
  _SessionSubagentListParamsDto instance,
) => <String, dynamic>{'sessionId': instance.sessionId};

_SessionCreateParamsDto _$SessionCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionCreateParamsDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  agentDefinitionId: json['agentDefinitionId'] as String,
  model: json['model'] == null
      ? null
      : ModelSelectionDto.fromJson(json['model'] as Map<String, dynamic>),
  modelControls:
      (json['modelControls'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          ModelControlValueDto.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <String, ModelControlValueDto>{},
  permissionMode: $enumDecodeNullable(
    _$PermissionModeEnumMap,
    json['permissionMode'],
  ),
);

Map<String, dynamic> _$SessionCreateParamsDtoToJson(
  _SessionCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'worktreeId': instance.worktreeId,
  'title': instance.title,
  'agentDefinitionId': instance.agentDefinitionId,
  'model': instance.model,
  'modelControls': instance.modelControls,
  'permissionMode': _$PermissionModeEnumMap[instance.permissionMode],
};

const _$PermissionModeEnumMap = {
  PermissionMode.readOnly: 'readOnly',
  PermissionMode.ask: 'ask',
  PermissionMode.workspaceWrite: 'workspaceWrite',
  PermissionMode.fullAccess: 'fullAccess',
};

_SessionSettingsPatchDto _$SessionSettingsPatchDtoFromJson(
  Map<String, dynamic> json,
) => _SessionSettingsPatchDto(
  hasModel: json['hasModel'] as bool? ?? false,
  model: json['model'] == null
      ? null
      : ModelSelectionDto.fromJson(json['model'] as Map<String, dynamic>),
  hasModelControls: json['hasModelControls'] as bool? ?? false,
  modelControls:
      (json['modelControls'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          ModelControlValueDto.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <String, ModelControlValueDto>{},
  hasPermissionMode: json['hasPermissionMode'] as bool? ?? false,
  permissionMode: $enumDecodeNullable(
    _$PermissionModeEnumMap,
    json['permissionMode'],
  ),
);

Map<String, dynamic> _$SessionSettingsPatchDtoToJson(
  _SessionSettingsPatchDto instance,
) => <String, dynamic>{
  'hasModel': instance.hasModel,
  'model': instance.model,
  'hasModelControls': instance.hasModelControls,
  'modelControls': instance.modelControls,
  'hasPermissionMode': instance.hasPermissionMode,
  'permissionMode': _$PermissionModeEnumMap[instance.permissionMode],
};

_SessionSettingsUpdateParamsDto _$SessionSettingsUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionSettingsUpdateParamsDto(
  sessionId: json['sessionId'] as String,
  patch: SessionSettingsPatchDto.fromJson(
    json['patch'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$SessionSettingsUpdateParamsDtoToJson(
  _SessionSettingsUpdateParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'patch': instance.patch,
};

_AgentDefinitionIdParamsDto _$AgentDefinitionIdParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionIdParamsDto(id: json['id'] as String);

Map<String, dynamic> _$AgentDefinitionIdParamsDtoToJson(
  _AgentDefinitionIdParamsDto instance,
) => <String, dynamic>{'id': instance.id};

_AgentDefinitionCreateParamsDto _$AgentDefinitionCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionCreateParamsDto(
  id: json['id'] as String,
  definition: AgentDefinitionDto.fromJson(
    json['definition'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AgentDefinitionCreateParamsDtoToJson(
  _AgentDefinitionCreateParamsDto instance,
) => <String, dynamic>{'id': instance.id, 'definition': instance.definition};

_AgentDefinitionUpdateParamsDto _$AgentDefinitionUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionUpdateParamsDto(
  definition: AgentDefinitionDto.fromJson(
    json['definition'] as Map<String, dynamic>,
  ),
  expectedContentHash: json['expectedContentHash'] as String,
  force: json['force'] as bool? ?? false,
);

Map<String, dynamic> _$AgentDefinitionUpdateParamsDtoToJson(
  _AgentDefinitionUpdateParamsDto instance,
) => <String, dynamic>{
  'definition': instance.definition,
  'expectedContentHash': instance.expectedContentHash,
  'force': instance.force,
};

_AgentDefinitionValidateParamsDto _$AgentDefinitionValidateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionValidateParamsDto(
  id: json['id'] as String,
  markdown: json['markdown'] as String,
);

Map<String, dynamic> _$AgentDefinitionValidateParamsDtoToJson(
  _AgentDefinitionValidateParamsDto instance,
) => <String, dynamic>{'id': instance.id, 'markdown': instance.markdown};

_PluginIdParamsDto _$PluginIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _PluginIdParamsDto(id: json['id'] as String);

Map<String, dynamic> _$PluginIdParamsDtoToJson(_PluginIdParamsDto instance) =>
    <String, dynamic>{'id': instance.id};

_PluginReloadParamsDto _$PluginReloadParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginReloadParamsDto(
  id: json['id'] as String,
  agentId: json['agentId'] as String,
);

Map<String, dynamic> _$PluginReloadParamsDtoToJson(
  _PluginReloadParamsDto instance,
) => <String, dynamic>{'id': instance.id, 'agentId': instance.agentId};

_PluginScaffoldParamsDto _$PluginScaffoldParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginScaffoldParamsDto(
  id: json['id'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$PluginScaffoldParamsDtoToJson(
  _PluginScaffoldParamsDto instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_PluginForkParamsDto _$PluginForkParamsDtoFromJson(Map<String, dynamic> json) =>
    _PluginForkParamsDto(
      sourceId: json['sourceId'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$PluginForkParamsDtoToJson(
  _PluginForkParamsDto instance,
) => <String, dynamic>{
  'sourceId': instance.sourceId,
  'id': instance.id,
  'name': instance.name,
};

_AgentPluginGrantsParamsDto _$AgentPluginGrantsParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentPluginGrantsParamsDto(agentId: json['agentId'] as String);

Map<String, dynamic> _$AgentPluginGrantsParamsDtoToJson(
  _AgentPluginGrantsParamsDto instance,
) => <String, dynamic>{'agentId': instance.agentId};

_PluginGrantParamsDto _$PluginGrantParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginGrantParamsDto(
  grant: AgentPluginGrantDto.fromJson(json['grant'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PluginGrantParamsDtoToJson(
  _PluginGrantParamsDto instance,
) => <String, dynamic>{'grant': instance.grant};

_PluginSecretSetParamsDto _$PluginSecretSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginSecretSetParamsDto(
  agentId: json['agentId'] as String,
  pluginId: json['pluginId'] as String,
  name: json['name'] as String,
  value: json['value'] as String,
);

Map<String, dynamic> _$PluginSecretSetParamsDtoToJson(
  _PluginSecretSetParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'pluginId': instance.pluginId,
  'name': instance.name,
  'value': instance.value,
};

_PluginSecretRemoveParamsDto _$PluginSecretRemoveParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginSecretRemoveParamsDto(
  agentId: json['agentId'] as String,
  pluginId: json['pluginId'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$PluginSecretRemoveParamsDtoToJson(
  _PluginSecretRemoveParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'pluginId': instance.pluginId,
  'name': instance.name,
};

_PluginSessionControlParamsDto _$PluginSessionControlParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginSessionControlParamsDto(
  sessionId: json['sessionId'] as String,
  pluginId: json['pluginId'] as String,
  contributionId: json['contributionId'] as String,
);

Map<String, dynamic> _$PluginSessionControlParamsDtoToJson(
  _PluginSessionControlParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'pluginId': instance.pluginId,
  'contributionId': instance.contributionId,
};

_PluginSessionControlSetParamsDto _$PluginSessionControlSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginSessionControlSetParamsDto(
  sessionId: json['sessionId'] as String,
  pluginId: json['pluginId'] as String,
  contributionId: json['contributionId'] as String,
  value: json['value'],
);

Map<String, dynamic> _$PluginSessionControlSetParamsDtoToJson(
  _PluginSessionControlSetParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'pluginId': instance.pluginId,
  'contributionId': instance.contributionId,
  'value': instance.value,
};

_PluginUiRenderParamsDto _$PluginUiRenderParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginUiRenderParamsDto(
  agentId: json['agentId'] as String,
  pluginId: json['pluginId'] as String,
  contributionId: json['contributionId'] as String,
  slot: $enumDecode(_$PluginUiSlotEnumMap, json['slot']),
  input: json['input'],
  context:
      json['context'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$PluginUiRenderParamsDtoToJson(
  _PluginUiRenderParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'pluginId': instance.pluginId,
  'contributionId': instance.contributionId,
  'slot': _$PluginUiSlotEnumMap[instance.slot]!,
  'input': instance.input,
  'context': instance.context,
};

const _$PluginUiSlotEnumMap = {
  PluginUiSlot.agentSettings: 'agentSettings',
  PluginUiSlot.composerControl: 'composerControl',
  PluginUiSlot.conversationStatus: 'conversationStatus',
  PluginUiSlot.timeline: 'timeline',
  PluginUiSlot.dialog: 'dialog',
  PluginUiSlot.toast: 'toast',
};

_PluginUiActionParamsDto _$PluginUiActionParamsDtoFromJson(
  Map<String, dynamic> json,
) => _PluginUiActionParamsDto(
  agentId: json['agentId'] as String,
  pluginId: json['pluginId'] as String,
  action: PluginUiActionDto.fromJson(json['action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PluginUiActionParamsDtoToJson(
  _PluginUiActionParamsDto instance,
) => <String, dynamic>{
  'agentId': instance.agentId,
  'pluginId': instance.pluginId,
  'action': instance.action,
};

_SkillListParamsDto _$SkillListParamsDtoFromJson(Map<String, dynamic> json) =>
    _SkillListParamsDto(
      view: $enumDecode(_$SkillListViewEnumMap, json['view']),
      workspaceId: json['workspaceId'] as String?,
    );

Map<String, dynamic> _$SkillListParamsDtoToJson(_SkillListParamsDto instance) =>
    <String, dynamic>{
      'view': _$SkillListViewEnumMap[instance.view]!,
      'workspaceId': instance.workspaceId,
    };

const _$SkillListViewEnumMap = {
  SkillListView.global: 'global',
  SkillListView.project: 'project',
  SkillListView.effective: 'effective',
};

_ProviderConnectApiKeyParamsDto _$ProviderConnectApiKeyParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectApiKeyParamsDto(
  definitionId: json['definitionId'] as String,
  apiKey: json['apiKey'] as String,
  connectionId: json['connectionId'] as String?,
  modelPrefix: json['modelPrefix'] as String?,
);

Map<String, dynamic> _$ProviderConnectApiKeyParamsDtoToJson(
  _ProviderConnectApiKeyParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'apiKey': instance.apiKey,
  'connectionId': instance.connectionId,
  'modelPrefix': instance.modelPrefix,
};

_ProviderConnectNoneParamsDto _$ProviderConnectNoneParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectNoneParamsDto(
  definitionId: json['definitionId'] as String,
  connectionId: json['connectionId'] as String?,
  modelPrefix: json['modelPrefix'] as String?,
);

Map<String, dynamic> _$ProviderConnectNoneParamsDtoToJson(
  _ProviderConnectNoneParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'connectionId': instance.connectionId,
  'modelPrefix': instance.modelPrefix,
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
  connectionId: json['connectionId'] as String?,
  modelPrefix: json['modelPrefix'] as String?,
);

Map<String, dynamic> _$ProviderAuthStartParamsDtoToJson(
  _ProviderAuthStartParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'methodId': instance.methodId,
  'connectionId': instance.connectionId,
  'modelPrefix': instance.modelPrefix,
};

_ProviderPrefixUpdateParamsDto _$ProviderPrefixUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderPrefixUpdateParamsDto(
  connectionId: json['connectionId'] as String,
  modelPrefix: json['modelPrefix'] as String,
);

Map<String, dynamic> _$ProviderPrefixUpdateParamsDtoToJson(
  _ProviderPrefixUpdateParamsDto instance,
) => <String, dynamic>{
  'connectionId': instance.connectionId,
  'modelPrefix': instance.modelPrefix,
};

_ProviderAuthAttemptParamsDto _$ProviderAuthAttemptParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthAttemptParamsDto(attemptId: json['attemptId'] as String);

Map<String, dynamic> _$ProviderAuthAttemptParamsDtoToJson(
  _ProviderAuthAttemptParamsDto instance,
) => <String, dynamic>{'attemptId': instance.attemptId};

_ProviderCustomCreateParamsDto _$ProviderCustomCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderCustomCreateParamsDto(
  id: json['id'] as String,
  config: CustomProviderConfigDto.fromJson(
    json['config'] as Map<String, dynamic>,
  ),
  apiKey: json['apiKey'] as String?,
  modelPrefix: json['modelPrefix'] as String?,
);

Map<String, dynamic> _$ProviderCustomCreateParamsDtoToJson(
  _ProviderCustomCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'config': instance.config,
  'apiKey': instance.apiKey,
  'modelPrefix': instance.modelPrefix,
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
      sessionId: json['sessionId'] as String,
      turnId: json['turnId'] as String,
      prompt: json['prompt'] as String,
      attachmentIds:
          (json['attachmentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$TurnStartParamsDtoToJson(_TurnStartParamsDto instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'turnId': instance.turnId,
      'prompt': instance.prompt,
      'attachmentIds': instance.attachmentIds,
    };

_SessionIdParamsDto _$SessionIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _SessionIdParamsDto(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$SessionIdParamsDtoToJson(_SessionIdParamsDto instance) =>
    <String, dynamic>{'sessionId': instance.sessionId};

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

_SessionPendingInputParamsDto _$SessionPendingInputParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionPendingInputParamsDto(sessionId: json['sessionId'] as String);

Map<String, dynamic> _$SessionPendingInputParamsDtoToJson(
  _SessionPendingInputParamsDto instance,
) => <String, dynamic>{'sessionId': instance.sessionId};

_UserQuestionAnswerParamsDto _$UserQuestionAnswerParamsDtoFromJson(
  Map<String, dynamic> json,
) => _UserQuestionAnswerParamsDto(
  requestId: json['requestId'] as String,
  answers: (json['answers'] as List<dynamic>)
      .map((e) => UserQuestionAnswerDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserQuestionAnswerParamsDtoToJson(
  _UserQuestionAnswerParamsDto instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'answers': instance.answers,
};

_TimelineSubscribeParamsDto _$TimelineSubscribeParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TimelineSubscribeParamsDto(
  sessionId: json['sessionId'] as String,
  afterSequence: (json['afterSequence'] as num).toInt(),
  tailLimit: (json['tailLimit'] as num?)?.toInt(),
);

Map<String, dynamic> _$TimelineSubscribeParamsDtoToJson(
  _TimelineSubscribeParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'afterSequence': instance.afterSequence,
  'tailLimit': instance.tailLimit,
};

_TimelineHistoryParamsDto _$TimelineHistoryParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TimelineHistoryParamsDto(
  sessionId: json['sessionId'] as String,
  beforeSequence: (json['beforeSequence'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$TimelineHistoryParamsDtoToJson(
  _TimelineHistoryParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'beforeSequence': instance.beforeSequence,
  'limit': instance.limit,
};

_WorkspaceCatalogResultDto _$WorkspaceCatalogResultDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceCatalogResultDto(
  catalog: WorkspaceCatalogDto.fromJson(
    json['catalog'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$WorkspaceCatalogResultDtoToJson(
  _WorkspaceCatalogResultDto instance,
) => <String, dynamic>{'catalog': instance.catalog};

_WorkspaceRegisterResultDto _$WorkspaceRegisterResultDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceRegisterResultDto(
  workspace: WorkspaceDto.fromJson(json['workspace'] as Map<String, dynamic>),
  worktrees: (json['worktrees'] as List<dynamic>)
      .map((e) => WorktreeDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorkspaceRegisterResultDtoToJson(
  _WorkspaceRegisterResultDto instance,
) => <String, dynamic>{
  'workspace': instance.workspace,
  'worktrees': instance.worktrees,
};

_WorkspaceUnregisterResultDto _$WorkspaceUnregisterResultDtoFromJson(
  Map<String, dynamic> json,
) => _WorkspaceUnregisterResultDto(unregistered: json['unregistered'] as bool);

Map<String, dynamic> _$WorkspaceUnregisterResultDtoToJson(
  _WorkspaceUnregisterResultDto instance,
) => <String, dynamic>{'unregistered': instance.unregistered};

_DirectorySuggestResultDto _$DirectorySuggestResultDtoFromJson(
  Map<String, dynamic> json,
) => _DirectorySuggestResultDto(
  suggestions: (json['suggestions'] as List<dynamic>)
      .map((e) => DirectorySuggestionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DirectorySuggestResultDtoToJson(
  _DirectorySuggestResultDto instance,
) => <String, dynamic>{'suggestions': instance.suggestions};

_FileSearchResultDto _$FileSearchResultDtoFromJson(Map<String, dynamic> json) =>
    _FileSearchResultDto(
      matches: (json['matches'] as List<dynamic>)
          .map((e) => FileMatchDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      truncated: json['truncated'] as bool? ?? false,
    );

Map<String, dynamic> _$FileSearchResultDtoToJson(
  _FileSearchResultDto instance,
) => <String, dynamic>{
  'matches': instance.matches,
  'truncated': instance.truncated,
};

_GitBranchesListResultDto _$GitBranchesListResultDtoFromJson(
  Map<String, dynamic> json,
) => _GitBranchesListResultDto(
  branches: (json['branches'] as List<dynamic>)
      .map((e) => GitBranchDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GitBranchesListResultDtoToJson(
  _GitBranchesListResultDto instance,
) => <String, dynamic>{'branches': instance.branches};

_WorktreeResultDto _$WorktreeResultDtoFromJson(Map<String, dynamic> json) =>
    _WorktreeResultDto(
      worktree: WorktreeDto.fromJson(json['worktree'] as Map<String, dynamic>),
      hookRuns:
          (json['hookRuns'] as List<dynamic>?)
              ?.map(
                (e) => WorktreeHookRunDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WorktreeHookRunDto>[],
    );

Map<String, dynamic> _$WorktreeResultDtoToJson(_WorktreeResultDto instance) =>
    <String, dynamic>{
      'worktree': instance.worktree,
      'hookRuns': instance.hookRuns,
    };

_ProjectSettingsGetParamsDto _$ProjectSettingsGetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProjectSettingsGetParamsDto(workspaceId: json['workspaceId'] as String);

Map<String, dynamic> _$ProjectSettingsGetParamsDtoToJson(
  _ProjectSettingsGetParamsDto instance,
) => <String, dynamic>{'workspaceId': instance.workspaceId};

_ProjectSettingsSaveParamsDto _$ProjectSettingsSaveParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProjectSettingsSaveParamsDto(
  workspaceId: json['workspaceId'] as String,
  settings: ProjectSettingsDto.fromJson(
    json['settings'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ProjectSettingsSaveParamsDtoToJson(
  _ProjectSettingsSaveParamsDto instance,
) => <String, dynamic>{
  'workspaceId': instance.workspaceId,
  'settings': instance.settings,
};

_ProjectSettingsResultDto _$ProjectSettingsResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProjectSettingsResultDto(
  settings: ProjectSettingsDto.fromJson(
    json['settings'] as Map<String, dynamic>,
  ),
  sourcePath: json['sourcePath'] as String,
);

Map<String, dynamic> _$ProjectSettingsResultDtoToJson(
  _ProjectSettingsResultDto instance,
) => <String, dynamic>{
  'settings': instance.settings,
  'sourcePath': instance.sourcePath,
};

_WorktreeArchivePreviewResultDto _$WorktreeArchivePreviewResultDtoFromJson(
  Map<String, dynamic> json,
) => _WorktreeArchivePreviewResultDto(
  preview: WorktreeArchivePreviewDto.fromJson(
    json['preview'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$WorktreeArchivePreviewResultDtoToJson(
  _WorktreeArchivePreviewResultDto instance,
) => <String, dynamic>{'preview': instance.preview};

_SessionListResultDto _$SessionListResultDtoFromJson(
  Map<String, dynamic> json,
) => _SessionListResultDto(
  sessions: (json['sessions'] as List<dynamic>)
      .map((e) => SessionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SessionListResultDtoToJson(
  _SessionListResultDto instance,
) => <String, dynamic>{'sessions': instance.sessions};

_SessionResultDto _$SessionResultDtoFromJson(Map<String, dynamic> json) =>
    _SessionResultDto(
      session: SessionDto.fromJson(json['session'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SessionResultDtoToJson(_SessionResultDto instance) =>
    <String, dynamic>{'session': instance.session};

_TerminalListParamsDto _$TerminalListParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalListParamsDto(worktreeId: json['worktreeId'] as String);

Map<String, dynamic> _$TerminalListParamsDtoToJson(
  _TerminalListParamsDto instance,
) => <String, dynamic>{'worktreeId': instance.worktreeId};

_TerminalListResultDto _$TerminalListResultDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalListResultDto(
  terminals: (json['terminals'] as List<dynamic>)
      .map((e) => TerminalDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TerminalListResultDtoToJson(
  _TerminalListResultDto instance,
) => <String, dynamic>{'terminals': instance.terminals};

_TerminalCreateParamsDto _$TerminalCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalCreateParamsDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  columns: (json['columns'] as num).toInt(),
  rows: (json['rows'] as num).toInt(),
);

Map<String, dynamic> _$TerminalCreateParamsDtoToJson(
  _TerminalCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'worktreeId': instance.worktreeId,
  'title': instance.title,
  'columns': instance.columns,
  'rows': instance.rows,
};

_TerminalIdParamsDto _$TerminalIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _TerminalIdParamsDto(terminalId: json['terminalId'] as String);

Map<String, dynamic> _$TerminalIdParamsDtoToJson(
  _TerminalIdParamsDto instance,
) => <String, dynamic>{'terminalId': instance.terminalId};

_TerminalViewportDto _$TerminalViewportDtoFromJson(Map<String, dynamic> json) =>
    _TerminalViewportDto(
      columns: (json['columns'] as num).toInt(),
      rows: (json['rows'] as num).toInt(),
    );

Map<String, dynamic> _$TerminalViewportDtoToJson(
  _TerminalViewportDto instance,
) => <String, dynamic>{'columns': instance.columns, 'rows': instance.rows};

_TerminalAttachParamsDto _$TerminalAttachParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalAttachParamsDto(
  terminalId: json['terminalId'] as String,
  mode: $enumDecode(_$TerminalRestoreModeEnumMap, json['mode']),
  afterSequence: (json['afterSequence'] as num?)?.toInt() ?? 0,
  scrollbackLines:
      (json['scrollbackLines'] as num?)?.toInt() ??
      terminalRestoreScrollbackLines,
  viewport: json['viewport'] == null
      ? null
      : TerminalViewportDto.fromJson(json['viewport'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TerminalAttachParamsDtoToJson(
  _TerminalAttachParamsDto instance,
) => <String, dynamic>{
  'terminalId': instance.terminalId,
  'mode': _$TerminalRestoreModeEnumMap[instance.mode]!,
  'afterSequence': instance.afterSequence,
  'scrollbackLines': instance.scrollbackLines,
  'viewport': instance.viewport,
};

const _$TerminalRestoreModeEnumMap = {
  TerminalRestoreMode.resume: 'resume',
  TerminalRestoreMode.snapshot: 'snapshot',
};

TerminalDeltaRestoreDto _$TerminalDeltaRestoreDtoFromJson(
  Map<String, dynamic> json,
) => TerminalDeltaRestoreDto(
  afterSequence: (json['afterSequence'] as num).toInt(),
  chunks: (json['chunks'] as List<dynamic>)
      .map((e) => TerminalOutputDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$TerminalDeltaRestoreDtoToJson(
  TerminalDeltaRestoreDto instance,
) => <String, dynamic>{
  'afterSequence': instance.afterSequence,
  'chunks': instance.chunks,
  'type': instance.$type,
};

TerminalSnapshotRestoreDto _$TerminalSnapshotRestoreDtoFromJson(
  Map<String, dynamic> json,
) => TerminalSnapshotRestoreDto(
  throughSequence: (json['throughSequence'] as num).toInt(),
  ansi: json['ansi'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$TerminalSnapshotRestoreDtoToJson(
  TerminalSnapshotRestoreDto instance,
) => <String, dynamic>{
  'throughSequence': instance.throughSequence,
  'ansi': instance.ansi,
  'type': instance.$type,
};

_TerminalAttachResultDto _$TerminalAttachResultDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalAttachResultDto(
  terminal: TerminalDto.fromJson(json['terminal'] as Map<String, dynamic>),
  restore: TerminalRestoreDto.fromJson(json['restore'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TerminalAttachResultDtoToJson(
  _TerminalAttachResultDto instance,
) => <String, dynamic>{
  'terminal': instance.terminal,
  'restore': instance.restore,
};

_TerminalResultDto _$TerminalResultDtoFromJson(Map<String, dynamic> json) =>
    _TerminalResultDto(
      terminal: TerminalDto.fromJson(json['terminal'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TerminalResultDtoToJson(_TerminalResultDto instance) =>
    <String, dynamic>{'terminal': instance.terminal};

_TerminalWriteParamsDto _$TerminalWriteParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalWriteParamsDto(
  terminalId: json['terminalId'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$TerminalWriteParamsDtoToJson(
  _TerminalWriteParamsDto instance,
) => <String, dynamic>{
  'terminalId': instance.terminalId,
  'data': instance.data,
};

_TerminalResizeParamsDto _$TerminalResizeParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TerminalResizeParamsDto(
  terminalId: json['terminalId'] as String,
  columns: (json['columns'] as num).toInt(),
  rows: (json['rows'] as num).toInt(),
);

Map<String, dynamic> _$TerminalResizeParamsDtoToJson(
  _TerminalResizeParamsDto instance,
) => <String, dynamic>{
  'terminalId': instance.terminalId,
  'columns': instance.columns,
  'rows': instance.rows,
};

_TerminalShellDto _$TerminalShellDtoFromJson(Map<String, dynamic> json) =>
    _TerminalShellDto(
      shell: json['shell'] == null
          ? null
          : ShellSpecDto.fromJson(json['shell'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TerminalShellDtoToJson(_TerminalShellDto instance) =>
    <String, dynamic>{'shell': instance.shell};

_PermissionSettingsDto _$PermissionSettingsDtoFromJson(
  Map<String, dynamic> json,
) => _PermissionSettingsDto(
  defaultMode:
      $enumDecodeNullable(_$PermissionModeEnumMap, json['defaultMode']) ??
      PermissionMode.ask,
);

Map<String, dynamic> _$PermissionSettingsDtoToJson(
  _PermissionSettingsDto instance,
) => <String, dynamic>{
  'defaultMode': _$PermissionModeEnumMap[instance.defaultMode]!,
};

_DaemonModelSettingsDto _$DaemonModelSettingsDtoFromJson(
  Map<String, dynamic> json,
) => _DaemonModelSettingsDto(
  defaultModel: json['defaultModel'] == null
      ? null
      : ModelSelectionDto.fromJson(
          json['defaultModel'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$DaemonModelSettingsDtoToJson(
  _DaemonModelSettingsDto instance,
) => <String, dynamic>{'defaultModel': instance.defaultModel};

_SetDaemonDefaultModelParamsDto _$SetDaemonDefaultModelParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SetDaemonDefaultModelParamsDto(
  model: ModelSelectionDto.fromJson(json['model'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SetDaemonDefaultModelParamsDtoToJson(
  _SetDaemonDefaultModelParamsDto instance,
) => <String, dynamic>{'model': instance.model};

_AgentDefinitionListResultDto _$AgentDefinitionListResultDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionListResultDto(
  definitions: (json['definitions'] as List<dynamic>)
      .map((e) => AgentDefinitionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AgentDefinitionListResultDtoToJson(
  _AgentDefinitionListResultDto instance,
) => <String, dynamic>{'definitions': instance.definitions};

_AgentDefinitionResultDto _$AgentDefinitionResultDtoFromJson(
  Map<String, dynamic> json,
) => _AgentDefinitionResultDto(
  definition: AgentDefinitionDto.fromJson(
    json['definition'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$AgentDefinitionResultDtoToJson(
  _AgentDefinitionResultDto instance,
) => <String, dynamic>{'definition': instance.definition};

_PluginListResultDto _$PluginListResultDtoFromJson(Map<String, dynamic> json) =>
    _PluginListResultDto(
      plugins: (json['plugins'] as List<dynamic>)
          .map((e) => PluginDescriptorDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PluginListResultDtoToJson(
  _PluginListResultDto instance,
) => <String, dynamic>{'plugins': instance.plugins};

_PluginResultDto _$PluginResultDtoFromJson(Map<String, dynamic> json) =>
    _PluginResultDto(
      plugin: PluginDescriptorDto.fromJson(
        json['plugin'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PluginResultDtoToJson(_PluginResultDto instance) =>
    <String, dynamic>{'plugin': instance.plugin};

_PluginAuthoringEnvironmentResultDto
_$PluginAuthoringEnvironmentResultDtoFromJson(Map<String, dynamic> json) =>
    _PluginAuthoringEnvironmentResultDto(
      environment: PluginAuthoringEnvironmentDto.fromJson(
        json['environment'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PluginAuthoringEnvironmentResultDtoToJson(
  _PluginAuthoringEnvironmentResultDto instance,
) => <String, dynamic>{'environment': instance.environment};

_PluginGrantListResultDto _$PluginGrantListResultDtoFromJson(
  Map<String, dynamic> json,
) => _PluginGrantListResultDto(
  grants: (json['grants'] as List<dynamic>)
      .map((e) => AgentPluginGrantDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PluginGrantListResultDtoToJson(
  _PluginGrantListResultDto instance,
) => <String, dynamic>{'grants': instance.grants};

_PluginSessionControlResultDto _$PluginSessionControlResultDtoFromJson(
  Map<String, dynamic> json,
) => _PluginSessionControlResultDto(
  control: PluginSessionControlValueDto.fromJson(
    json['control'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PluginSessionControlResultDtoToJson(
  _PluginSessionControlResultDto instance,
) => <String, dynamic>{'control': instance.control};

_PluginUiDocumentResultDto _$PluginUiDocumentResultDtoFromJson(
  Map<String, dynamic> json,
) => _PluginUiDocumentResultDto(
  document: PluginUiDocumentDto.fromJson(
    json['document'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$PluginUiDocumentResultDtoToJson(
  _PluginUiDocumentResultDto instance,
) => <String, dynamic>{'document': instance.document};

_AgentToolCatalogParamsDto _$AgentToolCatalogParamsDtoFromJson(
  Map<String, dynamic> json,
) => _AgentToolCatalogParamsDto(worktreeId: json['worktreeId'] as String?);

Map<String, dynamic> _$AgentToolCatalogParamsDtoToJson(
  _AgentToolCatalogParamsDto instance,
) => <String, dynamic>{'worktreeId': instance.worktreeId};

_McpServersParamsDto _$McpServersParamsDtoFromJson(Map<String, dynamic> json) =>
    _McpServersParamsDto(worktreeId: json['worktreeId'] as String?);

Map<String, dynamic> _$McpServersParamsDtoToJson(
  _McpServersParamsDto instance,
) => <String, dynamic>{'worktreeId': instance.worktreeId};

_McpServersResultDto _$McpServersResultDtoFromJson(Map<String, dynamic> json) =>
    _McpServersResultDto(
      servers: (json['servers'] as List<dynamic>)
          .map((e) => McpServerStateDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$McpServersResultDtoToJson(
  _McpServersResultDto instance,
) => <String, dynamic>{'servers': instance.servers};

_McpServerParamsDto _$McpServerParamsDtoFromJson(Map<String, dynamic> json) =>
    _McpServerParamsDto(
      server: McpServerConfigDto.fromJson(
        json['server'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$McpServerParamsDtoToJson(_McpServerParamsDto instance) =>
    <String, dynamic>{'server': instance.server};

_McpServerIdParamsDto _$McpServerIdParamsDtoFromJson(
  Map<String, dynamic> json,
) => _McpServerIdParamsDto(id: json['id'] as String);

Map<String, dynamic> _$McpServerIdParamsDtoToJson(
  _McpServerIdParamsDto instance,
) => <String, dynamic>{'id': instance.id};

_McpServerStateResultDto _$McpServerStateResultDtoFromJson(
  Map<String, dynamic> json,
) => _McpServerStateResultDto(
  state: McpServerStateDto.fromJson(json['state'] as Map<String, dynamic>),
);

Map<String, dynamic> _$McpServerStateResultDtoToJson(
  _McpServerStateResultDto instance,
) => <String, dynamic>{'state': instance.state};

_McpSecretParamsDto _$McpSecretParamsDtoFromJson(Map<String, dynamic> json) =>
    _McpSecretParamsDto(
      key: json['key'] as String,
      value: json['value'] as String,
    );

Map<String, dynamic> _$McpSecretParamsDtoToJson(_McpSecretParamsDto instance) =>
    <String, dynamic>{'key': instance.key, 'value': instance.value};

_AgentToolCatalogResultDto _$AgentToolCatalogResultDtoFromJson(
  Map<String, dynamic> json,
) => _AgentToolCatalogResultDto(
  tools: (json['tools'] as List<dynamic>)
      .map((e) => AgentToolDefinitionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AgentToolCatalogResultDtoToJson(
  _AgentToolCatalogResultDto instance,
) => <String, dynamic>{'tools': instance.tools};

_SkillListResultDto _$SkillListResultDtoFromJson(Map<String, dynamic> json) =>
    _SkillListResultDto(
      skills: (json['skills'] as List<dynamic>)
          .map((e) => SkillSummaryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SkillListResultDtoToJson(_SkillListResultDto instance) =>
    <String, dynamic>{'skills': instance.skills};

_CommandListResultDto _$CommandListResultDtoFromJson(
  Map<String, dynamic> json,
) => _CommandListResultDto(
  commands: (json['commands'] as List<dynamic>)
      .map((e) => AgentCommandDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CommandListResultDtoToJson(
  _CommandListResultDto instance,
) => <String, dynamic>{'commands': instance.commands};

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

_ProviderUsageResultDto _$ProviderUsageResultDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderUsageResultDto(
  usage: (json['usage'] as List<dynamic>)
      .map((e) => ProviderUsageDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ProviderUsageResultDtoToJson(
  _ProviderUsageResultDto instance,
) => <String, dynamic>{'usage': instance.usage};

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

_UserQuestionResultDto _$UserQuestionResultDtoFromJson(
  Map<String, dynamic> json,
) => _UserQuestionResultDto(
  request: UserQuestionRequestDto.fromJson(
    json['request'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$UserQuestionResultDtoToJson(
  _UserQuestionResultDto instance,
) => <String, dynamic>{'request': instance.request};

_TimelineResultDto _$TimelineResultDtoFromJson(Map<String, dynamic> json) =>
    _TimelineResultDto(
      events: (json['events'] as List<dynamic>)
          .map((e) => TimelineEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TimelineResultDtoToJson(_TimelineResultDto instance) =>
    <String, dynamic>{'events': instance.events};
