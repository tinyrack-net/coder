@Tags(<String>['feature_test__tool_harness_parity__unit'])
library;

import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test('the default policy covers every permission and risk combination', () {
    const expected = <AgentPermissionMode, List<ApprovalEvaluation>>{
      AgentPermissionMode.readOnly: <ApprovalEvaluation>[
        ApprovalEvaluation.allow,
        ApprovalEvaluation.deny,
        ApprovalEvaluation.deny,
        ApprovalEvaluation.deny,
      ],
      AgentPermissionMode.ask: <ApprovalEvaluation>[
        ApprovalEvaluation.allow,
        ApprovalEvaluation.ask,
        ApprovalEvaluation.ask,
        ApprovalEvaluation.ask,
      ],
      AgentPermissionMode.workspaceWrite: <ApprovalEvaluation>[
        ApprovalEvaluation.allow,
        ApprovalEvaluation.allow,
        ApprovalEvaluation.ask,
        ApprovalEvaluation.ask,
      ],
      AgentPermissionMode.fullAccess: <ApprovalEvaluation>[
        ApprovalEvaluation.allow,
        ApprovalEvaluation.allow,
        ApprovalEvaluation.allow,
        ApprovalEvaluation.allow,
      ],
    };

    for (final mode in AgentPermissionMode.values) {
      final policy = DefaultApprovalPolicy(mode);
      for (final risk in AgentToolRisk.values) {
        final invocation = ToolInvocation(
          callId: '${mode.name}-${risk.name}',
          name: 'test_tool',
          arguments: <String, dynamic>{'risk': risk.name},
          risk: risk,
          workspaceRoot: '/workspace',
          preview: 'Exercise ${risk.name}.',
        );
        final evaluation = expected[mode]![risk.index];

        expect(
          policy.evaluate(invocation),
          evaluation,
          reason: '${mode.name} must classify ${risk.name} consistently.',
        );
        expect(policy.evaluateRisk(risk), evaluation);
      }
    }
  });
}
