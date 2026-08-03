import 'dart:async';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';

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
  final phase = switch (failure.phase) {
    WorktreeHookPhase.setup => 'Setup',
    WorktreeHookPhase.teardown => 'Teardown',
  };
  // The archived worktree's own context is disposed with its list tile, so
  // the detail dialog is pushed onto the navigator captured up front.
  final navigator = Navigator.of(context, rootNavigator: true);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$phase 실패 (exit ${failure.exitCode}): ${failure.command}',
      ),
      action: SnackBarAction(
        label: '자세히',
        onPressed: () => unawaited(_showHookOutput(navigator, failure, phase)),
      ),
    ),
  );
}

Future<void> _showHookOutput(
  NavigatorState navigator,
  WorktreeHookRunDto failure,
  String phase,
) {
  final output = <String>[
    if (failure.stdout.trim().isNotEmpty) failure.stdout.trim(),
    if (failure.stderr.trim().isNotEmpty) failure.stderr.trim(),
  ].join('\n');
  return navigator.push(
    DialogRoute<void>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        title: Text('$phase hook 실패'),
        content: SingleChildScrollView(
          child: SelectableText(
            '${failure.command}\n\nexit ${failure.exitCode}\n'
            '${output.isEmpty ? '(출력 없음)' : output}',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    ),
  );
}
