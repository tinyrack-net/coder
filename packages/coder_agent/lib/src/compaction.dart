import 'dart:convert';

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/exec_tools.dart';
import 'package:coder_agent/src/usage.dart';

/// Every value that decides when and how a conversation is compacted.
///
/// They live together rather than next to their call sites because they only
/// make sense as one policy: the trigger ratio, the retention budget, and the
/// prompts all trade the same thing away.
abstract final class CompactionPolicy {
  /// Share of the context window that may be spent before compacting.
  ///
  /// The remaining tenth is headroom: the summary request itself, the system
  /// prompt, and the tool schemas all have to fit alongside the history.
  static const double autoCompactRatio = 0.9;

  /// Token budget for the user messages carried into the new window.
  static const int retainedUserMessageTokens = 20000;

  /// Stands in for a summary the model declined to produce.
  ///
  /// An empty final item would leave the next turn with no statement of where
  /// the work stood, which reads to the model as a fresh conversation.
  static const String missingSummaryPlaceholder = '(no summary available)';

  /// Asks the model to hand its own work off to the next context window.
  static const String summarizationPrompt =
      'You are performing a CONTEXT CHECKPOINT COMPACTION. Create a handoff '
      'summary for another LLM that will resume the task.\n'
      '\n'
      'Include:\n'
      '- Current progress and key decisions made\n'
      '- Important context, constraints, or user preferences\n'
      '- What remains to be done (clear next steps)\n'
      '- Any critical data, examples, or references needed to continue\n'
      '\n'
      'Be concise, structured, and focused on helping the next LLM seamlessly '
      'continue the work.';

  /// System prompt for the summary request.
  ///
  /// The turn's own instructions are about using tools safely, and the summary
  /// request advertises none, so replacing them keeps both the automatic and
  /// the requested compaction on exactly the same prompt.
  static const String summarizationInstructions =
      'You are summarizing a coding session so another model can resume it. '
      'Answer with the summary itself and nothing else. Do not call tools and '
      'do not act on the workspace.';

  /// Introduces the summary to the model that inherits it.
  ///
  /// It also marks the item: a later compaction recognises its own output by
  /// this prefix and drops it instead of stacking summaries of summaries.
  static const String summaryPrefix =
      'Another language model started to solve this problem and produced a '
      'summary of its thinking process. Use this to build on the work that has '
      'already been done and avoid duplicating work. Here is the summary '
      'produced by the other language model, use the information in this '
      'summary to assist with your own analysis:';
}

/// The model settings a compaction request is issued under.
///
/// Only the fields that decide how the summary is produced: the compactor
/// supplies the prompt and withholds every tool, so nothing else of the turn is
/// relevant. It is a value type rather than a whole [ModelRequest] so the path
/// that runs between turns does not have to rebuild an agent's system prompt.
class CompactionTarget {
  /// Creates a [CompactionTarget].
  const CompactionTarget({
    required this.model,
    required this.reasoningEffort,
    required this.safetyIdentifier,
    this.serviceTier,
  });

  /// The model that writes the summary; the one that produced the work.
  final String model;

  /// The reasoningEffort public API member.
  final String reasoningEffort;

  /// The safetyIdentifier public API member.
  final String safetyIdentifier;

  /// Provider service tier; null uses the provider default.
  final String? serviceTier;
}

/// Replaces a spent context window with a summary of the work so far.
///
/// It holds nothing but the provider, so the same instance serves the automatic
/// trigger inside a turn and the explicit request that arrives between turns.
class ConversationCompactor {
  /// Creates a [ConversationCompactor].
  ConversationCompactor(this._provider);

  final ModelProvider _provider;

