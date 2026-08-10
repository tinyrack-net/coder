import 'package:agent/agent.dart';
import 'package:test/test.dart';

const _tags = <String>['feature_test__turn_execution__unit'];

void main() {
  group('permissionsInstructions', () {
    test('describes every mode distinctly', tags: _tags, () {
      final rendered = <AgentPermissionMode, String>{
        for (final mode in AgentPermissionMode.values)
          mode: permissionsInstructions(mode: mode, workspaceRoot: '/w'),
      };
      expect(
        rendered.values.toSet(),
        hasLength(AgentPermissionMode.values.length),
      );
      for (final text in rendered.values) {
        expect(text.trim(), isNotEmpty);
      }
    });

    test('read-only rejects rather than escalates', tags: _tags, () {
      final text = permissionsInstructions(
        mode: AgentPermissionMode.readOnly,
        workspaceRoot: '/w',
      );
      expect(text, contains('`read-only`'));
      expect(text, contains('`never`'));
      expect(text, isNot(contains('# Escalation Requests')));
    });

    test('full access never prompts', tags: _tags, () {
      final text = permissionsInstructions(
        mode: AgentPermissionMode.fullAccess,
        workspaceRoot: '/w',
      );
      expect(text, contains('`full-access`'));
      expect(text, contains('`never`'));
      expect(text, isNot(contains('# Escalation Requests')));
    });

    test('ask escalates every mutation', tags: _tags, () {
      final text = permissionsInstructions(
        mode: AgentPermissionMode.ask,
        workspaceRoot: '/w',
      );
      expect(text, contains('`on-request`'));
      expect(text, contains('# Escalation Requests'));
    });

    test('workspace write escalates only commands', tags: _tags, () {
      final text = permissionsInstructions(
        mode: AgentPermissionMode.workspaceWrite,
        workspaceRoot: '/w',
      );
      expect(text, contains('`workspace-write`'));
      expect(text, contains('`unless-trusted`'));
      expect(text, contains('# Escalation Requests'));
    });

    test('names the writable root where one applies', tags: _tags, () {
      expect(
        permissionsInstructions(
          mode: AgentPermissionMode.workspaceWrite,
          workspaceRoot: '/some/root',
        ),
        contains('The writable root is `/some/root`.'),
      );
      expect(
        permissionsInstructions(
          mode: AgentPermissionMode.readOnly,
          workspaceRoot: '/some/root',
        ),
        isNot(contains('writable root')),
      );
    });

    test('leaves no unrendered placeholder behind', tags: _tags, () {
      for (final mode in AgentPermissionMode.values) {
        expect(
          permissionsInstructions(mode: mode, workspaceRoot: '/w'),
          isNot(contains('{{')),
        );
      }
    });
  });
}
