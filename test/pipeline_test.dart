import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Matrix entries `changes` narrows for a pull request and expands otherwise.
final Map<String, dynamic> _matrices =
    jsonDecode(File('.github/ci-matrices.json').readAsStringSync())
        as Map<String, dynamic>;

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
  final windowsInstaller = File(
    'packages/app/windows/installer/tinest.iss',
  ).readAsStringSync();
  final cliSmoke = File(
    '.github/actions/smoke-cli-bundle/action.yml',
  ).readAsStringSync();
  final luaHostBuilder = File('tool/build_lua_host.dart').readAsStringSync();

  test('normal quality jobs do not run in the nightly workflow', () {
    for (final job in <String>[
      'changes',
      'static-linux',
      'generated-linux',
      'dart-tests',
      'flutter-tests',
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'relay-coverage-linux',
      'relay-smoke-linux',
      'golden-linux',
      'debug-e2e-linux',
      'linux-ibus-terminal-e2e',
      'mobile-debug-build',
      'desktop-debug-build',
      'web-build',
      'cli-verify',
    ]) {
      expect(_job(workflow, job), contains("github.event_name != 'schedule'"));
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

  test('the cross-platform suites stay in separate parallel jobs', () {
    // Merging them to pay `setup-flutter` once was tried and measured: on
    // Windows the suites take 7.6 and 4.4 minutes, so one job serialises them
    // into 15.6 and the merge-queue run went 7.7 -> 18.2 minutes. Repeating a
    // setup that now costs under 2 minutes is the cheaper of the two, and the
    // queue gates every merge, so its wall clock is what matters here.
    final dart = _job(workflow, 'dart-tests');
    final flutter = _job(workflow, 'flutter-tests');
    expect(dart, contains('dart run melos test:dart'));
    expect(dart, isNot(contains('dart run melos test:flutter')));
    expect(flutter, contains('dart run melos test:flutter'));
    expect(flutter, isNot(contains('dart run melos test:dart')));
    for (final job in <String>[dart, flutter]) {
      expect(job, contains('macos-26'));
      expect(job, contains('windows-2025'));
    }
    // A single job running both is what the measurement rejected.
    expect(workflow, isNot(contains('\n  cross-platform-tests:\n')));
  });

  test('Windows fetches the SDK archive instead of the Actions cache', () {
    // The cached blob and the published archive are the same size on every
    // host (Windows 1.81 GB against 1.8, macOS 2.08 against 2.1, Linux 1.69
    // against 1.5), so the cache carries no precache bloat and the payload is
    // identical either way. Only throughput differs, and Windows restores at
    // ~6 MB/s against 48 MB/s for the same blob on macOS.
    final setup = File(
      '.github/actions/setup-flutter/action.yml',
    ).readAsStringSync();
    expect(setup, contains(r"cache: ${{ runner.os != 'Windows' }}"));
    expect(setup, isNot(contains('cache: true')));
    // One definition, so no job can quietly opt back into the slow path.
    expect(
      RegExp('setup-flutter').allMatches(workflow).length,
      greaterThan(1),
    );
    expect(workflow, isNot(contains('subosito/flutter-action')));
  });

  test('cross-platform duplicates run in the merge queue, not on every PR', () {
    // macOS is 68% of the bill and these jobs re-run suites the Linux jobs
    // already run. The merge queue is an active ALLGREEN ruleset, so it still
    // blocks `main`; only the per-pull-request copy goes away.
    for (final job in <String>[
      'dart-tests',
      'flutter-tests',
      'desktop-debug-build',
    ]) {
      expect(
        _job(workflow, job),
        contains("github.event_name != 'pull_request'"),
      );
    }
    // Coverage is Linux-only and is what the 90%/80% gate reads, so it must
    // stay on every pull request.
    for (final job in <String>[
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'relay-coverage-linux',
      'relay-smoke-linux',
      'golden-linux',
      'debug-e2e-linux',
      'static-linux',
    ]) {
      expect(
        _job(workflow, job),
        isNot(contains("github.event_name != 'pull_request'")),
      );
    }
  });

  test('scoped matrices keep one host and expand to every queue target', () {
    // Both matrices are chosen in `changes`, so each job body stays single.
    expect(_job(workflow, 'cli-verify'), contains('fromJSON'));
    expect(_job(workflow, 'mobile-debug-build'), contains('fromJSON'));
    expect(_job(workflow, 'changes'), contains('CROSS_PLATFORM'));

    // An empty matrix is a workflow error, not a skipped job, so every `host`
    // list has to stay non-empty however the scope is narrowed.
    for (final key in <String>['cli', 'mobile']) {
      final group = _matrices[key]! as Map<String, dynamic>;
      expect(group['host'], isNotEmpty, reason: '$key host matrix is empty');
      expect(group['cross'], isNotEmpty, reason: '$key cross matrix is empty');
    }
    expect(
      (_matrices['cli']! as Map<String, dynamic>)['host'],
      hasLength(1),
      reason: 'a pull request should build one CLI target',
    );
  });

  test('a documentation-only pull request skips the quality matrix', () {
    final scope = _job(workflow, 'changes');
    expect(scope, contains('docs_only'));
    expect(scope, contains('pulls/'));
    // An empty or unreadable diff must not read as documentation-only, or a
    // code change could merge without ever running a gate.
    expect(scope, contains('docs_only=false'));
    expect(scope, contains('verification_scope=full'));
    for (final job in <String>[
      'static-linux',
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'golden-linux',
      'debug-e2e-linux',
      'linux-ibus-terminal-e2e',
      'linux-ibus-terminal-wayland-e2e',
      'web-build',
      'cli-verify',
      'mobile-debug-build',
      'dart-tests',
      'flutter-tests',
      'desktop-debug-build',
    ]) {
      expect(
        _job(workflow, job),
        contains("needs.changes.outputs.docs_only != 'true'"),
      );
    }
  });

  test('pull request jobs follow the conservative change scope', () {
    final scope = _job(workflow, 'changes');
    expect(scope, contains('scope='));
    expect(scope, contains('tool/resolve_ci_scope.dart'));

    expect(
      _job(workflow, 'relay-coverage-linux'),
      contains("needs.changes.outputs.scope == 'relay-only'"),
    );
    expect(
      _job(workflow, 'relay-smoke-linux'),
      contains("needs.changes.outputs.scope == 'relay-only'"),
    );
    for (final job in <String>[
      'generated-linux',
      'coverage-flutter-linux',
      'golden-linux',
      'debug-e2e-linux',
      'linux-ibus-terminal-e2e',
      'linux-ibus-terminal-wayland-e2e',
      'mobile-debug-build',
      'web-build',
    ]) {
      expect(
        _job(workflow, job),
        contains("needs.changes.outputs.scope != 'relay-only'"),
        reason: job,
      );
    }
    for (final job in <String>['coverage-dart-linux', 'cli-verify']) {
      expect(
        _job(workflow, job),
        contains("needs.changes.outputs.scope == 'full'"),
        reason: job,
      );
    }
  });

  test('Dart coverage enforces every non-Flutter package', () {
    final coverage = _job(workflow, 'coverage-dart-linux');
    for (final package in <String>[
      'agent',
      'cli',
      'client',
      'daemon',
      'protocol',
      'relay',
      'relay_protocol',
    ]) {
      expect(coverage, contains('--scope=$package'), reason: package);
    }
    expect(
      _job(workflow, 'relay-coverage-linux'),
      contains('test:coverage:relay'),
    );
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
    expect(release, contains('Tinest-android-universal.apk'));
    expect(release, contains('if: always()'));
    expect(release, isNot(contains('pull_request')));

    final publish = _job(workflow, 'publish-release');
    expect(publish, contains('- build-android-release'));
    expect(publish, contains('pattern: tinest-*'));
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
    expect(relayWorkflow, contains('ghcr.io/tinyrack-net/tinest-relay'));
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

  test('every release version file shipworld writes exists', () {
    // `release prepare` reads each synchronized path before rewriting it, so a
    // path left behind by a package move fails the release itself rather than
    // any earlier gate. Nothing else in the workspace references these files by
    // the name shipworld knows them under.
    final declared = RegExp(
      r'^\s*path:\s*(\S+version\.g\.dart)\s*$',
      multiLine: true,
    ).allMatches(shipworld).map((match) => match.group(1)!).toList();

    expect(declared, hasLength(3));
    for (final path in declared) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'shipworld.yaml writes $path, which does not exist',
      );
    }
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
    // `cli-verify` now takes its matrix from `changes` so a pull request can
    // build the host target alone; the target list lives in the matrix file.
    final cli = _matrices['cli']! as Map<String, dynamic>;
    final verified =
        <dynamic>[
              ...(cli['host']! as List<dynamic>),
              ...(cli['cross']! as List<dynamic>),
            ]
            .cast<Map<String, dynamic>>()
            .map((entry) => entry['target']! as String)
            .toList();
    for (final target in <String>[
      'linux-x64',
      'macos-x64',
      'macos-arm64',
      'windows-x64',
    ]) {
      expect(verified, contains(target));
      expect(release, contains('target: $target'));
    }
    // A queue run has to verify exactly what a tag releases, or the job stops
    // being the thing that catches a release-path breakage.
    expect(verified, hasLength(4));
    // Linux arm64 has no Flutter SDK, so it is not a release target and must
    // not reappear here; `shipworld.yaml` omits it too.
    expect(verified, isNot(contains('linux-arm64')));
    expect(release, isNot(contains('linux-arm64')));
    // A fork pull request has no signing secrets and no release to upload to.
    expect(verify, isNot(contains('APPLE_CERTIFICATE')));
    expect(verify, isNot(contains('upload-artifact')));
  });

  test('CLI smoke waits for daemon readiness before connecting', () {
    expect(cliSmoke, contains('daemon_log='));
    expect(cliSmoke, contains('trap cleanup EXIT'));
    expect(cliSmoke, contains(r'kill -0 "$daemon"'));
    expect(cliSmoke, contains(r'wait "$daemon"'));
    expect(cliSmoke, contains(r'cat "$daemon_log"'));
    expect(cliSmoke, contains('Tinest daemon listening on'));

    final ready = cliSmoke.indexOf('Tinest daemon listening on');
    final connect = cliSmoke.indexOf(r'"$cli" provider list');
    expect(ready, isNonNegative);
    expect(connect, greaterThan(ready));
  });

  test('the aggregate gate requires every quality job', () {
    final gate = _job(workflow, 'quality-gate');
    for (final dependency in <String>[
      'changes',
      'static-linux',
      'generated-linux',
      'dart-tests',
      'flutter-tests',
      'coverage-dart-linux',
      'coverage-flutter-linux',
      'relay-coverage-linux',
      'relay-smoke-linux',
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
    // Scoping jobs out by event or by diff makes them report `skipped`, which
    // the gate has to accept. It must not accept a skip that came from
    // `changes` itself failing, because that skips everything at once.
    expect(
      gate,
      contains('all(.[]; .result == "success" or .result == "skipped")'),
    );
    expect(gate, contains('.changes.result == "success"'));
    expect(gate, isNot(contains('.result == "failure"')));
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
    final androidBuild = _mobileEntry('ubuntu-24.04');
    final iosBuild = _mobileEntry('macos-26');

    expect(androidBuild['gradle_cache'], isTrue);
    expect(iosBuild['gradle_cache'], isFalse);
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
    final iosBuild = _mobileEntry('macos-26');
    expect(
      iosBuild['command'],
      contains('flutter build ios --debug --no-codesign'),
    );
    expect(iosBuild['command'], isNot(contains('--simulator')));
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

  test('Windows release artifacts carry their app-local MSVC runtime', () {
    expect(
      windowsCmake,
      contains('set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)'),
    );
    expect(windowsCmake, contains('include(InstallRequiredSystemLibraries)'));
    expect(
      windowsCmake,
      contains(r'install(PROGRAMS ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}'),
    );
    expect(
      windowsCmake,
      contains(r'DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime'),
    );

    final release = _job(workflow, 'build-and-package');
    expect(release, contains(r'$PWD\packages\app\build\windows\'));
    expect(
      release,
      contains(r'$PWD\packages\app\windows\installer\tinest.iss'),
    );
    expect(release, isNot(contains(r'$PWD\apps\app\')));
    for (final dll in <String>[
      'msvcp140.dll',
      'vcruntime140.dll',
      'vcruntime140_1.dll',
    ]) {
      expect(release, contains(dll));
    }
    expect(release, contains('Test-Path -LiteralPath'));
    expect(release, contains('/VERYSILENT'));
    expect(release, contains('/CURRENTUSER'));
    expect(release, contains('Start-Process'));
    expect(release, contains('-Wait'));
    expect(release, contains('-PassThru'));
    expect(release, contains(r'$installProcess.ExitCode'));
    expect(release, isNot(contains(r'& $installer /VERYSILENT')));
    expect(
      windowsInstaller,
      contains('PrivilegesRequiredOverridesAllowed=commandline dialog'),
    );
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

/// The mobile build matrix entry for [os], from either scope.
Map<String, dynamic> _mobileEntry(String os) {
  final mobile = _matrices['mobile']! as Map<String, dynamic>;
  final entries = <dynamic>[
    ...(mobile['host']! as List<dynamic>),
    ...(mobile['cross']! as List<dynamic>),
  ];
  return entries
          .cast<Map<String, dynamic>>()
          .where((entry) => entry['os'] == os)
          .firstOrNull ??
      (throw StateError('Missing mobile matrix entry for $os'));
}

String _matrixEntry(String job, String os) {
  final start = job.indexOf('          - os: $os\n');
  if (start < 0) throw StateError('Missing matrix entry for $os');
  final next = job.indexOf('          - os:', start + 1);
  return job.substring(start, next < 0 ? job.length : next);
}
