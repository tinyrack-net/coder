import 'package:coder_workspace/src/architecture_verifier.dart';
import 'package:test/test.dart';

void main() {
  const verifier = ArchitectureVerifier('/workspace');

  test('agent domain cannot import the wire protocol', () {
    final violations = verifier.verifySource(
      package: 'coder_agent',
      path: 'packages/coder_agent/lib/src/runtime.dart',
      source: "import 'package:coder_protocol/coder_protocol.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('source_dependency_direction'),
    );
  });

  test('daemon application code cannot import protocol or infrastructure', () {
    final violations = verifier.verifySource(
      package: 'coder_daemon',
      path:
          'packages/coder_daemon/lib/src/features/sessions/application/'
          'session_service.dart',
      source:
          "import 'package:coder_protocol/coder_protocol.dart';\n"
          "import 'package:drift/drift.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_protocol_dependency',
        'application_infrastructure_import',
      ]),
    );
  });
}
