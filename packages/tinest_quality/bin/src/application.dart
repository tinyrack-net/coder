import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tinest_quality/src/architecture_verifier.dart';
import 'package:tinest_quality/src/ci_change_scope.dart';
import 'package:tinest_quality/src/feature_manifest.dart';
import 'package:tinest_quality/src/feature_verifier.dart';
import 'package:tinest_quality/src/verification_runner.dart';
import 'package:yaml/yaml.dart';

/// Receives one human-readable line from a quality command.
typedef QualityOutput = void Function(Object? value);

enum _TinestQualityCommand {
  generate('generate'),
  test('test'),
  verify('verify'),
  e2e('e2e'),
  ciScope('ci-scope'),
  architectureCheck('_architecture-check'),
  featuresCheck('_features-check'),
  testDart('_test-dart'),
  testFlutter('_test-flutter'),
  coverageDart('_coverage-dart'),
  coverageDartPackage('_coverage-dart-package'),
  coverageFlutter('_coverage-flutter');

  const _TinestQualityCommand(this.cliName);

  final String cliName;

  static _TinestQualityCommand? parse(String value) {
    for (final command in values) {
      if (command.cliName == value) return command;
    }
    return null;
  }
}

/// Runs the Tinest repository-quality command and returns a process exit code.
Future<int> runTinestQuality(
  List<String> arguments, {
  QualityOutput out = _writeOutput,
  QualityOutput? error,
}) async {
  final writeError = error ?? _writeError;
  if (arguments.isEmpty) return _usage(writeError);
  final command = _TinestQualityCommand.parse(arguments.first);
  if (command == null) return _usage(writeError);
  final rest = arguments.skip(1).toList(growable: false);
  switch (command) {
    case _TinestQualityCommand.generate:
      if (rest.any((argument) => argument != '--check')) {
        return _usage(writeError);
      }
      return _generate(
        check: rest.contains('--check'),
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.test:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runPlan(WorkspaceVerificationPlans.tests(), out, writeError);
    case _TinestQualityCommand.verify:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runPlan(WorkspaceVerificationPlans.full(), out, writeError);
    case _TinestQualityCommand.e2e:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runProcess(
        'dart',
        const <String>['run', 'packages/app/tool/run_desktop_e2e.dart'],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.ciScope:
      if (rest.isNotEmpty) return _usage(writeError);
      final files = await stdin
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();
      out(CiChangeScope.forPullRequest(files).outputValue);
      return 0;
    case _TinestQualityCommand.architectureCheck:
      if (rest.isNotEmpty) return _usage(writeError);
      return _architectureCheck(out, writeError);
    case _TinestQualityCommand.featuresCheck:
      if (rest.isNotEmpty) return _usage(writeError);
      return _featuresCheck(out, writeError);
    case _TinestQualityCommand.testDart:
      if (rest.any((argument) => !argument.startsWith('--scope='))) {
        return _usage(writeError);
      }
      final scopes = <String>[
        for (final argument in rest) argument,
      ];
      return _runProcess(
        'dart',
        <String>[
          'run',
          'melos',
          'exec',
          '--no-flutter',
          '--dir-exists=test',
          ...scopes,
          '-c',
          '4',
          '--',
          'dart test --concurrency=1 --test-randomize-ordering-seed=random',
        ],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.testFlutter:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runProcess(
        'dart',
        <String>[
          'run',
          'melos',
          'exec',
          '--flutter',
          '--scope=app',
          '--',
          <String>[
            'flutter test test --concurrency=4',
            '--test-randomize-ordering-seed=random',
          ].join(' '),
        ],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.coverageDart:
      if (rest.any((argument) => !argument.startsWith('--scope='))) {
        return _usage(writeError);
      }
      return _runProcess(
        'dart',
        <String>[
          'run',
          'melos',
          'exec',
          '--no-flutter',
          '--dir-exists=test',
          ...rest,
          '-c',
          '4',
          '--',
          'dart run tinest_quality _coverage-dart-package',
        ],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.coverageDartPackage:
      if (rest.isNotEmpty) return _usage(writeError);
      Directory('coverage').createSync(recursive: true);
      final packageName =
          Platform.environment['MELOS_PACKAGE_NAME'] ?? _currentPackageName();
      final coveragePath = File('coverage/lcov.info').absolute.path;
      return _runProcess(
        'dart',
        <String>[
          'test',
          '--concurrency=1',
          '--coverage-path=$coveragePath',
          '--coverage-package=$packageName',
          '--branch-coverage',
          '--test-randomize-ordering-seed=random',
        ],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.coverageFlutter:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runProcess(
        'dart',
        <String>[
          'run',
          'melos',
          'exec',
          '--flutter',
          '--scope=app',
          '--',
          <String>[
            'flutter test --coverage --concurrency=4 --branch-coverage',
            '--test-randomize-ordering-seed=random',
          ].join(' '),
        ],
        out: out,
        error: writeError,
      );
  }
}

Future<int> _generate({
  required bool check,
  required QualityOutput out,
  required QualityOutput error,
}) async {
  final before = check ? _generatedSources() : const <String, String>{};
  final commands = <({String executable, List<String> arguments, String? cwd})>[
    (
      executable: 'flutter',
      arguments: const <String>['gen-l10n'],
      cwd: 'packages/app',
    ),
    (
      executable: 'dart',
      arguments: const <String>[
        'run',
        'packages/daemon/tool/generate_provider_catalog.dart',
      ],
      cwd: null,
    ),
    (
      executable: 'dart',
      arguments: const <String>[
        'run',
        'packages/agent/tool/generate_prompts.dart',
      ],
      cwd: null,
    ),
    (
      executable: 'dart',
      arguments: const <String>[
        'run',
        'melos',
        'exec',
        '--depends-on=build_runner',
        '-c',
        '3',
        '-o',
        '--',
        'dart run build_runner build',
      ],
      cwd: null,
    ),
  ];
  for (final command in commands) {
    final result = await _runProcess(
      command.executable,
      command.arguments,
      workingDirectory: command.cwd,
      out: out,
      error: error,
    );
    if (result != 0) return result;
  }
  if (!check) return 0;
  final after = _generatedSources();
  final changed = <String>{
    ...before.keys,
    ...after.keys,
  }.where((path) => before[path] != after[path]).toList()..sort();
  if (changed.isEmpty) {
    out('Generated sources are current.');
    return 0;
  }
  error('Generated sources were stale:');
  changed.forEach(error);
  return 1;
}

Map<String, String> _generatedSources() => <String, String>{
  for (final entity in Directory.current.listSync(recursive: true))
    if (entity is File && _isGeneratedSource(entity.path))
      entity.path: entity.readAsStringSync(),
};

bool _isGeneratedSource(String value) {
  final path = value.replaceAll(r'\', '/');
  return path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.contains('/packages/app/lib/l10n/gen/app_localizations');
}

int _architectureCheck(QualityOutput out, QualityOutput error) {
  final violations = ArchitectureVerifier(Directory.current.path).verify();
  if (violations.isEmpty) {
    out('Architecture verification passed.');
    return 0;
  }
  violations.forEach(error);
  return 1;
}

int _featuresCheck(QualityOutput out, QualityOutput error) {
  final violations = FeatureVerifier(
    Directory.current.path,
    contracts: tinestFeatureManifest,
    uiContracts: tinestUiReachabilityManifest,
    uiJourneys: tinestUiJourneyManifest,
  ).verify();
  if (violations.isEmpty) {
    out(
      'Feature verification passed (${tinestFeatureManifest.length} features).',
    );
    return 0;
  }
  error('Feature verification failed:');
  for (final violation in violations) {
    error('  - $violation');
  }
  return 1;
}

Future<int> _runPlan(
  VerificationPlan plan,
  QualityOutput out,
  QualityOutput error,
) async {
  final report = await VerificationRunner(
    executor: _ProcessTaskExecutor(out, error),
    maxConcurrency: 4,
  ).run(plan);
  out('\nVerification summary:');
  for (final result in report.results) {
    out(
      '  ${result.succeeded ? 'PASS' : 'FAIL'} ${result.task.name} '
      '(${result.duration.inMilliseconds / 1000}s, exit ${result.exitCode})',
    );
  }
  return report.succeeded ? 0 : 1;
}

final class _ProcessTaskExecutor implements VerificationTaskExecutor {
  const _ProcessTaskExecutor(this.out, this.error);

  final QualityOutput out;
  final QualityOutput error;

  @override
  Future<VerificationTaskResult> run(VerificationTask task) async {
    out('\n[${task.name}] ${task.executable} ${task.arguments.join(' ')}');
    final stopwatch = Stopwatch()..start();
    final result = await _runProcess(
      task.executable,
      task.arguments,
      workingDirectory: task.workingDirectory,
      out: out,
      error: error,
    );
    stopwatch.stop();
    return VerificationTaskResult(
      task: task,
      exitCode: result,
      duration: stopwatch.elapsed,
    );
  }
}

Future<int> _runProcess(
  String executable,
  List<String> arguments, {
  required QualityOutput out,
  required QualityOutput error,
  String? workingDirectory,
  Map<String, String> environment = const <String, String>{},
}) async {
  try {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows && executable == 'flutter',
    );
    return process.exitCode;
  } on ProcessException catch (failure) {
    error(failure);
    return 127;
  }
}

int _usage(QualityOutput error) {
  error(
    'Usage: dart run tinest_quality '
    '<generate|test|verify|e2e|ci-scope>',
  );
  return 64;
}

void _writeOutput(Object? value) => stdout.writeln(value);

void _writeError(Object? value) => stderr.writeln(value);

String _currentPackageName() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  return pubspec['name'] as String;
}
