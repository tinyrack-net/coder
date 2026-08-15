import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/testing/devtools/desktop_e2e_runner.dart';
import 'package:app/testing/devtools/desktop_host.dart';
import 'package:app/testing/devtools/io_windows_build_environment.dart';
import 'package:app/testing/devtools/windows_build_environment.dart';

import 'src/desktop_e2e_cli.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runDesktopE2eCli(
    arguments,
    detectedJobs: Platform.numberOfProcessors,
    defaultSeed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
    execute: _runDesktopE2e,
  );
}

Future<int> _runDesktopE2e(DesktopE2eOptions options) async {
  final host = DesktopHost.fromOperatingSystem(Platform.operatingSystem);
  if (host == null) {
    stderr.writeln('Desktop E2E does not support ${Platform.operatingSystem}.');
    return 64;
  }

  late final Map<String, String> environment;
  try {
    environment = await resolveWindowsBuildEnvironment();
  } on WindowsBuildToolsException catch (error) {
    stderr.writeln(error);
    return 78;
  }

  final stopwatch = Stopwatch()..start();
  final result =
      await DesktopE2eRunner(
        runtime: const _IoDesktopE2eRuntime(),
        environment: environment,
      ).run(
        DesktopE2ePlan.forHost(host),
        jobs: options.jobs,
        seed: options.seed,
        scenario: options.scenario,
      );
  stopwatch.stop();
  if (options.reportPath case final reportPath?) {
    final reportFile = File(reportPath);
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, Object>{
        'host': Platform.operatingSystem,
        'detectedJobs': Platform.numberOfProcessors,
        'jobs': options.jobs,
        'scenario': ?options.scenario,
        'seed': options.seed,
        'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
        'exitCode': result.exitCode,
        'slotUtilization': stopwatch.elapsedMilliseconds == 0
            ? 0.0
            : result.lanes.fold<int>(
                    0,
                    (total, lane) => total + lane.elapsed.inMilliseconds,
                  ) /
                  (stopwatch.elapsedMilliseconds * result.lanes.length),
        'lanes': <Object>[
          for (final lane in result.lanes)
            <String, Object?>{
              'index': lane.lane.index,
              'scenarios': lane.lane.scenarios
                  .map((scenario) => scenario.id)
                  .toList(growable: false),
              'estimatedSeconds': lane.lane.estimatedSeconds,
              'seed': lane.seed,
              'readyMilliseconds': lane.readyAfter?.inMilliseconds,
              'elapsedMilliseconds': lane.elapsed.inMilliseconds,
              'exitCode': lane.exitCode,
            },
        ],
      }),
    );
  }
  return result.exitCode;
}

final class _IoDesktopE2eRuntime implements DesktopE2eRuntime {
  const _IoDesktopE2eRuntime();

  @override
  Future<DesktopE2eBuildLease> acquireProjectBuildLease(
    String projectDirectory,
  ) => _acquireBuildLease(projectDirectory, 'project');

  @override
  Future<DesktopE2eBuildLease> acquireLaneBuildLease(
    String projectDirectory,
    int laneIndex,
  ) => _acquireBuildLease(
    projectDirectory,
    desktopE2eWindowsLaneBuildPath(laneIndex),
  );

