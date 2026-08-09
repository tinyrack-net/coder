import 'dart:io';

import 'package:daemon/daemon.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/daemon_lock_holder.dart';

/// A daemon home is exclusive, and a second daemon over one is the failure a
/// Windows user hits when a tray-resident copy still owns `daemon.lock`. The
/// raw `PathAccessException` that `RandomAccessFile.lock` throws names a lock
/// file and an errno, which reads as data corruption rather than as a running
/// daemon, so the daemon has to report the cause itself.
void main() {
  late Directory home;

  setUp(() async {
    home = await Directory.systemTemp.createTemp('coder-daemon-lock-');
    await Directory(p.join(home.path, 'v4')).create();
  });

  tearDown(() => deleteWithRetry(home));

  test(
    'a daemon over a home another process holds reports the running daemon',
    () async {
      final lockPath = p.join(home.path, 'v4', 'daemon.lock');
      final holder = await DaemonLockHolder.start(
        root: home,
        lockPath: lockPath,
      );
      addTearDown(holder.stop);

      await expectLater(
        DaemonApplication.start(_config(home.path)),
        throwsA(
          isA<DaemonAlreadyRunningException>()
              .having(
                (failure) => failure.homeDirectory,
                'homeDirectory',
                p.join(home.path, 'v4'),
              )
              .having(
                (failure) => failure.diagnostic,
                'diagnostic',
                contains('daemon.lock'),
              ),
        ),
      );
    },
    tags: const <String>['feature_test__daemon_management__unit'],
  );

  test(
    'a daemon starts once the process holding the home releases it',
    () async {
      final holder = await DaemonLockHolder.start(
        root: home,
        lockPath: p.join(home.path, 'v4', 'daemon.lock'),
      );
      await holder.stop();

      final handle = await DaemonApplication.start(_config(home.path));
      addTearDown(handle.stop);

      expect(handle.serverId, isNotEmpty);
    },
    tags: const <String>['feature_test__daemon_management__unit'],
  );

  test(
    'an embedded daemon reports a held home as a typed startup failure',
    () async {
      final holder = await DaemonLockHolder.start(
        root: home,
        lockPath: p.join(home.path, 'v4', 'daemon.lock'),
      );
      addTearDown(holder.stop);

      await expectLater(
        EmbeddedDaemonHandle.start(_config(home.path)),
        throwsA(
          isA<EmbeddedDaemonStartupException>().having(
            (failure) => failure.reason,
            'reason',
            EmbeddedDaemonStartupFailureReason.alreadyRunning,
          ),
        ),
      );
    },
    tags: const <String>['feature_test__daemon_management__contract'],
  );
}

DaemonConfig _config(String home) => DaemonConfig(
  homeDirectory: home,
  port: 0,
  bearerToken: 'test-token-0123456789abcdef0123456789',
  useEnvironmentCredentials: false,
);
