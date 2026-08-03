import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// An in-memory [CoderApi] used by notifier and widget tests.
final class FakeCoderApi implements CoderApi {
  /// Creates a configurable [FakeCoderApi].
  FakeCoderApi({
    ServerInfoDto? serverInfo,
    ProviderCatalogDto? catalog,
    List<ProviderConnectionDto>? connections,
    List<WorkspaceDto>? workspaces,
    List<WorktreeDto>? worktrees,
    List<SessionDto>? agents,
    List<AgentDefinitionDto>? agentDefinitions,
    Map<String, List<TimelineEventDto>>? timelines,
    Map<String, List<ProviderModelDto>>? models,
    this.eventStream,
    this.agentListError,
    this.failNextAgentCreate = false,
    this.failNextAgentUpdate = false,
    this.defaultModelSetGate,
    this.defaultModelSetError,
    this.modelListGate,
  }) : _serverInfo = serverInfo ?? _defaultServerInfo,
       _catalog = catalog ?? _defaultCatalog,
       _connections = connections ?? <ProviderConnectionDto>[_openAIConnection],
       _workspaces = workspaces ?? <WorkspaceDto>[],
       _worktrees = worktrees ?? <WorktreeDto>[],
       _agents = agents ?? <SessionDto>[],
       _agentDefinitions = List<AgentDefinitionDto>.of(
         agentDefinitions ?? <AgentDefinitionDto>[_coder],
       ),
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
  static const ServerInfoDto _defaultServerInfo = ServerInfoDto(
    serverId: 'server',
    version: 'test',
    protocolVersion: coderProtocolVersion,
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
    isDefault: true,
    defaultModelId: 'gpt-5.6-sol',
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
      reasoningEffort: CapabilitySupport.supported,
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
      source: AgentModelSource.daemonDefault,
    ),
    reasoningEffort: 'medium',
    permissionMode: PermissionMode.ask,
    toolIds: <String>['read_file'],
    callableAgentIds: <String>[],
    contentHash: 'coder-hash',
    sourcePath: '/config/agents/coder.md',
    isBuiltIn: true,
  );

  final ServerInfoDto _serverInfo;
  ProviderCatalogDto _catalog;
  final List<ProviderConnectionDto> _connections;
  final List<WorkspaceDto> _workspaces;
  final List<WorktreeDto> _worktrees;
  final List<SessionDto> _agents;
  final List<AgentDefinitionDto> _agentDefinitions;
  final Map<String, List<TimelineEventDto>> _timelines;
  final Map<String, List<ProviderModelDto>> _models;

  /// Optional event stream that can model transport lifecycle races.
  final Stream<ClientEvent>? eventStream;

  /// Optional failure returned while loading Markdown agent definitions.
  final Exception? agentListError;

  /// Whether the next guarded Markdown save should simulate a file race.
  bool failNextAgentUpdate;

  /// Whether the next Markdown create should simulate a daemon failure.
  bool failNextAgentCreate;

  /// Optional gate used to observe the model-saving state.
  final Future<void>? defaultModelSetGate;

  /// Optional daemon error returned while selecting a default model.
  final Exception? defaultModelSetError;

  /// Optional gate used to keep model discovery in its loading state.
  final Future<void>? modelListGate;
  final StreamController<ClientEvent> _events =
      StreamController<ClientEvent>.broadcast(sync: true);
  final StreamController<ClientConnectionState> _states =
      StreamController<ClientConnectionState>.broadcast(sync: true);
  bool _closed = false;

  /// Whether [close] released this fake client.
  bool get isClosed => _closed;

  /// Sessions created through the fake, in creation order.
  final List<SessionDto> createdSessions = <SessionDto>[];

  /// Session model overrides written through the fake.
  final List<({String sessionId, SessionModelSelectionDto? model})>
  updatedSessionModels =
      <({String sessionId, SessionModelSelectionDto? model})>[];

  /// Turn prompts received by the fake.
  final List<String> startedPrompts = <String>[];

  /// Turn identifiers received by the fake.
  final List<String> startedTurnIds = <String>[];

  /// Agent identifiers cancelled through the fake.
  final List<String> cancelledAgents = <String>[];

  /// Provider credentials written through the fake.
  final Map<String, String> credentials = <String, String>{};

  /// OAuth attempts cancelled through the fake.
  final List<String> cancelledAuthAttempts = <String>[];

  /// Approval decisions received by the fake.
  final List<({String id, bool approved})> approvalDecisions =
      <({String id, bool approved})>[];

  /// Emits a typed daemon notification.
  void emit(ClientEvent event) => _events.add(event);

  /// Emits a transport connection state.
  void emitState(ClientConnectionState state) => _states.add(state);

  @override
  Stream<ClientEvent> get events => eventStream ?? _events.stream;

  @override
  Stream<ClientConnectionState> get states => _states.stream;

  @override
  ServerInfoDto get serverInfo => _serverInfo;

  @override
  Future<WorkspaceCatalogDto> getWorkspaceCatalog() async =>
      WorkspaceCatalogDto(
        workspaces: List<WorkspaceDto>.unmodifiable(_workspaces),
        worktrees: List<WorktreeDto>.unmodifiable(_worktrees),
      );

  @override
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  }) async {
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
  }) async => <DirectorySuggestionDto>[
    DirectorySuggestionDto(path: query, name: query.split('/').last),
  ];

  @override
  Future<List<GitBranchDto>> listGitBranches(String workspaceId) async =>
      const <GitBranchDto>[
        GitBranchDto(name: 'main', current: true, checkedOut: true),
      ];

  @override
  Future<WorktreeDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  }) async {
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
    return worktree;
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
  Future<WorktreeDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  }) async {
    final index = _worktrees.indexWhere((item) => item.id == worktreeId);
    final archived = _worktrees[index].copyWith(archivedAt: _now);
    _worktrees.removeAt(index);
    return archived;
  }

  @override
  Future<List<SessionDto>> listSessions({String? worktreeId}) async => _agents
      .where((agent) => worktreeId == null || agent.worktreeId == worktreeId)
      .toList(growable: false);

  @override
  Future<SessionDto> createSession({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    SessionModelSelectionDto? model,
  }) async {
    final agent = SessionDto(
      id: id,
      worktreeId: worktreeId,
      title: title,
      agentDefinitionId: agentDefinitionId,
      origin: SessionOrigin.manual,
      status: SessionStatus.idle,
      model: model,
      createdAt: _now,
      updatedAt: _now,
    );
    _agents.add(agent);
    createdSessions.add(agent);
    return agent;
  }

  @override
  Future<SessionDto> updateSessionModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    updatedSessionModels.add((sessionId: sessionId, model: model));
    final index = _agents.indexWhere((agent) => agent.id == sessionId);
    if (index < 0) throw StateError('Session not found: $sessionId');
    final updated = _agents[index].copyWith(model: model);
    _agents[index] = updated;
    emit(SessionUpdatedClientEvent(updated));
    return updated;
  }

  @override
  Future<List<AgentDefinitionDto>> listAgentDefinitions() async {
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
  Future<List<AgentToolDefinitionDto>> listAgentTools() async =>
      const <AgentToolDefinitionDto>[
        AgentToolDefinitionDto(
          id: 'read_file',
          name: 'read_file',
          description: 'Read a file.',
          risk: ToolRisk.read,
        ),
      ];

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async => _catalog;

  @override
  Future<List<ProviderConnectionDto>> listProviderConnections() async =>
      List<ProviderConnectionDto>.unmodifiable(_connections);

  @override
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey, {
    bool makeDefault = false,
  }) async {
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
        isDefault: makeDefault,
        defaultModelId: definition.recommendedModelIds.firstOrNull,
        createdAt: _now,
        updatedAt: _now,
      ),
      makeDefault: makeDefault,
    );
  }

  @override
  Future<ProviderConnectionDto> connectProviderNone(
    String definitionId, {
    bool makeDefault = false,
  }) async {
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
        isDefault: makeDefault,
        defaultModelId: definition.recommendedModelIds.firstOrNull,
        createdAt: _now,
        updatedAt: _now,
      ),
      makeDefault: makeDefault,
    );
  }

  @override
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId, {
    bool makeDefault = false,
  }) async => ProviderAuthAttemptDto(
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
        isDefault: false,
      ),
    );
  }

  @override
  Future<void> setDefaultProvider(String connectionId) async {
    for (var index = 0; index < _connections.length; index += 1) {
      _connections[index] = _connections[index].copyWith(
        isDefault: _connections[index].id == connectionId,
      );
    }
  }

  @override
  Future<void> setDefaultProviderModel(
    String connectionId,
    String modelId,
  ) async {
    final gate = defaultModelSetGate;
    if (gate != null) await gate;
    final error = defaultModelSetError;
    if (error != null) throw error;
    final connection = _connections.singleWhere(
      (item) => item.id == connectionId,
    );
    _saveConnection(connection.copyWith(defaultModelId: modelId));
  }

  @override
  Future<ProviderCatalogDto> refreshProviderCatalog() async =>
      _catalog = _catalog.copyWith(source: ProviderCatalogSource.refreshed);

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
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
    bool makeDefault = false,
  }) async {
    if (apiKey != null) credentials[id] = apiKey;
    for (final modelId in config.manualModelIds) {
      _models
          .putIfAbsent(id, () => <ProviderModelDto>[])
          .add(
            ProviderModelDto(
              connectionId: id,
              id: modelId,
              label: modelId,
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
        isDefault: makeDefault,
        defaultModelId: config.manualModelIds.firstOrNull,
        customConfig: config,
        createdAt: _now,
        updatedAt: _now,
      ),
      makeDefault: makeDefault,
    );
  }

  @override
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    if (apiKey != null) credentials[connectionId] = apiKey;
    for (final modelId in config.manualModelIds) {
      final models = _models.putIfAbsent(
        connectionId,
        () => <ProviderModelDto>[],
      );
      if (models.any((model) => model.id == modelId)) continue;
      models.add(
        ProviderModelDto(
          connectionId: connectionId,
          id: modelId,
          label: modelId,
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
        defaultModelId: config.manualModelIds.firstOrNull,
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

  ProviderConnectionDto _saveConnection(
    ProviderConnectionDto connection, {
    bool makeDefault = false,
  }) {
    if (makeDefault) {
      for (var index = 0; index < _connections.length; index += 1) {
        _connections[index] = _connections[index].copyWith(isDefault: false);
      }
    }
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
  }) async {
    startedPrompts.add(prompt);
    startedTurnIds.add(turnId);
  }

  @override
  Future<void> cancelTurn(String sessionId) async {
    cancelledAgents.add(sessionId);
  }

  @override
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) async {
    approvalDecisions.add((id: approvalId, approved: approved));
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
  }
}

/// Creates app services with one deterministic remote daemon profile.
AppServices fakeAppServices(
  FakeCoderApi api, {
  bool connected = true,
  String hostId = 'server',
}) {
  final now = DateTime.utc(2026, 8, 2);
  final store = MemoryAppStore(
    settings: const AppSettings(embeddedDaemonEnabled: false),
    profiles: <RemoteDaemonProfile>[
      RemoteDaemonProfile(
        id: hostId,
        label: 'Test daemon',
        websocketUri: Uri.parse('ws://127.0.0.1:7337/ws'),
        autoConnect: connected,
        createdAt: now,
        updatedAt: now,
      ),
    ],
    tokens: <String, String>{hostId: 'test-token'},
  );
  return AppServices(
    settings: store,
    profiles: store,
    credentials: store,
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
