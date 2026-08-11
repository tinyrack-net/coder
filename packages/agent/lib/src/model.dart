import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/tools/tool_search.dart';
import 'package:agent/src/usage.dart';

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

/// Wire-level kind of a model-facing tool.
enum ModelToolKind {
  /// A JSON-schema function.
  function,

  /// A raw-input custom tool.
  freeform,

  /// A group of related functions.
  namespace,

  /// Provider-native deferred tool discovery.
  deferredSearch,
}

/// Provider-neutral model-facing tool declaration.
sealed class ModelToolDefinition {
  const ModelToolDefinition({
    required this.name,
    required this.description,
    this.supportsParallelToolCalls = false,
  });

  /// The name public API member.
  final String name;

  /// The description public API member.
  final String description;

  /// Wire-level tool kind.
  ModelToolKind get kind;

  /// Whether calls to this tool may run concurrently with sibling calls.
  final bool supportsParallelToolCalls;
}

/// A strict or provider-owned JSON function tool.
final class ModelFunctionToolDefinition extends ModelToolDefinition {
  /// Creates a function definition.
  const ModelFunctionToolDefinition({
    required super.name,
    required super.description,
    required this.parameters,
    this.outputSchema,
    this.strict = true,
    super.supportsParallelToolCalls,
  });

  @override
  ModelToolKind get kind => ModelToolKind.function;

  /// JSON schema accepted by the function.
  final Map<String, dynamic> parameters;

  /// Optional JSON schema produced by the function.
  final Map<String, dynamic>? outputSchema;

  /// Whether [parameters] satisfies provider strict-schema requirements.
  final bool strict;
}

/// A provider grammar declaration for freeform input.
final class ModelFreeformToolFormat {
  /// Creates a freeform grammar declaration.
  const ModelFreeformToolFormat({
    required this.type,
    required this.syntax,
    required this.definition,
  });

  /// Provider format kind, normally `grammar`.
  final String type;

  /// Grammar syntax, normally `lark`.
  final String syntax;

  /// Grammar source.
  final String definition;
}

/// A tool whose model input is raw source rather than a JSON object.
final class ModelFreeformToolDefinition extends ModelToolDefinition {
  /// Creates a freeform definition.
  const ModelFreeformToolDefinition({
    required super.name,
    required super.description,
    this.format,
    super.supportsParallelToolCalls,
  });

  @override
  ModelToolKind get kind => ModelToolKind.freeform;

  /// Optional provider grammar.
  final ModelFreeformToolFormat? format;
}

/// One function nested in a provider namespace.
final class ModelNamespaceToolDefinition extends ModelToolDefinition {
  /// Creates a namespace definition.
  const ModelNamespaceToolDefinition({
    required super.name,
    required super.description,
    required this.tools,
  });

  @override
  ModelToolKind get kind => ModelToolKind.namespace;

  /// Functions belonging to the namespace.
  final List<ModelFunctionToolDefinition> tools;
}

/// Provider-native BM25 discovery over deferred tool metadata.
final class ModelDeferredSearchToolDefinition extends ModelToolDefinition {
  /// Creates a deferred search declaration.
  const ModelDeferredSearchToolDefinition({
    required super.description,
    required this.parameters,
    this.execution = 'client',
  }) : super(name: 'tool_search');

  @override
  ModelToolKind get kind => ModelToolKind.deferredSearch;

  /// Where matching and loading are performed.
  final String execution;

  /// Query and result-limit schema.
  final Map<String, dynamic> parameters;
}

/// Typed input persisted for a tool call.
sealed class ToolCallInput {
  const ToolCallInput();

  /// Decodes modern persisted input.
  factory ToolCallInput.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'json' => JsonToolCallInput(
          Map<String, dynamic>.from(json['value']! as Map),
        ),
        'freeform' => FreeformToolCallInput(json['value']! as String),
        _ => throw FormatException('Unknown tool input: ${json['type']}'),
      };

  /// Encodes this input without legacy argument aliases.
  Map<String, dynamic> toJson();
}

/// JSON object input of a function tool.
final class JsonToolCallInput extends ToolCallInput {
  /// Creates JSON input.
  const JsonToolCallInput(this.value);

  /// Decoded JSON arguments.
  final Map<String, dynamic> value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'json',
    'value': value,
  };
}

