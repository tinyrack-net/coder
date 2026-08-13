import 'dart:convert';
import 'dart:typed_data';

import 'package:app/src/features/conversation/application/chat_tool_presentation.dart';
import 'package:app/src/features/conversation/presentation/chat_plan.dart';
import 'package:protocol/protocol.dart';

/// Loads authenticated attachment bytes for preview.
typedef ChatAttachmentLoader = Future<Uint8List> Function(
  ChatAttachment attachment,
);

/// Exports an authenticated attachment through the platform adapter.
typedef ChatAttachmentExporter = Future<void> Function(
  ChatAttachment attachment,
);

/// One renderable entry of a session conversation.
///
/// The projection collapses many raw [TimelineEventDto]s into a small set of
/// typed items so the UI never has to inspect event names or dump raw data.
sealed class ChatItem {
  /// Creates a chat item.
  const ChatItem({
    required this.key,
    required this.turnId,
    required this.createdAt,
  });

  /// Stable identity used as a list key; never changes as events arrive.
  final String key;

  /// Turn that produced this item, when the daemon recorded one.
  final String? turnId;

  /// Instant of the first event backing this item.
  final DateTime createdAt;
}

/// A prompt submitted by the user.
final class ChatUserMessage extends ChatItem {
  /// Creates a user message.
  const ChatUserMessage({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.text,
    this.attachments = const <ChatAttachment>[],
  });

  /// The prompt text.
  final String text;

  /// Ordered files submitted with the prompt.
  final List<ChatAttachment> attachments;
}

/// Renderable attachment metadata copied into the timeline.
final class ChatAttachment {
  /// Creates attachment presentation metadata.
  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
  });

  /// Stable daemon identifier.
  final String id;

  /// Display filename.
  final String fileName;

  /// Validated media type.
  final String mimeType;

  /// Exact payload length.
  final int byteSize;

  /// Whether the attachment can be previewed as an image.
  bool get isImage => <String>{
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/gif',
  }.contains(mimeType);
}

/// One file explicitly attached by the assistant.
final class ChatAttachmentMessage extends ChatItem {
  /// Creates an assistant attachment row.
  const ChatAttachmentMessage({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.attachment,
  });

  /// Published attachment.
  final ChatAttachment attachment;
}

/// Assistant prose merged from every delta of one uninterrupted block.
final class ChatAssistantMessage extends ChatItem {
  /// Creates an assistant message.
  const ChatAssistantMessage({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.markdown,
    this.isStreaming = false,
  });

  /// Markdown source assembled from the block's deltas.
  final String markdown;

  /// Whether the turn is still producing text.
  final bool isStreaming;
}

/// One provider invocation's display-safe reasoning text.
final class ChatReasoningActivity extends ChatItem {
  /// Creates a reasoning timeline item.
  const ChatReasoningActivity({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.markdown,
    required this.isStreaming,
  });

  /// Provider-authored plaintext reasoning or reasoning summary.
  final String markdown;

  /// Whether the provider invocation is still reasoning.
  final bool isStreaming;
}

/// A plan the agent recorded with the `update_plan` tool.
final class ChatPlanProposal extends ChatItem {
  /// Creates a plan proposal.
  const ChatPlanProposal({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.steps,
    required this.explanation,
  });

  /// The plan's steps in execution order; never empty.
  final List<ChatPlanStep> steps;

  /// Why the plan looks like this; empty when the agent gave no rationale.
  final String explanation;
}

/// Lifecycle shared by actionable conversation rows.
enum ChatInteractionStatus {
  /// The user can still act on the request.
  pending,

  /// The request has been resolved and remains in history.
  resolved,
}

/// One tool approval, retained in the timeline after it is resolved.
final class ChatApprovalInteraction extends ChatItem {
  /// Creates an approval timeline row.
  const ChatApprovalInteraction({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.approval,
    required this.status,
    this.approved,
  });

  /// The request and preview supplied by the daemon.
  final ApprovalRequestDto approval;

  /// Whether the row is still actionable.
  final ChatInteractionStatus status;

