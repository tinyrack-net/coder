import 'dart:async';
import 'dart:typed_data';

import 'package:coder_agent/src/tool_search.dart';
import 'package:coder_agent/src/usage.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// CancellationToken defines a public contract.
class CancellationToken {
  /// The isCancelled public API member.
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  /// The cancel public API member.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  /// The onCancel public API member.
  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  /// The throwIfCancelled public API member.
  void throwIfCancelled() {
    if (_isCancelled) throw const AgentCancelledException();
  }
}

/// AgentCancelledException defines a public contract.
class AgentCancelledException implements Exception {
  /// Creates a [AgentCancelledException].
  const AgentCancelledException();
}

/// A provider refused a request because the conversation outgrew its context
/// window.
///
/// Every adapter classifies this one failure itself, because the runner has to
/// tell "the history no longer fits" apart from every other transport error:
/// the first is recoverable by compacting, the rest are not.
class ModelContextOverflowException implements Exception {
  /// Creates a [ModelContextOverflowException].
  const ModelContextOverflowException(this.message);

  /// The provider's own wording, kept for the failure surfaced to the user.
  final String message;

  @override
  String toString() => 'ModelContextOverflowException: $message';
}

/// ModelToolDefinition defines a public contract.
class ModelToolDefinition {
  /// Creates a [ModelToolDefinition].
  const ModelToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
    this.strict = true,
  });

  /// The name public API member.
  final String name;

  /// The description public API member.
  final String description;

  /// The parameters public API member.
  final Map<String, dynamic> parameters;

  /// Whether [parameters] satisfies provider strict-schema requirements.
  final bool strict;
}

/// ConversationToolCall defines a public contract.
class ConversationToolCall {
  /// Creates a [ConversationToolCall].
  const ConversationToolCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  /// Creates a [ConversationToolCall].
  factory ConversationToolCall.fromJson(Map<String, dynamic> json) =>
      ConversationToolCall(
        callId: json['callId']! as String,
        name: json['name']! as String,
        arguments: Map<String, dynamic>.from(json['arguments']! as Map),
      );

  /// The callId public API member.
  final String callId;

  /// The name public API member.
  final String name;

  /// The arguments public API member.
  final Map<String, dynamic> arguments;

  /// The toJson public API member.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'callId': callId,
    'name': name,
    'arguments': arguments,
  };
}

/// ConversationItem defines a public contract.
sealed class ConversationItem {
  const ConversationItem();

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'user' => UserConversationItem(
        json['text']! as String,
        attachments: (json['attachments'] as List? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) => ConversationAttachment.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
      ),
      'assistant' => AssistantConversationItem(
        text: json['text'] as String? ?? '',
        toolCalls: (json['toolCalls'] as List? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) => ConversationToolCall.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
        opaqueItems: (json['opaqueItems'] as List? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false),
      ),
      'toolResult' => ToolResultConversationItem(
        callId: json['callId']! as String,
        output: json['output']! as String,
        isError: json['isError'] == true,
      ),
      _ => throw FormatException('Unknown conversation item: ${json['type']}'),
    };
  }

  /// The toJson public API member.
  Map<String, dynamic> toJson();
}

