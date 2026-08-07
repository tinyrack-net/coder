import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/shared/presentation/coder_icons.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// The lifecycle indicator of one subagent: a spinner while it works, a
/// status icon once it stopped.
class SubagentStatusIcon extends StatelessWidget {
  /// Creates a lifecycle indicator.
  const SubagentStatusIcon({required this.lifecycle, super.key});

  /// The lifecycle to render; null renders as pending.
  final AgentLifecycle? lifecycle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.tinyrackTheme;
    return switch (lifecycle) {
      AgentLifecycle.running || AgentLifecycle.pendingInit || null => TRSpinner(
        uiSize: TRUiSize.sm,
        variant: TRSpinnerVariant.muted,
        label: l10n.subagentStatusRunning,
      ),
      AgentLifecycle.errored => Icon(
        CoderIcons.error,
        color: colors.danger,
        semanticLabel: l10n.subagentStatusErrored,
      ),
      AgentLifecycle.interrupted => Icon(
        CoderIcons.paused,
        color: colors.textMuted,
        semanticLabel: l10n.subagentStatusInterrupted,
      ),
      AgentLifecycle.completed => Icon(
        CoderIcons.success,
        color: colors.textMuted,
        semanticLabel: l10n.subagentStatusCompleted,
      ),
    };
  }
}
