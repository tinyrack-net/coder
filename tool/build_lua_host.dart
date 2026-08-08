import 'dart:io';

Future<void> main(List<String> arguments) async {
  final destinationIndex = arguments.indexOf('--destination');
  if (destinationIndex < 0 || destinationIndex + 1 >= arguments.length) {
    stderr.writeln(
      'usage: dart run tool/build_lua_host.dart --destination DIR '
      '[--build-mode debug|release] [--cmake-executable PATH] '
      '[--build-directory DIR]',
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
  final cmakeExecutable = _value(arguments, '--cmake-executable');
  final buildDirectory = _value(arguments, '--build-directory');
  final stageArguments = <String>[
    'run',
    'lua_tool_runtime:stage',
    '--destination',
    destination,
    '--build-mode',
    buildMode,
    if (cmakeExecutable != null) ...[
      '--cmake-executable',
      cmakeExecutable,
    ],
    if (buildDirectory != null) ...['--build-directory', buildDirectory],
  ];
  final process = await Process.start(
    Platform.resolvedExecutable,
    stageArguments,
    workingDirectory: daemon.path,
    mode: ProcessStartMode.inheritStdio,
  );
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(
      Platform.resolvedExecutable,
      stageArguments,
      'Exited with $result',
      result,
    );
  }
}

String? _value(List<String> arguments, String flag) {
  final index = arguments.indexOf(flag);
  return index >= 0 && index + 1 < arguments.length
      ? arguments[index + 1]
      : null;
}
