@Tags(<String>['feature_test__tool_clock__unit'])
library;

import 'package:agent/agent.dart';
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

  test('clock__curr_time returns the canonical UTC form', () async {
    clock.now = DateTime.utc(2026, 8, 5, 14, 23, 1);

    final result = await CurrentTimeTool(
      clock: clock,
    ).execute(const <String, dynamic>{}, context);

    expect(result.value, '2026-08-05 14:23:01 UTC');
    final codeMode = await CurrentTimeTool(clock: clock).execute(
      const <String, dynamic>{},
      ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
        toolSurfaceMode: AgentToolSurfaceMode.luaCode,
      ),
    );
    expect(codeMode.value, <String, dynamic>{
      'current_time': '2026-08-05 14:23:01 UTC',
    });
  });

  test('sleep reports how long it waited and why it stopped', () async {
    clock.outcome = SleepOutcome.elapsed;

    final elapsed = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 2000},
      context,
    );

    expect(clock.slept.single, const Duration(seconds: 2));
    expect(elapsed.output, contains('Sleep completed.'));
    expect(elapsed.output, startsWith('Wall time: '));

    clock.outcome = SleepOutcome.interrupted;
    final interrupted = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 2000},
      context,
    );
    expect(interrupted.output, contains('Sleep interrupted by new input.'));
  });

  test('out-of-range durations are rejected without sleeping', () async {
    final tool = SleepTool(clock: clock);

    final tooSmall = await tool.execute(
      <String, dynamic>{'duration_ms': 0},
      context,
    );
    final tooLarge = await tool.execute(
      <String, dynamic>{'duration_ms': maxSleepDuration.inMilliseconds + 1},
      context,
    );

    expect(tooSmall.isError, isTrue);
    expect(tooLarge.isError, isTrue);
    expect(clock.slept, isEmpty);
  });

  test('a non-integer duration is corrected, not slept on', () async {
    final result = await SleepTool(clock: clock).execute(
      <String, dynamic>{'duration_ms': 'soon'},
      context,
    );

    expect(result.isError, isTrue);
    expect(clock.slept, isEmpty);
  });

  test('the duration is what the user sees in the preview', () async {
    final tool = SleepTool(clock: clock);

    expect(
      await tool.preview(
        <String, dynamic>{'duration_ms': 1000},
        context,
      ),
      '1000 ms',
    );
  });

  test('a cancelled turn stops instead of finishing its sleep', () async {
    final cancellation = CancellationToken();
    clock.cancelBeforeSleep = cancellation;

    await expectLater(
      SleepTool(clock: clock).execute(
        <String, dynamic>{'duration_ms': 5000},
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
        <String, dynamic>{'duration_ms': 5000},
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
