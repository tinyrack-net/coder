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
Future<void> deleteTemporaryDirectory(Directory directory) async {
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
