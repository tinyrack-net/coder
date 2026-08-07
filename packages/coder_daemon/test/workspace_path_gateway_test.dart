import 'dart:io';

import 'package:coder_daemon/src/shared/ports/daemon_ports.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'filesystem gateway canonicalizes, creates, filters, and limits',
    () async {
      final created = await Directory.systemTemp.createTemp('coder-path-port-');
      addTearDown(() => created.delete(recursive: true));
      // macOS puts the system temporary directory behind a /var symlink to
      // /private/var, and canonicalizing is the gateway's whole job, so the
      // expectations have to start from the resolved path a caller would get.
      final root = Directory(await created.resolveSymbolicLinks());
      const gateway = IoWorkspacePathGateway();
      final alpha = await Directory(p.join(root.path, 'alpha')).create();
      await Directory(p.join(root.path, 'beta')).create();
      await File(p.join(root.path, 'alphabet.txt')).writeAsString('ignored');

      expect(gateway.canonicalizeExistingDirectory(alpha.path), alpha.path);
      final nested = p.join(root.path, 'nested', 'child');
      await gateway.createDirectory(nested);
      expect(Directory(nested).existsSync(), isTrue);
      expect(await gateway.suggest('', 10), isEmpty);
      expect(await gateway.suggest(root.path, 0), isEmpty);
      expect(
        await gateway.suggest(p.join(root.path, 'missing', 'child'), 10),
        isEmpty,
      );
      final filtered = await gateway.suggest(p.join(root.path, 'al'), 10);
      expect(filtered.map((item) => item.name), <String>['alpha']);
      final limited = await gateway.suggest(root.path, 1);
      expect(limited, hasLength(1));
    },
  );

  test('filesystem gateway rejects a missing workspace', () {
    expect(
      () => const IoWorkspaceCanonicalizer().canonicalizeExistingDirectory(
        p.join(Directory.systemTemp.path, 'coder-path-that-does-not-exist'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('system adapters produce UTC time and unique UUID identifiers', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
    final first = const UuidIdGenerator().generate();
    final second = const UuidIdGenerator().generate();
    expect(first, isNot(second));
    expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
  });
}