  /// The recorded decision, null while pending.
  final bool? approved;
}

/// One pending question occupying its eventual answer's timeline slot.
final class ChatQuestionInteraction extends ChatItem {
  /// Creates a question timeline row.
  const ChatQuestionInteraction({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.request,
  });

  /// The questions awaiting answers.
  final UserQuestionRequestDto request;
}

/// Lifecycle of one tool call.
enum ChatToolStatus {
  /// The tool was requested and has not reported a result yet.
  running,

  /// The tool returned a result.
  succeeded,

  /// The tool threw before returning a result.
  failed,

  /// The user rejected the approval request.
  denied,
}

/// One tool call with its request and result merged.
final class ChatToolActivity extends ChatItem {
  /// Creates a tool activity.
  const ChatToolActivity({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.callId,
    required this.toolName,
    required this.arguments,
    required this.status,
    this.output,
    this.error,
    this.isError = false,
  });

  /// Provider-assigned identifier shared by the request and its result.
  final String callId;

  /// Tool identifier, for example `exec_command`.
  final String toolName;

  /// Requested arguments; empty when only the result survived in history.
  final Map<String, dynamic> arguments;

  /// Lifecycle state of this call.
  final ChatToolStatus status;

  /// Raw tool output; some tools encode JSON inside this string.
  final String? output;

  /// Failure message when [status] is [ChatToolStatus.failed].
  final String? error;

  /// Whether a returned result reported a tool-level error.
  final bool isError;
}

/// Terminal state of one turn.
enum ChatNoticeKind {
  /// The turn finished normally.
  turnCompleted,

  /// The turn ended with an error.
  turnFailed,

  /// The user cancelled the turn.
  turnCancelled,
}

/// A short status line closing one turn.
final class ChatNotice extends ChatItem {
  /// Creates a turn notice.
  const ChatNotice({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.kind,
    this.message,
    this.toolRounds,
  });

  /// Which terminal state this notice reports.
  final ChatNoticeKind kind;

  /// Failure text for [ChatNoticeKind.turnFailed].
  final String? message;

  /// Tool rounds reported by a completed turn.
  final int? toolRounds;
}

/// One question the agent asked and the answer the user gave.
final class ChatQuestionAnswer {
  /// Creates a question-and-answer pair.
  const ChatQuestionAnswer({
    required this.header,
    required this.question,
    required this.answer,
    required this.isFreeForm,
  });

  /// The short label the agent gave the question.
  final String header;

  /// The question as it was put to the user.
  final String question;

  /// What the user chose, or typed when [isFreeForm].
  final String answer;

  /// Whether the user typed the answer instead of taking an option.
  final bool isFreeForm;
}

/// An answered `request_user_input` call, read as conversation rather than
/// tool output.
final class ChatUserAnswer extends ChatItem {
  /// Creates an answered-question item.
  const ChatUserAnswer({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.entries,
  });

  /// Every question of the call, paired with its answer.
  final List<ChatQuestionAnswer> entries;
}

/// One `sleep` call, rendered as a countdown rather than a tool row.
final class ChatSleep extends ChatItem {
  /// Creates a sleep item.
  const ChatSleep({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.duration,
    required this.startedAt,
    required this.isRunning,
    this.reason,
  });

  /// How long the agent asked to wait.
  final Duration duration;

  /// When the request was recorded, so elapsed time is recomputed on replay.
  final DateTime startedAt;

  /// Whether the wait is still in progress.
  final bool isRunning;

  /// What the agent said it was waiting for.
  final String? reason;
}

/// The point where `new_context` discarded the model's history.
///
/// The conversation above it stays on screen: only the model forgot it.
final class ChatContextReset extends ChatItem {
  /// Creates a context reset divider.
  const ChatContextReset({
    required super.key,
    required super.turnId,
    required super.createdAt,
  });
}

