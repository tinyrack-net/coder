import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/src/contracts.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/tool_registry.dart';
import 'package:coder_agent/src/tools/tool_support.dart';

/// Lifecycle of one step in an agent-authored plan.
enum PlanStepStatus {
  /// The step has not been started.
  pending,

  /// The step is the one the agent is working on right now.
  inProgress,

  /// The step is finished.
  completed;

  /// The wire name the model writes and the client reads.
  String get wireName => switch (this) {
    PlanStepStatus.pending => 'pending',
    PlanStepStatus.inProgress => 'in_progress',
    PlanStepStatus.completed => 'completed',
  };

  /// Resolves [wireName] back to a status, or null when it is unknown.
  static PlanStepStatus? fromWireName(String wireName) => PlanStepStatus.values
      .where((status) => status.wireName == wireName)
      .firstOrNull;
}

/// Records the agent's ordered plan so the client can render its progress.
///
/// The tool is deliberately side-effect free: the emitted `tool.requested` and
/// `tool.completed` timeline events already persist and replay the plan, so
/// storing it a second time on the session would create a rival source of
/// truth.
class UpdatePlanTool extends AgentTool {
  /// Creates an [UpdatePlanTool].
  UpdatePlanTool();

  @override
  String get name => 'update_plan';

  @override
  String get description =>
      'Record the ordered plan for the current task and the progress of each '
      'step. Call it once the plan is settled and again whenever a step '
      'starts or finishes. Keep at most one step in_progress.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'plan': <String, dynamic>{
          'type': 'array',
          'description': 'The ordered steps, at least one, in execution order.',
          'items': strictToolObject(<String, Map<String, dynamic>>{
            'step': <String, dynamic>{
              'type': 'string',
              'description': 'One short imperative step, unique in the plan.',
            },
            'status': <String, dynamic>{
              'type': 'string',
              'enum': PlanStepStatus.values
                  .map((status) => status.wireName)
                  .toList(growable: false),
            },
          }),
        },
        'explanation': <String, dynamic>{
          'type': 'string',
          'description':
              'Why the plan looks like this; empty when it needs no rationale.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['plan'];
    if (raw is! List || raw.isEmpty) {
      return _reject('A plan must contain at least one step.');
    }
    final steps = <Map<String, dynamic>>[];
    final seen = <String>{};
    var active = 0;
    for (final entry in raw) {
      if (entry is! Map) return _reject('Every plan entry must be an object.');
      final step = entry['step'];
      if (step is! String || step.trim().isEmpty) {
        return _reject('Every step needs a non-empty "step" description.');
      }
      final statusName = entry['status'];
      if (statusName is! String) {
        return _reject('Every step needs a "status".');
      }
      final status = PlanStepStatus.fromWireName(statusName);
      if (status == null) {
        return _reject(
          'Unknown status "$statusName". Use pending, in_progress, or '
          'completed.',
        );
      }
      final normalized = step.trim();
      if (!seen.add(normalized)) {
        return _reject('Duplicate step "$normalized".');
      }
      if (status == PlanStepStatus.inProgress) active += 1;
      steps.add(<String, dynamic>{
        'step': normalized,
        'status': status.wireName,
      });
    }
    if (active > 1) {
      return _reject('At most one step may be in_progress; found $active.');
    }
    final explanation = arguments['explanation'];
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'plan': steps,
          'explanation': explanation is String ? explanation : '',
        }),
      ),
    );
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Registers the shared plan the host UI renders.
final class UpdatePlanToolProvider extends SelectableToolProvider {
  /// Creates a [UpdatePlanToolProvider].
  const UpdatePlanToolProvider();

  @override
  String get id => 'update_plan';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: UpdatePlanTool().description,
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    UpdatePlanTool(),
  ];
}
