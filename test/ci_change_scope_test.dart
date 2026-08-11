import 'package:test/test.dart';

import '../tool/resolve_ci_scope.dart';

void main() {
  group('CI change scope', () {
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
          'packages/app/linux/CMakeLists.txt',
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
        <String>['tool/verify_workspace.dart'],
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
