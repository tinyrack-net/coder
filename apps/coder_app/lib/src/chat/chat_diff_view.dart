import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_diff.dart';
import 'package:coder_app/src/chat/chat_theme.dart';
import 'package:flutter/material.dart';

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
    final colors = chatDiffColorsOf(context);
    final theme = Theme.of(context);
    var budget = maxLines;
    final rows = <Widget>[];
    var hidden = 0;
    for (final file in files) {
      if (file.path.isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2, top: 4),
            child: Text(
              '${file.path}  +${file.added} -${file.removed}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
        rows.add(_DiffLineRow(line: line, colors: colors));
      }
    }
    if (hidden > 0) {
      rows.add(
        Text(
          AppLocalizations.of(context).chatMoreLines(hidden),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }
}

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.line, required this.colors});

  final ChatDiffLine line;
  final ChatDiffColors colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (
      Color? background,
      Color foreground,
      String marker,
    ) = switch (line.kind) {
      ChatDiffLineKind.added => (
        colors.addedBackground,
        colors.addedForeground,
        '+',
      ),
      ChatDiffLineKind.removed => (
        colors.removedBackground,
        colors.removedForeground,
        '-',
      ),
      ChatDiffLineKind.hunkHeader => (
        null,
        theme.colorScheme.primary,
        '',
      ),
      ChatDiffLineKind.context => (
        null,
        theme.colorScheme.onSurfaceVariant,
        ' ',
      ),
    };
    final style = chatMonospaceStyle(context, color: foreground);
    return ColoredBox(
      color: background ?? Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              '${_gutter(line.oldLine)} ${_gutter(line.newLine)}',
              style: chatMonospaceStyle(
                context,
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText('$marker${line.text}', style: style),
          ),
        ],
      ),
    );
  }

  String _gutter(int? value) => value == null ? '    ' : '$value'.padLeft(4);
}
