import 'dart:async';

import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'bootstrap.dart';

final bootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw StateError('AppBootstrap must be overridden.'),
);

final coderControllerProvider = NotifierProvider<CoderController, CoderState>(
  CoderController.new,
);

class CoderState {
  const CoderState({
    this.connecting = false,
    this.connected = false,
    this.connectionLabel,
    this.serverInfo,
    this.workspaces = const <WorkspaceDto>[],
    this.agents = const <AgentDto>[],
    this.timeline = const <TimelineEventDto>[],
    this.approvals = const <String, ApprovalRequestDto>{},
    this.providerCatalog,
    this.providerModels = const <String, List<ProviderModelDto>>{},
    this.providerBusy = false,
    this.selectedWorkspaceId,
    this.selectedAgentId,
    this.error,
  });

  final bool connecting;
  final bool connected;
  final String? connectionLabel;
  final ServerInfoDto? serverInfo;
  final List<WorkspaceDto> workspaces;
  final List<AgentDto> agents;
  final List<TimelineEventDto> timeline;
  final Map<String, ApprovalRequestDto> approvals;
  final ProviderCatalogDto? providerCatalog;
  final Map<String, List<ProviderModelDto>> providerModels;
  final bool providerBusy;
  final String? selectedWorkspaceId;
  final String? selectedAgentId;
  final String? error;

  CoderState copyWith({
    bool? connecting,
    bool? connected,
    String? connectionLabel,
    ServerInfoDto? serverInfo,
    List<WorkspaceDto>? workspaces,
    List<AgentDto>? agents,
    List<TimelineEventDto>? timeline,
    Map<String, ApprovalRequestDto>? approvals,
    ProviderCatalogDto? providerCatalog,
    Map<String, List<ProviderModelDto>>? providerModels,
    bool? providerBusy,
    String? selectedWorkspaceId,
    String? selectedAgentId,
    String? error,
    bool clearError = false,
    bool clearWorkspace = false,
    bool clearAgent = false,
  }) => CoderState(
    connecting: connecting ?? this.connecting,
    connected: connected ?? this.connected,
    connectionLabel: connectionLabel ?? this.connectionLabel,
    serverInfo: serverInfo ?? this.serverInfo,
    workspaces: workspaces ?? this.workspaces,
    agents: agents ?? this.agents,
    timeline: timeline ?? this.timeline,
    approvals: approvals ?? this.approvals,
    providerCatalog: providerCatalog ?? this.providerCatalog,
    providerModels: providerModels ?? this.providerModels,
    providerBusy: providerBusy ?? this.providerBusy,
    selectedWorkspaceId: clearWorkspace
        ? null
        : selectedWorkspaceId ?? this.selectedWorkspaceId,
    selectedAgentId: clearAgent
        ? null
        : selectedAgentId ?? this.selectedAgentId,
    error: clearError ? null : error ?? this.error,
  );
}

class CoderController extends Notifier<CoderState> {
  CoderClient? _client;
  StreamSubscription<WireEnvelope>? _events;
  StreamSubscription<ClientConnectionState>? _connectionStates;
  bool _initialized = false;
  final Uuid _uuid = const Uuid();
  late AppBootstrap _bootstrapInstance;

  AppBootstrap get _bootstrap => _bootstrapInstance;
  bool get canRegisterLocalWorkspace => _bootstrap.canRegisterLocalWorkspace;
  bool get canManageProviders =>
      state.serverInfo?.features['providerAdmin'] == true;

