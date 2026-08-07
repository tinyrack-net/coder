import 'package:coder_app/src/chat/tools/presenter.dart';

/// How `attach_file` appears in the chat timeline.
final Map<String, ChatToolPresenter> attachFilePresenters =
    <String, ChatToolPresenter>{
      'attach_file': ChatToolPresenter(
        timeline: ChatToolTimeline.suppressed,
        glyph: ChatToolGlyph.read,
        title: (l10n, activity) =>
            'Attach('
            '${truncateToolText(stringToolArg(activity, 'path') ?? '?', 60)})',
        result: (l10n, activity, output) {
          if (output is! ChatToolJsonObject) {
            return genericToolResult(l10n, output);
          }
          final name = output.value['fileName'];
          return name is String
              ? l10n.toolAttached(name)
              : genericToolResult(l10n, output);
        },
      ),
    };