/// An attachment reference carried in provider conversation history.
///
/// Persisted JSON contains references and metadata only. [bytes] is populated
/// just before a provider request and is deliberately never serialized.
class ConversationAttachment {
  /// Creates a conversation attachment reference.
  const ConversationAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.path,
    this.bytes,
    this.kind,
    this.sha256,
    this.createdAt,
    this.imageDetail,
  });

  /// Decodes a persisted attachment reference.
  factory ConversationAttachment.fromJson(Map<String, dynamic> json) =>
      ConversationAttachment(
        id: json['id']! as String,
        fileName: json['fileName']! as String,
        mimeType: json['mimeType']! as String,
        byteSize: json['byteSize']! as int,
        path: json['path']! as String,
        kind: json['kind'] == null
            ? null
            : AttachmentKind.values.byName(json['kind']! as String),
        sha256: json['sha256'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt']! as String),
        imageDetail: json['imageDetail'] as String?,
      );

  /// Stable daemon attachment identifier.
  final String id;

  /// Display-only original file name.
  final String fileName;

  /// Validated media type.
  final String mimeType;

  /// Exact content length.
  final int byteSize;

  /// Daemon-controlled path exposed to attachment tools as a fallback.
  final String path;

  /// Ephemeral bytes hydrated for a provider invocation.
  final Uint8List? bytes;

  /// Broad preview kind from the daemon metadata snapshot.
  final AttachmentKind? kind;

  /// Content digest from the daemon metadata snapshot.
  final String? sha256;

  /// Upload completion time from the daemon metadata snapshot.
  final DateTime? createdAt;

  /// Fidelity a provider should read this image at: `auto`, `low`, or `high`.
  ///
  /// Null everywhere except an image a tool deliberately put into the model's
  /// context, where the tool chooses how much detail the task needs.
  final String? imageDetail;

  /// Encodes only the durable reference and metadata.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'byteSize': byteSize,
    'path': path,
    if (kind != null) 'kind': kind!.name,
    if (sha256 != null) 'sha256': sha256,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (imageDetail != null) 'imageDetail': imageDetail,
  };
}

/// UserConversationItem defines a public contract.
class UserConversationItem extends ConversationItem {
  /// Creates a [UserConversationItem].
  const UserConversationItem(
    this.text, {
    this.attachments = const <ConversationAttachment>[],
  });

  /// The text public API member.
  final String text;

  /// Ordered attachment references submitted with this message.
  final List<ConversationAttachment> attachments;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'user',
    'text': text,
    if (attachments.isNotEmpty)
      'attachments': attachments.map((item) => item.toJson()).toList(),
  };
}

/// AssistantConversationItem defines a public contract.
class AssistantConversationItem extends ConversationItem {
  /// Creates a [AssistantConversationItem].
  const AssistantConversationItem({
    required this.text,
    this.toolCalls = const <ConversationToolCall>[],
    this.opaqueItems = const <Map<String, dynamic>>[],
  });

  /// The text public API member.
  final String text;

  /// The toolCalls public API member.
  final List<ConversationToolCall> toolCalls;

  /// The opaqueItems public API member.
  final List<Map<String, dynamic>> opaqueItems;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'assistant',
    'text': text,
    'toolCalls': toolCalls.map((item) => item.toJson()).toList(),
    'opaqueItems': opaqueItems,
  };
}

/// ToolResultConversationItem defines a public contract.
class ToolResultConversationItem extends ConversationItem {
  /// Creates a [ToolResultConversationItem].
  const ToolResultConversationItem({
    required this.callId,
    required this.output,
    this.isError = false,
  });

  /// The callId public API member.
  final String callId;

  /// The output public API member.
  final String output;

  /// The isError public API member.
  final bool isError;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'toolResult',
    'callId': callId,
    'output': output,
    'isError': isError,
  };
}

/// ModelRequest defines a public contract.
class ModelRequest {
  /// Creates a [ModelRequest].
  const ModelRequest({
    required this.model,
    required this.reasoningEffort,
    required this.instructions,
    required this.history,
    required this.tools,
    required this.safetyIdentifier,
    this.forceToolName,
    this.serviceTier,
  });

  /// The model public API member.
  final String model;

  /// The reasoningEffort public API member.
  final String reasoningEffort;

  /// Provider service tier for this request; null uses the provider default.
  final String? serviceTier;

  /// The instructions public API member.
  final String instructions;

  /// The history public API member.
  final List<ConversationItem> history;

  /// The tools public API member.
  final List<ModelToolDefinition> tools;

  /// The safetyIdentifier public API member.
  final String safetyIdentifier;

  /// The forceToolName public API member.
  final String? forceToolName;
}

/// ModelEvent defines a public contract.
sealed class ModelEvent {
  const ModelEvent();
}

/// ModelTextDelta defines a public contract.
class ModelTextDelta extends ModelEvent {
  /// Creates a [ModelTextDelta].
  const ModelTextDelta(this.delta);

  /// The delta public API member.
  final String delta;
}

/// ModelFunctionCall defines a public contract.
class ModelFunctionCall extends ModelEvent {
  /// Creates a [ModelFunctionCall].
  const ModelFunctionCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  /// The callId public API member.
  final String callId;

