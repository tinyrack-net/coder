import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools.dart';
import 'package:agent/src/tools/tool_registry.dart';

/// Why a [SleepTool] call stopped waiting.
enum SleepOutcome {
  /// The full duration elapsed.
  elapsed,

  /// New input arrived for the turn, so waiting stopped early.
  interrupted,
}

/// The host's view of time, so the agent never reads the wall clock itself.
///
/// One port for both tools on purpose: they share the concern — the host owns
/// time — and one port means one fake in every test.
abstract interface class AgentClock {
  /// The current instant in UTC.
  DateTime nowUtc();

  /// Waits up to [duration], returning early when new input arrives.
  ///
  /// Throws [AgentCancelledException] when [cancellation] fires: a cancelled
  /// turn stops, it does not finish sleeping.
  Future<SleepOutcome> sleep(
    Duration duration,
    CancellationToken cancellation,
  );
}

/// Shortest wait [SleepTool] accepts.
const Duration minSleepDuration = Duration(milliseconds: 1);

/// Longest wait [SleepTool] accepts.
///
/// A turn that needs to wait longer than this should end and be resumed, not
/// hold a provider connection open.
const Duration maxSleepDuration = Duration(hours: 12);

/// Reports the current UTC time to the model.
class CurrentTimeTool extends AgentTool {
  /// Creates a [CurrentTimeTool].
  factory CurrentTimeTool({required AgentClock clock}) =>
      CurrentTimeTool._(clock);

  CurrentTimeTool._(this._clock);

  final AgentClock _clock;

  @override
  String get name => 'clock__curr_time';

  @override
  String get description =>
      'Get the current time in UTC. Use it before reasoning about dates, '
      'deadlines, or how stale something is — your training cutoff is not '
      'today.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  // An empty object still has to declare its shape: strict schemas reject a
  // bare `{}` on both provider APIs.
  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(const <String, Map<String, dynamic>>{});

  @override
  ModelToolDefinition get modelSpec => ModelNamespaceToolDefinition(
    name: 'clock',
    description: 'Tools for reading and waiting on time.',
    tools: <ModelFunctionToolDefinition>[
      ModelFunctionToolDefinition(
        name: 'curr_time',
        description: 'Return the current time in UTC.',
        parameters: strictJsonSchema,
        strict: false,
        outputSchema: const <String, dynamic>{
          'type': 'object',
          'properties': <String, dynamic>{
            'current_time': <String, dynamic>{'type': 'string'},
          },
          'required': <String>['current_time'],
          'additionalProperties': false,
        },
      ),
    ],
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    // UTC only: a remote daemon's host timezone is not the user's, and
    // shipping a timezone database to guess is out of scope.
    final now = _clock.nowUtc();
    final formatted =
        '${now.toIso8601String().substring(0, 10)} '
        '${now.toIso8601String().substring(11, 19)} UTC';
    return ToolResult(
      value: context.toolSurfaceMode == AgentToolSurfaceMode.luaCode
          ? <String, dynamic>{'current_time': formatted}
          : formatted,
    );
  }
}

/// Pauses the turn, ending early when the user sends something new.
class SleepTool extends AgentTool {
  /// Creates a [SleepTool].
  factory SleepTool({required AgentClock clock}) => SleepTool._(clock);

  SleepTool._(this._clock);

  final AgentClock _clock;

  @override
  String get name => 'clock__sleep';

  @override
  String get description =>
      'Pause before checking something again — a build, a deployment, a file '
      'another process writes. Ends early if the user sends new input. '
      'Accepts ${minSleepDuration.inMilliseconds}ms to '
      '${maxSleepDuration.inMilliseconds}ms and returns elapsed wall time.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'duration_ms': <String, dynamic>{
          'type': 'integer',
          'description':
              'How long to wait, in milliseconds. Clamped to '
              '${minSleepDuration.inMilliseconds}…'
              '${maxSleepDuration.inMilliseconds}.',
        },
      });

  @override
  bool get strict => false;

  @override
  ModelToolDefinition get modelSpec => ModelNamespaceToolDefinition(
    name: 'clock',
    description: 'Tools for reading and waiting on time.',
    tools: <ModelFunctionToolDefinition>[
      ModelFunctionToolDefinition(
        name: 'sleep',
        description:
            'Pause execution for a specified duration. The sleep ends early '
            'when new input arrives and returns elapsed wall-clock time.',
        parameters: strictJsonSchema,
        strict: false,
      ),
    ],
  );

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    return '${arguments['duration_ms']} ms';
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['duration_ms'];
    if (raw is! int) {
      return const ToolResult(
        value: <String, dynamic>{
          'error': 'duration_ms must be an integer.',
        },
        isError: true,
      );
    }
    if (raw < minSleepDuration.inMilliseconds ||
        raw > maxSleepDuration.inMilliseconds) {
      return ToolResult(
        value:
            'duration_ms must be between ${minSleepDuration.inMilliseconds} '
            'and ${maxSleepDuration.inMilliseconds}',
        isError: true,
      );
    }
    final duration = Duration(milliseconds: raw);
    context.cancellation.throwIfCancelled();
    final stopwatch = Stopwatch()..start();
    final outcome = await _clock.sleep(duration, context.cancellation);
    stopwatch.stop();
    final message = outcome == SleepOutcome.interrupted
        ? 'Sleep interrupted by new input.'
        : 'Sleep completed.';
    final wallSeconds =
        stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    return ToolResult(
      value:
          'Wall time: '
          '${wallSeconds.toStringAsFixed(4)} '
          'seconds\n$message',
    );
  }
}

/// Registers reading the wall clock.
final class CurrentTimeToolProvider extends SelectableToolProvider {
  /// Creates a [CurrentTimeToolProvider].
  const CurrentTimeToolProvider();

  @override
  String get id => 'clock__curr_time';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'clock__curr_time',
    name: 'clock__curr_time',
    description: 'Get the current time in UTC.',
    risk: AgentToolRisk.read,
    group: AgentToolGroup.session,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    CurrentTimeTool(clock: scope.clock),
  ];
}

/// Registers pausing before checking something again.
final class SleepToolProvider extends SelectableToolProvider {
  /// Creates a [SleepToolProvider].
  const SleepToolProvider();

  @override
  String get id => 'clock__sleep';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'clock__sleep',
    name: 'clock__sleep',
    description:
        'Pause before checking something again; ends early on new user input.',
    risk: AgentToolRisk.read,
    group: AgentToolGroup.session,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    SleepTool(clock: scope.clock),
  ];
}
