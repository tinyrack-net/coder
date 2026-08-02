import 'dart:async';

import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'controller.g.dart';

/// The bootstrapProvider public API member.
final bootstrapProvider = Provider<AppBootstrap>(
  (ref) => throw StateError('AppBootstrap must be overridden.'),
);

/// The appClockProvider public API member.
final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());

/// The appIdGeneratorProvider public API member.
final appIdGeneratorProvider = Provider<AppIdGenerator>(
  (ref) => const UuidAppIdGenerator(),
);

/// ConnectionSnapshot defines a public contract.
final class ConnectionSnapshot {
  /// Creates a [ConnectionSnapshot].
  const ConnectionSnapshot({
    required this.api,
    required this.endpoint,
    required this.connectionState,
  });

  /// The api public API member.
  final CoderApi api;

  /// The endpoint public API member.
  final HostEndpoint endpoint;

  /// The connectionState public API member.
  final ClientConnectionState connectionState;

  /// The serverInfo public API member.
  ServerInfoDto get serverInfo => api.serverInfo;

  /// The connected public API member.
  bool get connected => connectionState == ClientConnectionState.connected;

  /// The connecting public API member.
  bool get connecting =>
      connectionState == ClientConnectionState.connecting ||
      connectionState == ClientConnectionState.reconnecting;

  /// The label public API member.
  String get label => endpoint.websocketUri.authority;

  /// The copyWith public API member.
  ConnectionSnapshot copyWith({ClientConnectionState? connectionState}) =>
      ConnectionSnapshot(
        api: api,
        endpoint: endpoint,
        connectionState: connectionState ?? this.connectionState,
      );
}

@Riverpod(keepAlive: true)
/// ConnectionController defines a public contract.
class ConnectionController extends _$ConnectionController {
  StreamSubscription<ClientConnectionState>? _states;
  CoderApi? _api;
  late AppBootstrap _bootstrap;

  /// The canRegisterLocalWorkspace public API member.
  bool get canRegisterLocalWorkspace => _bootstrap.canRegisterLocalWorkspace;

  @override
  Future<ConnectionSnapshot?> build() async {
    _bootstrap = ref.watch(bootstrapProvider);
    ref.onDispose(() => unawaited(_dispose()));
    final connection = await _bootstrap.autoConnect();
    return connection == null ? null : _attach(connection);
  }

  /// The connect public API member.
  Future<void> connect(String address, String token) async {
    state = const AsyncLoading<ConnectionSnapshot?>();
    try {
      final endpoint = HostEndpoint.parse(address.trim(), token: token.trim());
      final connection = await _bootstrap.connectRemote(endpoint);
      state = AsyncData<ConnectionSnapshot?>(await _attach(connection));
    } on Exception catch (error, stackTrace) {
      state = AsyncError<ConnectionSnapshot?>(error, stackTrace);
    }
  }

  Future<ConnectionSnapshot> _attach(BootstrapConnection connection) async {
    await _states?.cancel();
    if (!identical(_api, connection.client)) await _api?.close();
    _api = connection.client;
    _states = connection.client.states.listen((connectionState) {
      final current = state.asData?.value;
      if (current != null) {
        state = AsyncData<ConnectionSnapshot?>(
          current.copyWith(connectionState: connectionState),
        );
      }
    });
    return ConnectionSnapshot(
      api: connection.client,
      endpoint: connection.endpoint,
      connectionState: ClientConnectionState.connected,
    );
  }

  Future<void> _dispose() async {
    await _states?.cancel();
    await _api?.close();
    await _bootstrap.close();
  }
}

@Riverpod(keepAlive: true)
/// WorkspacesController defines a public contract.
class WorkspacesController extends _$WorkspacesController {
  @override
  Future<List<WorkspaceDto>> build() async {
    final connection = await ref.watch(connectionControllerProvider.future);
    return connection == null
        ? const <WorkspaceDto>[]
        : connection.api.listWorkspaces();
  }

  /// The register public API member.
  Future<WorkspaceDto> register(String rootPath) async {
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null) throw StateError('Daemon connection required.');
    final previous = state.asData?.value ?? const <WorkspaceDto>[];
    state = const AsyncLoading<List<WorkspaceDto>>();
    try {
      final workspace = await connection.api.registerWorkspace(
        id: ref.read(appIdGeneratorProvider).generate(),
        rootPath: rootPath,
        name: rootPath.split(RegExp(r'[/\\]')).last,
      );
      state = AsyncData<List<WorkspaceDto>>(<WorkspaceDto>[
        ...previous,
        workspace,
      ]);
      return workspace;
    } catch (error, stackTrace) {
      state = AsyncError<List<WorkspaceDto>>(error, stackTrace);
      rethrow;
    }
  }
}

