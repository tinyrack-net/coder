import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/app_identity.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/presentation/host_labels.dart';
import 'package:app/src/features/workspace/application/workspace_controller.dart';
import 'package:app/src/features/workspace/presentation/widgets/worktree_hook_report.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// One workspace row, resolved against the daemon that serves it.
typedef _WorkspaceEntry = ({
  String hostId,
  String hostLabel,
  TinestApi api,
  WorkspaceDto workspace,
  List<WorktreeDto> worktrees,
});

/// Selection value used by the workspace navigation tree.
typedef WorkspaceNavValue = ({
  String hostId,
  String workspaceId,
  String? worktreeId,
});

/// Left navigation listing every workspace and its worktrees.
class WorkspaceSidebar extends ConsumerWidget {
  /// Creates the workspace sidebar.
  const WorkspaceSidebar({
    required this.hosts,
    required this.catalog,
    required this.homeSessions,
    required this.selected,
    required this.treeController,
    required this.onNewWorkspace,
    required this.onSelect,
    required this.onSelectSession,
    required this.onOpenDaemonSettings,
    required this.onConnectDaemon,
    required this.onArchivedSelection,
    super.key,
  });

  /// Daemon runtimes keyed by host ID, or null while the registry still loads.
  ///
  /// Narrower than the whole registry on purpose: the device-local settings
  /// beside it change on every tab switch, and the sidebar must not follow.
  final Map<String, HostRuntimeSnapshot>? hosts;

  /// Catalog of repositories and worktrees per daemon.
  final AsyncValue<UnifiedWorkspaceCatalogState> catalog;

  /// Sessions that belong to no project, across every daemon.
  final AsyncValue<List<HomeSessionEntry>> homeSessions;

  /// Currently open checkout, when any.
  final WorkspaceSelection? selected;

  /// Owns expansion state across workspace route changes.
  final TRTreeNavController<WorkspaceNavValue> treeController;

  /// Opens the new-workspace composer.
  final VoidCallback onNewWorkspace;

  /// Opens one checkout.
  final ValueChanged<WorkspaceSelection> onSelect;

  /// Opens one session that belongs to no project.
  final void Function(WorkspaceSelection selection, String sessionId)
  onSelectSession;

  /// Opens daemon settings when no daemon is configured.
  final VoidCallback onOpenDaemonSettings;

  /// Starts the shared daemon connection flow when none is configured.
  final VoidCallback onConnectDaemon;

  /// Called when the open checkout was archived.
  final VoidCallback onArchivedSelection;

