import 'dart:async';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('agent executes an approved tool loop and completes', () async {
    final provider = _FakeProvider(<List<ModelEvent>>[
      <ModelEvent>[
        const ModelFunctionCall(
          callId: 'call-1',
          name: 'echo',
          arguments: <String, dynamic>{'value': 'hello'},
        ),
        const ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: '',
            toolCalls: <ConversationToolCall>[
              ConversationToolCall(
                callId: 'call-1',
                name: 'echo',
                arguments: <String, dynamic>{'value': 'hello'},
              ),
            ],
          ),
        ),
      ],
      <ModelEvent>[
        const ModelTextDelta('done'),
        const ModelResponseCompleted(
          assistant: AssistantConversationItem(text: 'done'),
        ),
      ],
    ]);
    final events = <String>[];
    final runner = AgentRunner(
      provider: provider,
      tools: <AgentTool>[_EchoTool()],
      approvals: _ApproveAll(),
      onEvent: (type, _) => events.add(type),
      onStatus: (_, {error}) {},
      onProviderItems: (_) {},
    );

    final result = await runner.startTurn(
      AgentRunRequest(
        agentId: 'agent-1',
        turnId: 'turn-1',
        workspaceRoot: Directory.current.path,
        prompt: 'test',
        model: 'test-model',
        permissionMode: PermissionMode.ask,
        history: const <ConversationItem>[],
        safetyIdentifier: 'safe-id',
      ),
      CancellationToken(),
    );

    expect(result.toolRounds, 1);
    expect(
      events,
      containsAllInOrder(<String>[
        'tool.requested',
        'tool.completed',
        'turn.completed',
      ]),
    );
  });
}

class _FakeProvider implements ModelProvider {
  _FakeProvider(this.responses);
  final List<List<ModelEvent>> responses;
  var index = 0;
  @override
  String get id => 'fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    yield* Stream<ModelEvent>.fromIterable(responses[index++]);
  }
}

class _EchoTool extends AgentTool {
  @override
  String get name => 'echo';
  @override
  String get description => 'echo';
  @override
  ToolRisk get risk => ToolRisk.command;
  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'value': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['value'],
    'additionalProperties': false,
  };
  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => ToolResult(output: arguments['value'] as String);
}

class _ApproveAll implements ApprovalCoordinator {
  @override
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) async => ApprovalDecision.approved;
}
