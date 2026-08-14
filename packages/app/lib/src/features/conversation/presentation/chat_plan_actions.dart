import 'dart:async';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/application/conversation_controller.dart';
import 'package:app/src/features/conversation/presentation/chat_plan.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/sessions/application/session_starter.dart';
import 'package:app/src/features/sessions/application/sessions_controller.dart';
import 'package:app/src/features/sessions/domain/session_title.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

// The two prompts below reach the model rather than the screen, but they are
// still localized: the language a request is written in is the strongest hint
// the model has about which language to answer in, and the answer is what the
// user reads.

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
              onPressed: () => unawaited(_startFreshSession(ref, l10n)),
              child: TRText.inherit(l10n.chatPlanRunInNewSession),
            ),
            TRButton(
              intent: TRIntent.primary,
              onPressed: () => unawaited(_implementHere(ref, l10n)),
              child: TRText.inherit(l10n.chatPlanRun),
            ),
          ],
        ),
      ],
    );
    if (embedded) return content;
    return Padding(
      padding: const EdgeInsets.only(
        left: TRSpacing.large,
        top: TRSpacing.small,
        right: TRSpacing.large,
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

  Future<void> _implementHere(WidgetRef ref, AppLocalizations l10n) async {
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
    await conversation.startTurn(l10n.planImplementPrompt);
  }

  Future<void> _startFreshSession(WidgetRef ref, AppLocalizations l10n) async {
    final markdown = ChatPlanUpdate(
      steps: proposal.steps,
      explanation: proposal.explanation,
    ).toMarkdown();
    final prompt = '${l10n.planFreshSessionPreamble}\n\n$markdown';
    final created = await startSessionWithPrompt(
      ref,
      selection: selection,
      agentDefinitionId: session.agentDefinitionId,
      model: session.model,
      title: deriveSessionTitle(
        proposal.steps.first.step,
        fallback: l10n.sessionDefaultTitle,
      ),
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
  String? draftTabId,
  List<PendingAttachment> attachments = const <PendingAttachment>[],
  SessionMode mode = SessionMode.normal,
  ModelSelectionDto? model,
  Map<String, ModelControlValueDto> modelControls =
      const <String, ModelControlValueDto>{},
  PermissionMode? permissionMode,
}) => ref
    .read(sessionStarterProvider)
    .start(
      selection: selection,
      agentDefinitionId: agentDefinitionId,
      title: title,
      prompt: prompt,
      draftTabId: draftTabId,
      attachments: attachments,
      mode: mode,
      model: model,
      modelControls: modelControls,
      permissionMode: permissionMode,
    );