/// The point where the model's history was replaced by a summary of itself.
///
/// Unlike [ChatContextReset] the work above was carried forward rather than
/// dropped, so the two read differently even though both retire a window.
final class ChatContextCompacted extends ChatItem {
  /// Creates a compaction divider.
  const ChatContextCompacted({
    required super.key,
    required super.turnId,
    required super.createdAt,
  });
}

/// A notice that some tools were withheld from the model's tool list.
final class ChatDeferredTools extends ChatItem {
  /// Creates a deferred-tools notice.
  const ChatDeferredTools({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.count,
  });

  /// How many tools are reachable only through a search.
  final int count;
}

/// Token accounting reported by the provider.
final class ChatUsage extends ChatItem {
  /// Creates a usage item.
  const ChatUsage({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.tokens,
  });

  /// Provider-defined token counters.
  final Map<String, num> tokens;
}

/// An event this build does not know how to render yet.
final class ChatUnknownEvent extends ChatItem {
  /// Creates an unknown-event item.
  const ChatUnknownEvent({
    required super.key,
    required super.turnId,
    required super.createdAt,
    required this.type,
    required this.data,
  });

  /// Raw event type.
  final String type;

  /// Raw event payload, shown only when the user expands the row.
  final Map<String, dynamic> data;
}

/// Projects a persisted timeline into ordered, renderable chat items.
///
/// Assistant deltas of one turn merge across interleaved tool calls, tool
/// requests merge with their results, and live approval or question snapshots
/// merge with persisted events into one stable interaction row.
List<ChatItem> projectChatTimeline(
  List<TimelineEventDto> events, {
  Map<String, ApprovalRequestDto> approvals =
      const <String, ApprovalRequestDto>{},
  Map<String, UserQuestionRequestDto> questions =
      const <String, UserQuestionRequestDto>{},
}) {
  final ordered = List<TimelineEventDto>.of(events)
    ..sort((left, right) => left.sequence.compareTo(right.sequence));
  final builders = <_ChatItemBuilder>[];
  final openAssistant = <String?, _AssistantBuilder>{};
  final openReasoning = <String?, _ReasoningBuilder>{};
  final openTools = <String, _ToolBuilder>{};
  final openPlans = <String, _PlanBuilder>{};
  final openSleeps = <String, _SleepBuilder>{};
  final openQuestions = <String, _QuestionBuilder>{};
  final openApprovals = <String, _ApprovalBuilder>{};
  final terminatedTurns = <String?>{};

  void closeAssistant(String? turnId) => openAssistant.remove(turnId);
  void closeReasoning(String? turnId) {
    openReasoning.remove(turnId)?.complete();
  }

  for (final event in ordered) {
    final turnId = event.turnId;
    if (event.type != 'assistant.reasoning.started' &&
        event.type != 'assistant.reasoning.delta') {
      closeReasoning(turnId);
    }
    switch (event.type) {
      case 'user.message':
        closeAssistant(turnId);
        builders.add(
          _StaticBuilder(
            ChatUserMessage(
              key: 'user-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              text: _string(event.data['text']) ?? '',
              attachments: _attachments(event.data['attachments']),
            ),
          ),
        );
      case 'assistant.attachment':
        closeAssistant(turnId);
        final attachment = _attachment(event.data);
        if (attachment != null) {
          builders.add(
            _StaticBuilder(
              ChatAttachmentMessage(
                key: 'attachment-${event.sequence}',
                turnId: turnId,
                createdAt: event.createdAt,
                attachment: attachment,
              ),
            ),
          );
        }
      case 'assistant.delta':
        closeReasoning(turnId);
        final text = _string(event.data['text']) ?? '';
        final open = openAssistant[turnId];
        if (open == null) {
          final builder = _AssistantBuilder(
            key: 'assistant-${event.sequence}',
            turnId: turnId,
            createdAt: event.createdAt,
          )..append(text);
          openAssistant[turnId] = builder;
          builders.add(builder);
        } else {
          open.append(text);
        }
      case 'assistant.reasoning.started':
        closeAssistant(turnId);
        closeReasoning(turnId);
        final builder = _ReasoningBuilder(
          key: 'reasoning-${event.sequence}',
          turnId: turnId,
          createdAt: event.createdAt,
        );
        openReasoning[turnId] = builder;
        builders.add(builder);
      case 'assistant.reasoning.delta':
        closeAssistant(turnId);
        final text = _string(event.data['text']) ?? '';
        final builder = openReasoning[turnId];
        if (builder != null) {
          builder.append(text);
        } else {
          final synthesized = _ReasoningBuilder(
            key: 'reasoning-${event.sequence}',
            turnId: turnId,
            createdAt: event.createdAt,
          )..append(text);
          openReasoning[turnId] = synthesized;
          builders.add(synthesized);
        }
      case 'assistant.reasoning.completed':
        closeAssistant(turnId);
        closeReasoning(turnId);
      case 'tool.requested':
        closeAssistant(turnId);
        // A tool that renders as its own item wants no row beside it, which
        // is a fact each presenter states rather than a set kept here.
        if (_timelineOf(event) == ChatToolTimeline.suppressed) continue;
        final callId = _string(event.data['callId']) ?? '';
        if (_timelineOf(event) == ChatToolTimeline.card &&
            _string(event.data['name']) == 'update_plan' &&
            !openPlans.containsKey('$turnId/$callId')) {
          // A plan renders as its own card; a plan the model malformed badly
          // enough to parse to nothing falls through to a plain tool row so the
          // failure stays visible.
          final update = parseUpdatePlanArguments(
            _map(event.data['arguments']),
          );
          if (update != null) {
            final builder = _PlanBuilder(
              key: 'plan-$callId-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              callId: callId,
              update: update,
            );
            openPlans['$turnId/$callId'] = builder;
            builders.add(builder);
            continue;
          }
        }
        if (_timelineOf(event) == ChatToolTimeline.card &&
            _string(event.data['name']) == 'request_user_input' &&
            !openQuestions.containsKey('$turnId/$callId')) {
          // A pending question renders from conversation state, so a tool row
          // beside it would only duplicate it; the answer replaces both.
          final builder = _QuestionBuilder(
            key: 'question-$callId-${event.sequence}',
            turnId: turnId,
            createdAt: event.createdAt,
            callId: callId,
            questions: _map(event.data['arguments'])['questions'],
          );
          openQuestions['$turnId/$callId'] = builder;
          builders.add(builder);
          continue;
        }
        if (_timelineOf(event) == ChatToolTimeline.card &&
            _string(event.data['name']) == 'clock__sleep' &&
            !openSleeps.containsKey('$turnId/$callId')) {
          final arguments = _map(event.data['arguments']);
          final milliseconds = arguments['duration_ms'];
          if (milliseconds is int && milliseconds > 0) {
            final builder = _SleepBuilder(
              key: 'sleep-$callId-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              duration: Duration(milliseconds: milliseconds),
              reason: _string(arguments['reason']),
            );
            openSleeps['$turnId/$callId'] = builder;
            builders.add(builder);
            continue;
          }
        }
        final existing = openTools['$turnId/$callId'];
        if (existing != null && existing.status == ChatToolStatus.running) {
          continue;
        }
        if (existing != null && existing.synthesized) {
          // A truncated history delivered the result first; this request only
          // restores the arguments instead of starting a second activity.
          existing.arguments = _map(event.data['arguments']);
          continue;
        }
        final builder = _ToolBuilder(
          key: 'tool-$callId-${event.sequence}',
          turnId: turnId,
          createdAt: event.createdAt,
          callId: callId,
          toolName: _string(event.data['name']) ?? '',
          arguments: _map(event.data['arguments']),
        );
        openTools['$turnId/$callId'] = builder;
        builders.add(builder);
      case 'tool.completed':
      case 'tool.failed':
      case 'tool.denied':
        closeAssistant(turnId);
        // A failure still falls through to a plain row so it stays visible.
        if (event.type == 'tool.completed' &&
            _timelineOf(event) == ChatToolTimeline.suppressed &&
            event.data['isError'] != true) {
          continue;
        }
        final callId = _string(event.data['callId']) ?? '';
        final status = switch (event.type) {
          'tool.completed' => ChatToolStatus.succeeded,
          'tool.failed' => ChatToolStatus.failed,
          _ => ChatToolStatus.denied,
        };
        final question = openQuestions['$turnId/$callId'];
        if (question != null) {
          question.finish(
            status: status,
            output: _string(event.data['output']),
            error: _string(event.data['error']),
            isError: event.data['isError'] == true,
          );
          continue;
        }
        final sleep = openSleeps['$turnId/$callId'];
        if (sleep != null) {
          sleep.finish();
          continue;
        }
        final plan = openPlans['$turnId/$callId'];
        if (plan != null) {
          if (status != ChatToolStatus.succeeded ||
              event.data['isError'] == true) {
            // The daemon rejected the plan, so surface the rejection rather
            // than a card built from arguments that were never accepted.
            plan.reject(
              status: status,
              output: _string(event.data['output']),
              error: _string(event.data['error']),
            );
          }
          continue;
        }
        final existing = openTools['$turnId/$callId'];
        if (existing != null && existing.status != ChatToolStatus.running) {
          continue;
        }
        final builder =
            existing ??
            (_ToolBuilder(
              key: 'tool-$callId-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              callId: callId,
              toolName: _string(event.data['name']) ?? '',
              arguments: const <String, dynamic>{},
              synthesized: true,
            ));
        if (existing == null) {
          openTools['$turnId/$callId'] = builder;
          builders.add(builder);
        }
        builder.finish(
          status: status,
          output: _string(event.data['output']),
          error: _string(event.data['error']),
          isError: event.data['isError'] == true,
        );
      case 'context.reset':
        closeAssistant(turnId);
        builders.add(
          _StaticBuilder(
            ChatContextReset(
              key: 'context-reset-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
            ),
          ),
        );
      case 'context.compacted':
        closeAssistant(turnId);
        builders.add(
          _StaticBuilder(
            ChatContextCompacted(
              key: 'context-compacted-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
            ),
          ),
        );
      case 'tools.deferred':
        closeAssistant(turnId);
        final count = event.data['count'];
        if (count is int && count > 0) {
          builders.add(
            _StaticBuilder(
              ChatDeferredTools(
                key: 'deferred-${event.sequence}',
                turnId: turnId,
                createdAt: event.createdAt,
                count: count,
              ),
            ),
          );
        }
      case 'model.usage':
        closeAssistant(turnId);
        builders.add(
          _StaticBuilder(
            ChatUsage(
              key: 'usage-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              tokens: <String, num>{
                for (final entry in event.data.entries)
                  if (entry.value is num) entry.key: entry.value as num,
              },
            ),
          ),
        );
      case 'turn.completed':
      case 'turn.failed':
      case 'turn.cancelled':
        closeAssistant(turnId);
        terminatedTurns.add(turnId);
        final kind = switch (event.type) {
          'turn.completed' => ChatNoticeKind.turnCompleted,
          'turn.failed' => ChatNoticeKind.turnFailed,
          _ => ChatNoticeKind.turnCancelled,
        };
        final rounds = event.data['toolRounds'];
        builders.add(
          _StaticBuilder(
            ChatNotice(
              key: 'notice-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              kind: kind,
              message: _string(event.data['error']),
              toolRounds: rounds is int ? rounds : null,
            ),
          ),
        );
      case 'approval.requested':
        final raw = event.data['approval'];
        if (raw is Map<dynamic, dynamic>) {
          final approval = ApprovalRequestDto.fromJson(
            Map<String, dynamic>.from(raw),
          );
          final builder = _ApprovalBuilder(
            approval: approval,
            turnId: turnId,
            createdAt: event.createdAt,
          );
          openApprovals[approval.id] = builder;
          builders.add(builder);
        }
      case 'approval.resolved':
        final approvalId = _string(event.data['approvalId']);
        final status = _string(event.data['status']);
        if (approvalId != null) {
          openApprovals[approvalId]?.decision = status == 'approved';
        }
      case 'userQuestion.requested':
        final raw = event.data['request'];
        if (raw is Map<dynamic, dynamic>) {
          final request = UserQuestionRequestDto.fromJson(
            Map<String, dynamic>.from(raw),
          );
          openQuestions['${request.turnId}/${request.toolCallId}']?.request =
              request;
        }
      case 'userQuestion.answered':
        continue;
      default:
        closeAssistant(turnId);
        builders.add(
          _StaticBuilder(
            ChatUnknownEvent(
              key: 'event-${event.sequence}',
              turnId: turnId,
              createdAt: event.createdAt,
              type: event.type,
              data: event.data,
            ),
          ),
        );
    }
  }

  // Broadcast notifications can precede their persisted timeline event. Fold
  // those snapshots into the same builders so the later event does not create
  // a second row or a new key.
  for (final approval in approvals.values) {
    final existing = openApprovals[approval.id];
    if (existing != null) continue;
    final builder = _ApprovalBuilder(
      approval: approval,
      turnId: approval.turnId,
      createdAt: approval.createdAt,
    );
    openApprovals[approval.id] = builder;
    builders.add(builder);
  }
  for (final request in questions.values) {
    final existing = openQuestions['${request.turnId}/${request.toolCallId}'];
    if (existing != null) {
      existing.request = request;
      continue;
    }
    builders.add(
      _StaticBuilder(
        ChatQuestionInteraction(
          key: 'question-${request.toolCallId}',
          turnId: request.turnId,
          createdAt: request.createdAt,
          request: request,
        ),
      ),
    );
  }

  // Only the trailing assistant block of an unfinished turn is still growing.
  final lastAssistant = <String?, _AssistantBuilder>{};
  for (final builder in builders) {
    if (builder is _AssistantBuilder) lastAssistant[builder.turnId] = builder;
  }

  // A turn shows one plan card: repeated update_plan calls revise the same
  // plan, so every accepted call but the last is superseded.
  final lastPlan = <String?, _PlanBuilder>{};
  for (final builder in builders) {
    if (builder is _PlanBuilder && !builder.rejected) {
      lastPlan[builder.turnId] = builder;
    }
  }
  for (final builder in builders) {
    if (builder is _PlanBuilder && !builder.rejected) {
      builder.superseded = !identical(lastPlan[builder.turnId], builder);
    }
  }
  final items = <ChatItem>[];
  for (final builder in builders) {
    items.addAll(
      builder.build(
        isStreaming:
            !terminatedTurns.contains(builder.turnId) &&
            identical(lastAssistant[builder.turnId], builder),
      ),
    );
  }
  return List<ChatItem>.unmodifiable(items);
}