  @override
  CoderState build() {
    _bootstrapInstance = ref.read(bootstrapProvider);
    ref.onDispose(() {
      unawaited(_dispose());
    });
    return const CoderState();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    state = state.copyWith(connecting: true, clearError: true);
    try {
      final connection = await _bootstrap.autoConnect();
      if (connection == null) {
        state = state.copyWith(connecting: false);
        return;
      }
      await _attach(connection);
    } catch (error) {
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: '$error',
      );
    }
  }

  Future<void> connect(String address, String token) async {
    state = state.copyWith(connecting: true, clearError: true);
    try {
      final endpoint = HostEndpoint.parse(address.trim(), token: token.trim());
      final connection = await _bootstrap.connectRemote(endpoint);
      await _attach(connection);
    } catch (error) {
      state = state.copyWith(
        connecting: false,
        connected: false,
        error: '$error',
      );
    }
  }

  Future<void> _attach(BootstrapConnection connection) async {
    await _client?.close();
    await _events?.cancel();
    await _connectionStates?.cancel();
    _client = connection.client;
    _events = connection.client.events.listen(_handleEvent);
    _connectionStates = connection.client.states.listen((connectionState) {
      state = state.copyWith(
        connected: connectionState == ClientConnectionState.connected,
        connecting:
            connectionState == ClientConnectionState.connecting ||
            connectionState == ClientConnectionState.reconnecting,
      );
    });
    final results = await Future.wait<Object>(<Future<Object>>[
      connection.client.listWorkspaces(),
      connection.client.listProviderCatalog(),
    ]);
    final workspaces = results[0] as List<WorkspaceDto>;
    final providerCatalog = results[1] as ProviderCatalogDto;
    state = state.copyWith(
      connecting: false,
      connected: true,
      connectionLabel: connection.endpoint.websocketUri.authority,
      serverInfo: connection.client.serverInfo,
      workspaces: workspaces,
      agents: const <AgentDto>[],
      timeline: const <TimelineEventDto>[],
      approvals: const <String, ApprovalRequestDto>{},
      providerCatalog: providerCatalog,
      providerModels: const <String, List<ProviderModelDto>>{},
      clearWorkspace: true,
      clearAgent: true,
      clearError: true,
    );
  }

  Future<WorkspaceDto> registerWorkspace(String rootPath) async {
    final workspace = await _client!.registerWorkspace(
      id: _uuid.v4(),
      rootPath: rootPath,
      name: rootPath.split(RegExp(r'[/\\]')).last,
    );
    state = state.copyWith(
      workspaces: <WorkspaceDto>[...state.workspaces, workspace],
    );
    return workspace;
  }

  Future<void> selectWorkspace(String id) async {
    if (state.selectedWorkspaceId == id && state.agents.isNotEmpty) return;
    final agents = await _client!.listAgents(workspaceId: id);
    state = state.copyWith(
      selectedWorkspaceId: id,
      agents: agents,
      timeline: const <TimelineEventDto>[],
      approvals: const <String, ApprovalRequestDto>{},
      clearAgent: true,
      clearError: true,
    );
  }

  Future<AgentDto> createAgent({
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
    PermissionMode permissionMode = PermissionMode.ask,
  }) async {
    final agent = await _client!.createAgent(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      title: title,
      providerId: providerId,
      model: model,
      reasoningEffort: reasoningEffort,
      permissionMode: permissionMode,
    );
    state = state.copyWith(agents: <AgentDto>[agent, ...state.agents]);
    return agent;
  }

  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerId,
    required String model,
    required String reasoningEffort,
  }) async {
    final updated = await _client!.updateAgentConfiguration(
      agentId: agentId,
      providerId: providerId,
      model: model,
      reasoningEffort: reasoningEffort,
    );
    state = state.copyWith(
      agents: <AgentDto>[
        for (final agent in state.agents)
          if (agent.id == updated.id) updated else agent,
      ],
    );
    return updated;
  }

  Future<void> loadProviderModels(String providerId) async {
    final models = await _client!.listProviderModels(providerId);
    state = state.copyWith(
      providerModels: <String, List<ProviderModelDto>>{
        ...state.providerModels,
        providerId: models,
      },
    );
  }

  Future<void> refreshProviderModels(String providerId) async {
    state = state.copyWith(providerBusy: true, clearError: true);
    try {
      final models = await _client!.refreshProviderModels(providerId);
      state = state.copyWith(
        providerBusy: false,
        providerModels: <String, List<ProviderModelDto>>{
          ...state.providerModels,
          providerId: models,
        },
      );
    } catch (error) {
      state = state.copyWith(providerBusy: false, error: '$error');
      rethrow;
    }
  }

  Future<ApiProviderDto> saveProvider(
    ApiProviderDto provider, {
    String? apiKey,
    bool makeDefault = false,
  }) async {
    state = state.copyWith(providerBusy: true, clearError: true);
    try {
      final saved = await _client!.upsertProvider(
        provider,
        makeDefault: makeDefault,
      );
      if (provider.credentialSource == CredentialSource.stored &&
          apiKey != null &&
          apiKey.isNotEmpty) {
        await _client!.setProviderCredential(provider.id, apiKey);
      }
      final catalog = await _client!.listProviderCatalog();
      state = state.copyWith(providerBusy: false, providerCatalog: catalog);
      return saved;
    } catch (error) {
      state = state.copyWith(providerBusy: false, error: '$error');
      rethrow;
    }
  }

  Future<void> deleteProvider(String providerId) async {
    await _client!.deleteProvider(providerId);
    final catalog = await _client!.listProviderCatalog();
    final models = Map<String, List<ProviderModelDto>>.of(state.providerModels)
      ..remove(providerId);
    state = state.copyWith(providerCatalog: catalog, providerModels: models);
  }

  Future<ProviderModelDto> saveManualModel(ProviderModelDto model) async {
    final saved = await _client!.upsertProviderModel(model);
    await loadProviderModels(model.providerId);
    return saved;
  }

  Future<void> deleteProviderModel(String providerId, String modelId) async {
    await _client!.deleteProviderModel(providerId, modelId);
    await loadProviderModels(providerId);
  }

  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  ) async {
    state = state.copyWith(providerBusy: true, clearError: true);
    try {
      final result = await _client!.diagnoseProviderModel(providerId, modelId);
      await loadProviderModels(providerId);
      state = state.copyWith(providerBusy: false);
      return result;
    } catch (error) {
      state = state.copyWith(providerBusy: false, error: '$error');
      rethrow;
    }
  }

  Future<void> selectAgent(String id) async {
    if (state.selectedAgentId == id && state.timeline.isNotEmpty) return;
    final timeline = await _client!.subscribeTimeline(id);
    final approvals = <String, ApprovalRequestDto>{};
    for (final event in timeline) {
      final approval = _approvalFromTimeline(event);
      if (approval != null && approval.status == ApprovalStatus.pending) {
        approvals[approval.id] = approval;
      }
      if (event.type == 'approval.resolved') {
        approvals.remove(event.data['approvalId']);
      }
    }
    state = state.copyWith(
      selectedAgentId: id,
      timeline: timeline,
      approvals: approvals,
    );
  }

  Future<void> startTurn(String prompt) async {
    final agentId = state.selectedAgentId;
    if (agentId == null || prompt.trim().isEmpty) return;
    await _client!.startTurn(
      agentId: agentId,
      turnId: _uuid.v4(),
      prompt: prompt.trim(),
    );
  }

  Future<void> cancelTurn() async {
    final agentId = state.selectedAgentId;
    if (agentId != null) await _client!.cancelTurn(agentId);
  }

  Future<void> resolveApproval(String id, bool approved) async {
    await _client!.resolveApproval(approvalId: id, approved: approved);
    final approvals = Map<String, ApprovalRequestDto>.of(state.approvals)
      ..remove(id);
    state = state.copyWith(approvals: approvals);
  }

  void _handleEvent(WireEnvelope envelope) {
    switch (envelope.type) {
      case MessageType.timelineEvent:
        final event = TimelineEventDto.fromJson(envelope.payload);
        if (event.agentId != state.selectedAgentId ||
            state.timeline.any((item) => item.sequence == event.sequence)) {
          return;
        }
        final approvals = Map<String, ApprovalRequestDto>.of(state.approvals);
        final approval = _approvalFromTimeline(event);
        if (approval != null) approvals[approval.id] = approval;
        if (event.type == 'approval.resolved')
          approvals.remove(event.data['approvalId']);
        state = state.copyWith(
          timeline: <TimelineEventDto>[...state.timeline, event],
          approvals: approvals,
        );
      case MessageType.agentUpdate:
        final updated = AgentDto.fromJson(envelope.payload);
        final items = <AgentDto>[
          for (final item in state.agents)
            if (item.id == updated.id) updated else item,
        ];
        state = state.copyWith(agents: items);
      case MessageType.approvalRequest:
        final approval = ApprovalRequestDto.fromJson(envelope.payload);
        if (approval.agentId == state.selectedAgentId) {
          state = state.copyWith(
            approvals: <String, ApprovalRequestDto>{
              ...state.approvals,
              approval.id: approval,
            },
          );
        }
    }
  }

  ApprovalRequestDto? _approvalFromTimeline(TimelineEventDto event) {
    if (event.type != 'approval.requested') return null;
    final raw = event.data['approval'];
    return raw is Map
        ? ApprovalRequestDto.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }

  Future<void> _dispose() async {
    await _events?.cancel();
    await _connectionStates?.cancel();
    await _client?.close();
    await _bootstrap.close();
  }
}
