import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_list_row.dart';
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
  WorkspaceDto workspace,
  List<WorktreeDto> worktrees,
});

/// Left navigation listing every workspace and its worktrees.
class WorkspaceSidebar extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            uiSize: TRUiSize.sm,
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
        const TRSeparator(),
        Expanded(child: _body(context, l10n, runtimes, connected, entries)),
      ],
    );
  }

  Widget _body(
    BuildContext context,
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
      children: <Widget>[
        for (final entry in entries)
          _WorkspaceTreeNode(
            key: ValueKey<String>(
              'workspace-tree-${entry.hostId}-${entry.workspace.id}',
            ),
            onSelect: onSelect,
            onArchivedSelection: onArchivedSelection,
            hostId: entry.hostId,
            hostLabel: entry.hostLabel,
            workspace: entry.workspace,
            worktrees: entry.worktrees,
            selected: selected,
            // A lone workspace has no sibling to choose between, so opening it
            // saves the first click on a fresh launch.
            expandedByDefault:
                entries.length == 1 ||
                selected?.workspaceId == entry.workspace.id,
          ),
      ],
    );
  }
}

class _WorkspaceTreeNode extends ConsumerWidget {
  const _WorkspaceTreeNode({
    required this.onSelect,
    required this.onArchivedSelection,
    required this.hostId,
    required this.hostLabel,
    required this.workspace,
    required this.worktrees,
    required this.selected,
    required this.expandedByDefault,
    super.key,
  });

  final ValueChanged<WorkspaceSelection> onSelect;
  final VoidCallback onArchivedSelection;
  final String hostId;
  final String hostLabel;
  final WorkspaceDto workspace;
  final List<WorktreeDto> worktrees;
  final WorkspaceSelection? selected;
  final bool expandedByDefault;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TRSpacing.extraSmall,
        vertical: TRSpacing.extraSmall,
      ),
      child: TRCollapsible(
        defaultOpen: expandedByDefault,
        trigger: Row(
          children: <Widget>[
            Icon(
              workspace.kind == WorkspaceKind.git
                  ? CoderIcons.worktree
                  : CoderIcons.folder,
            ),
            const SizedBox(width: TRSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(workspace.name),
                  Text(
                    '$hostLabel · ${workspace.rootPath}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          children: <Widget>[
            for (final worktree in worktrees)
              CoderListRow(
                contentPadding: const EdgeInsets.only(left: 32, right: 12),
                selected:
                    selected?.hostId == hostId &&
                    selected?.worktreeId == worktree.id,
                leading: Icon(
                  worktree.kind == WorktreeKind.checkout
                      ? CoderIcons.workspace
                      : CoderIcons.branch,
                  size: 20,
                ),
                title: Text(worktree.branch ?? worktree.name),
                subtitle: Text(
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
                        _archiveWorktree(context, ref, worktree),
                      ),
                      child: Text(l10n.workspaceArchive),
                    ),
                  ],
                ),
                onTap: () => onSelect(
                  WorkspaceSelection(
                    hostId: hostId,
                    workspaceId: workspace.id,
                    worktreeId: worktree.id,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveWorktree(
    BuildContext context,
    WidgetRef ref,
    WorktreeDto worktree,
  ) async {
    final l10n = AppLocalizations.of(context);
    final api = await _api(ref);
    final preview = await api.previewWorktreeArchive(worktree.id);
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
              uiSize: TRUiSize.sm,
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
            uiSize: TRUiSize.sm,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TRButton(
            key: const ValueKey<String>('worktree-archive-confirm'),
            intent: TRIntent.primary,
            uiSize: TRUiSize.sm,
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              risky ? l10n.workspaceArchiveRisky : l10n.workspaceArchive,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final archived = await api.archiveWorktree(worktree.id, force: risky);
    await ref
        .read(workspaceCatalogControllerProvider.notifier)
        .refreshHost(hostId);
    // Teardown never blocks the archive, so surface failures afterwards.
    if (context.mounted) {
      reportWorktreeHookFailure(context, archived.hookRuns);
    }
    if (context.mounted && selected?.worktreeId == worktree.id) {
      onArchivedSelection();
    }
  }

  Future<CoderApi> _api(WidgetRef ref) async {
    final runtime = (await ref.read(
      hostRegistryControllerProvider.future,
    )).runtimes[hostId];
    return runtime?.api ??
        (throw StateError('Online daemon connection required.'));
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
                uiSize: TRUiSize.sm,
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
