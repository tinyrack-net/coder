import 'dart:io';

import 'package:tinest_workspace/src/source_inventory.dart';

/// Formats every Dart source Git tracks or does not ignore.
///
/// `dart format .` would also walk generated Flutter build output under
/// `build/`, which the formatter has no flag to exclude. Running
/// `dart run melos verify` right after `dart run melos verify:debug` then
/// failed on third-party sources the E2E build had just written.
Future<void> main(List<String> arguments) async {
  final check = arguments.contains('--check');
  if (arguments.any((argument) => argument != '--check')) {
    stderr.writeln('Usage: dart run tool/format_sources.dart [--check]');
    exitCode = 64;
    return;
  }

  final git = await Process.run('git', <String>[
    'ls-files',
    '--cached',
    '--others',
    '--exclude-standard',
    '--',
    '*.dart',
  ]);
  if (git.exitCode != 0) {
    stderr.writeln('git ls-files failed: ${git.stderr}');
    exitCode = git.exitCode;
    return;
  }

  final sources = dartSourcesToFormat(
    gitOutput: git.stdout as String,
    workspaceRoot: Directory.current.path,
  );
  if (sources.isEmpty) {
    stdout.writeln('No Dart sources to format.');
    return;
  }

  // Batching is an argument-length detail, so keep reporting every offending
  // file the way a single `dart format` run would instead of stopping early.
  var failure = 0;
  for (final batch in chunkForCommandLine(sources, batchSize: 200)) {
    final result = await Process.run('dart', <String>[
      'format',
      if (check) ...<String>['--output=none', '--set-exit-if-changed'],
      ...batch,
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) failure = result.exitCode;
  }
  if (failure != 0) {
    exitCode = failure;
    return;
  }
  stdout.writeln('Formatted ${sources.length} Dart sources.');
}