  /// The name public API member.
  final String name;

  /// The arguments public API member.
  final Map<String, dynamic> arguments;
}

/// ModelResponseCompleted defines a public contract.
class ModelResponseCompleted extends ModelEvent {
  /// Creates a [ModelResponseCompleted].
  const ModelResponseCompleted({
    required this.assistant,
    this.usage = const ModelUsage(),
  });

  /// The assistant public API member.
  final AssistantConversationItem assistant;

  /// Token counters the provider reported, normalized across APIs.
  final ModelUsage usage;
}

/// Public API exposed by this library.
abstract interface class ModelProvider {
  /// The id public API member.
  String get id;

  /// The stream public API member.
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  );
}

/// ToolInvocation defines a public contract.
class ToolInvocation {
  /// Creates a [ToolInvocation].
  const ToolInvocation({
    required this.callId,
    required this.name,
    required this.arguments,
    required this.risk,
    required this.workspaceRoot,
    this.preview,
  });

  /// The callId public API member.
  final String callId;

  /// The name public API member.
  final String name;

  /// The arguments public API member.
  final Map<String, dynamic> arguments;

  /// The risk public API member.
  final ToolRisk risk;

  /// The workspaceRoot public API member.
  final String workspaceRoot;

  /// The preview public API member.
  final String? preview;
}

/// Values supported by ApprovalEvaluation.
enum ApprovalEvaluation {
  /// Runs the tool without asking.
  allow,

  /// Requires an explicit approval decision.
  ask,

  /// Rejects the tool invocation.
  deny,
}

/// Values supported by ApprovalDecision.
enum ApprovalDecision {
  /// The invocation may proceed.
  approved,

  /// The invocation must not proceed.
  denied,
}

/// Public API exposed by this library.
abstract interface class ApprovalPolicy {
  /// Decides whether [invocation] may run, must be asked about, or is denied.
  ///
  /// Takes the whole invocation rather than its risk so a policy can reason
  /// about which tool is being called and with what — an interactive shell
  /// session, for instance, is approved once rather than per keystroke.
  ApprovalEvaluation evaluate(ToolInvocation invocation);
}

/// DefaultApprovalPolicy defines a public contract.
class DefaultApprovalPolicy implements ApprovalPolicy {
  /// Creates a [DefaultApprovalPolicy].
  const DefaultApprovalPolicy(this.mode);

  /// The mode public API member.
  final PermissionMode mode;

  @override
  ApprovalEvaluation evaluate(ToolInvocation invocation) =>
      evaluateRisk(invocation.risk);

  /// Decides from a bare risk, ignoring which tool raised it.
  ApprovalEvaluation evaluateRisk(ToolRisk risk) => switch ((mode, risk)) {
    (PermissionMode.fullAccess, _) => ApprovalEvaluation.allow,
    (_, ToolRisk.read) => ApprovalEvaluation.allow,
    (PermissionMode.readOnly, _) => ApprovalEvaluation.deny,
    (PermissionMode.workspaceWrite, ToolRisk.write) => ApprovalEvaluation.allow,
    _ => ApprovalEvaluation.ask,
  };
}

/// Public API exposed by this library.
abstract interface class ApprovalCoordinator {
  /// The request public API member.
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  );
}

/// One fixed choice the agent offered for a [UserQuestion].
class UserQuestionOption {
  /// Creates a [UserQuestionOption].
  const UserQuestionOption({required this.label, required this.description});

  /// The short choice shown on the control.
  final String label;

  /// What choosing this option means.
  final String description;
}

/// One multiple-choice question the agent asked the user.
///
/// [options] holds only what the agent wrote. The host always offers a
/// free-form answer beside them, so the agent never authors an "other" choice.
class UserQuestion {
  /// Creates a [UserQuestion].
  const UserQuestion({
    required this.id,
    required this.header,
    required this.question,
    required this.options,
  });

  /// Identifier the answer is keyed by; unique within one ask.
  final String id;

  /// A very short label for the question, bounded by the tool that raises it.
  final String header;

  /// The question itself.
  final String question;

  /// The offered choices.
  final List<UserQuestionOption> options;
}

