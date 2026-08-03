import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/plan_mode_prompt.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by AgentEventCallback.
typedef AgentEventCallback =
    FutureOr<void> Function(String type, Map<String, dynamic> data);

/// Signature used by SessionStatusCallback.
typedef SessionStatusCallback =
    FutureOr<void> Function(SessionStatus status, {String? error});

/// Signature used by ProviderItemsCallback.
typedef ProviderItemsCallback =
    FutureOr<void> Function(List<ConversationItem> items);

/// AgentRunRequest defines a public contract.
class AgentRunRequest {
  /// Creates a [AgentRunRequest].
  const AgentRunRequest({
    required this.sessionId,
    required this.turnId,
    required this.workspaceRoot,
    required this.prompt,
    required this.model,
    required this.permissionMode,
    required this.history,
    required this.safetyIdentifier,
    this.reasoningEffort = 'medium',
    this.maxToolRounds = 64,
    this.sessionMode = SessionMode.normal,
    this.customSystemPrompt,
  });

  /// The sessionId public API member.
  final String sessionId;

  /// The turnId public API member.
  final String turnId;

  /// The workspaceRoot public API member.
  final String workspaceRoot;

  /// The prompt public API member.
  final String prompt;

  /// The model public API member.
  final String model;

  /// The reasoningEffort public API member.
  final String reasoningEffort;

  /// The permissionMode public API member.
  final PermissionMode permissionMode;

  /// The history public API member.
  final List<ConversationItem> history;

  /// The safetyIdentifier public API member.
  final String safetyIdentifier;

  /// The maxToolRounds public API member.
  final int maxToolRounds;

  /// Collaboration mode of the owning session.
  final SessionMode sessionMode;

  /// Optional Markdown agent prompt appended after immutable safety rules.
  final String? customSystemPrompt;
}

/// AgentRunResult defines a public contract.
class AgentRunResult {
  /// Creates a [AgentRunResult].
  const AgentRunResult({
    required this.conversationItems,
    required this.toolRounds,
  });

  /// The conversationItems public API member.
  final List<ConversationItem> conversationItems;

  /// The toolRounds public API member.
  final int toolRounds;
}

/// AgentRunner defines a public contract.
class AgentRunner {
  /// Creates a [AgentRunner].
  AgentRunner({
    required this._provider,
    required Iterable<AgentTool> tools,
    required this._approvals,
    required this._onEvent,
    required this._onStatus,
    required this._onProviderItems,
  }) : _tools = <String, AgentTool>{for (final tool in tools) tool.name: tool};

  final ModelProvider _provider;
  final Map<String, AgentTool> _tools;
  final ApprovalCoordinator _approvals;
  final AgentEventCallback _onEvent;
  final SessionStatusCallback _onStatus;
  final ProviderItemsCallback _onProviderItems;

