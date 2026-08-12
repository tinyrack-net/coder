import 'dart:io';

import 'package:test/test.dart';
import 'package:tinest_quality/src/verification_runner.dart';
import 'package:yaml/yaml.dart';

import 'support/repo_root.dart';

void main() {
  useRepositoryRoot();
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final scripts = (pubspec['melos'] as YamlMap)['scripts'] as YamlMap;

  test('root exposes only four quality commands', () {
    const qualityCommands = <String>{
      'generate',
      'test',
      'verify',
      'verify:debug',
    };
    final actual = scripts.keys
        .whereType<String>()
        .where((name) => !name.startsWith('run:') && !name.startsWith('build:'))
        .toSet();
    expect(actual, qualityCommands);
    for (final command in qualityCommands) {
      expect((scripts[command] as YamlMap)['run'], contains('tinest_quality'));
    }
  });

  test('root contains configuration but no source or test package', () {
    for (final path in <String>['lib', 'tool', 'test', 'dart_test.yaml']) {
      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    }
  });

  test('package tests own app static contracts and suite dispatch', () {
    expect(
      File(
        'packages/app/test/devtools/embedded_port_verifier_test.dart',
      ).existsSync(),
      isTrue,
    );
    final commands = <String>[
      for (final phase in WorkspaceVerificationPlans.tests(jobs: 4).phases)
        for (final task in phase.tasks) task.arguments.join(' '),
    ];
    expect(
      commands.singleWhere((value) => value.contains('_test-dart')),
      contains('tinest_quality _test-dart'),
    );
    expect(
      commands.singleWhere((value) => value.contains('_test-flutter')),
      contains('tinest_quality _test-flutter'),
    );
  });

  test('full verification delegates shared policy upstream', () {
    final commands = <String>[
      for (final phase in WorkspaceVerificationPlans.full(jobs: 4).phases)
        for (final task in phase.tasks) task.arguments.join(' '),
    ];
    expect(commands, contains(contains('tinyrack_workspace source-check')));
    expect(commands, contains(contains('tinyrack_workspace coverage-check')));
    expect(commands, contains(contains('tinyrack_ui:tinyrack_ui_check')));
  });

  test('coverage uses one kernel runner per package cache', () {
    final application = File(
      'packages/tinest_quality/bin/src/application.dart',
    ).readAsStringSync();

    expect(application, contains('incremental_kernel'));
    expect(application, isNot(contains("'--total-shards='")));
    expect(application, contains("'testRandomizationSeeds'"));
  });
}
