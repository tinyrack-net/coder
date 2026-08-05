import 'dart:typed_data';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/chat/chat_markdown.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_tool_presentation.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TRText(
            '>',
            variant: TRTextVariant.code,
            color: TRTextColor.primary,
          ),
          const SizedBox(width: TRSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.text.isNotEmpty)
                  SelectionArea(
                    child: TRText(
                      message.text,
                      color: TRTextColor.muted,
                    ),
                  ),
                if (message.attachments.isNotEmpty) ...<Widget>[
                  if (message.text.isNotEmpty)
                    const SizedBox(height: TRSpacing.small),
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
                      borderRadius: const BorderRadius.all(TRRadii.medium),
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
                  : const Center(child: TRSpinner()),
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
          padding: const EdgeInsets.all(TRSpacing.small),
          decoration: BoxDecoration(
            border: Border.all(color: context.tinyrackTheme.border),
            borderRadius: const BorderRadius.all(TRRadii.large),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              preview,
              const SizedBox(width: TRSpacing.small),
              Flexible(
                child: TRText.inherit(
                  '${attachment.fileName}\n'
                  '${_attachmentSize(attachment.byteSize)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!attachment.isImage) ...<Widget>[
                const SizedBox(width: TRSpacing.small),
                const Icon(CoderIcons.download),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              CoderIcons.status,
              size: TRSpacing.small,
              color: context.tinyrackTheme.primary,
            ),
          ),
          const SizedBox(width: TRSpacing.small),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: TRText(
                      '▌',
                      variant: TRTextVariant.code,
                      color: TRTextColor.primary,
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
    final l10n = AppLocalizations.of(context);
    final (String label, TRTextColor color) = switch (notice.kind) {
      ChatNoticeKind.turnCompleted => (l10n.commonDone, TRTextColor.muted),
      ChatNoticeKind.turnCancelled => (
        l10n.chatNoticeCancelled,
        TRTextColor.muted,
      ),
      ChatNoticeKind.turnFailed => (
        l10n.chatNoticeFailed(notice.message ?? ''),
        TRTextColor.danger,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: TRText(label, variant: TRTextVariant.bodySm, color: color),
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
    final l10n = AppLocalizations.of(context);
    final summary = describeTokenUsage(l10n, usage.tokens);
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: TRText(
        summary,
        key: const ValueKey<String>('chat-usage-line'),
        variant: TRTextVariant.bodySm,
        color: TRTextColor.muted,
      ),
    );
  }
}

/// Renders an answered agent question as question-and-answer prose.
///
/// The pending question is a card the user acts on; once answered it belongs
/// in the transcript as conversation, not as a tool row full of JSON.
class ChatUserAnswerLine extends StatelessWidget {
  /// Creates an answered-question line.
  const ChatUserAnswerLine({required this.answer, super.key});

  /// The answered questions to render.
  final ChatUserAnswer answer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TRSpacing.extraSmall,
        horizontal: TRSpacing.extraSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final entry in answer.entries)
            Padding(
              key: ValueKey<String>('chat-answer-${entry.header}'),
              padding: const EdgeInsets.only(bottom: TRSpacing.threeExtraSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TRSpacing.threeExtraSmall,
                    ),
                    child: Icon(
                      CoderIcons.chat,
                      size: TRTypography.bodySm.fontSize,
                      color: context.tinyrackTheme.primary,
                    ),
                  ),
                  const SizedBox(width: TRSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TRText(
                          entry.question,
                          variant: TRTextVariant.bodySm,
                          color: TRTextColor.muted,
                        ),
                        TRText(
                          entry.isFreeForm
                              ? l10n.chatAnswerTyped(entry.answer)
                              : entry.answer,
                        ),
                      ],
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

/// Marks where the model's history was discarded.
///
/// The conversation above stays readable, so the divider is what tells the
/// user why the agent no longer remembers any of it.
class ChatContextResetLine extends StatelessWidget {
  /// Creates a context reset divider.
  const ChatContextResetLine({required this.reset, super.key});

  /// The reset to render.
  final ChatContextReset reset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TRSpacing.small),
    child: Row(
      children: <Widget>[
        const Expanded(child: TRSeparator(variant: TRSeparatorVariant.muted)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TRSpacing.small),
          child: TRText(
            AppLocalizations.of(context).chatContextReset,
            key: const ValueKey<String>('chat-context-reset'),
            variant: TRTextVariant.bodySm,
            color: TRTextColor.muted,
          ),
        ),
        const Expanded(child: TRSeparator(variant: TRSeparatorVariant.muted)),
      ],
    ),
  );
}

/// Tells the user that tools exist beyond the ones the model was handed.
class ChatDeferredToolsLine extends StatelessWidget {
  /// Creates a deferred-tools line.
  const ChatDeferredToolsLine({required this.notice, super.key});

  /// The notice to render.
  final ChatDeferredTools notice;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: TRSpacing.threeExtraSmall,
      horizontal: TRSpacing.extraSmall,
    ),
    child: Row(
      children: <Widget>[
        Icon(
          CoderIcons.tool,
          size: TRTypography.bodySm.fontSize,
          color: context.tinyrackTheme.textMuted,
        ),
        const SizedBox(width: TRSpacing.small),
        TRText(
          AppLocalizations.of(context).chatDeferredTools(notice.count),
          key: const ValueKey<String>('chat-deferred-tools'),
          variant: TRTextVariant.bodySm,
          color: TRTextColor.muted,
        ),
      ],
    ),
  );
}

/// An event this build cannot render, shown as a collapsible row.
class ChatUnknownEventLine extends StatelessWidget {
  /// Creates an unknown-event line.
  const ChatUnknownEventLine({required this.event, super.key});

  /// The unrecognized event.
  final ChatUnknownEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      child: TRText(
        event.type,
        variant: TRTextVariant.bodySm,
        color: TRTextColor.muted,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            CoderIcons.chat,
            size: TRSpacing.twoExtraLarge,
            color: context.tinyrackTheme.textMuted,
          ),
          const SizedBox(height: TRSpacing.medium),
          TRText(AppLocalizations.of(context).chatEmptyTitle),
          const SizedBox(height: TRSpacing.small),
          TRText(
            AppLocalizations.of(context).chatEmptyExample,
            variant: TRTextVariant.bodySm,
            color: TRTextColor.muted,
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
          ),
        ),
        const SizedBox(width: TRSpacing.small),
        TRText(
          AppLocalizations.of(context).commonRunning,
          variant: TRTextVariant.bodySm,
          color: TRTextColor.muted,
        ),
      ],
    ),
  );
}
