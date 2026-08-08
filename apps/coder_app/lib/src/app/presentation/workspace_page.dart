import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/app/presentation/new_workspace_pane.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/agents/application/agent_definitions_controller.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/conversation/application/subagent_track_model.dart';
import 'package:coder_app/src/features/conversation/domain/composer_commands.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_plan_actions.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_question_card.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_timeline_view.dart';
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
import 'package:coder_app/src/shared/presentation/coder_layout.dart';
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
    return CoderPageShell(
      appBar: CoderPageHeader(
        // The toggle keeps one position in both states: the very top left.
        leading:
            MediaQuery.sizeOf(context).width < CoderLayout.compactBreakpoint
            ? null
            : TRIconButton(
                appearance: TRAppearance.ghost,
                key: const ValueKey('workspace-sidebar-toggle'),
                label: collapsed
                    ? AppLocalizations.of(context).workspaceSidebarExpand
                    : AppLocalizations.of(context).workspaceSidebarCollapse,
                onPressed: () => unawaited(_setSidebarCollapsed(!collapsed)),
                icon: Icon(collapsed ? CoderIcons.menu : CoderIcons.menuOpen),
              ),
        title: TRText.inherit(AppLocalizations.of(context).workspacesTitle),
        actions: <Widget>[
          TRIconButton(
            key: const ValueKey('workspace-settings-button'),
            appearance: TRAppearance.ghost,
            label: AppLocalizations.of(context).settingsTitle,
            onPressed: () {
              final hostId = widget.selection?.hostId;
              unawaited(
                hostId == null
                    ? const DaemonSettingsRoute().push<void>(context)
                    : ProviderSettingsRoute(hostId: hostId).push<void>(context),
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
            onOpenDaemonSettings: () =>
                unawaited(const DaemonSettingsRoute().push<void>(context)),
            onArchivedSelection: () =>
                const WorkspaceHomeRoute().replace(context),
          );
          final detail = widget.selection == null
              ? NewWorkspacePane(
                  showBack:
                      constraints.maxWidth < CoderLayout.compactBreakpoint,
                  onBack: () => const WorkspaceHomeRoute().replace(context),
                  onStarted: (selection, session) =>
                      _goSession(context, selection, session.id),
                )
              : _SessionArea(
                  // Selecting a checkout replaces the location rather than
                  // pushing, so this page is not rebuilt from scratch. Key the
                  // session area on the checkout so its tabs, conversation,
                  // and terminals still start clean on a different one.
                  key: ValueKey<WorkspaceSelection>(widget.selection!),
                  selection: widget.selection!,
                  requestedAgentId: widget.requestedAgentId,
                  requestedTerminalId: widget.requestedTerminalId,
                  showBack:
                      constraints.maxWidth < CoderLayout.compactBreakpoint,
                );
          if (constraints.maxWidth < CoderLayout.compactBreakpoint) {
            return widget.selection == null && !widget.compose
                ? sidebar
                : detail;
          }
          return Row(
            children: <Widget>[
              // The sidebar owns its width so collapsing animates instead of
              // dropping the pane out of the row.
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
    this.showBack = false,
    super.key,
  });

  final WorkspaceSelection selection;
  final String? requestedAgentId;
  final String? requestedTerminalId;
  final bool showBack;

  @override
  ConsumerState<_SessionArea> createState() => _SessionAreaState();
}

class _SessionAreaState extends ConsumerState<_SessionArea> {
  // Selecting a session or terminal replaces the location rather than pushing,
  // so this state outlives the change. These remember which id was opened
  // instead of latching on "have I opened one", or the second location to name
  // a session would never open it.
  String? _openedAgentId;
  String? _openedTerminalId;

  @override
  Widget build(BuildContext context) {
    final provider = sessionTabsControllerProvider(widget.selection);
    final tabs = ref.watch(provider);
    final state = tabs.asData?.value;
    if (widget.requestedAgentId != null &&
        widget.requestedAgentId != _openedAgentId &&
        state != null &&
        state.sessions.any((item) => item.id == widget.requestedAgentId)) {
      _openedAgentId = widget.requestedAgentId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref.read(provider.notifier).open(widget.requestedAgentId!),
          );
        }
      });
    }
    if (widget.requestedTerminalId != null &&
        widget.requestedTerminalId != _openedTerminalId &&
        state != null &&
        state.terminals.any(
          (item) => item.id == widget.requestedTerminalId,
        )) {
      _openedTerminalId = widget.requestedTerminalId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref
                .read(provider.notifier)
                .openTerminal(
                  widget.requestedTerminalId!,
                ),
          );
        }
      });
    }
    return Column(
      children: <Widget>[
        TRTabs.bar(
          key: const ValueKey<String>('session-tab-strip'),
          semanticLabel: AppLocalizations.of(context).workspaceAllSessions,
          value: state?.selectedTerminalId ?? state?.selectedAgentId,
          onValueChange: _selectTab,
          leading: widget.showBack
              ? TRIconButton(
                  appearance: TRAppearance.ghost,
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => const WorkspaceHomeRoute().replace(context),
                  icon: const Icon(CoderIcons.back),
                )
              : null,
          tabs: <TRTabsTab>[
            if (state != null) ...<TRTabsTab>[
              for (final id in state.openAgentIds)
                _sessionTab(
                  context,
                  state.sessions.where((item) => item.id == id).first,
                ),
              for (final id in state.openTerminalIds)
                _terminalTab(
                  context,
                  state.terminals.where((item) => item.id == id).first,
                ),
            ],
          ],
          actions: <Widget>[
            // Until the tabs load there is nothing to command, so the strip
            // spins where the menus will be rather than offering menus that
            // would open onto an empty list.
            if (state == null)
              const TRSpinner()
            else ...<Widget>[
              TRMenu.icon(
                key: const ValueKey<String>('workspace-new-tab-menu'),
                icon: const Icon(CoderIcons.add),
                label: AppLocalizations.of(context).workspaceNewTab,
                menuChildren: <Widget>[
                  TRMenuItem(
                    key: const ValueKey<String>('workspace-new-session'),
                    onPressed: _startDraft,
                    leadingIcon: const Icon(CoderIcons.chat),
                    child: TRText.inherit(
                      AppLocalizations.of(context).workspaceNewSession,
                    ),
                  ),
                  TRMenuItem(
                    key: const ValueKey<String>('workspace-new-terminal'),
                    onPressed: _createTerminal,
                    leadingIcon: const Icon(CoderIcons.terminal),
                    child: TRText.inherit(
                      AppLocalizations.of(context).workspaceNewTerminal,
                    ),
                  ),
                ],
              ),
              TRMenu.icon(
                key: const ValueKey('workspace-all-sessions-menu'),
                icon: const Icon(CoderIcons.more),
                label: AppLocalizations.of(context).workspaceAllSessions,
                menuChildren: <Widget>[
                  // Subagent sessions open through the subagent track of
                  // their root conversation, never from the tab menu.
                  for (final agent in state.sessions.where(
                    (session) => !isSubagentSession(session),
                  ))
                    TRMenuItem(
                      onPressed: () => _open(agent.id),
                      child: TRText.inherit(agent.title),
                    ),
                  for (final terminal in state.terminals)
                    TRMenuItem(
                      leadingIcon: const Icon(CoderIcons.terminal),
                      onPressed: () => _openTerminal(terminal.id),
                      child: TRText.inherit(terminal.title),
                    ),
                ],
              ),
            ],
          ],
        ),
        Expanded(
          child: switch ((
            state?.selectedTerminalId,
            state?.selectedAgentId,
          )) {
            // Keyed per terminal because the pane's state owns that terminal's
            // emulator, event subscription, and last-seen sequence. Reusing it
            // across a tab switch would keep the previous terminal's sequence
            // and silently drop the new one's replay.
            (final terminalId?, _) => _TerminalPane(
              key: ValueKey<String>('terminal-pane-$terminalId'),
              selection: widget.selection,
              terminal: state!.terminals
                  .where((item) => item.id == terminalId)
                  .first,
            ),
            (_, null) => DraftSessionPane(
              selection: widget.selection,
              onCreated: (session) =>
                  _goSession(context, widget.selection, session.id),
            ),
            (_, final agentId?) => _ConversationPane(
              selection: widget.selection,
              agent: state!.sessions.where((item) => item.id == agentId).first,
            ),
          },
        ),
      ],
    );
  }

  TRTabsTab _sessionTab(BuildContext context, SessionDto agent) {
    final subagent = isSubagentSession(agent);
    return TRTabsTab(
      value: agent.id,
      label: subagent ? agent.taskName ?? agent.title : agent.title,
      leading: subagent ? SubagentStatusIcon(lifecycle: agent.lifecycle) : null,
      onClose: () => unawaited(_close(agent.id)),
      closeLabel: AppLocalizations.of(context).workspaceCloseTab,
    );
  }

  TRTabsTab _terminalTab(BuildContext context, TerminalDto terminal) =>
      TRTabsTab(
        value: terminal.id,
        label: terminal.title,
        leading: const Icon(CoderIcons.terminal),
        onClose: () => unawaited(_closeTerminal(terminal.id)),
        closeLabel: AppLocalizations.of(context).workspaceCloseTab,
      );

  /// Routes a tab id to the right selector.
  ///
  /// Sessions and terminals share one strip, so the strip reports an id
  /// without knowing which kind it names.
  void _selectTab(String id) {
    final state = ref
        .read(sessionTabsControllerProvider(widget.selection))
        .value;
    if (state == null) return;
    unawaited(
      state.terminals.any((terminal) => terminal.id == id)
          ? _selectTerminal(id)
          : _select(id),
    );
  }

  Future<void> _select(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .select(id);
    if (mounted) _goSession(context, widget.selection, id);
  }

  Future<void> _open(String id) async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .open(id);
    if (mounted) _goSession(context, widget.selection, id);
  }

  Future<void> _close(String id) async {
    final notifier = ref.read(
      sessionTabsControllerProvider(widget.selection).notifier,
    );
    await notifier.close(id);
    if (!mounted) return;
    final selected = ref
        .read(sessionTabsControllerProvider(widget.selection))
        .requireValue
        .selectedAgentId;
    if (selected == null) {
      _goWorktree(context, widget.selection);
    } else {
      _goSession(context, widget.selection, selected);
    }
  }

  Future<void> _startDraft() async {
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .startDraft();
    if (mounted) _goWorktree(context, widget.selection);
  }

  Future<void> _createTerminal() async {
    final terminal = await ref
        .read(
          terminalsControllerProvider(
            widget.selection.hostId,
            widget.selection.worktreeId,
          ).notifier,
        )
        .create();
    await ref
        .read(sessionTabsControllerProvider(widget.selection).notifier)
        .addTerminal(terminal);
  }

  Future<void> _selectTerminal(String id) => ref
      .read(sessionTabsControllerProvider(widget.selection).notifier)
      .selectTerminal(id);

  Future<void> _openTerminal(String id) => ref
      .read(sessionTabsControllerProvider(widget.selection).notifier)
      .openTerminal(id);

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
  const _ConversationPane({required this.selection, required this.agent});

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
    final l10n = AppLocalizations.of(context);
    final conversation = ref.watch(
      conversationControllerProvider(widget.selection.hostId, current.id),
    );
    final value = conversation.asData?.value;
    final items = projectChatTimeline(
      value?.timeline ?? const <TimelineEventDto>[],
    );
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
    final lastPlan = items.whereType<ChatPlanProposal>().lastOrNull;
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
                items: items,
                busy: busy,
                loadAttachment: _loadAttachment,
                exportAttachment: _exportAttachment,
              ),
            ),
            // A plan and any number of approvals sit between the timeline and
            // the composer, and each grows with the content it previews. The
            // bottom group is capped so the composer always keeps its natural
            // size and only the cards scroll; whatever the group leaves over
            // goes back to the timeline above.
            if (!readOnly)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (pendingPlan != null)
                              ChatPlanActions(
                                selection: widget.selection,
                                session: current,
                                proposal: pendingPlan,
                                onDismiss: () => setState(
                                  () => _dismissedPlans.add(pendingPlan.key),
                                ),
                                onSessionCreated: (session) => _goSession(
                                  context,
                                  widget.selection,
                                  session.id,
                                ),
                              ),
                            for (final approval
                                in value?.approvals.values ??
                                    const <ApprovalRequestDto>[])
                              ApprovalCard(
                                hostId: widget.selection.hostId,
                                approval: approval,
                              ),
                            for (final question
                                in value?.questions.values ??
                                    const <UserQuestionRequestDto>[])
                              ChatQuestionCard(
                                hostId: widget.selection.hostId,
                                request: question,
                              ),
                          ],
                        ),
                      ),
                    ),
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
                          onModelChanged: (model) => unawaited(
                            ref
                                .read(
                                  sessionsControllerProvider(
                                    widget.selection.hostId,
                                    widget.selection.worktreeId,
                                  ).notifier,
                                )
                                .setModel(current.id, model),
                          ),
                          reasoningEffort: current.reasoningEffort,
                          onReasoningEffortChanged: (effort) => unawaited(
                            _sessions(
                              ref,
                            ).setReasoningEffort(current.id, effort),
                          ),
                          permissionMode: current.permissionMode,
                          onPermissionModeChanged: (mode) async {
                            await _sessions(
                              ref,
                            ).setPermissionMode(current.id, mode);
                          },
                          serviceTier: current.serviceTier,
                          onServiceTierChanged: (tier) => unawaited(
                            _sessions(ref).setServiceTier(current.id, tier),
                          ),
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
      case ClientCommandAction.help:
        // Typing `/` already lists every command, so help only reopens it.
        break;
    }
    return true;
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
