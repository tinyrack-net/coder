import 'dart:convert';

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
const Duration minSleepDuration = Duration(milliseconds: 100);

/// Longest wait [SleepTool] accepts.
///
/// A turn that needs to wait longer than this should end and be resumed, not
/// hold a provider connection open.
const Duration maxSleepDuration = Duration(minutes: 5);

/// Reports the current UTC time to the model.
class CurrentTimeTool extends AgentTool {
  /// Creates a [CurrentTimeTool].
  factory CurrentTimeTool({required AgentClock clock}) =>
      CurrentTimeTool._(clock);

  CurrentTimeTool._(this._clock);

  final AgentClock _clock;

  @override
  String get name => 'current_time';

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
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    // UTC only: a remote daemon's host timezone is not the user's, and
    // shipping a timezone database to guess is out of scope.
    final now = _clock.nowUtc();
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'utc': now.toIso8601String(),
        'unixSeconds': now.millisecondsSinceEpoch ~/ 1000,
      }),
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
  String get name => 'sleep';

  @override
  String get description =>
      'Pause before checking something again — a build, a deployment, a file '
      'another process writes. Ends early if the user sends new input. '
      'Accepts ${minSleepDuration.inMilliseconds}ms to '
      '${maxSleepDuration.inSeconds}s.';

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
        'reason': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description': 'What you are waiting for, shown to the user.',
        },
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final reason = arguments['reason'];
    return reason is String && reason.isNotEmpty ? reason : null;
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['duration_ms'];
    if (raw is! int) {
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'duration_ms must be an integer.',
        }),
        isError: true,
      );
    }
    final duration = Duration(
      milliseconds: raw.clamp(
        minSleepDuration.inMilliseconds,
        maxSleepDuration.inMilliseconds,
      ),
    );
    context.cancellation.throwIfCancelled();
    final outcome = await _clock.sleep(duration, context.cancellation);
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'sleptMs': duration.inMilliseconds,
        'outcome': outcome.name,
      }),
    );
  }
}

/// Registers reading the wall clock.
final class CurrentTimeToolProvider extends SelectableToolProvider {
  /// Creates a [CurrentTimeToolProvider].
  const CurrentTimeToolProvider();

  @override
  String get id => 'current_time';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'current_time',
    name: 'current_time',
    description: 'Get the current time in UTC.',
    risk: AgentToolRisk.read,
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
  String get id => 'sleep';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'sleep',
    name: 'sleep',
    description:
        'Pause before checking something again; ends early on new user input.',
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    SleepTool(clock: scope.clock),
  ];
}