@riverpod
/// AgentsController defines a public contract.
class AgentsController extends _$AgentsController {
  StreamSubscription<ClientEvent>? _events;
  late String? _workspaceId;

  @override
  Future<List<AgentDto>> build(String? workspaceId) async {
    _workspaceId = workspaceId;
    final connection = await ref.watch(connectionControllerProvider.future);
    if (connection == null || workspaceId == null) {
      return const <AgentDto>[];
    }
    _events = connection.api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return connection.api.listAgents(workspaceId: workspaceId);
  }

  /// The create public API member.
  Future<AgentDto> create({
    required String title,
    required String providerConnectionId,
    required String model,
    required String reasoningEffort,
    required PermissionMode permissionMode,
  }) async {
    final workspaceId = _workspaceId;
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null || workspaceId == null) {
      throw StateError('Workspace selection and daemon connection required.');
    }
    final previous = state.asData?.value ?? const <AgentDto>[];
    state = const AsyncLoading<List<AgentDto>>();
    try {
      final agent = await connection.api.createAgent(
        id: ref.read(appIdGeneratorProvider).generate(),
        workspaceId: workspaceId,
        title: title,
        providerConnectionId: providerConnectionId,
        model: model,
        reasoningEffort: reasoningEffort,
        permissionMode: permissionMode,
      );
      state = AsyncData<List<AgentDto>>(<AgentDto>[agent, ...previous]);
      return agent;
    } catch (error, stackTrace) {
      state = AsyncError<List<AgentDto>>(error, stackTrace);
      rethrow;
    }
  }

  /// The updateConfiguration public API member.
  Future<AgentDto> updateConfiguration({
    required String agentId,
    required String providerConnectionId,
    required String model,
    required String reasoningEffort,
  }) async {
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null) throw StateError('Daemon connection required.');
    final updated = await connection.api.updateAgentConfiguration(
      agentId: agentId,
      providerConnectionId: providerConnectionId,
      model: model,
      reasoningEffort: reasoningEffort,
    );
    _replace(updated);
    return updated;
  }

  void _handleEvent(ClientEvent event) {
    if (event case AgentUpdatedClientEvent(
      :final agent,
    ) when agent.workspaceId == _workspaceId) {
      _replace(agent);
    }
  }

  void _replace(AgentDto updated) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<List<AgentDto>>(<AgentDto>[
      for (final agent in current)
        if (agent.id == updated.id) updated else agent,
    ]);
  }
}

/// ConversationState defines a public contract.
final class ConversationState {
  /// Creates a [ConversationState].
  const ConversationState({
    this.timeline = const <TimelineEventDto>[],
    this.approvals = const <String, ApprovalRequestDto>{},
  });

  /// The timeline public API member.
  final List<TimelineEventDto> timeline;

  /// The approvals public API member.
  final Map<String, ApprovalRequestDto> approvals;

  /// The copyWith public API member.
  ConversationState copyWith({
    List<TimelineEventDto>? timeline,
    Map<String, ApprovalRequestDto>? approvals,
  }) => ConversationState(
    timeline: timeline ?? this.timeline,
    approvals: approvals ?? this.approvals,
  );
}

@riverpod
/// ConversationController defines a public contract.
class ConversationController extends _$ConversationController {
  StreamSubscription<ClientEvent>? _events;
  late String? _agentId;

  @override
  Future<ConversationState> build(String? agentId) async {
    _agentId = agentId;
    final connection = await ref.watch(connectionControllerProvider.future);
    if (connection == null || agentId == null) {
      return const ConversationState();
    }
    final timeline = await connection.api.subscribeTimeline(agentId);
    _events = connection.api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return ConversationState(
      timeline: timeline,
      approvals: _pendingApprovals(timeline),
    );
  }

