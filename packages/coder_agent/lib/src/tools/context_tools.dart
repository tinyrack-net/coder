import 'dart:convert';

import 'package:coder_agent/src/contracts.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools.dart';
import 'package:coder_agent/src/tools/tool_registry.dart';

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
      'Check how many tokens are left in the context window. Use it before '
      'reading something large, and start a fresh window with new_context '
      'when it is running low.';

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
    final window = context.contextWindowTokens;
    final used = context.turnUsage.contextTokens;
    // A provider that never reported a window size gets an honest null rather
    // than a guess the model would then reason from.
    final remaining = window == null ? null : (window - used).clamp(0, window);
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'usedTokens': used,
        'contextWindowTokens': window,
        'remainingTokens': remaining,
      }),
    );
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
      'Start a fresh context window. The conversation so far is discarded '
      'without being summarized, so carry anything you still need into your '
      'next message first. Files, processes, and the workspace are untouched.';

  // Read risk, like update_plan and ask_user: it must work in plan mode and
  // under readOnly, and its visibility is the timeline divider rather than an
  // approval dialog.
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
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'started': true,
        'note': 'History before this point is gone from the model context.',
      }),
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