  /// The startTurn public API member.
  Future<AgentRunResult> startTurn(
    AgentRunRequest request,
    CancellationToken cancellation,
  ) async {
    final userItem = UserConversationItem(request.prompt);
    final input = <ConversationItem>[...request.history, userItem];
    final persisted = <ConversationItem>[userItem];
    var toolRounds = 0;
    await _onStatus(SessionStatus.running);
    await _onEvent('user.message', <String, dynamic>{'text': request.prompt});
    await _onProviderItems(<ConversationItem>[userItem]);

    try {
      while (true) {
        cancellation.throwIfCancelled();

        final functionCalls = <ModelFunctionCall>[];
        ModelResponseCompleted? completed;
        final modelRequest = ModelRequest(
          model: request.model,
          reasoningEffort: request.reasoningEffort,
          instructions: _instructions(request),
          history: input,
          safetyIdentifier: request.safetyIdentifier,
          tools: _tools.values
              .map(
                (tool) => ModelToolDefinition(
                  name: tool.name,
                  description: tool.description,
                  parameters: tool.strictJsonSchema,
                ),
              )
              .toList(growable: false),
        );

        await for (final event in _provider.stream(
          modelRequest,
          cancellation,
        )) {
          switch (event) {
            case ModelTextDelta(:final delta):
              await _onEvent('assistant.delta', <String, dynamic>{
                'text': delta,
              });
            case ModelFunctionCall():
              functionCalls.add(event);
              await _onEvent('tool.requested', <String, dynamic>{
                'callId': event.callId,
                'name': event.name,
                'arguments': event.arguments,
              });
            case ModelResponseCompleted():
              completed = event;
          }
        }

        if (completed == null) {
          throw StateError('Model stream ended without response.completed.');
        }
        final assistant = completed.assistant;
        input.add(assistant);
        persisted.add(assistant);
        await _onProviderItems(<ConversationItem>[assistant]);
        await _onEvent('model.usage', <String, dynamic>{...completed.usage});

        if (functionCalls.isEmpty) {
          await _onEvent('turn.completed', <String, dynamic>{
            'toolRounds': toolRounds,
          });
          await _onStatus(SessionStatus.idle);
          return AgentRunResult(
            conversationItems: persisted,
            toolRounds: toolRounds,
          );
        }

        if (toolRounds >= request.maxToolRounds) {
          throw StateError(
            'Tool round limit (${request.maxToolRounds}) exceeded.',
          );
        }
        toolRounds += 1;
        for (final call in functionCalls) {
          cancellation.throwIfCancelled();
          final tool = _tools[call.name];
          if (tool == null) {
            final output = <String, dynamic>{
              'error': 'Unknown tool: ${call.name}',
            };
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: jsonEncode(output),
              isError: true,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            continue;
          }

          try {
            final context = ToolExecutionContext(
              workspaceRoot: request.workspaceRoot,
              cancellation: cancellation,
            );
            final preview = await tool.preview(call.arguments, context);
            final invocation = ToolInvocation(
              callId: call.callId,
              name: call.name,
              arguments: call.arguments,
              risk: tool.risk,
              workspaceRoot: request.workspaceRoot,
              preview: preview,
            );
            final policy = DefaultApprovalPolicy(
              request.permissionMode,
            ).evaluate(tool.risk);
            var approved = policy == ApprovalEvaluation.allow;
            if (policy == ApprovalEvaluation.ask) {
              await _onStatus(SessionStatus.waitingForApproval);
              approved =
                  await _approvals.request(invocation, cancellation) ==
                  ApprovalDecision.approved;
              await _onStatus(SessionStatus.running);
            }
            if (policy == ApprovalEvaluation.deny || !approved) {
              final item = ToolResultConversationItem(
                callId: call.callId,
                output: jsonEncode(<String, dynamic>{
                  'error': 'Tool execution was denied.',
                }),
                isError: true,
              );
              input.add(item);
              persisted.add(item);
              await _onProviderItems(<ConversationItem>[item]);
              await _onEvent('tool.denied', <String, dynamic>{
                'callId': call.callId,
                'name': call.name,
              });
              continue;
            }

            final result = await tool.execute(call.arguments, context);
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: result.output,
              isError: result.isError,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            await _onEvent('tool.completed', <String, dynamic>{
              'callId': call.callId,
              'name': call.name,
              'output': result.output,
              'isError': result.isError,
            });
          } on AgentCancelledException {
            rethrow;
          } on Exception catch (error) {
            final item = ToolResultConversationItem(
              callId: call.callId,
              output: jsonEncode(<String, dynamic>{'error': '$error'}),
              isError: true,
            );
            input.add(item);
            persisted.add(item);
            await _onProviderItems(<ConversationItem>[item]);
            await _onEvent('tool.failed', <String, dynamic>{
              'callId': call.callId,
              'name': call.name,
              'error': '$error',
            });
          }
        }
      }
    } on AgentCancelledException {
      await _onEvent('turn.cancelled', const <String, dynamic>{});
      await _onStatus(SessionStatus.idle);
      rethrow;
    } catch (error) {
      await _onEvent('turn.failed', <String, dynamic>{'error': '$error'});
      await _onStatus(SessionStatus.failed, error: '$error');
      rethrow;
    }
  }

  String _instructions(AgentRunRequest request) {
    final customPrompt = request.customSystemPrompt?.trim();
    final planning = request.sessionMode == SessionMode.plan
        ? '\n${planModeInstructions()}'
        : '';
    return '''
You are a coding agent operating in ${request.workspaceRoot}.
Use only the supplied tools. Read before editing, keep changes scoped to the request,
and validate relevant behavior before finishing. Never attempt to access paths outside
the workspace. Approval decisions are enforced by the host; do not work around them.
$planning${customPrompt == null || customPrompt.isEmpty ? '' : '\n$customPrompt'}
''';
  }
}