String? _string(Object? value) => value is String ? value : null;

Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic>
    ? Map<String, dynamic>.unmodifiable(value)
    : const <String, dynamic>{};

List<ChatAttachment> _attachments(Object? value) => value is List
    ? value
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => _attachment(Map<String, dynamic>.from(item)))
          .whereType<ChatAttachment>()
          .toList(growable: false)
    : const <ChatAttachment>[];

ChatAttachment? _attachment(Map<dynamic, dynamic> data) {
  final id = data['id'];
  final fileName = data['fileName'];
  final mimeType = data['mimeType'];
  final byteSize = data['byteSize'];
  if (id is! String ||
      fileName is! String ||
      mimeType is! String ||
      byteSize is! int) {
    return null;
  }
  return ChatAttachment(
    id: id,
    fileName: fileName,
    mimeType: mimeType,
    byteSize: byteSize,
  );
}

sealed class _ChatItemBuilder {
  const _ChatItemBuilder();

  String? get turnId;

  List<ChatItem> build({required bool isStreaming});
}

final class _StaticBuilder extends _ChatItemBuilder {
  const _StaticBuilder(this.item);

  final ChatItem item;

  @override
  String? get turnId => item.turnId;

  @override
  List<ChatItem> build({required bool isStreaming}) => <ChatItem>[item];
}