  /// Whether [usage] has spent enough of [contextWindowTokens] to compact.
  ///
  /// A provider that never reported a window size gets a false rather than a
  /// guess, matching `get_context_remaining`: compacting on an invented budget
  /// would throw away work for no reason.
  bool shouldCompact({
    required ModelUsage usage,
    required int? contextWindowTokens,
  }) {
    if (contextWindowTokens == null || contextWindowTokens <= 0) return false;
    final used = usage.contextTokens;
    if (used <= 0) return false;
    return used >= contextWindowTokens * CompactionPolicy.autoCompactRatio;
  }

  /// Summarizes [history] and returns the history that replaces it.
  ///
  /// The result is user messages only, so it cannot contain a
  /// `function_call_output` whose `function_call` was dropped — a shape both
  /// provider APIs reject.
  Future<List<ConversationItem>> compact({
    required List<ConversationItem> history,
    required CompactionTarget target,
    required CancellationToken cancellation,
  }) async {
    final summary = await _summarize(history, target, cancellation);
    return _rebuild(history, summary);
  }

  /// Runs the summary request, shrinking the input until it fits.
  Future<String> _summarize(
    List<ConversationItem> history,
    CompactionTarget target,
    CancellationToken cancellation,
  ) async {
    final input = <ConversationItem>[
      ...history,
      const UserConversationItem(CompactionPolicy.summarizationPrompt),
    ];
    while (true) {
      cancellation.throwIfCancelled();
      try {
        return await _requestSummary(input, target, cancellation);
      } on ModelContextOverflowException {
        // Trimming from the front rather than the back preserves the cached
        // prompt suffix and keeps the most recent work, which is what the
        // handoff is mostly about.
        if (input.length <= 1) rethrow;
        input.removeAt(0);
      }
    }
  }

  Future<String> _requestSummary(
    List<ConversationItem> input,
    CompactionTarget target,
    CancellationToken cancellation,
  ) async {
    final request = ModelRequest(
      model: target.model,
      reasoningEffort: target.reasoningEffort,
      serviceTier: target.serviceTier,
      instructions: CompactionPolicy.summarizationInstructions,
      history: List<ConversationItem>.unmodifiable(input),
      // The summary turn must not act on the workspace, and advertising tools
      // would invite the model to call one instead of answering.
      tools: const <ModelToolDefinition>[],
      safetyIdentifier: target.safetyIdentifier,
    );
    var text = '';
    await for (final event in _provider.stream(request, cancellation)) {
      if (event is ModelResponseCompleted) text = event.assistant.text;
    }
    return text;
  }

  /// Builds the replacement history: past asks, then the summary.
  List<ConversationItem> _rebuild(
    List<ConversationItem> history,
    String summary,
  ) {
    final retained = <UserConversationItem>[];
    var budget = CompactionPolicy.retainedUserMessageTokens;
    // Walking newest-first spends the budget on the asks still in play.
    for (final item in history.reversed) {
      if (budget <= 0) break;
      if (item is! UserConversationItem) continue;
      if (_isSummary(item)) continue;
      // Attachments are dropped rather than carried: their real cost is images
      // and files this budget cannot measure, so retaining them would leave the
      // window just as full as before. What they showed belongs in the summary.
      final text = item.text.trim();
      if (text.isEmpty) continue;
      final cost = _tokenCost(item.text);
      if (cost <= budget) {
        retained.add(UserConversationItem(item.text));
        budget -= cost;
        continue;
      }
      retained.add(
        UserConversationItem(truncateToTokenBudget(item.text, budget)),
      );
      budget = 0;
    }
    final body = summary.trim();
    return List<ConversationItem>.unmodifiable(<ConversationItem>[
      ...retained.reversed,
      UserConversationItem(
        '${CompactionPolicy.summaryPrefix}\n'
        '${body.isEmpty ? CompactionPolicy.missingSummaryPlaceholder : body}',
      ),
    ]);
  }

  static bool _isSummary(UserConversationItem item) =>
      item.text.startsWith('${CompactionPolicy.summaryPrefix}\n');

  static int _tokenCost(String text) =>
      (utf8.encode(text).length / bytesPerToken).ceil();
}
