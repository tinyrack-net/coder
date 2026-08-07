import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/presentation/new_workspace_pane.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/conversation/application/conversation_timeline_controller.dart';
import 'package:coder_app/src/features/conversation/application/subagent_track_model.dart';
import 'package:coder_app/src/features/conversation/domain/composer_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_plan_actions.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:coder_app/src/features/conversation/presentation/goal_status_bar.dart';
import 'package:coder_app/src/features/conversation/presentation/subagents/subagent_status_icon.dart';
import 'package:coder_app/src/features/conversation/presentation/subagents/subagent_track.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/composer_completion_scope.dart';
import 'package:coder_app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/providers/application/provider_settings_controller.dart';
import 'package:coder_app/src/features/providers/application/session_model_options.dart';
import 'package:coder_app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:coder_app/src/features/sessions/application/sessions_controller.dart';
import 'package:coder_app/src/features/terminals/application/terminals_controller.dart';
import 'package:coder_app/src/features/terminals/presentation/coder_terminal_view.dart';
import 'package:coder_app/src/features/workspace/application/workspace_controller.dart';
import 'package:coder_app/src/features/workspace/presentation/widgets/workspace_sidebar.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:coder_app/src/shared/presentation/coder_list_row.dart';
import 'package:coder_app/src/shared/presentation/coder_page_shell.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:termworld/termworld.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Unified host/repository/worktree tree and session-tab workspace.
class WorkspacePage extends ConsumerStatefulWidget {
  /// Creates a workspace page.
  const WorkspacePage({
    this.selection,
    this.requestedAgentId,
    this.requestedTerminalId,
    this.compose = false,
    super.key,
  });

  /// Whether the right pane opens the new-workspace composer directly.
  final bool compose;

  /// Selected checkout, if any.
  final WorkspaceSelection? selection;

  /// Session requested by the route.
  final String? requestedAgentId;