final class _ApprovalBuilder extends _ChatItemBuilder {
  _ApprovalBuilder({
    required this.approval,
    required this.turnId,
    required this.createdAt,
  });

  final ApprovalRequestDto approval;

  @override
  final String? turnId;

  final DateTime createdAt;
  bool? _decision;

  bool? get decision => _decision;

  set decision(bool value) => _decision = value;

  @override
  List<ChatItem> build({required bool isStreaming}) => <ChatItem>[
    ChatApprovalInteraction(
      key: 'approval-${approval.id}',
      turnId: turnId,
      createdAt: createdAt,
      approval: approval,
      status: decision == null
          ? ChatInteractionStatus.pending
          : ChatInteractionStatus.resolved,
      approved: decision,
    ),
  ];
}

final class _AssistantBuilder extends _ChatItemBuilder {
  _AssistantBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final StringBuffer _text = StringBuffer();

  void append(String text) => _text.write(text);

  @override
  List<ChatItem> build({required bool isStreaming}) {
    final markdown = _text.toString();
    return <ChatItem>[
      if (markdown.isNotEmpty)
        ChatAssistantMessage(
          key: key,
          turnId: turnId,
          createdAt: createdAt,
          markdown: markdown,
          isStreaming: isStreaming,
        ),
    ];
  }
}

