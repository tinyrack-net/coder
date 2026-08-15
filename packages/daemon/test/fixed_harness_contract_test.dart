@Tags(<String>['feature_test__agent_harness__unit'])
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('v5 production code has no fixed Dart harness contracts', () {
    final workspace = _workspaceRoot();
    final productionRoots = <Directory>[
      Directory(p.join(workspace.path, 'packages', 'agent', 'lib')),
      Directory(p.join(workspace.path, 'packages', 'app', 'lib')),
      Directory(p.join(workspace.path, 'packages', 'client', 'lib')),
      Directory(p.join(workspace.path, 'packages', 'daemon', 'lib')),
      Directory(p.join(workspace.path, 'packages', 'protocol', 'lib')),
    ];
    final forbidden = <RegExp>[
      RegExp(r'\bAgentSessionMode\b'),
      RegExp(r'\bSessionMode\b'),
      RegExp(r'\bGoalStatus\b'),
      RegExp(r'\bGoalDto\b'),
      RegExp(r'\bGoal(?:Replace|Update|Get|Result|Clear|Cleared)\w*Dto\b'),
      RegExp(r'\bSessionGoalService\b'),
      RegExp(r'\bGoalToolProvider\b'),
      RegExp(r'\bGoalRepository\b'),
      RegExp(r'\bGoalDao\b'),
      RegExp(r'\bclass\s+Goals\s+extends\s+Table\b'),
      RegExp(r'\bsessions(?:Get|Replace|Update|Clear)GoalProcedure\b'),
      RegExp(r'\bsessionsGoal(?:Updated|Cleared)Notification\b'),
      RegExp(r'\bsessionsCompactProcedure\b'),
      RegExp(r'\bcompactSession\s*\('),
      RegExp(r'\bConversationCompactor\b'),
      RegExp(r'\bAgentRunner\b'),
      RegExp(r'\bAgentRunRequest\b'),
      RegExp(r'\bAgentToolSurface(?:Provider)?\b'),
      RegExp(r'\bAgentToolRegistry\b'),
      RegExp(
        r'\b(?:AgentToolCatalog|StaticAgentToolCatalog|CompositeAgentToolCatalog)\b',
      ),
      RegExp(r'\bAgentToolProvider\b'),
      RegExp(r'\bSelectableToolProvider\b'),
      RegExp(r'\bAgentToolScope\b'),
      RegExp(r'\bAgentToolTurn\b'),
      RegExp(r'\bclass\s+\w+\s+extends\s+AgentTool\b'),
      RegExp(r'\bbuiltInAgentToolRegistry\b'),
      RegExp(r'\bToolSearchIndex\b'),
      RegExp(
        r'''(?:name\s*[:=]|super\s*\(\s*name\s*:?)\s*['"]tool_search['"]''',
      ),
      RegExp(r'\bAgentToolGroup\b'),
      RegExp('ModelToolSurface'),
      RegExp('alwaysOn', caseSensitive: false),
      RegExp(r'\bPromptAssets\b'),
      RegExp(r'\bpermissionsInstructions\s*\('),
      RegExp(r'\borchestratorPrompt\b'),
      RegExp(r'\bsubagentPrompt\b'),
      RegExp(r'\bapplyPatchToolInstructions\b'),
    ];
    final violations = <String>[];

    for (final root in productionRoots) {
      for (final entry in root.listSync(recursive: true)) {
        if (entry is! File || !entry.path.endsWith('.dart')) continue;
        final relative = p.relative(entry.path, from: workspace.path);
        final lines = entry.readAsLinesSync();
        for (var index = 0; index < lines.length; index += 1) {
          for (final pattern in forbidden) {
            if (pattern.hasMatch(lines[index])) {
              violations.add('$relative:${index + 1}: ${lines[index].trim()}');
            }
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'The Agent harness is Lua plugin behavior in v5, '
          'not fixed Dart API:\n'
          '${violations.join('\n')}',
    );
  });

  test('provider adapters do not inject built-in Lua tool names', () {
    final workspace = _workspaceRoot();
    final providerRoot = Directory(
      p.join(
        workspace.path,
        'packages',
        'daemon',
        'lib',
        'src',
        'features',
        'providers',
      ),
    );
    final builtInToolNames = RegExp(
      r'\b(?:list_directory|read_file|search_text|view_image|apply_patch|'
      'exec_command|write_stdin|attach_file|read_attachment|'
      'request_user_input|current_time|get_context_remaining|new_context|'
      'compact_context|list_skills|create_goal|get_goal|update_goal|'
      'list_resources|list_resource_templates|read_resource|spawn_agent|'
      r'send_message|followup_task|wait_agent|interrupt_agent|list_agents)\b',
    );
    final violations = <String>[];

    for (final entry in providerRoot.listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final relative = p.relative(entry.path, from: workspace.path);
      final lines = entry.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        if (builtInToolNames.hasMatch(lines[index])) {
          violations.add('$relative:${index + 1}: ${lines[index].trim()}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Provider adapters transport model blocks and tool schemas supplied '
          'by the Lua driver; they must not inject instructions for a built-in '
          'tool:\n${violations.join('\n')}',
    );
  });

  test('Lua host primitives dispatch only through the typed registry', () {
    final workspace = _workspaceRoot();
    final harness = File(
      p.join(
        workspace.path,
        'packages',
        'daemon',
        'lib',
        'src',
        'features',
        'plugins',
        'runtime',
        'plugin_agent_harness.dart',
      ),
    );
    final source = harness.readAsStringSync();
    final directDispatch = RegExp(
      r'''(?:case\s+['"]host\.|operation\s*==\s*['"]host\.)''',
    );

    expect(
      directDispatch.allMatches(source),
      isEmpty,
      reason:
          'Every host primitive, including network and secret access, must '
          'use HostPrimitiveRegistry safety metadata and structured results. '
          'The harness must not grow operation-name switches.',
    );
  });

  test('plugin UI callbacks expose host primitives through the registry', () {
    final workspace = _workspaceRoot();
    final uiService = File(
      p.join(
        workspace.path,
        'packages',
        'daemon',
        'lib',
        'src',
        'features',
        'plugins',
        'infrastructure',
        'plugin_ui_service.dart',
      ),
    ).readAsStringSync();

    expect(
      uiService,
      isNot(
        anyOf(contains('PluginUiHostGateway'), contains('requiredCapability')),
      ),
      reason:
          'UI callbacks must resolve capability, effect, cancellation, and '
          'structured results from HostPrimitiveRegistry descriptors instead '
          'of a parallel string-dispatch gateway.',
    );
  });
}

Directory _workspaceRoot() {
  var directory = Directory.current.absolute;
  while (true) {
    if (Directory(p.join(directory.path, 'packages', 'daemon')).existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Tinest workspace root not found.');
    }
    directory = parent;
  }
}
