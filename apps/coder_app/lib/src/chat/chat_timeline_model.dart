import 'dart:typed_data';

import 'package:coder_app/src/chat/chat_plan.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Loads authenticated attachment bytes for preview.
typedef ChatAttachmentLoader =
    Future<Uint8List> Function(
      ChatAttachment attachment,
    );

/// Exports an authenticated attachment through the platform adapter.
typedef ChatAttachmentExporter =
    Future<void> Function(
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
/// requests merge with their result, and approval bookkeeping is dropped
/// because pending approvals are rendered from conversation state instead.
List<ChatItem> projectChatTimeline(List<TimelineEventDto> events) {
  final ordered = List<TimelineEventDto>.of(events)
    ..sort((left, right) => left.sequence.compareTo(right.sequence));
  final builders = <_ChatItemBuilder>[];
  final openAssistant = <String?, _AssistantBuilder>{};
  final openTools = <String, _ToolBuilder>{};
  final openPlans = <String, _PlanBuilder>{};
  final terminatedTurns = <String?>{};

  void closeAssistant(String? turnId) => openAssistant.remove(turnId);

  for (final event in ordered) {
    final turnId = event.turnId;
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
      case 'tool.requested':
        closeAssistant(turnId);
        if (_string(event.data['name']) == 'attach_file') continue;
        final callId = _string(event.data['callId']) ?? '';
        if (_string(event.data['name']) == 'update_plan' &&
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
        if (event.type == 'tool.completed' &&
            _string(event.data['name']) == 'attach_file' &&
            event.data['isError'] != true) {
          continue;
        }
        final callId = _string(event.data['callId']) ?? '';
        final status = switch (event.type) {
          'tool.completed' => ChatToolStatus.succeeded,
          'tool.failed' => ChatToolStatus.failed,
          _ => ChatToolStatus.denied,
        };
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
      case 'approval.resolved':
        // Pending approvals are rendered from conversation state, and a denied
        // approval already arrives as tool.denied.
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
