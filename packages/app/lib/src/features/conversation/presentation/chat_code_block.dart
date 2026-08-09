import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Scrollable monospace block used for tool arguments and command output.
///
/// Content is capped before layout so a multi-megabyte command output cannot
/// stall a frame.
class ChatCodeBlock extends StatelessWidget {
  /// Creates a code block.
  const ChatCodeBlock({
    required this.text,
    this.maxLines = 24,
    this.maxCharacters = 20000,
    this.showCopy = true,
    super.key,
  });

  /// Raw text to render.
  final String text;

  /// Lines shown before the block is truncated.
  final int maxLines;

  /// Characters kept before the text is truncated.
  final int maxCharacters;

  /// Whether the copy affordance is offered.
  final bool showCopy;

  @override
  Widget build(BuildContext context) {
    final capped = text.length > maxCharacters
        ? text.substring(0, maxCharacters)
        : text;
    final lines = capped.split('\n');
    final visible = lines.length > maxLines
        ? lines.take(maxLines).join('\n')
        : capped;
    final hidden = lines.length > maxLines ? lines.length - maxLines : 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tinyrackTheme.surfaceMuted,
        borderRadius: const BorderRadius.all(TRRadii.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TRSpacing.small,
          TRSpacing.small,
          TRSpacing.extraSmall,
          TRSpacing.small,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SelectionArea(
                      child: TRText(
                        visible,
                        variant: TRTextVariant.code,
                      ),
                    ),
                    if (hidden > 0)
                      TRText(
                        AppLocalizations.of(context).chatMoreLines(hidden),
                        variant: TRTextVariant.bodySm,
                        color: TRTextColor.muted,
                      ),
                  ],
                ),
              ),
            ),
            if (showCopy)
              TRIconButton(
                appearance: TRAppearance.ghost,
                label: AppLocalizations.of(context).commonCopy,
                onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                icon: const Icon(CoderIcons.copy),
              ),
          ],
        ),
      ),
    );
  }
}
