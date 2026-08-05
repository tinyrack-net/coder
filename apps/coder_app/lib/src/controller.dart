import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/attachment_ports.dart';
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
  return _connectedApi(runtime);
}

/// Resolves the API inside a `build`, re-running once the daemon connects.
Future<CoderApi> _watchHostApi(Ref ref, String hostId) async {
  final runtime = (await ref.watch(
    hostRegistryControllerProvider.future,
  )).runtimes[hostId];
  return _connectedApi(runtime);
}

CoderApi _connectedApi(HostRuntimeSnapshot? runtime) {
  final api = runtime?.api;
  if (api == null || runtime?.connected != true) {
    throw StateError('Online daemon connection required.');
  }
  return api;
}

Duration? _noAutomaticRetry(int retryCount, Object error) => null;

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
      embeddedDataEraser: services.embeddedDataEraser,
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

  /// Changes the app-owned daemon port and restarts it when active.
  Future<void> setEmbeddedDaemonPort(int port) =>
      _registry.setEmbeddedDaemonPort(port);

  /// Erases stored daemon data and every device-local app setting.
  Future<void> resetToFactoryDefaults() => _registry.resetToFactoryDefaults();

  /// Persists the app UI language, where null follows the system locale.
  Future<void> setLocaleTag(String? tag) => _registry.setLocaleTag(tag);

  /// Persists the theme the app paints itself with.
  Future<void> setThemeMode(AppThemeMode mode) => _registry.setThemeMode(mode);

  /// Persists whether the operating system launches the app at login.
  Future<void> setStartAtBoot({required bool enabled}) =>
      _registry.setStartAtBoot(enabled: enabled);

  /// Persists whether a login-time launch starts hidden in the tray.
  Future<void> setStartMinimizedAtBoot({required bool enabled}) =>
      _registry.setStartMinimizedAtBoot(enabled: enabled);

  /// Stops every client and the app-owned daemon before the process exits.
  Future<void> shutdown() => _registry.shutdown();

  /// Persists whether the workspace sidebar is hidden.
  Future<void> setSidebarCollapsed({required bool collapsed}) =>
      _registry.setSidebarCollapsed(collapsed: collapsed);

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

@Riverpod(keepAlive: true)
/// The daemon that host-scoped screens read and write.
///
/// The saved [AppSettings.lastActiveHostId] wins so the choice survives a
/// restart and stays in step with the workspace window. It is allowed to name
/// an offline daemon, so the fallbacks only run when it names no daemon at all.
String? activeHostId(Ref ref) {
  final registry = ref.watch(hostRegistryControllerProvider).asData?.value;
  if (registry == null) return null;
  final runtimes = registry.runtimes;
  final saved = registry.settings.lastActiveHostId;
  if (saved != null && runtimes.containsKey(saved)) return saved;
  return runtimes.values.where((item) => item.connected).firstOrNull?.id ??
      runtimes.values.firstOrNull?.id;
}

@Riverpod(keepAlive: true)
/// Tracks whether the saved worktree was already restored this run.
///
/// The workspace page is rebuilt whenever the route changes, so the guard has
/// to outlive its state or leaving a session would snap straight back into it.
class SelectionRestoreController extends _$SelectionRestoreController {
  @override
  bool build() => false;

  /// Marks the saved selection as consumed for this app run.
  void markConsumed() => state = true;
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
/// Lists local Git branches for one repository.
Future<List<GitBranchDto>> gitBranches(
  Ref ref,
  String hostId,
  String workspaceId,
) async {
  final api = await _watchHostApi(ref, hostId);
  return api.listGitBranches(workspaceId);
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
  ///
  /// A non-null [model] pins the session to one provider connection and model
  /// instead of inheriting the model of its agent definition.
  Future<SessionDto> create({
    required String title,
    required String agentDefinitionId,
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
    String? reasoningEffort,
    PermissionMode? permissionMode,
    String? serviceTier,
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
        mode: mode,
        model: model,
        reasoningEffort: reasoningEffort,
        permissionMode: permissionMode,
        serviceTier: serviceTier,
      );
      state = AsyncData<List<SessionDto>>(<SessionDto>[session, ...previous]);
      return session;
    } catch (error, stackTrace) {
      state = AsyncError<List<SessionDto>>(error, stackTrace);
      rethrow;
    }
  }

