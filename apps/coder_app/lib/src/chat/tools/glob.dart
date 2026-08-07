import 'package:coder_app/src/chat/tools/presenter.dart';

/// How `glob` appears in the chat timeline.
final Map<String, ChatToolPresenter> globPresenters =
    <String, ChatToolPresenter>{
      'glob': ChatToolPresenter(
        glyph: ChatToolGlyph.search,
        title: (l10n, activity) {
          final pattern = truncateToolText(
            stringToolArg(activity, 'pattern') ?? '',
            40,
          );
          final path = stringToolArg(activity, 'path');
          return path == null ? 'Glob($pattern)' : 'Glob($pattern in $path)';
        },
        result: (l10n, activity, output) {
          if (output is! ChatToolJsonObject) {
            return genericToolResult(l10n, output);
          }
          final error = output.value['error'];
          if (error is String) return error;
          final paths = output.value['paths'];
          if (paths is! List || paths.isEmpty) return l10n.toolNoPaths;
          return output.value['truncated'] == true
              ? l10n.toolPathsTruncated(paths.length)
              : l10n.toolPaths(paths.length);
        },
        isFailure: (output) =>
            output is ChatToolJsonObject && output.value['error'] != null,
      ),
    };
