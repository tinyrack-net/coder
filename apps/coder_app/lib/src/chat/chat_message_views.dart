import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_markdown.dart';
import 'package:coder_app/src/chat/chat_theme.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// A user prompt rendered as a CLI-style `>` line.
class ChatUserLine extends StatelessWidget {
  /// Creates a user line.
  const ChatUserLine({required this.message, super.key});

  /// The prompt to render.
  final ChatUserMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '>',
            style: chatMonospaceStyle(
              context,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Assistant prose rendered as Markdown with a leading accent dot.
class ChatAssistantMessageView extends ConsumerWidget {
  /// Creates an assistant message view.
  const ChatAssistantMessageView({required this.message, super.key});

  /// The assistant block to render.
  final ChatAssistantMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              CoderIcons.status,
              size: 8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MarkdownBody(
                  data: message.markdown,
                  selectable: true,
                  styleSheet: chatMarkdownStyleSheet(context),
                  onTapLink: (text, href, title) => openChatLink(
                    ref.read(externalUrlOpenerProvider),
                    href,
                  ),
                ),
                if (message.isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '▌',
                      style: chatMonospaceStyle(
                        context,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short muted line closing one turn.
class ChatNoticeLine extends StatelessWidget {
  /// Creates a notice line.
  const ChatNoticeLine({required this.notice, super.key});

  /// The notice to render.
  final ChatNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final (String label, Color color) = switch (notice.kind) {
      ChatNoticeKind.turnCompleted => (
        l10n.commonDone,
        theme.colorScheme.outline,
      ),
      ChatNoticeKind.turnCancelled => (
        l10n.chatNoticeCancelled,
        theme.colorScheme.outline,
      ),
      ChatNoticeKind.turnFailed => (
        l10n.chatNoticeFailed(notice.message ?? ''),
        theme.colorScheme.error,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

/// Token accounting rendered as a muted footer.
class ChatUsageLine extends StatelessWidget {
  /// Creates a usage line.
  const ChatUsageLine({required this.usage, super.key});

  /// The usage entry to render.
  final ChatUsage usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (usage.tokens.isEmpty) return const SizedBox.shrink();
    final summary = usage.tokens.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: Text(
        summary,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// An event this build cannot render, shown as a collapsible row.
class ChatUnknownEventLine extends StatelessWidget {
  /// Creates an unknown-event line.
  const ChatUnknownEventLine({required this.event, super.key});

  /// The unrecognized event.
  final ChatUnknownEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: Text(
        event.type,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// Placeholder shown before a session has any timeline events.
class ChatEmptyState extends StatelessWidget {
  /// Creates the empty state.
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CoderIcons.chat,
            size: 40,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).chatEmptyTitle),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).chatEmptyExample,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Row shown while a turn is still running.
class ChatRunningIndicator extends StatelessWidget {
  /// Creates the running indicator.
  const ChatRunningIndicator({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
    child: Row(
      children: <Widget>[
        SizedBox.square(
          dimension: 12,
          child: TRSpinner(
            label: AppLocalizations.of(context).commonRunning,
            uiSize: TRUiSize.sm,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context).commonRunning,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
