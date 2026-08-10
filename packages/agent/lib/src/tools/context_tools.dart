import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools.dart';
import 'package:agent/src/tools/tool_registry.dart';

/// Reports how much of the context window is left.
///
/// A pure function of its execution context: the window size comes from the
/// turn request and the usage from the last response, so there is no port to
/// fake and nothing to keep in sync.
class GetContextRemainingTool extends AgentTool {
  /// Creates a [GetContextRemainingTool].
  GetContextRemainingTool();

  @override
  String get name => 'get_context_remaining';

  @override
  String get description =>
      'Get the remaining tokens in the current context window.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(const <String, Map<String, dynamic>>{});

  @override
  ModelToolDefinition get modelSpec => ModelFunctionToolDefinition(
    name: name,
    description: description,
    parameters: strictJsonSchema,
    strict: false,
    outputSchema: const <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'tokens_left': <String, dynamic>{
          'anyOf': <Map<String, dynamic>>[
            <String, dynamic>{'type': 'integer'},
            <String, dynamic>{'type': 'null'},
          ],
        },
      },
      'required': <String>['tokens_left'],
      'additionalProperties': false,
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final window = context.contextWindowTokens;
    final used = context.turnUsage.contextTokens;
    // A provider that never reported a window size gets an honest null rather
    // than a guess the model would then reason from.
    final remaining = window == null ? null : (window - used).clamp(0, window);
    return ToolResult(value: <String, dynamic>{'tokens_left': remaining});
  }
}

/// Starts a fresh context window, discarding the conversation so far.
class NewContextTool extends AgentTool {
  /// Creates a [NewContextTool].
  NewContextTool();

  @override
  String get name => 'new_context';

  @override
  String get description =>
      'Start a new context window. Does not clear, reset, or otherwise affect '
      'environment state.';

  // Read risk, like update_plan and request_user_input: it must work in plan
  // mode and under readOnly, and its visibility is the timeline divider rather
  // than an approval dialog.
  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(const <String, Map<String, dynamic>>{});

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    // The runner performs the reset once the whole round finishes; doing it
    // here would strand any tool call that follows in the same round.
    context.requestContextReset();
    return const ToolResult(
      value:
          'A new context window will start without summarizing conversation '
          'history.',
    );
  }
}

/// Registers the context-window tools.
///
/// Hidden rather than selectable: how a turn measures and retires its own
/// context window is part of how the runtime works, not a capability a user
/// grants an agent.
final class ContextWindowToolProvider extends AgentToolProvider {
  /// Creates a [ContextWindowToolProvider].
  const ContextWindowToolProvider();

  @override
  String get id => 'context_window';

  @override
  AgentToolDefinition? get catalogEntry => null;

  @override
  List<AgentTool> create(AgentToolScope scope) => <AgentTool>[
    GetContextRemainingTool(),
    NewContextTool(),
  ];
}
