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
    // Registry changes rebuild this provider; keeping the previous catalogs
    // preserves stale-but-usable sections instead of blanking the sidebar on
    // every reconnect. Fresh fetches below overwrite them host by host.
    final previous = state.asData?.value.catalogs;
    final registry = await ref.watch(hostRegistryControllerProvider.future);
    // Hosts resolve independently and merge as they answer: one slow daemon
    // delays only its own catalog section, never the whole sidebar. Consumers
    // treat a connected host with no catalog entry yet as still loading.
    for (final runtime in registry.runtimes.values) {
      if (runtime.connected) unawaited(_loadHost(runtime));
    }
    return UnifiedWorkspaceCatalogState(
      hosts: registry.runtimes,
      catalogs: Map<String, WorkspaceCatalogDto>.unmodifiable(
        <String, WorkspaceCatalogDto>{
          if (previous != null)
            for (final entry in previous.entries)
              if (registry.runtimes.containsKey(entry.key))
                entry.key: entry.value,
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
    // The daemon request above crosses an async boundary, allowing the empty
    // snapshot from build to install before this merge. Do not await this
    // provider's future: a late daemon response may arrive after a registry
    // rebuild has disposed this notifier.
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
/// Loads and edits the `coder.json` worktree hooks of one project.
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
