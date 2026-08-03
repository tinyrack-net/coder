import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/host_registry.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'controller.g.dart';

/// Platform composition supplied by desktop or mobile entrypoints.
final appServicesProvider = Provider<AppServices>(
  (ref) => throw StateError('AppServices must be overridden.'),
);

/// The appClockProvider public API member.
final appClockProvider = Provider<AppClock>((ref) => const SystemAppClock());

/// The appIdGeneratorProvider public API member.
final appIdGeneratorProvider = Provider<AppIdGenerator>(
  (ref) => const UuidAppIdGenerator(),
);

Future<CoderApi> _requireHostApi(Ref ref, String hostId) async {
  final runtime = (await ref.read(
    hostRegistryControllerProvider.future,
  )).runtimes[hostId];
  final api = runtime?.api;
  if (api == null || runtime?.connected != true) {
    throw StateError('Online daemon connection required.');
  }
  return api;
}

@Riverpod(keepAlive: true)
/// Riverpod bridge exposing the independently testable [HostRegistry].
class HostRegistryController extends _$HostRegistryController {
  StreamSubscription<HostRegistryState>? _changes;
  late HostRegistry _registry;

  @override
  Future<HostRegistryState> build() async {
    final services = ref.watch(appServicesProvider);
    _registry = HostRegistry(
      store: services.settings,
      profiles: services.profiles,
      credentials: services.credentials,
      clientFactory: services.clients,
      embeddedLauncher: services.embeddedLauncher,
      ids: ref.watch(appIdGeneratorProvider),
      clock: ref.watch(appClockProvider),
      delay: services.delay,
      clientKind: services.clientKind,
    );
    ref.onDispose(() => unawaited(_dispose()));
    final initial = await _registry.load();
    _changes = _registry.changes.listen((next) {
      state = AsyncData<HostRegistryState>(next);
    });
    return initial;
  }

  /// Adds a remote daemon without requiring it to be online.
  Future<RemoteDaemonProfile> addRemote({
    required String label,
    required String address,
    required String bearerToken,
    required bool autoConnect,
  }) => _registry.addRemote(
    label: label,
    address: address,
    bearerToken: bearerToken,
    autoConnect: autoConnect,
  );

  /// Updates one remote profile.
  Future<void> updateRemote({
    required String profileId,
    required String label,
    required String address,
    required bool autoConnect,
    String? replacementBearerToken,
  }) => _registry.updateRemote(
    profileId: profileId,
    label: label,
    address: address,
    autoConnect: autoConnect,
    replacementBearerToken: replacementBearerToken,
  );

  /// Removes one remote host and its secret.
  Future<void> removeRemote(String profileId) =>
      _registry.removeRemote(profileId);

  /// Connects one host immediately.
  Future<void> reconnect(String hostId) => _registry.reconnect(hostId);

  /// Enables or disables startup connection for one remote host.
  Future<void> setRemoteAutoConnect(
    String hostId, {
    required bool enabled,
  }) => _registry.setAutoConnect(hostId, enabled: enabled);

  /// Selects one host without requiring an online connection.
  Future<void> selectHost(String hostId) => _registry.selectHost(hostId);

  /// Enables or disables the app-owned desktop daemon.
  Future<void> setEmbeddedDaemonEnabled({required bool enabled}) =>
      _registry.setEmbeddedDaemonEnabled(enabled: enabled);

  /// Changes the app-owned daemon listener and restarts it when active.
  Future<void> setEmbeddedDaemonExposure(EmbeddedDaemonExposure exposure) =>
      _registry.setEmbeddedDaemonExposure(exposure);

  /// Persists a checkout selection and its visible session tabs.
  Future<void> saveWorkspaceUi({
    required WorkspaceSelection selection,
    required SessionTabPreference tabs,
  }) => _registry.saveWorkspaceUi(selection: selection, tabs: tabs);

