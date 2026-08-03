import 'dart:async';

import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Prompt sent when the user accepts a plan in the current session.
const String implementPlanPrompt = '계획을 실행해줘.';

/// Preamble sent when a plan is handed to a brand-new session.
const String freshSessionPlanPreamble =
    '이전 에이전트가 사용자의 요청을 위해 아래 계획을 세웠습니다. '
    '이 계획을 새로운 컨텍스트에서 구현하세요. 계획을 사용자 의도의 근거로 삼되, '
    '필요한 파일은 다시 읽고 구현과 검증까지 진행하세요.';

/// Asks whether the proposed plan should be carried out.
///
/// Mirrors the Codex "Implement this plan?" prompt: accept in place, accept in
/// a fresh session, or keep planning.
class ChatPlanActions extends ConsumerWidget {
  /// Creates the plan action card.
  const ChatPlanActions({
    required this.selection,
    required this.session,
    required this.proposal,
    required this.onDismiss,
    required this.onSessionCreated,
    super.key,
  });

  /// Worktree owning the session.
  final WorkspaceSelection selection;

  /// Session that produced the plan.
  final SessionDto session;

  /// The plan awaiting a decision.
  final ChatPlanProposal proposal;

  /// Called when the user chooses to keep planning.
  final VoidCallback onDismiss;

  /// Called with a session started from the plan in a fresh context.
  final ValueChanged<SessionDto> onSessionCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Card(
      key: const ValueKey('chat-plan-actions'),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '이 계획대로 진행할까요?',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('계속 계획'),
                ),
                TextButton(
                  onPressed: () => unawaited(_startFreshSession(ref)),
                  child: const Text('새 세션에서 실행'),
                ),
                FilledButton(
                  onPressed: () => unawaited(_implementHere(ref)),
                  child: const Text('계획대로 실행'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _implementHere(WidgetRef ref) async {
    // Read the notifiers first: dismissing unmounts this widget, and `ref` is
    // unusable afterwards.
    final sessions = ref.read(
      sessionsControllerProvider(
        selection.hostId,
        selection.worktreeId,
      ).notifier,
    );
    final conversation = ref.read(
      conversationControllerProvider(selection.hostId, session.id).notifier,
    );
    onDismiss();
    await sessions.setMode(session.id, SessionMode.normal);
    await conversation.startTurn(implementPlanPrompt);
  }

  Future<void> _startFreshSession(WidgetRef ref) async {
    final prompt = '$freshSessionPlanPreamble\n\n${proposal.markdown}';
    // Dismiss only after the work is done; this widget owns the `ref` used by
    // `startSessionWithPrompt` and unmounts as soon as the card is dismissed.
    final created = await startSessionWithPrompt(
      ref,
      selection: selection,
      agentDefinitionId: session.agentDefinitionId,
      model: session.model,
      title: deriveSessionTitle(proposal.markdown),
      prompt: prompt,
    );
    onDismiss();
    onSessionCreated(created);
  }
}

/// Creates a session, opens its tab, and starts its first turn.
///
/// Shared by the draft composer and the plan hand-off so both keep the same
/// ordering: the turn starts before navigation because the caller unmounts.
Future<SessionDto> startSessionWithPrompt(
  WidgetRef ref, {
  required WorkspaceSelection selection,
  required String agentDefinitionId,
  required String title,
  required String prompt,
  SessionMode mode = SessionMode.normal,
  SessionModelSelectionDto? model,
}) async {
  final sessions = sessionsControllerProvider(
    selection.hostId,
    selection.worktreeId,
  );
  // The caller may never have rendered this worktree - the new-workspace
  // composer starts a session on one it just created - so hold the providers
  // alive across the awaits instead of letting them dispose mid-sequence.
  final sessionsHandle = ref.listenManual(sessions, (previous, next) {});
  final tabsHandle = ref.listenManual(
    sessionTabsControllerProvider(selection),
    (previous, next) {},
  );
  try {
    await ref.read(sessions.future);
    final session = await ref
        .read(sessions.notifier)
        .create(
          title: title,
          agentDefinitionId: agentDefinitionId,
          mode: mode,
          model: model,
        );
    await ref
        .read(sessionTabsControllerProvider(selection).notifier)
        .add(session);
    final conversation = conversationControllerProvider(
      selection.hostId,
      session.id,
    );
    final conversationHandle = ref.listenManual(
      conversation,
      (previous, next) {},
    );
    try {
      await ref.read(conversation.notifier).startTurn(prompt);
    } finally {
      conversationHandle.close();
    }
    return session;
  } finally {
    tabsHandle.close();
    sessionsHandle.close();
  }
}
