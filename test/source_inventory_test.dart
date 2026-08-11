import 'dart:io';

import 'package:test/test.dart';
import 'package:tinest_workspace/src/source_inventory.dart';

void main() {
  test('build output never reaches the formatter', () {
    // The exclusion lives in `.gitignore`, so assert the real pipeline rather
    // than a second copy of the ignore rules: run the command the tool runs and
    // confirm generated build output cannot come back out of it.
    final git = Process.runSync('git', <String>[
      'ls-files',
      '--cached',
      '--others',
      '--exclude-standard',
      '--',
      '*.dart',
    ]);
    expect(git.exitCode, 0, reason: '${git.stderr}');

    final sources = dartSourcesToFormat(
      gitOutput: git.stdout as String,
      workspaceRoot: Directory.current.path,
    );

    expect(sources, contains('lib/src/source_inventory.dart'));
    expect(
      sources.where((path) => path.split('/').contains('build')),
      isEmpty,
      reason: 'Flutter build output must stay out of the formatter.',
    );
  });

  test('only existing Dart files survive, listed once', () {
    final directory = Directory.systemTemp.createTempSync('source-inventory-');
    addTearDown(() => directory.deleteSync(recursive: true));
    _touch(directory, 'lib/src/kept.dart');
    _touch(directory, 'pubspec.yaml');

    final sources = dartSourcesToFormat(
      gitOutput:
          'lib/src/kept.dart\n'
          // `--cached` and `--others` can both list the same path.
          'lib/src/kept.dart\n'
          // Not Dart.
          'pubspec.yaml\n'
          // Staged deletion: still in the index, already gone from disk.
          'lib/src/deleted.dart\n'
          '\n',
      workspaceRoot: directory.path,
    );

    expect(sources, <String>['lib/src/kept.dart']);
  });

  test('paths are chunked so no command line grows unbounded', () {
    final sources = <String>[
      for (var i = 0; i < 450; i += 1) 'lib/file$i.dart',
    ];

    final batches = chunkForCommandLine(sources, batchSize: 200);

    expect(batches.map((batch) => batch.length), <int>[200, 200, 50]);
    expect(batches.expand((batch) => batch), sources);
    expect(chunkForCommandLine(const <String>[], batchSize: 200), isEmpty);
  });
}

void _touch(Directory root, String relativePath) {
  File('${root.path}/$relativePath')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('');
}
