import 'dart:io';

Future<void> main(List<String> arguments) async {
  final destinationIndex = arguments.indexOf('--destination');
  if (destinationIndex < 0 || destinationIndex + 1 >= arguments.length) {
    stderr.writeln(
      'usage: dart run tool/build_lua_host.dart --destination DIR '
      '[--build-mode debug|release]',
    );
    exitCode = 64;
    return;
  }
  final root = Directory.current.absolute;
  final daemon = Directory('${root.path}/packages/coder_daemon');
  if (!File('${daemon.path}/pubspec.yaml').existsSync()) {
    throw StateError('Run this command from the Coder repository root.');
  }
  final destination = Directory(
    arguments[destinationIndex + 1],
  ).absolute.path;
  final buildModeIndex = arguments.indexOf('--build-mode');
  var buildMode = 'release';
  if (buildModeIndex >= 0 && buildModeIndex + 1 < arguments.length) {
    buildMode = arguments[buildModeIndex + 1];
  }
  final process = await Process.start(
    Platform.resolvedExecutable,
    <String>[
      'run',
      'lua_tool_runtime:stage',
      '--destination',
      destination,
      '--build-mode',
      buildMode,
    ],
    workingDirectory: daemon.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(
      Platform.resolvedExecutable,
      const <String>['run', 'lua_tool_runtime:stage'],
      'Exited with $result',
      result,
    );
  }
}
