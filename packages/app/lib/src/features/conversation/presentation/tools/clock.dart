import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How the clock tools appear in the chat timeline.
final Map<String, ChatToolPresenter> clockPresenters =
    <String, ChatToolPresenter>{
      'current_time': ChatToolPresenter(
        glyph: ChatToolGlyph.clock,
        title: (l10n, activity) => 'Now()',
        result: (l10n, activity, output) =>
            output is ChatToolJsonObject && output.value['utc'] is String
            ? output.value['utc']! as String
            : genericToolResult(l10n, output),
      ),
      // A running sleep renders as its own countdown card; this only draws one
      // that failed or was denied.,
      'sleep': ChatToolPresenter(
        timeline: ChatToolTimeline.card,
        glyph: ChatToolGlyph.clock,
        title: (l10n, activity) {
          final milliseconds = activity.arguments['duration_ms'];
          return milliseconds is int ? 'Sleep(${milliseconds}ms)' : 'Sleep()';
        },
        result: (l10n, activity, output) {
          if (output is! ChatToolJsonObject) {
            return genericToolResult(l10n, output);
          }
          final error = output.value['error'];
          if (error is String) return error;
          final slept = output.value['sleptMs'];
          return slept is int
              ? l10n.chatSleepDone((slept / 1000).ceil())
              : genericToolResult(l10n, output);
        },
        isFailure: toolHasErrorKey,
      ),
    };
