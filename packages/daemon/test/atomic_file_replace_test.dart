import 'dart:io';

import 'package:test/test.dart';

/// Deleting a file before renaming over it, guarded to Windows.
///
/// Written to match the whole statement rather than the call alone so that an
/// unrelated `delete` on a path nothing is about to replace does not trip it.
final _deleteBeforeRename = RegExp(
  r'Platform\.isWindows[^\n]*\bdelete(?:Sync)?\(',
);

void main() {
  test('a configuration write replaces its file instead of clearing it', () {
    // `File.rename` removes an existing destination itself, on every platform
    // this daemon runs on. Deleting first buys nothing and costs twice:
    //
    // 1. The delete fails outright while anything else holds a handle to the
    //    file. On Windows that includes the scanner that reads every file the
    //    moment it is created, so a store that writes twice in quick
    //    succession — a token and then a key, at daemon startup — throws
    //    `PathAccessException: The process cannot access the file because it
    //    is being used by another process` and takes the daemon down with it.
    // 2. Between the delete and the rename the file does not exist. A process
    //    that dies in that window has not written the new credentials; it has
    //    destroyed the old ones.
    final offenders = <String>[];
    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        if (!_deleteBeforeRename.hasMatch(lines[index])) continue;
        // Only a delete that a rename is about to make redundant. A following
        // line is enough: these writes are `delete` then `rename`, never with
        // anything in between.
        final next = index + 1 < lines.length ? lines[index + 1] : '';
        if (!next.contains('.rename(')) continue;
        offenders.add('${entity.path}:${index + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these writes delete their destination before renaming over it, '
          'which throws under a concurrent handle and leaves no file at all '
          'if the process dies in between',
    );
  });
}
