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
);

Map<String, dynamic> _$WorktreeCreateParamsDtoToJson(
  _WorktreeCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'workspaceId': instance.workspaceId,
  'mode': _$WorktreeCreateModeEnumMap[instance.mode]!,
  'branchName': instance.branchName,
  'baseBranch': instance.baseBranch,
};

const _$WorktreeCreateModeEnumMap = {
  WorktreeCreateMode.newBranch: 'newBranch',
  WorktreeCreateMode.existingBranch: 'existingBranch',
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

_SessionCreateParamsDto _$SessionCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionCreateParamsDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  agentDefinitionId: json['agentDefinitionId'] as String,
  mode:
      $enumDecodeNullable(_$SessionModeEnumMap, json['mode']) ??
      SessionMode.normal,
  model: json['model'] == null
      ? null
      : SessionModelSelectionDto.fromJson(
          json['model'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SessionCreateParamsDtoToJson(
  _SessionCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'worktreeId': instance.worktreeId,
  'title': instance.title,
  'agentDefinitionId': instance.agentDefinitionId,
  'mode': _$SessionModeEnumMap[instance.mode]!,
  'model': instance.model,
};

const _$SessionModeEnumMap = {
  SessionMode.plan: 'plan',
  SessionMode.normal: 'normal',
};

_SessionModeSetParamsDto _$SessionModeSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionModeSetParamsDto(
  sessionId: json['sessionId'] as String,
  mode: $enumDecode(_$SessionModeEnumMap, json['mode']),
);

Map<String, dynamic> _$SessionModeSetParamsDtoToJson(
  _SessionModeSetParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'mode': _$SessionModeEnumMap[instance.mode]!,
};

_SessionModelSetParamsDto _$SessionModelSetParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SessionModelSetParamsDto(
  sessionId: json['sessionId'] as String,
  model: json['model'] == null
      ? null
      : SessionModelSelectionDto.fromJson(
          json['model'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SessionModelSetParamsDtoToJson(
  _SessionModelSetParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'model': instance.model,
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

_SkillScopeParamsDto _$SkillScopeParamsDtoFromJson(Map<String, dynamic> json) =>
    _SkillScopeParamsDto(workspaceId: json['workspaceId'] as String?);

Map<String, dynamic> _$SkillScopeParamsDtoToJson(
  _SkillScopeParamsDto instance,
) => <String, dynamic>{'workspaceId': instance.workspaceId};

_SkillIdParamsDto _$SkillIdParamsDtoFromJson(Map<String, dynamic> json) =>
    _SkillIdParamsDto(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String?,
    );

Map<String, dynamic> _$SkillIdParamsDtoToJson(_SkillIdParamsDto instance) =>
    <String, dynamic>{'id': instance.id, 'workspaceId': instance.workspaceId};

_SkillCreateParamsDto _$SkillCreateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SkillCreateParamsDto(
  id: json['id'] as String,
  source: $enumDecode(_$SkillSourceEnumMap, json['source']),
  name: json['name'] as String,
  description: json['description'] as String,
  body: json['body'] as String,
  workspaceId: json['workspaceId'] as String?,
);

Map<String, dynamic> _$SkillCreateParamsDtoToJson(
  _SkillCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'source': _$SkillSourceEnumMap[instance.source]!,
  'name': instance.name,
  'description': instance.description,
  'body': instance.body,
  'workspaceId': instance.workspaceId,
};

const _$SkillSourceEnumMap = {
  SkillSource.builtIn: 'builtIn',
  SkillSource.userHome: 'userHome',
  SkillSource.config: 'config',
  SkillSource.project: 'project',
};

_SkillUpdateParamsDto _$SkillUpdateParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SkillUpdateParamsDto(
  skill: SkillDto.fromJson(json['skill'] as Map<String, dynamic>),
  expectedContentHash: json['expectedContentHash'] as String,
  workspaceId: json['workspaceId'] as String?,
  force: json['force'] as bool? ?? false,
);

Map<String, dynamic> _$SkillUpdateParamsDtoToJson(
  _SkillUpdateParamsDto instance,
) => <String, dynamic>{
  'skill': instance.skill,
  'expectedContentHash': instance.expectedContentHash,
  'workspaceId': instance.workspaceId,
  'force': instance.force,
};

_SkillSetEnabledParamsDto _$SkillSetEnabledParamsDtoFromJson(
  Map<String, dynamic> json,
) => _SkillSetEnabledParamsDto(
  id: json['id'] as String,
  enabled: json['enabled'] as bool,
  workspaceId: json['workspaceId'] as String?,
);

Map<String, dynamic> _$SkillSetEnabledParamsDtoToJson(
  _SkillSetEnabledParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'enabled': instance.enabled,
  'workspaceId': instance.workspaceId,
};

_ProviderConnectApiKeyParamsDto _$ProviderConnectApiKeyParamsDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderConnectApiKeyParamsDto(
  definitionId: json['definitionId'] as String,
  apiKey: json['apiKey'] as String,
);

Map<String, dynamic> _$ProviderConnectApiKeyParamsDtoToJson(
  _ProviderConnectApiKeyParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'apiKey': instance.apiKey,
};

_ProviderConnectNoneParamsDto _$ProviderConnectNoneParamsDtoFromJson(
  Map<String, dynamic> json,
) =>
    _ProviderConnectNoneParamsDto(definitionId: json['definitionId'] as String);

Map<String, dynamic> _$ProviderConnectNoneParamsDtoToJson(
  _ProviderConnectNoneParamsDto instance,
) => <String, dynamic>{'definitionId': instance.definitionId};

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
);

Map<String, dynamic> _$ProviderAuthStartParamsDtoToJson(
  _ProviderAuthStartParamsDto instance,
) => <String, dynamic>{
  'definitionId': instance.definitionId,
  'methodId': instance.methodId,
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
);

Map<String, dynamic> _$ProviderCustomCreateParamsDtoToJson(
  _ProviderCustomCreateParamsDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'config': instance.config,
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
      sessionId: json['sessionId'] as String,
      turnId: json['turnId'] as String,
      prompt: json['prompt'] as String,
    );

Map<String, dynamic> _$TurnStartParamsDtoToJson(_TurnStartParamsDto instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'turnId': instance.turnId,
      'prompt': instance.prompt,
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

_TimelineSubscribeParamsDto _$TimelineSubscribeParamsDtoFromJson(
  Map<String, dynamic> json,
) => _TimelineSubscribeParamsDto(
  sessionId: json['sessionId'] as String,
  afterSequence: (json['afterSequence'] as num).toInt(),
);

Map<String, dynamic> _$TimelineSubscribeParamsDtoToJson(
  _TimelineSubscribeParamsDto instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'afterSequence': instance.afterSequence,
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
          .map((e) => SkillDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SkillListResultDtoToJson(_SkillListResultDto instance) =>
    <String, dynamic>{'skills': instance.skills};

_SkillResultDto _$SkillResultDtoFromJson(Map<String, dynamic> json) =>
    _SkillResultDto(
      skill: SkillDto.fromJson(json['skill'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SkillResultDtoToJson(_SkillResultDto instance) =>
    <String, dynamic>{'skill': instance.skill};

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
