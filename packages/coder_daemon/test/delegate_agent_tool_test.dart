@Tags(<String>['feature_test__agent_delegation__unit'])
library;

import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  late _RecordingGateway gateway;
  late DelegateAgentTool tool;
  late ToolExecutionContext context;

  setUp(() {
    gateway = _RecordingGateway();
    tool = DelegateAgentTool(gateway: gateway);
    context = ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
    );
  });

  Map<String, dynamic> decode(ToolResult result) =>
      jsonDecode(result.output) as Map<String, dynamic>;

  test('a valid call reaches the gateway and returns its result', () async {
    gateway.result = const ToolResult(
      output: '{"childSessionId":"child-1","status":"completed"}',
    );

    final result = await tool.execute(const <String, dynamic>{
      'agentDefinitionId': 'reviewer',
      'prompt': 'Review the diff.',
    }, context);

    expect(gateway.calls.single.agentDefinitionId, 'reviewer');
    expect(gateway.calls.single.prompt, 'Review the diff.');
    expect(decode(result)['childSessionId'], 'child-1');
    expect(result.isError, isFalse);
  });

  test('the turn cancellation is handed to the child', () async {
    await tool.execute(const <String, dynamic>{
      'agentDefinitionId': 'reviewer',
      'prompt': 'Review.',
    }, context);

    // The child has to stop when the parent turn does, so the same token
    // travels down rather than a fresh one.
    expect(
      identical(gateway.calls.single.cancellation, context.cancellation),
      isTrue,
    );
  });

  group('argument validation', () {
    test('a missing or empty agent id never reaches the gateway', () async {
      for (final id in <Object?>[null, '', 7]) {
        final result = await tool.execute(<String, dynamic>{
          'agentDefinitionId': id,
          'prompt': 'Review.',
        }, context);

        expect(result.isError, isTrue, reason: '$id');
        expect(decode(result)['error'], contains('agentDefinitionId'));
      }
      expect(gateway.calls, isEmpty);
    });

    test('a blank prompt never reaches the gateway', () async {
      for (final prompt in <Object?>[null, '', '   ', 7]) {
        final result = await tool.execute(<String, dynamic>{
          'agentDefinitionId': 'reviewer',
          'prompt': prompt,
        }, context);

        expect(result.isError, isTrue, reason: '$prompt');
        expect(decode(result)['error'], contains('prompt'));
      }
      // Spending a whole child turn on an empty instruction helps nobody, so
      // it is rejected before anything is created.
      expect(gateway.calls, isEmpty);
    });
  });

  test('a gateway refusal surfaces rather than being swallowed', () async {
    gateway.error = const _RefusedDelegation();

    // The refusals that matter — a non-root parent, an agent outside the
    // allowlist, an archived subagent — are decided by the service, and the
    // tool must not turn them into a success.
    await expectLater(
      tool.execute(const <String, dynamic>{
        'agentDefinitionId': 'other',
        'prompt': 'Do it.',
      }, context),
      throwsA(isA<_RefusedDelegation>()),
    );
  });

  test('the tool describes itself strictly and previews its target', () async {
    expect(tool.name, 'delegate_agent');
    expect(tool.risk, ToolRisk.read);
    expect(tool.strict, isTrue);
    expect(tool.strictJsonSchema['additionalProperties'], isFalse);
    expect(tool.strictJsonSchema['required'], <String>[
      'agentDefinitionId',
      'prompt',
    ]);
    expect(
      await tool.preview(const <String, dynamic>{
        'agentDefinitionId': 'reviewer',
      }, context),
      'reviewer',
    );
    expect(await tool.preview(const <String, dynamic>{}, context), isNull);
  });
}

/// Stands in for the service refusing a delegation it is not allowed to run.
final class _RefusedDelegation implements Exception {
  const _RefusedDelegation();
}

final class _RecordingGateway implements AgentDelegationGateway {
  final List<
    ({String agentDefinitionId, String prompt, CancellationToken cancellation})
  >
  calls =
      <
        ({
          String agentDefinitionId,
          String prompt,
          CancellationToken cancellation,
        })
      >[];

  ToolResult result = const ToolResult(output: '{}');
  Exception? error;

  @override
  Future<ToolResult> delegate({
    required String agentDefinitionId,
    required String prompt,
    required CancellationToken cancellation,
  }) async {
    calls.add((
      agentDefinitionId: agentDefinitionId,
      prompt: prompt,
      cancellation: cancellation,
    ));
    if (error case final failure?) throw failure;
    return result;
  }
}
