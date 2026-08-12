import 'dart:async';

import 'package:app/src/devtools/desktop_host.dart';

/// One independently runnable desktop E2E scenario.
final class DesktopE2eScenario {
  /// Creates a catalog entry.
  const DesktopE2eScenario({
    required this.id,
    required this.estimatedSeconds,
  });

  /// Stable command-line identifier.
  final String id;

  /// Measured warm runtime used for deterministic lane balancing.
  final int estimatedSeconds;
}

/// The complete app-owned desktop E2E catalog.
const desktopE2eScenarios = <DesktopE2eScenario>[
  DesktopE2eScenario(id: 'daemon-workspace', estimatedSeconds: 17),
  DesktopE2eScenario(id: 'project-worktree', estimatedSeconds: 12),
  DesktopE2eScenario(id: 'relay', estimatedSeconds: 1),
  DesktopE2eScenario(id: 'conversation-adversity', estimatedSeconds: 6),
  DesktopE2eScenario(id: 'conversation', estimatedSeconds: 84),
  DesktopE2eScenario(id: 'provider', estimatedSeconds: 12),
  DesktopE2eScenario(id: 'settings-desktop', estimatedSeconds: 18),
  DesktopE2eScenario(id: 'remote-bootstrap', estimatedSeconds: 2),
  DesktopE2eScenario(id: 'desktop-shell', estimatedSeconds: 2),
];

/// Typed command-line options for the app-owned E2E runner.
final class DesktopE2eOptions {
  /// Creates parsed options.
  const DesktopE2eOptions({
    required this.jobs,
    required this.seed,
    this.scenario,
    this.reportPath,
  });

  /// Global CPU budget requested by the caller.
  final int jobs;

  /// Concrete randomized test-order seed.
  final int seed;

  /// Optional focused catalog scenario.
  final String? scenario;

  /// Optional JSON timing report path.
  final String? reportPath;
}

/// One deterministic subset of the scenario catalog.
final class DesktopE2eLane {
  /// Creates a lane.
  const DesktopE2eLane({required this.index, required this.scenarios});

  /// Zero-based stable lane index.
  final int index;

  /// Scenarios assigned to this lane in catalog order.
  final List<DesktopE2eScenario> scenarios;

  /// Total measured weight assigned to the lane.
  int get estimatedSeconds => scenarios.fold<int>(
    0,
    (total, scenario) => total + scenario.estimatedSeconds,
  );
}

/// One process invocation in a desktop E2E run.
final class DesktopE2eCommand {
  /// Creates a process invocation.
  const DesktopE2eCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    this.environment = const <String, String>{},
    this.runInShell = false,
  });

  /// Executable passed to the process runtime.
  final String executable;

  /// Ordered command arguments.
  final List<String> arguments;

  /// Directory from which the command starts.
  final String workingDirectory;

  /// Environment overrides for the child process.
  final Map<String, String> environment;

  /// Whether the host shell resolves the executable.
  final bool runInShell;

  /// Returns this command with the supplied environment overrides.
  DesktopE2eCommand withEnvironment(Map<String, String> value) =>
      DesktopE2eCommand(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: value,
        runInShell: runInShell,
      );
}

/// Platform-specific command plan for the complete desktop E2E suite.
final class DesktopE2ePlan {
  const DesktopE2ePlan._({required this.host, required this.device});

  /// Creates a plan for [host].
  factory DesktopE2ePlan.forHost(DesktopHost host) =>
      DesktopE2ePlan._(host: host, device: host.name);

  /// Host operating system.
  final DesktopHost host;

  /// Flutter desktop device identifier.
  final String device;

