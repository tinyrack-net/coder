import 'dart:async';
import 'dart:typed_data';

import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';

sealed class ClientEvent {
  const ClientEvent();
}

extension TypedClientEventStream on Stream<ClientEvent> {
  Stream<T> whereType<T extends ClientEvent>() =>
      where((event) => event is T).cast<T>();
}

final class TimelineClientEvent extends ClientEvent {
  const TimelineClientEvent(this.event);
  final TimelineEventDto event;
}

final class SessionUpdatedClientEvent extends ClientEvent {
  const SessionUpdatedClientEvent(this.session);
  final SessionDto session;
}

final class TerminalOutputClientEvent extends ClientEvent {
  const TerminalOutputClientEvent(this.output);
  final TerminalOutputDto output;
}

final class TerminalUpdatedClientEvent extends ClientEvent {
  const TerminalUpdatedClientEvent(this.terminal);
  final TerminalDto terminal;
}

final class AgentDefinitionsChangedClientEvent extends ClientEvent {
  const AgentDefinitionsChangedClientEvent();
}

final class McpServersChangedClientEvent extends ClientEvent {
  const McpServersChangedClientEvent();
}

final class SkillsChangedClientEvent extends ClientEvent {
  const SkillsChangedClientEvent();
}

final class CommandsChangedClientEvent extends ClientEvent {
  const CommandsChangedClientEvent();
}

final class ApprovalRequestedClientEvent extends ClientEvent {
  const ApprovalRequestedClientEvent(this.approval);
  final ApprovalRequestDto approval;
}

final class UserQuestionRequestedClientEvent extends ClientEvent {
  const UserQuestionRequestedClientEvent(this.request);
  final UserQuestionRequestDto request;
}

final class ProviderAuthUpdatedClientEvent extends ClientEvent {
  const ProviderAuthUpdatedClientEvent(this.attempt);
  final ProviderAuthAttemptDto attempt;
}

