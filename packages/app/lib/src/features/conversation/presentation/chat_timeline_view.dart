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
import 'package:flutter/material.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Builds the controls belonging to one actionable plan row.
typedef ChatPlanActionBuilder = Widget? Function(ChatPlanProposal proposal);

/// Scrolling conversation body rendered from projected chat items.
class ChatTimelineView extends StatefulWidget {
  /// Creates a timeline view.
  const ChatTimelineView({
    required this.items,
    required this.busy,
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
  static const double _cacheExtentViewportMultiplier = 4;

  // Expansion lives here so a card keeps its state when it scrolls out of the
  // cache extent or when new events shift every reversed index.
  final Set<String> _expanded = <String>{};
  final Map<String, Future<Uint8List>> _attachmentCache =
      <String, Future<Uint8List>>{};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Folds or unfolds a row while holding it still on screen.
  ///
  /// The list is reversed, so a row that grows extends toward the top of the
  /// viewport. Without this correction the header the user just clicked jumps
  /// upward by the body's height and the body lands where the header was, which
  /// reads as unfolding upward. Restoring the row's top edge pins the header
  /// and lets the body claim the space below it instead.
  void _toggle(String key, BuildContext rowContext) {
    final before = _rowTop(rowContext);
    setState(() {
      if (!_expanded.remove(key)) _expanded.add(key);
    });
    if (before == null) return;
    // One frame is enough: the disclosure swaps its body in without animating.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final after = _rowTop(rowContext);
      if (after == null) return;
      final position = _scrollController.position;
      // A reversed offset grows upward, so adding the drop pushes the row back
      // down to where the pointer left it.
      final target = (position.pixels + (before - after)).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (target != position.pixels) _scrollController.jumpTo(target);
    });
  }

  double? _rowTop(BuildContext rowContext) {
    if (!rowContext.mounted) return null;
    final box = rowContext.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero).dy;
  }

  Future<Uint8List> _load(ChatAttachment attachment) =>
      _attachmentCache.putIfAbsent(
        attachment.id,
        () => widget.loadAttachment!(attachment),
      );

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
    // The list is reversed so new items pin to the bottom; every row carries a
    // stable key so expanding a tool card cannot leak into its neighbour when
    // indices shift.
    // The list owns its own viewport, so the scroll area may only theme it.
    return TRScrollArea.forScrollable(
      controller: _scrollController,
      child: ListView.separated(
        controller: _scrollController,
        primary: false,
        reverse: true,
        // Flutter estimates an unbuilt SliverList's full height from the
        // rows currently laid out. Chat rows vary sharply in height, so a
        // wider viewport-relative sample keeps the scrollbar thumb stable
        // while retaining lazy construction for distant history.
        scrollCacheExtent: const .viewport(
          _cacheExtentViewportMultiplier,
        ),
        padding: const EdgeInsets.fromLTRB(
          TRSpacing.extraLarge,
          TRSpacing.large,
          TRSpacing.extraLarge,
          TRSpacing.large,
        ),
        itemCount: items.length + (showRunning ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: TRSpacing.small),
        // Every new event shifts the reversed indices, so keys are mapped
        // back to their slot; without this an expanded card would leak its
        // state into whichever item lands on its old index.
        findItemIndexCallback: (key) {
          if (key is! ValueKey<String>) return null;
          final position = items.indexWhere(
            (item) => item.key == key.value,
          );
          if (position < 0) return null;
          return items.length - position - 1 + (showRunning ? 1 : 0);
        },
        itemBuilder: (context, index) {
          if (showRunning && index == 0) {
            return const KeyedSubtree(
              key: ValueKey<String>('chat-running'),
              child: ChatRunningIndicator(),
            );
          }
          final itemIndex = index - (showRunning ? 1 : 0);
          final item = items[items.length - itemIndex - 1];
          return KeyedSubtree(
            key: ValueKey<String>(item.key),
            // The builder hands the toggle a context inside the row so the row
            // can be measured before and after it changes height.
            child: Builder(
              builder: (rowContext) => ChatItemView(
                item: item,
                expanded: _expanded.contains(item.key),
                onToggle: () => _toggle(item.key, rowContext),
                loadAttachment: widget.loadAttachment == null ? null : _load,
                exportAttachment: widget.exportAttachment,
                hostId: widget.hostId,
                planActionBuilder: widget.planActionBuilder,
              ),
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
