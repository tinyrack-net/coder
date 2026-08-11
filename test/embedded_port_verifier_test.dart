import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tinest_workspace/src/embedded_port_verifier.dart';

void main() {
  const verifier = EmbeddedPortVerifier('/workspace');
  const path = 'packages/app/integration_test/example_e2e_test.dart';

  const compliant =
      "import 'support/ephemeral_port.dart';\n"
      'Future<void> main() async {\n'
      '  final launcher = IsolateEmbeddedDaemonLauncher(\n'
      '    resolveConfig: () => DaemonConfig(homeDirectory: home.path),\n'
      '  );\n'
      '  final store = MemoryAppStore(\n'
      '    settings: AppSettings(\n'
      '      embeddedDaemonPort: await reserveEphemeralPort(),\n'
      '    ),\n'
      '  );\n'
      '}\n';

  test('a fixture that reserves a port for every store passes', () {
    expect(
      verifier.verifySource(path: path, source: compliant),
      isEmpty,
    );
  });

  test('a store left on the default port is reported', () {
    final violations = verifier.verifySource(
      path: path,
      source: compliant.replaceAll(
        '      embeddedDaemonPort: await reserveEphemeralPort(),\n',
        '      localeTag: null,\n',
      ),
    );

    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'unreserved_embedded_daemon_port',
        'unpinned_embedded_daemon_port',
      ]),
    );
    expect(violations.first.path, path);
  });

  test('a second unpinned store in a compliant file is still reported', () {
    final violations = verifier.verifySource(
      path: path,
      source: '$compliant  final other = MemoryAppStore();\n',
    );

    expect(
      violations.single.rule,
      'unpinned_embedded_daemon_port',
    );
    expect(violations.single.message, contains('found 2 stores and 1 pinned'));
  });

  test('a hard-coded machine-global port is reported with its line', () {
    for (final source in <String>[
      'const port = 7337;',
      'const port = defaultEmbeddedDaemonPort;',
    ]) {
      final violations = verifier.verifySource(
        path: path,
        source: 'void main() {}\n$source\n',
      );

      expect(violations.single.rule, 'fixed_embedded_daemon_port');
      expect(violations.single.line, 2);
    }
  });

  test('a port-like substring is not mistaken for the fixed port', () {
    expect(
      verifier.verifySource(path: path, source: 'const port = 173370;'),
      isEmpty,
    );
  });

  test('an ambient daemon configuration is reported', () {
    final violations = verifier.verifySource(
      path: path,
      source: compliant.replaceAll(
        '    resolveConfig: () => DaemonConfig(homeDirectory: home.path),\n',
        '',
      ),
    );

    expect(violations.single.rule, 'ambient_daemon_config');
  });

  test('a file that never starts a real daemon is not constrained', () {
    expect(
      verifier.verifySource(
        path: path,
        source: 'final store = MemoryAppStore();',
      ),
      isEmpty,
    );
  });

  test('a workspace without the integration test directory is clean', () {
    expect(const EmbeddedPortVerifier('/does/not/exist').verify(), isEmpty);
  });

  test('the verifier reads sources from disk in a stable order', () async {
    final root = await Directory.systemTemp.createTemp('embedded-port-check-');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    final directory = Directory(
      p.join(
        root.path,
        p.joinAll(
          p.posix.split(EmbeddedPortVerifier.integrationTestDirectory),
        ),
      ),
    )..createSync(recursive: true);
    File(p.join(directory.path, 'b_test.dart')).writeAsStringSync(
      'const port = 7337;',
    );
    File(p.join(directory.path, 'a_test.dart')).writeAsStringSync(
      'const port = 7337;',
    );
    File(p.join(directory.path, 'notes.md')).writeAsStringSync('7337');

    final violations = EmbeddedPortVerifier(root.path).verify();

    expect(
      violations.map((violation) => violation.path),
      <String>[
        '${EmbeddedPortVerifier.integrationTestDirectory}/a_test.dart',
        '${EmbeddedPortVerifier.integrationTestDirectory}/b_test.dart',
      ],
    );
    expect(
      violations.first.toString(),
      startsWith(
        '${EmbeddedPortVerifier.integrationTestDirectory}/a_test.dart:1 '
        '[fixed_embedded_daemon_port]',
      ),
    );
  });
}
