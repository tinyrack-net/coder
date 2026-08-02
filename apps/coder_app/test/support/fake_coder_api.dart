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
    List<WorkspaceDto>? workspaces,
    List<AgentDto>? agents,
    Map<String, List<TimelineEventDto>>? timelines,
    Map<String, List<ProviderModelDto>>? models,
  }) : _serverInfo =
           serverInfo ??
           const ServerInfoDto(
             serverId: 'server',
             version: 'test',
             protocolVersion: coderProtocolVersion,
             features: <String, bool>{'providerAdmin': true},
           ),
       _catalog = catalog ?? _defaultCatalog,
       _workspaces = workspaces ?? <WorkspaceDto>[],
       _agents = agents ?? <AgentDto>[],
       _timelines = <String, List<TimelineEventDto>>{
         for (final entry
             in (timelines ?? <String, List<TimelineEventDto>>{}).entries)
           entry.key: List<TimelineEventDto>.of(entry.value),
       },
       _models = <String, List<ProviderModelDto>>{
         for (final entry
             in (models ?? <String, List<ProviderModelDto>>{}).entries)
           entry.key: List<ProviderModelDto>.of(entry.value),
       };

  static final DateTime _now = DateTime.utc(2026);
  static final ProviderCatalogDto _defaultCatalog = ProviderCatalogDto(
    defaultProviderId: 'openai',
    presets: const <ProviderPresetDto>[
      ProviderPresetDto(
        id: 'openai',
        name: 'OpenAI',
        defaultBaseUrl: 'https://api.openai.com/v1',
        defaultTransport: ApiTransport.responses,
        defaultCredentialSource: CredentialSource.environment,
        strictToolSchema: true,
        defaultModelId: 'gpt-5.6-sol',
        modelIds: <String>['gpt-5.6-sol'],
      ),
    ],
    providers: <ApiProviderDto>[
      ApiProviderDto(
        id: 'openai',
        name: 'OpenAI',
        presetId: 'openai',
        baseUrl: 'https://api.openai.com/v1',
        transport: ApiTransport.responses,
        credentialSource: CredentialSource.environment,
        credentialConfigured: false,
        environmentVariable: 'OPENAI_API_KEY',
        enabled: true,
        strictToolSchema: true,
        defaultModelId: 'gpt-5.6-sol',
        createdAt: _now,
        updatedAt: _now,
      ),
    ],
  );

  final ServerInfoDto _serverInfo;
  ProviderCatalogDto _catalog;
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
    required String providerId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  }) async {
    final agent = AgentDto(
      id: id,
      workspaceId: workspaceId,
      title: title,
      providerId: providerId,
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
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
  }) async {
    final index = _agents.indexWhere((agent) => agent.id == agentId);
    final updated = _agents[index].copyWith(
      providerId: providerId,
      model: model,
      reasoningEffort: reasoningEffort,
    );
    _agents[index] = updated;
    return updated;
  }

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async => _catalog;

  @override
  Future<ApiProviderDto> upsertProvider(
    ApiProviderDto provider, {
    bool makeDefault = false,
  }) async {
    _catalog = _catalog.copyWith(
      providers: <ApiProviderDto>[
        for (final current in _catalog.providers)
          if (current.id != provider.id) current,
        provider,
      ],
      defaultProviderId: makeDefault ? provider.id : _catalog.defaultProviderId,
    );
    return provider;
  }

  @override
  Future<void> deleteProvider(String providerId) async {
    _catalog = _catalog.copyWith(
      providers: _catalog.providers
          .where((provider) => provider.id != providerId)
          .toList(growable: false),
    );
  }

  @override
  Future<List<ProviderModelDto>> listProviderModels(String providerId) async =>
      List<ProviderModelDto>.unmodifiable(
        _models[providerId] ?? const <ProviderModelDto>[],
      );

  @override
  Future<List<ProviderModelDto>> refreshProviderModels(String providerId) =>
      listProviderModels(providerId);

  @override
  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model) async {
    _models.putIfAbsent(model.providerId, () => <ProviderModelDto>[])
      ..removeWhere((current) => current.id == model.id)
      ..add(model);
    return model;
  }

  @override
  Future<void> deleteProviderModel(String providerId, String modelId) async {
    _models[providerId]?.removeWhere((model) => model.id == modelId);
  }

  @override
  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  ) async => ProviderDiagnosticDto(
    providerId: providerId,
    model: modelId,
    status: DiagnosticStatus.verified,
    endpointReachable: true,
    streaming: true,
    toolCalling: true,
    checkedAt: _now,
  );

  @override
  Future<void> setProviderCredential(String providerId, String apiKey) async {
    credentials[providerId] = apiKey;
  }

  @override
  Future<void> clearProviderCredential(String providerId) async {
    credentials.remove(providerId);
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
