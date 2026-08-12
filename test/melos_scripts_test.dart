import 'dart:io';

import 'package:test/test.dart';
import 'package:tinest_workspace/src/verification_runner.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('canonical Dart commands include root and package tests once', () {
    for (final script in <String>['test:dart', 'test:coverage:dart']) {
      final command = _script(pubspec, script);
      expect(command, contains('dart test test '));
      expect(command, contains('--no-flutter --dir-exists=test -c 4'));
      expect(command, isNot(contains(' -c 1 ')));
    }
  });

  test('Flutter commands use bounded four-worker concurrency', () {
    expect(_script(pubspec, 'test:flutter'), contains('--concurrency=4'));
    expect(
      _script(pubspec, 'test:coverage:flutter'),
      contains('--concurrency=4'),
    );
  });

  test('the canonical generator owns checked-in localizations', () {
    expect(_script(pubspec, 'generate'), contains('flutter gen-l10n'));
    expect(
      _script(pubspec, 'generate:check'),
      contains('tool/generate_check.dart'),
    );
  });

  test('Debug E2E delegates to the host desktop runner', () {
    final command = _script(pubspec, 'test:e2e:desktop');
    expect(command, contains('tool/run_desktop_e2e.dart'));
    expect(pubspec, isNot(contains('test:e2e:linux:')));
    expect(pubspec, isNot(contains('tool/run_linux_e2e.dart')));
    expect(
      _script(pubspec, 'verify:debug'),
      contains('dart run melos test:e2e:desktop'),
    );
  });

  test('formatting runs over a Git-derived file list, never the tree', () {
    // `dart format .` walks generated Flutter build output, which has no
    // exclude flag, so verify fails right after verify:debug populates build/.
    for (final script in <String>['format', 'format:check']) {
      final command = _script(pubspec, script);
      expect(command, contains('tool/format_sources.dart'));
      expect(command, isNot(contains('dart format .')));
    }
    expect(_script(pubspec, 'format:check'), contains('--check'));
    expect(_script(pubspec, 'format'), isNot(contains('--check')));
  });

  test('every static scanner skips Flutter build output', () {
    // verify:debug leaves packages/app/build populated, and a following
    // verify must not read the plugin sources a Flutter build writes there.
    final options = File('analysis_options.yaml').readAsStringSync();
    expect(options, contains('- "build/**"'));
    expect(options, contains('- "**/build/**"'));
    expect(
      File('packages/app/dart_dependency_validator.yaml').readAsStringSync(),
      contains('- "build/**"'),
    );
  });

  test('the embedded daemon port gate is a registered static check', () {
    expect(
      _script(pubspec, 'embedded-ports:check'),
      contains('tool/verify_embedded_ports.dart'),
    );
    expect(
      _scripts(WorkspaceVerificationPlans.fast()),
      contains('embedded-ports:check'),
    );
    expect(
      _scripts(WorkspaceVerificationPlans.full()),
      contains('embedded-ports:check'),
    );
  });

  test('the Tinyrack design-system checker is a registered static check', () {
    expect(
      _script(pubspec, 'design-system:check'),
      contains('tinyrack_ui:tinyrack_ui_check'),
    );
    expect(
      _scripts(WorkspaceVerificationPlans.fast()),
      contains('design-system:check'),
    );
    expect(
      _scripts(WorkspaceVerificationPlans.full()),
      contains('design-system:check'),
    );
  });
}

List<String> _scripts(VerificationPlan plan) => <String>[
  for (final phase in plan.phases)
    for (final task in phase.tasks) task.script,
];

String _script(String pubspec, String name) {
  final marker = '    $name:\n';
  final start = pubspec.indexOf(marker);
  if (start < 0) throw StateError('Missing Melos script $name');
  final remainder = pubspec.substring(start + marker.length);
  final next = RegExp(r'^    [a-z][a-z0-9:-]*:$', multiLine: true).firstMatch(
    remainder,
  );
  return next == null ? remainder : remainder.substring(0, next.start);
}