/// The user's answer to one [UserQuestion].
class UserAnswer {
  /// Creates a [UserAnswer].
  const UserAnswer({
    required this.questionId,
    required this.answer,
    required this.isFreeForm,
  });

  /// The [UserQuestion.id] this answers.
  final String questionId;

  /// The chosen label, or the text the user typed when [isFreeForm].
  final String answer;

  /// Whether the user typed the answer instead of choosing an option.
  final bool isFreeForm;
}

/// Blocks a turn on a structured question and returns the user's answers.
///
/// Deliberately separate from [ApprovalCoordinator]: an approval is a binary
/// gate the runtime applies from a tool's risk, while a question is raised by a
/// tool body, returns structured content, and must work under every
/// [PermissionMode].
abstract interface class UserQuestionCoordinator {
  /// Asks [questions] for the tool call [callId] and completes once answered.
  Future<List<UserAnswer>> ask(
    String callId,
    List<UserQuestion> questions,
    CancellationToken cancellation,
  );
}

/// Discards the persisted conversation and starts a fresh context window.
///
/// The retained items are re-appended under a new epoch so the database and
/// the runner's in-memory conversation cannot drift apart.
abstract interface class ContextResetCoordinator {
  /// Keeps only [retain], under a new context epoch.
  Future<void> reset(List<ConversationItem> retain);
}

/// ToolExecutionContext defines a public contract.
class ToolExecutionContext {
  /// Creates a [ToolExecutionContext].
  const ToolExecutionContext({
    required this.workspaceRoot,
    required this.cancellation,
    this.callId = '',
    this.contextWindowTokens,
    this.turnUsage = const ModelUsage(),
    this.requestContextReset = _ignoreContextReset,
  });

  /// The workspaceRoot public API member.
  final String workspaceRoot;

  /// The cancellation public API member.
  final CancellationToken cancellation;

  /// Provider-assigned identifier of the call being executed.
  ///
  /// A tool that raises host state of its own — a question the user must
  /// answer, for instance — keys that state by this so the client can tie it
  /// back to the call that produced it.
  final String callId;

  /// Tokens this model's context window holds, when the provider reports one.
  final int? contextWindowTokens;

  /// What the last response in this turn consumed.
  final ModelUsage turnUsage;

  /// Asks the runner to start a fresh context window after this round.
  ///
  /// Deliberately deferred: resetting inside the tool would strand any call
  /// that follows it in the same round.
  final void Function() requestContextReset;
}

void _ignoreContextReset() {}

/// ToolResult defines a public contract.
class ToolResult {
  /// Creates a [ToolResult].
  const ToolResult({
    required this.output,
    this.isError = false,
    this.attachments = const <ConversationAttachment>[],
    this.contextImages = const <ConversationAttachment>[],
  });

  /// The output public API member.
  final String output;

  /// The isError public API member.
  final bool isError;

  /// Files explicitly published by the tool for the user.
  final List<ConversationAttachment> attachments;

  /// Images the tool put into the model's context.
  ///
  /// Neither the Responses nor the Chat Completions API accepts image content
  /// inside a tool result, so the runner appends these as a follow-up user
  /// item instead of trying to embed them in [output].
  final List<ConversationAttachment> contextImages;
}

/// AgentTool defines a public contract.
abstract class AgentTool {
  /// The name public API member.
  String get name;

  /// The description public API member.
  String get description;

  /// The risk public API member.
  ToolRisk get risk;

  /// The strictJsonSchema public API member.
  Map<String, dynamic> get strictJsonSchema;

  /// Whether [strictJsonSchema] satisfies provider strict-schema requirements.
  ///
  /// Tools that pass through a schema authored elsewhere — an external MCP
  /// server, for instance — cannot guarantee that every property is required
  /// and that every object forbids additional properties, so they opt out.
  bool get strict => true;

  /// Whether the model is told about this tool up front.
  ///
  /// A deferred tool stays dispatchable; only its advertisement is withheld
  /// until [ToolSearchTool] surfaces it.
  ToolExposure get exposure => ToolExposure.advertised;

  /// The preview public API member.
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => null;

  /// The execute public API member.
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  );
}
