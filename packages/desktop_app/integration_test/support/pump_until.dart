import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// How long an end-to-end wait may take before it counts as a failure.
///
/// These tests drive a real daemon, spawned MCP and shell processes, and Git
/// commands, so one step can legitimately take seconds, and a shared CI runner
/// is slower than a developer machine. A generous budget costs nothing on a
/// passing run, because every wait returns as soon as its condition holds; it
/// only has to stay well inside the job timeout so a genuine hang still fails.
const Duration e2eWaitBudget = Duration(seconds: 60);

/// Budget for a wait that spans a complete agent turn.
///
/// A turn reaches the provider, may call a tool, and streams its result back,
/// so it is the slowest thing these tests wait for.
const Duration e2eTurnBudget = Duration(seconds: 120);

/// Gap between polls.
///
/// The live binding schedules a real timer for a pump that carries a duration,
/// so every poll costs this much wall time. That is what makes the budgets
/// above real seconds rather than frame counts.
const Duration _pollInterval = Duration(milliseconds: 100);

/// Pumps until [condition] holds, and fails after [budget].
///
/// [description] completes the sentence "Timed out after 60s waiting for ...".
///
/// The pump comes before the first check on purpose. Callers wait on states
/// that the frame after their own action produces, such as a sent prompt
/// appearing in the transcript; checking first would read the state the action
/// was about to change and return immediately.
Future<void> pumpUntilCondition(
  WidgetTester tester,
  FutureOr<bool> Function() condition,
  String description, {
  Duration budget = e2eWaitBudget,
}) async {
  for (var polled = Duration.zero; polled < budget; polled += _pollInterval) {
    await tester.pump(_pollInterval);
    if (await condition()) return;
  }
  throw TestFailure(
    'Timed out after ${budget.inSeconds}s waiting for $description.',
  );
}

/// Pumps until [finder] matches at least one widget.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration budget = e2eWaitBudget,
}) => pumpUntilCondition(
  tester,
  () => finder.evaluate().isNotEmpty,
  '$finder',
  budget: budget,
);

/// Pumps until [finder] matches nothing.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration budget = e2eWaitBudget,
}) => pumpUntilCondition(
  tester,
  () => finder.evaluate().isEmpty,
  '$finder to disappear',
  budget: budget,
);

// The two helpers below poll state the widget tree does not own, so there is no
// frame to wait for and they read before their first delay.

/// Waits for [read] to produce a value, for state the widget tree does not own.
Future<T> awaitValue<T extends Object>(
  FutureOr<T?> Function() read,
  String description, {
  Duration budget = e2eWaitBudget,
}) async {
  for (var waited = Duration.zero; waited < budget; waited += _pollInterval) {
    final value = await read();
    if (value != null) return value;
    await Future<void>.delayed(_pollInterval);
  }
  throw TestFailure(
    'Timed out after ${budget.inSeconds}s waiting for $description.',
  );
}

/// Waits for [condition] without pumping, for state the widget tree does not
/// own, such as a native window reporting its own visibility.
Future<void> awaitCondition(
  FutureOr<bool> Function() condition,
  String description, {
  Duration budget = e2eWaitBudget,
}) async {
  for (var waited = Duration.zero; waited < budget; waited += _pollInterval) {
    if (await condition()) return;
    await Future<void>.delayed(_pollInterval);
  }
  throw TestFailure(
    'Timed out after ${budget.inSeconds}s waiting for $description.',
  );
}