/// Raw source input of a freeform tool.
final class FreeformToolCallInput extends ToolCallInput {
  /// Creates freeform input.
  const FreeformToolCallInput(this.value);

  /// Unmodified model source.
  final String value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'freeform',
    'value': value,
  };
}

/// ConversationToolCall defines a public contract.
class ConversationToolCall {
  /// Creates a [ConversationToolCall].
  const ConversationToolCall.function({
    required this.callId,
    required this.name,
    required Map<String, dynamic> arguments,
    this.namespace,
  }) : _jsonInput = arguments,
       _freeformInput = null,
       kind = ModelToolKind.function;

  /// Creates a provider-native deferred-search call.
  const ConversationToolCall.deferredSearch({
    required this.callId,
    required Map<String, dynamic> arguments,
  }) : name = 'tool_search',
       namespace = null,
       _jsonInput = arguments,
       _freeformInput = null,
       kind = ModelToolKind.deferredSearch;

  /// Creates a raw freeform call.
  const ConversationToolCall.freeform({
    required this.callId,
    required this.name,
    required String input,
    this.namespace,
  }) : _jsonInput = null,
       _freeformInput = input,
       kind = ModelToolKind.freeform;

  ConversationToolCall._({
    required this.callId,
    required this.name,
    required ToolCallInput input,
    required this.kind,
    this.namespace,
  }) : _jsonInput = input is JsonToolCallInput ? input.value : null,
       _freeformInput = input is FreeformToolCallInput ? input.value : null;

  /// Creates a [ConversationToolCall].
  factory ConversationToolCall.fromJson(Map<String, dynamic> json) =>
      ConversationToolCall._(
        callId: json['callId']! as String,
        name: json['name']! as String,
        namespace: json['namespace'] as String?,
        kind: ModelToolKind.values.byName(json['kind']! as String),
        input: ToolCallInput.fromJson(
          Map<String, dynamic>.from(json['input']! as Map),
        ),
      );

  /// The callId public API member.
  final String callId;

  /// The name public API member.
  final String name;

  /// Responses API namespace that owns this tool, when present.
  final String? namespace;

  /// Wire kind that emitted this call.
  final ModelToolKind kind;

  final Map<String, dynamic>? _jsonInput;
  final String? _freeformInput;

  /// Typed call input.
  ToolCallInput get input => switch ((_jsonInput, _freeformInput)) {
    (final value?, null) => JsonToolCallInput(value),
    (null, final value?) => FreeformToolCallInput(value),
    _ => throw StateError('Tool call has no input.'),
  };

  /// The toJson public API member.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'callId': callId,
    'name': name,
    if (namespace != null) 'namespace': namespace,
    'kind': kind.name,
    'input': input.toJson(),
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
        toolKind: ModelToolKind.values.byName(json['toolKind']! as String),
        isError: json['isError'] == true,
        content: (json['content'] as List? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (item) => ToolContent.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
        structuredContent: json['structuredContent'],
        meta: json['meta'] is Map
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : const <String, dynamic>{},
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
            : AgentAttachmentKind.values.byName(json['kind']! as String),
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
  final AgentAttachmentKind? kind;

  /// Content digest from the daemon metadata snapshot.
  final String? sha256;

  /// Upload completion time from the daemon metadata snapshot.
  final DateTime? createdAt;

  /// Fidelity a provider should read this image at: `high` or `original`.
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
    required this.toolKind,
    this.isError = false,
    this.content = const <ToolContent>[],
    this.structuredContent,
    this.meta = const <String, dynamic>{},
  });

  /// The callId public API member.
  final String callId;

  /// The output public API member.
  final String output;

  /// Kind of call this result completes.
  final ModelToolKind toolKind;

  /// The isError public API member.
  final bool isError;

  /// Ordered multimodal content carried by the result.
  final List<ToolContent> content;

  /// Provider-owned structured payload.
  final Object? structuredContent;

  /// Provider metadata retained with the result.
  final Map<String, dynamic> meta;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'toolResult',
    'callId': callId,
    'output': output,
    'toolKind': toolKind.name,
    'isError': isError,
    if (content.isNotEmpty)
      'content': content.map((item) => item.toJson()).toList(),
    if (structuredContent != null) 'structuredContent': structuredContent,
    if (meta.isNotEmpty) 'meta': meta,
  };
}

