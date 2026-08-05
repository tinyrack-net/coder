import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/workspace/worktree_hook_report.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// One workspace row, resolved against the daemon that serves it.
typedef _WorkspaceEntry = ({
  String hostId,
  String hostLabel,
  CoderApi api,
  WorkspaceDto workspace,
  List<WorktreeDto> worktrees,
});

typedef _WorkspaceNavValue = ({
  String hostId,
  String workspaceId,
  String? worktreeId,
});

/// Left navigation listing every workspace and its worktrees.
class WorkspaceSidebar extends ConsumerWidget {
  /// Creates the workspace sidebar.
  const WorkspaceSidebar({
    required this.registry,
    required this.catalog,
    required this.selected,
    required this.onNewWorkspace,
    required this.onSelect,
    required this.onOpenDaemonSettings,
    required this.onArchivedSelection,
    super.key,
  });

  /// Daemon profiles and their runtimes.
  final HostRegistryState? registry;

  /// Catalog of repositories and worktrees per daemon.
  final AsyncValue<UnifiedWorkspaceCatalogState> catalog;

  /// Currently open checkout, when any.
  final WorkspaceSelection? selected;

  /// Opens the new-workspace composer.
  final VoidCallback onNewWorkspace;

  /// Opens one checkout.
  final ValueChanged<WorkspaceSelection> onSelect;