  Future<void> _dispose() async {
    await _changes?.cancel();
    await _registry.close();
  }
}

/// Catalogs from every host, kept separate by app-local host identity.
final class UnifiedWorkspaceCatalogState {
  /// Creates a unified catalog snapshot.
  const UnifiedWorkspaceCatalogState({
    required this.hosts,
    required this.catalogs,
  });

  /// Every host runtime, including offline hosts.
  final Map<String, HostRuntimeSnapshot> hosts;

  /// Online daemon catalogs keyed by host profile ID.
  final Map<String, WorkspaceCatalogDto> catalogs;
}

@Riverpod(keepAlive: true)
/// Loads every online daemon catalog without merging daemon-local IDs.
class WorkspaceCatalogController extends _$WorkspaceCatalogController {
  @override
  Future<UnifiedWorkspaceCatalogState> build() async {
    final registry = await ref.watch(hostRegistryControllerProvider.future);
    final entries = await Future.wait(
      registry.runtimes.values.where((item) => item.connected).map((
        runtime,
      ) async {
        final catalog = await runtime.api!.getWorkspaceCatalog();
        return MapEntry<String, WorkspaceCatalogDto>(runtime.id, catalog);
      }),
    );
    return UnifiedWorkspaceCatalogState(
      hosts: registry.runtimes,
      catalogs: Map<String, WorkspaceCatalogDto>.unmodifiable(
        Map<String, WorkspaceCatalogDto>.fromEntries(entries),
      ),
    );
  }

  /// Registers a folder on the selected daemon and refreshes its catalog.
  Future<WorkspaceRegisterResultDto> register(
    String hostId,
    String rootPath,
  ) async {
    final api = await _requireHostApi(ref, hostId);
    final result = await api.registerWorkspace(
      workspaceId: ref.read(appIdGeneratorProvider).generate(),
      checkoutId: ref.read(appIdGeneratorProvider).generate(),
      rootPath: rootPath,
      name: rootPath.split(RegExp(r'[/\\]')).last,
    );
    await refreshHost(hostId);
    return result;
  }

  /// Refreshes one daemon catalog without affecting other hosts.
  Future<void> refreshHost(String hostId) async {
    final api = await _requireHostApi(ref, hostId);
    final catalog = await api.getWorkspaceCatalog();
    final current = state.requireValue;
    state = AsyncData<UnifiedWorkspaceCatalogState>(
      UnifiedWorkspaceCatalogState(
        hosts: current.hosts,
        catalogs: Map<String, WorkspaceCatalogDto>.unmodifiable(
          <String, WorkspaceCatalogDto>{
            ...current.catalogs,
            hostId: catalog,
          },
        ),
      ),
    );
  }
}

@riverpod
/// SessionsController defines a public contract.
class SessionsController extends _$SessionsController {
  StreamSubscription<ClientEvent>? _events;
  late String? _worktreeId;

  @override
  Future<List<SessionDto>> build(String hostId, String? worktreeId) async {
    _worktreeId = worktreeId;
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true || worktreeId == null) {
      return const <SessionDto>[];
    }
    final api = runtime!.api!;
    _events = api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.listSessions(worktreeId: worktreeId);
  }

  /// The create public API member.
  Future<SessionDto> create({
    required String title,
    required String agentDefinitionId,
  }) async {
    final worktreeId = _worktreeId;
    if (worktreeId == null) {
      throw StateError('Worktree selection and daemon connection required.');
    }
    final api = await _requireHostApi(ref, hostId);
    final previous = state.asData?.value ?? const <SessionDto>[];
    state = const AsyncLoading<List<SessionDto>>();
    try {
      final session = await api.createSession(
        id: ref.read(appIdGeneratorProvider).generate(),
        worktreeId: worktreeId,
        title: title,
        agentDefinitionId: agentDefinitionId,
      );
      state = AsyncData<List<SessionDto>>(<SessionDto>[session, ...previous]);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError<List<SessionDto>>(error, stackTrace);
      rethrow;
    }
  }

  void _handleEvent(ClientEvent event) {
    if (!ref.mounted) return;
    if (event case SessionUpdatedClientEvent(
      :final session,
    ) when session.worktreeId == _worktreeId) {
      _replace(session);
    }
  }

  void _replace(SessionDto updated) {
    final current = state.asData?.value;
    if (current == null) return;
    final exists = current.any((session) => session.id == updated.id);
    state = AsyncData<List<SessionDto>>(<SessionDto>[
      if (!exists) updated,
      for (final agent in current)
        if (agent.id == updated.id) updated else agent,
    ]);
  }
}

