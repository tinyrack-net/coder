import 'package:coder_workspace/src/architecture_verifier.dart';
import 'package:coder_workspace/src/coverage_verifier.dart';
import 'package:test/test.dart';

void main() {
  const verifier = ArchitectureVerifier('/workspace');

  test('valid application fixture depends only on an injected API', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path: 'apps/coder_app/lib/src/controller.dart',
      source:
          "import 'package:coder_client/coder_client.dart';\n"
          'final CoderApi api = throw UnimplementedError();',
    );
    expect(violations, isEmpty);
  });

  test('invalid application fixture reports imports and concrete calls', () {
    final violations = verifier.verifySource(
      package: 'coder_app',
      path: 'apps/coder_app/lib/src/controller.dart',
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

  test('invalid package fixture reports a reversed dependency', () {
    final violations = verifier.verifySource(
      package: 'coder_protocol',
      path: 'packages/coder_protocol/lib/src/bad.dart',
      source: "import 'package:coder_daemon/coder_daemon.dart';",
    );
    expect(violations.single.rule, 'source_dependency_direction');
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
}
