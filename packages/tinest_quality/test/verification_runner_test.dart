import 'dart:async';

import 'package:test/test.dart';
import 'package:tinest_quality/src/verification_runner.dart';

const _task = VerificationTask(
  name: 'task',
  executable: 'dart',
  arguments: <String>['test'],
);

void main() {
  test('runs phases in order and tasks within a phase concurrently', () async {
    final executor = _ControlledExecutor();
    final run = VerificationRunner(executor: executor, maxConcurrency: 2).run(
      const VerificationPlan(
        phases: <VerificationPhase>[
          VerificationPhase(
            tasks: <VerificationTask>[
              VerificationTask(
                name: 'generate',
                executable: 'dart',
                arguments: <String>['run', 'generator'],
              ),
            ],
          ),
          VerificationPhase(
            tasks: <VerificationTask>[
              VerificationTask(
                name: 'analyze',
                executable: 'dart',
                arguments: <String>['analyze'],
              ),
              VerificationTask(
                name: 'dart tests',
                executable: 'dart',
                arguments: <String>['test'],
              ),
              VerificationTask(
                name: 'flutter tests',
                executable: 'flutter',
                arguments: <String>['test'],
              ),
            ],
          ),
        ],
      ),
    );

    expect(executor.started, <String>['generate']);
    executor.complete('generate');
    await pumpEventQueue();
    expect(executor.started, <String>['generate', 'analyze', 'dart tests']);
    executor.complete('analyze');
    await pumpEventQueue();
    expect(executor.started.last, 'flutter tests');
    executor
      ..complete('dart tests')
      ..complete('flutter tests');

    final report = await run;
    expect(report.succeeded, isTrue);
    expect(executor.maximumActive, 2);
  });

  test('aggregates current-phase failures and skips later phases', () async {
    final executor = _ImmediateExecutor(
      const <String, int>{'analyze': 1, 'tests': 2},
    );
    final report =
        await VerificationRunner(
          executor: executor,
          maxConcurrency: 4,
        ).run(
          const VerificationPlan(
            phases: <VerificationPhase>[
              VerificationPhase(
                tasks: <VerificationTask>[
                  VerificationTask(
                    name: 'analyze',
                    executable: 'dart',
                    arguments: <String>['analyze'],
                  ),
                  VerificationTask(
                    name: 'tests',
                    executable: 'dart',
                    arguments: <String>['test'],
                  ),
                ],
              ),
              VerificationPhase(tasks: <VerificationTask>[_task]),
            ],
          ),
        );

    expect(report.succeeded, isFalse);
    expect(report.failures.map((failure) => failure.exitCode), <int>[1, 2]);
    expect(executor.started, <String>['analyze', 'tests']);
  });

  test('canonical plans run each suite once on every host', () {
    final tests = WorkspaceVerificationPlans.tests();
    final full = WorkspaceVerificationPlans.full();

    expect(
      _commands(tests).where((value) => value.contains('_test-dart')),
      hasLength(1),
    );
    expect(
      _commands(tests).where((value) => value.contains('_test-flutter')),
      hasLength(1),
    );
    expect(
      _commands(full).where((value) => value.contains('_coverage-dart')),
      hasLength(1),
    );
    expect(
      _commands(full).where((value) => value.contains('_coverage-flutter')),
      hasLength(1),
    );
    expect(_commands(full).any((value) => value.contains('_golden')), isFalse);
    expect(
      _commands(full).singleWhere((value) => value.contains('coverage-check')),
      allOf(contains('--line=90'), contains('--branch=80')),
    );
  });
}

List<String> _commands(VerificationPlan plan) => <String>[
  for (final phase in plan.phases)
    for (final task in phase.tasks)
      '${task.executable} ${task.arguments.join(' ')}',
];

final class _ImmediateExecutor implements VerificationTaskExecutor {
  _ImmediateExecutor(this.exitCodes);

  final Map<String, int> exitCodes;
  final List<String> started = <String>[];

  @override
  Future<VerificationTaskResult> run(VerificationTask task) async {
    started.add(task.name);
    return VerificationTaskResult(
      task: task,
      exitCode: exitCodes[task.name] ?? 0,
      duration: Duration.zero,
    );
  }
}

final class _ControlledExecutor implements VerificationTaskExecutor {
  final List<String> started = <String>[];
  final Map<String, Completer<VerificationTaskResult>> _completers = {};
  var _active = 0;
  int maximumActive = 0;

  @override
  Future<VerificationTaskResult> run(VerificationTask task) {
    started.add(task.name);
    _active += 1;
    if (_active > maximumActive) maximumActive = _active;
    final completer = Completer<VerificationTaskResult>();
    _completers[task.name] = completer;
    return completer.future.whenComplete(() => _active -= 1);
  }

  void complete(String name) {
    final task = VerificationTask(
      name: name,
      executable: 'dart',
      arguments: const <String>[],
    );
    _completers[name]!.complete(
      VerificationTaskResult(
        task: task,
        exitCode: 0,
        duration: Duration.zero,
      ),
    );
  }
}