/// Agent definition editor data owned by one daemon.
final class AgentDefinitionsState {
  /// Creates an immutable Markdown agent catalog snapshot.
  const AgentDefinitionsState({
    required this.definitions,
    required this.tools,
  });

  /// Visible primary and subagent definitions.
  final List<AgentDefinitionDto> definitions;

  /// Tools this daemon can execute.
  final List<AgentToolDefinitionDto> tools;
}

@riverpod
/// Loads and edits one daemon's Markdown agent files.
class AgentDefinitionsController extends _$AgentDefinitionsController {
  StreamSubscription<ClientEvent>? _events;

  @override
  Future<AgentDefinitionsState> build(String hostId) async {
    final api = await _requireHostApi(ref, hostId);
    _events = api.events.listen((event) {
      if (event is AgentDefinitionsChangedClientEvent) unawaited(refresh());
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return AgentDefinitionsState(
      definitions: await api.listAgentDefinitions(),
      tools: await api.listAgentTools(),
    );
  }

  /// Reloads files and diagnostics from the daemon.
  Future<void> refresh() async {
    final api = await _requireHostApi(ref, hostId);
    final current = state.asData?.value;
    state = AsyncData<AgentDefinitionsState>(
      AgentDefinitionsState(
        definitions: await api.listAgentDefinitions(),
        tools: current?.tools ?? await api.listAgentTools(),
      ),
    );
  }

  /// Creates a custom Markdown-backed definition.
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final api = await _requireHostApi(ref, hostId);
    final created = await api.createAgentDefinition(id, definition);
    await refresh();
    return created;
  }

  /// Saves an edit, rejecting external-file races by default.
  Future<AgentDefinitionDto> saveDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final api = await _requireHostApi(ref, hostId);
    final updated = await api.updateAgentDefinition(
      definition,
      expectedContentHash: expectedContentHash,
      force: force,
    );
    await refresh();
    return updated;
  }

  /// Archives one custom definition.
  Future<void> archive(String id) async {
    final api = await _requireHostApi(ref, hostId);
    await api.archiveAgentDefinition(id);
    await refresh();
  }

  /// Restores the built-in Coder definition.
  Future<AgentDefinitionDto> resetCoder() async {
    final api = await _requireHostApi(ref, hostId);
    final reset = await api.resetAgentDefinition('coder');
    await refresh();
    return reset;
  }
}

/// Visible and selected session tabs for one worktree.
final class SessionTabsState {
  /// Creates immutable tab state.
  const SessionTabsState({
    required this.sessions,
    required this.openAgentIds,
    this.selectedAgentId,
  });

  /// All daemon sessions available to the overflow picker.
  final List<SessionDto> sessions;

  /// Session IDs visible in the tab strip.
  final List<String> openAgentIds;

  /// Currently active tab.
  final String? selectedAgentId;
}

@riverpod
/// Owns local tab visibility independently for each host worktree.
class SessionTabsController extends _$SessionTabsController {
  late WorkspaceSelection _selection;

