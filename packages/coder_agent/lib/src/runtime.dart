import 'dart:async';
import 'dart:convert';

import 'package:coder_protocol/coder_protocol.dart';

import 'model.dart';

typedef AgentEventCallback =
    FutureOr<void> Function(String type, Map<String, dynamic> data);
typedef AgentStatusCallback =
    FutureOr<void> Function(AgentStatus status, {String? error});
typedef ProviderItemsCallback =
    FutureOr<void> Function(List<ConversationItem> items);

class AgentRunRequest {
  const AgentRunRequest({
    required this.agentId,
    required this.turnId,
    required this.workspaceRoot,
    required this.prompt,
    required this.model,
    required this.permissionMode,
    required this.history,
    required this.safetyIdentifier,
    this.reasoningEffort = 'medium',
    this.maxToolRounds = 64,
  });

  final String agentId;
  final String turnId;
  final String workspaceRoot;
  final String prompt;
  final String model;
  final String reasoningEffort;
  final PermissionMode permissionMode;
  final List<ConversationItem> history;
  final String safetyIdentifier;
  final int maxToolRounds;
}

class AgentRunResult {
  const AgentRunResult({
    required this.conversationItems,
    required this.toolRounds,
  });

  final List<ConversationItem> conversationItems;
  final int toolRounds;
}

class AgentRunner {
  AgentRunner({
    required ModelProvider provider,
    required Iterable<AgentTool> tools,
    required ApprovalCoordinator approvals,
    required AgentEventCallback onEvent,
    required AgentStatusCallback onStatus,
    required ProviderItemsCallback onProviderItems,
  }) : _provider = provider,
       _tools = <String, AgentTool>{for (final tool in tools) tool.name: tool},
       _approvals = approvals,
       _onEvent = onEvent,
       _onStatus = onStatus,
       _onProviderItems = onProviderItems;

  final ModelProvider _provider;
  final Map<String, AgentTool> _tools;
  final ApprovalCoordinator _approvals;
  final AgentEventCallback _onEvent;
  final AgentStatusCallback _onStatus;
  final ProviderItemsCallback _onProviderItems;

  Future<AgentRunResult> startTurn(
    AgentRunRequest request,
    CancellationToken cancellation,
  ) async {
    final userItem = UserConversationItem(request.prompt);
    final input = <ConversationItem>[...request.history, userItem];
    final persisted = <ConversationItem>[userItem];
    var toolRounds = 0;
    await _onStatus(AgentStatus.running);
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
          await _onStatus(AgentStatus.idle);
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
              await _onStatus(AgentStatus.waitingForApproval);
              approved =
                  await _approvals.request(invocation, cancellation) ==
                  ApprovalDecision.approved;
              await _onStatus(AgentStatus.running);
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
          } catch (error) {
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
      await _onStatus(AgentStatus.idle);
      rethrow;
    } catch (error) {
      await _onEvent('turn.failed', <String, dynamic>{'error': '$error'});
      await _onStatus(AgentStatus.failed, error: '$error');
      rethrow;
    }
  }

  String _instructions(AgentRunRequest request) =>
      '''
You are a coding agent operating in ${request.workspaceRoot}.
Use only the supplied tools. Read before editing, keep changes scoped to the request,
and validate relevant behavior before finishing. Never attempt to access paths outside
the workspace. Approval decisions are enforced by the host; do not work around them.
''';
}
