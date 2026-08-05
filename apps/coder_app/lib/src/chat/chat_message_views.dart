import 'dart:typed_data';

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
  const ChatUserLine({
    required this.message,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// The prompt to render.
  final ChatUserMessage message;

  /// Authenticated attachment byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform file exporter.
  final ChatAttachmentExporter? exportAttachment;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.text.isNotEmpty)
                  SelectableText(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (message.attachments.isNotEmpty) ...<Widget>[
                  if (message.text.isNotEmpty) const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final attachment in message.attachments)
                        ChatAttachmentTile(
                          attachment: attachment,
                          loadAttachment: loadAttachment,
                          exportAttachment: exportAttachment,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An assistant-published file row.
class ChatAttachmentLine extends StatelessWidget {
  /// Creates an assistant attachment line.
  const ChatAttachmentLine({
    required this.message,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// Attachment timeline item.
  final ChatAttachmentMessage message;

  /// Authenticated attachment byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform file exporter.
  final ChatAttachmentExporter? exportAttachment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 18),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ChatAttachmentTile(
        attachment: message.attachment,
        loadAttachment: loadAttachment,
        exportAttachment: exportAttachment,
      ),
    ),
  );
}

/// Thumbnail or file pill shared by inbound and outbound attachments.
class ChatAttachmentTile extends StatelessWidget {
  /// Creates an attachment tile.
  const ChatAttachmentTile({
    required this.attachment,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// Attachment metadata.
  final ChatAttachment attachment;

  /// Authenticated byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform exporter.
  final ChatAttachmentExporter? exportAttachment;

  @override
  Widget build(BuildContext context) {
    final loader = loadAttachment;
    final preview = attachment.isImage && loader != null
        ? SizedBox.square(
            dimension: 56,
            child: FutureBuilder<Uint8List>(
              future: loader(attachment),
              builder: (context, snapshot) => snapshot.hasData
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        snapshot.data!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          CoderIcons.image,
                        ),
                      ),
                    )
                  : const Center(child: TRSpinner(uiSize: TRUiSize.md)),
            ),
          )
        : Icon(attachment.isImage ? CoderIcons.image : CoderIcons.file);
    final onTap = loader == null
        ? null
        : () => attachment.isImage
              ? _showImage(context, loader)
              : exportAttachment?.call(attachment);
    return Semantics(
      button: true,
      enabled: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        key: ValueKey('chat-attachment-${attachment.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              preview,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${attachment.fileName}\n'
                  '${_attachmentSize(attachment.byteSize)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!attachment.isImage) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(CoderIcons.download, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImage(
    BuildContext context,
    ChatAttachmentLoader loader,
  ) async {
    final bytes = await loader(attachment);
    if (!context.mounted) return;
    await showTRDialog<void>(
      context: context,
      builder: (context) => TRDialog(
        semanticLabel: attachment.fileName,
        content: InteractiveViewer(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

String _attachmentSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            uiSize: TRUiSize.md,
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
