import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How `search_text` appears in the chat timeline.
final Map<String, ChatToolPresenter>
searchTextPresenters = <String, ChatToolPresenter>{
  'search_text': ChatToolPresenter(
    glyph: ChatToolGlyph.search,
    title: (l10n, activity) {
      final query = truncateToolText(
        stringToolArg(activity, 'query') ?? '',
        40,
      );
      final path = stringToolArg(activity, 'path');
      return path == null
          ? l10n.toolTitleSearch(query)
          : l10n.toolTitleSearchIn(query, path);
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final matches = output.value['matches'];
      if (matches is! List || matches.isEmpty) return l10n.toolNoMatches;
      final paths = matches
          .whereType<Map<String, dynamic>>()
          .map((match) => match['path'])
          .whereType<String>()
          .toSet();
      // The cap changes what the count means: a truncated run says "at least",
      // not "exactly".
      return output.value['truncated'] == true
          ? l10n.toolMatchesTruncated(matches.length, paths.length)
          : l10n.toolMatches(matches.length, paths.length);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
};
