import 'dart:io';

import 'package:coder_workspace/src/verification_runner.dart';
import 'package:test/test.dart';

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
