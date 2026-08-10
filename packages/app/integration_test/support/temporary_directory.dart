import 'dart:io';

/// Deletes an E2E temporary directory after native handles have been released.
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