/// An in-memory [CoderApi] used by notifier and widget tests.
final class FakeCoderApi
    implements
        CoderApi,
        WorkspacesApi,
        SessionsApi,
        AgentsApi,
        PromptsApi,
        ProvidersApi,
        McpApi,
        TerminalsApi,
        AttachmentsApi {
  /// Creates a configurable [FakeCoderApi].
  FakeCoderApi({
    ServerInfoDto? serverInfo,
    ProviderCatalogDto? catalog,
    List<ProviderConnectionDto>? connections,
    List<WorkspaceDto>? workspaces,
    List<WorktreeDto>? worktrees,
    List<SessionDto>? agents,
    List<TerminalDto>? terminals,
    List<AgentDefinitionDto>? agentDefinitions,
    List<SkillDto>? skills,
    List<SkillDto>? projectSkills,
    Map<String, List<TimelineEventDto>>? timelines,
    Map<String, List<ProviderModelDto>>? models,
    this.eventStream,
    this.agentListError,
    this.skillListError,
    this.failNextAgentCreate = false,
    this.failNextAgentUpdate = false,
    this.failNextSkillUpdate = false,
    this.catalogRefreshError,
    this.modelListGate,
    this.suggestDirectoriesGate,
    this.workspaceCatalogGate,
    this.agentDefinitionsGate,
    this.createWorktreeError,
    this.suggestDirectoriesError,
    this.projectSettingsError,
    List<Future<List<McpServerStateDto>>>? mcpListResponses,
    this.terminalAttachError,
    this.terminalReplay = const <TerminalOutputDto>[],
    Map<String, List<String>>? directories,
    Map<String, List<String>>? files,
    List<AgentCommandDto>? commands,
    this.searchFilesGate,
    this.searchFilesError,
    this.defaultPermissionSetError,
    this.sessionPermissionSetError,
    this._defaultPermissionMode = PermissionMode.ask,
  }) : mcpListResponses =
           mcpListResponses ?? <Future<List<McpServerStateDto>>>[],
       directories = directories ?? const <String, List<String>>{},
       files = files ?? const <String, List<String>>{},
       commands = List<AgentCommandDto>.of(
         commands ?? const <AgentCommandDto>[],
       ),
       _serverInfo = serverInfo ?? _defaultServerInfo,
       _catalog = catalog ?? _defaultCatalog,
       _connections = connections ?? <ProviderConnectionDto>[_openAIConnection],
       _workspaces = workspaces ?? <WorkspaceDto>[],
       _worktrees = worktrees ?? <WorktreeDto>[],
       _agents = agents ?? <SessionDto>[],
       _terminals = terminals ?? <TerminalDto>[],
       _agentDefinitions = List<AgentDefinitionDto>.of(
         agentDefinitions ?? <AgentDefinitionDto>[_coder],
       ),
       _skills = List<SkillDto>.of(
         skills ?? <SkillDto>[_builtInSkill, _configSkill],
       ),
       _projectSkills = List<SkillDto>.of(projectSkills ?? <SkillDto>[]),
       _timelines = <String, List<TimelineEventDto>>{
         for (final entry
             in (timelines ?? <String, List<TimelineEventDto>>{}).entries)
           entry.key: List<TimelineEventDto>.of(entry.value),
       },
       _models = <String, List<ProviderModelDto>>{
         'openai': <ProviderModelDto>[_openAIModel],
         for (final entry
             in (models ?? <String, List<ProviderModelDto>>{}).entries)
           entry.key: List<ProviderModelDto>.of(entry.value),
       };

  static final DateTime _now = DateTime.utc(2026);

  /// Error thrown once by the next explicit provider catalog refresh.
  CoderClientException? catalogRefreshError;
  static const ServerInfoDto _defaultServerInfo = ServerInfoDto(
    serverId: 'server',
    version: 'test',
    protocolVersion: coderProtocolMajor,
    features: <String, bool>{},
  );
  static final ProviderCatalogDto _defaultCatalog = ProviderCatalogDto(
    definitions: const <ProviderDefinitionDto>[
      ProviderDefinitionDto(
        id: 'openai',
        name: 'OpenAI',
        description: 'OpenAI Platform API or ChatGPT subscription.',
        authMethods: <ProviderAuthMethodDto>[
          ProviderAuthMethodDto(
            id: 'chatgpt-browser',
            label: 'Sign in with ChatGPT',
            kind: ProviderAuthKind.oauth,
            flow: ProviderAuthFlow.oauthBrowser,
            experimental: true,
          ),
          ProviderAuthMethodDto(
            id: 'api-key',
            label: 'API key',
            kind: ProviderAuthKind.apiKey,
            flow: ProviderAuthFlow.apiKey,
          ),
        ],
        recommendedModelIds: <String>['gpt-5.6-sol'],
      ),
      ProviderDefinitionDto(
        id: 'deepseek',
        name: 'DeepSeek',
        description: 'DeepSeek hosted models.',
        authMethods: <ProviderAuthMethodDto>[
          ProviderAuthMethodDto(
            id: 'api-key',
            label: 'API key',
            kind: ProviderAuthKind.apiKey,
            flow: ProviderAuthFlow.apiKey,
          ),
        ],
      ),
    ],
    source: ProviderCatalogSource.bundled,
    updatedAt: _now,
  );
  static final ProviderConnectionDto _openAIConnection = ProviderConnectionDto(
    id: 'openai',
    definitionId: 'openai',
    displayName: 'OpenAI',
    status: ProviderConnectionStatus.connected,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    createdAt: _now,
    updatedAt: _now,
  );
  static const ProviderModelDto _openAIModel = ProviderModelDto(
    connectionId: 'openai',
    id: 'gpt-5.6-sol',
    label: 'GPT-5.6 Sol',
    source: ProviderModelSource.bundled,
    capabilities: ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
      controls: <ModelControlDescriptorDto>[
        ModelControlDescriptorDto(
          id: 'reasoning_effort',
          label: 'Reasoning effort',
          kind: ModelControlKind.choice,
          presentation: ModelControlPresentation.menuChip,
          choices: <ModelControlChoiceDto>[
            ModelControlChoiceDto(id: 'medium', label: 'Medium'),
          ],
        ),
      ],
      source: CapabilitySource.bundled,
    ),
  );
  static const AgentDefinitionDto _coder = AgentDefinitionDto(
    id: 'coder',
    name: 'Coder',
    description: 'General-purpose coding agent',
    mode: AgentMode.primary,
    promptEnabled: true,
    systemPrompt: 'Code carefully.',
    model: AgentModelSelectionDto(
      source: AgentModelSource.session,
    ),
    permissionMode: PermissionMode.ask,
    toolIds: <String>['read_file'],
    callableAgentIds: <String>[],
    contentHash: 'coder-hash',
    sourcePath: '/config/agents/coder.md',
    isBuiltIn: true,
  );

  static const SkillDto _builtInSkill = SkillDto(
    id: 'coding-conventions',
    name: 'coding-conventions',
    description: 'Match the surrounding code.',
    source: SkillSource.builtIn,
    sourcePath: '',
    contentHash: 'coding-conventions-hash',
    body: 'Read neighbouring code first.',
    isMandatory: true,
  );

  static const SkillDto _configSkill = SkillDto(
    id: 'commit',
    name: 'commit',
    description: 'Writes atomic commits.',
    source: SkillSource.config,
    sourcePath: '/config/skills/commit/SKILL.md',
    contentHash: 'commit-hash',
    body: 'Stage related changes together.',
    isEditable: true,
    resources: <SkillResourceDto>[
      SkillResourceDto(path: 'scripts/split.sh', sizeBytes: 11),
    ],
  );

  final ServerInfoDto _serverInfo;
  ProviderCatalogDto _catalog;
  final List<ProviderConnectionDto> _connections;
  final List<WorkspaceDto> _workspaces;
  final List<WorktreeDto> _worktrees;
  final List<SessionDto> _agents;
  final List<TerminalDto> _terminals;
  ShellSpecDto? _terminalShell;

  /// Host shell saved through the settings API.
  ShellSpecDto? get terminalShell => _terminalShell;
  SessionModelSelectionDto? _defaultModel;

  /// Daemon-global default model saved through the provider settings API.
  SessionModelSelectionDto? get defaultModel => _defaultModel;
  PermissionMode _defaultPermissionMode;

  /// Error thrown when the daemon-global permission default is saved.
  final Exception? defaultPermissionSetError;

  /// Error thrown when a chat permission override is saved.
  final Exception? sessionPermissionSetError;

  /// Daemon-global default permission mode.
  PermissionMode get defaultPermissionMode => _defaultPermissionMode;
  final List<AgentDefinitionDto> _agentDefinitions;
  final List<SkillDto> _skills;
  final List<SkillDto> _projectSkills;
  final Map<String, List<TimelineEventDto>> _timelines;
  final Map<String, List<ProviderModelDto>> _models;

  /// Optional event stream that can model transport lifecycle races.
  final Stream<ClientEvent>? eventStream;

  /// Optional failure returned while loading Markdown agent definitions.
  final Exception? agentListError;

  /// Optional failure returned while loading the skill catalog.
  Exception? skillListError;

  /// Optional attach failure used by terminal error-state tests.
  final Exception? terminalAttachError;

  /// Scrollback returned by terminal attach.
  final List<TerminalOutputDto> terminalReplay;

  /// Whether the next guarded Markdown save should simulate a file race.
  bool failNextAgentUpdate;

  /// Whether the next guarded skill save should simulate a file race.
  bool failNextSkillUpdate;

  /// Whether the next Markdown create should simulate a daemon failure.
  bool failNextAgentCreate;

  /// Optional gate used to keep model discovery in its loading state.
  final Future<void>? modelListGate;

  /// Optional gate used to keep the workspace catalog in its loading state.
  final Future<void>? workspaceCatalogGate;

  /// Optional gate used to keep agent definition discovery in its loading
  /// state.
  final Future<void>? agentDefinitionsGate;

  /// Daemon-side directory tree keyed by parent path.
  final Map<String, List<String>> directories;

  /// Optional gate used to order concurrent directory listings.
  final Future<void>? suggestDirectoriesGate;

  /// Optional daemon failure returned while creating a worktree.
  final CoderClientException? createWorktreeError;

  /// Optional daemon failure returned while listing directories.
  final CoderClientException? suggestDirectoriesError;

  /// Directory queries received by the fake, in call order.
  final List<String> suggestedQueries = <String>[];

  /// Worktree-relative file paths keyed by worktree ID.
  final Map<String, List<String>> files;

  /// Agent commands the daemon offers.
  final List<AgentCommandDto> commands;

  /// Optional gate used to keep a file search in its loading state.
  final Future<void>? searchFilesGate;

  /// Optional daemon failure returned while searching files.
  final CoderClientException? searchFilesError;

  /// File search queries received by the fake, in call order.
  final List<String> searchedQueries = <String>[];

  /// Worktree creations recorded by the fake.
  final List<({WorktreeCreateMode mode, String branchName, String? baseBranch})>
  createdWorktrees =
      <({WorktreeCreateMode mode, String branchName, String? baseBranch})>[];

  /// Workspace IDs whose Git branches were requested.
  final List<String> listedGitBranchWorkspaceIds = <String>[];
  final StreamController<ClientEvent> _events =
      StreamController<ClientEvent>.broadcast(sync: true);
  final StreamController<ClientConnectionState> _states =
      StreamController<ClientConnectionState>.broadcast(sync: true);
  final StreamController<ProviderCatalogDto> _catalogUpdates =
      StreamController<ProviderCatalogDto>.broadcast(sync: true);
  bool _closed = false;

  /// Whether [close] released this fake client.
  bool get isClosed => _closed;

  @override
  Stream<ProviderCatalogDto> get catalogUpdates => _catalogUpdates.stream;

  /// Paths registered through the fake, in call order.
  final List<String> registeredPaths = <String>[];

  /// Sessions created through the fake, in creation order.
  final List<SessionDto> createdSessions = <SessionDto>[];

  /// Session mode switches written through the fake.
  final List<({String sessionId, SessionMode mode})> updatedSessionModes =
      <({String sessionId, SessionMode mode})>[];

  /// Session model overrides written through the fake.
  final List<({String sessionId, SessionModelSelectionDto? model})>
  updatedSessionModels =
      <({String sessionId, SessionModelSelectionDto? model})>[];

  /// Session reasoning effort overrides written through the fake.
  final List<({String sessionId, String? reasoningEffort})>
  updatedSessionReasoningEfforts =
      <({String sessionId, String? reasoningEffort})>[];

  /// Session permission mode overrides written through the fake.
  final List<({String sessionId, PermissionMode? permissionMode})>
  updatedSessionPermissionModes =
      <({String sessionId, PermissionMode? permissionMode})>[];

  /// Session service tier selections written through the fake.
  final List<({String sessionId, String? serviceTier})>
  updatedSessionServiceTiers = <({String sessionId, String? serviceTier})>[];

  /// Turn prompts received by the fake.
  final List<String> startedPrompts = <String>[];

  /// Turn identifiers received by the fake.
  final List<String> startedTurnIds = <String>[];

  /// Ordered attachment IDs received by each started turn.
  final List<List<String>> startedAttachmentIds = <List<String>>[];

  final Map<String, ({AttachmentDto metadata, Uint8List bytes})> _attachments =
      <String, ({AttachmentDto metadata, Uint8List bytes})>{};

  /// Agent identifiers cancelled through the fake.
  final List<String> cancelledAgents = <String>[];

  /// Sessions the client asked to compact, in order.
  final List<String> compactedSessions = <String>[];

  /// Provider credentials written through the fake.
  final Map<String, String> credentials = <String, String>{};

  /// OAuth attempts cancelled through the fake.
  final List<String> cancelledAuthAttempts = <String>[];

  /// Approval decisions received by the fake.
  /// Answers submitted through [answerUserQuestion], in order.
  final List<({String id, List<UserQuestionAnswerDto> answers})>
  questionAnswers = <({String id, List<UserQuestionAnswerDto> answers})>[];

  final List<({String id, bool approved})> approvalDecisions =
      <({String id, bool approved})>[];

  /// Thrown instead of starting a turn, so a caller's rollback can be checked.
  Exception? startTurnError;

  /// Prompts [startTurn] was called with, recorded before it can throw.
  ///
  /// [startedPrompts] only records what succeeded, so a retry bound has to be
  /// counted here or a failing send looks like no send at all.
  final List<String> attemptedPrompts = <String>[];

  /// Number of leading [startTurn] calls that fail before one is allowed.
  ///
  /// Separate from [startTurnError], which fails every call, so a test can
  /// distinguish "recovers on retry" from "never recovers".
  int startTurnFailures = 0;

  /// Awaited before a turn starts, to hold one send in flight.
  Completer<void>? startTurnGate;

  /// Thrown instead of noting pending input.
  Exception? notePendingInputError;

  /// Number of leading [listSessions] calls that fail before one succeeds.
  int listSessionsFailures = 0;

  /// Thrown instead of writing a session turn setting.
  Exception? sessionUpdateError;

  /// Awaited before a session turn setting is written.
  ///
  /// Lets a test observe the state a caller shows while the write is in
  /// flight, rather than only its settled result.
  Completer<void>? sessionUpdateGate;

  Future<void> _beforeSessionUpdate() async {
    final gate = sessionUpdateGate;
    if (gate != null) await gate.future;
    final error = sessionUpdateError;
    if (error != null) throw error;
  }

  /// Emits a typed daemon notification.
  ///
  /// A session update also lands in the stored sessions, so a later
  /// [listSessions] agrees with what subscribers were told.
  void emit(ClientEvent event) {
    if (event is SessionUpdatedClientEvent) {
      final index = _agents.indexWhere((agent) => agent.id == event.session.id);
      if (index >= 0) _agents[index] = event.session;
    }
    _events.add(event);
  }

  /// Appends and broadcasts one timeline event for a session.
  void emitTimeline(
    String sessionId,
    String type,
    Map<String, dynamic> data,
  ) {
    final events = _timelines.putIfAbsent(
      sessionId,
      () => <TimelineEventDto>[],
    );
    final event = TimelineEventDto(
      sessionId: sessionId,
      sequence: events.length + 1,
      turnId: 'turn-1',
      type: type,
      data: data,
      createdAt: _now,
    );
    events.add(event);
    emit(TimelineClientEvent(event));
  }

  /// Emits a transport connection state.
  void emitState(ClientConnectionState state) => _states.add(state);

  Stream<ClientEvent> get events => eventStream ?? _events.stream;

  @override
  Stream<ClientConnectionState> get states => _states.stream;

  @override
  WorkspacesApi get workspaces => this;

  @override
  SessionsApi get sessions => this;

  @override
  AgentsApi get agents => this;

  @override
  PromptsApi get prompts => this;

  @override
  ProvidersApi get providers => this;

  @override
  McpApi get mcp => this;

  @override
  TerminalsApi get terminals => this;

  @override
  AttachmentsApi get attachments => this;

  @override
  Stream<SessionDto> get sessionUpdates => events
      .whereType<SessionUpdatedClientEvent>()
      .map((event) => event.session);

  @override
  Stream<TimelineEventDto> get timelineEvents =>
      events.whereType<TimelineClientEvent>().map((event) => event.event);

  @override
  Stream<ApprovalRequestDto> get approvalRequests => events
      .whereType<ApprovalRequestedClientEvent>()
      .map((event) => event.approval);

  @override
  Stream<UserQuestionRequestDto> get questionRequests => events
      .whereType<UserQuestionRequestedClientEvent>()
      .map((event) => event.request);

  @override
  Stream<void> get definitionChanges =>
      events.whereType<AgentDefinitionsChangedClientEvent>().map((_) {});

  @override
  Stream<void> get skillChanges =>
      events.whereType<SkillsChangedClientEvent>().map((_) {});

  @override
  Stream<void> get commandChanges =>
      events.whereType<CommandsChangedClientEvent>().map((_) {});

  @override
  Stream<ProviderAuthAttemptDto> get authUpdates => events
      .whereType<ProviderAuthUpdatedClientEvent>()
      .map((event) => event.attempt);

  @override
  Stream<void> get serverChanges =>
      events.whereType<McpServersChangedClientEvent>().map((_) {});

  @override
  Stream<TerminalOutputDto> get output => events
      .whereType<TerminalOutputClientEvent>()
      .map((event) => event.output);

  @override
  Stream<TerminalDto> get terminalUpdates => events
      .whereType<TerminalUpdatedClientEvent>()
      .map((event) => event.terminal);

  @override
  ServerInfoDto get serverInfo => _serverInfo;

  @override
  Future<WorkspaceCatalogDto> getWorkspaceCatalog() async {
    await workspaceCatalogGate;
    return WorkspaceCatalogDto(
      workspaces: List<WorkspaceDto>.unmodifiable(_workspaces),
      worktrees: List<WorktreeDto>.unmodifiable(_worktrees),
    );
  }

  @override
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  }) async {
    registeredPaths.add(rootPath);
    final workspace = WorkspaceDto(
      id: workspaceId,
      name: name,
      rootPath: rootPath,
      kind: WorkspaceKind.directory,
      createdAt: _now,
    );
    final worktree = WorktreeDto(
      id: checkoutId,
      workspaceId: workspace.id,
      name: name,
      path: rootPath,
      kind: WorktreeKind.directory,
      isCoderOwned: false,
      createdAt: _now,
    );
    _workspaces.add(workspace);
    _worktrees.add(worktree);
    return WorkspaceRegisterResultDto(
      workspace: workspace,
      worktrees: <WorktreeDto>[worktree],
    );
  }

  @override
  Future<WorkspaceCatalogDto> refreshWorkspace(String workspaceId) =>
      getWorkspaceCatalog();

  @override
  Future<void> unregisterWorkspace(String workspaceId) async {
    _workspaces.removeWhere((item) => item.id == workspaceId);
    _worktrees.removeWhere((item) => item.workspaceId == workspaceId);
  }

  @override
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query, {
    int limit = 30,
  }) async {
    suggestedQueries.add(query);
    await suggestDirectoriesGate;
    final failure = suggestDirectoriesError;
    if (failure != null) throw failure;
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <DirectorySuggestionDto>[];
    // Mirrors the daemon: an existing directory lists its children, anything
    // else filters the siblings of the typed basename.
    final children = directories[trimmed];
    if (children != null) return _entries(children);
    final separator = trimmed.lastIndexOf('/');
    if (separator < 0) return const <DirectorySuggestionDto>[];
    final parent = separator == 0 ? '/' : trimmed.substring(0, separator);
    final needle = trimmed.substring(separator + 1).toLowerCase();
    final siblings = directories[parent] ?? const <String>[];
    return _entries(
      siblings
          .where((path) => _basename(path).toLowerCase().contains(needle))
          .toList(growable: false),
    );
  }

  List<DirectorySuggestionDto> _entries(List<String> paths) => paths
      .map((path) => DirectorySuggestionDto(path: path, name: _basename(path)))
      .toList(growable: false);

  static String _basename(String path) =>
      path.split('/').where((part) => part.isNotEmpty).lastOrNull ?? path;

  @override
  Future<List<GitBranchDto>> listGitBranches(String workspaceId) async {
    listedGitBranchWorkspaceIds.add(workspaceId);
    return branches;
  }

  /// Branches reported for every workspace.
  List<GitBranchDto> branches = const <GitBranchDto>[
    GitBranchDto(name: 'main', current: true, checkedOut: true),
    GitBranchDto(name: 'feature', current: false, checkedOut: false),
    GitBranchDto(
      name: 'origin/main',
      current: false,
      checkedOut: false,
      isRemote: true,
      isDefault: true,
    ),
  ];

  /// Project settings keyed by workspace ID.
  final Map<String, ProjectSettingsDto> projectSettings =
      <String, ProjectSettingsDto>{};

  /// Error returned while loading project settings.
  Exception? projectSettingsError;

  /// Number of project settings load attempts.
  int projectSettingsLoadCount = 0;

  /// Hook runs reported by the next worktree create call.
  List<WorktreeHookRunDto> createWorktreeHookRuns =
      const <WorktreeHookRunDto>[];

  /// Hook runs reported by the next worktree archive call.
  List<WorktreeHookRunDto> archiveWorktreeHookRuns =
      const <WorktreeHookRunDto>[];

  /// Holds an archive open, so a test can unmount the caller mid-flight.
  Completer<void>? archiveWorktreeGate;

  @override
  Future<ProjectSettingsResultDto> getProjectSettings(
    String workspaceId,
  ) async {
    projectSettingsLoadCount += 1;
    if (projectSettingsError case final error?) throw error;
    return ProjectSettingsResultDto(
      settings: projectSettings[workspaceId] ?? const ProjectSettingsDto(),
      sourcePath: '/projects/$workspaceId/coder.json',
    );
  }

  @override
  Future<ProjectSettingsResultDto> saveProjectSettings(
    String workspaceId,
    ProjectSettingsDto settings,
  ) async {
    projectSettings[workspaceId] = settings;
    return getProjectSettings(workspaceId);
  }

  @override
  Future<WorktreeResultDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  }) async {
    final failure = createWorktreeError;
    if (failure != null) throw failure;
    createdWorktrees.add((
      mode: mode,
      branchName: branchName,
      baseBranch: baseBranch,
    ));
    final worktree = WorktreeDto(
      id: id,
      workspaceId: workspaceId,
      name: branchName,
      path: '/worktrees/$branchName',
      branch: branchName,
      kind: WorktreeKind.managed,
      isCoderOwned: true,
      createdAt: _now,
    );
    _worktrees.add(worktree);
    return WorktreeResultDto(
      worktree: worktree,
      hookRuns: createWorktreeHookRuns,
    );
  }

  @override
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(
    String worktreeId,
  ) async => WorktreeArchivePreviewDto(
    worktreeId: worktreeId,
    dirty: false,
    unpushedCommitCount: 0,
    runningSessionCount: 0,
    removesDirectory: _worktrees
        .where((item) => item.id == worktreeId)
        .first
        .isCoderOwned,
  );

  @override
  Future<WorktreeResultDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  }) async {
    if (archiveWorktreeGate case final gate?) await gate.future;
    final index = _worktrees.indexWhere((item) => item.id == worktreeId);
    final archived = _worktrees[index].copyWith(archivedAt: _now);
    _worktrees.removeAt(index);
    return WorktreeResultDto(
      worktree: archived,
      hookRuns: archiveWorktreeHookRuns,
    );
  }

  @override
  Future<List<SessionDto>> listSessions({String? worktreeId}) async {
    if (listSessionsFailures > 0) {
      listSessionsFailures -= 1;
      throw Exception('transient listSessions failure');
    }
    return _agents
        .where((agent) => worktreeId == null || agent.worktreeId == worktreeId)
        .toList(growable: false);
  }

  @override
  Future<List<SessionDto>> listSubagents(String sessionId) async {
    final session = _agents.firstWhere(
      (agent) => agent.id == sessionId,
      orElse: () => throw StateError('Session not found: $sessionId'),
    );
    final rootId = session.rootSessionId ?? session.id;
    return _agents
        .where(
          (agent) => agent.id == rootId || agent.rootSessionId == rootId,
        )
        .toList(growable: false)
      ..sort(
        (left, right) =>
            (left.agentPath ?? '').compareTo(right.agentPath ?? ''),
      );
  }

  @override
  Future<SessionDto> createSession({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
    Map<String, ModelControlValueDto> modelControls =
        const <String, ModelControlValueDto>{},
    PermissionMode? permissionMode,
  }) async {
    final agent = SessionDto(
      id: id,
      worktreeId: worktreeId,
      title: title,
      agentDefinitionId: agentDefinitionId,
      origin: SessionOrigin.manual,
      status: SessionStatus.idle,
      mode: mode,
      model: model,
      modelControls: modelControls,
      permissionMode: permissionMode,
      createdAt: _now,
      updatedAt: _now,
    );
    _agents.add(agent);
    createdSessions.add(agent);
    return agent;
  }

  @override
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  ) async {
    await _beforeSessionUpdate();
    final index = _agents.indexWhere((agent) => agent.id == sessionId);
    if (index < 0) throw StateError('Session not found: $sessionId');
    var updated = _agents[index];
    if (patch.mode case final mode?) {
      updatedSessionModes.add((sessionId: sessionId, mode: mode));
      updated = updated.copyWith(mode: mode);
    }
    if (patch.hasModel) {
      updatedSessionModels.add((sessionId: sessionId, model: patch.model));
      updated = updated.copyWith(model: patch.model);
    }
    if (patch.hasModelControls) {
      final controls = patch.modelControls;
      final effort = controls['reasoning_effort']?.map(
        stringValue: (value) => value.value,
        boolValue: (_) => null,
        intValue: (_) => null,
      );
      updatedSessionReasoningEfforts.add((
        sessionId: sessionId,
        reasoningEffort: effort,
      ));
      final fast = controls['fast_mode']?.map(
        stringValue: (_) => false,
        boolValue: (value) => value.value,
        intValue: (_) => false,
      );
      updatedSessionServiceTiers.add((
        sessionId: sessionId,
        serviceTier: fast == true ? 'priority' : null,
      ));
      updated = updated.copyWith(modelControls: controls);
    }
    if (patch.hasPermissionMode) {
      if (sessionPermissionSetError case final error?) throw error;
      updatedSessionPermissionModes.add((
        sessionId: sessionId,
        permissionMode: patch.permissionMode,
      ));
      updated = updated.copyWith(permissionMode: patch.permissionMode);
    }
    _agents[index] = updated;
    emit(SessionUpdatedClientEvent(updated));
    return updated;
  }

  @override
  Future<PermissionSettingsDto> getDefaultPermissionMode() async =>
      PermissionSettingsDto(defaultMode: _defaultPermissionMode);

  @override
  Future<PermissionSettingsDto> setDefaultPermissionMode(
    PermissionMode permissionMode,
  ) async {
    if (defaultPermissionSetError case final error?) throw error;
    _defaultPermissionMode = permissionMode;
    return PermissionSettingsDto(defaultMode: permissionMode);
  }

  @override
  Future<List<TerminalDto>> listTerminals(String worktreeId) async =>
      _terminals.where((item) => item.worktreeId == worktreeId).toList();

  @override
  Future<TerminalDto> createTerminal({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  }) async {
    final terminal = TerminalDto(
      id: id,
      worktreeId: worktreeId,
      title: title,
      shell: const ShellSpecDto(executable: '/bin/sh'),
      status: TerminalStatus.running,
      columns: columns,
      rows: rows,
      lastSequence: 0,
    );
    _terminals.add(terminal);
    emit(TerminalUpdatedClientEvent(terminal));
    return terminal;
  }

  @override
  Future<TerminalAttachResultDto> attachTerminal(
    String terminalId, {
    int afterSequence = 0,
  }) async {
    final error = terminalAttachError;
    if (error != null) throw error;
    attachedTerminalIds.add(terminalId);
    return TerminalAttachResultDto(
      terminal: _terminals.firstWhere((item) => item.id == terminalId),
      replay: terminalReplay,
    );
  }

  /// Terminals attached to, in order, including repeat attachments.
  final List<String> attachedTerminalIds = <String>[];

  /// Terminal input received by the fake.
  final List<({String terminalId, String data})> terminalWrites =
      <({String terminalId, String data})>[];

  @override
  Future<void> writeTerminal(String terminalId, String data) async {
    terminalWrites.add((terminalId: terminalId, data: data));
  }

  @override
  Future<TerminalDto> resizeTerminal(
    String terminalId, {
    required int columns,
    required int rows,
  }) async {
    final index = _terminals.indexWhere((item) => item.id == terminalId);
    final terminal = _terminals[index].copyWith(columns: columns, rows: rows);
    _terminals[index] = terminal;
    return terminal;
  }

  @override
  Future<void> terminateTerminal(String terminalId) async {
    final index = _terminals.indexWhere((item) => item.id == terminalId);
    final terminal = _terminals[index].copyWith(
      status: TerminalStatus.exited,
      exitCode: 0,
    );
    _terminals[index] = terminal;
    emit(TerminalUpdatedClientEvent(terminal));
  }

  @override
  Future<ShellSpecDto?> getTerminalShell() async => _terminalShell;

  @override
  Future<void> setTerminalShell(ShellSpecDto? shell) async {
    _terminalShell = shell;
  }

  @override
  Future<List<AgentDefinitionDto>> listAgentDefinitions() async {
    await agentDefinitionsGate;
    final error = agentListError;
    if (error != null) throw error;
    return List<AgentDefinitionDto>.unmodifiable(_agentDefinitions);
  }

  @override
  Future<AgentDefinitionDto> getAgentDefinition(String id) async =>
      _agentDefinitions.singleWhere((definition) => definition.id == id);

  @override
  Future<AgentDefinitionDto> createAgentDefinition(
    String id,
    AgentDefinitionDto definition,
  ) async {
    if (failNextAgentCreate) {
      failNextAgentCreate = false;
      throw Exception('agent_create_failed');
    }
    if (_agentDefinitions.any((item) => item.id == id)) {
      throw StateError('Agent definition already exists: $id');
    }
    final created = definition.copyWith(
      id: id,
      contentHash: '$id-hash',
      sourcePath: '/config/agents/$id.md',
    );
    _agentDefinitions.add(created);
    return created;
  }

  @override
  Future<AgentDefinitionDto> updateAgentDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    if (failNextAgentUpdate && !force) {
      failNextAgentUpdate = false;
      throw Exception('agent_file_conflict');
    }
    final index = _agentDefinitions.indexWhere(
      (item) => item.id == definition.id,
    );
    if (!force && _agentDefinitions[index].contentHash != expectedContentHash) {
      throw StateError('agent_file_conflict');
    }
    final updated = definition.copyWith(
      contentHash: '${definition.id}-updated-hash',
    );
    _agentDefinitions[index] = updated;
    return updated;
  }

  @override
  Future<void> archiveAgentDefinition(String id) async {
    _agentDefinitions.removeWhere((definition) => definition.id == id);
  }

  @override
  Future<AgentDefinitionDto> resetAgentDefinition(String id) async {
    if (id != 'coder') throw StateError('Only coder can be reset.');
    final index = _agentDefinitions.indexWhere(
      (definition) => definition.id == id,
    );
    _agentDefinitions[index] = _coder;
    return _coder;
  }

  @override
  Future<AgentDefinitionDto> validateAgentDefinition(
    String id,
    String markdown,
  ) async => _coder.copyWith(id: id, systemPrompt: markdown);

  @override
  Future<List<AgentToolDefinitionDto>> listAgentTools({
    String? worktreeId,
  }) async => const <AgentToolDefinitionDto>[
    AgentToolDefinitionDto(
      id: 'read_file',
      name: 'read_file',
      description: 'Read a file.',
      risk: ToolRisk.read,
      alwaysOn: true,
    ),
    AgentToolDefinitionDto(
      id: 'exec_command',
      name: 'exec_command',
      description: 'Run a command in a pseudo-terminal.',
      risk: ToolRisk.command,
    ),
  ];

  /// MCP servers this fake daemon reports, keyed by id.
  final Map<String, McpServerStateDto> mcpServers =
      <String, McpServerStateDto>{};

  /// Ordered MCP list responses used to reproduce out-of-order reloads.
  final List<Future<List<McpServerStateDto>>> mcpListResponses;

  /// Secrets stored through [setMcpSecret].
  final Map<String, String> mcpSecrets = <String, String>{};

  @override
  Future<List<McpServerStateDto>> listMcpServers({String? worktreeId}) async {
    if (mcpListResponses.isNotEmpty) {
      return mcpListResponses.removeAt(0);
    }
    return mcpServers.values.toList(growable: false);
  }

  @override
  Future<McpServerStateDto> addMcpServer(McpServerConfigDto server) async =>
      mcpServers[server.id] = _readyState(server);

  @override
  Future<McpServerStateDto> updateMcpServer(McpServerConfigDto server) async =>
      mcpServers[server.id] = _readyState(server);

  @override
  Future<void> removeMcpServer(String id) async => mcpServers.remove(id);

  @override
  Future<McpServerStateDto> testMcpServer(McpServerConfigDto server) async =>
      _readyState(server);

  @override
  Future<void> setMcpSecret(String key, String value) async =>
      mcpSecrets[key] = value;

  McpServerStateDto _readyState(McpServerConfigDto server) => McpServerStateDto(
    config: server,
    status: server.enabled ? McpServerStatus.ready : McpServerStatus.disabled,
    scope: McpConfigScope.user,
    sourcePath: '/config/mcp.json',
    serverName: server.id,
    protocolVersion: '2025-06-18',
    tools: <McpToolSummaryDto>[
      McpToolSummaryDto(
        toolId: 'mcp__${server.id}__echo',
        name: 'echo',
        description: 'Echoes its argument.',
      ),
    ],
  );

  List<SkillDto> _skillsFor(String? workspaceId) =>
      workspaceId == null ? _skills : <SkillDto>[..._skills, ..._projectSkills];

  List<SkillDto> _skillStoreFor(SkillSource source) =>
      source == SkillSource.project ? _projectSkills : _skills;

  @override
  Future<FileSearchResultDto> searchFiles({
    required String worktreeId,
    required String query,
    int limit = 50,
  }) async {
    searchedQueries.add(query);
    await searchFilesGate;
    final failure = searchFilesError;
    if (failure != null) throw failure;
    final paths = files[worktreeId] ?? const <String>[];
    // Mirrors the daemon's coarse filter: a subsequence over the whole path.
    final matched = paths
        .where(
          (path) => _isSubsequence(path.toLowerCase(), query.toLowerCase()),
        )
        .take(limit)
        .map(
          (path) => FileMatchDto(
            relativePath: path,
            absolutePath: '/worktree/$path',
            name: path.split('/').last,
            isDirectory: false,
          ),
        )
        .toList(growable: false);
    return FileSearchResultDto(matches: matched);
  }

  static bool _isSubsequence(String candidate, String query) {
    var cursor = 0;
    for (
      var index = 0;
      index < candidate.length && cursor < query.length;
      index += 1
    ) {
      if (candidate.codeUnitAt(index) == query.codeUnitAt(cursor)) cursor += 1;
    }
    return cursor == query.length;
  }

  @override
  Future<List<AgentCommandDto>> listCommands({String? workspaceId}) async =>
      List<AgentCommandDto>.unmodifiable(commands);

  @override
  Future<List<SkillDto>> listSkills({String? workspaceId}) async {
    final error = skillListError;
    if (error != null) throw error;
    return List<SkillDto>.unmodifiable(_skillsFor(workspaceId));
  }

  @override
  Future<SkillDto> getSkill(String id, {String? workspaceId}) async =>
      _skillsFor(workspaceId).singleWhere((skill) => skill.id == id);

  @override
  Future<SkillDto> createSkill({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    String? workspaceId,
  }) async {
    if (_skillsFor(workspaceId).any((skill) => skill.id == id)) {
      throw StateError('Skill already exists: $id');
    }
    final created = SkillDto(
      id: id,
      name: name,
      description: description,
      source: source,
      sourcePath: '/config/skills/$id/SKILL.md',
      contentHash: '$id-hash',
      body: body,
      isEditable: true,
    );
    _skillStoreFor(source).add(created);
    return created;
  }

  @override
  Future<SkillDto> updateSkill(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    String? workspaceId,
  }) async {
    if (failNextSkillUpdate && !force) {
      failNextSkillUpdate = false;
      throw Exception('skill_file_conflict');
    }
    final store = _skillStoreFor(skill.source);
    final index = store.indexWhere((item) => item.id == skill.id);
    if (index < 0) throw StateError('Skill not found: ${skill.id}');
    if (!force && store[index].contentHash != expectedContentHash) {
      throw StateError('skill_file_conflict');
    }
    final updated = skill.copyWith(contentHash: '${skill.id}-updated-hash');
    store[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSkill(String id, {String? workspaceId}) async {
    _skills.removeWhere((skill) => skill.id == id && skill.isEditable);
    _projectSkills.removeWhere((skill) => skill.id == id);
  }

  @override
  Future<SkillDto> setSkillEnabled(
    String id, {
    required bool enabled,
    String? workspaceId,
  }) async {
    for (final store in <List<SkillDto>>[_skills, _projectSkills]) {
      final index = store.indexWhere((skill) => skill.id == id);
      if (index < 0) continue;
      if (store[index].isMandatory) {
        throw StateError('Skill is always enabled: $id');
      }
      final updated = store[index].copyWith(isEnabled: enabled);
      store[index] = updated;
      return updated;
    }
    throw StateError('Skill not found: $id');
  }

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async => _catalog;

  @override
  Future<List<ProviderConnectionDto>> listProviderConnections() async =>
      List<ProviderConnectionDto>.unmodifiable(_connections);

  @override
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey,
  ) async {
    credentials[definitionId] = apiKey;
    final definition = _catalog.definitions.singleWhere(
      (item) => item.id == definitionId,
    );
    return _saveConnection(
      ProviderConnectionDto(
        id: definitionId,
        definitionId: definitionId,
        displayName: definition.name,
        status: ProviderConnectionStatus.connected,
        authKind: ProviderAuthKind.apiKey,
        credentialOrigin: ProviderCredentialOrigin.stored,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  }

  @override
  Future<ProviderConnectionDto> connectProviderNone(String definitionId) async {
    final definition = _catalog.definitions.singleWhere(
      (item) => item.id == definitionId,
    );
    return _saveConnection(
      ProviderConnectionDto(
        id: definitionId,
        definitionId: definitionId,
        displayName: definition.name,
        status: ProviderConnectionStatus.connected,
        authKind: ProviderAuthKind.none,
        credentialOrigin: ProviderCredentialOrigin.none,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  }

  @override
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId,
  ) async => ProviderAuthAttemptDto(
    id: 'attempt',
    definitionId: definitionId,
    methodId: methodId,
    status: ProviderAuthAttemptStatus.awaitingUser,
    authorizationUrl: 'https://auth.example/authorize',
    userCode: methodId.contains('device') ? 'CODE-1234' : null,
  );

  @override
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId) async =>
      const ProviderAuthAttemptDto(
        id: 'attempt',
        definitionId: 'openai',
        methodId: 'chatgpt-browser',
        status: ProviderAuthAttemptStatus.awaitingUser,
      );

  @override
  Future<void> cancelProviderAuth(String attemptId) async {
    cancelledAuthAttempts.add(attemptId);
  }

  @override
  Future<void> disconnectProvider(String connectionId) async {
    credentials.remove(connectionId);
    final current = _connections.singleWhere((item) => item.id == connectionId);
    _saveConnection(
      current.copyWith(
        status: ProviderConnectionStatus.disconnected,
        credentialOrigin: ProviderCredentialOrigin.none,
      ),
    );
  }

  @override
  Future<ProviderCatalogDto> refreshProviderCatalog() async {
    final error = catalogRefreshError;
    catalogRefreshError = null;
    if (error != null) throw error;
    return _catalog = _catalog.copyWith(
      source: ProviderCatalogSource.refreshed,
    );
  }

  @override
  Future<List<ProviderModelDto>> listProviderModels(
    String connectionId,
  ) async {
    final gate = modelListGate;
    if (gate != null) await gate;
    return List<ProviderModelDto>.unmodifiable(
      _models[connectionId] ?? const <ProviderModelDto>[],
    );
  }

  @override
  Future<SessionModelSelectionDto?> getDefaultModel() async => _defaultModel;

  @override
  Future<void> setDefaultModel(SessionModelSelectionDto? model) async {
    _defaultModel = model;
  }

  @override
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    if (apiKey != null) credentials[id] = apiKey;
    for (final manualModel in config.models) {
      _models
          .putIfAbsent(id, () => <ProviderModelDto>[])
          .add(
            ProviderModelDto(
              connectionId: id,
              id: manualModel.id,
              label: manualModel.label,
              source: ProviderModelSource.manual,
              capabilities: const ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
                source: CapabilitySource.manual,
              ),
            ),
          );
    }
    return _saveConnection(
      ProviderConnectionDto(
        id: id,
        definitionId: 'custom',
        displayName: config.name,
        status: ProviderConnectionStatus.connected,
        authKind: config.authenticationRequired
            ? ProviderAuthKind.apiKey
            : ProviderAuthKind.none,
        credentialOrigin: apiKey == null
            ? ProviderCredentialOrigin.none
            : ProviderCredentialOrigin.stored,
        customConfig: config,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  }

  @override
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    if (apiKey != null) credentials[connectionId] = apiKey;
    for (final manualModel in config.models) {
      final models = _models.putIfAbsent(
        connectionId,
        () => <ProviderModelDto>[],
      );
      if (models.any((model) => model.id == manualModel.id)) continue;
      models.add(
        ProviderModelDto(
          connectionId: connectionId,
          id: manualModel.id,
          label: manualModel.label,
          source: ProviderModelSource.manual,
          capabilities: const ModelCapabilitiesDto(
            streaming: CapabilitySupport.supported,
            toolCalling: CapabilitySupport.supported,
            source: CapabilitySource.manual,
          ),
        ),
      );
    }
    final current = _connections.singleWhere(
      (item) => item.id == connectionId,
    );
    return _saveConnection(
      current.copyWith(
        displayName: config.name,
        customConfig: config,
      ),
    );
  }

  @override
  Future<void> deleteCustomProvider(String connectionId) async {
    _connections.removeWhere((item) => item.id == connectionId);
    _models.remove(connectionId);
    credentials.remove(connectionId);
  }

  ProviderConnectionDto _saveConnection(ProviderConnectionDto connection) {
    _connections
      ..removeWhere((item) => item.id == connection.id)
      ..add(connection);
    return connection;
  }

  @override
  Future<void> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
  }) async {
    attemptedPrompts.add(prompt);
    final gate = startTurnGate;
    if (gate != null) await gate.future;
    if (startTurnFailures > 0) {
      startTurnFailures -= 1;
      throw Exception('transient send failure');
    }
    final error = startTurnError;
    if (error != null) throw error;
    startedPrompts.add(prompt);
    startedTurnIds.add(turnId);
    startedAttachmentIds.add(List<String>.of(attachmentIds));
  }

  @override
  Future<AttachmentDto> uploadAttachment({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> bytes,
  }) async {
    final builder = BytesBuilder(copy: false);
    await bytes.forEach(builder.add);
    final payload = builder.takeBytes();
    if (payload.length != byteSize) {
      throw const FormatException('Attachment size mismatch.');
    }
    final id = 'attachment-${_attachments.length + 1}';
    final metadata = AttachmentDto(
      id: id,
      fileName: fileName,
      mimeType: mimeType,
      byteSize: byteSize,
      kind: mimeType.startsWith('image/')
          ? AttachmentKind.image
          : AttachmentKind.file,
      sha256: 'fake-sha256-$id',
      createdAt: _now,
    );
    _attachments[id] = (metadata: metadata, bytes: payload);
    return metadata;
  }

  @override
  Future<AttachmentDownload> downloadAttachment(String id) async {
    final attachment = _attachments[id];
    if (attachment == null) throw StateError('Attachment not found: $id');
    return AttachmentDownload(
      fileName: attachment.metadata.fileName,
      mimeType: attachment.metadata.mimeType,
      byteSize: attachment.metadata.byteSize,
      bytes: Stream<List<int>>.value(attachment.bytes),
    );
  }

  @override
  Future<void> cancelTurn(String sessionId) async {
    cancelledAgents.add(sessionId);
  }

  @override
  Future<void> compactSession(String sessionId) async {
    compactedSessions.add(sessionId);
  }

  @override
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) async {
    approvalDecisions.add((id: approvalId, approved: approved));
  }

  /// Sessions the app told the daemon had queued input, in order.
  final List<String> notedPendingInput = <String>[];

  @override
  Future<void> notePendingInput(String sessionId) async {
    notedPendingInput.add(sessionId);
    final error = notePendingInputError;
    if (error != null) throw error;
  }

  @override
  Future<UserQuestionRequestDto> answerUserQuestion({
    required String requestId,
    required List<UserQuestionAnswerDto> answers,
  }) async {
    questionAnswers.add((id: requestId, answers: answers));
    return UserQuestionRequestDto(
      id: requestId,
      sessionId: 'session',
      turnId: 'turn',
      toolCallId: 'ask-call',
      questions: const <UserQuestionItemDto>[],
      status: UserQuestionStatus.answered,
      createdAt: DateTime.utc(2026, 8, 3),
      answers: answers,
    );
  }

  @override
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  }) async => (_timelines[sessionId] ?? const <TimelineEventDto>[])
      .where((event) => event.sequence > afterSequence)
      .toList(growable: false);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _events.close();
    await _states.close();
    await _catalogUpdates.close();
  }
}

