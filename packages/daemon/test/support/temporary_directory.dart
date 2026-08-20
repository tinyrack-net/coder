import 'dart:io';

/// Deletes a scratch directory once the OS has released its native handles.
///
/// Windows refuses to remove a directory while any file inside it is still
/// open, and it releases a terminated process's image handle asynchronously.
/// A suite that staged and ran an executable there can therefore reach its
/// teardown before the handle is gone and fail with
/// `Access is denied, errno = 5` while nothing is actually wrong.
///
/// That window is short and unrelated to load, but the odds of landing in it
/// rise with concurrency: it stayed invisible while these suites ran one at a
/// time and surfaced as soon as they ran four at a time.
///
/// This waits for the condition rather than a fixed duration, and still fails
/// if the handle never goes -- a directory that stays locked is a leaked
/// process, which is a real defect and not something to swallow.
///
/// When it does fail it names the entries that refused to go, because the
/// directory path alone does not say which handle is still open. A staged host
/// holds its executable and its native libraries, and knowing which one is
/// pinned is the difference between a diagnosable failure and a retry.
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
/// the tree, so whatever rejects it here is what held the tree. This is only
/// reached on a teardown that already failed, and the directory is being
/// discarded either way, so removing what it can is not a loss.
///
/// POSIX unlinks a file that is still open, so a held handle produces no
/// finding there; the report says so rather than implying the tree was clean.
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
