import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/goal_service.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Hidden always-on goal capability for manually-created root sessions.
final class GoalToolProvider extends AgentToolProvider {
  /// Creates a provider that resolves the service at turn time.
  GoalToolProvider(this._service);

  final SessionGoalService? Function() _service;

  @override
  String get id => 'session_goal';

  @override
  AgentToolDefinition? get catalogEntry => null;

  @override
  List<AgentTool> create(AgentToolScope scope) {
    final service = _service();
    final session = scope.session.value;
    if (service == null ||
        session is! SessionDto ||
        session.origin != SessionOrigin.manual ||
        session.parentSessionId != null) {
      return const <AgentTool>[];
    }
    return <AgentTool>[
      GetGoalTool(service, session.id),
      CreateGoalTool(service, session.id),
      UpdateGoalTool(service, session.id),
    ];
  }
}

abstract base class _GoalTool extends AgentTool {
  _GoalTool(this.service, this.sessionId);

  final SessionGoalService service;
  final String sessionId;

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  ToolResult json(Object? value, {bool isError = false}) => ToolResult(
    output: jsonEncode(value),
    isError: isError,
  );

  Future<ToolResult> guard(Future<Object?> Function() operation) async {
    try {
      return json(await operation());
    } on Object catch (error) {
      return json(<String, dynamic>{'error': '$error'}, isError: true);
    }
  }

  Map<String, dynamic> response(GoalDto? goal) => <String, dynamic>{
    'goal': goal?.toJson(),
    'remainingTokens': goal?.tokenBudget == null
        ? null
        : (goal!.tokenBudget! - goal.tokensUsed).clamp(0, 1 << 62),
  };
}

/// Reads the current session goal.
final class GetGoalTool extends _GoalTool {
  /// Creates a goal reader bound to one session.
  GetGoalTool(super.service, super.sessionId);

  @override
  String get name => 'get_goal';

  @override
  String get description =>
      'Get the current goal for this session, including status, budget, token '
      'usage, elapsed time, and remaining token budget.';

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject({});

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) => guard(() async => response(await service.get(sessionId)));
}

/// Starts a new explicitly requested session goal.
final class CreateGoalTool extends _GoalTool {
  /// Creates a goal creator bound to one session.
  CreateGoalTool(super.service, super.sessionId);

  @override
  String get name => 'create_goal';

  @override
  String get description =>
      'Create a goal only when the user explicitly requests persistent goal '
      'execution. Do not infer a goal from an ordinary task. An unfinished '
      'goal must be completed or managed by the user first.';

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject({
    'objective': <String, dynamic>{'type': 'string'},
    'token_budget': <String, dynamic>{
      'type': <String>['integer', 'null'],
      'description': 'Positive budget, only when explicitly requested.',
    },
  });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) => guard(() async {
    final goal = await service.createFromAgent(
      sessionId: sessionId,
      objective: arguments['objective'] as String,
      tokenBudget: arguments['token_budget'] as int?,
    );
    return response(goal);
  });
}

/// Reports a verified terminal goal outcome.
final class UpdateGoalTool extends _GoalTool {
  /// Creates a terminal-status updater bound to one session.
  UpdateGoalTool(super.service, super.sessionId);

  @override
  String get name => 'update_goal';

  @override
  String get description =>
      'Mark the goal complete only after verifying the full objective. Mark '
      'blocked only after the same blocker prevents progress for three '
      'consecutive goal turns. Do not use blocked for difficult or incomplete '
      'work.';

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject({
    'status': <String, dynamic>{
      'type': 'string',
      'enum': <String>['complete', 'blocked'],
    },
  });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) => guard(() async {
    final status = switch (arguments['status']) {
      'complete' => GoalStatus.complete,
      'blocked' => GoalStatus.blocked,
      _ => throw const FormatException('Unknown goal status.'),
    };
    return response(
      await service.updateFromAgent(sessionId: sessionId, status: status),
    );
  });
}