  @override
  Future<SessionTabsState> build(WorkspaceSelection selection) async {
    _selection = selection;
    final sessions = await ref.watch(
      sessionsControllerProvider(selection.hostId, selection.worktreeId).future,
    );
    final settings = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).settings;
    final saved = settings.sessionTabs[selection.storageKey];
    final existingIds = sessions.map((item) => item.id).toSet();
    final open =
        saved?.openAgentIds
            .where(existingIds.contains)
            .toList(growable: false) ??
        <String>[if (sessions.isNotEmpty) sessions.first.id];
    final selected = open.contains(saved?.selectedAgentId)
        ? saved?.selectedAgentId
        : open.firstOrNull;
    return SessionTabsState(
      sessions: sessions,
      openAgentIds: open,
      selectedAgentId: selected,
    );
  }

  /// Opens and selects a session from the overflow picker.
  Future<void> open(String sessionId) async {
    final current = state.requireValue;
    final open = <String>[
      ...current.openAgentIds.where((id) => id != sessionId),
      sessionId,
    ];
    await _set(current, open, sessionId);
  }

  /// Selects an already-open session.
  Future<void> select(String sessionId) =>
      _set(state.requireValue, state.requireValue.openAgentIds, sessionId);

  /// Hides a tab without deleting its daemon session or history.
  Future<void> close(String sessionId) async {
    final current = state.requireValue;
    final open = current.openAgentIds
        .where((id) => id != sessionId)
        .toList(growable: false);
    final selected = current.selectedAgentId == sessionId
        ? open.lastOrNull
        : current.selectedAgentId;
    await _set(current, open, selected);
  }

  /// Adds a newly-created daemon session to the tab strip.
  Future<void> add(SessionDto agent) async {
    final current = state.requireValue;
    await _set(
      SessionTabsState(
        sessions: <SessionDto>[agent, ...current.sessions],
        openAgentIds: current.openAgentIds,
        selectedAgentId: current.selectedAgentId,
      ),
      <String>[...current.openAgentIds, agent.id],
      agent.id,
    );
  }

  Future<void> _set(
    SessionTabsState current,
    List<String> open,
    String? selected,
  ) async {
    final next = SessionTabsState(
      sessions: current.sessions,
      openAgentIds: List<String>.unmodifiable(open),
      selectedAgentId: selected,
    );
    state = AsyncData<SessionTabsState>(next);
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .saveWorkspaceUi(
          selection: _selection,
          tabs: SessionTabPreference(
            openAgentIds: next.openAgentIds,
            selectedAgentId: next.selectedAgentId,
          ),
        );
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
  late String? _sessionId;

  @override
  Future<ConversationState> build(String hostId, String? sessionId) async {
    _sessionId = sessionId;
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true || sessionId == null) {
      return const ConversationState();
    }
    final api = runtime!.api!;
    final timeline = await api.subscribeTimeline(sessionId);
    _events = api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return ConversationState(
      timeline: timeline,
      approvals: _pendingApprovals(timeline),
    );
  }

  /// The startTurn public API member.
  Future<void> startTurn(String prompt) async {
    final sessionId = _sessionId;
    if (sessionId == null || prompt.trim().isEmpty) return;
    final api = await _requireHostApi(ref, hostId);
    await api.startTurn(
      sessionId: sessionId,
      turnId: ref.read(appIdGeneratorProvider).generate(),
      prompt: prompt.trim(),
    );
  }

  /// The cancelTurn public API member.
  Future<void> cancelTurn() async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      final api = await _requireHostApi(ref, hostId);
      await api.cancelTurn(sessionId);
    }
  }

  /// The resolveApproval public API member.
  Future<void> resolveApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final api = await _requireHostApi(ref, hostId);
    await api.resolveApproval(
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
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    switch (clientEvent) {
      case TimelineClientEvent(:final event):
        if (event.sessionId != _sessionId ||
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
        if (approval.sessionId == _sessionId) {
          state = AsyncData<ConversationState>(
            current.copyWith(
              approvals: <String, ApprovalRequestDto>{
                ...current.approvals,
                approval.id: approval,
              },
            ),
          );
        }
      case SessionUpdatedClientEvent():
      case ProviderAuthUpdatedClientEvent():
      case AgentDefinitionsChangedClientEvent():
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

  @override
  Future<ProviderSettingsState?> build(String hostId) async {
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true) return null;
    final api = runtime!.api!;
    _events = api.events.listen(_handleEvent);
    ref.onDispose(() => unawaited(_events?.cancel()));
    return ProviderSettingsState(
      catalog: await api.listProviderCatalog(),
      connections: await api.listProviderConnections(),
    );
  }

  /// The loadModels public API member.
  Future<void> loadModels(String connectionId) async {
    final runtime = (await ref.read(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true || state.asData?.value == null) return;
    final models = await runtime!.api!.listProviderModels(connectionId);
    final current = state.asData?.value;
    if (current == null) return;
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
    final api = await _requireConnection();
    final result = await api.connectProviderApiKey(
      definitionId,
      apiKey,
      makeDefault: makeDefault,
    );
    await _reload(api);
    return result;
  }

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectNone(
    String definitionId, {
    bool makeDefault = false,
  }) async {
    final api = await _requireConnection();
    final result = await api.connectProviderNone(
      definitionId,
      makeDefault: makeDefault,
    );
    await _reload(api);
    return result;
  }

  /// Starts ChatGPT browser or device-code authorization.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId, {
    bool makeDefault = false,
  }) async {
    final api = await _requireConnection();
    final attempt = await api.startProviderAuth(
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
    final api = await _requireConnection();
    await api.cancelProviderAuth(attemptId);
  }

  /// Disconnects a provider connection while retaining history.
  Future<void> disconnect(String connectionId) async {
    final api = await _requireConnection();
    await api.disconnectProvider(connectionId);
    await _reload(api);
  }

  /// Selects a connection as the daemon default.
  Future<void> setDefault(String connectionId) async {
    final api = await _requireConnection();
    await api.setDefaultProvider(connectionId);
    await _reload(api);
  }

  /// Selects the connection's default model.
  Future<void> setDefaultModel(
    String connectionId,
    String modelId,
  ) async {
    final api = await _requireConnection();
    await api.setDefaultProviderModel(
      connectionId,
      modelId,
    );
    await _reload(api);
  }

  /// Explicitly refreshes catalog metadata.
  Future<void> refreshCatalog() async {
    final api = await _requireConnection();
    final catalog = await api.refreshProviderCatalog();
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
    final api = await _requireConnection();
    final result = await api.createCustomProvider(
      id,
      config,
      apiKey: apiKey,
      makeDefault: makeDefault,
    );
    await _reload(api);
    return result;
  }

  /// Updates an advanced custom OpenAI-compatible provider.
  Future<ProviderConnectionDto> updateCustom(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  }) async {
    final api = await _requireConnection();
    final result = await api.updateCustomProvider(
      connectionId,
      config,
      apiKey: apiKey,
    );
    await _reload(api);
    return result;
  }

  /// Deletes an advanced custom connection.
  Future<void> deleteCustom(String connectionId) async {
    final api = await _requireConnection();
    await api.deleteCustomProvider(connectionId);
    await _reload(api);
  }

  Future<CoderApi> _requireConnection() => _requireHostApi(ref, hostId);

  Future<void> _reload(CoderApi api) async {
    final current = state.asData?.value;
    state = AsyncData<ProviderSettingsState?>(
      ProviderSettingsState(
        catalog: await api.listProviderCatalog(),
        connections: await api.listProviderConnections(),
        models: current?.models ?? const <String, List<ProviderModelDto>>{},
        authAttempts:
            current?.authAttempts ?? const <String, ProviderAuthAttemptDto>{},
      ),
    );
  }

  void _handleEvent(ClientEvent event) {
    if (!ref.mounted) return;
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