  Future<DesktopE2eBuildLease> _acquireBuildLease(
    String projectDirectory,
    String resource,
  ) async {
    final projectPath = Directory(projectDirectory).absolute.path.toLowerCase();
    final lockKey = '$projectPath|$resource';
    final lockFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'tinest-desktop-e2e-${_stablePathHash(lockKey)}.lock',
    );
    final handle = await lockFile.open(mode: FileMode.append);
    try {
      await handle.lock();
      return _IoDesktopE2eBuildLease(handle);
    } catch (_) {
      await handle.close();
      rethrow;
    }
  }

  @override
  Future<void> prepareWindowsBuild(
    String projectDirectory,
    int laneIndex,
  ) async {
    final project = Directory(projectDirectory).absolute;
    final wrapper = Directory(
      '${project.path}${Platform.pathSeparator}windows'
      '${Platform.pathSeparator}flutter${Platform.pathSeparator}ephemeral'
      '${Platform.pathSeparator}cpp_client_wrapper',
    );
    final generatedStateIsComplete = desktopE2eWindowsGeneratedSources.every(
      (name) =>
          File('${wrapper.path}${Platform.pathSeparator}$name').existsSync(),
    );
    if (generatedStateIsComplete) return;

    final relativeLanePath = desktopE2eWindowsLaneBuildPath(
      laneIndex,
    ).replaceAll('/', Platform.pathSeparator);
    final laneWindows = Directory(
      '${project.path}${Platform.pathSeparator}$relativeLanePath',
    ).absolute;
    final projectPrefix = '${project.path}${Platform.pathSeparator}';
    if (!laneWindows.path.startsWith(projectPrefix)) {
      throw StateError('Windows E2E build path escaped the desktop project.');
    }
    if (laneWindows.existsSync()) {
      await laneWindows.delete(recursive: true);
    }
  }

  @override
  Future<DesktopE2eLaneResources> createLaneResources(int laneIndex) async {
    final root = await Directory.systemTemp.createTemp(
      'tinest-e2e-lane-$laneIndex-',
    );
    final home = Directory('${root.path}${Platform.pathSeparator}home');
    final config = Directory('${root.path}${Platform.pathSeparator}config');
    await home.create();
    await config.create();
    final settings = Platform.isWindows
        ? File('${config.path}${Platform.pathSeparator}.flutter_settings')
        : File(
            '${config.path}${Platform.pathSeparator}flutter'
            '${Platform.pathSeparator}settings',
          );
    await settings.parent.create(recursive: true);
    await settings.writeAsString(
      jsonEncode(<String, String>{'build-dir': 'build/e2e/lane-$laneIndex'}),
    );
    return DesktopE2eLaneResources(
      home: home.path,
      configHome: config.path,
      readinessMarker: '${root.path}${Platform.pathSeparator}application.ready',
    );
  }

  @override
  Future<void> deleteLaneResources(DesktopE2eLaneResources resources) async {
    final root = Directory(resources.home).parent;
    for (var attempt = 0; attempt < 20; attempt += 1) {
      if (!root.existsSync()) return;
      try {
        await root.delete(recursive: true);
        return;
      } on FileSystemException {
        if (attempt == 19) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  @override
  Future<DesktopE2eProcess> start(DesktopE2eCommand command) async {
    stdout.writeln('Desktop E2E: ${command.arguments.join(' ')}');
    final process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: command.workingDirectory,
      environment: command.environment,
      mode: ProcessStartMode.inheritStdio,
      runInShell: command.runInShell,
    );
    return _IoDesktopE2eProcess(
      process: process,
      readinessMarker: command.environment['TINYRACK_TINEST_E2E_READY_FILE']!,
    );
  }
}

final class _IoDesktopE2eBuildLease implements DesktopE2eBuildLease {
  _IoDesktopE2eBuildLease(this._handle);

  RandomAccessFile? _handle;

  @override
  Future<void> release() async {
    final handle = _handle;
    if (handle == null) return;
    _handle = null;
    try {
      await handle.unlock();
    } finally {
      await handle.close();
    }
  }
}

String _stablePathHash(String value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

final class _IoDesktopE2eProcess implements DesktopE2eProcess {
  _IoDesktopE2eProcess({
    required Process process,
    required String readinessMarker,
  }) : exitCode = process.exitCode,
       ready = _waitForMarker(process.exitCode, readinessMarker);

  @override
  final Future<int> exitCode;

  @override
  final Future<void> ready;

  static Future<void> _waitForMarker(
    Future<int> processExit,
    String markerPath,
  ) async {
    final marker = File(markerPath);
    if (marker.existsSync()) return;
    final completer = Completer<void>();
    late final StreamSubscription<FileSystemEvent> subscription;
    subscription = marker.parent.watch().listen((event) {
      if (!completer.isCompleted && marker.existsSync()) completer.complete();
    }, onError: completer.completeError);
    unawaited(
      processExit.then<void>((_) {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Desktop app exited before readiness.'),
          );
        }
      }),
    );
    try {
      await completer.future;
    } finally {
      await subscription.cancel();
    }
  }
}