/// ModelRequest defines a public contract.
class ModelRequest {
  /// Creates a [ModelRequest].
  const ModelRequest({
    required this.model,
    required this.instructions,
    required this.history,
    required this.tools,
    required this.safetyIdentifier,
    this.modelControls = const <String, AgentModelControlValue>{},
    this.forceToolName,
  });

  /// The model public API member.
  final String model;

  /// Model-specific values validated against the resolved provider catalog.
  final Map<String, AgentModelControlValue> modelControls;

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

/// Display-safe reasoning text emitted by a provider.
///
/// Providers must only surface plaintext reasoning or a provider-authored
/// summary here. Encrypted, signed, or redacted continuation data belongs in
/// [AssistantConversationItem.opaqueItems] instead.
class ModelReasoningDelta extends ModelEvent {
  /// Creates a reasoning text delta.
  const ModelReasoningDelta(this.delta);

  /// The next visible fragment of reasoning text.
  final String delta;
}

/// A typed tool call emitted by a model provider.
sealed class ModelToolCall extends ModelEvent {
  const ModelToolCall({
    required this.callId,
    required this.name,
    this.namespace,
  });

  /// Provider call identifier.
  final String callId;

  /// Canonical tool name.
  final String name;

  /// Provider namespace that qualified this call, when present.
  final String? namespace;

  /// Typed call input.
  ToolCallInput get input;
}

/// ModelFunctionCall defines a public contract.
class ModelFunctionCall extends ModelToolCall {
  /// Creates a [ModelFunctionCall].
  const ModelFunctionCall({
    required super.callId,
    required super.name,
    required this.arguments,
    super.namespace,
  });

  /// The arguments public API member.
  final Map<String, dynamic> arguments;

  @override
  ToolCallInput get input => JsonToolCallInput(arguments);
}

/// A raw custom-tool call emitted by a model provider.
final class ModelFreeformCall extends ModelToolCall {
  /// Creates a freeform call.
  const ModelFreeformCall({
    required super.callId,
    required super.name,
    required this.rawInput,
  });

  /// Unmodified provider source.
  final String rawInput;

  @override
  ToolCallInput get input => FreeformToolCallInput(rawInput);
}

/// A provider-native deferred-search call.
final class ModelDeferredSearchCall extends ModelToolCall {
  /// Creates a client-executed search call.
  const ModelDeferredSearchCall({
    required super.callId,
    required this.arguments,
  }) : super(name: 'tool_search');

  /// Search query and optional result limit.
  final Map<String, dynamic> arguments;

  @override
  ToolCallInput get input => JsonToolCallInput(arguments);
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
  final AgentToolRisk risk;

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
  final AgentPermissionMode mode;

  @override
  ApprovalEvaluation evaluate(ToolInvocation invocation) =>
      evaluateRisk(invocation.risk);

  /// Decides from a bare risk, ignoring which tool raised it.
  ApprovalEvaluation evaluateRisk(AgentToolRisk risk) => switch ((mode, risk)) {
    (AgentPermissionMode.fullAccess, _) => ApprovalEvaluation.allow,
    (_, AgentToolRisk.read) => ApprovalEvaluation.allow,
    (AgentPermissionMode.readOnly, _) => ApprovalEvaluation.deny,
    (AgentPermissionMode.workspaceWrite, AgentToolRisk.write) =>
      ApprovalEvaluation.allow,
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
/// [AgentPermissionMode].
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

/// Invokes a tool intentionally hidden behind an orchestration surface.
abstract interface class NestedToolInvoker {
  /// Runs [name] through the turn's normal approval and cancellation path.
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  );
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
    this.nestedTools,
    this.sessionMode = AgentSessionMode.normal,
    this.toolSurfaceMode = AgentToolSurfaceMode.direct,
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

  /// Dispatcher for tools hidden behind the current orchestration surface.
  final NestedToolInvoker? nestedTools;

  /// Collaboration mode of the owning session.
  final AgentSessionMode sessionMode;

  /// Model-facing tool surface executing this call.
  final AgentToolSurfaceMode toolSurfaceMode;

  /// Invokes one nested tool.
  Future<ToolResult> invokeNestedTool(
    String name,
    Map<String, dynamic> arguments,
  ) {
    final invoker = nestedTools;
    if (invoker == null) {
      throw StateError('Nested tool invocation is unavailable.');
    }
    return invoker.invoke(name, arguments);
  }
}

void _ignoreContextReset() {}

/// One provider-neutral content block returned by a tool.
sealed class ToolContent {
  const ToolContent();

