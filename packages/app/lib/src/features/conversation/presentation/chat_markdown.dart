import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/conversation/presentation/chat_code_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Schemes a chat link is allowed to open.
const Set<String> chatLinkSchemes = <String>{'http', 'https', 'mailto'};

/// Renders every fenced block in assistant prose on the shared code surface.
///
/// The Markdown package draws its own `pre`, which leaves a fenced block
/// looking unlike the identical payload a tool call shows and with no way to
/// copy it. Routing it here gives both, and keeps the horizontal scrolling a
/// long line needs.
Map<String, MarkdownElementBuilder> chatMarkdownBuilders() =>
    <String, MarkdownElementBuilder>{'pre': _ChatFencedCodeBuilder()};

class _ChatFencedCodeBuilder extends MarkdownElementBuilder {
  static final RegExp _language = RegExp(r'\blanguage-(\S+)');

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final fence = element.children?.whereType<md.Element>().firstOrNull;
    final classes = fence?.attributes['class'];
    // A fence closes with a newline the block does not have to render.
    return ChatCodeBlock(
      text: element.textContent.replaceFirst(RegExp(r'\n$'), ''),
      language: classes == null
          ? null
          : _language.firstMatch(classes)?.group(1),
    );
  }
}

/// Markdown styling for assistant prose.
///
/// The Markdown package styles its blocks with raw `TextStyle` and
/// `BoxDecoration`, so this is the adapter that maps Tinyrack tokens onto that
/// API. Every value here still comes from a token.
MarkdownStyleSheet chatMarkdownStyleSheet(BuildContext context) {
  final colors = context.tinyrackTheme;
  final base = MarkdownStyleSheet.fromTheme(Theme.of(context));
  return base.copyWith(
    p: TRTypography.body.copyWith(color: colors.text),
    code: TRTypography.code.copyWith(
      color: colors.text,
      backgroundColor: colors.surfaceMuted,
    ),
    codeblockDecoration: BoxDecoration(
      color: colors.surfaceMuted,
      borderRadius: const BorderRadius.all(TRRadii.medium),
    ),
    codeblockPadding: const EdgeInsets.all(TRSpacing.small),
    blockquoteDecoration: BoxDecoration(
      color: colors.surfaceMuted,
      borderRadius: const BorderRadius.all(TRRadii.medium),
    ),
    a: TRTypography.body.copyWith(
      color: colors.primary,
      decoration: TextDecoration.underline,
    ),
    blockSpacing: TRSpacing.small,
  );
}

/// Opens a Markdown link, ignoring schemes that are not browser-safe.
Future<void> openChatLink(ExternalUrlOpener opener, String? href) async {
  if (href == null || href.isEmpty) return;
  final uri = Uri.tryParse(href);
  if (uri == null || !chatLinkSchemes.contains(uri.scheme)) return;
  await opener.open(uri);
}
