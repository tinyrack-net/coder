@Tags(<String>['feature_test__tool_context_budget__unit'])
library;

import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:test/test.dart';

void main() {
  ToolExecutionContext context({
    int? window,
    ModelUsage usage = const ModelUsage(),
    void Function()? onReset,
  }) => ToolExecutionContext(
    workspaceRoot: '/workspace',
    cancellation: CancellationToken(),
    contextWindowTokens: window,
    turnUsage: usage,
    requestContextReset: onReset ?? () {},
  );

  Map<String, dynamic> decode(ToolResult result) =>
      jsonDecode(result.output) as Map<String, dynamic>;

  test('both tools read and work under every permission mode', () {
    for (final tool in <AgentTool>[
      GetContextRemainingTool(),
      NewContextTool(),
    ]) {
      expect(tool.risk, AgentToolRisk.read, reason: tool.name);
      for (final mode in AgentPermissionMode.values) {
        expect(
          DefaultApprovalPolicy(mode).evaluateRisk(tool.risk),
          ApprovalEvaluation.allow,
          reason: '${tool.name} under $mode',
        );
      }
      final schema = tool.strictJsonSchema;
      expect(schema['type'], 'object', reason: tool.name);
      expect(schema['additionalProperties'], isFalse, reason: tool.name);
    }
  });

  test('remaining tokens subtract what the last response used', () async {
    final result = await GetContextRemainingTool().execute(
      const <String, dynamic>{},
      context(
        window: 200000,
        usage: const ModelUsage(
          inputTokens: 30000,
          outputTokens: 2000,
          totalTokens: 32000,
        ),
      ),
    );

    final decoded = decode(result);
    expect(decoded['usedTokens'], 32000);
    expect(decoded['contextWindowTokens'], 200000);
    expect(decoded['remainingTokens'], 168000);
  });

  test('an unknown window reports null rather than a guess', () async {
    final result = await GetContextRemainingTool().execute(
      const <String, dynamic>{},
      context(usage: const ModelUsage(inputTokens: 100, totalTokens: 100)),
    );

    final decoded = decode(result);
    expect(decoded['usedTokens'], 100);
    expect(decoded['contextWindowTokens'], isNull);
    expect(decoded['remainingTokens'], isNull);
  });

  test('an overflowing window floors at zero', () async {
    // A provider can report more used than the window it advertised; a
    // negative budget would be nonsense for the model to reason from.
    final result = await GetContextRemainingTool().execute(
      const <String, dynamic>{},
      context(
        window: 1000,
        usage: const ModelUsage(inputTokens: 4000, totalTokens: 4000),
      ),
    );

    expect(decode(result)['remainingTokens'], 0);
  });

  test('new_context asks the runner rather than resetting itself', () async {
    var requested = 0;

    final result = await NewContextTool().execute(
      const <String, dynamic>{},
      context(onReset: () => requested += 1),
    );

    expect(requested, 1);
    expect(result.isError, isFalse);
    expect(decode(result)['started'], isTrue);
  });
}