  /// Partitions scenarios with deterministic longest-processing-time packing.
  List<DesktopE2eLane> lanes({required int jobs}) {
    final laneCount = jobs <= 1 ? 1 : 2;
    final assignments = List.generate(
      laneCount,
      (_) => <DesktopE2eScenario>[],
      growable: false,
    );
    final totals = List<int>.filled(laneCount, 0);
    final ordered = [...desktopE2eScenarios]
      ..sort((left, right) {
        final byDuration = right.estimatedSeconds.compareTo(
          left.estimatedSeconds,
        );
        return byDuration != 0 ? byDuration : left.id.compareTo(right.id);
      });
    for (final scenario in ordered) {
      var target = 0;
      for (var index = 1; index < laneCount; index += 1) {
        if (totals[index] < totals[target]) target = index;
      }
      assignments[target].add(scenario);
      totals[target] += scenario.estimatedSeconds;
    }
    return <DesktopE2eLane>[
      for (var index = 0; index < laneCount; index += 1)
        DesktopE2eLane(
          index: index,
          scenarios: <DesktopE2eScenario>[
            for (final scenario in desktopE2eScenarios)
              if (assignments[index].contains(scenario)) scenario,
          ],
        ),
    ];
  }

  /// Builds the aggregate process command for [lane].
  DesktopE2eCommand commandForLane(
    DesktopE2eLane lane, {
    required int seed,
  }) => commandForScenarioIds(
    lane.scenarios.map((scenario) => scenario.id).toList(growable: false),
    seed: seed,
  );

  /// Builds a focused CI command.
  DesktopE2eCommand commandForScenario(String scenarioId, {required int seed}) {
    if (!desktopE2eScenarios.any((scenario) => scenario.id == scenarioId)) {
      throw ArgumentError.value(scenarioId, 'scenarioId', 'unknown scenario');
    }
    return commandForScenarioIds(<String>[scenarioId], seed: seed);
  }

  /// Builds an aggregate command containing [scenarioIds].
  DesktopE2eCommand commandForScenarioIds(
    List<String> scenarioIds, {
    required int seed,
  }) {
    final flutterArguments = <String>[
      '--suppress-analytics',
      'test',
      'integration_test/desktop_e2e_suite_test.dart',
      '-d',
      device,
      '--test-randomize-ordering-seed=$seed',
      '--dart-define=TINEST_E2E_SCENARIOS=${scenarioIds.join(',')}',
    ];
    return DesktopE2eCommand(
      executable: host == DesktopHost.linux ? 'xvfb-run' : 'flutter',
      arguments: host == DesktopHost.linux
          ? <String>['-a', 'flutter', ...flutterArguments]
          : flutterArguments,
      workingDirectory: 'packages/app',
      runInShell: host == DesktopHost.windows,
    );
  }
}

/// Temporary, isolated resources owned by one lane.
final class DesktopE2eLaneResources {
  /// Creates lane resources.
  const DesktopE2eLaneResources({
    required this.home,
    required this.configHome,
    required this.readinessMarker,
  });

  /// Isolated Tinest home.
  final String home;

  /// Isolated Flutter configuration home.
  final String configHome;

  /// Application readiness marker path.
  final String readinessMarker;
}

/// A started Flutter process with an application-level readiness signal.
abstract interface class DesktopE2eProcess {
  /// Completes when the native app writes its readiness marker.
  Future<void> get ready;

  /// Completes when Flutter exits.
  Future<int> get exitCode;
}

/// Runtime boundary for filesystem and process operations used by E2E.
abstract interface class DesktopE2eRuntime {
  /// Creates temporary resources for [laneIndex].
  Future<DesktopE2eLaneResources> createLaneResources(int laneIndex);

  /// Starts [command] without waiting for its exit.
  Future<DesktopE2eProcess> start(DesktopE2eCommand command);

  /// Deletes resources after the lane process exits.
  Future<void> deleteLaneResources(DesktopE2eLaneResources resources);
}

/// Result of one lane.
final class DesktopE2eLaneResult {
  /// Creates a lane result.
  const DesktopE2eLaneResult({
    required this.lane,
    required this.seed,
    required this.exitCode,
    required this.elapsed,
    required this.readyAfter,
  });

  /// Executed lane.
  final DesktopE2eLane lane;

  /// Concrete randomized test-order seed.
  final int seed;

  /// Flutter process exit code.
  final int exitCode;

  /// Total build and runtime duration.
  final Duration elapsed;

