import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/conversation/application/attachment_ports.dart';
import 'package:coder_app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_plan.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/sessions/application/session_tabs_controller.dart';
import 'package:coder_app/src/features/sessions/application/sessions_controller.dart';
import 'package:coder_app/src/features/sessions/domain/session_title.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

// The two prompts below are sent to the model, not shown to the user, so they
// are deliberately left out of the localized strings.

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
    this.embedded = false,
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

  /// Whether the controls are already hosted by the plan card.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TRText(l10n.chatPlanPrompt, variant: TRTextVariant.headingSm),
        const SizedBox(height: TRSpacing.small),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: TRSpacing.small,
          runSpacing: TRSpacing.small,
          children: <Widget>[
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: onDismiss,
              child: TRText.inherit(l10n.chatPlanKeepPlanning),
            ),
            TRButton(
              appearance: TRAppearance.ghost,
              onPressed: () => unawaited(_startFreshSession(ref)),
              child: TRText.inherit(l10n.chatPlanRunInNewSession),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => unawaited(_implementHere(ref)),
              child: TRText.inherit(l10n.chatPlanRun),
            ),
          ],
        ),
      ],
    );
    if (embedded) return content;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TRSpacing.large,
        TRSpacing.small,
        TRSpacing.large,
        0,
      ),
      child: TRCard(
        padding: TRCardPadding.none,
        key: const ValueKey('chat-plan-actions'),
        variant: TRCardVariant.elevated,
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.medium),
          child: content,
        ),
      ),
    );
  }

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
    final markdown = ChatPlanUpdate(
      steps: proposal.steps,
      explanation: proposal.explanation,
    ).toMarkdown();
    final prompt = '$freshSessionPlanPreamble\n\n$markdown';
    // Dismiss only after the work is done; this widget owns the `ref` used by
    // `startSessionWithPrompt` and unmounts as soon as the card is dismissed.
    final created = await startSessionWithPrompt(
      ref,
      selection: selection,
      agentDefinitionId: session.agentDefinitionId,
      model: session.model,
      title: deriveSessionTitle(proposal.steps.first.step),
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
  // The caller may never have rendered this worktree - the new-workspace
  // composer starts a session on one it just created - so hold the providers
  // alive across the awaits instead of letting them dispose mid-sequence.
  final sessionsHandle = ref.listenManual(sessions, (previous, next) {});
  final tabsHandle = ref.listenManual(
    sessionTabsControllerProvider(selection),
    (previous, next) {},
  );
  try {
    await Future.wait(<Future<Object?>>[
      ref.read(sessions.future),
      ref.read(sessionTabsControllerProvider(selection).future),
    ]);
    final session = await ref
        .read(sessions.notifier)
        .create(
          title: title,
          agentDefinitionId: agentDefinitionId,
          mode: mode,
          model: model,
          modelControls: modelControls,
          permissionMode: permissionMode,
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
      await ref
          .read(conversation.notifier)
          .startTurn(prompt, attachments: attachments);
    } finally {
      conversationHandle.close();
    }
    return session;
  } finally {
    tabsHandle.close();
    sessionsHandle.close();
  }
}
