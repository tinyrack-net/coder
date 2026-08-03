/// Opening marker the model writes around a finished plan.
const String proposedPlanOpenTag = '<proposed_plan>';

/// Closing marker the model writes around a finished plan.
const String proposedPlanCloseTag = '</proposed_plan>';

/// Assistant prose split into ordinary text and a proposed plan.
final class ChatPlanSegments {
  /// Creates plan segments.
  const ChatPlanSegments({
    required this.markdown,
    required this.plan,
    required this.isComplete,
  });

  /// Assistant text with the plan block removed.
  final String markdown;

  /// Plan body, or null when the text carries no plan.
  final String? plan;

  /// Whether the closing tag arrived; false while the plan still streams.
  final bool isComplete;
}

/// Carves a `<proposed_plan>` block out of assistant prose.
///
/// The tags stay in the persisted timeline and in provider history, so this
/// runs on every render, including a replay after reconnecting.
ChatPlanSegments extractProposedPlan(String assistantMarkdown) {
  final start = assistantMarkdown.indexOf(proposedPlanOpenTag);
  if (start < 0) {
    return ChatPlanSegments(
      markdown: assistantMarkdown,
      plan: null,
      isComplete: false,
    );
  }
  final bodyStart = start + proposedPlanOpenTag.length;
  final end = assistantMarkdown.indexOf(proposedPlanCloseTag, bodyStart);
  final plan = end < 0
      ? assistantMarkdown.substring(bodyStart)
      : assistantMarkdown.substring(bodyStart, end);
  final tail = end < 0
      ? ''
      : assistantMarkdown.substring(end + proposedPlanCloseTag.length);
  final head = assistantMarkdown.substring(0, start).trim();
  final rest = tail.trim();
  return ChatPlanSegments(
    markdown: <String>[
      if (head.isNotEmpty) head,
      if (rest.isNotEmpty) rest,
    ].join('\n'),
    plan: plan.trim(),
    isComplete: end >= 0,
  );
}
