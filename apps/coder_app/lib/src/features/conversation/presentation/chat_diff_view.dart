import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/conversation/application/chat_diff.dart';
import 'package:coder_app/src/features/conversation/presentation/chat_theme.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Renders parsed unified-diff files with added and removed lines colored.
class ChatDiffView extends StatelessWidget {
  /// Creates a diff view.
  const ChatDiffView({required this.files, this.maxLines = 60, super.key});

  /// Files to render, in source order.
  final List<ChatDiffFile> files;

  /// Total lines rendered before the diff is truncated.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    var budget = maxLines;
    final rows = <Widget>[];
    var hidden = 0;
    for (final file in files) {
      if (file.path.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 4),
            child: TRText(
              '${file.path}  +${file.added} -${file.removed}',
              variant: TRTextVariant.label,
              color: TRTextColor.muted,
            ),
          ),
        );
      }
      for (final line in file.lines) {
        if (budget <= 0) {
          hidden += 1;
          continue;
        }
        budget -= 1;
        rows.add(_DiffLineRow(line: line));
      }
    }
    if (hidden > 0) {
      rows.add(
        TRText(
          AppLocalizations.of(context).chatMoreLines(hidden),
          variant: TRTextVariant.bodySm,
          color: TRTextColor.muted,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tinyrackTheme.surfaceMuted,
        borderRadius: const BorderRadius.all(TRRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TRSpacing.small),
        // Selection spans the whole hunk rather than a single row, so a user
        // can copy a run of diff lines in one drag.
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        ),
      ),
    );
  }
}

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.line});

  final ChatDiffLine line;

  @override
  Widget build(BuildContext context) {
    // `added` is null for a line the diff does not change.
    final (bool? added, String marker) = switch (line.kind) {
      ChatDiffLineKind.added => (true, '+'),
      ChatDiffLineKind.removed => (false, '-'),
      ChatDiffLineKind.hunkHeader => (null, ''),
      ChatDiffLineKind.context => (null, ' '),
    };
    final foreground = line.kind == ChatDiffLineKind.hunkHeader
        ? TRTextColor.primary
        : chatDiffForeground(added: added);
    return ColoredBox(
      color: chatDiffSurface(context, added: added) ?? Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: TRSpacing.fourExtraLarge,
            child: TRText(
              '${_gutter(line.oldLine)} ${_gutter(line.newLine)}',
              variant: TRTextVariant.code,
              color: TRTextColor.muted,
              align: TRTextAlign.end,
            ),
          ),
          const SizedBox(width: TRSpacing.small),
          Expanded(
            child: TRText(
              '$marker${line.text}',
              variant: TRTextVariant.code,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  String _gutter(int? value) => value == null ? '    ' : '$value'.padLeft(4);
}