final class _ReasoningBuilder extends _ChatItemBuilder {
  _ReasoningBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final StringBuffer _text = StringBuffer();
  bool _completed = false;

  void append(String text) => _text.write(text);

  void complete() => _completed = true;

  @override
  List<ChatItem> build({required bool isStreaming}) {
    final markdown = _text.toString();
    return <ChatItem>[
      if (markdown.isNotEmpty || !_completed)
        ChatReasoningActivity(
          key: key,
          turnId: turnId,
          createdAt: createdAt,
          markdown: markdown,
          isStreaming: !_completed,
        ),
    ];
  }
}

final class _PlanBuilder extends _ChatItemBuilder {
  _PlanBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
    required this.callId,
    required this.update,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final String callId;
  final ChatPlanUpdate update;

  /// Whether a later accepted plan in the same turn replaced this one.
  bool superseded = false;

  /// Whether the daemon refused this plan; set by [reject].
  bool rejected = false;

  ChatToolStatus _status = ChatToolStatus.succeeded;
  String? _output;
  String? _error;

  void reject({
    required ChatToolStatus status,
    required String? output,
    required String? error,
  }) {
    rejected = true;
    _status = status;
    _output = output;
    _error = error;
  }

  @override
  List<ChatItem> build({required bool isStreaming}) {
    if (rejected) {
      return <ChatItem>[
        ChatToolActivity(
          key: key,
          turnId: turnId,
          createdAt: createdAt,
          callId: callId,
          toolName: 'update_plan',
          arguments: const <String, dynamic>{},
          status: _status,
          output: _output,
          error: _error,
          isError: _status == ChatToolStatus.succeeded,
        ),
      ];
    }
    if (superseded) return const <ChatItem>[];
    return <ChatItem>[
      ChatPlanProposal(
        key: key,
        turnId: turnId,
        createdAt: createdAt,
        steps: update.steps,
        explanation: update.explanation,
      ),
    ];
  }
}

