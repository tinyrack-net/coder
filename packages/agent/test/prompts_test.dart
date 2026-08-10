import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  group('defaultBaseInstructions', () {
    test(
      'carries every section the prompt contract defines',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        for (final header in const <String>[
          '# How you work',
          '## Personality',
          '# AGENTS.md spec',
          '## Responsiveness',
          '## Planning',
          '## Asking the user',
          '## Task execution',
          '## Validating your work',
          '## Ambition vs. precision',
          '## Sharing progress updates',
          '## Presenting your work and final message',
          '### Final answer structure and style guidelines',
          '# Tool Guidelines',
        ]) {
          expect(defaultBaseInstructions, contains(header));
        }
      },
    );

    test(
      'names only tools this package defines',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        // The upstream prompt names its own harness and tools; a bad port
        // would carry those across unnoticed.
        for (final absent in const <String>[
          'Codex CLI',
          'rg --files',
          'ask_user',
        ]) {
          expect(defaultBaseInstructions, isNot(contains(absent)));
        }
        for (final tool in const <String>[
          'apply_patch',
          'update_plan',
          'request_user_input',
          'exec_command',
          'search_text',
          'read_file',
          'glob',
        ]) {
          expect(defaultBaseInstructions, contains(tool));
        }
      },
    );
  });

  group('prompt assets', () {
    test(
      'carry no carriage returns into the model',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        // An asset edited on Windows would otherwise ship `\r` in the prompt.
        for (final asset in <String>[
          defaultBaseInstructions,
          planModeInstructions(),
          applyPatchToolInstructions,
          orchestratorPrompt,
          goalContinuationPrompt,
          goalBudgetLimitPrompt,
          CompactionPolicy.summarizationPrompt,
          CompactionPolicy.summarizationInstructions,
          CompactionPolicy.summaryPrefix,
          for (final mode in AgentPermissionMode.values)
            permissionsInstructions(mode: mode, workspaceRoot: '/w'),
        ]) {
          expect(asset, isNot(contains('\r')));
        }
      },
    );
  });

  group('named prompts', () {
    test(
      'goal prompts declare the variables the host fills in',
      tags: const <String>['feature_test__session_goal__unit'],
      () {
        for (final variable in const <String>[
          '{{objective}}',
          '{{tokensUsed}}',
          '{{tokenBudget}}',
        ]) {
          expect(goalContinuationPrompt, contains(variable));
          expect(goalBudgetLimitPrompt, contains(variable));
        }
        expect(goalContinuationPrompt, contains('{{remainingTokens}}'));
      },
    );

    test(
      'apply_patch instructions describe the format the tool parses',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        // Every header `CodexPatch.parse` accepts has to be documented, or the
        // model has no way to reach an operation the tool supports.
        for (final header in const <String>[
          '*** Begin Patch',
          '*** End Patch',
          '*** Add File: ',
          '*** Delete File: ',
          '*** Update File: ',
          '*** Move to: ',
        ]) {
          expect(applyPatchToolInstructions, contains(header));
        }
        // The tool rejects unified diffs outright, so nothing may suggest one.
        expect(applyPatchToolInstructions, isNot(contains('/dev/null')));
      },
    );
  });

  group('renderPromptTemplate', () {
    test(
      'substitutes every declared variable',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('a {{one}} b {{two}}', const <String, String>{
            'one': '1',
            'two': '2',
          }),
          'a 1 b 2',
        );
      },
    );

    test(
      'drops placeholders no variable supplies',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('a {{missing}}b', const <String, String>{}),
          'a b',
        );
      },
    );

    test(
      'leaves text without placeholders untouched',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          renderPromptTemplate('plain', const <String, String>{'x': 'y'}),
          'plain',
        );
      },
    );
  });

  group('buildSystemPrompt', () {
    test(
      'leads with the base instructions',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        final prompt = buildSystemPrompt(
          const SystemPromptInputs(workspaceRoot: '/w'),
        );
        expect(prompt, startsWith(defaultBaseInstructions.trimRight()));
      },
    );

    test(
      'orders every layer after the base instructions',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        final prompt = buildSystemPrompt(
          const SystemPromptInputs(
            workspaceRoot: '/w',
            permissionsInstructions: 'PERMISSIONS',
            environmentContext: 'ENVIRONMENT',
            projectDoc: 'PROJECT_DOC',
            toolPrompts: <String>['TOOL_ONE', 'TOOL_TWO'],
            modeInstructions: 'MODE',
            customInstructions: 'CUSTOM',
            internalInstructions: 'INTERNAL',
          ),
        );
        final order = <String>[
          '# Tool Guidelines',
          'PERMISSIONS',
          'ENVIRONMENT',
          'PROJECT_DOC',
          'TOOL_ONE',
          'TOOL_TWO',
          'MODE',
          'CUSTOM',
          'INTERNAL',
        ].map(prompt.indexOf).toList(growable: false);
        expect(order, everyElement(greaterThanOrEqualTo(0)));
        expect(order, orderedEquals(<int>[...order]..sort()));
      },
    );

    test(
      'omits layers the turn does not supply',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        final prompt = buildSystemPrompt(
          const SystemPromptInputs(
            workspaceRoot: '/w',
            customInstructions: '   ',
          ),
        );
        expect(prompt.trim(), defaultBaseInstructions.trim());
      },
    );

    test(
      'reports the workspace root in the environment context it builds',
      tags: const <String>['feature_test__turn_execution__unit'],
      () {
        expect(
          environmentContext(workspaceRoot: '/some/where'),
          contains('/some/where'),
        );
      },
    );
  });
}
