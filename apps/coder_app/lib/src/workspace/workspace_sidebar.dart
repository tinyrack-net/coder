import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_labels.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/workspace/worktree_hook_report.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Left navigation listing every daemon, repository, and worktree.
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

  @override
  Widget build(BuildContext context) {
    final runtimes =
        registry?.runtimes.values.toList(growable: false) ??
        const <HostRuntimeSnapshot>[];
    final catalogs =
        catalog.value?.catalogs ?? const <String, WorkspaceCatalogDto>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: FilledButton.icon(
            key: const ValueKey('workspace-new-button'),
            onPressed: onNewWorkspace,
            icon: const Icon(Icons.add, size: 18),
            label: Text(AppLocalizations.of(context).workspaceNewWorkspace),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: runtimes.isEmpty
              ? _NoDaemonState(onSettings: onOpenDaemonSettings)
              : ListView(
                  children: <Widget>[
                    for (final host in runtimes)
                      _HostTreeNode(
                        host: host,
                        catalog: catalogs[host.id],
                        selected: selected,
                        onSelect: onSelect,
                        onArchivedSelection: onArchivedSelection,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HostTreeNode extends StatelessWidget {
  const _HostTreeNode({
    required this.host,
    required this.catalog,
    required this.selected,
    required this.onSelect,
    required this.onArchivedSelection,
  });

  final HostRuntimeSnapshot host;
  final WorkspaceCatalogDto? catalog;
  final WorkspaceSelection? selected;
  final ValueChanged<WorkspaceSelection> onSelect;
  final VoidCallback onArchivedSelection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaces = catalog?.workspaces ?? const <WorkspaceDto>[];
    if (!host.connected) {
      final error = hostErrorText(l10n, host);
      return ListTile(
        leading: const Icon(Icons.cloud_off_outlined),
        title: Text(hostLabel(l10n, host)),
        subtitle: Text(
          '${_hostStatusLabel(l10n, host.status)}'
          '${error == null ? '' : ' · $error'}',
        ),
      );
    }
    return ExpansionTile(
      initiallyExpanded: true,
      leading: const Icon(Icons.dns_outlined),
      title: Text(hostLabel(l10n, host)),
      subtitle: Text(_hostStatusLabel(l10n, host.status)),
      children: <Widget>[
        for (final workspace in workspaces)
          _RepositoryTreeNode(
            onSelect: onSelect,
            onArchivedSelection: onArchivedSelection,
            hostId: host.id,
            workspace: workspace,
            worktrees: catalog!.worktrees
                .where((item) => item.workspaceId == workspace.id)
                .toList(growable: false),
            selected: selected,
          ),
      ],
    );
  }
}

class _RepositoryTreeNode extends ConsumerWidget {
  const _RepositoryTreeNode({
    required this.onSelect,
    required this.onArchivedSelection,
    required this.hostId,
    required this.workspace,
    required this.worktrees,
    required this.selected,
  });

  final ValueChanged<WorkspaceSelection> onSelect;
  final VoidCallback onArchivedSelection;
  final String hostId;
  final WorkspaceDto workspace;
  final List<WorktreeDto> worktrees;
  final WorkspaceSelection? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        initiallyExpanded: selected?.workspaceId == workspace.id,
        leading: Icon(
          workspace.kind == WorkspaceKind.git
              ? Icons.account_tree_outlined
              : Icons.folder_outlined,
        ),
        title: Text(workspace.name),
        subtitle: Text(
          workspace.rootPath,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: <Widget>[
          for (final worktree in worktrees)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 48, right: 12),
              selected:
                  selected?.hostId == hostId &&
                  selected?.worktreeId == worktree.id,
              leading: Icon(
                worktree.kind == WorktreeKind.checkout
                    ? Icons.home_work_outlined
                    : Icons.call_split_outlined,
                size: 20,
              ),
              title: Text(worktree.branch ?? worktree.name),
              subtitle: Text(
                worktree.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                tooltip: l10n.workspaceWorktreeMenu,
                onSelected: (action) {
                  if (action == 'archive') {
                    unawaited(_archiveWorktree(context, ref, worktree));
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'archive',
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
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.workspaceArchiveBlockedTitle),
          content: Text(
            l10n.workspaceArchiveBlockedBody(preview.runningSessionCount),
          ),
          actions: <Widget>[
            TextButton(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workspaceArchiveTitle(worktree.name)),
        content: Text('$dirtyWarning$unpushedWarning$removalWarning'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
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

class _NoDaemonState extends StatelessWidget {
  const _NoDaemonState({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(AppLocalizations.of(context).workspaceNoDaemons),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onSettings,
            child: Text(
              AppLocalizations.of(context).workspaceOpenDaemonSettings,
            ),
          ),
        ],
      ),
    ),
  );
}

String _hostStatusLabel(AppLocalizations l10n, HostRuntimeStatus status) =>
    switch (status) {
      HostRuntimeStatus.online => l10n.hostStatusOnline,
      HostRuntimeStatus.connecting => l10n.hostStatusConnecting,
      HostRuntimeStatus.reconnecting => l10n.hostStatusReconnecting,
      HostRuntimeStatus.offline => l10n.hostStatusOffline,
      HostRuntimeStatus.error => l10n.hostStatusError,
      HostRuntimeStatus.conflict => l10n.hostStatusConflict,
      HostRuntimeStatus.idle => l10n.hostStatusIdle,
    };
