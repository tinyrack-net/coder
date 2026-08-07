import 'package:coder_app/src/chat/tools/presenter.dart';

/// How `ask_user` appears in the chat timeline.
final Map<String, ChatToolPresenter> askUserPresenters =
    <String, ChatToolPresenter>{
      'ask_user': ChatToolPresenter(
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
          if (output is! ChatToolJsonArray) {
            return genericToolResult(l10n, output);
          }
          final answers = output.value
              .whereType<Map<dynamic, dynamic>>()
              .map((answer) => answer['answer'])
              .whereType<String>();
          return answers.isEmpty
              ? genericToolResult(l10n, output)
              : answers.join(', ');
        },
      ),
    };
