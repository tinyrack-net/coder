import 'dart:async';

import 'package:coder_workspace/src/desktop_host.dart';
import 'package:coder_workspace/src/verification_runner.dart';
import 'package:test/test.dart';

void main() {
  test('runs phases in order and tasks within a phase concurrently', () async {
    final executor = _ControlledExecutor();
    final runner = VerificationRunner(executor: executor, maxConcurrency: 2);
    final run = runner.run(
      const VerificationPlan(
        phases: <VerificationPhase>[
          VerificationPhase(
            tasks: <VerificationTask>[
              VerificationTask(name: 'generate', script: 'generate:check'),
            ],
          ),
          VerificationPhase(
            tasks: <VerificationTask>[
              VerificationTask(name: 'analyze', script: 'analyze'),
              VerificationTask(name: 'dart tests', script: 'test:dart'),
              VerificationTask(name: 'flutter tests', script: 'test:flutter'),
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
    expect(
      executor.started,
      <String>['generate', 'analyze', 'dart tests', 'flutter tests'],
    );
    executor
      ..complete('dart tests')
      ..complete('flutter tests');

    final report = await run;
    expect(report.succeeded, isTrue);
    expect(report.results.map((result) => result.task.name), <String>[
      'generate',
      'analyze',
      'dart tests',
      'flutter tests',
    ]);
    expect(executor.maximumActive, 2);
  });

  test('aggregates current-phase failures and skips later phases', () async {
    final executor = _ImmediateExecutor(
      exitCodes: const <String, int>{'analyze': 1, 'tests': 2},
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
                  VerificationTask(name: 'analyze', script: 'analyze'),
                  VerificationTask(name: 'tests', script: 'test:dart'),
                ],
              ),
              VerificationPhase(
                tasks: <VerificationTask>[
                  VerificationTask(name: 'coverage', script: 'coverage:check'),
                ],
              ),
            ],
          ),
        );

    expect(report.succeeded, isFalse);
    expect(
      report.failures.map(
        (failure) => '${failure.task.name}:${failure.exitCode}',
      ),
      <String>['analyze:1', 'tests:2'],
    );
    expect(executor.started, <String>['analyze', 'tests']);
  });

  test('workspace plans keep every canonical test suite single-pass', () {
    final fast = WorkspaceVerificationPlans.fast();
    final linux = WorkspaceVerificationPlans.full(
      hostPlatform: DesktopHost.linux,
    );
    final windows = WorkspaceVerificationPlans.full(
      hostPlatform: DesktopHost.windows,
    );
    final macos = WorkspaceVerificationPlans.full(
      hostPlatform: DesktopHost.macos,
    );
    final coverage = WorkspaceVerificationPlans.coverage();

    expect(_scripts(fast), containsAll(<String>['test:dart', 'test:flutter']));
    expect(
      _scripts(fast).where((script) => script == 'test:dart'),
      hasLength(1),
    );
    expect(
      _scripts(fast).where((script) => script == 'test:flutter'),
      hasLength(1),
    );
    expect(
      _scripts(fast),
      isNot(containsAll(<String>['test:unit', 'test:contract'])),
    );

    expect(
      _scripts(linux),
      containsAll(<String>[
        'test:coverage:dart',
        'test:coverage:flutter',
        'test:golden',
        'coverage:check',
      ]),
    );
    expect(_scripts(linux), isNot(contains('test:dart')));
    expect(_scripts(linux), isNot(contains('test:flutter')));
    final flutterCoveragePhase = linux.phases.indexWhere(
      (phase) => phase.tasks.any(
        (task) => task.script == 'test:coverage:flutter',
      ),
    );
    final goldenPhase = linux.phases.indexWhere(
      (phase) => phase.tasks.any((task) => task.script == 'test:golden'),
    );
    expect(goldenPhase, greaterThan(flutterCoveragePhase));
    expect(_scripts(windows), isNot(contains('test:golden')));
    expect(_scripts(macos), isNot(contains('test:golden')));
    for (final plan in <VerificationPlan>[windows, macos]) {
      expect(
        _scripts(plan),
        containsAll(<String>[
          'test:coverage:dart',
          'test:coverage:flutter',
          'coverage:check',
        ]),
      );
    }
    expect(_scripts(coverage), <String>[
      'test:coverage:dart',
      'test:coverage:flutter',
      'coverage:check',
    ]);
  });

  test('verification host platforms resolve supported desktop systems', () {
    expect(
      DesktopHost.fromOperatingSystem('linux'),
      DesktopHost.linux,
    );
    expect(
      DesktopHost.fromOperatingSystem('macos'),
      DesktopHost.macos,
    );
    expect(
      DesktopHost.fromOperatingSystem('windows'),
      DesktopHost.windows,
    );
    expect(DesktopHost.fromOperatingSystem('android'), isNull);
  });
}

List<String> _scripts(VerificationPlan plan) => <String>[
  for (final phase in plan.phases)
    for (final task in phase.tasks) task.script,
];

final class _ImmediateExecutor implements VerificationTaskExecutor {
  _ImmediateExecutor({required this.exitCodes});

  final Map<String, int> exitCodes;
  final List<String> started = <String>[];

  @override
  Future<VerificationTaskResult> run(VerificationTask task) async {
    started.add(task.name);
    return VerificationTaskResult(
      task: task,
      exitCode: exitCodes[task.name] ?? 0,
      duration: const Duration(seconds: 1),
    );
  }
}

final class _ControlledExecutor implements VerificationTaskExecutor {
  final List<String> started = <String>[];
  final Map<String, Completer<VerificationTaskResult>> _completers =
      <String, Completer<VerificationTaskResult>>{};
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
    _completers[name]!.complete(
      VerificationTaskResult(
        task: VerificationTask(name: name, script: name),
        exitCode: 0,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
