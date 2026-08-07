import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/sessions/application/sessions_controller.dart';
import 'package:coder_app/src/features/terminals/application/terminals_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_tabs_controller.g.dart';

/// Visible and selected session and terminal tabs for one worktree.
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
    // Subagent sessions never open by default; they are reached through the
    // subagent track of their root conversation.
    final firstRoot = sessions
        .where((session) => session.parentSessionId == null)
        .firstOrNull;
    final open =
        saved?.openAgentIds
            .where(existingIds.contains)
            .toList(growable: false) ??
        <String>[if (firstRoot != null) firstRoot.id];
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