  /// Switches one session between planning and normal collaboration.
  Future<SessionDto> setMode(String sessionId, SessionMode mode) => _apply(
    sessionId,
    (session) => session.copyWith(mode: mode),
    (api) => api.updateSessionMode(sessionId, mode),
  );

  /// Sets or clears the provider and model override of one session.
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) => _apply(
    sessionId,
    (session) => session.copyWith(model: model),
    (api) => api.updateSessionModel(sessionId, model),
  );

  /// Sets or clears the reasoning effort override of one session.
  Future<SessionDto> setReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  ) => _apply(
    sessionId,
    (session) => session.copyWith(reasoningEffort: reasoningEffort),
    (api) => api.updateSessionReasoningEffort(sessionId, reasoningEffort),
  );

  /// Sets or clears the permission mode override of one session.
  Future<SessionDto> setPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  ) => _apply(
    sessionId,
    (session) => session.copyWith(permissionMode: permissionMode),
    (api) => api.updateSessionPermissionMode(sessionId, permissionMode),
  );

  /// Sets or clears the provider service tier of one session.
  Future<SessionDto> setServiceTier(
    String sessionId,
    String? serviceTier,
  ) => _apply(
    sessionId,
    (session) => session.copyWith(serviceTier: serviceTier),
    (api) => api.updateSessionServiceTier(sessionId, serviceTier),
  );

  /// Shows a turn-setting change immediately and confirms it with the daemon.
  ///
  /// Without the local patch the chip keeps its old label for a full round
  /// trip and then flips, which reads as a flicker rather than a toggle. The
  /// daemon still owns the value, so its answer replaces the guess and a
  /// failure restores what was on screen before.
  Future<SessionDto> _apply(
    String sessionId,
    SessionDto Function(SessionDto session) patch,
    Future<SessionDto> Function(CoderApi api) commit,
  ) async {
    // Patched before the first suspension, so the chip is already showing the
    // new value on the frame the tap is handled.
    final previous = state.asData?.value
        .where((session) => session.id == sessionId)
        .firstOrNull;
    if (previous != null) _replace(patch(previous));
    try {
      final session = await commit(await _requireHostApi(ref, hostId));
      _replace(session);
      return session;
    } on Exception {
      if (previous != null) _replace(previous);
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

@Riverpod(retry: _noAutomaticRetry)
/// Loads and edits the `coder.json` worktree hooks of one project.
class ProjectSettingsController extends _$ProjectSettingsController {
  @override
  Future<ProjectSettingsResultDto> build(
    String hostId,
    String workspaceId,
  ) async {
    final api = await _watchHostApi(ref, hostId);
    return api.getProjectSettings(workspaceId);
  }

  /// Replaces the worktree hook section on the daemon host.
  Future<void> save(ProjectSettingsDto settings) async {
    final api = await _requireHostApi(ref, hostId);
    state = AsyncData<ProjectSettingsResultDto>(
      await api.saveProjectSettings(workspaceId, settings),
    );
  }
}

/// MCP server editor data owned by one daemon.
final class McpServersState {
  /// Creates immutable MCP server state.
  const McpServersState({required this.servers});

  /// Every server visible to this daemon and the selected worktree.
  final List<McpServerStateDto> servers;

  /// Servers the user configured, which are the editable ones.
  List<McpServerStateDto> get userServers => servers
      .where((server) => server.scope == McpConfigScope.user)
      .toList(growable: false);

  /// Servers the selected repository declares, which are read-only.
  List<McpServerStateDto> get projectServers => servers
      .where((server) => server.scope == McpConfigScope.project)
      .toList(growable: false);
}

@riverpod
/// Loads and edits one daemon's MCP server configuration.
class McpServersController extends _$McpServersController {
  StreamSubscription<ClientEvent>? _events;
  int _refreshGeneration = 0;

  @override
  Future<McpServersState> build(String hostId, String? worktreeId) async {
    final api = await _watchHostApi(ref, hostId);
    _events = api.events.listen((event) {
      if (event is McpServersChangedClientEvent) unawaited(refresh());
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return McpServersState(
      servers: await api.listMcpServers(worktreeId: worktreeId),
    );
  }

  /// Re-reads every server and its live connection state.
  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    final api = await _requireHostApi(ref, hostId);
    final servers = await api.listMcpServers(worktreeId: worktreeId);
    if (!ref.mounted || generation != _refreshGeneration) return;
    state = AsyncData<McpServersState>(
      McpServersState(servers: servers),
    );
  }

  /// Adds one user-scoped server.
  Future<void> add(McpServerConfigDto server) async {
    final api = await _requireHostApi(ref, hostId);
    await api.addMcpServer(server);
    await refresh();
  }

  /// Replaces one user-scoped server.
  Future<void> save(McpServerConfigDto server) async {
    final api = await _requireHostApi(ref, hostId);
    await api.updateMcpServer(server);
    await refresh();
  }

  /// Removes one user-scoped server.
  Future<void> remove(String id) async {
    final api = await _requireHostApi(ref, hostId);
    await api.removeMcpServer(id);
    await refresh();
  }

  /// Connects an unsaved configuration to report what it publishes.
  Future<McpServerStateDto> test(McpServerConfigDto server) async {
    final api = await _requireHostApi(ref, hostId);
    return api.testMcpServer(server);
  }

  /// Stores one secret an MCP configuration may reference.
  Future<void> setSecret(String key, String value) async {
    final api = await _requireHostApi(ref, hostId);
    await api.setMcpSecret(key, value);
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
    final api = await _watchHostApi(ref, hostId);
    _events = api.events.listen((event) {
      // An MCP server coming up changes the tool catalog, so both events
      // invalidate this state.
      if (event is AgentDefinitionsChangedClientEvent ||
          event is McpServersChangedClientEvent) {
        unawaited(refresh());
      }
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return AgentDefinitionsState(
      definitions: await api.listAgentDefinitions(),
      tools: await api.listAgentTools(),
    );
  }

  /// Reloads files, diagnostics, and the tool catalog from the daemon.
  ///
  /// The catalog is re-read rather than reused: MCP servers publish and
  /// withdraw tools while the daemon runs, so a cached list goes stale.
  Future<void> refresh() async {
    final api = await _requireHostApi(ref, hostId);
    state = AsyncData<AgentDefinitionsState>(
      AgentDefinitionsState(
        definitions: await api.listAgentDefinitions(),
        tools: await api.listAgentTools(),
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

@riverpod
/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.
class SkillsController extends _$SkillsController {
  StreamSubscription<ClientEvent>? _events;

  @override
  Future<List<SkillDto>> build(String hostId, String? workspaceId) async {
    final api = await _watchHostApi(ref, hostId);
    _events = api.events.listen((event) {
      if (event is SkillsChangedClientEvent) unawaited(refresh());
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.listSkills(workspaceId: workspaceId);
  }

  /// Reloads the catalog from the daemon.
  Future<void> refresh() async {
    final api = await _requireHostApi(ref, hostId);
    final skills = await api.listSkills(workspaceId: workspaceId);
    if (!ref.mounted) return;
    state = AsyncData<List<SkillDto>>(skills);
  }

  /// Creates one skill in a writable source.
  Future<SkillDto> create({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
  }) async {
    final api = await _requireHostApi(ref, hostId);
    final created = await api.createSkill(
      id: id,
      source: source,
      name: name,
      description: description,
      body: body,
      workspaceId: workspaceId,
    );
    await refresh();
    return created;
  }

  /// Saves an edit, rejecting external-file races by default.
  Future<SkillDto> save(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final api = await _requireHostApi(ref, hostId);
    final updated = await api.updateSkill(
      skill,
      expectedContentHash: expectedContentHash,
      force: force,
      workspaceId: workspaceId,
    );
    await refresh();
    return updated;
  }

  /// Archives one editable skill.
  Future<void> delete(String id) async {
    final api = await _requireHostApi(ref, hostId);
    await api.deleteSkill(id, workspaceId: workspaceId);
    await refresh();
  }

  /// Turns one skill on or off.
  Future<SkillDto> setEnabled(String id, {required bool enabled}) async {
    final api = await _requireHostApi(ref, hostId);
    final updated = await api.setSkillEnabled(
      id,
      enabled: enabled,
      workspaceId: workspaceId,
    );
    await refresh();
    return updated;
  }
}

@riverpod
/// Owns the live terminal catalog for one connected worktree.
class TerminalsController extends _$TerminalsController {
  StreamSubscription<ClientEvent>? _events;

  @override
  Future<List<TerminalDto>> build(String hostId, String worktreeId) async {
    final runtime = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    if (runtime?.connected != true) return const <TerminalDto>[];
    final api = runtime!.api!;
    _events = api.events.listen((event) {
      if (event case TerminalUpdatedClientEvent(
        :final terminal,
      ) when terminal.worktreeId == worktreeId) {
        final current = state.asData?.value ?? const <TerminalDto>[];
        state = AsyncData<List<TerminalDto>>(<TerminalDto>[
          terminal,
          ...current.where((item) => item.id != terminal.id),
        ]);
      }
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return api.listTerminals(worktreeId);
  }

  /// Creates a terminal with a standard initial character grid.
  Future<TerminalDto> create() async {
    final api = await _requireHostApi(ref, hostId);
    final current = state.asData?.value ?? const <TerminalDto>[];
    final terminal = await api.createTerminal(
      id: ref.read(appIdGeneratorProvider).generate(),
      worktreeId: worktreeId,
      title: 'Terminal ${current.length + 1}',
      columns: 80,
      rows: 24,
    );
    state = AsyncData<List<TerminalDto>>(<TerminalDto>[terminal, ...current]);
    return terminal;
  }
}

/// Visible and selected session tabs for one worktree.
final class SessionTabsState {
  /// Creates immutable tab state.
  const SessionTabsState({
    required this.sessions,
    required this.openAgentIds,
    required this.terminals,
    required this.openTerminalIds,
    this.selectedAgentId,
    this.selectedTerminalId,
  });

  /// All daemon sessions available to the overflow picker.
  final List<SessionDto> sessions;

  /// Session IDs visible in the tab strip.
  final List<String> openAgentIds;

  /// Currently active tab.
  final String? selectedAgentId;

  /// Daemon-owned terminals available to the tab strip.
  final List<TerminalDto> terminals;

  /// Terminal IDs visible in the tab strip.
  final List<String> openTerminalIds;

  /// Currently active terminal tab.
  final String? selectedTerminalId;
}

@riverpod
/// Owns local tab visibility independently for each host worktree.
class SessionTabsController extends _$SessionTabsController {
  late WorkspaceSelection _selection;

  @override
  Future<SessionTabsState> build(WorkspaceSelection selection) async {
    _selection = selection;
    final values = await Future.wait<Object>(<Future<Object>>[
      ref.watch(
        sessionsControllerProvider(
          selection.hostId,
          selection.worktreeId,
        ).future,
      ),
      ref.watch(
        terminalsControllerProvider(
          selection.hostId,
          selection.worktreeId,
        ).future,
      ),
    ]);
    final sessions = values[0] as List<SessionDto>;
    final terminals = values[1] as List<TerminalDto>;
    final settings = (await ref.watch(
      hostRegistryControllerProvider.future,
    )).settings;
    final saved = settings.sessionTabs[selection.storageKey];
    final existingIds = sessions.map((item) => item.id).toSet();
    final existingTerminalIds = terminals.map((item) => item.id).toSet();
    final open =
        saved?.openAgentIds
            .where(existingIds.contains)
            .toList(growable: false) ??
        <String>[if (sessions.isNotEmpty) sessions.first.id];
    // A saved null selection means the composer draft is showing, so it must
    // not snap back to the first open tab on the next rebuild.
    final selected = saved == null
        ? open.firstOrNull
        : (open.contains(saved.selectedAgentId) ? saved.selectedAgentId : null);
    final openTerminals =
        saved?.openTerminalIds
            .where(existingTerminalIds.contains)
            .toList(growable: false) ??
        const <String>[];
    final selectedTerminal =
        selected == null && openTerminals.contains(saved?.selectedTerminalId)
        ? saved?.selectedTerminalId
        : null;
    return SessionTabsState(
      sessions: sessions,
      openAgentIds: open,
      selectedAgentId: selected,
      terminals: terminals,
      openTerminalIds: openTerminals,
      selectedTerminalId: selectedTerminal,
    );
  }

  /// Opens and selects a session from the overflow picker.
  Future<void> open(String sessionId) async {
    final current = state.requireValue;
    final open = <String>[
      ...current.openAgentIds.where((id) => id != sessionId),
      sessionId,
    ];
    await _set(current, open, sessionId, current.openTerminalIds, null);
  }

  /// Selects an already-open session.
  Future<void> select(String sessionId) => _set(
    state.requireValue,
    state.requireValue.openAgentIds,
    sessionId,
    state.requireValue.openTerminalIds,
    null,
  );

  /// Clears the selection so the composer starts a new session draft.
  Future<void> startDraft() => _set(
    state.requireValue,
    state.requireValue.openAgentIds,
    null,
    state.requireValue.openTerminalIds,
    null,
  );

  /// Hides a tab without deleting its daemon session or history.
  Future<void> close(String sessionId) async {
    final current = state.requireValue;
    final open = current.openAgentIds
        .where((id) => id != sessionId)
        .toList(growable: false);
    final selected = current.selectedAgentId == sessionId
        ? open.lastOrNull
        : current.selectedAgentId;
    await _set(current, open, selected, current.openTerminalIds, null);
  }

  /// Adds a newly-created daemon session to the tab strip.
  Future<void> add(SessionDto agent) async {
    final current = state.requireValue;
    await _set(
      SessionTabsState(
        sessions: <SessionDto>[agent, ...current.sessions],
        openAgentIds: current.openAgentIds,
        selectedAgentId: current.selectedAgentId,
        terminals: current.terminals,
        openTerminalIds: current.openTerminalIds,
        selectedTerminalId: current.selectedTerminalId,
      ),
      <String>[...current.openAgentIds, agent.id],
      agent.id,
      current.openTerminalIds,
      null,
    );
  }

  /// Adds and selects a newly-created terminal tab.
  Future<void> addTerminal(TerminalDto terminal) async {
    final current = state.requireValue;
    await _set(
      SessionTabsState(
        sessions: current.sessions,
        openAgentIds: current.openAgentIds,
        selectedAgentId: current.selectedAgentId,
        terminals: <TerminalDto>[terminal, ...current.terminals],
        openTerminalIds: current.openTerminalIds,
        selectedTerminalId: current.selectedTerminalId,
      ),
      current.openAgentIds,
      null,
      <String>[...current.openTerminalIds, terminal.id],
      terminal.id,
    );
  }

  /// Selects a visible terminal tab.
  Future<void> selectTerminal(String id) => _set(
    state.requireValue,
    state.requireValue.openAgentIds,
    null,
    state.requireValue.openTerminalIds,
    id,
  );

  /// Opens and selects a terminal from the overflow picker.
  Future<void> openTerminal(String id) {
    final current = state.requireValue;
    return _set(
      current,
      current.openAgentIds,
      null,
      <String>[...current.openTerminalIds.where((item) => item != id), id],
      id,
    );
  }

  /// Removes a terminated terminal from the visible strip.
  Future<void> closeTerminal(String id) async {
    final current = state.requireValue;
    final open = current.openTerminalIds.where((item) => item != id).toList();
    await _set(
      current,
      current.openAgentIds,
      current.selectedAgentId,
      open,
      current.selectedTerminalId == id
          ? open.lastOrNull
          : current.selectedTerminalId,
    );
  }

  Future<void> _set(
    SessionTabsState current,
    List<String> open,
    String? selected,
    List<String> openTerminals,
    String? selectedTerminal,
  ) async {
    final next = SessionTabsState(
      sessions: current.sessions,
      openAgentIds: List<String>.unmodifiable(open),
      selectedAgentId: selected,
      terminals: current.terminals,
      openTerminalIds: List<String>.unmodifiable(openTerminals),
      selectedTerminalId: selectedTerminal,
    );
    state = AsyncData<SessionTabsState>(next);
    await ref
        .read(hostRegistryControllerProvider.notifier)
        .saveWorkspaceUi(
          selection: _selection,
          tabs: SessionTabPreference(
            openAgentIds: next.openAgentIds,
            selectedAgentId: next.selectedAgentId,
            openTerminalIds: next.openTerminalIds,
            selectedTerminalId: next.selectedTerminalId,
          ),
        );
  }
}

/// Agent and model chosen in the composer before a session exists.
final class SessionComposerDraft {
  /// Creates a composer draft.
  const SessionComposerDraft({
    this.agentDefinitionId,
    this.model,
    this.mode = SessionMode.normal,
    this.reasoningEffort,
    this.permissionMode,
    this.serviceTier,
  });

  /// Explicitly chosen agent definition; null falls back to the first usable.
  final String? agentDefinitionId;

  /// Explicitly chosen provider and model; null inherits the agent definition.
  final SessionModelSelectionDto? model;

  /// Collaboration mode the next session starts in.
  final SessionMode mode;

  /// Explicitly chosen reasoning effort; null inherits the agent definition.
  final String? reasoningEffort;

  /// Explicitly chosen permission mode; null inherits the agent definition.
  final PermissionMode? permissionMode;

  /// Explicitly chosen provider service tier; null uses the provider default.
  final String? serviceTier;

  /// Returns a copy with the given fields replaced.
  ///
  /// Every nullable field takes a wrapper so passing an explicit null clears
  /// the override instead of being read as "leave unchanged".
  SessionComposerDraft copyWith({
    SessionMode? mode,
    ({String? value})? agentDefinitionId,
    ({SessionModelSelectionDto? value})? model,
    ({String? value})? reasoningEffort,
    ({PermissionMode? value})? permissionMode,
    ({String? value})? serviceTier,
  }) => SessionComposerDraft(
    agentDefinitionId: agentDefinitionId == null
        ? this.agentDefinitionId
        : agentDefinitionId.value,
    model: model == null ? this.model : model.value,
    mode: mode ?? this.mode,
    reasoningEffort: reasoningEffort == null
        ? this.reasoningEffort
        : reasoningEffort.value,
    permissionMode: permissionMode == null
        ? this.permissionMode
        : permissionMode.value,
    serviceTier: serviceTier == null ? this.serviceTier : serviceTier.value,
  );
}

@Riverpod(keepAlive: true)
/// Holds the composer selection used to create the next session.
class SessionComposerDraftController extends _$SessionComposerDraftController {
  @override
  SessionComposerDraft build(String hostId, String? worktreeId) =>
      const SessionComposerDraft();

  /// Chooses the agent definition and drops every override bound to the old
  /// agent, so the new definition supplies its own defaults.
  void selectAgent(String agentDefinitionId) => state = SessionComposerDraft(
    agentDefinitionId: agentDefinitionId,
    mode: state.mode,
  );

  /// Chooses the provider and model override, or clears it when null.
  void selectModel(SessionModelSelectionDto? model) => state = state.copyWith(
    model: (value: model),
    // A different model may not support the previous tier or effort.
    reasoningEffort: const (value: null),
    serviceTier: const (value: null),
  );

  /// Chooses the collaboration mode the next session starts in.
  void selectMode(SessionMode mode) => state = state.copyWith(mode: mode);

  /// Chooses the reasoning effort override, or clears it when null.
  void selectReasoningEffort(String? reasoningEffort) =>
      state = state.copyWith(reasoningEffort: (value: reasoningEffort));

  /// Chooses the permission mode override, or clears it when null.
  void selectPermissionMode(PermissionMode? permissionMode) =>
      state = state.copyWith(permissionMode: (value: permissionMode));

  /// Chooses the provider service tier, or clears it when null.
  void selectServiceTier(String? serviceTier) =>
      state = state.copyWith(serviceTier: (value: serviceTier));
}

/// One prompt typed while a turn was still running.
///
/// The daemon runs a single turn per session, so a follow-up waits here until
/// the active turn settles instead of being rejected or silently dropped.
final class QueuedTurn {
  /// Creates a [QueuedTurn].
  const QueuedTurn({
    required this.id,
    required this.text,
    required this.attachments,
  });

  /// Identity used to edit or promote one entry.
  final String id;

  /// Trimmed prompt text.
  final String text;

  /// Files that go up with the prompt.
  final List<PendingAttachment> attachments;
}

/// ConversationState defines a public contract.
final class ConversationState {
  /// Creates a [ConversationState].
  const ConversationState({
    this.timeline = const <TimelineEventDto>[],
    this.approvals = const <String, ApprovalRequestDto>{},
    this.queued = const <QueuedTurn>[],
    this.questions = const <String, UserQuestionRequestDto>{},
  });

  /// The timeline public API member.
  final List<TimelineEventDto> timeline;

  /// The approvals public API member.
  final Map<String, ApprovalRequestDto> approvals;

  /// Prompts waiting for the active turn to finish, oldest first.
  final List<QueuedTurn> queued;

  /// Questions the agent is blocked on, keyed by request id.
  final Map<String, UserQuestionRequestDto> questions;

  /// The copyWith public API member.
  ConversationState copyWith({
    List<TimelineEventDto>? timeline,
    Map<String, ApprovalRequestDto>? approvals,
    List<QueuedTurn>? queued,
    Map<String, UserQuestionRequestDto>? questions,
  }) => ConversationState(
    timeline: timeline ?? this.timeline,
    approvals: approvals ?? this.approvals,
    queued: queued ?? this.queued,
    questions: questions ?? this.questions,
  );
}

@riverpod
/// ConversationController defines a public contract.
class ConversationController extends _$ConversationController {
  StreamSubscription<ClientEvent>? _events;
  late String? _sessionId;
  // Both the idle session event and an explicit promotion can ask for a drain,
  // so one send is in flight at a time.
  bool _draining = false;

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
      questions: _pendingQuestions(timeline),
    );
  }

  /// The startTurn public API member.
  Future<void> startTurn(
    String prompt, {
    List<PendingAttachment> attachments = const <PendingAttachment>[],
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null || (prompt.trim().isEmpty && attachments.isEmpty)) {
      return;
    }
    final api = await _requireHostApi(ref, hostId);
    final uploaded = <AttachmentDto>[];
    for (final attachment in attachments) {
      uploaded.add(
        await api.uploadAttachment(
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          byteSize: attachment.byteSize,
          bytes: attachment.openRead(),
        ),
      );
    }
    await api.startTurn(
      sessionId: sessionId,
      turnId: ref.read(appIdGeneratorProvider).generate(),
      prompt: prompt.trim(),
      attachmentIds: uploaded.map((item) => item.id).toList(growable: false),
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

  /// Holds a prompt until the active turn settles.
  void enqueueTurn(
    String prompt, {
    List<PendingAttachment> attachments = const <PendingAttachment>[],
  }) {
    final text = prompt.trim();
    final current = state.asData?.value;
    if (current == null || (text.isEmpty && attachments.isEmpty)) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        queued: <QueuedTurn>[
          ...current.queued,
          QueuedTurn(
            id: ref.read(appIdGeneratorProvider).generate(),
            text: text,
            attachments: List<PendingAttachment>.unmodifiable(attachments),
          ),
        ],
      ),
    );
  }

  /// Removes one waiting prompt and returns it, so it can be edited again.
  QueuedTurn? takeQueuedTurn(String id) {
    final current = state.asData?.value;
    final item = current?.queued.where((entry) => entry.id == id).firstOrNull;
    if (current == null || item == null) return null;
    state = AsyncData<ConversationState>(
      current.copyWith(
        queued: current.queued
            .where((entry) => entry.id != id)
            .toList(growable: false),
      ),
    );
    return item;
  }

  /// Cancels the active turn and starts one waiting prompt immediately.
  Future<void> sendQueuedTurnNow(String id) async {
    final item = takeQueuedTurn(id);
    if (item == null) return;
    try {
      await cancelTurn();
      await startTurn(item.text, attachments: item.attachments);
    } on Exception {
      _restoreQueuedTurn(item);
      rethrow;
    }
  }

  /// Starts the oldest waiting prompt, if any.
  ///
  /// Exactly one prompt leaves the queue per call: each queued follow-up earns
  /// its own turn, and the next one waits for that turn to settle in turn.
  Future<void> drainQueue() async {
    if (_draining) return;
    final current = state.asData?.value;
    final next = current?.queued.firstOrNull;
    if (current == null || next == null) return;
    _draining = true;
    state = AsyncData<ConversationState>(
      current.copyWith(queued: current.queued.sublist(1)),
    );
    try {
      await startTurn(next.text, attachments: next.attachments);
    } on Exception {
      // The drain runs from a broadcast event with nobody to await it, so a
      // failed send puts the prompt back rather than disappearing.
      _restoreQueuedTurn(next);
    } finally {
      _draining = false;
    }
  }

  void _restoreQueuedTurn(QueuedTurn item) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(queued: <QueuedTurn>[item, ...current.queued]),
    );
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

  /// Answers a pending agent question and lets its turn continue.
  Future<void> answerUserQuestion(
    String requestId,
    List<UserQuestionAnswerDto> answers,
  ) async {
    final api = await _requireHostApi(ref, hostId);
    await api.answerUserQuestion(requestId: requestId, answers: answers);
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        questions: Map<String, UserQuestionRequestDto>.of(current.questions)
          ..remove(requestId),
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
        final timeline = <TimelineEventDto>[...current.timeline, event];
        state = AsyncData<ConversationState>(
          current.copyWith(
            timeline: timeline,
            approvals: approvals,
            questions: _pendingQuestions(timeline),
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
      case SessionUpdatedClientEvent(:final session):
        // A waiting prompt only exists because a turn was running, so a
        // settled session is the signal to start the next one.
        if (session.id == _sessionId &&
            current.queued.isNotEmpty &&
            (session.status == SessionStatus.idle ||
                session.status == SessionStatus.failed)) {
          unawaited(drainQueue());
        }
      case UserQuestionRequestedClientEvent(:final request):
        if (request.sessionId == _sessionId) {
          state = AsyncData<ConversationState>(
            current.copyWith(
              questions: <String, UserQuestionRequestDto>{
                ...current.questions,
                request.id: request,
              },
            ),
          );
        }
      case ProviderAuthUpdatedClientEvent():
      case AgentDefinitionsChangedClientEvent():
      case McpServersChangedClientEvent():
      case SkillsChangedClientEvent():
      case TerminalOutputClientEvent():
      case TerminalUpdatedClientEvent():
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

  /// Questions still awaiting an answer, derived from the timeline.
  ///
  /// A question whose turn already ended is dropped: the daemon cancels it on
  /// restart without writing an answer event, so leaving it would strand a card
  /// the user can never resolve.
  Map<String, UserQuestionRequestDto> _pendingQuestions(
    List<TimelineEventDto> timeline,
  ) {
    final questions = <String, UserQuestionRequestDto>{};
    final terminated = <String?>{
      for (final event in timeline)
        if (event.type == 'turn.completed' ||
            event.type == 'turn.failed' ||
            event.type == 'turn.cancelled')
          event.turnId,
    };
    for (final event in timeline) {
      final request = _questionFromTimeline(event);
      if (request != null && request.status == UserQuestionStatus.pending) {
        questions[request.id] = request;
      }
      if (event.type == 'userQuestion.answered') {
        questions.remove(event.data['requestId']);
      }
    }
    questions.removeWhere(
      (_, request) => terminated.contains(request.turnId),
    );
    return questions;
  }

  UserQuestionRequestDto? _questionFromTimeline(TimelineEventDto event) {
    if (event.type != 'userQuestion.requested') return null;
    final raw = event.data['request'];
    return raw is Map<dynamic, dynamic>
        ? UserQuestionRequestDto.fromJson(Map<String, dynamic>.from(raw))
        : null;
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
    String apiKey,
  ) async {
    final api = await _requireConnection();
    final result = await api.connectProviderApiKey(
      definitionId,
      apiKey,
    );
    await _reload(api);
    return result;
  }

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectNone(String definitionId) async {
    final api = await _requireConnection();
    final result = await api.connectProviderNone(definitionId);
    await _reload(api);
    return result;
  }

  /// Starts ChatGPT browser or device-code authorization.
  Future<ProviderAuthAttemptDto> startAuth(
    String definitionId,
    String methodId,
  ) async {
    final api = await _requireConnection();
    final attempt = await api.startProviderAuth(
      definitionId,
      methodId,
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
  }) async {
    final api = await _requireConnection();
    final result = await api.createCustomProvider(
      id,
      config,
      apiKey: apiKey,
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
    final ProviderCatalogDto catalog;
    final List<ProviderConnectionDto> connections;
    try {
      catalog = await api.listProviderCatalog();
      connections = await api.listProviderConnections();
    } on CoderClientException catch (error, stackTrace) {
      // A refresh that loses its daemon must not escape as an unhandled error.
      if (ref.mounted) {
        state = AsyncError<ProviderSettingsState?>(error, stackTrace);
      }
      return;
    }
    if (!ref.mounted) return;
    state = AsyncData<ProviderSettingsState?>(
      ProviderSettingsState(
        catalog: catalog,
        connections: connections,
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
