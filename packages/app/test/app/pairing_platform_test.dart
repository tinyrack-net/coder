import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final packageRoot = Directory.current;

  String packageFile(String path) =>
      File('${packageRoot.path}/$path').readAsStringSync();

  test(
    'mobile platforms register the canonical HTTPS pair route',
    () {
      final android = packageFile('android/app/src/main/AndroidManifest.xml');
      expect(android, contains('android:autoVerify="true"'));
      expect(android, contains('android:host="tinest.tinyrack.net"'));
      expect(android, contains('android:path="/pair"'));

      final ios = packageFile('ios/Runner/Runner.entitlements');
      expect(ios, contains('applinks:tinest.tinyrack.net'));
    },
    tags: const <String>['feature_test__daemon_relay__platformSmoke'],
  );

  test(
    'desktop packages register only the fragment-safe custom protocol',
    () {
      for (final file in <String>[
        'ios/Runner/Info.plist',
        'macos/Runner/Info.plist',
        'windows/installer/tinest.iss',
        'linux/net.tinyrack.tinest.desktop',
      ]) {
        final contents = packageFile(file);
        expect(contents, contains('tinyrack-tinest'), reason: file);
        expect(contents, isNot(contains('?offer=')), reason: file);
      }
    },
    tags: const <String>['feature_test__daemon_relay__platformSmoke'],
  );

  test(
    'web deployment falls back to the Flutter pair route',
    () {
      final wrangler = packageFile('wrangler.jsonc');
      expect(wrangler, contains('tinest.tinyrack.net'));
      expect(
        wrangler,
        contains('"not_found_handling": "single-page-application"'),
      );
    },
    tags: const <String>['feature_test__daemon_relay__platformSmoke'],
  );
}
