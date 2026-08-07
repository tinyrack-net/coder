import 'dart:io';

import 'package:coder_daemon/src/bootstrap/data_reset.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/daemon_lock_holder.dart';

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

void main() {
  // Canonical, matching what _RecordingDataFiles records.
  String home(String entry) =>
      p.canonicalize(p.join('/state/tinyrack-coder', 'v4', entry));
  String config(String entry) =>
      p.canonicalize(p.join('/config/tinyrack-coder', 'v4', entry));

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
          config('secrets.json'),
          config('config.json'),
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
        config('secrets.json'),
        config('config.json'),
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
      expect(DaemonDataReset.preservedHomeEntries, <String>['v4/worktrees']);
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
          p.join('/shared', 'v4', 'coder.sqlite'),
          p.join('/shared', 'v4', 'secrets.json'),
        },
      );

      await reset(
        files,
        configDirectory: '/shared/',
        homeDirectory: '/shared',
      ).eraseAll();

      expect(files.deleted, <String>[
        p.canonicalize(p.join('/shared', 'v4', 'coder.sqlite')),
        p.canonicalize(p.join('/shared', 'v4', 'secrets.json')),
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

  test(
    'v4 reset never touches preserved v2 or v3 namespaces',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{
          p.join('/state/tinyrack-coder', 'v2'),
          p.join('/state/tinyrack-coder', 'v3'),
          home('coder.sqlite'),
        },
        directories: <String>{
          p.join('/state/tinyrack-coder', 'v2'),
          p.join('/state/tinyrack-coder', 'v3'),
        },
      );

      await reset(files).eraseAll();

      expect(files.deleted, <String>[home('coder.sqlite')]);
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  test(
    'legacy cleanup requires and removes only explicit versions',
    () async {
      final files = _RecordingDataFiles(
        entries: <String>{
          p.join('/state/tinyrack-coder', 'v2'),
          p.join('/config/tinyrack-coder', 'v2'),
          p.join('/state/tinyrack-coder', 'v3'),
        },
        directories: <String>{
          p.join('/state/tinyrack-coder', 'v2'),
          p.join('/config/tinyrack-coder', 'v2'),
          p.join('/state/tinyrack-coder', 'v3'),
        },
      );
      final cleanup = DaemonLegacyDataCleanup(
        configDirectory: '/config/tinyrack-coder',
        homeDirectory: '/state/tinyrack-coder',
        files: files,
      );

      await cleanup.erase(versions: const <int>{2});

      expect(
        files.deleted,
        containsAll(<String>[
          p.canonicalize(p.join('/state/tinyrack-coder', 'v2')),
          p.canonicalize(p.join('/config/tinyrack-coder', 'v2')),
        ]),
      );
      expect(
        files.deleted,
        isNot(contains(p.canonicalize(p.join('/state/tinyrack-coder', 'v3')))),
      );
      await expectLater(
        cleanup.erase(versions: const <int>{4}),
        throwsArgumentError,
      );
    },
    tags: const <String>['feature_test__settings_reset__unit'],
  );

  group('NativeDaemonDataFiles', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('coder-data-reset-');
    });

    tearDown(() => deleteWithRetry(root));

    test(
      'erases daemon files on disk and keeps the worktrees checkout',
      () async {
        final state = Directory(p.join(root.path, 'state'));
        final configRoot = Directory(p.join(root.path, 'config'));
        final stateV4 = Directory(p.join(state.path, 'v4'));
        final configV4 = Directory(p.join(configRoot.path, 'v4'));
        await stateV4.create(recursive: true);
        await configV4.create(recursive: true);
        await File(p.join(stateV4.path, 'coder.sqlite')).writeAsString('db');
        await File(p.join(stateV4.path, 'daemon.lock')).writeAsString('');
        await Directory(p.join(stateV4.path, 'attachments')).create();
        await File(
          p.join(stateV4.path, 'worktrees', 'repo', 'main.dart'),
        ).create(recursive: true);
        await File(
          p.join(configV4.path, 'secrets.json'),
        ).writeAsString('{}');
        await File(
          p.join(configV4.path, 'agents', 'coder.md'),
        ).create(recursive: true);

        await DaemonDataReset(
          configDirectory: configRoot.path,
          homeDirectory: state.path,
        ).eraseAll();

        expect(
          File(p.join(stateV4.path, 'coder.sqlite')).existsSync(),
          isFalse,
        );
        expect(File(p.join(stateV4.path, 'daemon.lock')).existsSync(), isFalse);
        expect(
          Directory(p.join(stateV4.path, 'attachments')).existsSync(),
          isFalse,
        );
        expect(
          File(p.join(configV4.path, 'secrets.json')).existsSync(),
          isFalse,
        );
        expect(
          Directory(p.join(configV4.path, 'agents')).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(stateV4.path, 'worktrees', 'repo', 'main.dart'),
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
        final stateV4 = Directory(p.join(state.path, 'v4'));
        await stateV4.create(recursive: true);
        await File(p.join(stateV4.path, 'coder.sqlite')).writeAsString('db');
        final holder = await DaemonLockHolder.start(
          root: root,
          lockPath: p.join(stateV4.path, 'daemon.lock'),
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
          expect(
            File(p.join(stateV4.path, 'coder.sqlite')).existsSync(),
            isTrue,
          );
        } finally {
          await holder.stop();
        }
      },
      tags: const <String>['feature_test__settings_reset__unit'],
    );
  });
}