/// Creates app services with one deterministic remote daemon profile.
AppServices fakeAppServices(
  FakeCoderApi api, {
  bool connected = true,
  String hostId = 'server',
  MemoryAppStore? store,
}) {
  final now = DateTime.utc(2026, 8, 2);
  final profiles = <RemoteDaemonProfile>[
    RemoteDaemonProfile(
      id: hostId,
      label: 'Test daemon',
      websocketUri: Uri.parse('ws://127.0.0.1:7337/ws'),
      autoConnect: connected,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  final tokens = <String, String>{hostId: 'test-token'};
  final effectiveStore =
      store ??
      MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: profiles,
        tokens: tokens,
      );
  if (store != null) {
    // Keep caller-provided settings such as a collapsed sidebar.
    store
      ..settings = store.settings.copyWith(embeddedDaemonEnabled: false)
      ..profiles.addAll(profiles)
      ..tokens.addAll(tokens);
  }
  return AppServices(
    settings: effectiveStore,
    profiles: effectiveStore,
    credentials: effectiveStore,
    clients: _FakeHostClientFactory(api),
    clientKind: 'test',
  );
}

final class _FakeHostClientFactory implements HostClientFactory {
  const _FakeHostClientFactory(this.api);

  final CoderApi api;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) async => api;
}
