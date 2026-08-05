import 'dart:typed_data';

import 'package:coder_app/src/chat/chat_message_views.dart';
import 'package:coder_app/src/chat/chat_plan_card.dart';
import 'package:coder_app/src/chat/chat_sleep_card.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_tool_card.dart';
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Scrolling conversation body rendered from projected chat items.
class ChatTimelineView extends StatefulWidget {
  /// Creates a timeline view.
  const ChatTimelineView({
    required this.items,
    required this.busy,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// Items to render, oldest first.
  final List<ChatItem> items;

  /// Whether the session is currently running a turn.
  final bool busy;

  /// Authenticated attachment byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform file exporter.
  final ChatAttachmentExporter? exportAttachment;

  @override
  State<ChatTimelineView> createState() => _ChatTimelineViewState();
}

class _ChatTimelineViewState extends State<ChatTimelineView> {
  // Expansion lives here so a card keeps its state when it scrolls out of the
  // cache extent or when new events shift every reversed index.
  final Set<String> _expanded = <String>{};
  final Map<String, Future<Uint8List>> _attachmentCache =
      <String, Future<Uint8List>>{};

  Future<Uint8List> _load(ChatAttachment attachment) =>
      _attachmentCache.putIfAbsent(
        attachment.id,
        () => widget.loadAttachment!(attachment),
      );

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final busy = widget.busy;
    if (items.isEmpty) return const ChatEmptyState();
    // The list is reversed so new items pin to the bottom; every row carries a
    // stable key so expanding a tool card cannot leak into its neighbour when
    // indices shift.
    // The list owns its own viewport, so the scroll area may only theme it.
    return TRScrollArea.forScrollable(
      child: ListView.separated(
        reverse: true,
        padding: const EdgeInsets.fromLTRB(
          TRSpacing.extraLarge,
          TRSpacing.large,
          TRSpacing.extraLarge,
          TRSpacing.large,
        ),
        itemCount: items.length + (busy ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: TRSpacing.small),
        // Every new event shifts the reversed indices, so keys are mapped back
        // to their slot; without this an expanded card would leak its state
        // into whichever item lands on its old index.
        findItemIndexCallback: (key) {
          if (key is! ValueKey<String>) return null;
          final position = items.indexWhere((item) => item.key == key.value);
          if (position < 0) return null;
          return items.length - position - 1 + (busy ? 1 : 0);
        },
        itemBuilder: (context, index) {
          if (busy && index == 0) return const ChatRunningIndicator();
          final item = items[items.length - index - 1 + (busy ? 1 : 0)];
          return KeyedSubtree(
            key: ValueKey<String>(item.key),
            child: ChatItemView(
              item: item,
              expanded: _expanded.contains(item.key),
              onToggle: () => setState(() {
                if (!_expanded.remove(item.key)) _expanded.add(item.key);
              }),
              loadAttachment: widget.loadAttachment == null ? null : _load,
              exportAttachment: widget.exportAttachment,
            ),
          );
        },
      ),
    );
  }
}

/// Renders one projected chat item.
class ChatItemView extends StatelessWidget {
  /// Creates a chat item view.
  const ChatItemView({
    required this.item,
    this.expanded = false,
    this.onToggle,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// The item to render.
  final ChatItem item;

  /// Whether an expandable item shows its details.
  final bool expanded;

  /// Called when an expandable item is tapped.
  final VoidCallback? onToggle;

  /// Authenticated attachment byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform file exporter.
  final ChatAttachmentExporter? exportAttachment;

  @override
  Widget build(BuildContext context) {
    final value = item;
    return switch (value) {
      ChatUserMessage() => ChatUserLine(
        message: value,
        loadAttachment: loadAttachment,
        exportAttachment: exportAttachment,
      ),
      ChatAttachmentMessage() => ChatAttachmentLine(
        message: value,
        loadAttachment: loadAttachment,
        exportAttachment: exportAttachment,
      ),
      ChatAssistantMessage() => ChatAssistantMessageView(message: value),
      ChatPlanProposal() => ChatPlanCard(proposal: value),
      ChatToolActivity() => ChatToolCard(
        activity: value,
        expanded: expanded,
        onToggle: onToggle,
      ),
      ChatNotice() => ChatNoticeLine(notice: value),
      ChatUserAnswer() => ChatUserAnswerLine(answer: value),
      ChatSleep() => ChatSleepCard(sleep: value),
      ChatDeferredTools() => ChatDeferredToolsLine(notice: value),
      ChatContextReset() => ChatContextResetLine(reset: value),
      ChatUsage() => ChatUsageLine(usage: value),
      ChatUnknownEvent() => ChatUnknownEventLine(event: value),
    };
  }
}