  /// The startTurn public API member.
  Future<void> startTurn(String prompt) async {
    final agentId = _agentId;
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null || agentId == null || prompt.trim().isEmpty) return;
    await connection.api.startTurn(
      agentId: agentId,
      turnId: ref.read(appIdGeneratorProvider).generate(),
      prompt: prompt.trim(),
    );
  }

  /// The cancelTurn public API member.
  Future<void> cancelTurn() async {
    final agentId = _agentId;
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection != null && agentId != null) {
      await connection.api.cancelTurn(agentId);
    }
  }

  /// The resolveApproval public API member.
  Future<void> resolveApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null) throw StateError('Daemon connection required.');
    await connection.api.resolveApproval(
      approvalId: approvalId,
      approved: approved,
    );
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        approvals: Map<String, ApprovalRequestDto>.of(current.approvals)
          ..remove(approvalId),
      ),
    );
  }

  void _handleEvent(ClientEvent clientEvent) {
    final current = state.asData?.value;
    if (current == null) return;
    switch (clientEvent) {
      case TimelineClientEvent(:final event):
        if (event.agentId != _agentId ||
            current.timeline.any((item) => item.sequence == event.sequence)) {
          return;
        }
        final approvals = Map<String, ApprovalRequestDto>.of(current.approvals);
        final approval = _approvalFromTimeline(event);
        if (approval != null) approvals[approval.id] = approval;
        if (event.type == 'approval.resolved') {
          approvals.remove(event.data['approvalId']);
        }
        state = AsyncData<ConversationState>(
          current.copyWith(
            timeline: <TimelineEventDto>[...current.timeline, event],
            approvals: approvals,
          ),
        );
      case ApprovalRequestedClientEvent(:final approval):
        if (approval.agentId == _agentId) {
          state = AsyncData<ConversationState>(
            current.copyWith(
              approvals: <String, ApprovalRequestDto>{
                ...current.approvals,
                approval.id: approval,
              },
            ),
          );
        }
      case AgentUpdatedClientEvent():
      case ProviderAuthUpdatedClientEvent():
        break;
    }
  }

  Map<String, ApprovalRequestDto> _pendingApprovals(
    List<TimelineEventDto> timeline,
  ) {
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
    return approvals;
  }

  ApprovalRequestDto? _approvalFromTimeline(TimelineEventDto event) {
    if (event.type != 'approval.requested') return null;
    final raw = event.data['approval'];
    return raw is Map<dynamic, dynamic>
        ? ApprovalRequestDto.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }
}

/// ProviderSettingsState defines a public contract.
final class ProviderSettingsState {
  /// Creates a [ProviderSettingsState].
  const ProviderSettingsState({
    required this.catalog,
    required this.connections,
    this.models = const <String, List<ProviderModelDto>>{},
    this.authAttempts = const <String, ProviderAuthAttemptDto>{},
  });

  /// The catalog public API member.
  final ProviderCatalogDto catalog;

  /// User-owned provider connections.
  final List<ProviderConnectionDto> connections;

  /// The models public API member.
  final Map<String, List<ProviderModelDto>> models;

  /// Transient interactive authorization attempts.
  final Map<String, ProviderAuthAttemptDto> authAttempts;

  /// The copyWith public API member.
  ProviderSettingsState copyWith({
    ProviderCatalogDto? catalog,
    List<ProviderConnectionDto>? connections,
    Map<String, List<ProviderModelDto>>? models,
    Map<String, ProviderAuthAttemptDto>? authAttempts,
  }) => ProviderSettingsState(
    catalog: catalog ?? this.catalog,
    connections: connections ?? this.connections,
    models: models ?? this.models,
    authAttempts: authAttempts ?? this.authAttempts,
  );
}

@Riverpod(keepAlive: true)
/// ProviderSettingsController defines a public contract.
class ProviderSettingsController extends _$ProviderSettingsController {
  StreamSubscription<ClientEvent>? _events;

  /// The canManage public API member.
  bool get canManage =>
      ref
          .read(connectionControllerProvider)
          .asData
          ?.value
          ?.serverInfo
          .features['providerAdmin'] ==
      true;

  @override
  Future<ProviderSettingsState?> build() async {
    final connection = await ref.watch(connectionControllerProvider.future);
    if (connection == null) return null;
    _events = connection.api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return ProviderSettingsState(
      catalog: await connection.api.listProviderCatalog(),
      connections: await connection.api.listProviderConnections(),
    );
  }

  /// The loadModels public API member.
  Future<void> loadModels(String connectionId) async {
    final connection = await ref.read(connectionControllerProvider.future);
    final current = state.asData?.value;
    if (connection == null || current == null) return;
    final models = await connection.api.listProviderModels(connectionId);
    state = AsyncData<ProviderSettingsState?>(
      current.copyWith(
        models: <String, List<ProviderModelDto>>{
          ...current.models,
          connectionId: models,
        },
      ),
    );
  }

