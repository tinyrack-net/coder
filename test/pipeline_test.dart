import 'dart:io';

import 'package:test/test.dart';

void main() {
  final workflow = File('.github/workflows/pipeline.yml').readAsStringSync();
  final setupFlutter = File(
    '.github/actions/setup-flutter/action.yml',
  ).readAsStringSync();
  final androidBuild = File(
    'apps/coder_app/android/build.gradle.kts',
  ).readAsStringSync();
  final cargoKitCompat = File(
    'apps/coder_app/android/cargokit-gradle9-compat.gradle',
  );

  test('normal quality jobs do not run in the nightly workflow', () {
    for (final job in <String>[
      'static-linux',
      'generated-linux',
      'dart-tests',
      'flutter-tests',
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'golden-linux',
      'debug-e2e-linux',
      'mobile-debug-build',
      'desktop-debug-build',
      'web-build',
      'cli-verify',
    ]) {
      expect(
        _job(workflow, job),
        contains("if: github.event_name != 'schedule'"),
      );
    }
    for (final job in <String>[
      'nightly-desktop-e2e',
      'nightly-android-smoke',
      'nightly-ios-smoke',
    ]) {
      expect(
        _job(workflow, job),
        contains("if: github.event_name == 'schedule'"),
      );
    }
  });

  test(
    'release builds are tag or manual only and publishing stays tag only',
    () {
      final build = _job(workflow, 'build-and-package');
      expect(build, contains("startsWith(github.ref, 'refs/tags/v')"));
      expect(build, contains("github.event_name == 'workflow_dispatch'"));
      expect(build, contains('inputs.package_release'));
      expect(build, isNot(contains("github.ref == 'refs/heads/main'")));

      for (final job in <String>[
        'publish-release',
        'publish-homebrew',
        'publish-winget',
      ]) {
        expect(
          _job(workflow, job),
          contains("startsWith(github.ref, 'refs/tags/v')"),
        );
      }
    },
  );

  test('both CLI jobs build and smoke the bundle through one definition', () {
    final verify = _job(workflow, 'cli-verify');
    final release = _job(workflow, 'build-cli');

    // Sharing the steps is what keeps the pull-request job honest: a smoke
    // test duplicated into two copies is one that stops matching the CLI.
    for (final job in <String>[verify, release]) {
      expect(job, contains('./.github/actions/build-cli-bundle'));
      expect(job, contains('./.github/actions/smoke-cli-bundle'));
    }
    for (final target in <String>[
      'linux-x64',
      'macos-x64',
      'macos-arm64',
      'windows-x64',
    ]) {
      expect(verify, contains('target: $target'));
      expect(release, contains('target: $target'));
    }
    // Linux arm64 has no Flutter SDK, so it is not a release target and must
    // not reappear here; `shipworld.yaml` omits it too.
    expect(verify, isNot(contains('linux-arm64')));
    expect(release, isNot(contains('linux-arm64')));
    // A fork pull request has no signing secrets and no release to upload to.
    expect(verify, isNot(contains('APPLE_CERTIFICATE')));
    expect(verify, isNot(contains('upload-artifact')));
  });

  test('the aggregate gate requires every quality job', () {
    final gate = _job(workflow, 'quality-gate');
    for (final dependency in <String>[
      'static-linux',
      'generated-linux',
      'dart-tests',
      'flutter-tests',
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'golden-linux',
      'debug-e2e-linux',
      'mobile-debug-build',
      'desktop-debug-build',
      'web-build',
      // The CLI is only built here on a pull request; `build-cli` waits for a
      // tag, which is how two release-path breakages reached main.
      'cli-verify',
    ]) {
      expect(gate, contains('- $dependency'));
    }
    expect(gate, contains('all(.[]; .result == "success")'));
    expect(_job(workflow, 'publish-release'), contains('- quality-gate'));
  });

  test('desktop E2E jobs execute every domain shard', () {
    final linux = _job(workflow, 'debug-e2e-linux');
    final nightly = _job(workflow, 'nightly-desktop-e2e');
    for (final testFile in <String>[
      'daemon_workspace_e2e_test.dart',
      'project_worktree_e2e_test.dart',
      'debug_e2e_test.dart',
      'provider_e2e_test.dart',
      'settings_desktop_e2e_test.dart',
    ]) {
      expect(linux, contains(testFile));
      expect(nightly, contains(testFile));
    }
    expect(linux, contains('fail-fast: false'));
    expect(nightly, contains(r'-d ${{ matrix.platform.device }}'));
  });

  test('mobile nightly jobs run remote bootstrap and provider E2E', () {
    for (final job in <String>[
      _job(workflow, 'nightly-android-smoke'),
      _job(workflow, 'nightly-ios-smoke'),
    ]) {
      expect(job, contains('remote_bootstrap_smoke_test.dart'));
      expect(job, contains('provider_e2e_test.dart'));
    }
  });

  test('only Android mobile builds use the enhanced Gradle cache', () {
    final mobileBuild = _job(workflow, 'mobile-debug-build');
    final androidBuild = _matrixEntry(mobileBuild, 'ubuntu-24.04');
    final iosBuild = _matrixEntry(mobileBuild, 'macos-26');

    expect(androidBuild, contains('gradle_cache: true'));
    expect(iosBuild, contains('gradle_cache: false'));
    expect(mobileBuild, contains('if: matrix.gradle_cache'));
    expect(mobileBuild, contains('uses: gradle/actions/setup-gradle@v6'));
    expect(mobileBuild, contains('cache-provider: enhanced'));
  });

  test('macOS runners skip the Flutter SDK cache but keep the pub cache', () {
    // The macOS SDK archive is ~2.03 GB per architecture and restores no
    // faster than a fresh CDN download, so caching it only consumes the
    // repository's 10 GB quota and evicts the caches that do pay off.
    // flutter-action gates the pub cache on `inputs.cache` unless `pub-cache`
    // is set explicitly, so pin it to keep pub caching on every runner.
    expect(setupFlutter, contains("cache: \${{ runner.os != 'macOS' }}"));
    expect(setupFlutter, contains("pub-cache: 'true'"));
  });

  test('native attachment plugins receive macOS and Windows debug builds', () {
    final desktopBuild = _job(workflow, 'desktop-debug-build');
    expect(
      _matrixEntry(desktopBuild, 'macos-26'),
      contains('flutter build macos --debug -t lib/main_desktop.dart'),
    );
    expect(
      _matrixEntry(desktopBuild, 'windows-2025'),
      contains('flutter build windows --debug -t lib/main_desktop.dart'),
    );
    expect(_job(workflow, 'quality-gate'), contains('- desktop-debug-build'));
  });

  test('Android supplies the CargoKit Gradle 9 exec compatibility service', () {
    expect(
      androidBuild,
      contains('apply(from = "cargokit-gradle9-compat.gradle")'),
    );
    expect(cargoKitCompat.existsSync(), isTrue);
    final script = cargoKitCompat.readAsStringSync();
    expect(script, contains('ExecOperations'));
    expect(script, isNot(contains('project.exec')));
    expect(script, contains('android.compileSdk = 36'));
  });

  test('shipworld runs from the pinned Tinyrack Dart workspace', () {
    const shipworldRoot = '.dart_tool/tinyrack-dart-packages';
    final shipworldExecutable = <String>[
      shipworldRoot,
      'packages',
      'shipworld',
      'bin',
      'shipworld.dart',
    ].join('/');
    // The workflow ref and the cliweave dependency ref are two independent
    // copies of one commit; a release that resolved them differently would
    // package the CLI with a shipworld that disagrees with the framework it
    // was built against. Comparing them keeps the SHA in one place.
    final pubspec = File(
      'packages/coder_cli/pubspec.yaml',
    ).readAsStringSync();
    final dependencyRef = RegExp(
      'ref: ([0-9a-f]{40})',
    ).firstMatch(pubspec)?.group(1);
    expect(dependencyRef, isNotNull);
    expect(
      workflow,
      contains('TINYRACK_DART_PACKAGES_REF: $dependencyRef'),
    );
    expect(workflow, contains('repository: tinyrack-net/dart-packages'));
    expect(
      workflow,
      contains(r'ref: ${{ env.TINYRACK_DART_PACKAGES_REF }}'),
    );
    expect(
      workflow,
      contains('dart pub get --directory $shipworldRoot'),
    );
    expect(workflow, contains('dart run $shipworldExecutable'));
    expect(workflow, isNot(contains('dart pub global activate shipworld')));
    expect(
      workflow,
      isNot(contains('dart pub global run shipworld:shipworld')),
    );
  });
}

String _job(String workflow, String name) {
  final start = workflow.indexOf('  $name:\n');
  if (start < 0) throw StateError('Missing workflow job $name');
  final next = RegExp(r'^  [a-z][a-z0-9-]*:$', multiLine: true).firstMatch(
    workflow.substring(start + name.length + 3),
  );
  final end = next == null
      ? workflow.length
      : start + name.length + 3 + next.start;
  return workflow.substring(start, end);
}

String _matrixEntry(String job, String os) {
  final start = job.indexOf('          - os: $os\n');
  if (start < 0) throw StateError('Missing matrix entry for $os');
  final next = job.indexOf('          - os:', start + 1);
  return job.substring(start, next < 0 ? job.length : next);
}
