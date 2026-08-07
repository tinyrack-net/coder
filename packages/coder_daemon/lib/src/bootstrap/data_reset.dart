import 'dart:io';

import 'package:path/path.dart' as p;

/// Filesystem primitives required to erase stored daemon data.
abstract interface class DaemonDataFiles {
  /// Whether an entity exists at [path].
  Future<bool> exists(String path);

  /// Whether [path] points at a directory rather than a file.
  Future<bool> isDirectory(String path);

  /// Deletes the file at [path].
  Future<void> deleteFile(String path);

  /// Recursively deletes the directory at [path].
  Future<void> deleteDirectory(String path);

  /// Throws when another process still holds the daemon lock at [lockPath].
  ///
  /// Record locks are owned per process, so this cannot detect a daemon
  /// running inside the calling process. Callers stop their own daemon first.
  Future<void> assertLockAvailable(String lockPath);
}

/// Why a [DaemonDataReset] refused to erase stored data.
enum DaemonDataResetFailureReason {
  /// Another daemon process owns the data directory.
  daemonRunning,

  /// The operating system rejected a delete.
  filesystem,
}

/// Raised when stored daemon data cannot be erased.
final class DaemonDataResetException implements Exception {
  /// Creates a [DaemonDataResetException].
  const DaemonDataResetException(
    this.message, {
    required this.reason,
    this.path,
  });

  /// Human-readable explanation of the failure.
  final String message;

  /// Machine-readable failure classification.
  final DaemonDataResetFailureReason reason;

  /// The path that could not be erased, when the failure names one.
  final String? path;

  @override
  String toString() => 'DaemonDataResetException(${reason.name}): $message';
}

/// Native [DaemonDataFiles] adapter backed by `dart:io`.
final class NativeDaemonDataFiles implements DaemonDataFiles {
  /// Creates the production filesystem adapter.
  const NativeDaemonDataFiles();

  @override
  Future<bool> exists(String path) async =>
      FileSystemEntity.typeSync(path, followLinks: false) !=
      FileSystemEntityType.notFound;

  @override
  Future<bool> isDirectory(String path) async =>
      FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.directory;

  @override
  Future<void> deleteFile(String path) => File(path).delete();

  @override
  Future<void> deleteDirectory(String path) =>
      Directory(path).delete(recursive: true);

  @override
  Future<void> assertLockAvailable(String lockPath) async {
    final file = File(lockPath);
    if (!file.existsSync()) return;
    final handle = await file.open(mode: FileMode.append);
    try {
      await handle.lock();
      await handle.unlock();
    } on FileSystemException catch (error) {
      throw DaemonDataResetException(
        'Another daemon owns ${p.dirname(lockPath)}: ${error.message}',
        reason: DaemonDataResetFailureReason.daemonRunning,
        path: lockPath,
      );
    } finally {
      await handle.close();
    }
  }
}

/// Erases every daemon-owned file while preserving managed Git checkouts.
///
/// The daemon must be stopped first: it holds an exclusive lock on
/// `daemon.lock` and an open handle on `coder.sqlite`.
final class DaemonDataReset {
  /// Creates a reset targeting one daemon's config and state directories.
  const DaemonDataReset({
    required this.configDirectory,
    required this.homeDirectory,
    this.files = const NativeDaemonDataFiles(),
  });

  /// Directory holding credentials and declarative configuration.
  final String configDirectory;

  /// Directory holding the database, attachments, and managed checkouts.
  final String homeDirectory;

  /// Filesystem adapter used to inspect and delete entries.
  final DaemonDataFiles files;

  /// Entries erased from [homeDirectory].
  static const List<String> homeEntries = <String>[
    'v3/coder.sqlite',
    'v3/coder.sqlite-wal',
    'v3/coder.sqlite-shm',
    'v3/coder.sqlite-journal',
    'v3/attachments',
    'v3/daemon.lock',
  ];

  /// Entries erased from [configDirectory].
  static const List<String> configEntries = <String>[
    'v3/secrets.json',
    'v3/secrets.json.tmp',
    'v3/config.json',
    'v3/config.json.tmp',
    'v3/agents',
    'v3/skills',
    'v3/commands',
  ];

  /// Entries under [homeDirectory] that a reset must never touch.
  ///
  /// Managed checkouts can hold unpushed work, so they outlive a reset even
  /// though their workspace registrations do not.
  static const List<String> preservedHomeEntries = <String>['v3/worktrees'];

  /// Erases every entry in the allowlist, leaving both roots in place.
  ///
  /// Missing entries are not an error. Throws [DaemonDataResetException] when
  /// another daemon still owns the directory, in which case nothing is
  /// deleted.
  Future<void> eraseAll() async {
    await files.assertLockAvailable(
      p.join(homeDirectory, 'v3', 'daemon.lock'),
    );
    for (final path in _targets()) {
      if (!await files.exists(path)) continue;
      try {
        if (await files.isDirectory(path)) {
          await files.deleteDirectory(path);
        } else {
          await files.deleteFile(path);
        }
      } on FileSystemException catch (error) {
        throw DaemonDataResetException(
          'Failed to delete $path: ${error.message}',
          reason: DaemonDataResetFailureReason.filesystem,
          path: path,
        );
      }
    }
  }

  /// Absolute deletion targets, deduplicated by canonical path.
  ///
  /// The config and state roots collapse into one directory on macOS, on
  /// Windows without `LOCALAPPDATA`, and under `TINYRACK_CODER_HOME`, so the
  /// same entry can be named twice.
  List<String> _targets() {
    final seen = <String>{};
    final targets = <String>[];
    for (final (root, entries) in <(String, List<String>)>[
      (homeDirectory, homeEntries),
      (configDirectory, configEntries),
    ]) {
      for (final entry in entries) {
        final path = p.join(root, entry);
        if (seen.add(p.canonicalize(path))) targets.add(path);
      }
    }
    return targets;
  }
}
