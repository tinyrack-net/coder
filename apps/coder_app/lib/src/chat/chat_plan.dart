/// Progress of one step in an agent-authored plan.
enum ChatPlanStepStatus {
  /// The step has not been started.
  pending,

  /// The step the agent is working on right now.
  inProgress,

  /// The step is finished.
  completed,
}

/// One ordered step of an agent-authored plan.
final class ChatPlanStep {
  /// Creates a plan step.
  const ChatPlanStep({required this.step, required this.status});

  /// The imperative description the agent wrote.
  final String step;

  /// Progress of this step.
  final ChatPlanStepStatus status;
}

/// The plan carried by one `update_plan` tool call.
final class ChatPlanUpdate {
  /// Creates a plan update.
  const ChatPlanUpdate({required this.steps, required this.explanation});

  /// The steps in execution order; never empty.
  final List<ChatPlanStep> steps;

  /// Why the plan looks like this; empty when the agent gave no rationale.
  final String explanation;

  /// Renders the plan as Markdown for hand-off into a fresh session.
  String toMarkdown() => <String>[
    for (final step in steps) '- ${_marker(step.status)} ${step.step}',
    if (explanation.isNotEmpty) ...<String>['', explanation],
  ].join('\n');

  static String _marker(ChatPlanStepStatus status) => switch (status) {
    ChatPlanStepStatus.pending => '[ ]',
    ChatPlanStepStatus.inProgress => '[~]',
    ChatPlanStepStatus.completed => '[x]',
  };
}

/// Reads the arguments of an `update_plan` call into a typed plan.
///
/// The arguments come straight from the model, so anything malformed is dropped
/// rather than thrown: a plan that renders one recognizable step beats an error
/// in the transcript. Returns null when no step survives.
ChatPlanUpdate? parseUpdatePlanArguments(Map<String, dynamic> arguments) {
  final raw = arguments['plan'];
  if (raw is! List) return null;
  final steps = <ChatPlanStep>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final step = entry['step'];
    if (step is! String || step.trim().isEmpty) continue;
    steps.add(
      ChatPlanStep(
        step: step.trim(),
        status: _status(entry['status']) ?? ChatPlanStepStatus.pending,
      ),
    );
  }
  if (steps.isEmpty) return null;
  final explanation = arguments['explanation'];
  return ChatPlanUpdate(
    steps: List<ChatPlanStep>.unmodifiable(steps),
    explanation: explanation is String ? explanation : '',
  );
}

ChatPlanStepStatus? _status(Object? value) => switch (value) {
  'pending' => ChatPlanStepStatus.pending,
  'in_progress' => ChatPlanStepStatus.inProgress,
  'completed' => ChatPlanStepStatus.completed,
  _ => null,
};