  /// Connects a hosted built-in provider with an API key.
  Future<ProviderConnectionDto> connectApiKey(
    String definitionId,
    String apiKey, {
    bool makeDefault = false,
  }) async {
    final connection = await _requireConnection();
    final result = await connection.api.connectProviderApiKey(
      definitionId,
      apiKey,
      makeDefault: makeDefault,
    );
    await _reload(connection);
    return result;
  }

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectNone(
    String definitionId, {
    bool makeDefault = false,
  }) async {
    final connection = await _requireConnection();
    final result = await connection.api.connectProviderNone(
      definitionId,
      makeDefault: makeDefault,
    );
    await _reload(connection);
    return result;
  }

  /// Starts ChatGPT browser or device-code authorization.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId, {
    bool makeDefault = false,
  }) async {
    final connection = await _requireConnection();
    final attempt = await connection.api.startProviderAuth(
      definitionId,
      methodId,
      makeDefault: makeDefault,
    );
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData<ProviderSettingsState?>(
        current.copyWith(
          authAttempts: <String, ProviderAuthAttemptDto>{
            ...current.authAttempts,
            attempt.id: attempt,
          },
        ),
      );
    }
    return attempt;
  }

  /// Cancels an interactive authorization attempt.
  Future<void> cancelAuth(String attemptId) async {
    final connection = await _requireConnection();
    await connection.api.cancelProviderAuth(attemptId);
  }

  /// Disconnects a provider connection while retaining history.
  Future<void> disconnect(String connectionId) async {
    final connection = await _requireConnection();
    await connection.api.disconnectProvider(connectionId);
    await _reload(connection);
  }

  /// Selects a connection as the daemon default.
  Future<void> setDefault(String connectionId) async {
    final connection = await _requireConnection();
    await connection.api.setDefaultProvider(connectionId);
    await _reload(connection);
  }

  /// Selects the connection's default model.
  Future<void> setDefaultModel(
    String connectionId,
    String modelId,
  ) async {
    final connection = await _requireConnection();
    await connection.api.setDefaultProviderModel(
      connectionId,
      modelId,
    );
    await _reload(connection);
  }

  /// Explicitly refreshes catalog metadata.
  Future<void> refreshCatalog() async {
    final connection = await _requireConnection();
    final catalog = await connection.api.refreshProviderCatalog();
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData<ProviderSettingsState?>(
        current.copyWith(catalog: catalog),
      );
    }
  }

  /// Creates an advanced custom OpenAI-compatible provider.
  Future<ProviderConnectionDto> createCustom(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
    bool makeDefault = false,
  }) async {
    final connection = await _requireConnection();
    final result = await connection.api.createCustomProvider(
      id,
      config,
      apiKey: apiKey,
      makeDefault: makeDefault,
    );
    await _reload(connection);
    return result;
  }

  /// Updates an advanced custom OpenAI-compatible provider.
  Future<ProviderConnectionDto> updateCustom(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final connection = await _requireConnection();
    final result = await connection.api.updateCustomProvider(
      connectionId,
      config,
      apiKey: apiKey,
    );
    await _reload(connection);
    return result;
  }

  /// Deletes an advanced custom connection.
  Future<void> deleteCustom(String connectionId) async {
    final connection = await _requireConnection();
    await connection.api.deleteCustomProvider(connectionId);
    await _reload(connection);
  }

  Future<ConnectionSnapshot> _requireConnection() async {
    final connection = await ref.read(connectionControllerProvider.future);
    if (connection == null) throw StateError('Daemon connection required.');
    return connection;
  }

  Future<void> _reload(ConnectionSnapshot connection) async {
    final current = state.asData?.value;
    state = AsyncData<ProviderSettingsState?>(
      ProviderSettingsState(
        catalog: await connection.api.listProviderCatalog(),
        connections: await connection.api.listProviderConnections(),
        models: current?.models ?? const <String, List<ProviderModelDto>>{},
        authAttempts:
            current?.authAttempts ?? const <String, ProviderAuthAttemptDto>{},
      ),
    );
  }

  void _handleEvent(ClientEvent event) {
    if (event case ProviderAuthUpdatedClientEvent(:final attempt)) {
      final current = state.asData?.value;
      if (current == null) return;
      state = AsyncData<ProviderSettingsState?>(
        current.copyWith(
          authAttempts: <String, ProviderAuthAttemptDto>{
            ...current.authAttempts,
            attempt.id: attempt,
          },
        ),
      );
      if (attempt.status == ProviderAuthAttemptStatus.succeeded) {
        unawaited(_requireConnection().then(_reload));
      }
    }
  }
}
