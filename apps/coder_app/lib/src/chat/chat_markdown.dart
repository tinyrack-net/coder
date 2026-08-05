import 'package:coder_app/src/external_url_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Schemes a chat link is allowed to open.
const Set<String> chatLinkSchemes = <String>{'http', 'https', 'mailto'};

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