final class _QuestionBuilder extends _ChatItemBuilder {
  _QuestionBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
    required this.callId,
    required this.questions,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final String callId;
  final Object? questions;
  UserQuestionRequestDto? request;

  ChatToolStatus _status = ChatToolStatus.running;
  String? _output;
  String? _error;
  bool _isError = false;

  void finish({
    required ChatToolStatus status,
    required String? output,
    required String? error,
    required bool isError,
  }) {
    _status = status;
    _output = output;
    _error = error;
    _isError = isError;
  }

  /// Pairs each asked question with the answer that came back.
  List<ChatQuestionAnswer> _entries() {
    final asked = questions;
    final output = _output;
    if (asked is! List || output == null) return const <ChatQuestionAnswer>[];
    final Object? decoded;
    try {
      decoded = jsonDecode(output);
    } on FormatException {
      return const <ChatQuestionAnswer>[];
    }
    if (decoded is! List) return const <ChatQuestionAnswer>[];
    final answers = <String, Map<String, dynamic>>{
      for (final entry in decoded.whereType<Map<dynamic, dynamic>>())
        if (entry['questionId'] case final String id)
          id: Map<String, dynamic>.from(entry),
    };
    return <ChatQuestionAnswer>[
      for (final entry in asked.whereType<Map<dynamic, dynamic>>())
        if (entry['id'] case final String id)
          if (answers[id] case final answer?)
            ChatQuestionAnswer(
              header: _string(entry['header']) ?? '',
              question: _string(entry['question']) ?? '',
              answer: _string(answer['answer']) ?? '',
              isFreeForm: answer['isFreeForm'] == true,
            ),
    ];
  }