  /// Duration until the native app signaled readiness, when reached.
  final Duration? readyAfter;
}

/// Complete deterministic run result.
final class DesktopE2eRunResult {
  /// Creates a run result.
  const DesktopE2eRunResult(this.lanes);

  /// Results in deterministic lane order.
  final List<DesktopE2eLaneResult> lanes;

  /// First non-zero exit code in stable lane order.
  int get exitCode => lanes
      .map((lane) => lane.exitCode)
      .firstWhere((code) => code != 0, orElse: () => 0);
}

/// Runs up to two staggered, isolated desktop E2E lanes.
final class DesktopE2eRunner {
  /// Creates a runner backed by [runtime].
  const DesktopE2eRunner({
    required this.runtime,
    this.environment = const <String, String>{},
  });

  /// Filesystem and process boundary.
  final DesktopE2eRuntime runtime;

  /// Host build-tool environment inherited by every lane.
  final Map<String, String> environment;

  /// Runs a focused scenario or the adaptive local lane plan.
  Future<DesktopE2eRunResult> run(
    DesktopE2ePlan plan, {
    required int jobs,
    required int seed,
    String? scenario,
  }) async {
    final lanes = scenario == null
        ? plan.lanes(jobs: jobs)
        : <DesktopE2eLane>[
            DesktopE2eLane(
              index: 0,
              scenarios: <DesktopE2eScenario>[
                desktopE2eScenarios.singleWhere((item) => item.id == scenario),
              ],
            ),
          ];
    final running = <Future<DesktopE2eLaneResult>>[];
    final first = await _startLane(plan, lanes.first, seed);
    running.add(first.result);
    if (lanes.length > 1) {
      await Future.any<void>(<Future<void>>[
        first.process.ready.then<void>((_) {}, onError: (_) {}),
        first.process.exitCode.then<void>((_) {}),
      ]);
      running.add((await _startLane(plan, lanes[1], seed + 1)).result);
    }
    final results = await Future.wait(running);
    results.sort((left, right) => left.lane.index.compareTo(right.lane.index));
    return DesktopE2eRunResult(results);
  }

  Future<_RunningLane> _startLane(
    DesktopE2ePlan plan,
    DesktopE2eLane lane,
    int seed,
  ) async {
    final resources = await runtime.createLaneResources(lane.index);
    final stopwatch = Stopwatch()..start();
    final command = plan.commandForLane(lane, seed: seed).withEnvironment(
      <String, String>{
        ...environment,
        'TINYRACK_TINEST_HOME': resources.home,
        'TINYRACK_TINEST_ALLOW_MULTIPLE_INSTANCES': '1',
        'TINYRACK_TINEST_E2E_READY_FILE': resources.readinessMarker,
        if (plan.host == DesktopHost.windows) 'APPDATA': resources.configHome,
        if (plan.host != DesktopHost.windows)
          'XDG_CONFIG_HOME': resources.configHome,
      },
    );
    try {
      final process = await runtime.start(command);
      final readyAt = Completer<Duration?>();
      unawaited(
        process.ready.then<void>(
          (_) {
            if (!readyAt.isCompleted) readyAt.complete(stopwatch.elapsed);
          },
          onError: (_) {
            if (!readyAt.isCompleted) readyAt.complete(null);
          },
        ),
      );
      final result = () async {
        try {
          final exitCode = await process.exitCode;
          if (!readyAt.isCompleted) readyAt.complete(null);
          return DesktopE2eLaneResult(
            lane: lane,
            seed: seed,
            exitCode: exitCode,
            elapsed: stopwatch.elapsed,
            readyAfter: await readyAt.future,
          );
        } finally {
          stopwatch.stop();
          await runtime.deleteLaneResources(resources);
        }
      }();
      return _RunningLane(process: process, result: result);
    } catch (_) {
      stopwatch.stop();
      await runtime.deleteLaneResources(resources);
      rethrow;
    }
  }
}

final class _RunningLane {
  const _RunningLane({required this.process, required this.result});

  final DesktopE2eProcess process;
  final Future<DesktopE2eLaneResult> result;
}
