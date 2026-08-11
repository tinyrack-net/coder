import 'dart:io';

import 'package:tinest_workspace/src/desktop_host.dart';
import 'package:tinest_workspace/src/verification_runner.dart';
import 'package:tinest_workspace/src/windows_build_environment.dart';

import 'support/windows_build_environment.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.length > 2) {
    _usage();
    exitCode = 64;
    return;
  }
  final profile = arguments.first;
  final hostPlatform = DesktopHost.fromOperatingSystem(
    Platform.operatingSystem,
  );
  final jobsArgument = arguments.where(
    (argument) => argument.startsWith('--jobs='),
  );
  final jobs = jobsArgument.isEmpty
      ? 4
      : int.tryParse(jobsArgument.single.substring('--jobs='.length));
  if (jobs == null ||
      jobs < 1 ||
      arguments
          .skip(1)
          .any(
            (argument) => !argument.startsWith('--jobs='),
          )) {
    _usage();
    exitCode = 64;
    return;
  }
  final plan = switch (profile) {
    'fast' => WorkspaceVerificationPlans.fast(),
    'full' when hostPlatform != null => WorkspaceVerificationPlans.full(
      hostPlatform: hostPlatform,
    ),
    'coverage' => WorkspaceVerificationPlans.coverage(),
    _ => null,
  };
  if (plan == null) {
    if (profile == 'full' && hostPlatform == null) {
      stderr.writeln(
        'Full verification is supported only on Linux, macOS, and Windows; '
        'found ${Platform.operatingSystem}.',
      );
    }
    _usage();
    exitCode = 64;
    return;
  }

  late final Map<String, String> environment;
  try {
    environment = await resolveWindowsBuildEnvironment();
  } on WindowsBuildToolsException catch (error) {
    stderr.writeln(error);
    exitCode = 78;
    return;
  }
  final report = await VerificationRunner(
    executor: _ProcessTaskExecutor(environment: environment),
    maxConcurrency: jobs,
  ).run(plan);
  stdout.writeln('\nVerification summary:');
  for (final result in report.results) {
    final status = result.succeeded ? 'PASS' : 'FAIL';
    stdout.writeln(
      '  $status ${result.task.name} '
      '(${result.duration.inMilliseconds / 1000}s, exit ${result.exitCode})',
    );
  }
  if (!report.succeeded) exitCode = 1;
}

void _usage() {
  stderr.writeln(
    'Usage: dart run tool/verify_workspace.dart '
    '<fast|full|coverage> [--jobs=N]',
  );
}

final class _ProcessTaskExecutor implements VerificationTaskExecutor {
  const _ProcessTaskExecutor({required this.environment});

  final Map<String, String> environment;

  @override
  Future<VerificationTaskResult> run(VerificationTask task) async {
    stdout.writeln('\n[${task.name}] dart run melos ${task.script}');
    final stopwatch = Stopwatch()..start();
    try {
      final process = await Process.start(
        'dart',
        <String>['run', 'melos', task.script],
        environment: environment,
        mode: ProcessStartMode.inheritStdio,
      );
      final processExitCode = await process.exitCode;
      stopwatch.stop();
      return VerificationTaskResult(
        task: task,
        exitCode: processExitCode,
        duration: stopwatch.elapsed,
      );
    } on ProcessException catch (error) {
      stopwatch.stop();
      stderr.writeln('[${task.name}] $error');
      return VerificationTaskResult(
        task: task,
        exitCode: 127,
        duration: stopwatch.elapsed,
      );
    }
  }
}
