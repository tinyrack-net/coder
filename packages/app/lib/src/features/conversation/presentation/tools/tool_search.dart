import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How `tool_search` appears in the chat timeline.
final Map<String, ChatToolPresenter>
toolSearchPresenters = <String, ChatToolPresenter>{
  'tool_search': ChatToolPresenter(
    glyph: ChatToolGlyph.tools,
    title: (l10n, activity) =>
        'Tools('
        '${truncateToolText(stringToolArg(activity, 'query') ?? '', 40)})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final found = output.value['tools'];
      final remaining = output.value['remaining'];
      return l10n.toolSearchFound(
        found is List ? found.length : 0,
        remaining is int ? remaining : 0,
      );
    },
    body: (activity, output) {
      // The names are the useful part; the schemas are for the model.
      if (output is! ChatToolJsonObject) return plainToolBody(activity, output);
      final found = output.value['tools'];
      if (found is! List) return plainToolBody(activity, output);
      final names = found
          .whereType<Map<dynamic, dynamic>>()
          .map((tool) => tool['name'])
          .whereType<String>()
          .join('\n');
      return names.isEmpty
          ? const ChatToolEmptyBody()
          : ChatToolTextBody(names);
    },
    isFailure: toolHasErrorKey,
  ),
};
