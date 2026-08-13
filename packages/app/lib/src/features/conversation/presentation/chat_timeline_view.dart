import 'dart:typed_data';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/application/chat_timeline_model.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/chat_message_views.dart';
import 'package:app/src/features/conversation/presentation/chat_plan_card.dart';
import 'package:app/src/features/conversation/presentation/chat_question_card.dart';
import 'package:app/src/features/conversation/presentation/chat_reasoning_card.dart';
import 'package:app/src/features/conversation/presentation/chat_sleep_card.dart';
import 'package:app/src/features/conversation/presentation/chat_tool_card.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Builds the controls belonging to one actionable plan row.
typedef ChatPlanActionBuilder = Widget? Function(ChatPlanProposal proposal);

/// Scrolling conversation body rendered from projected chat items.
class ChatTimelineView extends StatefulWidget {
  /// Creates a timeline view.
  const ChatTimelineView({
    required this.items,
    required this.busy,
    required this.pageStorageId,
    this.loading = false,
    this.hostId,
    this.planActionBuilder,
    this.loadAttachment,
    this.exportAttachment,
    super.key,
  });

  /// Items to render, oldest first.
  final List<ChatItem> items;

  /// Whether the session is currently running a turn.
  final bool busy;

  /// Stable restoration identity for this conversation's scroll position.
  final String pageStorageId;

  /// Whether history is still loading and no snapshot has ever arrived.
  ///
  /// A loading timeline renders a conversation-shaped skeleton: showing the
  /// "no messages" empty state would misreport a session that simply has not
  /// received its history yet.
  final bool loading;

  /// Host used to resolve approval and question interactions.
  final String? hostId;

  /// Builds actions inside the latest plan card.
  final ChatPlanActionBuilder? planActionBuilder;

  /// Authenticated attachment byte loader.
  final ChatAttachmentLoader? loadAttachment;

  /// Platform file exporter.
  final ChatAttachmentExporter? exportAttachment;

  @override
  State<ChatTimelineView> createState() => _ChatTimelineViewState();
}

class _ChatTimelineViewState extends State<ChatTimelineView> {
  // Expansion lives here so a card keeps its state when it scrolls out of the
  // cache extent or when new events shift its virtual index.
  final Set<String> _expanded = <String>{};
  final Map<String, Future<Uint8List>> _attachmentCache =
      <String, Future<Uint8List>>{};
  final TRVirtualListController<String> _virtualListController =
      TRVirtualListController<String>();

  @override
  void didUpdateWidget(covariant ChatTimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageStorageId == widget.pageStorageId) return;
    _expanded.clear();
    _attachmentCache.clear();
  }

  @override
  void dispose() {
    _virtualListController.dispose();
    super.dispose();
  }

  /// Folds or unfolds a row while holding it still on screen.
  void _toggle(String key) {
    _virtualListController.holdVisibleAnchorForNextLayout();
    setState(() {
      if (!_expanded.remove(key)) _expanded.add(key);
    });
  }

  Future<Uint8List> _load(ChatAttachment attachment) =>
      _attachmentCache.putIfAbsent(
        attachment.id,
        () => widget.loadAttachment!(attachment),
      );

  double _estimatedItemExtent(_ChatTimelineEntry entry, int _) =>
      switch (entry) {
        _ChatTimelineRunningEntry() => TRMeasurements.measureXs,
        _ChatTimelineItemEntry(:final item) => switch (item) {
          ChatAttachmentMessage() ||
          ChatNotice() ||
          ChatContextReset() ||
          ChatContextCompacted() ||
          ChatDeferredTools() ||
          ChatUsage() ||
          ChatUnknownEvent() => TRMeasurements.measureXs,
          ChatUserMessage() ||
          ChatAssistantMessage() ||
          ChatReasoningActivity() ||
          ChatPlanProposal() ||
          ChatApprovalInteraction() ||
          ChatQuestionInteraction() ||
          ChatToolActivity() ||
          ChatUserAnswer() ||
          ChatSleep() => TRMeasurements.measureSm,
        },
      };

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final busy = widget.busy;
    final reasoningActive =
        items.isNotEmpty &&
        items.last is ChatReasoningActivity &&
        (items.last as ChatReasoningActivity).isStreaming;
    final showRunning = busy && !reasoningActive;
    if (widget.loading && items.isEmpty) {
      return ChatTimelineSkeleton(
        semanticLabel: AppLocalizations.of(context).conversationLoading,
      );
    }
    if (items.isEmpty && !busy) return const ChatEmptyState();
    final entries = <_ChatTimelineEntry>[
      for (final item in items) _ChatTimelineItemEntry(item),
      if (showRunning) const _ChatTimelineRunningEntry(),
    ];
    return TRVirtualList<_ChatTimelineEntry, String>(
      items: entries,
      itemKey: (entry) => entry.key,
      estimatedItemExtent: _estimatedItemExtent,
      controller: _virtualListController,
      initialPosition: const TRVirtualListInitialPosition<String>.trailing(),
      follow: TRVirtualListFollow.trailing,
      scrollCacheExtent: const .viewport(4),
      pageStorageId: widget.pageStorageId,
      itemBuilder: (context, entry, index) {
        final content = switch (entry) {
          _ChatTimelineRunningEntry() => const ChatRunningIndicator(),
          _ChatTimelineItemEntry(:final item) => ChatItemView(
            item: item,
            expanded: _expanded.contains(item.key),
            onToggle: () => _toggle(item.key),
            loadAttachment: widget.loadAttachment == null ? null : _load,
            exportAttachment: widget.exportAttachment,
            hostId: widget.hostId,
            planActionBuilder: widget.planActionBuilder,
          ),
        };
        return Padding(
          padding: EdgeInsets.only(
            left: TRSpacing.extraLarge,
            top: index == 0 ? TRSpacing.large : 0,
            right: TRSpacing.extraLarge,
            bottom: index == entries.length - 1
                ? TRSpacing.large
                : TRSpacing.small,
          ),
          child: KeyedSubtree(
            key: ValueKey<String>(entry.key),
            child: content,
          ),
        );
      },
    );
  }
}

sealed class _ChatTimelineEntry {
  const _ChatTimelineEntry();

  String get key;
}

final class _ChatTimelineItemEntry extends _ChatTimelineEntry {
  const _ChatTimelineItemEntry(this.item);

  final ChatItem item;

  @override
  String get key => item.key;
}

final class _ChatTimelineRunningEntry extends _ChatTimelineEntry {
  const _ChatTimelineRunningEntry();

  @override
  String get key => 'chat-running';
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
    this.hostId,
    this.planActionBuilder,
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

  /// Host used by actionable interaction rows.
  final String? hostId;

  /// Builds actions inside a plan card.
  final ChatPlanActionBuilder? planActionBuilder;

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
      ChatReasoningActivity() => ChatReasoningCard(
        activity: value,
        expanded: expanded,
        onToggle: onToggle,
      ),
      ChatPlanProposal() => ChatPlanCard(
        proposal: value,
        actions: planActionBuilder?.call(value),
      ),
      ChatApprovalInteraction() => ApprovalCard(
        hostId: hostId,
        interaction: value,
      ),
      ChatQuestionInteraction() => ChatQuestionCard(
        key: ValueKey<String>(value.request.id),
        hostId: hostId,
        request: value.request,
      ),
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
      ChatContextCompacted() => ChatContextCompactedLine(compacted: value),
      ChatUsage() => ChatUsageLine(usage: value),
      ChatUnknownEvent() => ChatUnknownEventLine(event: value),
    };
  }
}
