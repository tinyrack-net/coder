import 'dart:io';

import 'package:test/test.dart';

void main() {
  final workflow = File('.github/workflows/pipeline.yml').readAsStringSync();
  final relayWorkflowFile = File('.github/workflows/relay-release.yml');
  final relayWorkflow = relayWorkflowFile.existsSync()
      ? relayWorkflowFile.readAsStringSync()
      : '';
  final relayDockerfile = File(
    'packages/relay/Dockerfile',
  ).readAsStringSync();
  final shipworld = File('shipworld.yaml').readAsStringSync();
  final ibusTerminalRunner = File(
    'tool/run_linux_ibus_terminal_e2e.sh',
  ).readAsStringSync();
  final androidBuild = File(
    'packages/app/android/build.gradle.kts',
  ).readAsStringSync();
  final androidAppBuild = File(
    'packages/app/android/app/build.gradle.kts',
  ).readAsStringSync();
  final appPubspec = File('packages/app/pubspec.yaml').readAsStringSync();
  final iosDebugConfig = File(
    'packages/app/ios/Flutter/Debug.xcconfig',
  ).readAsStringSync();
  final iosReleaseConfig = File(
    'packages/app/ios/Flutter/Release.xcconfig',
  ).readAsStringSync();
  final iosPodfileFile = File('packages/app/ios/Podfile');
  final iosPodfile = iosPodfileFile.existsSync()
      ? iosPodfileFile.readAsStringSync()
      : '';
  final iosProject = File(
    'packages/app/ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();
  final cargoKitCompat = File(
    'packages/app/android/cargokit-gradle9-compat.gradle',
  );
  final windowsCmake = File(
    'packages/app/windows/CMakeLists.txt',
  ).readAsStringSync();
  final luaHostBuilder = File('tool/build_lua_host.dart').readAsStringSync();

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
      'linux-ibus-terminal-e2e',
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
      final androidRelease = _job(workflow, 'build-android-release');
      expect(build, contains("startsWith(github.ref, 'refs/tags/v')"));
      expect(build, contains("github.event_name == 'workflow_dispatch'"));
      expect(build, contains('inputs.package_release'));
      expect(build, isNot(contains("github.ref == 'refs/heads/main'")));
      expect(
        androidRelease,
        contains("startsWith(github.ref, 'refs/tags/v')"),
      );
      expect(
        androidRelease,
        contains("github.event_name == 'workflow_dispatch'"),
      );
      expect(androidRelease, contains('inputs.package_release'));
      expect(
        androidRelease,
        isNot(contains("github.ref == 'refs/heads/main'")),
      );

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

  test('Android releases require the private key and publish a signed APK', () {
    final release = _job(workflow, 'build-android-release');
    for (final secret in <String>[
      'ANDROID_KEYSTORE_BASE64',
      'ANDROID_KEYSTORE_PASSWORD',
      'ANDROID_KEY_ALIAS',
      'ANDROID_KEY_PASSWORD',
    ]) {
      final reference = r'${{ secrets.SECRET }}'.replaceFirst('SECRET', secret);
      expect(release, contains(reference));
    }
    expect(release, contains('gradle/actions/setup-gradle@v6'));
    expect(
      release,
      contains('flutter build apk --release -t lib/main_mobile.dart'),
    );
    expect(release, contains('verify --verbose --print-certs'));
    expect(release, contains('Coder-android-universal.apk'));
    expect(release, contains('if: always()'));
    expect(release, isNot(contains('pull_request')));

    final publish = _job(workflow, 'publish-release');
    expect(publish, contains('- build-android-release'));
    expect(publish, contains('pattern: coder-*'));
  });

  test('Android release builds cannot fall back to the debug signing key', () {
    expect(androidAppBuild, contains('key.properties'));
    expect(androidAppBuild, contains('signingConfigs'));
    expect(androidAppBuild, contains('signingConfigs.getByName("release")'));
    expect(
      androidAppBuild,
      isNot(contains('signingConfigs.getByName("debug")')),
    );
  });

  test('app tags deploy web as a required release artifact', () {
    final deployWeb = _job(workflow, 'deploy-web');
    final publishRelease = _job(workflow, 'publish-release');

    expect(deployWeb, contains("startsWith(github.ref, 'refs/tags/v')"));
    expect(deployWeb, isNot(contains("github.ref == 'refs/heads/main'")));
    for (final dependency in <String>[
      'quality-gate',
      'web-build',
      'build-and-package',
      'build-cli',
    ]) {
      expect(deployWeb, contains('- $dependency'));
    }
    expect(publishRelease, contains('- deploy-web'));
  });

  test('relay tags publish one attested multi-platform GHCR image', () {
    expect(relayWorkflow, contains('relay-v*.*.*'));
    expect(relayWorkflow, contains('packages: write'));
    expect(relayWorkflow, contains('attestations: write'));
    expect(relayWorkflow, contains('id-token: write'));
    expect(relayWorkflow, contains('release verify relay'));
    expect(relayWorkflow, contains('linux/amd64,linux/arm64'));
    expect(relayWorkflow, contains('ghcr.io/tinyrack-net/coder-relay'));
    expect(
      relayWorkflow,
      contains(r'v${{ steps.version.outputs.version }}'),
    );
    expect(relayWorkflow, contains('latest'));
    expect(relayWorkflow, contains('actions/attest'));
    expect(
      relayWorkflow,
      contains('packages/relay/tool/smoke_relay.dart'),
    );
    expect(relayWorkflow, isNot(contains('gh release create')));
  });

  test('relay release has an independent version and reproducible image', () {
    expect(shipworld, contains('  relay:'));
    expect(shipworld, contains('source: packages/relay/pubspec.yaml'));
    expect(shipworld, contains('tag: "relay-v{version}"'));

    expect(relayDockerfile, contains('dart:3.12.2@sha256:'));
    expect(relayDockerfile, contains('cc-debian12:nonroot@sha256:'));
    expect(relayDockerfile, contains('docker/pubspec.lock pubspec.lock'));
    expect(relayDockerfile, contains('dart pub get --enforce-lockfile'));
    expect(relayDockerfile, isNot(contains('dart:stable')));
    expect(File('packages/relay/docker/pubspec.lock').existsSync(), isTrue);
    expect(File('packages/relay/deploy/kubernetes.yaml').existsSync(), isFalse);
  });

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
      'linux-ibus-terminal-e2e',
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

  test('Linux IBus terminal E2E is a required real desktop job', () {
    final job = _job(workflow, 'linux-ibus-terminal-e2e');
    expect(workflow, contains('pull_request:'));
    expect(workflow, contains('merge_group:'));
    expect(workflow, contains('- main'));
    expect(job, contains("if: github.event_name != 'schedule'"));
    expect(job, contains('runs-on: ubuntu-24.04'));
    expect(job, contains('./.github/actions/setup-flutter'));
    for (final package in <String>[
      'ibus-gtk3',
      'ibus-hangul',
      'xdotool',
      'xclip',
      'dbus-x11',
      'xvfb',
    ]) {
      expect(job, contains(package));
    }
    expect(job, contains('xvfb-run -a dbus-run-session'));
    expect(job, contains('tool/run_linux_ibus_terminal_e2e.sh'));
    expect(job, contains('terminal_ibus_e2e_test.dart'));
    expect(job, isNot(contains('continue-on-error')));
    expect(job, isNot(contains('retry')));
    expect(
      ibusTerminalRunner,
      contains('flutter pub get --enforce-lockfile'),
    );
    expect(job, isNot(contains('mise')));
    expect(ibusTerminalRunner, isNot(contains('mise')));
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

  test('the scanner no longer forces SwiftPM off while iOS uses CocoaPods', () {
    expect(appPubspec, contains('mobile_scanner: ^7.4.0'));
    expect(
      appPubspec,
      isNot(contains('enable-swift-package-manager: false')),
    );
    expect(iosDebugConfig, contains('Pods-Runner.debug.xcconfig'));
    expect(iosReleaseConfig, contains('Pods-Runner.release.xcconfig'));
    expect(iosPodfile, contains("platform :ios, '13.0'"));
    expect(iosPodfile, isNot(contains('use_frameworks!')));
    expect(iosPodfile, contains('use_modular_headers!'));
    expect(
      iosPodfile,
      contains("config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'"),
    );
    expect(iosPodfile, contains('post_integrate do |installer|'));
    expect(iosPodfile, contains('frameworks_build_phase.files.find'));
    expect(iosPodfile, contains("display_name == 'libPods-Runner.a'"));
    expect(iosPodfile, contains('frameworks_group.remove_reference'));
    expect(iosPodfile, contains('frameworks_build_phase.remove_build_file'));
    expect(
      iosPodfile,
      contains("raise 'Missing redundant Pods-Runner library reference'"),
    );
    final iosBuild = _matrixEntry(
      _job(workflow, 'mobile-debug-build'),
      'macos-26',
    );
    expect(iosBuild, contains('flutter build ios --debug --no-codesign'));
    expect(iosBuild, isNot(contains('--simulator')));
    expect(iosProject, isNot(contains('FlutterGeneratedPluginSwiftPackage')));
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

  test('Windows stages Lua with Flutter CMake in a short build tree', () {
    expect(
      windowsCmake,
      contains(r'--cmake-executable "${CMAKE_COMMAND}"'),
    );
    expect(
      windowsCmake,
      contains(r'--build-directory "${LUA_RUNTIME_BUILD}"'),
    );
    expect(luaHostBuilder, contains("'--cmake-executable'"));
    expect(luaHostBuilder, contains("'--build-directory'"));
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
      'packages/cli/pubspec.yaml',
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
