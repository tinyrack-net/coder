import 'dart:io';

import 'package:coder_daemon/src/data_reset.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Records every filesystem interaction so ordering can be asserted.
final class _RecordingDataFiles implements DaemonDataFiles {
  _RecordingDataFiles({
    required Set<String> entries,
    Set<String> directories = const <String>{},
    this.lockFailure,
    String? deleteFailure,
  }) : entries = entries.map(p.canonicalize).toSet(),
       directories = directories.map(p.canonicalize).toSet(),
       deleteFailure = deleteFailure == null
           ? null
           : p.canonicalize(deleteFailure);

  // Canonical, because a real filesystem resolves `/x/y` and `/x//y` to the
  // same entry and the reset joins onto caller-supplied directory strings.
  final Set<String> entries;
  final Set<String> directories;
  final DaemonDataResetException? lockFailure;
  final String? deleteFailure;

  final List<String> calls = <String>[];
  final List<String> deleted = <String>[];

  @override
  Future<void> assertLockAvailable(String lockPath) async {
    calls.add('lock:$lockPath');
    final failure = lockFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<bool> exists(String path) async =>
      entries.contains(p.canonicalize(path));

  @override
  Future<bool> isDirectory(String path) async =>
      directories.contains(p.canonicalize(path));

  @override
  Future<void> deleteFile(String path) async => _delete('file', path);

  @override
  Future<void> deleteDirectory(String path) async => _delete('dir', path);

  void _delete(String kind, String path) {
    calls.add('$kind:$path');
    if (p.canonicalize(path) == deleteFailure) {
      throw FileSystemException('denied', path);
    }
    deleted.add(p.canonicalize(path));
  }
}

/// Holds the daemon lock from a separate process.
///
/// POSIX record locks are owned per process, so a second handle opened by the
/// test itself would acquire the lock instead of contending for it.
final class _LockHolder {
  _LockHolder._(this._process);

  final Process _process;

  static Future<_LockHolder> start({
    required Directory root,
    required String lockPath,
  }) async {
    final script = File(p.join(root.path, 'lock_holder.dart'));
    await script.writeAsString('''
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final handle = await File(arguments.single).open(mode: FileMode.append);
  await handle.lock();
  stdout.writeln('locked');
  await stdin.first;
  await handle.unlock();
  await handle.close();
}
''');
    final process = await Process.start(Platform.resolvedExecutable, <String>[
      script.path,
      lockPath,
    ]);
    await process.stdout.first;
    return _LockHolder._(process);
  }

  /// Releases the lock and waits for the holder to exit.
  ///
  /// The holder unlocks and closes its handle when stdin delivers a line.
  /// Killing it skipped that protocol, and on Windows the file was still open
  /// when the temporary directory was deleted, failing the test in teardown
  /// with "the process cannot access the file because it is being used by
  /// another process".
  Future<void> stop() async {
    _process.stdin.writeln();
    await _process.stdin.flush();
    await _process.stdin.close();
    await _process.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _process.kill();
        return _process.exitCode;
      },
    );
  }
}

/// Deletes [directory], retrying briefly while the platform still holds it.
///
/// Windows can report a just-closed file as in use for a moment, and a
/// teardown that trips over it fails a test that already passed.
Future<void> _deleteWithRetry(Directory directory) async {
  for (var attempt = 0; ; attempt += 1) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      if (attempt >= 10) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}