  @override
  List<ChatItem> build({required bool isStreaming}) {
    if (_status == ChatToolStatus.running) {
      final pending = request;
      return pending == null
          ? const <ChatItem>[]
          : <ChatItem>[
              ChatQuestionInteraction(
                key: key,
                turnId: turnId,
                createdAt: createdAt,
                request: pending,
              ),
            ];
    }
    final entries = _entries();
    if (_isError || _status != ChatToolStatus.succeeded || entries.isEmpty) {
      // A refused or cancelled question stays a tool row so it is visible.
      return <ChatItem>[
        ChatToolActivity(
          key: key,
          turnId: turnId,
          createdAt: createdAt,
          callId: callId,
          toolName: 'request_user_input',
          arguments: const <String, dynamic>{},
          status: _status,
          output: _output,
          error: _error,
          isError: _isError,
        ),
      ];
    }
    return <ChatItem>[
      ChatUserAnswer(
        key: key,
        turnId: turnId,
        createdAt: createdAt,
        entries: entries,
      ),
    ];
  }
}

final class _SleepBuilder extends _ChatItemBuilder {
  _SleepBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
    required this.duration,
    required this.reason,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final Duration duration;
  final String? reason;
  bool _running = true;

  void finish() => _running = false;

  @override
  List<ChatItem> build({required bool isStreaming}) => <ChatItem>[
    ChatSleep(
      key: key,
      turnId: turnId,
      createdAt: createdAt,
      duration: duration,
      startedAt: createdAt,
      isRunning: _running,
      reason: reason,
    ),
  ];
}

final class _ToolBuilder extends _ChatItemBuilder {
  _ToolBuilder({
    required this.key,
    required this.turnId,
    required this.createdAt,
    required this.callId,
    required this.toolName,
    required this.arguments,
    this.synthesized = false,
  });

  final String key;

  @override
  final String? turnId;

  final DateTime createdAt;
  final String callId;
  final String toolName;

  /// Whether this activity was created from a result without a request.
  final bool synthesized;

  /// Requested arguments, restored later when the result arrived first.
  Map<String, dynamic> arguments;

  ChatToolStatus status = ChatToolStatus.running;

  String? output;
  String? error;
  bool isError = false;

  void finish({
    required ChatToolStatus status,
    required String? output,
    required String? error,
    required bool isError,
  }) {
    this.status = status;
    this.output = output;
    this.error = error;
    this.isError = isError;
  }

  @override
  List<ChatItem> build({required bool isStreaming}) => <ChatItem>[
    ChatToolActivity(
      key: key,
      turnId: turnId,
      createdAt: createdAt,
      callId: callId,
      toolName: toolName,
      arguments: arguments,
      status: status,
      output: output,
      error: error,
      isError: isError,
    ),
  ];
}

/// Where the tool behind [event] belongs in the timeline.
///
/// The answer is the tool's own, so a tool that renders as a card or as
/// nothing says so once in its presenter instead of being listed here.
ChatToolTimeline _timelineOf(TimelineEventDto event) =>
    presenterFor(_string(event.data['name']) ?? '').timeline;