  /// Restores one persisted content block.
  factory ToolContent.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'text' => ToolTextContent(
          json['text']! as String,
          annotations: _contentMap(json['annotations']),
          meta: _contentMap(json['_meta']),
        ),
        'image' => ToolImageContent(
          imageUrl: json['image_url']! as String,
          detail: json['detail'] as String?,
          annotations: _contentMap(json['annotations']),
          meta: _contentMap(json['_meta']),
        ),
        'audio' => ToolAudioContent(
          audioUrl: json['audio_url']! as String,
          annotations: _contentMap(json['annotations']),
          meta: _contentMap(json['_meta']),
        ),
        'resource' => ToolEmbeddedResourceContent(
          uri: json['uri']! as String,
          mimeType: json['mimeType'] as String?,
          text: json['text'] as String?,
          blob: json['blob'] as String?,
          meta: json['_meta'] is Map
              ? Map<String, dynamic>.from(json['_meta'] as Map)
              : const <String, dynamic>{},
          annotations: _contentMap(json['annotations']),
        ),
        'resource_link' => ToolResourceLinkContent(
          name: json['name']! as String,
          uri: json['uri']! as String,
          title: json['title'] as String?,
          description: json['description'] as String?,
          mimeType: json['mimeType'] as String?,
          size: json['size'] as int?,
          meta: json['_meta'] is Map
              ? Map<String, dynamic>.from(json['_meta'] as Map)
              : const <String, dynamic>{},
          annotations: _contentMap(json['annotations']),
        ),
        _ => throw FormatException('Unknown tool content: ${json['type']}'),
      };

  /// Durable MCP-compatible representation.
  Map<String, dynamic> toJson();
}

/// Text returned by a tool.
final class ToolTextContent extends ToolContent {
  /// Creates text content.
  const ToolTextContent(
    this.text, {
    this.annotations = const <String, dynamic>{},
    this.meta = const <String, dynamic>{},
  });

  /// Text value.
  final String text;

  /// MCP annotations retained from the content block.
  final Map<String, dynamic> annotations;

  /// MCP metadata retained from the content block.
  final Map<String, dynamic> meta;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'text',
    'text': text,
    if (annotations.isNotEmpty) 'annotations': annotations,
    if (meta.isNotEmpty) '_meta': meta,
  };
}

/// Image returned by a tool.
final class ToolImageContent extends ToolContent {
  /// Creates image content.
  const ToolImageContent({
    required this.imageUrl,
    this.detail,
    this.annotations = const <String, dynamic>{},
    this.meta = const <String, dynamic>{},
  });

  /// Data URL or provider-supported image URL.
  final String imageUrl;

  /// Requested fidelity.
  final String? detail;

  /// MCP annotations retained from the content block.
  final Map<String, dynamic> annotations;

  /// MCP metadata retained from the content block.
  final Map<String, dynamic> meta;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'image',
    'image_url': imageUrl,
    if (detail != null) 'detail': detail,
    if (annotations.isNotEmpty) 'annotations': annotations,
    if (meta.isNotEmpty) '_meta': meta,
  };
}

/// Audio returned by a tool.
final class ToolAudioContent extends ToolContent {
  /// Creates audio content.
  const ToolAudioContent({
    required this.audioUrl,
    this.annotations = const <String, dynamic>{},
    this.meta = const <String, dynamic>{},
  });

  /// Data URL or provider-supported audio URL.
  final String audioUrl;

  /// MCP annotations retained from the content block.
  final Map<String, dynamic> annotations;

  /// MCP metadata retained from the content block.
  final Map<String, dynamic> meta;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'audio',
    'audio_url': audioUrl,
    if (annotations.isNotEmpty) 'annotations': annotations,
    if (meta.isNotEmpty) '_meta': meta,
  };
}

/// An embedded text or binary resource returned by a tool.
final class ToolEmbeddedResourceContent extends ToolContent {
  /// Creates an embedded resource.
  const ToolEmbeddedResourceContent({
    required this.uri,
    this.mimeType,
    this.text,
    this.blob,
    this.meta = const <String, dynamic>{},
    this.annotations = const <String, dynamic>{},
  });

  /// Resource URI.
  final String uri;

