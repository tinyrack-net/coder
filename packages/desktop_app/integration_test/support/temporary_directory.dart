import 'dart:io';

/// How long a caller waits for the operating system to release native handles.
///
/// A caller is expected to have stopped whatever owned the directory first.
/// This budget only covers the lag between a process exiting and Windows
/// dropping its file handles, which stretches when every E2E lane competes for
/// the same disk.
const Duration _handleReleaseBudget = Duration(seconds: 10);

const Duration _retryInterval = Duration(milliseconds: 100);

/// Deletes an E2E temporary directory after native handles have been released.
Future<void> deleteTemporaryDirectory(Directory directory) async {
  final attempts =
      _handleReleaseBudget.inMilliseconds ~/ _retryInterval.inMilliseconds;
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    if (!directory.existsSync()) return;
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      if (attempt == attempts - 1) rethrow;
      await Future<void>.delayed(_retryInterval);
    }
  }
}
