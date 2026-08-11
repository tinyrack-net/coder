import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The lifecycle indicator of one subagent: a spinner while it works, an
/// attention icon while it waits on the user, a status icon once it stopped.
class SubagentStatusIcon extends StatelessWidget {
  /// Creates a lifecycle indicator.
  const SubagentStatusIcon({
    required this.lifecycle,
    this.status,
    super.key,
  });

  /// The lifecycle to render; null renders as pending.
  final AgentLifecycle? lifecycle;

  /// The session status, which distinguishes a subagent that is working from
  /// one parked on an approval only the user can answer.
  final SessionStatus? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.tinyrackTheme;
    // A blocked subagent is still `running`, so lifecycle alone would render
    // it as a spinner and hide the one row the user has to act on.
    if (status == SessionStatus.waitingForApproval) {
      return Icon(
        TinestIcons.approvalPending,
        color: colors.warning,
        semanticLabel: l10n.subagentStatusWaitingForApproval,
      );
    }
    return switch (lifecycle) {
      AgentLifecycle.running || AgentLifecycle.pendingInit || null => TRSpinner(
        uiSize: TRUiSize.sm,
        variant: TRSpinnerVariant.muted,
        label: l10n.subagentStatusRunning,
      ),
      AgentLifecycle.errored => Icon(
        TinestIcons.error,
        color: colors.danger,
        semanticLabel: l10n.subagentStatusErrored,
      ),
      AgentLifecycle.interrupted => Icon(
        TinestIcons.paused,
        color: colors.textMuted,
        semanticLabel: l10n.subagentStatusInterrupted,
      ),
      AgentLifecycle.completed => Icon(
        TinestIcons.success,
        color: colors.textMuted,
        semanticLabel: l10n.subagentStatusCompleted,
      ),
    };
  }
}
