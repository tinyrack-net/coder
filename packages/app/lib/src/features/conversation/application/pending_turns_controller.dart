import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_turns_controller.g.dart';

/// A first prompt whose daemon turn has not been accepted yet.
typedef PendingFirstTurn = ({
  String prompt,
  DateTime createdAt,
  bool failed,
  List<PendingAttachment> attachments,
});

@Riverpod(keepAlive: true)
/// First prompts of freshly created sessions, keyed by session id.
///
/// A new session navigates before its timeline subscription and first turn
/// complete, so the conversation pane renders the prompt from here as an
/// optimistic user bubble until the real timeline echoes it. A turn that
/// failed to start is marked rather than dropped: the auto-disposed
/// conversation state cannot yet hold it, so the mounted conversation pane
/// restores the entry in the composer once its conversation is live.
class PendingFirstTurns extends _$PendingFirstTurns {
  @override
  Map<String, PendingFirstTurn> build() => const <String, PendingFirstTurn>{};

  /// Records [prompt] as the pending first turn of [sessionId].
  void put(
    String sessionId,
    String prompt, {
    List<PendingAttachment> attachments = const <PendingAttachment>[],
  }) {
    state = <String, PendingFirstTurn>{
      ...state,
      sessionId: (
        prompt: prompt,
        createdAt: ref.read(appClockProvider).nowUtc(),
        failed: false,
        attachments: List<PendingAttachment>.unmodifiable(attachments),
      ),
    };
  }

  /// Marks the pending first turn of [sessionId] as failed to start.
  void markFailed(String sessionId) {
    final entry = state[sessionId];
    if (entry == null) return;
    state = <String, PendingFirstTurn>{
      ...state,
      sessionId: (
        prompt: entry.prompt,
        createdAt: entry.createdAt,
        failed: true,
        attachments: entry.attachments,
      ),
    };
  }

  /// Forgets the pending first turn of [sessionId].
  void clear(String sessionId) {
    if (!state.containsKey(sessionId)) return;
    state = <String, PendingFirstTurn>{...state}..remove(sessionId);
  }
}
