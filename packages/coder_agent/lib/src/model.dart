import 'dart:async';

import 'package:coder_protocol/coder_protocol.dart';

class CancellationToken {
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;
  final List<void Function()> _listeners = <void Function()>[];

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void throwIfCancelled() {
    if (_isCancelled) throw const AgentCancelledException();
  }
}

class AgentCancelledException implements Exception {
  const AgentCancelledException();
}

class ModelToolDefinition {
  const ModelToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, dynamic> parameters;
}

class ConversationToolCall {
  const ConversationToolCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  factory ConversationToolCall.fromJson(Map<String, dynamic> json) =>
      ConversationToolCall(
        callId: json['callId']! as String,
        name: json['name']! as String,
        arguments: Map<String, dynamic>.from(json['arguments']! as Map),
      );

  final String callId;
  final String name;
  final Map<String, dynamic> arguments;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'callId': callId,
    'name': name,
    'arguments': arguments,
  };
}

sealed class ConversationItem {
  const ConversationItem();

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'user' => UserConversationItem(json['text']! as String),
      'assistant' => AssistantConversationItem(
        text: json['text'] as String? ?? '',
        toolCalls: (json['toolCalls'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) => ConversationToolCall.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false),
        opaqueItems: (json['opaqueItems'] as List? ?? const <dynamic>[])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
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

  Map<String, dynamic> toJson();
}

class UserConversationItem extends ConversationItem {
  const UserConversationItem(this.text);
  final String text;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'user',
    'text': text,
  };
}

class AssistantConversationItem extends ConversationItem {
  const AssistantConversationItem({
    required this.text,
    this.toolCalls = const <ConversationToolCall>[],
    this.opaqueItems = const <Map<String, dynamic>>[],
  });

  final String text;
  final List<ConversationToolCall> toolCalls;
  final List<Map<String, dynamic>> opaqueItems;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'assistant',
    'text': text,
    'toolCalls': toolCalls.map((item) => item.toJson()).toList(),
    'opaqueItems': opaqueItems,
  };
}

class ToolResultConversationItem extends ConversationItem {
  const ToolResultConversationItem({
    required this.callId,
    required this.output,
    this.isError = false,
  });

  final String callId;
  final String output;
  final bool isError;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'toolResult',
    'callId': callId,
    'output': output,
    'isError': isError,
  };
}

class ModelRequest {
  const ModelRequest({
    required this.model,
    required this.reasoningEffort,
    required this.instructions,
    required this.history,
    required this.tools,
    required this.safetyIdentifier,
    this.forceToolName,
  });

  final String model;
  final String reasoningEffort;
  final String instructions;
  final List<ConversationItem> history;
  final List<ModelToolDefinition> tools;
  final String safetyIdentifier;
  final String? forceToolName;
}

sealed class ModelEvent {
  const ModelEvent();
}

class ModelTextDelta extends ModelEvent {
  const ModelTextDelta(this.delta);
  final String delta;
}

class ModelFunctionCall extends ModelEvent {
  const ModelFunctionCall({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  final String callId;
  final String name;
  final Map<String, dynamic> arguments;
}

class ModelResponseCompleted extends ModelEvent {
  const ModelResponseCompleted({
    required this.assistant,
    this.usage = const <String, int>{},
  });

  final AssistantConversationItem assistant;
  final Map<String, int> usage;
}

abstract interface class ModelProvider {
  String get id;
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  );
}

class ToolInvocation {
  const ToolInvocation({
    required this.callId,
    required this.name,
    required this.arguments,
    required this.risk,
    required this.workspaceRoot,
    this.preview,
  });

  final String callId;
  final String name;
  final Map<String, dynamic> arguments;
  final ToolRisk risk;
  final String workspaceRoot;
  final String? preview;
}

enum ApprovalEvaluation { allow, ask, deny }

enum ApprovalDecision { approved, denied }

abstract interface class ApprovalPolicy {
  ApprovalEvaluation evaluate(ToolRisk risk);
}

class DefaultApprovalPolicy implements ApprovalPolicy {
  const DefaultApprovalPolicy(this.mode);

  final PermissionMode mode;

  @override
  ApprovalEvaluation evaluate(ToolRisk risk) => switch ((mode, risk)) {
    (_, ToolRisk.read) => ApprovalEvaluation.allow,
    (PermissionMode.readOnly, _) => ApprovalEvaluation.deny,
    (PermissionMode.workspaceWrite, ToolRisk.write) => ApprovalEvaluation.allow,
    _ => ApprovalEvaluation.ask,
  };
}

abstract interface class ApprovalCoordinator {
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  );
}

class ToolExecutionContext {
  const ToolExecutionContext({
    required this.workspaceRoot,
    required this.cancellation,
  });

  final String workspaceRoot;
  final CancellationToken cancellation;
}

class ToolResult {
  const ToolResult({required this.output, this.isError = false});

  final String output;
  final bool isError;
}

abstract class AgentTool {
  String get name;
  String get description;
  ToolRisk get risk;
  Map<String, dynamic> get strictJsonSchema;

  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => null;

  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  );
}
