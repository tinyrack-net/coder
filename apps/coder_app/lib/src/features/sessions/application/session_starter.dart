import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:coder_app/src/features/sessions/application/sessions_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts a session without borrowing the lifecycle of the submitting widget.
final sessionStarterProvider = Provider<SessionStarter>(SessionStarter.new);

/// Coordinates session creation, tab promotion, and the first turn.
///
/// The provider is deliberately not auto-disposed: a draft tab is replaced by
/// its session while this operation is running, so the widget that submitted
/// the prompt can unmount before the daemon finishes creating the session.
final class SessionStarter {
  /// Creates a starter owned by the application provider container.
  SessionStarter(this._ref);

  final Ref _ref;

  /// Creates a session, opens its tab, and starts its first turn.
  Future<SessionDto> start({
    required WorkspaceSelection selection,
    required String agentDefinitionId,
    required String title,
    required String prompt,
    String? draftTabId,
    List<PendingAttachment> attachments = const <PendingAttachment>[],
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
    Map<String, ModelControlValueDto> modelControls =
        const <String, ModelControlValueDto>{},
    PermissionMode? permissionMode,
  }) async {
    final sessions = sessionsControllerProvider(
      selection.hostId,
      selection.worktreeId,
    );
    final tabs = sessionTabsControllerProvider(selection);
    final sessionsHandle = _ref.listen(sessions, (previous, next) {});
    final tabsHandle = _ref.listen(tabs, (previous, next) {});
    try {
      await Future.wait(<Future<Object?>>[
        _ref.read(sessions.future),
        _ref.read(tabs.future),
      ]);
      final session = await _ref
          .read(sessions.notifier)
          .create(
            title: title,
            agentDefinitionId: agentDefinitionId,
            mode: mode,
            model: model,
            modelControls: modelControls,
            permissionMode: permissionMode,
          );
      final conversation = conversationControllerProvider(
        selection.hostId,
        session.id,
      );
      final conversationHandle = _ref.listen(
        conversation,
        (previous, next) {},
      );
      try {
        // Install the timeline subscription before starting the turn. The
        // draft remains on screen until the first turn is accepted, and the
        // exact draft is then promoted in one tab-state update.
        await _ref.read(conversation.future);
        await _ref
            .read(conversation.notifier)
            .startTurn(prompt, attachments: attachments);
        await _ref.read(tabs.notifier).add(session, draftTabId: draftTabId);
      } finally {
        conversationHandle.close();
      }
      return session;
    } finally {
      tabsHandle.close();
      sessionsHandle.close();
    }
  }
}
