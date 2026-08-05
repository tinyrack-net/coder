import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_code_block.dart';
import 'package:coder_app/src/chat/chat_diff_view.dart';
import 'package:coder_app/src/chat/chat_theme.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_tool_presentation.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Maps a tool glyph to its semantic Lucide icon.
IconData chatToolIcon(ChatToolGlyph glyph) => switch (glyph) {
  ChatToolGlyph.read => CoderIcons.document,
  ChatToolGlyph.list => CoderIcons.folderOpen,
  ChatToolGlyph.search => CoderIcons.search,
  ChatToolGlyph.edit => CoderIcons.edit,
  ChatToolGlyph.run => CoderIcons.terminal,
  ChatToolGlyph.delegate => CoderIcons.network,
  ChatToolGlyph.generic => CoderIcons.tool,
};

/// One tool call rendered as a collapsed CLI-style line.
///
/// Tapping the row reveals the full request and result instead of dumping raw
/// JSON into the conversation. Expansion is owned by the enclosing list so it
/// survives scrolling and newly arriving events.
class ChatToolCard extends StatelessWidget {
  /// Creates a tool card.
  const ChatToolCard({
    required this.activity,
    this.expanded = false,
    this.onToggle,
    super.key,
  });

  /// The merged tool call rendered by this card.
  final ChatToolActivity activity;

  /// Whether the request and result are visible.
  final bool expanded;

  /// Called when the row is tapped.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = describeToolActivity(
      AppLocalizations.of(context),
      activity,
    );
    final statusColor = switch (activity.status) {
      ChatToolStatus.failed => theme.colorScheme.error,
      ChatToolStatus.denied => theme.colorScheme.outline,
      ChatToolStatus.running || ChatToolStatus.succeeded =>
        presentation.isFailure
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
    };
    final hasBody =
        presentation.body is! ChatToolEmptyBody ||
        presentation.argumentBody is! ChatToolEmptyBody;
    return Semantics(
      button: true,
      expanded: expanded,
      label: presentation.title,
      child: FocusableActionDetector(
        enabled: hasBody && onToggle != null,
        mouseCursor: hasBody && onToggle != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (hasBody) onToggle?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasBody ? onToggle : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      chatToolIcon(presentation.glyph),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        presentation.title,
                        style: chatMonospaceStyle(
                          context,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (presentation.resultLine != null) ...<Widget>[
                      const SizedBox(width: 8),
                      if (activity.status == ChatToolStatus.running)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: SizedBox.square(
                            dimension: 12,
                            child: TRSpinner(
                              label: AppLocalizations.of(context).commonRunning,
                              uiSize: TRUiSize.md,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          presentation.resultLine!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: presentation.isFailure
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (hasBody)
                      Icon(
                        expanded ? CoderIcons.collapse : CoderIcons.expand,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                  ],
                ),
                if (expanded) ...<Widget>[
                  const SizedBox(height: 8),
                  _ChatToolBodyView(body: presentation.argumentBody),
                  if (presentation.argumentBody is! ChatToolEmptyBody &&
                      presentation.body is! ChatToolEmptyBody)
                    const SizedBox(height: 8),
                  _ChatToolBodyView(body: presentation.body),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatToolBodyView extends StatelessWidget {
  const _ChatToolBodyView({required this.body});

  final ChatToolBody body;

  @override
  Widget build(BuildContext context) => switch (body) {
    ChatToolEmptyBody() => const SizedBox.shrink(),
    ChatToolTextBody(:final text) => ChatCodeBlock(text: text),
    ChatToolDiffBody(:final files) => ChatDiffView(files: files),
  };
}
