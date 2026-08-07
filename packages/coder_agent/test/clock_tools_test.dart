@Tags(<String>['feature_test__tool_clock__unit'])
library;

import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:test/test.dart';

void main() {
  late _FakeClock clock;
  late ToolExecutionContext context;

  setUp(() {
    clock = _FakeClock();
    context = ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
    );
  });

  Map<String, dynamic> decode(ToolResult result) =>
      jsonDecode(result.output) as Map<String, dynamic>;

  test('both tools read without asking for approval', () {
    for (final tool in <AgentTool>[
      CurrentTimeTool(clock: clock),
      SleepTool(clock: clock),
    ]) {
      expect(tool.risk, AgentToolRisk.read, reason: tool.name);
      expect(
        const DefaultApprovalPolicy(
          AgentPermissionMode.readOnly,
        ).evaluateRisk(tool.risk),
        ApprovalEvaluation.allow,
        reason: tool.name,
      );
      // Strict schemas reject a bare empty object on both provider APIs.
      final schema = tool.strictJsonSchema;
      expect(schema['type'], 'object', reason: tool.name);
      expect(schema['additionalProperties'], isFalse, reason: tool.name);
      expect(
        schema['required'],
        (schema['properties']! as Map<String, dynamic>).keys.toList(),
        reason: tool.name,
      );
    }
  });

  test('current_time reports UTC in two forms', () async {
    clock.now = DateTime.utc(2026, 8, 5, 14, 23, 1);

    final result = await CurrentTimeTool(
      clock: clock,
    ).execute(const <String, dynamic>{}, context);

    final decoded = decode(result);
    expect(decoded['utc'], '2026-08-05T14:23:01.000Z');
    expect(decoded['unixSeconds'], clock.now.millisecondsSinceEpoch ~/ 1000);
  });

  test('sleep reports how long it waited and why it stopped', () async {
    clock.outcome = SleepOutcome.elapsed;

    final elapsed = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 2000, 'reason': 'the build'},
      context,
    );

    expect(clock.slept.single, const Duration(seconds: 2));
    expect(decode(elapsed)['sleptMs'], 2000);
    expect(decode(elapsed)['outcome'], 'elapsed');

    clock.outcome = SleepOutcome.interrupted;
    final interrupted = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 2000, 'reason': null},
      context,
    );
    expect(decode(interrupted)['outcome'], 'interrupted');
  });

  test('the requested duration is clamped to the supported range', () async {
    final tool = SleepTool(clock: clock);

    await tool.execute(
      <String, dynamic>{'duration_ms': 1, 'reason': null},
      context,
    );
    await tool.execute(
      <String, dynamic>{'duration_ms': 999999999, 'reason': null},
      context,
    );

    expect(clock.slept, <Duration>[minSleepDuration, maxSleepDuration]);
  });

  test('a non-integer duration is corrected, not slept on', () async {
    final result = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 'soon', 'reason': null},
      context,
    );

    expect(result.isError, isTrue);
    expect(clock.slept, isEmpty);
  });

  test('the reason is what the user sees in the preview', () async {
    final tool = SleepTool(clock: clock);

    expect(
      await tool.preview(
        <String, dynamic>{'duration_ms': 1000, 'reason': 'waiting for CI'},
        context,
      ),
      'waiting for CI',
    );
    expect(
      await tool.preview(
        <String, dynamic>{'duration_ms': 1000, 'reason': null},
        context,
      ),
      isNull,
    );
  });

  test('a cancelled turn stops instead of finishing its sleep', () async {
    final cancellation = CancellationToken();
    clock.cancelBeforeSleep = cancellation;

    await expectLater(
      SleepTool(clock: clock).execute(
        <String, dynamic>{'duration_ms': 5000, 'reason': null},
        ToolExecutionContext(
          workspaceRoot: '/workspace',
          cancellation: cancellation,
        ),
      ),
      throwsA(isA<AgentCancelledException>()),
    );
  });

  test('a turn cancelled before the call never sleeps at all', () async {
    final cancellation = CancellationToken()..cancel();

    await expectLater(
      SleepTool(clock: clock).execute(
        <String, dynamic>{'duration_ms': 5000, 'reason': null},
        ToolExecutionContext(
          workspaceRoot: '/workspace',
          cancellation: cancellation,
        ),
      ),
      throwsA(isA<AgentCancelledException>()),
    );
    expect(clock.slept, isEmpty);
  });
}

final class _FakeClock implements AgentClock {
  DateTime now = DateTime.utc(2026);
  SleepOutcome outcome = SleepOutcome.elapsed;
  final List<Duration> slept = <Duration>[];

  /// Cancelled just before the sleep resolves, if set.
  CancellationToken? cancelBeforeSleep;

  @override
  DateTime nowUtc() => now;

  @override
  Future<SleepOutcome> sleep(
    Duration duration,
    CancellationToken cancellation,
  ) async {
    slept.add(duration);
    cancelBeforeSleep?.cancel();
    cancellation.throwIfCancelled();
    return outcome;
  }
}
