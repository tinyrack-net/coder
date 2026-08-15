import 'dart:async';
import 'dart:io';

import 'package:app/src/devtools/desktop_e2e_runner.dart';
import 'package:app/src/devtools/desktop_host.dart';
import 'package:test/test.dart';

void main() {
  test('desktop hosts map to Flutter devices and Linux alone uses Xvfb', () {
    final linux = DesktopE2ePlan.forHost(DesktopHost.linux);
    final macos = DesktopE2ePlan.forHost(DesktopHost.macos);
    final windows = DesktopE2ePlan.forHost(DesktopHost.windows);
    final lane = windows.lanes(jobs: 1).single;

    expect(linux.commandForLane(lane, seed: 7).executable, 'xvfb-run');
    expect(macos.commandForLane(lane, seed: 7).executable, 'flutter');
    expect(windows.commandForLane(lane, seed: 7).executable, 'flutter');
    expect(windows.commandForLane(lane, seed: 7).runInShell, isTrue);
    expect(macos.commandForLane(lane, seed: 7).runInShell, isFalse);
    expect(
      windows.commandForLane(lane, seed: 7).arguments,
      containsAll(<String>[
        '-d',
        'windows',
        '--test-randomize-ordering-seed=7',
      ]),
    );
    expect(
      linux.commandForLane(lane, seed: 7).arguments,
      isNot(contains('--no-pub')),
      reason: 'clean isolated build directories need plugin symlink bootstrap',
    );
  });

  test('jobs adapt to one or two exact-once deterministic lanes', () {
    for (final jobs in <int>[1, 2, 4, 8, 32]) {
      final plan = DesktopE2ePlan.forHost(DesktopHost.windows);
      final first = plan.lanes(jobs: jobs);
      final second = plan.lanes(jobs: jobs);
      expect(first, hasLength(jobs == 1 ? 1 : 2));
      expect(
        first.expand((lane) => lane.scenarios).map((scenario) => scenario.id),
        unorderedEquals(desktopE2eScenarios.map((scenario) => scenario.id)),
      );
      expect(
        first.map((lane) => lane.scenarios.map((item) => item.id).toList()),
        second.map((lane) => lane.scenarios.map((item) => item.id).toList()),
      );
    }
  });

  test('integration dispatcher registers every catalog scenario once', () {
    final dispatcher = File(
      '../desktop_app/integration_test/desktop_e2e_suite_test.dart',
    ).readAsStringSync();
    for (final scenario in desktopE2eScenarios) {
      expect(
        RegExp("'${RegExp.escape(scenario.id)}':").allMatches(dispatcher),
        hasLength(1),
        reason: scenario.id,
      );
    }
  });

  test('longest scenario is isolated from the remaining measured work', () {
    final lanes = DesktopE2ePlan.forHost(
      DesktopHost.windows,
    ).lanes(jobs: 32);
    expect(lanes.first.scenarios.map((scenario) => scenario.id), <String>[
      'conversation',
    ]);
    expect(lanes.last.estimatedSeconds, 82);
  });

  test('second lane waits for application readiness', () async {
    final runtime = _FakeDesktopE2eRuntime();
    final future = DesktopE2eRunner(runtime: runtime).run(
      DesktopE2ePlan.forHost(DesktopHost.windows),
      jobs: 4,
      seed: 100,
    );
    await Future<void>.delayed(Duration.zero);
    expect(runtime.commands, hasLength(1));

    runtime.processes.first.markReady();
    await Future<void>.delayed(Duration.zero);
    expect(runtime.commands, hasLength(2));
    runtime.processes.first.finish(0);
    runtime.processes.last
      ..markReady()
      ..finish(0);

    final result = await future;
    expect(result.exitCode, 0);
    expect(result.lanes.map((lane) => lane.seed), <int>[100, 101]);
    expect(runtime.deleted, <int>[0, 1]);
  });

  test('early failure still launches and completes the other lane', () async {
    final runtime = _FakeDesktopE2eRuntime();
    final future = DesktopE2eRunner(runtime: runtime).run(
      DesktopE2ePlan.forHost(DesktopHost.windows),
      jobs: 8,
      seed: 9,
    );
    await Future<void>.delayed(Duration.zero);
    runtime.processes.first.finish(69);
    await Future<void>.delayed(Duration.zero);
    expect(runtime.commands, hasLength(2));
    runtime.processes.last
      ..markReady()
      ..finish(70);

    final result = await future;
    expect(result.exitCode, 69);
    expect(result.lanes.map((lane) => lane.exitCode), <int>[69, 70]);
    expect(runtime.deleted, <int>[0, 1]);
  });

  test(
    'lanes use independent home config readiness and build directories',
    () async {
      final runtime = _FakeDesktopE2eRuntime();
      final future = DesktopE2eRunner(runtime: runtime).run(
        DesktopE2ePlan.forHost(DesktopHost.windows),
        jobs: 2,
        seed: 2,
      );
      await Future<void>.delayed(Duration.zero);
      runtime.processes.first.markReady();
      await Future<void>.delayed(Duration.zero);
      for (final process in runtime.processes) {
        process
          ..markReady()
          ..finish(0);
      }
      await future;

      expect(
        runtime.commands.map((command) => command.environment['APPDATA']),
        <String>[r'C:\config\lane-0', r'C:\config\lane-1'],
      );
      expect(
        runtime.commands.map(
          (command) => command.environment['TINYRACK_TINEST_HOME'],
        ),
        <String>[r'C:\home\lane-0', r'C:\home\lane-1'],
      );
    },
  );

  test('macOS Lua host phase is incremental', () {
    final project = File(
      '../desktop_app/macos/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final start = project.indexOf('/* Bundle Lua Host */ = {');
    final end = project.indexOf('\n\t\t};', start);
    final phase = project.substring(start, end);
    expect(phase, isNot(contains('alwaysOutOfDate = 1')));
    expect(phase, contains(r'$(PROJECT_DIR)/../../../pubspec.lock'));
    expect(phase, contains('lua-tool-runtime-host'));
  });
}

final class _FakeDesktopE2eRuntime implements DesktopE2eRuntime {
  final List<DesktopE2eCommand> commands = <DesktopE2eCommand>[];
  final List<_FakeProcess> processes = <_FakeProcess>[];
  final List<int> deleted = <int>[];

  @override
  Future<DesktopE2eLaneResources> createLaneResources(int laneIndex) async =>
      DesktopE2eLaneResources(
        home: 'C:\\home\\lane-$laneIndex',
        configHome: 'C:\\config\\lane-$laneIndex',
        readinessMarker: 'C:\\ready\\lane-$laneIndex',
      );

  @override
  Future<void> deleteLaneResources(DesktopE2eLaneResources resources) async {
    deleted.add(int.parse(resources.home.substring(resources.home.length - 1)));
  }

  @override
  Future<DesktopE2eProcess> start(DesktopE2eCommand command) async {
    commands.add(command);
    final process = _FakeProcess();
    processes.add(process);
    return process;
  }
}

final class _FakeProcess implements DesktopE2eProcess {
  final Completer<void> _ready = Completer<void>();
  final Completer<int> _exitCode = Completer<int>();

  @override
  Future<void> get ready => _ready.future;

  @override
  Future<int> get exitCode => _exitCode.future;

  void markReady() {
    if (!_ready.isCompleted) _ready.complete();
  }

  void finish(int code) {
    if (!_exitCode.isCompleted) _exitCode.complete(code);
  }
}
