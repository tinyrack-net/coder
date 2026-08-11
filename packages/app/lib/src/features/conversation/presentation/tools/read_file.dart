import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How `read_file` appears in the chat timeline.
final Map<String, ChatToolPresenter> readFilePresenters =
    <String, ChatToolPresenter>{
      'read_file': ChatToolPresenter(
        glyph: ChatToolGlyph.read,
        title: (l10n, activity) {
          final path = stringToolArg(activity, 'path') ?? '?';
          final offset = activity.arguments['offset'];
          final limit = activity.arguments['limit'];
          if (offset == null && limit == null) return l10n.toolTitleRead(path);
          return l10n.toolTitleReadRange(
            path,
            '${offset ?? 0}',
            '${limit ?? 0}',
          );
        },
        result: (l10n, activity, output) {
          final text = toolOutputText(output);
          if (text.isEmpty) return l10n.toolEmptyFile;
          return l10n.toolReadLines(countToolLines(text));
        },
      ),
    };
