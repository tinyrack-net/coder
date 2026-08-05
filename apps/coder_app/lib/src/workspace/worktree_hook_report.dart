import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Returns the first hook that failed, or null when every hook succeeded.
WorktreeHookRunDto? failedWorktreeHook(List<WorktreeHookRunDto> runs) {
  for (final run in runs) {
    if (run.exitCode != 0) return run;
  }
  return null;
}

/// Reports a failed worktree hook without blocking the lifecycle operation.
///
/// The checkout already exists or is already archived at this point, so the
/// failure is surfaced as a dismissible message with the captured output.
void reportWorktreeHookFailure(
  BuildContext context,
  List<WorktreeHookRunDto> runs,
) {
  final failure = failedWorktreeHook(runs);
  if (failure == null) return;
  final l10n = AppLocalizations.of(context);
  final phase = switch (failure.phase) {
    WorktreeHookPhase.setup => 'Setup',
    WorktreeHookPhase.teardown => 'Teardown',
  };
  // The archived worktree's own context is disposed with its row, so the
  // report is pushed onto the root navigator captured up front.
  final navigator = Navigator.of(context, rootNavigator: true);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_showHookOutput(l10n, navigator, failure, phase));
  });
}

Future<void> _showHookOutput(
  AppLocalizations l10n,
  NavigatorState navigator,
  WorktreeHookRunDto failure,
  String phase,
) {
  final output = <String>[
    if (failure.stdout.trim().isNotEmpty) failure.stdout.trim(),
    if (failure.stderr.trim().isNotEmpty) failure.stderr.trim(),
  ].join('\n');
  return showTRDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (context) => TRAlertDialog(
      title: Text(l10n.hookFailureTitle(phase)),
      description: Text(
        l10n.hookFailureMessage(phase, failure.exitCode, failure.command),
      ),
      content: SingleChildScrollView(
        child: SelectableText(
          '${failure.command}\n\nexit ${failure.exitCode}\n'
          '${output.isEmpty ? l10n.hookFailureNoOutput : output}',
        ),
      ),
      actions: <TRButton>[
        TRButton(
          appearance: TRAppearance.ghost,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonConfirm),
        ),
      ],
    ),
  );
}
