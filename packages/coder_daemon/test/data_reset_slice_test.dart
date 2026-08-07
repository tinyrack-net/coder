import 'dart:io';

import 'package:coder_daemon/coder_daemon.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'a reset drops daemon state, keeps checkouts, and yields a new identity',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-reset-home-');
      final config = DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        useEnvironmentCredentials: false,
      );
      addTearDown(() async {
        if (home.existsSync()) await home.delete(recursive: true);
      });

      final first = await DaemonApplication.start(config);
      final firstServerId = first.serverId;
      final firstToken = first.bearerToken;
      // A managed checkout with unpushed work is exactly what a reset must
      // not take with it.
      final checkout = File(
        p.join(home.path, 'v4', 'worktrees', 'repo', 'main.dart'),
      );
      await checkout.create(recursive: true);
      await checkout.writeAsString('void main() {}');
      expect(
        File(p.join(home.path, 'v4', 'coder.sqlite')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(home.path, 'v4', 'secrets.json')).existsSync(),
        isTrue,
      );
      await first.stop();

      await DaemonDataReset(
        configDirectory: config.configDirectory,
        homeDirectory: config.homeDirectory,
      ).eraseAll();

      expect(
        File(p.join(home.path, 'v4', 'coder.sqlite')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(home.path, 'v4', 'secrets.json')).existsSync(),
        isFalse,
      );
      expect(
        Directory(p.join(home.path, 'v4', 'agents')).existsSync(),
        isFalse,
      );
      expect(
        Directory(p.join(home.path, 'v4', 'skills')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(home.path, 'v4', 'daemon.lock')).existsSync(),
        isFalse,
      );
      expect(checkout.existsSync(), isTrue);
      expect(await checkout.readAsString(), 'void main() {}');

      final second = await DaemonApplication.start(config);
      addTearDown(second.stop);

      expect(second.serverId, isNot(firstServerId));
      expect(second.bearerToken, isNot(firstToken));
      expect(checkout.existsSync(), isTrue);
    },
    tags: const <String>['feature_test__settings_reset__verticalSlice'],
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
