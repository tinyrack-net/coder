import 'dart:async';

/// One Melos script executed as part of workspace verification.
final class VerificationTask {
  /// Creates a task with a human-readable [name] and Melos [script].
  const VerificationTask({required this.name, required this.script});

  /// Label used in progress and failure output.
  final String name;

  /// Melos script name.
  final String script;
}

/// Tasks that may execute concurrently.
final class VerificationPhase {
  /// Creates a phase.
  const VerificationPhase({required this.tasks});

  /// Tasks in deterministic reporting order.
  final List<VerificationTask> tasks;
}

/// Ordered phases in a verification run.
final class VerificationPlan {
  /// Creates a plan.
  const VerificationPlan({required this.phases});

  /// Phases that execute sequentially.
  final List<VerificationPhase> phases;
}

/// Result returned by a task executor.
final class VerificationTaskResult {
  /// Creates a task result.
  const VerificationTaskResult({
    required this.task,
    required this.exitCode,
    required this.duration,
  });

  /// Task that ran.
  final VerificationTask task;

  /// Process exit code.
  final int exitCode;

  /// Wall-clock duration measured by the executor.
  final Duration duration;

  /// Whether the task completed successfully.
  bool get succeeded => exitCode == 0;
}

/// Typed process port used by [VerificationRunner].
abstract interface class VerificationTaskExecutor {
  /// Executes [task] and returns its exit code and duration.
  Future<VerificationTaskResult> run(VerificationTask task);
}

/// Aggregated result of a verification plan.
final class VerificationReport {
  /// Creates a report.
  const VerificationReport(this.results);

  /// Results in plan order, excluding phases skipped after a failure.
  final List<VerificationTaskResult> results;

  /// Failed task results.
  List<VerificationTaskResult> get failures =>
      results.where((result) => !result.succeeded).toList(growable: false);

  /// Whether every executed task succeeded.
  bool get succeeded => failures.isEmpty;
}

/// Executes ordered phases with bounded concurrency inside each phase.
final class VerificationRunner {
  /// Creates a runner.
  VerificationRunner({required this.executor, required this.maxConcurrency})
    : assert(maxConcurrency > 0, 'maxConcurrency must be positive');

  /// Process execution port.
  final VerificationTaskExecutor executor;

  /// Maximum simultaneous tasks in one phase.
  final int maxConcurrency;

  /// Runs [plan], stopping before the next phase after any failure.
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
        var workerIndex = 0;
        workerIndex < maxConcurrency && workerIndex < phase.tasks.length;
        workerIndex += 1
      )
        worker(),
    ]);
    return results.cast<VerificationTaskResult>();
  }
}

/// Canonical verification plans exposed through the workspace Melos scripts.
abstract final class WorkspaceVerificationPlans {
  static const _generated = VerificationPhase(
    tasks: <VerificationTask>[
      VerificationTask(
        name: 'generated sources',
        script: 'generate:check',
      ),
    ],
  );

  static const _staticTasks = <VerificationTask>[
    VerificationTask(name: 'format', script: 'format:check'),
    VerificationTask(name: 'analysis', script: 'analyze'),
    VerificationTask(name: 'dependencies', script: 'dependencies:check'),
    VerificationTask(
      name: 'Tinyrack dependency sources',
      script: 'tinyrack-sources:check',
    ),
    VerificationTask(name: 'architecture', script: 'architecture:check'),
    VerificationTask(name: 'features', script: 'features:check'),
    VerificationTask(
      name: 'embedded daemon ports',
      script: 'embedded-ports:check',
    ),
  ];

  static const _coverageTasks = <VerificationTask>[
    VerificationTask(
      name: 'Dart coverage',
      script: 'test:coverage:dart',
    ),
    VerificationTask(
      name: 'Flutter coverage',
      script: 'test:coverage:flutter',
    ),
  ];

  /// Fast, non-coverage plan used during development and on non-Linux CI.
  static VerificationPlan fast() => const VerificationPlan(
    phases: <VerificationPhase>[
      _generated,
      VerificationPhase(
        tasks: <VerificationTask>[
          ..._staticTasks,
          VerificationTask(name: 'Dart tests', script: 'test:dart'),
          VerificationTask(name: 'Flutter tests', script: 'test:flutter'),
        ],
      ),
    ],
  );

  /// Full plan in which coverage is the canonical execution of the tests.
  static VerificationPlan full() => const VerificationPlan(
    phases: <VerificationPhase>[
      _generated,
      VerificationPhase(
        tasks: <VerificationTask>[
          ..._staticTasks,
          ..._coverageTasks,
          VerificationTask(name: 'goldens', script: 'test:golden'),
        ],
      ),
      VerificationPhase(
        tasks: <VerificationTask>[
          VerificationTask(
            name: 'coverage thresholds',
            script: 'coverage:check',
          ),
        ],
      ),
    ],
  );

  /// Coverage-only plan used by the focused `test:coverage` command.
  static VerificationPlan coverage() => const VerificationPlan(
    phases: <VerificationPhase>[
      VerificationPhase(tasks: _coverageTasks),
      VerificationPhase(
        tasks: <VerificationTask>[
          VerificationTask(
            name: 'coverage thresholds',
            script: 'coverage:check',
          ),
        ],
      ),
    ],
  );
}
