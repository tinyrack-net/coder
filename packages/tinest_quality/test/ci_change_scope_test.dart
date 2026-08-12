import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:tinest_quality/tinest_quality.dart';

void main() {
  group('CI change scope', () {
    test(
      'standalone entrypoint runs without Pub workspace resolution',
      () async {
        final process = await Process.start(
          Platform.resolvedExecutable,
          <String>['packages/tinest_quality/bin/ci_scope.dart'],
        );
        process.stdin.write('packages/app/lib/main_desktop.dart\n');
        await process.stdin.close();
        final output = await process.stdout.transform(utf8.decoder).join();
        final error = await process.stderr.transform(utf8.decoder).join();

        expect(await process.exitCode, 0, reason: error);
        expect(output.trim(), 'app-only');
        expect(error, isEmpty);
      },
    );

    test('classifies documentation-only pull requests', () {
      expect(
        CiChangeScope.forPullRequest(<String>[
          'docs/testing.md',
          'packages/app/README.md',
        ]),
        CiChangeScope.docsOnly,
      );
    });

    test('classifies relay-only pull requests', () {
      expect(
        CiChangeScope.forPullRequest(<String>[
          'packages/relay/lib/relay.dart',
          'packages/relay/Dockerfile',
          'packages/relay/docker/pubspec.lock',
        ]),
        CiChangeScope.relayOnly,
      );
    });

    test('classifies app-only pull requests', () {
      expect(
        CiChangeScope.forPullRequest(<String>[
          'packages/app/lib/main_desktop.dart',
          'packages/desktop_app/linux/CMakeLists.txt',
        ]),
        CiChangeScope.appOnly,
      );
    });

    test('keeps shared and mixed changes in the full scope', () {
      for (final files in <List<String>>[
        <String>['packages/relay_protocol/lib/relay_protocol.dart'],
        <String>[
          'packages/relay/lib/relay.dart',
          'packages/app/lib/main_desktop.dart',
        ],
        <String>['pubspec.yaml'],
        <String>['pubspec.lock'],
        <String>['packages/tinest_quality/bin/src/application.dart'],
        <String>['.github/workflows/pipeline.yml'],
      ]) {
        expect(CiChangeScope.forPullRequest(files), CiChangeScope.full);
      }
    });

    test('an empty or invalid file listing stays in the full scope', () {
      expect(
        CiChangeScope.forPullRequest(const <String>[]),
        CiChangeScope.full,
      );
      expect(
        CiChangeScope.forPullRequest(const <String>['', '   ']),
        CiChangeScope.full,
      );
    });
  });
}
