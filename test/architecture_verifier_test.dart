import 'dart:io';

import 'package:coder_workspace/src/architecture_verifier.dart';
import 'package:coder_workspace/src/coverage_verifier.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const verifier = ArchitectureVerifier('/workspace');

  test('valid application fixture depends only on an injected API', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path:
          'apps/coder_app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source:
          "import 'package:coder_client/coder_client.dart';\n"
          'final CoderApi api = throw UnimplementedError();',
    );
    expect(violations, isEmpty);
  });

  test('invalid application fixture reports imports and concrete calls', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path:
          'apps/coder_app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source:
          "import 'dart:io';\n"
          "import 'package:uuid/uuid.dart';\n"
          'final now = DateTime.now();\n'
          'final id = Uuid();',
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('feature application directories enforce application rules', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path:
          'apps/coder_app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source: "import 'dart:io';\nfinal process = Process.start;",
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('feature presentation cannot import another feature presentation', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path:
          'apps/coder_app/lib/src/features/sessions/presentation/'
          'session_page.dart',
      source: <String>[
        "import 'package:coder_app/src/features/settings/presentation/pages/",
        "settings_page.dart';",
      ].join(),
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('feature_presentation_dependency'),
    );
  });

  test('shared code cannot depend on a feature', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path: 'apps/coder_app/lib/src/shared/presentation/list_row.dart',
      source: <String>[
        "import 'package:coder_app/src/features/workspace/domain/",
        "workspace_selection.dart';",
      ].join(),
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('shared_feature_dependency'),
    );
  });

  test('feature domain stays independent of framework layers', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path:
          'apps/coder_app/lib/src/features/workspace/domain/'
          'workspace_selection.dart',
      source: "import 'package:flutter/widgets.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('domain_framework_dependency'),
    );
  });

  test('a vendor name in shared code is a violation', () {
    for (final package in const <String>[
      'coder_agent',
      'coder_daemon',
      'coder_client',
      'coder_cli',
      'coder_app',
      'coder_protocol',
    ]) {
      final violations = verifier.verifySource(
        package: package,
        path: '$package/lib/src/service.dart',
        source: "if (definition.id == 'openai') connectChatGpt();",
      );
      expect(
        violations.map((violation) => violation.rule),
        contains('vendor_literal'),
        reason: package,
      );
    }
  });

  test('provider infrastructure and the composition root may name vendors', () {
    expect(
      verifier.verifySource(
        package: 'coder_daemon',
        path:
            'packages/coder_daemon/lib/src/features/providers/'
            'infrastructure/openai/plugins.dart',
        source: "const id = 'openai'; // ChatGPT subscription backend",
      ),
      isEmpty,
    );
    expect(
      verifier.verifySource(
        package: 'coder_daemon',
        path: 'packages/coder_daemon/lib/src/bootstrap/application.dart',
        source: 'final plugins = openAIFamilyPlugins(clock: clock);',
      ),
      isEmpty,
    );
  });

  test(
    'a tool name literal in the app outside its presenter is a violation',
    () {
      final violations = verifier.verifySource(
        package: 'coder_app',
        path: 'apps/coder_app/lib/src/chat/chat_approval_card.dart',
        source: "if (approval.toolName == 'apply_patch') showDiff();",
      );
      expect(violations.single.rule, 'tool_name_literal');

      // The presenter tree owns the names, the timeline builds the dedicated
      // cards, and other packages define the tools themselves.
      for (final (package, path) in const <(String, String)>[
        (
          'coder_app',
          'apps/coder_app/lib/src/features/conversation/presentation/tools/'
              'apply_patch.dart',
        ),
        (
          'coder_app',
          'apps/coder_app/lib/src/features/conversation/application/'
              'chat_timeline_model.dart',
        ),
        ('coder_agent', 'packages/coder_agent/lib/src/tools/apply_patch.dart'),
        ('coder_daemon', 'packages/coder_daemon/lib/src/built_in_tools.dart'),
      ]) {
        expect(
          verifier.verifySource(
            package: package,
            path: path,
            source: "const name = 'apply_patch';",
          ),
          isEmpty,
          reason: path,
        );
      }
    },
  );

  test('invalid package fixture reports a reversed dependency', () {
    final violations = verifier.verifySource(
      package: 'coder_protocol',
      path: 'packages/coder_protocol/lib/src/bad.dart',
      source: "import 'package:coder_daemon/coder_daemon.dart';",
    );
    expect(violations.single.rule, 'source_dependency_direction');
  });

  test('the agent package stays independent of every internal package', () {
    for (final forbidden in const <String>[
      'coder_protocol',
      'coder_client',
      'coder_daemon',
      'coder_cli',
    ]) {
      final violations = verifier.verifySource(
        package: 'coder_agent',
        path: 'packages/coder_agent/lib/src/runtime.dart',
        source: "import 'package:$forbidden/$forbidden.dart';",
      );
      expect(violations.single.rule, 'source_dependency_direction');
    }
    expect(
      verifier.verifySource(
        package: 'coder_daemon',
        path:
            'packages/coder_daemon/lib/src/features/mcp/'
            'infrastructure/mcp_service.dart',
        source:
            "import 'package:coder_daemon/src/features/mcp/infrastructure/mcp.dart';",
      ),
      isEmpty,
    );
  });

  test('the PTY package is reachable only from the daemon', () {
    for (final package in const <String>[
      'coder_agent',
      'coder_protocol',
      'coder_app',
      'coder_cli',
      'coder_mcp',
    ]) {
      final violations = verifier.verifySource(
        package: package,
        path: 'packages/$package/lib/src/bad.dart',
        source: "import 'package:ptyworld/ptyworld.dart';",
      );
      expect(violations.single.rule, 'source_dependency_direction');
    }
    expect(
      verifier.verifySource(
        package: 'coder_daemon',
        path: 'packages/coder_daemon/lib/src/portable_terminal.dart',
        source: "import 'package:ptyworld/ptyworld.dart';",
      ),
      isEmpty,
    );
  });

  test('an unrestricted external package stays reachable everywhere', () {
    // The PTY restriction must not accidentally generalise: only packages
    // named in the external map are confined, so ordinary third-party
    // dependencies stay unrestricted.
    for (final package in const <String>['coder_agent', 'coder_protocol']) {
      expect(
        verifier.verifySource(
          package: package,
          path: 'packages/$package/lib/src/fine.dart',
          source: "import 'package:path/path.dart';",
        ),
        isEmpty,
      );
    }
  });

  test('the MCP service is held to the application-layer rules', () {
    final violations = verifier.verifySource(
      package: 'coder_daemon',
      path: 'packages/coder_daemon/lib/src/mcp_service.dart',
      source:
          "import 'dart:io';\n"
          'final started = Process.start;\n'
          'final now = DateTime.now();',
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('every daemon application boundary rejects concrete infrastructure', () {
    for (final file in const <String>[
      'session_interactions.dart',
      'session_settings.dart',
      'mcp_server_service.dart',
      'workspace_service.dart',
    ]) {
      final violations = verifier.verifySource(
        package: 'coder_daemon',
        path: 'packages/coder_daemon/lib/src/$file',
        source: "import 'dart:io';\nfinal process = Process.start;",
      );
      expect(
        violations.map((violation) => violation.rule),
        containsAll(<String>[
          'application_infrastructure_import',
          'application_concrete_dependency',
        ]),
        reason: file,
      );
    }
  });

  test('coverage thresholds report both line and branch failures', () {
    const coverage = CoverageVerifier('/workspace');
    final result = coverage.validate(
      'fixture',
      const CoverageTotals(
        linesFound: 100,
        linesHit: 89,
        branchesFound: 10,
        branchesHit: 7,
        missingFiles: <String>[],
      ),
    );
    expect(result, contains('line=89.0%'));
    expect(result, contains('branch=70.0%'));
  });

  test('an interface-only file is not untested production code', () {
    final root = Directory.systemTemp.createTempSync('coverage-estimate-');
    addTearDown(() => root.deleteSync(recursive: true));
    final package = Directory(p.join(root.path, 'fixture'))
      ..createSync(recursive: true);
    Directory(p.join(package.path, 'lib')).createSync();
    Directory(p.join(package.path, 'coverage')).createSync();
    // A port file whose doc prose contains "for": the word must read as
    // documentation, not as a loop that went untested.
    File(p.join(package.path, 'lib', 'ports.dart')).writeAsStringSync('''
/// Overrides discovery for all of the plugins at once.
abstract interface class Discovery {
  /// Fetches identifiers for one connection.
  Future<List<String>> fetch();
}
''');
    File(p.join(package.path, 'lib', 'logic.dart')).writeAsStringSync('''
int double_(int value) {
  return value * 2;
}
''');
    File(p.join(package.path, 'coverage', 'lcov.info')).writeAsStringSync('''
SF:${p.join(package.path, 'lib', 'logic.dart')}
LF:2
LH:2
BRF:1
BRH:1
end_of_record
''');

    final totals = const CoverageVerifier('/unused').calculate(package.path);

    expect(totals.missingFiles, isEmpty);
    expect(totals.lineRate, 1.0);
  });

  test(
    'coverage workspace selects explicit scopes and rejects unknown ones',
    () {
      final root = Directory.systemTemp.createTempSync('coverage-workspace-');
      addTearDown(() => root.deleteSync(recursive: true));
      for (final path in <String>[
        'packages/alpha',
        'packages/beta',
        'apps/ui',
      ]) {
        final directory = Directory(
          p.join(root.path, path),
        )..createSync(recursive: true);
        File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
          'name: ${p.basename(path)}\n',
        );
      }
      final workspace = CoverageWorkspace(root.path);

      expect(
        workspace
            .packageDirectories(scopes: const <String>{'beta', 'ui'})
            .map(
              p.basename,
            ),
        <String>['ui', 'beta'],
      );
      expect(
        () => workspace.packageDirectories(scopes: const <String>{'missing'}),
        throwsA(isA<UnknownCoverageScopeException>()),
      );
    },
  );
}
