import 'package:coder_app/src/features/conversation/presentation/tools/presenter.dart';

/// How `list_directory` appears in the chat timeline.
final Map<String, ChatToolPresenter>
listDirectoryPresenters = <String, ChatToolPresenter>{
  'list_directory': ChatToolPresenter(
    glyph: ChatToolGlyph.list,
    title: (l10n, activity) =>
        'List(${stringToolArg(activity, 'path') ?? '.'})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonArray) return genericToolResult(l10n, output);
      final entries = output.value.whereType<Map<String, dynamic>>();
      if (entries.length != output.value.length) {
        return l10n.toolListItems(output.value.length);
      }
      final directories = entries
          .where((entry) => entry['type'] == 'directory')
          .length;
      return l10n.toolListEntries(directories, entries.length - directories);
    },
  ),
};
