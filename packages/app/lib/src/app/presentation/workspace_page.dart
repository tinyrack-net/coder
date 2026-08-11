import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/presentation/new_workspace_pane.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/application/conversation_controller.dart';
import 'package:app/src/features/conversation/application/conversation_timeline_controller.dart';
import 'package:app/src/features/conversation/application/pending_turns_controller.dart';
import 'package:app/src/features/conversation/application/subagent_track_model.dart';
import 'package:app/src/features/conversation/domain/composer_commands.dart';
import 'package:app/src/features/conversation/presentation/chat_plan_actions.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:app/src/features/conversation/presentation/goal_status_bar.dart';
import 'package:app/src/features/conversation/presentation/subagents/subagent_status_icon.dart';
import 'package:app/src/features/conversation/presentation/subagents/subagent_track.dart';
import 'package:app/src/features/conversation/presentation/widgets/composer_completion_scope.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/providers/application/provider_settings_controller.dart';
import 'package:app/src/features/providers/application/session_model_options.dart';
import 'package:app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:app/src/features/sessions/application/sessions_controller.dart';
import 'package:app/src/features/terminals/application/terminal_session_controller.dart';
import 'package:app/src/features/terminals/application/terminals_controller.dart';
import 'package:app/src/features/terminals/presentation/coder_terminal_view.dart';
import 'package:app/src/features/workspace/application/workspace_controller.dart';
import 'package:app/src/features/workspace/presentation/widgets/workspace_sidebar.dart';
import 'package:app/src/shared/presentation/client_error_alert.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:app/src/shared/presentation/coder_layout_metrics.dart';
import 'package:app/src/shared/presentation/coder_list_row.dart';
import 'package:app/src/shared/presentation/coder_page_shell.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protocol/protocol.dart';
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
  bool _missingSelectionScheduled = false;
  late final TRTreeNavController<WorkspaceNavValue> _workspaceTreeController;

  @override
  void initState() {
    super.initState();
    final selection = widget.selection;
    _workspaceTreeController = TRTreeNavController<WorkspaceNavValue>(
      expanded: selection == null
          ? const <WorkspaceNavValue>[]
          : <WorkspaceNavValue>[
              (
                hostId: selection.hostId,
                workspaceId: selection.workspaceId,
                worktreeId: null,
              ),
            ],
    );
  }

  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // One Navigator page now serves every checkout, so this state outlives a
    // selection change and each new checkout needs its own archived check.
    if (widget.selection != oldWidget.selection) {
      _missingSelectionScheduled = false;
      _releaseTerminals(oldWidget.selection);
    }
  }

  /// Ends the terminal sessions of a checkout the page has just left.
  ///
  /// Terminal sessions are `keepAlive` so a tab switch cannot reset them, which
  /// means leaving a checkout is what bounds their number. The departing tab
  /// state is read here, synchronously, while its own provider is still alive.
  /// Deliberately not done in [dispose]: a trip to settings tears this page
  /// down, and coming back must not find every terminal wiped.
  void _releaseTerminals(WorkspaceSelection? selection) {
    if (selection == null) return;
    final tabs = ref.read(sessionTabsControllerProvider(selection)).value;
    if (tabs == null) return;
    for (final entry in tabs.tabs.values) {
      if (entry.target case TerminalTabTarget(:final terminalId)) {
        ref.invalidate(
          terminalSessionControllerProvider(selection.hostId, terminalId),
        );
      }
    }
  }

  @override
  void dispose() {
    _workspaceTreeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Every tab switch persists the pane tree, which re-emits the whole
    // registry. Selecting only what this page renders keeps that write from
    // rebuilding the sidebar beside the tabs. `value` rather than `asData` so
    // a reload keeps showing the registry that is already loaded.
    final hosts = ref.watch(
      hostRegistryControllerProvider.select((value) => value.value?.runtimes),
    );
    final catalog = ref.watch(workspaceCatalogControllerProvider);
    final collapsed = ref.watch(
      hostRegistryControllerProvider.select(
        (value) => value.value?.settings.sidebarCollapsed ?? false,
      ),
    );
    final savedWorktree = ref.watch(
      hostRegistryControllerProvider.select(
        (value) => value.value?.settings.lastWorktree,
      ),
    );
    _restoreSelection(savedWorktree, catalog.value);
    _replaceMissingSelection(catalog.value);
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
                  hosts: hosts,
                  catalog: catalog,
                  homeSessions: _homeSessions(catalog.value),
                  selected: widget.selection,
                  treeController: _workspaceTreeController,
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
    WorkspaceSelection? saved,
    UnifiedWorkspaceCatalogState? catalog,
  ) {
    // Opening the composer is an explicit choice; never bounce out of it.
    if (widget.compose || widget.selection != null) return;
    if (_restoreScheduled) return;
    if (ref.read(selectionRestoreControllerProvider)) return;
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

  void _replaceMissingSelection(UnifiedWorkspaceCatalogState? catalog) {
    final selection = widget.selection;
    if (selection == null || catalog == null || _missingSelectionScheduled) {
      return;
    }
    final hostCatalog = catalog.catalogs[selection.hostId];
    if (hostCatalog == null) return;
    final exists = hostCatalog.worktrees.any(
      (worktree) =>
          worktree.id == selection.worktreeId &&
          worktree.workspaceId == selection.workspaceId,
    );
    if (exists) return;
    _missingSelectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_confirmMissingSelection(selection));
    });
  }

  Future<void> _confirmMissingSelection(WorkspaceSelection selection) async {
    try {
      await ref
          .read(workspaceCatalogControllerProvider.notifier)
          .refreshHost(selection.hostId);
    } on CoderClientException {
      _missingSelectionScheduled = false;
      return;
    }
    if (!mounted || widget.selection != selection) {
      _missingSelectionScheduled = false;
      return;
    }
    final refreshed = ref.read(workspaceCatalogControllerProvider).value;
    final stillMissing =
        refreshed?.catalogs[selection.hostId]?.worktrees.any(
          (worktree) =>
              worktree.id == selection.worktreeId &&
              worktree.workspaceId == selection.workspaceId,
        ) !=
        true;
    if (stillMissing) {
      const WorkspaceHomeRoute().replace(context);
      return;
    }
    _missingSelectionScheduled = false;
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
  CoderClientException? _terminalCreationError;

  @override
  Widget build(BuildContext context) {
    final provider = sessionTabsControllerProvider(widget.selection);
    ref.listen(provider, _releaseClosedTerminals);
    final value = ref.watch(provider);
    final workspace = value.asData?.value;
    _openRequestedRoute(provider, workspace);
    if (workspace == null) {
      return WorkspacePaneSkeleton(
        semanticLabel: AppLocalizations.of(context).workspaceLoading,
      );
    }
    final content = widget.mobile
        ? _buildMobile(context, workspace)
        : _buildNode(context, workspace, workspace.root);
    final error = _terminalCreationError;
    if (error == null) return content;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(TRSpacing.small),
          child: TRAlert(
            key: const ValueKey<String>('terminal-creation-error'),
            variant: TRStatusVariant.danger,
            title: TRText.inherit(l10n.terminalCreationFailed),
            description: TRText.inherit(clientErrorText(l10n, error)),
          ),
        ),
        Expanded(child: content),
      ],
    );
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

  /// Ends the sessions of terminals whose tab has just gone away.
  ///
  /// A terminal session is deliberately `keepAlive`, so something has to end
  /// it. Diffing the tab set covers every way a tab can disappear — the close
  /// button, the terminate confirmation, a discarded pending tab, the mobile
  /// sheet — instead of asking each of those call sites to remember.
  void _releaseClosedTerminals(
    AsyncValue<SessionTabsState>? previous,
    AsyncValue<SessionTabsState> next,
  ) {
    // A reload frame carries no value and must not read as "everything closed".
    if (previous == null || !previous.hasValue || !next.hasValue) return;
    final closed = _terminalIds(previous).difference(_terminalIds(next));
    for (final terminalId in closed) {
      ref.invalidate(
        terminalSessionControllerProvider(
          widget.selection.hostId,
          terminalId,
        ),
      );
    }
  }

  static Set<String> _terminalIds(
    AsyncValue<SessionTabsState> tabs,
  ) => <String>{
    for (final entry in tabs.value?.tabs.values ?? const <WorkspaceTabEntry>[])
      if (entry.target case TerminalTabTarget(:final terminalId)) terminalId,
  };

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
            TRTabs(
              key: ValueKey<String>(
                firstPane
                    ? 'session-tab-strip'
                    : 'session-tab-strip-${pane.id}',
              ),
              tabWidth: TRTabsWidth.fixed,
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
          child: TRTabs(
            tabWidth: TRTabsWidth.fixed,
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
    PendingTerminalTabTarget() => TRTabsTab(
      value: _controlValue(entry),
      label: AppLocalizations.of(context).workspaceTerminalStarting,
      leading: const Icon(CoderIcons.terminal),
      onClose: closable ? () => unawaited(_closeEntry(entry)) : null,
      closeLabel: AppLocalizations.of(context).workspaceCloseTab,
    ),
  };

  String _controlValue(WorkspaceTabEntry entry) => switch (entry.target) {
    SessionTabTarget(:final sessionId) => sessionId,
    TerminalTabTarget(:final terminalId) => terminalId,
    DraftTabTarget() || PendingTerminalTabTarget() => entry.id,
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
          onCreated: _createdSession,
        ),
        PendingTerminalTabTarget() => TerminalConnectingOverlay(
          key: ValueKey<String>('pending-terminal-pane-${entry.id}'),
          semanticLabel: AppLocalizations.of(context).workspaceTerminalStarting,
          message: AppLocalizations.of(context).workspaceTerminalStarting,
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
    final l10n = AppLocalizations.of(context);
    final tabs = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    if (_terminalCreationError != null) {
      setState(() => _terminalCreationError = null);
    }
    // The placeholder tab appears before the daemon answers, so creating a
    // terminal never leaves the pane frozen while the PTY spawns.
    final pendingTabId = tabs.openPendingTerminal(paneId);
    final TerminalDto terminal;
    try {
      terminal = await ref
          .read(
            terminalsControllerProvider(
              widget.selection.hostId,
              widget.selection.worktreeId,
            ).notifier,
          )
          .create(buildTitle: l10n.terminalTabTitle);
    } on CoderClientException catch (error) {
      await tabs.removePendingTerminal(pendingTabId);
      if (mounted) setState(() => _terminalCreationError = error);
      if (error.code == 'worktree_unavailable') {
        await ref
            .read(workspaceCatalogControllerProvider.notifier)
            .refreshHost(widget.selection.hostId);
      }
      return;
    } on Exception catch (error) {
      await tabs.removePendingTerminal(pendingTabId);
      if (mounted) await _showTerminalCreateError(error);
      return;
    }
    tabs.promotePendingTerminal(pendingTabId, terminal);
    if (mounted) _goTerminal(context, widget.selection, terminal.id);
  }

  Future<void> _showTerminalCreateError(Object error) => showTRDialog<void>(
    context: context,
    builder: (context) => TRAlertDialog(
      key: const ValueKey<String>('terminal-create-failed'),
      title: TRText.inherit(
        AppLocalizations.of(context).terminalConnectionFailed,
      ),
      content: TRText.inherit(
        AppLocalizations.of(context).workspaceTerminalStartFailed('$error'),
      ),
      actions: <TRButton>[
        TRButton(
          onPressed: () => Navigator.of(context).pop(),
          child: TRText.inherit(
            MaterialLocalizations.of(context).okButtonLabel,
          ),
        ),
      ],
    ),
  );

  void _createdSession(SessionDto session) {
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
      case PendingTerminalTabTarget():
        await ref
            .read(sessionTabsControllerProvider(widget.selection).notifier)
            .removePendingTerminal(entry.id);
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
      // A terminate the daemon refuses must not close the tab, or the process
      // keeps running with nothing left on screen that can reach it.
      final terminated = await ref
          .read(toastMessengerProvider)
          .run(
            () async {
              final registry = await ref.read(
                hostRegistryControllerProvider.future,
              );
              await registry.runtimes[widget.selection.hostId]!.api!.terminals
                  .terminateTerminal(id);
            },
            failure: AppLocalizations.of(context).terminalTerminateFailed,
            id: 'terminal-terminate',
          );
      if (!terminated) return;
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
      case DraftTabTarget() || PendingTerminalTabTarget() || null:
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

/// Renders one terminal session; the emulator itself lives in the provider.
///
/// Nothing durable is kept here, so the pane can be unmounted and rebuilt as
/// often as the tab layout likes without resetting what the user sees.
class _TerminalPaneState extends ConsumerState<_TerminalPane> {
  final TerminalViewController _controller = TerminalViewController();

  TerminalSessionControllerProvider get _provider =>
      terminalSessionControllerProvider(
        widget.selection.hostId,
        widget.terminal.id,
      );

  Terminal get _terminal => ref.read(_provider).terminal;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(_provider);
    if (session.status == TerminalSessionStatus.failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TRAlert(
              variant: TRStatusVariant.danger,
              title: TRText.inherit(l10n.terminalConnectionFailed),
              description: TRText.inherit('${session.error}'),
            ),
            const SizedBox(height: TRSpacing.medium),
            TRButton(
              key: const ValueKey<String>('terminal-attach-retry'),
              // Invalidating would destroy the emulator, so the retry goes
              // through the session, which keeps whatever it already holds.
              onPressed: () => ref.read(_provider.notifier).retry(),
              child: TRText.inherit(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    // The pane never blocks on the attach round trip: while the replay is on
    // its way, a visible connecting state explains why input is not accepted
    // yet instead of rendering an empty prompt that swallows keystrokes. Once
    // there is content to show, the terminal stays on screen through a
    // reconnect rather than being replaced by a spinner.
    if (session.status != TerminalSessionStatus.live && !session.hasContent) {
      return TerminalConnectingOverlay(
        key: ValueKey<String>('terminal-connecting-${widget.terminal.id}'),
        semanticLabel: l10n.terminalConnecting,
        message: l10n.terminalConnecting,
      );
    }
    // Input is dropped for the frames a rebuilt screen takes to paint, so the
    // terminal says so rather than looking live and swallowing keystrokes.
    final restoring = session.status == TerminalSessionStatus.restoring;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => CoderTerminalView(
        key: ValueKey<String>('terminal-view-${widget.terminal.id}'),
        terminal: session.terminal,
        controller: _controller,
        autofocus: true,
        readOnly: restoring,
        contextMenuItems: _buildContextMenu,
        onCopy: _copySelection,
        onPaste: _pasteClipboard,
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
      _terminal.paste(text);
      _controller.clearSelection();
    }());
  }

  /// Erases the screen and the scrollback, then homes the cursor.
  void _clearScreen() {
    _terminal.write('\x1b[H\x1b[2J\x1b[3J');
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
  final SessionComposerController _dropController = SessionComposerController();

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  SessionsController _sessions(WidgetRef ref) => ref.read(
    sessionsControllerProvider(
      widget.selection.hostId,
      widget.selection.worktreeId,
    ).notifier,
  );

  /// Applies a session setting and explains a refusal instead of dropping it.
  ///
  /// These controls stay live while a turn runs because they are meant for the
  /// next one, so the daemon can legitimately refuse the change: the mode and
  /// the model are read when a turn starts. Firing the change and forgetting
  /// it left the chip snapping back to its old value with nothing said, and
  /// the failure escaping as an unhandled asynchronous error.
  Future<void> _applySessionSetting(Future<void> Function() change) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ref.read(toastMessengerProvider);
    try {
      await change();
    }
    // Deliberately broad: this is the boundary that turns a refused setting
    // into something the user can read, and anything it declined to catch
    // would go back to being silent.
    on Object catch (error) {
      messenger.failure(
        error is CoderClientException
            ? clientErrorText(l10n, error)
            : l10n.errorSessionSettingFailed,
        id: 'session-setting',
      );
    }
  }

  ConversationController _conversation(WidgetRef ref, String sessionId) =>
      ref.read(
        conversationControllerProvider(
          widget.selection.hostId,
          sessionId,
        ).notifier,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
    var visibleItems = readOnly
        ? items
              .where(
                (item) =>
                    item is! ChatApprovalInteraction &&
                    item is! ChatQuestionInteraction,
              )
              .toList(growable: false)
        : items;
    // A freshly created session navigates before its first turn is accepted.
    // Until the real timeline echoes the prompt, render it optimistically so
    // the chat room never opens onto an empty page after Send.
    final pendingFirstTurn = ref.watch(
      pendingFirstTurnsProvider.select((value) => value[current.id]),
    );
    // A first turn that failed before this pane mounted could not be queued:
    // the auto-disposed conversation state was not alive to hold it. Now that
    // this pane keeps the conversation alive, convert the survivor into a
    // queued turn with its usual error and retry affordances.
    if (pendingFirstTurn != null &&
        pendingFirstTurn.failed &&
        conversation.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final entry = ref.read(pendingFirstTurnsProvider)[current.id];
        if (entry == null || !entry.failed) return;
        ref.read(pendingFirstTurnsProvider.notifier).clear(current.id);
        _conversation(
          ref,
          current.id,
        ).enqueueTurn(entry.prompt, attachments: entry.attachments);
      });
    }
    final optimistic =
        pendingFirstTurn != null &&
        !visibleItems.any((item) => item is ChatUserMessage);
    if (optimistic) {
      visibleItems = <ChatItem>[
        ...visibleItems,
        ChatUserMessage(
          key: 'pending-first-turn-${current.id}',
          turnId: 'pending-first-turn',
          createdAt: pendingFirstTurn.createdAt,
          text: pendingFirstTurn.prompt,
        ),
      ];
    }
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
    return ComposerDropPane(
      controller: _dropController,
      child: LayoutBuilder(
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
                          '${l10n.subagentReadOnlyNotice}'
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
                busy: busy || optimistic,
                loading: conversation.isLoading && !conversation.hasValue,
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
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (subagentRows.isNotEmpty)
                      SubagentTrack(
                        rows: subagentRows,
                        // Viewport-derived cap: the expanded list never
                        // squeezes the composer out of the bottom group.
                        maxListHeight: constraints.maxHeight / 4,
                        onOpenSubagent: (sessionId) =>
                            _goSession(context, widget.selection, sessionId),
                      ),
                    ComposerCompletionScope(
                      hostId: widget.selection.hostId,
                      workspaceId: widget.selection.workspaceId,
                      worktreeId: widget.selection.worktreeId,
                      builder: (context, completion) => SessionComposer(
                        controller: _dropController,
                        // A running turn never takes the keyboard away; the
                        // prompt queues instead.
                        enabled: effective != null,
                        busy: busy,
                        contextTokens: current.contextTokens,
                        contextWindow: current.contextWindow,
                        totalCostUsd: current.totalCostUsd,
                        providerConnectionId: effective == null
                            ? null
                            : connections
                                  .where(
                                    (connection) =>
                                        effective.qualifiedModelId.startsWith(
                                          '${connection.modelPrefix}/',
                                        ),
                                  )
                                  .firstOrNull
                                  ?.id,
                        onLoadProviderUsage: () => ref
                            .read(
                              providerSettingsControllerProvider(
                                widget.selection.hostId,
                              ).notifier,
                            )
                            .loadUsage(),
                        queued: value?.queued ?? const <QueuedTurn>[],
                        onQueue: (submission) =>
                            _conversation(ref, current.id).enqueueTurn(
                              submission.text,
                              attachments: submission.attachments,
                            ),
                        onQueuedEdit: (id) =>
                            _conversation(ref, current.id).takeQueuedTurn(id),
                        onQueuedSendNow: (id) => _conversation(
                          ref,
                          current.id,
                        ).sendQueuedTurnNow(id),
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
                            _applySessionSetting(
                              () => _sessions(ref).setMode(current.id, mode),
                            ),
                          ),
                          // Turn settings apply to the next turn, so they stay
                          // reachable while one is running.
                          agentEnabled: false,
                          onAgentChanged: (_) {},
                          onModelChanged: (model, controls) => unawaited(
                            _applySessionSetting(
                              () => _sessions(
                                ref,
                              ).setModel(current.id, model, controls),
                            ),
                          ),
                          modelControls: current.modelControls,
                          onModelControlsChanged: (controls) => unawaited(
                            _applySessionSetting(
                              () => _sessions(
                                ref,
                              ).setModelControls(current.id, controls),
                            ),
                          ),
                          permissionMode: current.permissionMode,
                          // Not routed through [_applySessionSetting]: the
                          // permission mode is not read at turn start, so the
                          // daemon never refuses it, and the composer already
                          // reports a save failure on the control itself.
                          onPermissionModeChanged: (mode) async {
                            await _sessions(
                              ref,
                            ).setPermissionMode(current.id, mode);
                          },
                        ),
                        onModeToggled: () => unawaited(
                          _applySessionSetting(
                            () => _sessions(ref).setMode(
                              current.id,
                              current.mode == SessionMode.plan
                                  ? SessionMode.normal
                                  : SessionMode.plan,
                            ),
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
        await _applySessionSetting(
          () => _sessions(ref).setMode(
            session.id,
            session.mode == SessionMode.plan
                ? SessionMode.normal
                : SessionMode.plan,
          ),
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
    // A user reaching this has hit a bug, not a situation to explain: the
    // caller is supposed to check the connection first. Left in English for
    // whoever reads the crash report.
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