  /// Opens daemon settings when no daemon is configured.
  final VoidCallback onOpenDaemonSettings;

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
        registry?.runtimes.values.toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final catalogs =
        catalog.value?.catalogs ?? const <String, WorkspaceCatalogDto>{};
    final entries = _entries(l10n, runtimes, catalogs);
    final connected = runtimes.any((host) => host.connected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: TRButton(
            key: const ValueKey('workspace-new-button'),
            intent: TRIntent.primary,
            onPressed: onNewWorkspace,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(CoderIcons.add, size: 18),
                const SizedBox(width: TRSpacing.extraSmall),
                Text(l10n.workspaceNewWorkspace),
              ],
            ),
          ),
        ),
        const TRSeparator(
          key: ValueKey<String>('workspace-sidebar-separator'),
          variant: TRSeparatorVariant.muted,
        ),
        Expanded(
          child: _body(context, ref, l10n, runtimes, connected, entries),
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
    List<_WorkspaceEntry> entries,
  ) {
    if (runtimes.isEmpty) {
      return _SidebarEmptyState(
        message: l10n.workspaceNoDaemons,
        onSettings: onOpenDaemonSettings,
      );
    }
    if (!connected) {
      return _SidebarEmptyState(
        message: l10n.workspaceNoConnectedDaemons,
        onSettings: onOpenDaemonSettings,
      );
    }
    if (entries.isEmpty) {
      return _SidebarEmptyState(message: l10n.workspaceNoWorkspaces);
    }
    return ListView(
      padding: const EdgeInsets.all(TRSpacing.extraSmall),
      children: <Widget>[
        TRTreeNav<_WorkspaceNavValue>.controlled(
          key: const ValueKey<String>('workspace-sidebar-tree'),
          pageStorageId: 'workspace-sidebar-tree',
          semanticLabel: l10n.workspacesTitle,
          value: selected == null
              ? null
              : (
                  hostId: selected!.hostId,
                  workspaceId: selected!.workspaceId,
                  worktreeId: selected!.worktreeId,
                ),
          items: <TRTreeNavItem<_WorkspaceNavValue>>[
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

  TRTreeNavItem<_WorkspaceNavValue> _treeItem(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    _WorkspaceEntry entry,
    int workspaceCount,
  ) {
    final workspace = entry.workspace;
    return TRTreeNavGroup<_WorkspaceNavValue>(
      value: (
        hostId: entry.hostId,
        workspaceId: workspace.id,
        worktreeId: null,
      ),
      initiallyExpanded:
          workspaceCount == 1 || selected?.workspaceId == workspace.id,
      leading: Icon(
        workspace.kind == WorkspaceKind.git
            ? CoderIcons.worktree
            : CoderIcons.folder,
      ),
      label: Row(
        children: <Widget>[
          Expanded(child: Text(workspace.name)),
          TRMenu(
            key: ValueKey<String>('workspace-menu-${workspace.id}'),
            trigger: Icon(
              CoderIcons.more,
              semanticLabel: l10n.workspaceProjectMenu,
            ),
            menuChildren: <Widget>[
              TRMenuItem(
                key: ValueKey<String>(
                  'workspace-unregister-${workspace.id}',
                ),
                onPressed: () => unawaited(
                  _unregisterWorkspace(context, ref, entry),
                ),
                child: Text(l10n.workspaceUnregister),
              ),
            ],
          ),
        ],
      ),
      description: Text(
        '${entry.hostLabel} · ${workspace.rootPath}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      children: <TRTreeNavItem<_WorkspaceNavValue>>[
        for (final worktree in entry.worktrees)
          TRTreeNavLeaf<_WorkspaceNavValue>(
            value: (
              hostId: entry.hostId,
              workspaceId: workspace.id,
              worktreeId: worktree.id,
            ),
            leading: Icon(
              worktree.kind == WorktreeKind.checkout
                  ? CoderIcons.workspace
                  : CoderIcons.branch,
            ),
            label: Text(worktree.branch ?? worktree.name),
            description: Text(
              worktree.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TRMenu(
              key: ValueKey<String>('worktree-menu-${worktree.id}'),
              trigger: Icon(
                CoderIcons.more,
                semanticLabel: l10n.workspaceWorktreeMenu,
              ),
              menuChildren: <Widget>[
                TRMenuItem(
                  onPressed: () => unawaited(
                    _archiveWorktree(context, ref, entry, worktree),
                  ),
                  child: Text(l10n.workspaceArchive),
                ),
              ],
            ),
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
    final preview = await entry.api.previewWorktreeArchive(worktree.id);
    if (!context.mounted) return;
    if (preview.runningSessionCount > 0) {
      await showTRDialog<void>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: Text(l10n.workspaceArchiveBlockedTitle),
          content: Text(
            l10n.workspaceArchiveBlockedBody(preview.runningSessionCount),
          ),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonConfirm),
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
        ? l10n.workspaceArchiveRemovesDirectory
        : l10n.workspaceArchiveKeepsDirectory;
    final confirmed = await showTRDialog<bool>(
      context: context,
      builder: (context) => TRAlertDialog(
        title: Text(l10n.workspaceArchiveTitle(worktree.name)),
        content: Text('$dirtyWarning$unpushedWarning$removalWarning'),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TRButton(
            key: const ValueKey<String>('worktree-archive-confirm'),
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              risky ? l10n.workspaceArchiveRisky : l10n.workspaceArchive,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final archived = await entry.api.archiveWorktree(worktree.id, force: risky);
    await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .refreshHost(entry.hostId);
    // Teardown never blocks the archive, so surface failures afterwards.
    if (context.mounted) {
      reportWorktreeHookFailure(context, archived.hookRuns);
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
        title: Text(l10n.workspaceUnregisterTitle(workspace.name)),
        content: Text(l10n.workspaceUnregisterBody),
        actions: <TRButton>[
          TRButton(
            appearance: TRAppearance.ghost,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TRButton(
            key: const ValueKey<String>('workspace-unregister-confirm'),
            intent: TRIntent.primary,
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.workspaceUnregister),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await entry.api.unregisterWorkspace(workspace.id);
    ref.invalidate(workspaceCatalogControllerProvider);
    if (selected?.workspaceId == workspace.id) onArchivedSelection();
  }
}

class _SidebarEmptyState extends StatelessWidget {
  const _SidebarEmptyState({required this.message, this.onSettings});

  final String message;

  /// Offered only when daemon settings are what the user needs next.
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final onSettings = this.onSettings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            if (onSettings != null) ...<Widget>[
              const SizedBox(height: 12),
              TRButton(
                appearance: TRAppearance.outline,
                onPressed: onSettings,
                child: Text(
                  AppLocalizations.of(context).workspaceOpenDaemonSettings,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
