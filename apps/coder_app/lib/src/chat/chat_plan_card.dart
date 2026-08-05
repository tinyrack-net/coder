import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_plan.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Renders the plan the agent recorded with `update_plan`.
///
/// Every step shows its own progress, so the card doubles as the live checklist
/// the agent ticks off while it works rather than only a plan-mode proposal.
class ChatPlanCard extends StatelessWidget {
  /// Creates a plan card.
  const ChatPlanCard({required this.proposal, super.key});

  /// The recorded plan.
  final ChatPlanProposal proposal;

  @override
  Widget build(BuildContext context) {
    final colors = context.tinyrackTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TRSpacing.extraSmall),
      child: TRCard(
        padding: TRCardPadding.none,
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(CoderIcons.plan, color: colors.primary),
                  const SizedBox(width: TRSpacing.small),
                  TRText(
                    AppLocalizations.of(context).chatPlanTitle,
                    variant: TRTextVariant.headingSm,
                    color: TRTextColor.primary,
                  ),
                ],
              ),
              const SizedBox(height: TRSpacing.small),
              for (final step in proposal.steps)
                _PlanStepRow(key: ValueKey<String>(step.step), step: step),
              if (proposal.explanation.isNotEmpty) ...<Widget>[
                const SizedBox(height: TRSpacing.small),
                TRText(
                  proposal.explanation,
                  variant: TRTextVariant.bodySm,
                  color: TRTextColor.muted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.step, super.key});

  final ChatPlanStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.tinyrackTheme;
    final l10n = AppLocalizations.of(context);
    final (IconData icon, Color color, String status) = switch (step.status) {
      ChatPlanStepStatus.completed => (
        CoderIcons.success,
        colors.success,
        l10n.chatPlanStepCompleted,
      ),
      ChatPlanStepStatus.inProgress => (
        CoderIcons.status,
        colors.primary,
        l10n.chatPlanStepInProgress,
      ),
      ChatPlanStepStatus.pending => (
        CoderIcons.unchecked,
        colors.textMuted,
        l10n.chatPlanStepPending,
      ),
    };
    return Semantics(
      label: '${step.step}, $status',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: TRSpacing.threeExtraSmall,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              // Nudge the marker onto the first line's optical centre.
              padding: const EdgeInsets.only(top: TRSpacing.threeExtraSmall),
              child: Icon(
                icon,
                size: TRTypography.bodySm.fontSize,
                color: color,
              ),
            ),
            const SizedBox(width: TRSpacing.small),
            Expanded(
              child: TRText(
                step.step,
                color: step.status == ChatPlanStepStatus.pending
                    ? TRTextColor.muted
                    : TRTextColor.defaultColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
