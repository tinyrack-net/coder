import 'dart:async';

import 'package:coder_app/src/bootstrap.dart';
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
    List<AgentDto>? agents,
    Map<String, List<TimelineEventDto>>? timelines,
    Map<String, List<ProviderModelDto>>? models,
  }) : _serverInfo = serverInfo ?? _defaultServerInfo,
       _catalog = catalog ?? _defaultCatalog,
       _connections = connections ?? <ProviderConnectionDto>[_openAIConnection],
       _workspaces = workspaces ?? <WorkspaceDto>[],
       _agents = agents ?? <AgentDto>[],
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
    features: <String, bool>{'providerAdmin': true},
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

  final ServerInfoDto _serverInfo;
  ProviderCatalogDto _catalog;
  final List<ProviderConnectionDto> _connections;
  final List<WorkspaceDto> _workspaces;
  final List<AgentDto> _agents;
  final Map<String, List<TimelineEventDto>> _timelines;
  final Map<String, List<ProviderModelDto>> _models;
  final StreamController<ClientEvent> _events =
      StreamController<ClientEvent>.broadcast(sync: true);
  final StreamController<ClientConnectionState> _states =
      StreamController<ClientConnectionState>.broadcast(sync: true);
  bool _closed = false;

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
  Stream<ClientEvent> get events => _events.stream;

  @override
  Stream<ClientConnectionState> get states => _states.stream;

  @override
  ServerInfoDto get serverInfo => _serverInfo;

  @override
  Future<List<WorkspaceDto>> listWorkspaces() async =>
      List<WorkspaceDto>.unmodifiable(_workspaces);

  @override
  Future<WorkspaceDto> registerWorkspace({
    required String id,
    required String rootPath,
    required String name,
  }) async {
    final workspace = WorkspaceDto(
      id: id,
      name: name,
      rootPath: rootPath,
      createdAt: _now,
    );
    _workspaces.add(workspace);
    return workspace;
  }

  @override
  Future<List<AgentDto>> listAgents({String? workspaceId}) async => _agents
      .where((agent) => workspaceId == null || agent.workspaceId == workspaceId)
      .toList(growable: false);

  @override
  Future<AgentDto> createAgent({
    required String id,
    required String workspaceId,
    required String title,
    required String providerConnectionId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  }) async {
    final agent = AgentDto(
      id: id,
      workspaceId: workspaceId,
      title: title,
      providerConnectionId: providerConnectionId,
      model: model,
      reasoningEffort: reasoningEffort,
      status: AgentStatus.idle,
      permissionMode: permissionMode,
      createdAt: _now,
      updatedAt: _now,
    );
    _agents.add(agent);
    return agent;
  }

  @override
  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerConnectionId,
    required String model,
    String reasoningEffort = 'medium',
  }) async {
    final index = _agents.indexWhere((agent) => agent.id == agentId);
    final updated = _agents[index].copyWith(
      providerConnectionId: providerConnectionId,
      model: model,
      reasoningEffort: reasoningEffort,
    );
    _agents[index] = updated;
    return updated;
  }

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
  ) async => List<ProviderModelDto>.unmodifiable(
    _models[connectionId] ?? const <ProviderModelDto>[],
  );

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
    required String agentId,
    required String turnId,
    required String prompt,
  }) async {
    startedPrompts.add(prompt);
    startedTurnIds.add(turnId);
  }

  @override
  Future<void> cancelTurn(String agentId) async {
    cancelledAgents.add(agentId);
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
    String agentId, {
    int afterSequence = 0,
  }) async => (_timelines[agentId] ?? const <TimelineEventDto>[])
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

/// An [AppBootstrap] that always returns an in-memory API connection.
final class FakeAppBootstrap implements AppBootstrap {
  /// Creates a [FakeAppBootstrap].
  FakeAppBootstrap({
    required this.api,
    this.canRegisterLocalWorkspace = true,
    this.autoConnectEnabled = true,
    this.connectFailures = 0,
  });

  /// The API returned by [autoConnect] and [connectRemote].
  final FakeCoderApi api;

  @override
  final bool canRegisterLocalWorkspace;

  /// Whether [autoConnect] returns the fake API connection.
  final bool autoConnectEnabled;

  /// Number of explicit remote connections that fail before succeeding.
  int connectFailures;

  @override
  Future<BootstrapConnection?> autoConnect() async => autoConnectEnabled
      ? BootstrapConnection(
          client: api,
          endpoint: HostEndpoint.parse(
            'ws://127.0.0.1:7337/ws',
            token: 'test-token',
          ),
        )
      : null;

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) async {
    if (connectFailures > 0) {
      connectFailures -= 1;
      throw const FormatException('Invalid test endpoint.');
    }
    return BootstrapConnection(client: api, endpoint: endpoint);
  }

  @override
  Future<void> close() async {}
}