void main() {
  // Canonical, matching what _RecordingDataFiles records.
  String home(String entry) =>
      p.canonicalize(p.join('/state/tinyrack-coder', entry));
  String config(String entry) =>
      p.canonicalize(p.join('/config/tinyrack-coder', entry));

  DaemonDataReset reset(
    DaemonDataFiles files, {
    String configDirectory = '/config/tinyrack-coder',
    String homeDirectory = '/state/tinyrack-coder',
  }) => DaemonDataReset(
    configDirectory: configDirectory,
    homeDirectory: homeDirectory,
    files: files,
  );

  test(
    'erases every allowlisted entry and keeps managed checkouts',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{
          home('coder.sqlite'),
          home('coder.sqlite-wal'),
          home('attachments'),
          home('daemon.lock'),
          home('worktrees'),
          config('credentials.json'),
          config('mcp.json'),
          config('agents'),
          config('skills'),
        },
        directories: <String>{
          home('attachments'),
          home('worktrees'),
          config('agents'),
          config('skills'),
        },
      );

      await reset(files).eraseAll();

      expect(files.deleted, <String>[
        home('coder.sqlite'),
        home('coder.sqlite-wal'),
        home('attachments'),
        home('daemon.lock'),
        config('credentials.json'),
        config('mcp.json'),
        config('agents'),
        config('skills'),
      ]);
      expect(files.deleted, isNot(contains(home('worktrees'))));
      expect(
        files.deleted,
        isNot(contains(p.canonicalize('/state/tinyrack-coder'))),
      );
      expect(
        files.deleted,
        isNot(contains(p.canonicalize('/config/tinyrack-coder'))),
      );
      expect(DaemonDataReset.preservedHomeEntries, <String>['worktrees']);
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'tolerates missing entries',
    () async {
      final files = _RecordingDataFiles(entries: <String>{});

      await reset(files).eraseAll();

      expect(files.deleted, isEmpty);
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'visits each entry once when config and state collapse into one directory',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{
          p.join('/shared', 'coder.sqlite'),
          p.join('/shared', 'credentials.json'),
        },
      );

      await reset(
        files,
        configDirectory: '/shared/',
        homeDirectory: '/shared',
      ).eraseAll();

      expect(files.deleted, <String>[
        p.canonicalize(p.join('/shared', 'coder.sqlite')),
        p.canonicalize(p.join('/shared', 'credentials.json')),
      ]);
      expect(
        files.calls.where((call) => call.startsWith('dir:')).length +
            files.calls.where((call) => call.startsWith('file:')).length,
        2,
      );
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'aborts before deleting anything while another daemon holds the lock',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{home('coder.sqlite')},
        lockFailure: const DaemonDataResetException(
          'locked',
          reason: DaemonDataResetFailureReason.daemonRunning,
        ),
      );

      await expectLater(
        reset(files).eraseAll(),
        throwsA(
          isA<DaemonDataResetException>().having(
            (error) => error.reason,
            'reason',
            DaemonDataResetFailureReason.daemonRunning,
          ),
        ),
      );
      expect(files.deleted, isEmpty);
      expect(files.calls.single, startsWith('lock:'));
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'reports the failing path when the operating system rejects a delete',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{home('coder.sqlite')},
        deleteFailure: home('coder.sqlite'),
      );

      await expectLater(
        reset(files).eraseAll(),
        throwsA(
          isA<DaemonDataResetException>()
              .having(
                (error) => error.reason,
                'reason',
                DaemonDataResetFailureReason.filesystem,
              )
              .having(
                (error) => p.canonicalize(error.path!),
                'path',
                home('coder.sqlite'),
              ),
        ),
      );
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  group('NativeDaemonDataFiles', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('coder-data-reset-');
    });

    tearDown(() => _deleteWithRetry(root));

    test(
      'erases daemon files on disk and keeps the worktrees checkout',
      () async {
        final state = Directory(p.join(root.path, 'state'));
        final configRoot = Directory(p.join(root.path, 'config'));
        await state.create(recursive: true);
        await configRoot.create(recursive: true);
        await File(p.join(state.path, 'coder.sqlite')).writeAsString('db');
        await File(p.join(state.path, 'daemon.lock')).writeAsString('');
        await Directory(p.join(state.path, 'attachments')).create();
        await File(
          p.join(state.path, 'worktrees', 'repo', 'main.dart'),
        ).create(recursive: true);
        await File(
          p.join(configRoot.path, 'credentials.json'),
        ).writeAsString('{}');
        await File(
          p.join(configRoot.path, 'agents', 'coder.md'),
        ).create(recursive: true);

        await DaemonDataReset(
          configDirectory: configRoot.path,
          homeDirectory: state.path,
        ).eraseAll();

        expect(File(p.join(state.path, 'coder.sqlite')).existsSync(), isFalse);
        expect(File(p.join(state.path, 'daemon.lock')).existsSync(), isFalse);
        expect(
          Directory(p.join(state.path, 'attachments')).existsSync(),
          isFalse,
        );
        expect(
          File(p.join(configRoot.path, 'credentials.json')).existsSync(),
          isFalse,
        );
        expect(
          Directory(p.join(configRoot.path, 'agents')).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(state.path, 'worktrees', 'repo', 'main.dart'),
          ).existsSync(),
          isTrue,
        );
        expect(state.existsSync(), isTrue);
        expect(configRoot.existsSync(), isTrue);
      },
      tags: const <String>['feature_test__settings_reset__unit'],
    );

    test(
      'refuses to erase while another process holds the daemon lock',
      () async {
        final state = Directory(p.join(root.path, 'locked'));
        await state.create(recursive: true);
        await File(p.join(state.path, 'coder.sqlite')).writeAsString('db');
        final holder = await _LockHolder.start(
          root: root,
          lockPath: p.join(state.path, 'daemon.lock'),
        );

        try {
          await expectLater(
            DaemonDataReset(
              configDirectory: state.path,
              homeDirectory: state.path,
            ).eraseAll(),
            throwsA(
              isA<DaemonDataResetException>().having(
                (error) => error.reason,
                'reason',
                DaemonDataResetFailureReason.daemonRunning,
              ),
            ),
          );
          expect(File(p.join(state.path, 'coder.sqlite')).existsSync(), isTrue);
        } finally {
          await holder.stop();
        }
      },
      tags: const <String>['feature_test__settings_reset__unit'],
    );
  });
}
