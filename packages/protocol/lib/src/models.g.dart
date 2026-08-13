// GENERATED CODE - DO NOT MODIFY BY HAND
// @dart=3.12

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShellSpecDto _$ShellSpecDtoFromJson(Map<String, dynamic> json) =>
    _ShellSpecDto(
      executable: json['executable'] as String,
      arguments:
          (json['arguments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ShellSpecDtoToJson(_ShellSpecDto instance) =>
    <String, dynamic>{
      'executable': instance.executable,
      'arguments': instance.arguments,
    };

_TerminalDto _$TerminalDtoFromJson(Map<String, dynamic> json) => _TerminalDto(
  id: json['id'] as String,
  worktreeId: json['worktreeId'] as String,
  title: json['title'] as String,
  shell: ShellSpecDto.fromJson(json['shell'] as Map<String, dynamic>),
  status: $enumDecode(_$TerminalStatusEnumMap, json['status']),
  columns: (json['columns'] as num).toInt(),
  rows: (json['rows'] as num).toInt(),
  lastSequence: (json['lastSequence'] as num).toInt(),
  exitCode: (json['exitCode'] as num?)?.toInt(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$TerminalDtoToJson(_TerminalDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'worktreeId': instance.worktreeId,
      'title': instance.title,
      'shell': instance.shell,
      'status': _$TerminalStatusEnumMap[instance.status]!,
      'columns': instance.columns,
      'rows': instance.rows,
      'lastSequence': instance.lastSequence,
      'exitCode': instance.exitCode,
      'error': instance.error,
    };

const _$TerminalStatusEnumMap = {
  TerminalStatus.running: 'running',
  TerminalStatus.exited: 'exited',
  TerminalStatus.failed: 'failed',
};

_TerminalOutputDto _$TerminalOutputDtoFromJson(Map<String, dynamic> json) =>
    _TerminalOutputDto(
      terminalId: json['terminalId'] as String,
      sequence: (json['sequence'] as num).toInt(),
      data: json['data'] as String,
    );

Map<String, dynamic> _$TerminalOutputDtoToJson(_TerminalOutputDto instance) =>
    <String, dynamic>{
      'terminalId': instance.terminalId,
      'sequence': instance.sequence,
      'data': instance.data,
    };

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
  WorkspaceKind.home: 'home',
};

_WorktreeDto _$WorktreeDtoFromJson(Map<String, dynamic> json) => _WorktreeDto(
  id: json['id'] as String,
  workspaceId: json['workspaceId'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  kind: $enumDecode(_$WorktreeKindEnumMap, json['kind']),
  isTinestOwned: json['isTinestOwned'] as bool,
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
      'isTinestOwned': instance.isTinestOwned,
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
      shell: json['shell'] == null
          ? null
          : ShellSpecDto.fromJson(json['shell'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProjectSettingsDtoToJson(_ProjectSettingsDto instance) =>
    <String, dynamic>{
      'setup': instance.setup,
      'teardown': instance.teardown,
      'shell': instance.shell,
    };

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

_FileMatchDto _$FileMatchDtoFromJson(Map<String, dynamic> json) =>
    _FileMatchDto(
      relativePath: json['relativePath'] as String,
      absolutePath: json['absolutePath'] as String,
      name: json['name'] as String,
      isDirectory: json['isDirectory'] as bool,
      score: (json['score'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FileMatchDtoToJson(_FileMatchDto instance) =>
    <String, dynamic>{
      'relativePath': instance.relativePath,
      'absolutePath': instance.absolutePath,
      'name': instance.name,
      'isDirectory': instance.isDirectory,
      'score': instance.score,
    };

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
  modelId: json['modelId'] as String?,
);

Map<String, dynamic> _$AgentModelSelectionDtoToJson(
  _AgentModelSelectionDto instance,
) => <String, dynamic>{
  'source': _$AgentModelSourceEnumMap[instance.source]!,
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
  toolIds: (json['toolIds'] as List<dynamic>).map((e) => e as String).toList(),
  callableAgentIds: (json['callableAgentIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  contentHash: json['contentHash'] as String,
  sourcePath: json['sourcePath'] as String,
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
      'toolIds': instance.toolIds,
      'callableAgentIds': instance.callableAgentIds,
      'contentHash': instance.contentHash,
      'sourcePath': instance.sourcePath,
      'modelControls': instance.modelControls,
      'permissionMode': _$PermissionModeEnumMap[instance.permissionMode],
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
  PermissionMode.fullAccess: 'fullAccess',
};

_AgentToolDefinitionDto _$AgentToolDefinitionDtoFromJson(
  Map<String, dynamic> json,
) => _AgentToolDefinitionDto(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  risk: $enumDecode(_$ToolRiskEnumMap, json['risk']),
  group: $enumDecode(_$ToolGroupEnumMap, json['group']),
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
  'group': _$ToolGroupEnumMap[instance.group]!,
  'available': instance.available,
  'alwaysOn': instance.alwaysOn,
};

const _$ToolRiskEnumMap = {
  ToolRisk.read: 'read',
  ToolRisk.write: 'write',
  ToolRisk.command: 'command',
  ToolRisk.dangerous: 'dangerous',
};

const _$ToolGroupEnumMap = {
  ToolGroup.filesystem: 'filesystem',
  ToolGroup.editing: 'editing',
  ToolGroup.execution: 'execution',
  ToolGroup.attachments: 'attachments',
  ToolGroup.mcp: 'mcp',
  ToolGroup.collaboration: 'collaboration',
  ToolGroup.session: 'session',
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

_McpResourceSummaryDto _$McpResourceSummaryDtoFromJson(
  Map<String, dynamic> json,
) => _McpResourceSummaryDto(
  uri: json['uri'] as String,
  name: json['name'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  mimeType: json['mimeType'] as String?,
  sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
);

Map<String, dynamic> _$McpResourceSummaryDtoToJson(
  _McpResourceSummaryDto instance,
) => <String, dynamic>{
  'uri': instance.uri,
  'name': instance.name,
  'title': instance.title,
  'description': instance.description,
  'mimeType': instance.mimeType,
  'sizeBytes': instance.sizeBytes,
};

_McpResourceTemplateSummaryDto _$McpResourceTemplateSummaryDtoFromJson(
  Map<String, dynamic> json,
) => _McpResourceTemplateSummaryDto(
  uriTemplate: json['uriTemplate'] as String,
  name: json['name'] as String?,
  title: json['title'] as String?,
  description: json['description'] as String?,
  mimeType: json['mimeType'] as String?,
);

Map<String, dynamic> _$McpResourceTemplateSummaryDtoToJson(
  _McpResourceTemplateSummaryDto instance,
) => <String, dynamic>{
  'uriTemplate': instance.uriTemplate,
  'name': instance.name,
  'title': instance.title,
  'description': instance.description,
  'mimeType': instance.mimeType,
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
  resources:
      (json['resources'] as List<dynamic>?)
          ?.map(
            (e) => McpResourceSummaryDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <McpResourceSummaryDto>[],
  resourceTemplates:
      (json['resourceTemplates'] as List<dynamic>?)
          ?.map(
            (e) => McpResourceTemplateSummaryDto.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const <McpResourceTemplateSummaryDto>[],
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
      'resources': instance.resources,
      'resourceTemplates': instance.resourceTemplates,
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

_AgentCommandDto _$AgentCommandDtoFromJson(Map<String, dynamic> json) =>
    _AgentCommandDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      source: $enumDecode(_$AgentCommandSourceEnumMap, json['source']),
      sourcePath: json['sourcePath'] as String,
      body: json['body'] as String,
      argumentHint: json['argumentHint'] as String?,
    );

Map<String, dynamic> _$AgentCommandDtoToJson(_AgentCommandDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'source': _$AgentCommandSourceEnumMap[instance.source]!,
      'sourcePath': instance.sourcePath,
      'body': instance.body,
      'argumentHint': instance.argumentHint,
    };

const _$AgentCommandSourceEnumMap = {
  AgentCommandSource.userHome: 'userHome',
  AgentCommandSource.config: 'config',
  AgentCommandSource.project: 'project',
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
) => _SessionModelSelectionDto(modelId: json['modelId'] as String);

Map<String, dynamic> _$SessionModelSelectionDtoToJson(
  _SessionModelSelectionDto instance,
) => <String, dynamic>{'modelId': instance.modelId};

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
  parentSessionId: json['parentSessionId'] as String?,
  taskName: json['taskName'] as String?,
  agentPath: json['agentPath'] as String?,
  rootSessionId: json['rootSessionId'] as String?,
  lifecycle: $enumDecodeNullable(_$AgentLifecycleEnumMap, json['lifecycle']),
  activeTurnId: json['activeTurnId'] as String?,
  lastError: json['lastError'] as String?,
  contextTokens: (json['contextTokens'] as num?)?.toInt() ?? 0,
  contextWindow: (json['contextWindow'] as num?)?.toInt(),
  totalCostUsd: (json['totalCostUsd'] as num?)?.toDouble(),
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
      'modelControls': instance.modelControls,
      'permissionMode': _$PermissionModeEnumMap[instance.permissionMode],
      'parentSessionId': instance.parentSessionId,
      'taskName': instance.taskName,
      'agentPath': instance.agentPath,
      'rootSessionId': instance.rootSessionId,
      'lifecycle': _$AgentLifecycleEnumMap[instance.lifecycle],
      'activeTurnId': instance.activeTurnId,
      'lastError': instance.lastError,
      'contextTokens': instance.contextTokens,
      'contextWindow': instance.contextWindow,
      'totalCostUsd': instance.totalCostUsd,
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
  SessionStatus.waitingForInput: 'waitingForInput',
  SessionStatus.failed: 'failed',
  SessionStatus.closed: 'closed',
};

const _$SessionModeEnumMap = {
  SessionMode.plan: 'plan',
  SessionMode.normal: 'normal',
};

const _$AgentLifecycleEnumMap = {
  AgentLifecycle.pendingInit: 'pendingInit',
  AgentLifecycle.running: 'running',
  AgentLifecycle.interrupted: 'interrupted',
  AgentLifecycle.completed: 'completed',
  AgentLifecycle.errored: 'errored',
};

_GoalDto _$GoalDtoFromJson(Map<String, dynamic> json) => _GoalDto(
  sessionId: json['sessionId'] as String,
  goalId: json['goalId'] as String,
  objective: json['objective'] as String,
  status: $enumDecode(_$GoalStatusEnumMap, json['status']),
  tokensUsed: (json['tokensUsed'] as num).toInt(),
  timeUsedSeconds: (json['timeUsedSeconds'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  tokenBudget: (json['tokenBudget'] as num?)?.toInt(),
);

Map<String, dynamic> _$GoalDtoToJson(_GoalDto instance) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'goalId': instance.goalId,
  'objective': instance.objective,
  'status': _$GoalStatusEnumMap[instance.status]!,
  'tokensUsed': instance.tokensUsed,
  'timeUsedSeconds': instance.timeUsedSeconds,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'tokenBudget': instance.tokenBudget,
};

const _$GoalStatusEnumMap = {
  GoalStatus.active: 'active',
  GoalStatus.paused: 'paused',
  GoalStatus.blocked: 'blocked',
  GoalStatus.usageLimited: 'usageLimited',
  GoalStatus.budgetLimited: 'budgetLimited',
  GoalStatus.complete: 'complete',
};

_AgentMailboxMessageDto _$AgentMailboxMessageDtoFromJson(
  Map<String, dynamic> json,
) => _AgentMailboxMessageDto(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  senderPath: json['senderPath'] as String,
  recipientPath: json['recipientPath'] as String,
  type: $enumDecode(_$InterAgentMessageTypeEnumMap, json['type']),
  payload: json['payload'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  senderSessionId: json['senderSessionId'] as String?,
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
);

Map<String, dynamic> _$AgentMailboxMessageDtoToJson(
  _AgentMailboxMessageDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'sessionId': instance.sessionId,
  'senderPath': instance.senderPath,
  'recipientPath': instance.recipientPath,
  'type': _$InterAgentMessageTypeEnumMap[instance.type]!,
  'payload': instance.payload,
  'createdAt': instance.createdAt.toIso8601String(),
  'senderSessionId': instance.senderSessionId,
  'deliveredAt': instance.deliveredAt?.toIso8601String(),
};

const _$InterAgentMessageTypeEnumMap = {
  InterAgentMessageType.message: 'message',
  InterAgentMessageType.newTask: 'newTask',
  InterAgentMessageType.finalAnswer: 'finalAnswer',
};

_ModelControlChoiceDto _$ModelControlChoiceDtoFromJson(
  Map<String, dynamic> json,
) => _ModelControlChoiceDto(
  id: json['id'] as String,
  label: json['label'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$ModelControlChoiceDtoToJson(
  _ModelControlChoiceDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'description': instance.description,
};

_ModelControlDescriptorDto _$ModelControlDescriptorDtoFromJson(
  Map<String, dynamic> json,
) => _ModelControlDescriptorDto(
  id: json['id'] as String,
  label: json['label'] as String,
  kind: $enumDecode(_$ModelControlKindEnumMap, json['kind']),
  presentation: $enumDecode(
    _$ModelControlPresentationEnumMap,
    json['presentation'],
  ),
  description: json['description'] as String?,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map(
            (e) => ModelControlChoiceDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModelControlChoiceDto>[],
  minimum: (json['minimum'] as num?)?.toInt(),
  maximum: (json['maximum'] as num?)?.toInt(),
  step: (json['step'] as num?)?.toInt(),
  conflictsWith:
      (json['conflictsWith'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
);

Map<String, dynamic> _$ModelControlDescriptorDtoToJson(
  _ModelControlDescriptorDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'kind': _$ModelControlKindEnumMap[instance.kind]!,
  'presentation': _$ModelControlPresentationEnumMap[instance.presentation]!,
  'description': instance.description,
  'choices': instance.choices,
  'minimum': instance.minimum,
  'maximum': instance.maximum,
  'step': instance.step,
  'conflictsWith': instance.conflictsWith,
};

const _$ModelControlKindEnumMap = {
  ModelControlKind.choice: 'choice',
  ModelControlKind.toggle: 'toggle',
  ModelControlKind.integer: 'integer',
};

const _$ModelControlPresentationEnumMap = {
  ModelControlPresentation.menuChip: 'menuChip',
  ModelControlPresentation.selectableChip: 'selectableChip',
  ModelControlPresentation.numberDialog: 'numberDialog',
};

ModelControlStringValueDto _$ModelControlStringValueDtoFromJson(
  Map<String, dynamic> json,
) => ModelControlStringValueDto(
  value: json['value'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ModelControlStringValueDtoToJson(
  ModelControlStringValueDto instance,
) => <String, dynamic>{'value': instance.value, 'type': instance.$type};

ModelControlBoolValueDto _$ModelControlBoolValueDtoFromJson(
  Map<String, dynamic> json,
) => ModelControlBoolValueDto(
  value: json['value'] as bool,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ModelControlBoolValueDtoToJson(
  ModelControlBoolValueDto instance,
) => <String, dynamic>{'value': instance.value, 'type': instance.$type};

ModelControlIntValueDto _$ModelControlIntValueDtoFromJson(
  Map<String, dynamic> json,
) => ModelControlIntValueDto(
  value: (json['value'] as num).toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ModelControlIntValueDtoToJson(
  ModelControlIntValueDto instance,
) => <String, dynamic>{'value': instance.value, 'type': instance.$type};

_ModelCapabilitiesDto _$ModelCapabilitiesDtoFromJson(
  Map<String, dynamic> json,
) => _ModelCapabilitiesDto(
  streaming:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['streaming']) ??
      CapabilitySupport.unknown,
  toolCalling:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['toolCalling']) ??
      CapabilitySupport.unknown,
  imageInput:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['imageInput']) ??
      CapabilitySupport.unknown,
  fileInput:
      $enumDecodeNullable(_$CapabilitySupportEnumMap, json['fileInput']) ??
      CapabilitySupport.unknown,
  controls:
      (json['controls'] as List<dynamic>?)
          ?.map(
            (e) =>
                ModelControlDescriptorDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModelControlDescriptorDto>[],
  toolSurface:
      $enumDecodeNullable(_$ModelToolSurfaceEnumMap, json['toolSurface']) ??
      ModelToolSurface.direct,
  source:
      $enumDecodeNullable(_$CapabilitySourceEnumMap, json['source']) ??
      CapabilitySource.unknown,
);

Map<String, dynamic> _$ModelCapabilitiesDtoToJson(
  _ModelCapabilitiesDto instance,
) => <String, dynamic>{
  'streaming': _$CapabilitySupportEnumMap[instance.streaming]!,
  'toolCalling': _$CapabilitySupportEnumMap[instance.toolCalling]!,
  'imageInput': _$CapabilitySupportEnumMap[instance.imageInput]!,
  'fileInput': _$CapabilitySupportEnumMap[instance.fileInput]!,
  'controls': instance.controls,
  'toolSurface': _$ModelToolSurfaceEnumMap[instance.toolSurface]!,
  'source': _$CapabilitySourceEnumMap[instance.source]!,
};

const _$CapabilitySupportEnumMap = {
  CapabilitySupport.unknown: 'unknown',
  CapabilitySupport.supported: 'supported',
  CapabilitySupport.unsupported: 'unsupported',
};

const _$ModelToolSurfaceEnumMap = {
  ModelToolSurface.direct: 'direct',
  ModelToolSurface.luaCode: 'luaCode',
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

_ProviderWireFormatDto _$ProviderWireFormatDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderWireFormatDto(
  id: json['id'] as String,
  label: json['label'] as String,
  controls:
      (json['controls'] as List<dynamic>?)
          ?.map(
            (e) =>
                ModelControlDescriptorDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModelControlDescriptorDto>[],
);

Map<String, dynamic> _$ProviderWireFormatDtoToJson(
  _ProviderWireFormatDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'controls': instance.controls,
};

_CustomProviderConfigDto _$CustomProviderConfigDtoFromJson(
  Map<String, dynamic> json,
) => _CustomProviderConfigDto(
  name: json['name'] as String,
  baseUrl: json['baseUrl'] as String,
  wireFormatId: json['wireFormatId'] as String,
  authenticationRequired: json['authenticationRequired'] as bool,
  strictToolSchema: json['strictToolSchema'] as bool? ?? false,
  models:
      (json['models'] as List<dynamic>?)
          ?.map(
            (e) => ManualProviderModelDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ManualProviderModelDto>[],
);

Map<String, dynamic> _$CustomProviderConfigDtoToJson(
  _CustomProviderConfigDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'baseUrl': instance.baseUrl,
  'wireFormatId': instance.wireFormatId,
  'authenticationRequired': instance.authenticationRequired,
  'strictToolSchema': instance.strictToolSchema,
  'models': instance.models,
};

_ManualProviderModelDto _$ManualProviderModelDtoFromJson(
  Map<String, dynamic> json,
) => _ManualProviderModelDto(
  id: json['id'] as String,
  label: json['label'] as String,
  controls:
      (json['controls'] as List<dynamic>?)
          ?.map(
            (e) =>
                ModelControlDescriptorDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <ModelControlDescriptorDto>[],
);

Map<String, dynamic> _$ManualProviderModelDtoToJson(
  _ManualProviderModelDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'controls': instance.controls,
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
  modelPrefix: json['modelPrefix'] as String? ?? '',
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
  'modelPrefix': instance.modelPrefix,
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
  ProviderCredentialOrigin.oauth: 'oauth',
  ProviderCredentialOrigin.none: 'none',
};

_ProviderUsageWindowDto _$ProviderUsageWindowDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderUsageWindowDto(
  kind: $enumDecode(_$ProviderUsageWindowKindEnumMap, json['kind']),
  usedPercent: (json['usedPercent'] as num).toDouble(),
  resetsAt: json['resetsAt'] == null
      ? null
      : DateTime.parse(json['resetsAt'] as String),
);

Map<String, dynamic> _$ProviderUsageWindowDtoToJson(
  _ProviderUsageWindowDto instance,
) => <String, dynamic>{
  'kind': _$ProviderUsageWindowKindEnumMap[instance.kind]!,
  'usedPercent': instance.usedPercent,
  'resetsAt': instance.resetsAt?.toIso8601String(),
};

const _$ProviderUsageWindowKindEnumMap = {
  ProviderUsageWindowKind.session: 'session',
  ProviderUsageWindowKind.weekly: 'weekly',
  ProviderUsageWindowKind.codeReview: 'codeReview',
};

_ProviderUsageDto _$ProviderUsageDtoFromJson(Map<String, dynamic> json) =>
    _ProviderUsageDto(
      connectionId: json['connectionId'] as String,
      status: $enumDecode(_$ProviderUsageStatusEnumMap, json['status']),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      provider: json['provider'] as String? ?? '',
      plan: json['plan'] as String?,
      windows:
          (json['windows'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ProviderUsageWindowDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ProviderUsageWindowDto>[],
      creditBalance: (json['creditBalance'] as num?)?.toDouble(),
      detail: json['detail'] as String?,
      errorCode: json['errorCode'] as String?,
    );

Map<String, dynamic> _$ProviderUsageDtoToJson(_ProviderUsageDto instance) =>
    <String, dynamic>{
      'connectionId': instance.connectionId,
      'status': _$ProviderUsageStatusEnumMap[instance.status]!,
      'fetchedAt': instance.fetchedAt.toIso8601String(),
      'provider': instance.provider,
      'plan': instance.plan,
      'windows': instance.windows,
      'creditBalance': instance.creditBalance,
      'detail': instance.detail,
      'errorCode': instance.errorCode,
    };

const _$ProviderUsageStatusEnumMap = {
  ProviderUsageStatus.available: 'available',
  ProviderUsageStatus.unsupported: 'unsupported',
  ProviderUsageStatus.error: 'error',
};

_ProviderAuthAttemptDto _$ProviderAuthAttemptDtoFromJson(
  Map<String, dynamic> json,
) => _ProviderAuthAttemptDto(
  id: json['id'] as String,
  definitionId: json['definitionId'] as String,
  methodId: json['methodId'] as String,
  status: $enumDecode(_$ProviderAuthAttemptStatusEnumMap, json['status']),
  connectionId: json['connectionId'] as String? ?? '',
  modelPrefix: json['modelPrefix'] as String? ?? '',
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
  'connectionId': instance.connectionId,
  'modelPrefix': instance.modelPrefix,
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
      providerModelId: json['providerModelId'] as String? ?? '',
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
      'providerModelId': instance.providerModelId,
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
      freshness:
          $enumDecodeNullable(
            _$ProviderCatalogFreshnessEnumMap,
            json['freshness'],
          ) ??
          ProviderCatalogFreshness.bundled,
      lastSuccessAt: json['lastSuccessAt'] == null
          ? null
          : DateTime.parse(json['lastSuccessAt'] as String),
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      refreshError: json['refreshError'] as String?,
      wireFormats:
          (json['wireFormats'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ProviderWireFormatDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ProviderWireFormatDto>[],
    );

Map<String, dynamic> _$ProviderCatalogDtoToJson(_ProviderCatalogDto instance) =>
    <String, dynamic>{
      'definitions': instance.definitions,
      'source': _$ProviderCatalogSourceEnumMap[instance.source]!,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'freshness': _$ProviderCatalogFreshnessEnumMap[instance.freshness]!,
      'lastSuccessAt': instance.lastSuccessAt?.toIso8601String(),
      'lastAttemptAt': instance.lastAttemptAt?.toIso8601String(),
      'refreshError': instance.refreshError,
      'wireFormats': instance.wireFormats,
    };

const _$ProviderCatalogSourceEnumMap = {
  ProviderCatalogSource.bundled: 'bundled',
  ProviderCatalogSource.refreshed: 'refreshed',
};

const _$ProviderCatalogFreshnessEnumMap = {
  ProviderCatalogFreshness.bundled: 'bundled',
  ProviderCatalogFreshness.cached: 'cached',
  ProviderCatalogFreshness.fresh: 'fresh',
  ProviderCatalogFreshness.stale: 'stale',
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

_UserQuestionOptionDto _$UserQuestionOptionDtoFromJson(
  Map<String, dynamic> json,
) => _UserQuestionOptionDto(
  label: json['label'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$UserQuestionOptionDtoToJson(
  _UserQuestionOptionDto instance,
) => <String, dynamic>{
  'label': instance.label,
  'description': instance.description,
};

_UserQuestionItemDto _$UserQuestionItemDtoFromJson(Map<String, dynamic> json) =>
    _UserQuestionItemDto(
      id: json['id'] as String,
      header: json['header'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => UserQuestionOptionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserQuestionItemDtoToJson(
  _UserQuestionItemDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'header': instance.header,
  'question': instance.question,
  'options': instance.options,
};

_UserQuestionAnswerDto _$UserQuestionAnswerDtoFromJson(
  Map<String, dynamic> json,
) => _UserQuestionAnswerDto(
  questionId: json['questionId'] as String,
  answer: json['answer'] as String,
  isFreeForm: json['isFreeForm'] as bool,
);

Map<String, dynamic> _$UserQuestionAnswerDtoToJson(
  _UserQuestionAnswerDto instance,
) => <String, dynamic>{
  'questionId': instance.questionId,
  'answer': instance.answer,
  'isFreeForm': instance.isFreeForm,
};

_UserQuestionRequestDto _$UserQuestionRequestDtoFromJson(
  Map<String, dynamic> json,
) => _UserQuestionRequestDto(
  id: json['id'] as String,
  sessionId: json['sessionId'] as String,
  turnId: json['turnId'] as String,
  toolCallId: json['toolCallId'] as String,
  questions: (json['questions'] as List<dynamic>)
      .map((e) => UserQuestionItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: $enumDecode(_$UserQuestionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  answers:
      (json['answers'] as List<dynamic>?)
          ?.map(
            (e) => UserQuestionAnswerDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <UserQuestionAnswerDto>[],
);

Map<String, dynamic> _$UserQuestionRequestDtoToJson(
  _UserQuestionRequestDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'sessionId': instance.sessionId,
  'turnId': instance.turnId,
  'toolCallId': instance.toolCallId,
  'questions': instance.questions,
  'status': _$UserQuestionStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'answers': instance.answers,
};

const _$UserQuestionStatusEnumMap = {
  UserQuestionStatus.pending: 'pending',
  UserQuestionStatus.answered: 'answered',
  UserQuestionStatus.cancelled: 'cancelled',
};

_ServerInfoDto _$ServerInfoDtoFromJson(Map<String, dynamic> json) =>
    _ServerInfoDto(
      serverId: json['serverId'] as String,
      version: json['version'] as String,
      protocolVersion: (json['protocolVersion'] as num).toInt(),
      features: Map<String, bool>.from(json['features'] as Map),
      homeDirectory: json['homeDirectory'] as String?,
    );

Map<String, dynamic> _$ServerInfoDtoToJson(_ServerInfoDto instance) =>
    <String, dynamic>{
      'serverId': instance.serverId,
      'version': instance.version,
      'protocolVersion': instance.protocolVersion,
      'features': instance.features,
      'homeDirectory': instance.homeDirectory,
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
