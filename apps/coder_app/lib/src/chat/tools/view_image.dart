import 'package:coder_app/src/chat/tools/presenter.dart';

/// How `view_image` appears in the chat timeline.
final Map<String, ChatToolPresenter>
viewImagePresenters = <String, ChatToolPresenter>{
  'view_image': ChatToolPresenter(
    glyph: ChatToolGlyph.image,
    title: (l10n, activity) =>
        'View(${stringToolArg(activity, 'path') ?? '?'})',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final bytes = output.value['byteSize'];
      return bytes is int
          ? l10n.toolImageLoaded(bytes)
          : genericToolResult(l10n, output);
    },
    isFailure: (output) =>
        output is ChatToolJsonObject && output.value['error'] != null,
  ),
  // An accepted plan renders as its own card, so this spec only ever draws a
  // plan the daemon rejected.,
};