  /// Terminal requested by the route.
  final String? requestedTerminalId;

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  /// Whether this state already queued the saved-worktree restore.
  bool _restoreScheduled = false;

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(hostRegistryControllerProvider);
    final catalog = ref.watch(workspaceCatalogControllerProvider);
    final collapsed = registry.value?.settings.sidebarCollapsed ?? false;
    _restoreSelection(registry.value, catalog.value);
    return LayoutBuilder(
      builder: (context, pageConstraints) {
        final compact =
            pageConstraints.maxWidth < CoderLayoutMetrics.compactBreakpoint;
        final showsCompactDetail =
            compact && (widget.selection != null || widget.compose);
        return PopScope<Object?>(
          canPop: !showsCompactDetail,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && showsCompactDetail) {
              const WorkspaceHomeRoute().replace(context);
            }
          },
          child: CoderPageShell(
            appBar: CoderPageHeader(
              // Compact Back and the desktop toggle share the one stable
              // navigation position at the very top left.
              leading: showsCompactDetail
                  ? TRIconButton(
                      key: const ValueKey<String>('workspace-back-button'),
                      appearance: TRAppearance.ghost,
                      label: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () =>
                          const WorkspaceHomeRoute().replace(context),
                      icon: const Icon(CoderIcons.back),
                    )
                  : compact
                  ? null
                  : TRIconButton(
                      appearance: TRAppearance.ghost,
                      key: const ValueKey('workspace-sidebar-toggle'),
                      label: collapsed
                          ? AppLocalizations.of(context).workspaceSidebarExpand
                          : AppLocalizations.of(
                              context,
                            ).workspaceSidebarCollapse,
                      onPressed: () =>
                          unawaited(_setSidebarCollapsed(!collapsed)),
                      icon: Icon(
                        collapsed ? CoderIcons.menu : CoderIcons.menuOpen,
                      ),
                    ),
              title: TRText.inherit(
                AppLocalizations.of(context).workspacesTitle,
              ),
              actions: <Widget>[
                TRIconButton(
                  key: const ValueKey('workspace-settings-button'),
                  appearance: TRAppearance.ghost,
                  label: AppLocalizations.of(context).settingsTitle,
                  onPressed: () {
                    if (compact) {
                      unawaited(const SettingsHomeRoute().push<void>(context));
                      return;
                    }
                    final hostId = widget.selection?.hostId;
                    unawaited(
                      hostId == null
                          ? const DaemonSettingsRoute().push<void>(context)
                          : ProviderSettingsRoute(
                              hostId: hostId,
                            ).push<void>(context),
                    );
                  },
                  icon: const Icon(CoderIcons.settings),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final sidebar = WorkspaceSidebar(
                  registry: registry.value,
                  catalog: catalog,
                  homeSessions: _homeSessions(catalog.value),
                  selected: widget.selection,
                  onNewWorkspace: () =>
                      const WorkspaceHomeRoute(compose: true).replace(context),
                  onSelect: (selection) => _goWorktree(context, selection),
                  onSelectSession: (selection, sessionId) =>
                      _goSession(context, selection, sessionId),
                  onOpenDaemonSettings: () => unawaited(
                    const DaemonSettingsRoute().push<void>(context),
                  ),
                  onArchivedSelection: () =>
                      const WorkspaceHomeRoute().replace(context),
                );
                final detail = widget.selection == null
                    ? NewWorkspacePane(
                        onStarted: (selection, session) =>
                            _goSession(context, selection, session.id),
                      )
                    : _SessionArea(
                        // Replacing a checkout location preserves this page.
                        // Key its session area so tabs, conversations, and
                        // terminals start clean on a different checkout.
                        key: ValueKey<WorkspaceSelection>(widget.selection!),
                        selection: widget.selection!,
                        requestedAgentId: widget.requestedAgentId,
                        requestedTerminalId: widget.requestedTerminalId,
                        mobile:
                            constraints.maxWidth <
                            CoderLayoutMetrics.compactBreakpoint,
                      );
                if (constraints.maxWidth <
                    CoderLayoutMetrics.compactBreakpoint) {
                  return widget.selection == null && !widget.compose
                      ? sidebar
                      : detail;
                }
                return Row(
                  children: <Widget>[
                    // Owning its width lets the sidebar animate its collapse
                    // instead of dropping out of the row.
                    TRAppShellSidebar(
                      key: const ValueKey<String>('workspace-sidebar-surface'),
                      collapsed: collapsed,
                      scroll: false,
                      child: sidebar,
                    ),
                    Expanded(child: detail),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Gathers the sessions that belong to no project across every daemon.
  ///
  /// Each daemon's home checkout is an ordinary checkout, so this reuses the
  /// same per-checkout session family the session area does rather than adding
  /// a second source of truth.
  AsyncValue<List<HomeSessionEntry>> _homeSessions(
    UnifiedWorkspaceCatalogState? catalog,
  ) {
    if (catalog == null) {
      return const AsyncValue<List<HomeSessionEntry>>.loading();
    }
    final entries = <HomeSessionEntry>[];
    for (final hostId in catalog.catalogs.keys) {
      final selection = catalog.homeSelection(hostId);
      if (selection == null) continue;
      final sessions = ref.watch(
        sessionsControllerProvider(hostId, selection.worktreeId),
      );
      for (final session in sessions.value ?? const <SessionDto>[]) {
        entries.add((selection: selection, session: session));
      }
    }
    return AsyncValue<List<HomeSessionEntry>>.data(sortedHomeSessions(entries));
  }

  Future<void> _setSidebarCollapsed(bool collapsed) => ref
      .read(hostRegistryControllerProvider.notifier)
      .setSidebarCollapsed(collapsed: collapsed);

  void _restoreSelection(
    HostRegistryState? registry,
    UnifiedWorkspaceCatalogState? catalog,
  ) {
    // Opening the composer is an explicit choice; never bounce out of it.
    if (widget.compose || widget.selection != null) return;
    if (_restoreScheduled) return;
    if (ref.read(selectionRestoreControllerProvider)) return;
    final saved = registry?.settings.lastWorktree;
    if (saved == null || catalog == null) return;
    final exists =
        catalog.catalogs[saved.hostId]?.worktrees.any(
          (item) =>
              item.id == saved.worktreeId &&
              item.workspaceId == saved.workspaceId,
        ) ??
        false;
    if (!exists) return;
    // This runs from build, where writing a provider is not allowed, so the
    // restore is both marked and navigated after the frame. The local flag
    // covers the frames in between, which the provider cannot yet reject.
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectionRestoreControllerProvider.notifier).markConsumed();
      _goWorktree(context, saved);
    });
  }
}

class _SessionArea extends ConsumerStatefulWidget {
  const _SessionArea({
    required this.selection,
    this.requestedAgentId,
    this.requestedTerminalId,
    this.mobile = false,
    super.key,
  });

  final WorkspaceSelection selection;
  final String? requestedAgentId;
  final String? requestedTerminalId;
  final bool mobile;

  @override
  ConsumerState<_SessionArea> createState() => _SessionAreaState();
}

class _SessionAreaState extends ConsumerState<_SessionArea> {
  // Selecting a session or terminal replaces the location rather than pushing,
  // so this state outlives the change. Remember each opened target so closing
  // a local tab is not immediately undone while the route is being replaced.
  String? _openedAgentId;
  String? _openedTerminalId;

  @override
  Widget build(BuildContext context) {
    final provider = sessionTabsControllerProvider(widget.selection);
    final value = ref.watch(provider);
    final workspace = value.asData?.value;
    _openRequestedRoute(provider, workspace);
    if (workspace == null) return const Center(child: TRSpinner());
    return widget.mobile
        ? _buildMobile(context, workspace)
        : _buildNode(context, workspace, workspace.root);
  }

  void _openRequestedRoute(
    SessionTabsControllerProvider provider,
    SessionTabsState? workspace,
  ) {
    if (widget.requestedAgentId != null &&
        widget.requestedAgentId != _openedAgentId &&
        workspace != null &&
        workspace.sessions.any((item) => item.id == widget.requestedAgentId)) {
      _openedAgentId = widget.requestedAgentId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(ref.read(provider.notifier).open(widget.requestedAgentId!));
        }
      });
    }
    if (widget.requestedTerminalId != null &&
        widget.requestedTerminalId != _openedTerminalId &&
        workspace != null &&
        workspace.terminals.any(
          (item) => item.id == widget.requestedTerminalId,
        )) {
      _openedTerminalId = widget.requestedTerminalId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref
                .read(provider.notifier)
                .openTerminal(widget.requestedTerminalId!),
          );
        }
      });
    }
  }

  Widget _buildNode(
    BuildContext context,
    SessionTabsState workspace,
    WorkspacePaneNode node,
  ) => switch (node) {
    PaneNode() => _buildPane(context, workspace, node),
    WorkspaceSplitNode() => TRSplitView(
      key: ValueKey<String>('workspace-split-${node.id}'),
      axis: node.axis == WorkspaceSplitAxis.horizontal
          ? Axis.horizontal
          : Axis.vertical,
      ratio: node.ratio,
      separatorLabel: AppLocalizations.of(context).workspaceResizePanes,
      onRatioChanged: (ratio) => unawaited(
        ref
            .read(sessionTabsControllerProvider(widget.selection).notifier)
            .resize(node.id, ratio),
      ),
      onRatioChangeEnd: (_) => unawaited(
        ref
            .read(sessionTabsControllerProvider(widget.selection).notifier)
            .commitResize(),
      ),
      first: _buildNode(context, workspace, node.first),
      second: _buildNode(context, workspace, node.second),
    ),
  };

  Widget _buildPane(
    BuildContext context,
    SessionTabsState workspace,
    PaneNode pane,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final canSplitRight =
          constraints.maxWidth >= TRMeasurements.splitPaneMinExtent * 2;
      final canSplitDown =
          constraints.maxHeight >= TRMeasurements.splitPaneMinExtent * 2;
      final firstPane = pane.id == workspace.panes.first.id;
      return KeyedSubtree(
        key: const ValueKey<String>('workspace-pane'),
        child: Column(
          children: <Widget>[
            TRTabs.bar(
              key: ValueKey<String>(
                firstPane
                    ? 'session-tab-strip'
                    : 'session-tab-strip-${pane.id}',
              ),
              semanticLabel: AppLocalizations.of(context).workspaceAllSessions,
              value: _controlValue(workspace.tabs[pane.activeTabId]!),
              onValueChange: (value) => unawaited(
                _activate(
                  pane.id,
                  pane.tabIds.firstWhere(
                    (id) => _controlValue(workspace.tabs[id]!) == value,
                  ),
                ),
              ),
              tabs: <TRTabsTab>[
                for (final tabId in pane.tabIds)
                  _tab(context, workspace, workspace.tabs[tabId]!),
              ],
              dragConfiguration: TRTabsDragConfiguration(
                groupId: pane.id,
                onDrop: (details) => unawaited(_dropTab(workspace, details)),
              ),
              actions: <Widget>[
                _newTabMenu(context, pane.id, firstPane),
                TRIconButton(
                  key: ValueKey<String>(
                    firstPane
                        ? 'workspace-split-right'
                        : 'workspace-split-right-${pane.id}',
                  ),
                  appearance: TRAppearance.ghost,
                  label: AppLocalizations.of(context).workspaceSplitRight,
                  onPressed: canSplitRight
                      ? () => unawaited(
                          _split(pane.id, WorkspaceSplitAxis.horizontal),
                        )
                      : null,
                  icon: const Icon(CoderIcons.splitRight),
                ),
                TRIconButton(
                  key: ValueKey<String>(
                    firstPane
                        ? 'workspace-split-down'
                        : 'workspace-split-down-${pane.id}',
                  ),
                  appearance: TRAppearance.ghost,
                  label: AppLocalizations.of(context).workspaceSplitDown,
                  onPressed: canSplitDown
                      ? () => unawaited(
                          _split(pane.id, WorkspaceSplitAxis.vertical),
                        )
                      : null,
                  icon: const Icon(CoderIcons.splitDown),
                ),
                _allTabsMenu(context, workspace, pane, firstPane),
              ],
            ),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey<String>('workspace-content-${pane.activeTabId}'),
                child: _content(workspace, workspace.tabs[pane.activeTabId]!),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _buildMobile(BuildContext context, SessionTabsState workspace) {
    final entry = workspace.focusedTab!;
    return Column(
      children: <Widget>[
        GestureDetector(
          key: const ValueKey<String>('workspace-mobile-tab-trigger'),
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_showTabSheet()),
          child: TRTabs.bar(
            semanticLabel: AppLocalizations.of(context).workspaceAllSessions,
            value: _controlValue(entry),
            onValueChange: (_) => unawaited(_showTabSheet()),
            tabs: <TRTabsTab>[
              _tab(context, workspace, entry, closable: false),
            ],
            actions: <Widget>[
              _newTabMenu(context, workspace.focusedPaneId, true),
            ],
          ),
        ),
        Expanded(child: _content(workspace, entry)),
      ],
    );
  }

  TRTabsTab _tab(
    BuildContext context,
    SessionTabsState workspace,
    WorkspaceTabEntry entry, {
    bool closable = true,
  }) => switch (entry.target) {
    SessionTabTarget(:final sessionId) => () {
      final session = workspace.sessions.firstWhere(
        (item) => item.id == sessionId,
      );
      final subagent = isSubagentSession(session);
      return TRTabsTab(
        value: _controlValue(entry),
        label: subagent ? session.taskName ?? session.title : session.title,
        leading: subagent
            ? SubagentStatusIcon(lifecycle: session.lifecycle)
            : null,
        onClose: closable ? () => unawaited(_closeEntry(entry)) : null,
        closeLabel: AppLocalizations.of(context).workspaceCloseTab,
      );
    }(),
    TerminalTabTarget(:final terminalId) => TRTabsTab(
      value: _controlValue(entry),
      label: workspace.terminals
          .firstWhere((item) => item.id == terminalId)
          .title,
      leading: const Icon(CoderIcons.terminal),
      onClose: closable ? () => unawaited(_closeEntry(entry)) : null,
      closeLabel: AppLocalizations.of(context).workspaceCloseTab,
    ),
    DraftTabTarget() => TRTabsTab(
      value: _controlValue(entry),
      label: AppLocalizations.of(context).workspaceNewTab,
      leading: const Icon(CoderIcons.chat),
      onClose: closable ? () => unawaited(_closeEntry(entry)) : null,
      closeLabel: AppLocalizations.of(context).workspaceCloseTab,
    ),
  };

  String _controlValue(WorkspaceTabEntry entry) => switch (entry.target) {
    SessionTabTarget(:final sessionId) => sessionId,
    TerminalTabTarget(:final terminalId) => terminalId,
    DraftTabTarget() => entry.id,
  };

  Widget _content(SessionTabsState workspace, WorkspaceTabEntry entry) =>
      switch (entry.target) {
        TerminalTabTarget(:final terminalId) => _TerminalPane(
          key: ValueKey<String>('terminal-pane-${entry.id}'),
          selection: widget.selection,
          terminal: workspace.terminals.firstWhere(
            (item) => item.id == terminalId,
          ),
        ),
        SessionTabTarget(:final sessionId) => _ConversationPane(
          key: ValueKey<String>('conversation-pane-${entry.id}'),
          selection: widget.selection,
          agent: workspace.sessions.firstWhere((item) => item.id == sessionId),
        ),
        DraftTabTarget() => DraftSessionPane(
          key: ValueKey<String>('draft-pane-${entry.id}'),
          selection: widget.selection,
          draftId: entry.id,
          onCreated: (session) => _createdSession(entry, session),
        ),
      };

  Widget _newTabMenu(
    BuildContext context,
    String paneId,
    bool primary,
  ) => TRMenu.icon(
    key: ValueKey<String>(
      primary ? 'workspace-new-tab-menu' : 'workspace-new-tab-menu-$paneId',
    ),
    icon: const Icon(CoderIcons.add),
    label: AppLocalizations.of(context).workspaceNewTab,
    menuChildren: <Widget>[
      TRMenuItem(
        key: primary ? const ValueKey<String>('workspace-new-session') : null,
        onPressed: () => unawaited(_startDraft(paneId)),
        leadingIcon: const Icon(CoderIcons.chat),
        child: TRText.inherit(
          AppLocalizations.of(context).workspaceNewSession,
        ),
      ),
      TRMenuItem(
        key: primary ? const ValueKey<String>('workspace-new-terminal') : null,
        onPressed: () => unawaited(_createTerminal(paneId)),
        leadingIcon: const Icon(CoderIcons.terminal),
        child: TRText.inherit(
          AppLocalizations.of(context).workspaceNewTerminal,
        ),
      ),
    ],
  );

  Widget _allTabsMenu(
    BuildContext context,
    SessionTabsState workspace,
    PaneNode pane,
    bool primary,
  ) => TRMenu.icon(
    key: ValueKey<String>(
      primary ? 'workspace-all-sessions-menu' : 'workspace-tabs-${pane.id}',
    ),
    icon: const Icon(CoderIcons.more),
    label: AppLocalizations.of(context).workspaceAllSessions,
    menuChildren: <Widget>[
      for (final session in workspace.sessions.where(
        (item) => !isSubagentSession(item),
      ))
        TRMenuItem(
          onPressed: () => unawaited(_open(session.id)),
          child: TRText.inherit(session.title),
        ),
      for (final terminal in workspace.terminals)
        TRMenuItem(
          leadingIcon: const Icon(CoderIcons.terminal),
          onPressed: () => unawaited(_openTerminal(terminal.id)),
          child: TRText.inherit(terminal.title),
        ),
      for (final target in workspace.panes.where((item) => item.id != pane.id))
        TRMenuItem(
          leadingIcon: const Icon(CoderIcons.movePane),
          onPressed: () => unawaited(
            _moveTab(
              tabId: pane.activeTabId,
              sourcePaneId: pane.id,
              targetPaneId: target.id,
              targetIndex: target.tabIds.length,
            ),
          ),
          child: TRText.inherit(
            AppLocalizations.of(context).workspaceMoveTabToPane,
          ),
        ),
    ],
  );

  Future<void> _showTabSheet() {
    final l10n = AppLocalizations.of(context);
    return showTRDrawer<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => TRDrawer(
        key: const ValueKey<String>('workspace-tab-sheet'),
        snapPoints: const <double>[0.8, 1],
        title: TRText.inherit(l10n.workspaceSwitchTab),
        content: Consumer(
          builder: (_, ref, _) {
            final workspace = ref
                .watch(sessionTabsControllerProvider(widget.selection))
                .requireValue;
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final pane in workspace.panes)
                  for (final tabId in pane.tabIds)
                    _tabSheetRow(context, workspace, pane, tabId),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabSheetRow(
    BuildContext context,
    SessionTabsState workspace,
    PaneNode pane,
    String tabId,
  ) {
    final entry = workspace.tabs[tabId]!;
    final tab = _tab(context, workspace, entry, closable: false);
    return CoderListRow(
      key: ValueKey<String>('workspace-tab-row-${entry.id}'),
      leading: tab.leading,
      title: TRText.inherit(tab.label),
      selected: pane.id == workspace.focusedPaneId && pane.activeTabId == tabId,
      onTap: () {
        Navigator.of(context).pop();
        unawaited(_activate(pane.id, tabId));
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (pane.id == workspace.focusedPaneId && pane.activeTabId == tabId)
            const Icon(CoderIcons.check),
          TRIconButton(
            appearance: TRAppearance.ghost,
            label: AppLocalizations.of(context).workspaceCloseTab,
            onPressed: () => unawaited(_closeEntry(entry)),
            icon: const Icon(CoderIcons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _split(String paneId, WorkspaceSplitAxis axis) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .split(paneId, axis);
    if (mounted) _routeFocused();
  }

  Future<void> _dropTab(
    SessionTabsState workspace,
    TRTabDropDetails details,
  ) {
    final source = workspace.panes.firstWhere(
      (item) => item.id == details.sourceGroupId,
    );
    final tabId = source.tabIds.firstWhere(
      (id) => _controlValue(workspace.tabs[id]!) == details.value,
    );
    return _moveTab(
      tabId: tabId,
      sourcePaneId: details.sourceGroupId,
      targetPaneId: details.targetGroupId,
      targetIndex: details.targetIndex,
    );
  }

  Future<void> _moveTab({
    required String tabId,
    required String sourcePaneId,
    required String targetPaneId,
    required int targetIndex,
  }) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .moveTab(
          tabId: tabId,
          sourcePaneId: sourcePaneId,
          targetPaneId: targetPaneId,
          targetIndex: targetIndex,
        );
    if (mounted) _routeFocused();
  }

  Future<void> _activate(String paneId, String tabId) async {
    final notifier = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    await notifier.selectTab(paneId, tabId);
    if (mounted) _routeFocused();
  }

  Future<void> _open(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .open(id);
    if (mounted) _goSession(context, widget.selection, id);
  }

  Future<void> _openTerminal(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .openTerminal(id);
    if (mounted) _goTerminal(context, widget.selection, id);
  }

  Future<void> _startDraft(String paneId) async {
    final notifier = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    await notifier.focusPane(paneId);
    await notifier.startDraft();
    if (mounted) _goWorktree(context, widget.selection);
  }

  Future<void> _createTerminal(String paneId) async {
    final tabs = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    await tabs.focusPane(paneId);
    final terminal = await ref
        .read(
          terminalsControllerProvider(
            widget.selection.hostId,
            widget.selection.worktreeId,
          ).notifier,
        )
        .create();
    await tabs.addTerminal(terminal);
    if (mounted) _goTerminal(context, widget.selection, terminal.id);
  }

  Future<void> _createdSession(
    WorkspaceTabEntry entry,
    SessionDto session,
  ) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .add(session, draftTabId: entry.id);
    if (mounted) _goSession(context, widget.selection, session.id);
  }

  Future<void> _closeEntry(WorkspaceTabEntry entry) async {
    switch (entry.target) {
      case SessionTabTarget(:final sessionId):
        await ref
            .read(sessionTabsControllerProvider(widget.selection).notifier)
            .close(sessionId);
      case TerminalTabTarget(:final terminalId):
        await _closeTerminal(terminalId);
      case DraftTabTarget():
        await ref
            .read(sessionTabsControllerProvider(widget.selection).notifier)
            .closeTab(entry.id);
    }
    if (mounted) _routeFocused();
  }

  Future<void> _closeTerminal(String id) async {
    final state = ref
        .read(sessionTabsControllerProvider(widget.selection))
        .requireValue;
    final terminal = state.terminals.where((item) => item.id == id).first;
    if (terminal.status == TerminalStatus.running) {
      final confirmed = await showTRDialog<bool>(
        context: context,
        builder: (context) => TRAlertDialog(
          key: const ValueKey<String>('terminal-close-dialog'),
          title: TRText.inherit(
            AppLocalizations.of(context).terminalCloseTitle,
          ),
          content: TRText.inherit(
            AppLocalizations.of(context).terminalCloseConfirm,
          ),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.of(context).pop(false),
              child: TRText.inherit(
                MaterialLocalizations.of(context).cancelButtonLabel,
              ),
            ),
            TRButton(
              intent: TRIntent.danger,
              key: const ValueKey<String>('terminal-close-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: TRText.inherit(
                AppLocalizations.of(context).terminalTerminate,
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final registry = await ref.read(hostRegistryControllerProvider.future);
      await registry.runtimes[widget.selection.hostId]!.api!.terminals
          .terminateTerminal(
            id,
          );
    }
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .closeTerminal(id);
  }

  void _routeFocused() {
    final entry = ref
        .read(sessionTabsControllerProvider(widget.selection))
        .requireValue
        .focusedTab;
    switch (entry?.target) {
      case SessionTabTarget(:final sessionId):
        _goSession(context, widget.selection, sessionId);
      case TerminalTabTarget(:final terminalId):
        _goTerminal(context, widget.selection, terminalId);
      case DraftTabTarget() || null:
        _goWorktree(context, widget.selection);
    }
  }
}

class _TerminalPane extends ConsumerStatefulWidget {
  const _TerminalPane({
    required this.selection,
    required this.terminal,
    super.key,
  });

  final WorkspaceSelection selection;
  final TerminalDto terminal;

  @override
  ConsumerState<_TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends ConsumerState<_TerminalPane> {
  late final TerminalEmulator _emulator;
  final TerminalViewController _controller = TerminalViewController();
  StreamSubscription<TerminalOutputDto>? _events;
  CoderApi? _api;
  int _sequence = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _emulator = TerminalEmulator(
      columns: widget.terminal.columns,
      rows: widget.terminal.rows,
      onOutput: _sendInput,
      onResize: _resize,
    );
    unawaited(_attach());
  }

  void _sendInput(String data) {
    unawaited(
      _api?.terminals.writeTerminal(widget.terminal.id, data) ??
          Future<void>.value(),
    );
  }

  void _resize(TerminalSize size) {
    unawaited(
      _api?.terminals.resizeTerminal(
            widget.terminal.id,
            columns: size.columns,
            rows: size.rows,
          ) ??
          Future<TerminalDto>.value(widget.terminal),
    );
  }

  Future<void> _attach() async {
    try {
      final registry = await ref.read(hostRegistryControllerProvider.future);
      final api = registry.runtimes[widget.selection.hostId]!.api!;
      _api = api;
      final attached = await api.terminals.attachTerminal(widget.terminal.id);
      attached.replay.forEach(_accept);
      _events = api.terminals.output.listen((output) {
        if (output.terminalId == widget.terminal.id) {
          _accept(output);
        }
      });
      if (mounted) setState(() {});
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _accept(TerminalOutputDto output) {
    if (output.sequence <= _sequence) return;
    _sequence = output.sequence;
    _emulator.write(output.data);
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    _controller.dispose();
    _emulator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      return Center(
        child: TRAlert(
          variant: TRStatusVariant.danger,
          title: TRText.inherit(
            AppLocalizations.of(context).terminalConnectionFailed,
          ),
          description: TRText.inherit('$error'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => CoderTerminalView(
        key: ValueKey<String>('terminal-view-${widget.terminal.id}'),
        emulator: _emulator,
        controller: _controller,
        autofocus: true,
        contextMenuItems: _buildContextMenu,
      ),
    );
  }

  /// Describes the terminal menu so the operating system can draw it.
  ///
  /// The ids are what a system menu reports back in place of a Dart closure,
  /// and are the same strings the Flutter presentation keys its items by.
  List<TRMenuElement> _buildContextMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSelection = _controller.hasSelection;
    return <TRMenuElement>[
      TRMenuActionElement(
        id: 'terminal-menu-copy',
        title: l10n.terminalMenuCopy,
        icon: CoderIcons.copy,
        enabled: hasSelection,
        onPressed: _copySelection,
      ),
      TRMenuActionElement(
        id: 'terminal-menu-paste',
        title: l10n.terminalMenuPaste,
        icon: CoderIcons.paste,
        onPressed: _pasteClipboard,
      ),
      const TRMenuSeparatorElement(),
      TRMenuActionElement(
        id: 'terminal-menu-select-all',
        title: l10n.terminalMenuSelectAll,
        icon: CoderIcons.selectAll,
        onPressed: _controller.selectAll,
      ),
      TRMenuActionElement(
        id: 'terminal-menu-clear-selection',
        title: l10n.terminalMenuClearSelection,
        icon: CoderIcons.clearSelection,
        enabled: hasSelection,
        onPressed: _controller.clearSelection,
      ),
      const TRMenuSeparatorElement(),
      TRMenuActionElement(
        id: 'terminal-menu-clear-screen',
        title: l10n.terminalMenuClearScreen,
        icon: CoderIcons.erase,
        onPressed: _clearScreen,
      ),
    ];
  }

  void _copySelection() {
    final text = _controller.selectedText;
    if (text == null) return;
    unawaited(Clipboard.setData(ClipboardData(text: text)));
  }

  void _pasteClipboard() {
    unawaited(() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || text.isEmpty) return;
      _emulator.paste(text);
      _controller.clearSelection();
    }());
  }

  /// Erases the screen and the scrollback, then homes the cursor.
  void _clearScreen() {
    _emulator.write('\x1b[H\x1b[2J\x1b[3J');
    _controller.clearSelection();
  }
}

class _ConversationPane extends ConsumerStatefulWidget {
  const _ConversationPane({
    required this.selection,
    required this.agent,
    super.key,
  });

  final WorkspaceSelection selection;
  final SessionDto agent;

  @override
  ConsumerState<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends ConsumerState<_ConversationPane> {
  final Set<String> _dismissedPlans = <String>{};

  SessionsController _sessions(WidgetRef ref) => ref.read(
    sessionsControllerProvider(
      widget.selection.hostId,
      widget.selection.worktreeId,
    ).notifier,
  );

  ConversationController _conversation(WidgetRef ref, String sessionId) =>
      ref.read(
        conversationControllerProvider(
          widget.selection.hostId,
          sessionId,
        ).notifier,
      );

  @override
  Widget build(BuildContext context) {
    final sessions =
        ref
            .watch(
              sessionsControllerProvider(
                widget.selection.hostId,
                widget.selection.worktreeId,
              ),
            )
            .value ??
        const <SessionDto>[];
    final current =
        sessions.where((item) => item.id == widget.agent.id).firstOrNull ??
        widget.agent;
    // A spawned subagent's conversation is watched live but never driven
    // from here: no composer, approvals, questions, or plan actions.
    final readOnly = isSubagentSession(current);
    final subagentRows = readOnly
        ? const <SubagentTrackRow>[]
        : buildSubagentTrackRows(sessions, current.id);
    final busy =
        current.status == SessionStatus.running ||
        current.status == SessionStatus.waitingForApproval ||
        current.status == SessionStatus.waitingForInput;
    final conversation = ref.watch(
      conversationControllerProvider(widget.selection.hostId, current.id),
    );
    final value = conversation.asData?.value;
    final items = ref.watch(
      conversationTimelineProvider(widget.selection.hostId, current.id),
    );
    final visibleItems = readOnly
        ? items
              .where(
                (item) =>
                    item is! ChatApprovalInteraction &&
                    item is! ChatQuestionInteraction,
              )
              .toList(growable: false)
        : items;
    final agentsAsync = ref.watch(
      agentDefinitionsControllerProvider(widget.selection.hostId),
    );
    final agents = agentsAsync.value;
    final agentsLoading = agentsAsync.isLoading && !agentsAsync.hasValue;
    final providersAsync = ref.watch(
      providerSettingsControllerProvider(widget.selection.hostId),
    );
    final connections =
        providersAsync.value?.connections ?? const <ProviderConnectionDto>[];
    final providersLoading =
        providersAsync.isLoading && !providersAsync.hasValue;
    final definitions = selectableAgentDefinitions(
      agents?.definitions ?? const <AgentDefinitionDto>[],
    );
    final definition = definitions
        .where((item) => item.id == current.agentDefinitionId)
        .firstOrNull;
    final effective =
        current.model ??
        effectiveModelFor(
          definition: definition,
          connections: connections,
          models:
              providersAsync.value?.models ??
              const <String, List<ProviderModelDto>>{},
          defaultModel: providersAsync.value?.defaultModel,
        );
    // Only the newest plan can still be acted on, and only in plan mode: the
    // card asks whether to leave planning and carry the plan out.
    final lastPlan = visibleItems.whereType<ChatPlanProposal>().lastOrNull;
    final pendingPlan =
        !busy &&
            current.mode == SessionMode.plan &&
            lastPlan != null &&
            !_dismissedPlans.contains(lastPlan.key)
        ? lastPlan
        : null;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: <Widget>[
          CoderListRow(
            leading: readOnly
                ? SubagentStatusIcon(lifecycle: current.lifecycle)
                : null,
            title: TRText.inherit(
              readOnly ? current.taskName ?? current.title : current.title,
            ),
            subtitle: TRText.inherit(
              readOnly
                  ? '${current.agentPath ?? current.agentDefinitionId} · '
                        '${AppLocalizations.of(context).subagentReadOnlyNotice}'
                  : '${current.agentDefinitionId} · ${current.origin.name}',
            ),
            trailing: busy
                ? TRIconButton(
                    appearance: TRAppearance.ghost,
                    label: AppLocalizations.of(context).commonStop,
                    onPressed: () => ref
                        .read(
                          conversationControllerProvider(
                            widget.selection.hostId,
                            current.id,
                          ).notifier,
                        )
                        .cancelTurn(),
                    icon: const Icon(CoderIcons.stop),
                  )
                : null,
          ),
          Expanded(
            child: ChatTimelineView(
              items: visibleItems,
              busy: busy,
              hostId: widget.selection.hostId,
              planActionBuilder: pendingPlan == null
                  ? null
                  : (proposal) => proposal.key != pendingPlan.key
                        ? null
                        : ChatPlanActions(
                            selection: widget.selection,
                            session: current,
                            proposal: proposal,
                            embedded: true,
                            onDismiss: () => setState(
                              () => _dismissedPlans.add(proposal.key),
                            ),
                            onSessionCreated: (session) => _goSession(
                              context,
                              widget.selection,
                              session.id,
                            ),
                          ),
              loadAttachment: _loadAttachment,
              exportAttachment: _exportAttachment,
            ),
          ),
          if (value?.goal case final GoalDto goal)
            if (!readOnly)
              GoalStatusBar(
                goal: goal,
                sessionMode: current.mode,
                onEdit: () => unawaited(_editGoal(current.id, goal)),
                onStatusChanged: (status) => unawaited(
                  _conversation(ref, current.id).updateGoal(
                    GoalUpdateDto(
                      expectedGoalId: goal.goalId,
                      status: status,
                    ),
                  ),
                ),
                onClear: () => unawaited(
                  _conversation(ref, current.id).clearGoal(),
                ),
              ),
          // Keep the auxiliary subagent track bounded so the composer retains
          // its natural height and the timeline receives the remaining space.
          if (!readOnly)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (subagentRows.isNotEmpty)
                    SubagentTrack(
                      rows: subagentRows,
                      // Viewport-derived cap: the expanded list never squeezes
                      // the composer out of the bottom group.
                      maxListHeight: constraints.maxHeight / 4,
                      onOpenSubagent: (sessionId) =>
                          _goSession(context, widget.selection, sessionId),
                    ),
                  ComposerCompletionScope(
                    hostId: widget.selection.hostId,
                    workspaceId: widget.selection.workspaceId,
                    worktreeId: widget.selection.worktreeId,
                    builder: (context, completion) => SessionComposer(
                      // A running turn never takes the keyboard away; the
                      // prompt queues instead.
                      enabled: effective != null,
                      busy: busy,
                      contextTokens: current.contextTokens,
                      contextWindow: current.contextWindow,
                      queued: value?.queued ?? const <QueuedTurn>[],
                      onQueue: (submission) =>
                          _conversation(ref, current.id).enqueueTurn(
                            submission.text,
                            attachments: submission.attachments,
                          ),
                      onQueuedEdit: (id) =>
                          _conversation(ref, current.id).takeQueuedTurn(id),
                      onQueuedSendNow: (id) =>
                          _conversation(ref, current.id).sendQueuedTurnNow(id),
                      onSubmitAndInterrupt: (submission) async {
                        await _conversation(ref, current.id).cancelTurn();
                        await _send(current.id, submission);
                      },
                      hint:
                          (agentsLoading ||
                              providersLoading ||
                              effective != null)
                          ? null
                          : AppLocalizations.of(
                              context,
                            ).composerConnectProviderFirst,
                      bar: SessionComposerBar(
                        hostId: widget.selection.hostId,
                        definitions: definitions,
                        agentDefinitionId: current.agentDefinitionId,
                        selection: effective,
                        mode: current.mode,
                        onModeChanged: (mode) => unawaited(
                          ref
                              .read(
                                sessionsControllerProvider(
                                  widget.selection.hostId,
                                  widget.selection.worktreeId,
                                ).notifier,
                              )
                              .setMode(current.id, mode),
                        ),
                        // Turn settings apply to the next turn, so they stay
                        // reachable while one is running.
                        agentEnabled: false,
                        onAgentChanged: (_) {},
                        onModelChanged: (model, controls) => unawaited(
                          ref
                              .read(
                                sessionsControllerProvider(
                                  widget.selection.hostId,
                                  widget.selection.worktreeId,
                                ).notifier,
                              )
                              .setModel(current.id, model, controls),
                        ),
                        modelControls: current.modelControls,
                        onModelControlsChanged: (controls) => unawaited(
                          _sessions(
                            ref,
                          ).setModelControls(current.id, controls),
                        ),
                        permissionMode: current.permissionMode,
                        onPermissionModeChanged: (mode) async {
                          await _sessions(
                            ref,
                          ).setPermissionMode(current.id, mode);
                        },
                      ),
                      onModeToggled: () => unawaited(
                        _sessions(ref).setMode(
                          current.id,
                          current.mode == SessionMode.plan
                              ? SessionMode.normal
                              : SessionMode.plan,
                        ),
                      ),
                      attachmentInput: ref.read(attachmentInputProvider),
                      commands: completion.commands,
                      suggestions: completion.suggestions,
                      onCompletionQueryChanged: completion.onQueryChanged,
                      onClientCommand: (invocation) =>
                          _runClientCommand(invocation, current),
                      onSubmit: (submission) => _send(current.id, submission),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Runs an app-owned command, reporting that the submission was consumed.
  Future<bool> _runClientCommand(
    ComposerCommandInvocation invocation,
    SessionDto session,
  ) async {
    switch (invocation.command.action!) {
      case ClientCommandAction.clear:
        // The draft is already cleared by the composer; nothing else to undo.
        break;
      case ClientCommandAction.newSession:
        await _sessions(ref).create(
          title: invocation.arguments.isEmpty
              ? AppLocalizations.of(context).workspaceNewSession
              : invocation.arguments,
          agentDefinitionId: session.agentDefinitionId,
          mode: session.mode,
          model: session.model,
        );
      case ClientCommandAction.toggleMode:
        await _sessions(ref).setMode(
          session.id,
          session.mode == SessionMode.plan
              ? SessionMode.normal
              : SessionMode.plan,
        );
      case ClientCommandAction.openAgentSettings:
        if (mounted) {
          AgentSettingsRoute(hostId: widget.selection.hostId).go(context);
        }
      case ClientCommandAction.openSkillSettings:
        if (mounted) {
          SkillSettingsRoute(hostId: widget.selection.hostId).go(context);
        }
      case ClientCommandAction.compact:
        await _sessions(ref).compact(session.id);
      case ClientCommandAction.goal:
        await _runGoalCommand(session.id, invocation.arguments);
      case ClientCommandAction.help:
        // Typing `/` already lists every command, so help only reopens it.
        break;
    }
    return true;
  }

  Future<void> _runGoalCommand(String sessionId, String arguments) async {
    final command = arguments.trim();
    final goal = ref
        .read(
          conversationControllerProvider(
            widget.selection.hostId,
            sessionId,
          ),
        )
        .asData
        ?.value
        .goal;
    switch (command) {
      case '':
      case 'edit':
        await _editGoal(sessionId, goal);
      case 'pause':
        if (goal != null) {
          await _conversation(ref, sessionId).updateGoal(
            GoalUpdateDto(
              expectedGoalId: goal.goalId,
              status: GoalStatus.paused,
            ),
          );
        }
      case 'resume':
        if (goal != null) {
          await _conversation(ref, sessionId).updateGoal(
            GoalUpdateDto(
              expectedGoalId: goal.goalId,
              status: GoalStatus.active,
            ),
          );
        }
      case 'clear':
        await _conversation(ref, sessionId).clearGoal();
      default:
        await _replaceGoal(sessionId, command, current: goal);
    }
  }

  Future<void> _editGoal(String sessionId, GoalDto? goal) async {
    final edited = await showGoalEditor(context, goal: goal);
    if (!mounted || edited == null) return;
    if (goal == null ||
        goal.status == GoalStatus.complete ||
        goal.status == GoalStatus.budgetLimited) {
      await _replaceGoal(
        sessionId,
        edited.objective,
        tokenBudget: edited.tokenBudget,
        current: goal,
      );
      return;
    }
    await _conversation(ref, sessionId).updateGoal(
      GoalUpdateDto(
        expectedGoalId: goal.goalId,
        objective: edited.objective,
        hasTokenBudget: true,
        tokenBudget: edited.tokenBudget,
      ),
    );
  }

  Future<void> _replaceGoal(
    String sessionId,
    String objective, {
    int? tokenBudget,
    GoalDto? current,
  }) async {
    if (current != null && current.status != GoalStatus.complete) {
      final replace = await showTRDialog<bool>(
        context: context,
        builder: (context) => TRAlertDialog(
          title: TRText.inherit(
            AppLocalizations.of(context).goalReplaceTitle,
          ),
          content: TRText.inherit(
            AppLocalizations.of(context).goalReplaceDescription,
          ),
          actions: <TRButton>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => Navigator.pop(context, false),
              child: TRText.inherit(
                AppLocalizations.of(context).commonCancel,
              ),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => Navigator.pop(context, true),
              child: TRText.inherit(
                AppLocalizations.of(context).goalReplaceAction,
              ),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    await _conversation(
      ref,
      sessionId,
    ).replaceGoal(objective, tokenBudget: tokenBudget);
  }

  Future<void> _send(
    String sessionId,
    ComposerSubmission submission,
  ) async {
    await ref
        .read(
          conversationControllerProvider(
            widget.selection.hostId,
            sessionId,
          ).notifier,
        )
        .startTurn(
          submission.text,
          attachments: submission.attachments,
        );
  }

  Future<Uint8List> _loadAttachment(ChatAttachment attachment) async {
    final registry = await ref.read(hostRegistryControllerProvider.future);
    final api = registry.runtimes[widget.selection.hostId]?.api;
    if (api == null) throw StateError('Daemon is not connected.');
    return readAttachmentDownload(
      await api.attachments.downloadAttachment(attachment.id),
    );
  }

  Future<void> _exportAttachment(ChatAttachment attachment) async {
    final bytes = await _loadAttachment(attachment);
    await ref
        .read(attachmentExportProvider)
        .export(
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          bytes: bytes,
        );
  }
}

/// Selects [selection] within the workspace surface.
///
/// Every workspace location renders the same [WorkspacePage], so this replaces
/// the current page: the page key survives, no transition plays, and the state
/// of the open sessions is not rebuilt from scratch.
void _goWorktree(BuildContext context, WorkspaceSelection selection) {
  WorktreeRoute(
    hostId: selection.hostId,
    workspaceId: selection.workspaceId,
    worktreeId: selection.worktreeId,
  ).replace(context);
}

void _goSession(
  BuildContext context,
  WorkspaceSelection selection,
  String sessionId,
) {
  SessionRoute(
    hostId: selection.hostId,
    workspaceId: selection.workspaceId,
    worktreeId: selection.worktreeId,
    sessionId: sessionId,
  ).replace(context);
}

void _goTerminal(
  BuildContext context,
  WorkspaceSelection selection,
  String terminalId,
) {
  TerminalRoute(
    hostId: selection.hostId,
    workspaceId: selection.workspaceId,
    worktreeId: selection.worktreeId,
    terminalId: terminalId,
  ).replace(context);
}
