import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Compact controls for one persistent session goal.
class GoalStatusBar extends StatelessWidget {
  /// Creates the goal status bar.
  const GoalStatusBar({
    required this.goal,
    required this.sessionMode,
    required this.onEdit,
    required this.onStatusChanged,
    required this.onClear,
    super.key,
  });

  /// Current goal generation.
  final GoalDto goal;

  /// Determines whether continuation is held for planning.
  final SessionMode sessionMode;

  /// Opens objective and budget editing.
  final VoidCallback onEdit;

  /// Pauses or resumes the goal.
  final ValueChanged<GoalStatus> onStatusChanged;

  /// Removes the goal.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resumable =
        goal.status == GoalStatus.paused ||
        goal.status == GoalStatus.blocked ||
        goal.status == GoalStatus.usageLimited;
    final canToggle = goal.status == GoalStatus.active || resumable;
    final progress = goal.tokenBudget == null
        ? null
        : goal.tokensUsed.toDouble();
    final detail =
        sessionMode == SessionMode.plan && goal.status == GoalStatus.active
        ? l10n.goalPlanHold
        : goal.tokenBudget == null
        ? l10n.goalElapsed(goal.timeUsedSeconds)
        : l10n.goalTokenUsage(goal.tokensUsed, goal.tokenBudget!);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TRSpacing.medium,
        TRSpacing.extraSmall,
        TRSpacing.medium,
        TRSpacing.extraSmall,
      ),
      child: TRCard(
        key: const ValueKey<String>('goal-status-bar'),
        padding: TRCardPadding.sm,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: TRSpacing.small,
              runSpacing: TRSpacing.extraSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                TRBadge(
                  variant: _variant(goal.status),
                  uiSize: TRUiSize.sm,
                  child: TRText.inherit(_status(l10n, goal.status)),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: TRSpacing.extraLarge,
                  ),
                  child: TRText(
                    goal.objective,
                    variant: TRTextVariant.bodySm,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TRText(
                  detail,
                  variant: TRTextVariant.bodySm,
                  color: TRTextColor.muted,
                ),
                if (canToggle)
                  TRIconButton(
                    appearance: TRAppearance.ghost,
                    label: resumable ? l10n.goalResume : l10n.goalPause,
                    onPressed: () => onStatusChanged(
                      resumable ? GoalStatus.active : GoalStatus.paused,
                    ),
                    icon: Icon(
                      resumable ? CoderIcons.resume : CoderIcons.paused,
                    ),
                  ),
                TRIconButton(
                  appearance: TRAppearance.ghost,
                  label: l10n.goalEdit,
                  onPressed: onEdit,
                  icon: const Icon(CoderIcons.edit),
                ),
                TRIconButton(
                  appearance: TRAppearance.ghost,
                  label: l10n.goalClear,
                  onPressed: onClear,
                  icon: const Icon(CoderIcons.delete),
                ),
              ],
            ),
            if (progress != null) ...<Widget>[
              const SizedBox(height: TRSpacing.extraSmall),
              TRProgress(
                value: progress,
                max: goal.tokenBudget!.toDouble(),
                label: detail,
                variant: _variant(goal.status),
                uiSize: TRUiSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static TRStatusVariant _variant(GoalStatus status) => switch (status) {
    GoalStatus.active => TRStatusVariant.info,
    GoalStatus.complete => TRStatusVariant.success,
    GoalStatus.paused => TRStatusVariant.neutral,
    GoalStatus.blocked ||
    GoalStatus.usageLimited ||
    GoalStatus.budgetLimited => TRStatusVariant.warning,
  };

  static String _status(AppLocalizations l10n, GoalStatus status) =>
      switch (status) {
        GoalStatus.active => l10n.goalStatusActive,
        GoalStatus.paused => l10n.goalStatusPaused,
        GoalStatus.blocked => l10n.goalStatusBlocked,
        GoalStatus.usageLimited => l10n.goalStatusUsageLimited,
        GoalStatus.budgetLimited => l10n.goalStatusBudgetLimited,
        GoalStatus.complete => l10n.goalStatusComplete,
      };
}

/// Shows the objective and optional token-budget editor.
Future<({String objective, int? tokenBudget})?> showGoalEditor(
  BuildContext context, {
  GoalDto? goal,
}) => showTRDialog<({String objective, int? tokenBudget})>(
  context: context,
  builder: (context) => _GoalEditorDialog(goal: goal),
);

class _GoalEditorDialog extends StatefulWidget {
  const _GoalEditorDialog({this.goal});

  final GoalDto? goal;

  @override
  State<_GoalEditorDialog> createState() => _GoalEditorDialogState();
}

class _GoalEditorDialogState extends State<_GoalEditorDialog> {
  late final TextEditingController _objective = TextEditingController(
    text: widget.goal?.objective,
  );
  late double? _budget = widget.goal?.tokenBudget?.toDouble();
  bool _submitted = false;

  int? get _parsedBudget => _budget?.round();

  bool get _valid =>
      _objective.text.trim().isNotEmpty &&
      _objective.text.trim().runes.length <= 4000 &&
      (_budget == null || (_parsedBudget ?? 0) > 0);

  @override
  void dispose() {
    _objective.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TRAlertDialog(
      semanticLabel: l10n.goalDialogTitle,
      title: TRText.inherit(l10n.goalDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TRTextField(
            controller: _objective,
            autofocus: true,
            maxLines: 5,
            label: l10n.goalObjectiveLabel,
            errorText:
                _submitted &&
                    (_objective.text.trim().isEmpty ||
                        _objective.text.trim().runes.length > 4000)
                ? l10n.goalObjectiveRequired
                : null,
            onChanged: (_) => setState(() {}),
          ),
          TRNumberField.controlled(
            value: _budget,
            label: l10n.goalBudgetLabel,
            min: 1,
            smallStep: 1,
            scrubbable: false,
            errorText:
                _submitted && _budget != null && (_parsedBudget ?? 0) <= 0
                ? l10n.goalBudgetInvalid
                : null,
            onValueChange: (value) => setState(() => _budget = value),
          ),
        ],
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: TRText.inherit(l10n.commonCancel),
        ),
        TRButton(
          intent: TRIntent.primary,
          onPressed: () {
            setState(() => _submitted = true);
            if (!_valid) return;
            Navigator.pop(
              context,
              (
                objective: _objective.text.trim(),
                tokenBudget: _parsedBudget,
              ),
            );
          },
          child: TRText.inherit(
            widget.goal == null ||
                    widget.goal?.status == GoalStatus.complete ||
                    widget.goal?.status == GoalStatus.budgetLimited
                ? l10n.goalStart
                : l10n.commonSave,
          ),
        ),
      ],
    );
  }
}
