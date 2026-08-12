import 'dart:async';
import 'dart:io';

import 'package:app/src/devtools/desktop_e2e_runner.dart';
import 'package:app/src/devtools/desktop_host.dart';
import 'package:app/src/devtools/io_windows_build_environment.dart';
import 'package:app/src/devtools/windows_build_environment.dart';

Future<void> main() async {
  final host = DesktopHost.fromOperatingSystem(Platform.operatingSystem);
  if (host == null) {
    stderr.writeln(
      'Desktop E2E supports only Linux, macOS, and Windows; '
      'found ${Platform.operatingSystem}.',
    );
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
  final result = await DesktopE2eRunner(
    runtime: const _IoDesktopE2eRuntime(),
    environment: environment,
  ).run(DesktopE2ePlan.forHost(host));
  if (result != 0) exitCode = result;
}

final class _IoDesktopE2eRuntime implements DesktopE2eRuntime {
  const _IoDesktopE2eRuntime();

  @override
  Future<String> createTemporaryHome() async =>
      (await Directory.systemTemp.createTemp('tinest-e2e-home-')).path;

  @override
  Future<void> deleteTemporaryHome(String path) async {
    final directory = Directory(path);
    for (var attempt = 0; attempt < 20; attempt += 1) {
      if (!directory.existsSync()) return;
      try {
        await directory.delete(recursive: true);
        return;
      } on FileSystemException {
        if (attempt == 19) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  @override
  Future<int> run(DesktopE2eCommand command) async {
    stdout.writeln(
      'Running Desktop E2E shard on ${Platform.operatingSystem}: '
      '${command.arguments.firstWhere(
        (argument) => argument.endsWith('_test.dart'),
      )}',
    );
    final process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: command.workingDirectory,
      environment: command.environment,
      mode: ProcessStartMode.inheritStdio,
      runInShell: command.runInShell,
    );
    final result = await process.exitCode;
    if (result != 0) {
      stderr.writeln('Desktop E2E shard failed with exit code $result.');
    }
    return result;
  }
}
