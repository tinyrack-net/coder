import 'dart:async';

/// One process executed as part of workspace verification.
final class VerificationTask {
  /// Creates a process-backed verification task.
  const VerificationTask({
    required this.name,
    required this.executable,
    required this.arguments,
    this.workingDirectory,
  });

  /// Human-readable task name.
  final String name;

  /// Executable launched for the task.
  final String executable;

  /// Arguments passed to [executable].
  final List<String> arguments;

  /// Optional working directory relative to the workspace root.
  final String? workingDirectory;
}

/// Tasks that may execute concurrently.
final class VerificationPhase {
  /// Creates a phase whose [tasks] may run concurrently.
  const VerificationPhase({required this.tasks});

  /// Tasks in this phase.
  final List<VerificationTask> tasks;
}

/// Ordered phases in a verification run.
final class VerificationPlan {
  /// Creates an ordered verification plan.
  const VerificationPlan({required this.phases});

  /// Ordered phases; a failed phase prevents later phases from running.
  final List<VerificationPhase> phases;
}

/// Result of running one [VerificationTask].
final class VerificationTaskResult {
  /// Creates a completed task result.
  const VerificationTaskResult({
    required this.task,
    required this.exitCode,
    required this.duration,
  });

  /// Task that ran.
  final VerificationTask task;

  /// Process exit code.
  final int exitCode;

  /// Elapsed execution time.
  final Duration duration;

  /// Whether the process exited successfully.
  bool get succeeded => exitCode == 0;
}

/// Executes one verification task.
abstract interface class VerificationTaskExecutor {
  /// Runs [task] and returns its result.
  Future<VerificationTaskResult> run(VerificationTask task);
}

/// Results collected from the phases that ran.
final class VerificationReport {
  /// Creates an immutable verification report.
  const VerificationReport(this.results);

  /// Task results in deterministic plan order.
  final List<VerificationTaskResult> results;

  /// Failed task results.
  List<VerificationTaskResult> get failures =>
      results.where((result) => !result.succeeded).toList(growable: false);

  /// Whether every executed task succeeded.
  bool get succeeded => failures.isEmpty;
}

/// Executes ordered phases with bounded concurrency inside each phase.
final class VerificationRunner {
  /// Creates a runner with bounded phase concurrency.
  VerificationRunner({required this.executor, required this.maxConcurrency})
    : assert(maxConcurrency > 0, 'maxConcurrency must be positive');

  /// Task execution boundary.
  final VerificationTaskExecutor executor;

  /// Maximum tasks running at once in a phase.
  final int maxConcurrency;

  /// Runs phases in order and stops after the first failed phase.
  Future<VerificationReport> run(VerificationPlan plan) async {
    final allResults = <VerificationTaskResult>[];
    for (final phase in plan.phases) {
      final results = await _runPhase(phase);
      allResults.addAll(results);
      if (results.any((result) => !result.succeeded)) break;
    }
    return VerificationReport(List.unmodifiable(allResults));
  }

  Future<List<VerificationTaskResult>> _runPhase(
    VerificationPhase phase,
  ) async {
    if (phase.tasks.isEmpty) return const <VerificationTaskResult>[];
    final results = List<VerificationTaskResult?>.filled(
      phase.tasks.length,
      null,
    );
    var nextTask = 0;
    Future<void> worker() async {
      while (nextTask < phase.tasks.length) {
        final index = nextTask;
        nextTask += 1;
        results[index] = await executor.run(phase.tasks[index]);
      }
    }

    await Future.wait(<Future<void>>[
      for (
        var index = 0;
        index < maxConcurrency && index < phase.tasks.length;
        index += 1
      )
        worker(),
    ]);
    return results.cast<VerificationTaskResult>();
  }
}

VerificationTask _dart(String name, List<String> arguments) =>
    VerificationTask(name: name, executable: 'dart', arguments: arguments);

/// Canonical plans used by the four public Melos quality commands.
abstract final class WorkspaceVerificationPlans {
  static final _generated = VerificationPhase(
    tasks: <VerificationTask>[
      _dart('generated sources', <String>[
        'run',
        'tinest_quality',
        'generate',
        '--check',
      ]),
    ],
  );

  static final _staticTasks = <VerificationTask>[
    _dart('format', <String>[
      'run',
      'melos',
      'format',
      '--output=none',
      '--set-exit-if-changed',
    ]),
    _dart('analysis', const <String>['analyze', '--fatal-infos']),
    _dart('dependencies', <String>[
      'run',
      'melos',
      'exec',
      '-c',
      '4',
      '--',
      'dart run dependency_validator',
    ]),
    _dart('Tinyrack dependency sources', const <String>[
      'run',
      'tinyrack_workspace',
      'source-check',
    ]),
    _dart('architecture', const <String>[
      'run',
      'tinest_quality',
      '_architecture-check',
    ]),
    _dart('features', const <String>[
      'run',
      'tinest_quality',
      '_features-check',
    ]),
    _dart('Tinyrack design system', const <String>[
      'run',
      'tinyrack_ui:tinyrack_ui_check',
      '--root',
      '.',
    ]),
  ];

  /// Runs every package test exactly once without coverage collection.
  static VerificationPlan tests() => VerificationPlan(
    phases: <VerificationPhase>[
      VerificationPhase(
        tasks: <VerificationTask>[
          _dart('Dart tests', const <String>[
            'run',
            'tinest_quality',
            '_test-dart',
          ]),
          _dart('Flutter tests', const <String>[
            'run',
            'tinest_quality',
            '_test-flutter',
          ]),
        ],
      ),
    ],
  );

  /// Runs the complete static and coverage gates on every supported host.
  static VerificationPlan full() => VerificationPlan(
    phases: <VerificationPhase>[
      _generated,
      VerificationPhase(tasks: _staticTasks),
      VerificationPhase(
        tasks: <VerificationTask>[
          _dart('Dart coverage', const <String>[
            'run',
            'tinest_quality',
            '_coverage-dart',
          ]),
        ],
      ),
      VerificationPhase(
        tasks: <VerificationTask>[
          _dart('Flutter coverage', const <String>[
            'run',
            'tinest_quality',
            '_coverage-flutter',
          ]),
        ],
      ),
      VerificationPhase(
        tasks: <VerificationTask>[
          _dart('coverage thresholds', const <String>[
            'run',
            'tinyrack_workspace',
            'coverage-check',
            '--line=90',
            '--branch=80',
          ]),
        ],
      ),
    ],
  );
}
