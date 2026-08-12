import 'dart:async';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:protocol/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_controller.g.dart';

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

  /// Whether any connected host has not delivered its catalog yet.
  ///
  /// Catalogs merge per host as daemons answer, so consumers use this to keep
  /// showing a loading shape instead of misreporting an empty workspace list.
  bool get hasPendingHosts => hosts.values.any(
    (host) => host.connected && !catalogs.containsKey(host.id),
  );

  /// Whether [hostId] is connected but has not delivered its catalog yet.
  bool isHostPending(String hostId) {
    final host = hosts[hostId];
    return host != null && host.connected && !catalogs.containsKey(hostId);
  }

  /// Resolves the implicit home checkout of [hostId], when its daemon has one.
  ///
  /// Sessions the user starts without picking a project live here. A daemon
  /// configured without a user home publishes no home workspace, and callers
  /// use that null to hide the project-less start entirely.
  WorkspaceSelection? homeSelection(String hostId) {
    final catalog = catalogs[hostId];
    if (catalog == null) return null;
    final workspace = catalog.workspaces
        .where((item) => item.kind == WorkspaceKind.home)
        .firstOrNull;
    if (workspace == null) return null;
    final worktree = catalog.worktrees
        .where((item) => item.workspaceId == workspace.id)
        .firstOrNull;
    if (worktree == null) return null;
    return WorkspaceSelection(
      hostId: hostId,
      workspaceId: workspace.id,
      worktreeId: worktree.id,
    );
  }
}

@Riverpod(keepAlive: true)
/// Loads every online daemon catalog without merging daemon-local IDs.
class WorkspaceCatalogController extends _$WorkspaceCatalogController {
  @override
  Future<UnifiedWorkspaceCatalogState> build() async {
    // Watching the runtimes rather than the whole registry keeps a device-local
    // settings write, such as the tab layout saved on every tab switch, from
    // sending the sidebar back to every daemon. A daemon connecting or leaving
    // still rebuilds this; keeping the previous catalogs preserves
    // stale-but-usable sections instead of blanking the sidebar on every
    // reconnect. Fresh fetches below overwrite them host by host.
    // `value`, not `asData`: this build runs while the state is a reload that
    // still carries the previous catalogs, and `asData` would report none.
    final previous = state.value?.catalogs;
    final runtimes = await ref.watch(
      hostRegistryControllerProvider.selectAsync((state) => state.runtimes),
    );
    // Hosts resolve independently and merge as they answer: one slow daemon
    // delays only its own catalog section, never the whole sidebar. Consumers
    // treat a connected host with no catalog entry yet as still loading.
    for (final runtime in runtimes.values) {
      if (runtime.connected) unawaited(_loadHost(runtime));
    }
    return UnifiedWorkspaceCatalogState(
      hosts: runtimes,
      catalogs: Map<String, WorkspaceCatalogDto>.unmodifiable(
        <String, WorkspaceCatalogDto>{
          if (previous != null)
            for (final entry in previous.entries)
              if (runtimes.containsKey(entry.key)) entry.key: entry.value,
        },
      ),
    );
  }

  Future<void> _loadHost(HostRuntimeSnapshot runtime) async {
    WorkspaceCatalogDto catalog;
    try {
      catalog = await runtime.api!.workspaces.getWorkspaceCatalog();
    } on Exception {
      // A daemon that fails to answer settles as an empty section instead of
      // pending forever; the registry's connection state is the surface that
      // reports the failure itself.
      catalog = const WorkspaceCatalogDto(
        workspaces: <WorkspaceDto>[],
        worktrees: <WorktreeDto>[],
      );
    }
    // The empty snapshot from build installs after this notifier returns, so
    // a catalog that answers first waits for it before merging. Check before
    // reading the provider future because a late daemon response may arrive
    // after a registry rebuild has disposed this notifier.
    if (!ref.mounted) return;
    await future;
    if (!ref.mounted) return;
    final current = state.requireValue;
    state = AsyncData<UnifiedWorkspaceCatalogState>(
      UnifiedWorkspaceCatalogState(
        hosts: current.hosts,
        catalogs: Map<String, WorkspaceCatalogDto>.unmodifiable(
          <String, WorkspaceCatalogDto>{
            ...current.catalogs,
            runtime.id: catalog,
          },
        ),
      ),
    );
  }

  /// Registers a folder on the selected daemon and refreshes its catalog.
  Future<WorkspaceRegisterResultDto> register(
    String hostId,
    String rootPath,
  ) async {
    final api = await requireHostApi(ref, hostId);
    final result = await api.workspaces.registerWorkspace(
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
    final api = await requireHostApi(ref, hostId);
    final catalog = await api.workspaces.getWorkspaceCatalog();
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

  /// Archives one checkout and refreshes its host catalog as one operation.
  ///
  /// The sidebar that starts this mutation may be replaced while teardown
  /// hooks run. Keeping the refresh in this keep-alive controller prevents a
  /// successful archive from leaving a stale row behind when that happens.
  Future<WorktreeResultDto> archiveWorktree(
    String hostId,
    String worktreeId, {
    required bool force,
  }) async {
    final api = await requireHostApi(ref, hostId);
    final archived = await api.workspaces.archiveWorktree(
      worktreeId,
      force: force,
    );
    if (ref.mounted) await refreshHost(hostId);
    return archived;
  }
}

@riverpod
/// Lists local Git branches for one repository.
Future<List<GitBranchDto>> gitBranches(
  Ref ref,
  String hostId,
  String workspaceId,
) async {
  final api = await watchHostApi(ref, hostId);
  return api.workspaces.listGitBranches(workspaceId);
}

/// One session that belongs to no project, with the checkout that runs it.
typedef HomeSessionEntry = ({
  WorkspaceSelection selection,
  SessionDto session,
});

/// Orders home sessions newest first, so a fresh one leads the section.
///
/// Kept next to [HomeSessionEntry] because the sidebar and its tests both need
/// the same order.
List<HomeSessionEntry> sortedHomeSessions(List<HomeSessionEntry> entries) =>
    entries.toList()
      ..sort((a, b) => b.session.updatedAt.compareTo(a.session.updatedAt));

@Riverpod(retry: noAutomaticRetry)
/// Loads and edits the `.tinest/config.json` worktree hooks of one project.
class ProjectSettingsController extends _$ProjectSettingsController {
  @override
  Future<ProjectSettingsResultDto> build(
    String hostId,
    String workspaceId,
  ) async {
    final api = await watchHostApi(ref, hostId);
    return api.workspaces.getProjectSettings(workspaceId);
  }

  /// Replaces the worktree hook section on the daemon host.
  Future<void> save(ProjectSettingsDto settings) async {
    final api = await requireHostApi(ref, hostId);
    state = AsyncData<ProjectSettingsResultDto>(
      await api.workspaces.saveProjectSettings(workspaceId, settings),
    );
  }
}