  /// Optional MIME type.
  final String? mimeType;

  /// Inline text body.
  final String? text;

  /// Inline base64 body.
  final String? blob;

  /// Provider metadata.
  final Map<String, dynamic> meta;

  /// MCP annotations retained from the content block.
  final Map<String, dynamic> annotations;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'resource',
    'uri': uri,
    if (mimeType != null) 'mimeType': mimeType,
    if (text != null) 'text': text,
    if (blob != null) 'blob': blob,
    if (meta.isNotEmpty) '_meta': meta,
    if (annotations.isNotEmpty) 'annotations': annotations,
  };
}

/// An MCP-style resource link returned by a tool.
final class ToolResourceLinkContent extends ToolContent {
  /// Creates a resource link.
  const ToolResourceLinkContent({
    required this.name,
    required this.uri,
    this.title,
    this.description,
    this.mimeType,
    this.size,
    this.meta = const <String, dynamic>{},
    this.annotations = const <String, dynamic>{},
  });

  /// Machine-readable resource name.
  final String name;

  /// Resource URI.
  final String uri;

  /// Optional display title.
  final String? title;

  /// Optional description.
  final String? description;

  /// Optional MIME type.
  final String? mimeType;

  /// Optional byte size.
  final int? size;

  /// Provider metadata.
  final Map<String, dynamic> meta;

  /// MCP annotations retained from the content block.
  final Map<String, dynamic> annotations;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'resource_link',
    'name': name,
    'uri': uri,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (mimeType != null) 'mimeType': mimeType,
    if (size != null) 'size': size,
    if (meta.isNotEmpty) '_meta': meta,
    if (annotations.isNotEmpty) 'annotations': annotations,
  };
}

Map<String, dynamic> _contentMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

/// ToolResult defines a public contract.
class ToolResult {
  /// Creates a [ToolResult].
  const ToolResult({
    required this.value,
    this.isError = false,
    this.content = const <ToolContent>[],
    this.structuredContent,
    this.meta = const <String, dynamic>{},
    this.attachments = const <ConversationAttachment>[],
    this.contextImages = const <ConversationAttachment>[],
    this.notifications = const <Object?>[],
  });

  /// Provider-neutral scalar or structured return value.
  final Object? value;

  /// String representation used by providers that accept text-only output.
  String get output => value is String ? value! as String : jsonEncode(value);

  /// The isError public API member.
  final bool isError;

  /// Ordered rich content returned by this tool.
  final List<ToolContent> content;

  /// Provider-owned structured result, such as MCP `structuredContent`.
  final Object? structuredContent;

  /// Provider-owned metadata.
  final Map<String, dynamic> meta;

  /// Files explicitly published by the tool for the user.
  final List<ConversationAttachment> attachments;

  /// Images the tool put into the model's context.
  ///
  /// Neither the Responses nor the Chat Completions API accepts image content
  /// inside a tool result, so the runner appends these as a follow-up user
  /// item instead of trying to embed them in [output].
  final List<ConversationAttachment> contextImages;

  /// Values emitted through an immediate side channel while the tool ran.
  final List<Object?> notifications;
}

/// AgentTool defines a public contract.
abstract class AgentTool {
  /// The name public API member.
  String get name;

  /// The description public API member.
  String get description;

  /// The risk public API member.
  AgentToolRisk get risk;

  /// The strictJsonSchema public API member.
  Map<String, dynamic> get strictJsonSchema;

  /// Whether [strictJsonSchema] satisfies provider strict-schema requirements.
  ///
  /// Tools that pass through a schema authored elsewhere — an external MCP
  /// server, for instance — cannot guarantee that every property is required
  /// and that every object forbids additional properties, so they opt out.
  bool get strict => true;

  /// Provider-neutral declaration exposed to the model.
  ModelToolDefinition get modelSpec => ModelFunctionToolDefinition(
    name: name,
    description: description,
    parameters: strictJsonSchema,
    strict: strict,
  );

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

  /// Builds an approval preview for raw freeform input.
  Future<String?> previewFreeform(
    String input,
    ToolExecutionContext context,
  ) async => null;

  /// The execute public API member.
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  );

  /// Executes raw freeform input when this tool declares a freeform spec.
  Future<ToolResult> executeFreeform(
    String input,
    ToolExecutionContext context,
  ) => throw StateError('$name does not accept freeform input.');
}
