import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How `request_user_input` appears in the chat timeline.
final Map<String, ChatToolPresenter> requestUserInputPresenters =
    <String, ChatToolPresenter>{
      'request_user_input': ChatToolPresenter(
        timeline: ChatToolTimeline.card,
        glyph: ChatToolGlyph.ask,
        title: (l10n, activity) {
          final questions = activity.arguments['questions'];
          final headers = questions is List
              ? questions
                    .whereType<Map<dynamic, dynamic>>()
                    .map((question) => question['header'])
                    .whereType<String>()
              : const <String>[];
          return 'Ask(${headers.isEmpty ? '?' : headers.join(', ')})';
        },
        result: (l10n, activity, output) {
          if (output is! ChatToolJsonObject) {
            return genericToolResult(l10n, output);
          }
          final rawAnswers = output.value['answers'];
          if (rawAnswers is! Map) return genericToolResult(l10n, output);
          final answers = rawAnswers.values
              .whereType<Map<dynamic, dynamic>>()
              .expand(
                (entry) => entry['answers'] is List
                    ? (entry['answers']! as List).whereType<String>()
                    : const <String>[],
              );
          return answers.isEmpty
              ? genericToolResult(l10n, output)
              : answers.join(', ');
        },
      ),
    };
