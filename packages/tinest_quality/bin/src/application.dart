import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tinest_quality/src/architecture_verifier.dart';
import 'package:tinest_quality/src/ci_change_scope.dart';
import 'package:tinest_quality/src/feature_manifest.dart';
import 'package:tinest_quality/src/feature_verifier.dart';
import 'package:tinest_quality/src/resource_budget.dart';
import 'package:tinest_quality/src/verification_runner.dart';
import 'package:tinest_quality/src/workload_planner.dart';
import 'package:yaml/yaml.dart';

/// Receives one human-readable line from a quality command.
typedef QualityOutput = void Function(Object? value);

enum _TinestQualityCommand {
  generate('generate'),
  test('test'),
  verify('verify'),
  e2e('e2e'),
  ciScope('ci-scope'),
  staticChecks('_static-checks'),
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
  late final QualityCommandOptions options;
  try {
    options = QualityCommandOptions.parse(
      arguments.skip(1).toList(growable: false),
      environment: Platform.environment,
      detectedJobs: Platform.numberOfProcessors,
    );
  } on FormatException catch (failure) {
    writeError(failure.message);
    return _usage(writeError);
  }
  final rest = options.remaining;
  switch (command) {
    case _TinestQualityCommand.generate:
      if (rest.any((argument) => argument != '--check')) {
        return _usage(writeError);
      }
      return _runMeasured(
        name: 'generate',
        jobs: options.jobs,
        reportPath: options.reportPath,
        body: () => _generate(
          check: rest.contains('--check'),
          jobs: options.jobs,
          out: out,
          error: writeError,
        ),
      );
    case _TinestQualityCommand.test:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runPlan(
        WorkspaceVerificationPlans.tests(jobs: options.jobs),
        jobs: options.jobs,
        reportPath: options.reportPath,
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.verify:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runPlan(
        WorkspaceVerificationPlans.full(jobs: options.jobs),
        jobs: options.jobs,
        reportPath: options.reportPath,
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.e2e:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runMeasured(
        name: 'e2e',
        jobs: options.jobs,
        reportPath: options.reportPath,
        body: () => _runProcess(
          'dart',
          <String>[
            'run',
            'packages/app/tool/run_desktop_e2e.dart',
            '--jobs=${options.jobs}',
            if (options.reportPath case final reportPath?)
              '--report=$reportPath.desktop.json',
          ],
          out: out,
          error: writeError,
        ),
      );
    case _TinestQualityCommand.ciScope:
      if (rest.isNotEmpty) return _usage(writeError);
      final files = await stdin
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();
      out(CiChangeScope.forPullRequest(files).outputValue);
      return 0;
    case _TinestQualityCommand.staticChecks:
      if (rest.isNotEmpty) return _usage(writeError);
      return _runPlan(
        WorkspaceVerificationPlans.staticChecks(jobs: options.jobs),
        jobs: options.jobs,
        reportPath: options.reportPath,
        out: out,
        error: writeError,
      );
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
      return _runDartPackages(
        jobs: options.jobs,
        scopes: _scopes(rest),
        coverage: false,
        reportPath: options.reportPath,
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.testFlutter:
      if (rest.isNotEmpty) return _usage(writeError);
      final seed = _newTestSeed();
      return _runMeasured(
        name: 'Flutter tests',
        jobs: options.jobs,
        reportPath: options.reportPath,
        testRandomizationSeed: seed,
        body: () => _runProcess(
          'flutter',
          <String>[
            'test',
            'test',
            '--concurrency=${options.jobs}',
            '--test-randomize-ordering-seed=$seed',
          ],
          workingDirectory: 'packages/app',
          out: out,
          error: writeError,
        ),
      );
    case _TinestQualityCommand.coverageDart:
      if (rest.any((argument) => !argument.startsWith('--scope='))) {
        return _usage(writeError);
      }
      return _runDartPackages(
        jobs: options.jobs,
        scopes: _scopes(rest),
        coverage: true,
        reportPath: options.reportPath,
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.coverageDartPackage:
      if (rest.isNotEmpty) return _usage(writeError);
      final seed = _newTestSeed();
      Directory('coverage').createSync(recursive: true);
      final packageName =
          Platform.environment['MELOS_PACKAGE_NAME'] ?? _currentPackageName();
      final coveragePath = File('coverage/lcov.info').absolute.path;
      return _runProcess(
        'dart',
        <String>[
          'test',
          '--concurrency=${options.jobs}',
          '--coverage-path=$coveragePath',
          '--coverage-package=$packageName',
          '--branch-coverage',
          '--test-randomize-ordering-seed=$seed',
        ],
        out: out,
        error: writeError,
      );
    case _TinestQualityCommand.coverageFlutter:
      if (rest.isNotEmpty) return _usage(writeError);
      final seed = _newTestSeed();
      return _runMeasured(
        name: 'Flutter coverage',
        jobs: options.jobs,
        reportPath: options.reportPath,
        testRandomizationSeed: seed,
        body: () => _runProcess(
          'flutter',
          <String>[
            'test',
            '--coverage',
            '--concurrency=${options.jobs}',
            '--branch-coverage',
            '--test-randomize-ordering-seed=$seed',
          ],
          workingDirectory: 'packages/app',
          out: out,
          error: writeError,
        ),
      );
  }
}

Future<int> _generate({
  required bool check,
  required int jobs,
  required QualityOutput out,
  required QualityOutput error,
}) async {
  final before = check ? _generatedSources() : const <String, String>{};
  final generatorReport =
      await VerificationRunner(
        executor: _ProcessTaskExecutor(out, error),
        maxJobs: jobs,
      ).run(
        const VerificationPlan(
          phases: <VerificationPhase>[
            VerificationPhase(
              tasks: <VerificationTask>[
                VerificationTask(
                  name: 'Flutter localizations',
                  executable: 'flutter',
                  arguments: <String>['gen-l10n'],
                  workingDirectory: 'packages/app',
                  exclusiveResources: <String>{'flutter-build'},
                ),
                VerificationTask(
                  name: 'provider catalog',
                  executable: 'dart',
                  arguments: <String>[
                    'run',
                    'packages/daemon/tool/generate_provider_catalog.dart',
                  ],
                ),
                VerificationTask(
                  name: 'agent prompts',
                  executable: 'dart',
                  arguments: <String>[
                    'run',
                    'packages/agent/tool/generate_prompts.dart',
                  ],
                ),
              ],
            ),
          ],
        ),
      );
  if (!generatorReport.succeeded) return 1;
  final buildRunnerResult = await _runProcess(
    'dart',
    <String>[
      'run',
      'melos',
      'exec',
      '--depends-on=build_runner',
      '-c',
      '$jobs',
      '-o',
      '--',
      'dart run build_runner build',
    ],
    out: out,
    error: error,
  );
  if (buildRunnerResult != 0) return buildRunnerResult;
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

Set<String> _scopes(List<String> arguments) => <String>{
  for (final argument in arguments) argument.substring('--scope='.length),
};

Future<int> _runDartPackages({
  required int jobs,
  required Set<String> scopes,
  required bool coverage,
  required String? reportPath,
  required QualityOutput out,
  required QualityOutput error,
}) async {
  final stopwatch = Stopwatch()..start();
  final targets = _dartPackageTargets(scopes);
  if (targets.isEmpty) {
    error('No Dart packages with tests matched the requested scope.');
    return 64;
  }
  final allocations = allocatePackageJobs(
    <PackageWorkload>[
      for (final target in targets)
        PackageWorkload(name: target.name, suites: target.suites),
    ],
    jobs,
  );
  final tasks = <VerificationTask>[];
  if (coverage) {
    for (final target in targets) {
      final concurrency = allocations[target.name]!;
      final shardDirectory = Directory('${target.path}/coverage/shards');
      if (shardDirectory.existsSync()) {
        shardDirectory.deleteSync(recursive: true);
      }
      shardDirectory.createSync(recursive: true);
      final seed = _newTestSeed();
      tasks.add(
        VerificationTask(
          name: '${target.name} coverage',
          executable: 'dart',
          arguments: <String>[
            'test',
            // Kernel compiler processes share a package-global
            // `.dart_tool/test/incremental_kernel` cache. Keep one runner per
            // package and parallelize its suites internally; packages still
            // fan out concurrently under the global resource budget.
            '--concurrency=$concurrency',
            '--coverage-path=${_coverageShardPath(target, 0)}',
            '--coverage-package=${target.name}',
            '--branch-coverage',
            '--test-randomize-ordering-seed=$seed',
          ],
          workingDirectory: target.path,
          cpuSlots: concurrency,
          testRandomizationSeed: seed,
        ),
      );
    }
  } else {
    for (final target in targets) {
      final seed = _newTestSeed();
      tasks.add(
        VerificationTask(
          name: '${target.name} tests',
          executable: 'dart',
          arguments: <String>[
            'test',
            '--concurrency=${allocations[target.name]}',
            '--test-randomize-ordering-seed=$seed',
          ],
          workingDirectory: target.path,
          cpuSlots: allocations[target.name]!,
          testRandomizationSeed: seed,
        ),
      );
    }
  }
  final report =
      await VerificationRunner(
        executor: _ProcessTaskExecutor(out, error),
        maxJobs: jobs,
      ).run(
        VerificationPlan(
          phases: <VerificationPhase>[
            VerificationPhase(tasks: tasks),
          ],
        ),
      );
  if (!report.succeeded) {
    stopwatch.stop();
    _writeReport(
      reportPath,
      jobs: jobs,
      duration: stopwatch.elapsed,
      results: report.results,
    );
    return 1;
  }
  if (!coverage) {
    stopwatch.stop();
    _writeReport(
      reportPath,
      jobs: jobs,
      duration: stopwatch.elapsed,
      results: report.results,
    );
    return 0;
  }
  final mergeResults = await Future.wait(<Future<int>>[
    for (final target in targets)
      _runProcess(
        'dart',
        <String>[
          'run',
          'tinyrack_workspace',
          'coverage-merge',
          '--input=${_coverageShardPath(target, 0)}',
          '--output=${_coveragePath(target)}',
        ],
        out: out,
        error: error,
      ),
  ]);
  stopwatch.stop();
  _writeReport(
    reportPath,
    jobs: jobs,
    duration: stopwatch.elapsed,
    results: report.results,
  );
  return mergeResults.every((result) => result == 0) ? 0 : 1;
}

List<_PackageTestTarget> _dartPackageTargets(Set<String> scopes) {
  final targets = <_PackageTestTarget>[];
  for (final entity in Directory('packages').listSync()) {
    if (entity is! Directory) continue;
    final pubspecFile = File('${entity.path}/pubspec.yaml');
    final testDirectory = Directory('${entity.path}/test');
    if (!pubspecFile.existsSync() || !testDirectory.existsSync()) continue;
    final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    final name = pubspec['name'] as String;
    final dependencies = pubspec['dependencies'];
    final isFlutter =
        dependencies is YamlMap && dependencies.containsKey('flutter');
    if (isFlutter || (scopes.isNotEmpty && !scopes.contains(name))) continue;
    final suiteCount = testDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .length;
    if (suiteCount == 0) continue;
    targets.add(
      _PackageTestTarget(name: name, path: entity.path, suites: suiteCount),
    );
  }
  targets.sort((left, right) {
    final suites = right.suites.compareTo(left.suites);
    return suites == 0 ? left.name.compareTo(right.name) : suites;
  });
  return targets;
}

final class _PackageTestTarget {
  const _PackageTestTarget({
    required this.name,
    required this.path,
    required this.suites,
  });

  final String name;
  final String path;
  final int suites;
}

String _coveragePath(_PackageTestTarget target) =>
    File('${target.path}/coverage/lcov.info').absolute.path;

String _coverageShardPath(_PackageTestTarget target, int shard) =>
    File('${target.path}/coverage/shards/$shard.info').absolute.path;

Future<int> _runPlan(
  VerificationPlan plan, {
  required int jobs,
  required String? reportPath,
  required QualityOutput out,
  required QualityOutput error,
}) async {
  final stopwatch = Stopwatch()..start();
  final report = await VerificationRunner(
    executor: _ProcessTaskExecutor(out, error),
    maxJobs: jobs,
  ).run(plan);
  stopwatch.stop();
  out('\nVerification summary:');
  for (final result in report.results) {
    out(
      '  ${result.succeeded ? 'PASS' : 'FAIL'} ${result.task.name} '
      '(${result.duration.inMilliseconds / 1000}s, exit ${result.exitCode})',
    );
  }
  _writeReport(
    reportPath,
    jobs: jobs,
    duration: stopwatch.elapsed,
    results: report.results,
  );
  return report.succeeded ? 0 : 1;
}

Future<int> _runMeasured({
  required String name,
  required int jobs,
  required String? reportPath,
  required Future<int> Function() body,
  int? testRandomizationSeed,
}) async {
  final stopwatch = Stopwatch()..start();
  final result = await body();
  stopwatch.stop();
  _writeReport(
    reportPath,
    jobs: jobs,
    duration: stopwatch.elapsed,
    results: <VerificationTaskResult>[
      VerificationTaskResult(
        task: VerificationTask(
          name: name,
          executable: 'dart',
          arguments: const <String>[],
          cpuSlots: jobs,
          testRandomizationSeed: testRandomizationSeed,
        ),
        exitCode: result,
        duration: stopwatch.elapsed,
      ),
    ],
  );
  return result;
}

void _writeReport(
  String? path, {
  required int jobs,
  required Duration duration,
  required List<VerificationTaskResult> results,
}) {
  if (path == null) return;
  final weightedMilliseconds = results.fold<int>(
    0,
    (sum, result) =>
        sum + result.duration.inMilliseconds * result.task.cpuSlots,
  );
  final capacityMilliseconds = duration.inMilliseconds * jobs;
  final nestedSeeds = <VerificationTaskResult, List<int>>{
    for (final result in results) result: _nestedTestSeeds(result.task),
  };
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(<String, Object?>{
        'schemaVersion': 1,
        'host': Platform.operatingSystem,
        'detectedJobs': Platform.numberOfProcessors,
        'effectiveJobs': jobs,
        'durationMilliseconds': duration.inMilliseconds,
        'slotUtilization': capacityMilliseconds == 0
            ? 0
            : weightedMilliseconds / capacityMilliseconds,
        'testRandomizationSeeds': <int>[
          for (final result in results) ?result.task.testRandomizationSeed,
          for (final result in results) ...nestedSeeds[result]!,
        ],
        'tasks': <Map<String, Object?>>[
          for (final result in results)
            <String, Object?>{
              'name': result.task.name,
              'cpuSlots': result.task.cpuSlots,
              'exclusiveResources': result.task.exclusiveResources.toList()
                ..sort(),
              'durationMilliseconds': result.duration.inMilliseconds,
              'exitCode': result.exitCode,
              'testRandomizationSeed': ?result.task.testRandomizationSeed,
              if (nestedSeeds[result]!.isNotEmpty)
                'nestedTestRandomizationSeeds': nestedSeeds[result],
            },
        ],
      }),
    );
}

List<int> _nestedTestSeeds(VerificationTask task) {
  final reportArgument = task.arguments
      .where((argument) => argument.startsWith('--report='))
      .firstOrNull;
  if (reportArgument == null) return const <int>[];
  final report = File(reportArgument.substring('--report='.length));
  if (!report.existsSync()) return const <int>[];
  final decoded = jsonDecode(report.readAsStringSync());
  if (decoded is! Map<String, Object?>) return const <int>[];
  final seeds = decoded['testRandomizationSeeds'];
  if (seeds is! List<Object?>) return const <int>[];
  return seeds.whereType<int>().toList(growable: false);
}

final Random _testSeedRandom = Random.secure();

int _newTestSeed() => _testSeedRandom.nextInt(0x7fffffff);

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
    '<generate|test|verify|e2e|ci-scope> '
    '[--jobs=N] [--report=path]',
  );
  return 64;
}

void _writeOutput(Object? value) => stdout.writeln(value);

void _writeError(Object? value) => stderr.writeln(value);

String _currentPackageName() {
  final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  return pubspec['name'] as String;
}
