import 'package:coder_app/src/features/conversation/presentation/tools/presenter.dart';

/// How `read_attachment` appears in the chat timeline.
final Map<String, ChatToolPresenter> readAttachmentPresenters =
    <String, ChatToolPresenter>{
      'read_attachment': ChatToolPresenter(
        glyph: ChatToolGlyph.read,
        title: (l10n, activity) =>
            'Attachment('
            '${truncateToolText(stringToolArg(activity, 'id') ?? '?', 40)})',
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
