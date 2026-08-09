import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/multi_agent.dart';
import 'package:protocol/protocol.dart';

/// Wire name of one [AgentLifecycle] value inside tool outputs.
String agentLifecycleWireName(AgentLifecycle lifecycle) => switch (lifecycle) {
  AgentLifecycle.pendingInit => 'pending_init',
  AgentLifecycle.running => 'running',
  AgentLifecycle.interrupted => 'interrupted',
  AgentLifecycle.completed => 'completed',
  AgentLifecycle.errored => 'errored',
};

ToolResult _errorResult(Object error) {
  final text = '$error';
  return ToolResult(
    output: jsonEncode(<String, dynamic>{'error': text}),
    isError: true,
  );
}

/// Spawns one subagent session and starts it asynchronously.
final class SpawnAgentTool extends AgentTool {
  /// Creates a [SpawnAgentTool] bound to one caller turn.
  SpawnAgentTool(
    this._service,
    this._caller,
    this._callerDefinition,
    this._turnId,
  );

  final MultiAgentService _service;
  final SessionDto _caller;
  final AgentDefinitionDto _callerDefinition;
  final String _turnId;

  @override
  String get name => 'spawn_agent';

  @override
  String get description =>
      'Spawn a subagent that works asynchronously on a task; returns '
      'immediately with its task name. The subagent shares your workspace. '
      'Results arrive later as a FINAL_ANSWER message. Do not spawn agents '
      'for work you can do faster yourself.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'task_name': <String, dynamic>{
        'type': 'string',
        'description':
            'Unique sibling name: lowercase letters, digits, underscores.',
      },
      'message': <String, dynamic>{
        'type': 'string',
        'description': 'The initial task delivered to the subagent.',
      },
      'agent_type': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'Allowlisted subagent definition ID; omit to reuse your own.',
      },
      'fork_turns': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'History the subagent inherits: "none" (default), "all", or the '
            'number of trailing turns.',
      },
      'model': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'Model ID override on your provider connection.',
      },
    },
    'required': <String>[
      'task_name',
      'message',
      'agent_type',
      'fork_turns',
      'model',
    ],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final path = await _service.spawn(
        caller: _caller,
        callerDefinition: _callerDefinition,
        turnId: _turnId,
        taskName: arguments['task_name'] as String,
        message: arguments['message'] as String,
        agentType: arguments['agent_type'] as String?,
        forkTurns: arguments['fork_turns'] as String? ?? 'none',
        model: arguments['model'] as String?,
      );
      return ToolResult(
        output: jsonEncode(<String, dynamic>{'task_name': path}),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}

/// Queues a message to another agent without starting a turn.
final class SendMessageTool extends AgentTool {
  /// Creates a [SendMessageTool] bound to one caller session.
  SendMessageTool(this._service, this._caller);

  final MultiAgentService _service;
  final SessionDto _caller;

  @override
  String get name => 'send_message';

  @override
  String get description =>
      'Queue a message for another agent in your tree. The message is '
      "delivered at the target's next message boundary; it never starts a "
      'turn on an idle agent (use followup_task for that).';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'target': <String, dynamic>{
        'type': 'string',
        'description': 'Relative (task_1) or canonical (/root/task_1) path.',
      },
      'message': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['target', 'message'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final target = arguments['target'] as String;
      await _service.sendMessage(
        caller: _caller,
        target: target,
        message: arguments['message'] as String,
      );
      return ToolResult(
        output: jsonEncode(<String, dynamic>{'queued': true}),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}

/// Sends a follow-up task that resumes an idle agent.
final class FollowupTaskTool extends AgentTool {
  /// Creates a [FollowupTaskTool] bound to one caller session.
  FollowupTaskTool(this._service, this._caller);

  final MultiAgentService _service;
  final SessionDto _caller;

  @override
  String get name => 'followup_task';

  @override
  String get description =>
      'Send a follow-up task to a subagent. Starts a turn when the target is '
      'idle; a running target receives it at its next message boundary. '
      'Cannot target the tree root.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'target': <String, dynamic>{
        'type': 'string',
        'description': 'Relative (task_1) or canonical (/root/task_1) path.',
      },
      'message': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['target', 'message'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final triggered = await _service.followupTask(
        caller: _caller,
        target: arguments['target'] as String,
        message: arguments['message'] as String,
      );
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'delivery': triggered ? 'triggered' : 'queued',
        }),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}

/// Blocks until agent activity, user input, or a timeout.
final class WaitAgentTool extends AgentTool {
  /// Creates a [WaitAgentTool] bound to one caller session.
  WaitAgentTool(this._service, this._caller);

  final MultiAgentService _service;
  final SessionDto _caller;

  @override
  String get name => 'wait_agent';

  @override
  String get description =>
      'Wait until another agent sends you a message, the user queues input, '
      'or the timeout elapses. Returns a summary only; the messages '
      'themselves arrive at your next message boundary. Call this sparingly '
      'and prefer doing useful work first.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'timeout_ms': <String, dynamic>{
        'type': <String>['number', 'null'],
        'description':
            'Deadline in milliseconds ($minWaitTimeoutMs-$maxWaitTimeoutMs); '
            'defaults to $defaultWaitTimeoutMs.',
      },
    },
    'required': <String>['timeout_ms'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final result = await _service.waitAgent(
        caller: _caller,
        cancellation: context.cancellation,
        timeoutMs: (arguments['timeout_ms'] as num?)?.toInt(),
      );
      final message = switch (result.outcome) {
        WaitAgentOutcome.mail => 'Wait completed: new agent activity arrived.',
        WaitAgentOutcome.steer => 'Wait interrupted by new user input.',
        WaitAgentOutcome.timeout => 'Wait timed out.',
      };
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'message': message,
          'timed_out': result.timedOut,
        }),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}

/// Interrupts the running turn of one subagent.
final class InterruptAgentTool extends AgentTool {
  /// Creates an [InterruptAgentTool] bound to one caller session.
  InterruptAgentTool(this._service, this._caller);

  final MultiAgentService _service;
  final SessionDto _caller;

  @override
  String get name => 'interrupt_agent';

  @override
  String get description =>
      'Interrupt the running turn of a subagent. The agent stays alive and '
      'messageable; resume it with followup_task.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'target': <String, dynamic>{
        'type': 'string',
        'description': 'Relative (task_1) or canonical (/root/task_1) path.',
      },
    },
    'required': <String>['target'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final previous = await _service.interruptAgent(
        caller: _caller,
        target: arguments['target'] as String,
      );
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'previous_status': agentLifecycleWireName(previous),
        }),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}

/// Lists the agents of the caller's collaboration tree.
final class ListAgentsTool extends AgentTool {
  /// Creates a [ListAgentsTool] bound to one caller session.
  ListAgentsTool(this._service, this._caller);

  final MultiAgentService _service;
  final SessionDto _caller;

  @override
  String get name => 'list_agents';

  @override
  String get description =>
      'List the agents of your collaboration tree with their status, '
      'optionally under a path prefix.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'path_prefix': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description': 'Canonical path prefix, e.g. /root/task_1.',
      },
    },
    'required': <String>['path_prefix'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    try {
      final agents = await _service.listAgents(
        caller: _caller,
        pathPrefix: arguments['path_prefix'] as String?,
      );
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'agents': <Map<String, dynamic>>[
            for (final agent in agents)
              <String, dynamic>{
                'agent_name': agent.agentName,
                'agent_status': agentLifecycleWireName(agent.agentStatus),
              },
          ],
        }),
      );
    } on CollaborationException catch (error) {
      return _errorResult(error);
    }
  }
}
