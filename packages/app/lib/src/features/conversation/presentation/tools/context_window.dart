import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How the context-window tools appear in the chat timeline.
final Map<String, ChatToolPresenter>
contextWindowPresenters = <String, ChatToolPresenter>{
  'get_context_remaining': ChatToolPresenter(
    glyph: ChatToolGlyph.context,
    title: (l10n, activity) => 'Context()',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final remaining = output.value['remainingTokens'];
      final window = output.value['contextWindowTokens'];
      final used = output.value['usedTokens'];
      // A provider that never advertised a window has no denominator, so the
      // row reports what was spent instead of inventing a percentage.
      if (remaining is! int || window is! int) {
        return l10n.toolContextRemainingUnknown(used is int ? used : 0);
      }
      return l10n.toolContextRemaining(remaining, window);
    },
  ),
  // A successful reset renders as its own divider; this only draws one that
  // failed or was denied.,
  'new_context': ChatToolPresenter(
    timeline: ChatToolTimeline.suppressed,
    glyph: ChatToolGlyph.context,
    title: (l10n, activity) => 'NewContext()',
    result: (l10n, activity, output) =>
        output is ChatToolJsonObject && output.value['error'] is String
        ? output.value['error']! as String
        : l10n.chatContextReset,
    isFailure: toolHasErrorKey,
  ),
};
