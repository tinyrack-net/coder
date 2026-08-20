import 'dart:io';

import 'package:test/test.dart';

import 'temporary_directory.dart';

void main() {
  test('a clean directory reports nothing locked', () async {
    final directory = await Directory.systemTemp.createTemp('lock-report-');
    addTearDown(() => _discard(directory));
    File('${directory.path}/plain.bin').writeAsStringSync('x');

    expect(
      describeUndeletableEntries(directory),
      'no entry refused deletion individually',
    );
  });

  test('an open handle is named on the platform that holds one', () async {
    final directory = await Directory.systemTemp.createTemp('lock-report-');
    addTearDown(() => _discard(directory));
    final file = File('${directory.path}/held.bin')..writeAsStringSync('x');
    final handle = await file.open(mode: FileMode.write);
    addTearDown(handle.close);

    final report = describeUndeletableEntries(directory);

    // Asserted on both platforms rather than skipped, because the two answers
    // are the contract: Windows pins an open file and POSIX unlinks it.
    if (Platform.isWindows) {
      expect(report, startsWith('entries still locked:'));
      expect(report, contains('held.bin'));
    } else {
      expect(report, 'no entry refused deletion individually');
    }
  });

  test('a deletable directory still goes away', () async {
    final directory = await Directory.systemTemp.createTemp('lock-report-');
    File('${directory.path}/plain.bin').writeAsStringSync('x');

    await deleteTemporaryDirectory(directory);

    expect(directory.existsSync(), isFalse);
  });

  test('deleting an absent directory is not an error', () async {
    final directory = await Directory.systemTemp.createTemp('lock-report-');
    await directory.delete(recursive: true);

    await expectLater(deleteTemporaryDirectory(directory), completes);
  });
}

Future<void> _discard(Directory directory) async {
  try {
    await directory.delete(recursive: true);
  } on FileSystemException {
    // The test that holds a handle cannot remove it on Windows until the
    // handle closes, and the OS reclaims the temporary tree regardless.
  }
}
