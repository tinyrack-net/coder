import 'dart:io';

/// Deletes an E2E temporary directory after native handles have been released.
///
/// When the handles never go, the failure names the entries that refused to be
/// removed. A real daemon fixture stages an executable and its libraries here,
/// and the directory path alone does not say which one is still pinned.
Future<void> deleteTemporaryDirectory(Directory directory) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    if (!directory.existsSync()) return;
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException catch (error) {
      if (attempt == 19) {
        throw FileSystemException(
          '${error.message}\n${describeUndeletableEntries(directory)}',
          error.path,
          error.osError,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

/// Names the files under [directory] that still refuse deletion.
///
/// Deleting each file individually is the same operation that just failed for
/// the tree, so whatever rejects it here is what held the tree. POSIX unlinks a
/// file that is still open, so a held handle produces no finding there.
String describeUndeletableEntries(Directory directory) {
  final locked = <String>[];
  try {
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      try {
        entity.deleteSync();
      } on FileSystemException catch (error) {
        final reason = error.osError?.message ?? error.message;
        locked.add('${entity.path}: $reason');
      }
    }
  } on FileSystemException catch (error) {
    return 'could not enumerate ${directory.path}: ${error.message}';
  }
  if (locked.isEmpty) return 'no entry refused deletion individually';
  return 'entries still locked:\n  ${locked.join('\n  ')}';
}