  /// Flattens every connected daemon's catalog into one workspace list.
  ///
  /// Daemons that are not connected are left out entirely; the sidebar shows
  /// their absence as an empty state instead of a per-daemon status row.
  List<_WorkspaceEntry> _entries(
    AppLocalizations l10n,
    List<HostRuntimeSnapshot> runtimes,
    Map<String, WorkspaceCatalogDto> catalogs,
  ) {
    final entries = <_WorkspaceEntry>[];
    for (final host in runtimes) {
      if (!host.connected) continue;
      final hostCatalog = catalogs[host.id];
      if (hostCatalog == null) continue;
      final label = hostLabel(l10n, host);
      for (final workspace in hostCatalog.workspaces) {
        // The home workspace only exists so project-less sessions have a
        // working directory; it is never offered as a project.
        if (workspace.kind == WorkspaceKind.home) continue;
        entries.add((
          hostId: host.id,
          hostLabel: label,
          api: host.api!,
          workspace: workspace,
          worktrees: hostCatalog.worktrees
              .where((item) => item.workspaceId == workspace.id)
              .toList(growable: false),
        ));
      }
    }
    entries.sort((a, b) {
      final byName = a.workspace.name.toLowerCase().compareTo(
        b.workspace.name.toLowerCase(),
      );
      return byName != 0 ? byName : a.hostLabel.compareTo(b.hostLabel);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final runtimes =
        hosts?.values.toList(growable: false) ?? const <HostRuntimeSnapshot>[];
    final catalogs =
        catalog.value?.catalogs ?? const <String, WorkspaceCatalogDto>{};
    final entries = _entries(l10n, runtimes, catalogs);
    final connected = runtimes.any((host) => host.connected);
    // Connected daemons whose catalog has not arrived yet: their sections are
    // still loading, which must never read as "no workspaces".
    final pendingHosts = catalog.value?.hasPendingHosts ?? false;
    final groupsToExpand = <WorkspaceNavValue>{
      if (entries.length == 1)
        (
          hostId: entries.single.hostId,
          workspaceId: entries.single.workspace.id,
          worktreeId: null,
        ),
      if (selected case final selection?)
        (
          hostId: selection.hostId,
          workspaceId: selection.workspaceId,
          worktreeId: null,
        ),
    };
    final collapsedTargets = groupsToExpand
        .where((group) => !treeController.expanded.contains(group))
        .toList(growable: false);
    if (collapsedTargets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        for (final group in collapsedTargets) {
          treeController.setExpanded(group, true);
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TRSpacing.medium,
            TRSpacing.small,
            TRSpacing.medium,
            TRSpacing.small,
          ),
          child: TRButton(
            key: const ValueKey('workspace-new-button'),
            intent: TRIntent.primary,
            onPressed: onNewWorkspace,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(TinestIcons.add),
                const SizedBox(width: TRSpacing.extraSmall),
                TRText(l10n.workspaceNewWorkspace),
              ],
            ),
          ),
        ),
        const TRSeparator(
          key: ValueKey<String>('workspace-sidebar-separator'),
          variant: TRSeparatorVariant.muted,
        ),
        Expanded(
          child: _body(
            context,
            ref,
            l10n,
            runtimes,
            connected,
            pendingHosts,
            entries,
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<HostRuntimeSnapshot> runtimes,
    bool connected,
    bool pendingHosts,
    List<_WorkspaceEntry> entries,
  ) {
    // While the registry or the catalog is still resolving, the sidebar's
    // shape is unknown; a tree-shaped skeleton keeps it from misreporting
    // "no daemons" or "no workspaces" for a state that has not loaded.
    if (hosts == null || (catalog.isLoading && !catalog.hasValue)) {
      return SidebarTreeSkeleton(semanticLabel: l10n.workspaceCatalogLoading);
    }
    if (runtimes.isEmpty) {
      return _SidebarEmptyState(
        message: l10n.workspaceNoDaemons,
        actionLabel: l10n.relayConnectDaemonTitle,
        onAction: onConnectDaemon,
      );
    }
    if (!connected) {
      return _SidebarEmptyState(
        message: l10n.workspaceNoConnectedDaemons,
        actionLabel: l10n.workspaceOpenDaemonSettings,
        onAction: onOpenDaemonSettings,
      );
    }
    final loose = homeSessions.value ?? const <HomeSessionEntry>[];
    if (entries.isEmpty && loose.isEmpty) {
      if (pendingHosts) {
        return SidebarTreeSkeleton(
          semanticLabel: l10n.workspaceCatalogLoading,
        );
      }
      return _SidebarEmptyState(message: l10n.workspaceNoWorkspaces);
    }
    return ListView(
      padding: const EdgeInsets.all(TRSpacing.extraSmall),
      children: <Widget>[
        if (loose.isNotEmpty) ...<Widget>[
          _SidebarSectionLabel(text: l10n.workspaceNoProjectSessions),
          TRTreeNav<String>.controlled(
            key: const ValueKey<String>('workspace-sidebar-home-sessions'),
            pageStorageId: 'workspace-sidebar-home-sessions',
            semanticLabel: l10n.workspaceNoProjectSessions,
            value: null,
            items: <TRTreeNavItem<String>>[
              for (final entry in loose)
                TRTreeNavLeaf<String>(
                  value: entry.session.id,
                  leading: const Icon(TinestIcons.chat),
                  label: TRText.inherit(
                    entry.session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onValueChange: (sessionId) {
              if (sessionId == null) return;
              final entry = loose
                  .where((item) => item.session.id == sessionId)
                  .firstOrNull;
              if (entry == null) return;
              onSelectSession(entry.selection, entry.session.id);
            },
          ),
          const SizedBox(height: TRSpacing.medium),
        ],
        if (entries.isNotEmpty)
          TRTreeNav<WorkspaceNavValue>.controlled(
            key: const ValueKey<String>('workspace-sidebar-tree'),
            pageStorageId: 'workspace-sidebar-tree',
            semanticLabel: l10n.workspacesTitle,
            controller: treeController,
            value: selected == null
                ? null
                : (
                    hostId: selected!.hostId,
                    workspaceId: selected!.workspaceId,
                    worktreeId: selected!.worktreeId,
                  ),
            items: <TRTreeNavItem<WorkspaceNavValue>>[
              for (final entry in entries)
                _treeItem(context, ref, l10n, entry, entries.length),
            ],
            onValueChange: (value) {
              final worktreeId = value?.worktreeId;
              if (value == null || worktreeId == null) return;
              onSelect(
                WorkspaceSelection(
                  hostId: value.hostId,
                  workspaceId: value.workspaceId,
                  worktreeId: worktreeId,
                ),
              );
            },
          ),
      ],
    );
  }

  TRTreeNavItem<WorkspaceNavValue> _treeItem(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    _WorkspaceEntry entry,
    int workspaceCount,
  ) {
    final workspace = entry.workspace;
    return TRTreeNavGroup<WorkspaceNavValue>(
      value: (
        hostId: entry.hostId,
        workspaceId: workspace.id,
        worktreeId: null,
      ),
      initiallyExpanded:
          workspaceCount == 1 || selected?.workspaceId == workspace.id,
      leading: Icon(
        workspace.kind == WorkspaceKind.git
            ? TinestIcons.worktree
            : TinestIcons.folder,
      ),
      label: Row(
        children: <Widget>[
          Expanded(child: TRText.inherit(workspace.name)),
          TRMenu.icon(
            key: ValueKey<String>('workspace-menu-${workspace.id}'),
            icon: const Icon(TinestIcons.more),
            label: l10n.workspaceProjectMenu,
            menuChildren: <Widget>[
              TRMenuItem(
                key: ValueKey<String>(
                  'workspace-unregister-${workspace.id}',
                ),
                onPressed: () => unawaited(
                  _unregisterWorkspace(context, ref, entry),
                ),
                child: TRText.inherit(l10n.workspaceUnregister),
              ),
            ],
          ),
        ],
      ),
      description: TRText.inherit(
        '${entry.hostLabel} · ${workspace.rootPath}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: <TRTreeNavItem<WorkspaceNavValue>>[
        for (final worktree in entry.worktrees)
          TRTreeNavLeaf<WorkspaceNavValue>(
            value: (
              hostId: entry.hostId,
              workspaceId: workspace.id,
              worktreeId: worktree.id,
            ),
            leading: Icon(
              worktree.kind == WorktreeKind.checkout
                  ? TinestIcons.workspace
                  : TinestIcons.branch,
            ),
            label: TRText.inherit(worktree.branch ?? worktree.name),
            description: TRText.inherit(
              worktree.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Archive is the only row action, so the workspace root keeps no
            // menu at all rather than an empty one.
            trailing: isArchivableWorktreeKind(worktree.kind)
                ? TRMenu.icon(
                    key: ValueKey<String>('worktree-menu-${worktree.id}'),
                    icon: const Icon(TinestIcons.more),
                    label: l10n.workspaceWorktreeMenu,
                    menuChildren: <Widget>[
                      TRMenuItem(
                        onPressed: () => unawaited(
                          _archiveWorktree(context, ref, entry, worktree),
                        ),
                        child: TRText.inherit(l10n.workspaceArchive),
                      ),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Future<void> _archiveWorktree(
    BuildContext context,
    WidgetRef ref,
    _WorkspaceEntry entry,
    WorktreeDto worktree,
  ) async {
    final l10n = AppLocalizations.of(context);
    final preview = await entry.api.workspaces.previewWorktreeArchive(
      worktree.id,
    );
    if (!context.mounted) return;
    if (preview.runningSessionCount > 0) {
      await showTRDialog<void>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: TRText.inherit(l10n.workspaceArchiveBlockedTitle),
          content: TRText.inherit(
            l10n.workspaceArchiveBlockedBody(preview.runningSessionCount),
          ),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context),
              child: TRText.inherit(l10n.commonConfirm),
            ),
          ],
        ),
      );
      return;
    }
    final risky = preview.dirty || preview.unpushedCommitCount > 0;
    final dirtyWarning = preview.dirty ? l10n.workspaceArchiveDirty : '';
    final unpushedWarning = preview.unpushedCommitCount > 0
        ? l10n.workspaceArchiveUnpushed(preview.unpushedCommitCount)
        : '';
    final removalWarning = preview.removesDirectory
        ? l10n.workspaceArchiveRemovesDirectory(AppIdentity.name)
        : l10n.workspaceArchiveKeepsDirectory;
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.workspaceArchiveTitle(worktree.name)),
        content: TRText.inherit('$dirtyWarning$unpushedWarning$removalWarning'),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            key: const ValueKey<String>('worktree-archive-confirm'),
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(
              risky ? l10n.workspaceArchiveRisky : l10n.workspaceArchive,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    WorktreeResultDto? archived;
    final succeeded = await ref
        .read(toastMessengerProvider)
        .run(
          () async => archived = await entry.api.workspaces.archiveWorktree(
            worktree.id,
            force: risky,
          ),
          failure: l10n.workspaceArchiveFailed,
          success: l10n.commonDeleted,
          id: 'worktree-archive',
        );
    if (!succeeded || archived == null) return;
    // Archiving the selected worktree can unmount this sidebar, and reading a
    // provider after that throws. Whatever replaces it reads the catalog
    // itself, so an unmounted sidebar has nothing left to do here.
    if (!context.mounted) return;
    await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .refreshHost(entry.hostId);
    // Teardown never blocks the archive, so surface failures afterwards.
    if (context.mounted) {
      reportWorktreeHookFailure(context, archived!.hookRuns);
    }
    if (context.mounted && selected?.worktreeId == worktree.id) {
      onArchivedSelection();
    }
  }

  Future<void> _unregisterWorkspace(
    BuildContext context,
    WidgetRef ref,
    _WorkspaceEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final workspace = entry.workspace;
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: TRText.inherit(l10n.workspaceUnregisterTitle(workspace.name)),
        content: TRText.inherit(
          l10n.workspaceUnregisterBody(AppIdentity.name),
        ),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: TRText.inherit(l10n.commonCancel),
          ),
          TRButton(
            key: const ValueKey<String>('workspace-unregister-confirm'),
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: TRText.inherit(l10n.workspaceUnregister),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Reported rather than swallowed: the user has just confirmed a
    // destructive action, and a refusal that says nothing is indistinguishable
    // from one that worked.
    final unregistered = await ref
        .read(toastMessengerProvider)
        .run(
          () => entry.api.workspaces.unregisterWorkspace(workspace.id),
          failure: l10n.workspaceUnregisterFailed,
          success: l10n.commonDeleted,
          id: 'workspace-unregister',
        );
    // Same unmount hazard as archiving.
    if (!unregistered || !context.mounted) return;
    ref.invalidate(workspaceCatalogControllerProvider);
    if (selected?.workspaceId == workspace.id) onArchivedSelection();
  }
}

/// Heading that separates the project tree from sessions without a project.
class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.small,
      TRSpacing.extraSmall,
    ),
    child: TRText(
      text,
      variant: TRTextVariant.label,
      color: TRTextColor.muted,
    ),
  );
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;

  /// Offered only when daemon settings are what the user needs next.
  final String? actionLabel;

  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final onAction = this.onAction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TRSpacing.extraLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TRText(message, align: TRTextAlign.center),
            if (onAction != null) ...<Widget>[
              const SizedBox(height: TRSpacing.medium),
              TRButton(
                appearance: TRAppearance.outline,
                onPressed: onAction,
                child: TRText.inherit(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
