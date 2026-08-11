import 'package:test/test.dart';
import 'package:tinest_workspace/src/desktop_e2e_runner.dart';
import 'package:tinest_workspace/src/desktop_host.dart';

void main() {
  test('desktop hosts map to Flutter devices and Linux alone uses Xvfb', () {
    final linux = DesktopE2ePlan.forHost(DesktopHost.linux);
    final macos = DesktopE2ePlan.forHost(DesktopHost.macos);
    final windows = DesktopE2ePlan.forHost(DesktopHost.windows);

    expect(linux.device, 'linux');
    expect(linux.commandFor('debug_e2e_test.dart').executable, 'xvfb-run');
    expect(linux.commandFor('debug_e2e_test.dart').arguments, <String>[
      '-a',
      'flutter',
      'test',
      'integration_test/debug_e2e_test.dart',
      '-d',
      'linux',
    ]);
    expect(macos.device, 'macos');
    expect(macos.commandFor('debug_e2e_test.dart').executable, 'flutter');
    expect(windows.device, 'windows');
    expect(windows.commandFor('debug_e2e_test.dart').executable, 'flutter');
    expect(windows.commandFor('debug_e2e_test.dart').runInShell, isTrue);
    expect(macos.commandFor('debug_e2e_test.dart').runInShell, isFalse);
    expect(linux.commandFor('debug_e2e_test.dart').runInShell, isFalse);
    expect(
      windows.commandFor('debug_e2e_test.dart').arguments,
      containsAllInOrder(<String>['-d', 'windows']),
    );
  });

  test('every supported desktop host runs the complete shard list', () {
    for (final host in DesktopHost.values) {
      expect(DesktopE2ePlan.forHost(host).shards, <String>[
        'daemon_workspace_e2e_test.dart',
        'project_worktree_e2e_test.dart',
        'relay_e2e_test.dart',
        'debug_e2e_test.dart',
        'provider_e2e_test.dart',
        'settings_desktop_e2e_test.dart',
        'remote_bootstrap_smoke_test.dart',
      ]);
    }
  });

  test('desktop host parsing rejects unsupported operating systems', () {
    expect(DesktopHost.fromOperatingSystem('linux'), DesktopHost.linux);
    expect(DesktopHost.fromOperatingSystem('macos'), DesktopHost.macos);
    expect(DesktopHost.fromOperatingSystem('windows'), DesktopHost.windows);
    expect(DesktopHost.fromOperatingSystem('android'), isNull);
  });

  test('runner isolates every shard and cleans its temporary home', () async {
    final runtime = _FakeDesktopE2eRuntime();
    final result =
        await DesktopE2eRunner(
          runtime: runtime,
          environment: const <String, String>{'PATH': 'build-tools'},
        ).run(
          DesktopE2ePlan.forHost(DesktopHost.windows),
        );

    expect(result, 0);
    expect(runtime.commands, hasLength(7));
    for (final command in runtime.commands) {
      expect(command.workingDirectory, 'packages/app');
      expect(command.environment, <String, String>{
        'PATH': 'build-tools',
        'TINYRACK_TINEST_HOME': r'C:\temp\tinest-e2e',
        'TINYRACK_TINEST_ALLOW_MULTIPLE_INSTANCES': '1',
      });
    }
    expect(runtime.deletedHomes, <String>[r'C:\temp\tinest-e2e']);
  });

  test('runner stops at the first failed shard and still cleans up', () async {
    final runtime = _FakeDesktopE2eRuntime(exitCodes: <int>[0, 69, 0]);
    final result = await DesktopE2eRunner(runtime: runtime).run(
      DesktopE2ePlan.forHost(DesktopHost.windows),
    );

    expect(result, 69);
    expect(runtime.commands, hasLength(2));
    expect(runtime.deletedHomes, <String>[r'C:\temp\tinest-e2e']);
  });

  test('runner cleans up when process execution throws', () async {
    final runtime = _FakeDesktopE2eRuntime(error: StateError('launch failed'));

    await expectLater(
      DesktopE2eRunner(runtime: runtime).run(
        DesktopE2ePlan.forHost(DesktopHost.windows),
      ),
      throwsStateError,
    );
    expect(runtime.deletedHomes, <String>[r'C:\temp\tinest-e2e']);
  });
}

final class _FakeDesktopE2eRuntime implements DesktopE2eRuntime {
  _FakeDesktopE2eRuntime({this.exitCodes = const <int>[], this.error});

  final List<int> exitCodes;
  final Error? error;
  final List<DesktopE2eCommand> commands = <DesktopE2eCommand>[];
  final List<String> deletedHomes = <String>[];

  @override
  Future<String> createTemporaryHome() async => r'C:\temp\tinest-e2e';

  @override
  Future<void> deleteTemporaryHome(String path) async {
    deletedHomes.add(path);
  }

  @override
  Future<int> run(DesktopE2eCommand command) async {
    commands.add(command);
    if (error case final error?) throw error;
    final index = commands.length - 1;
    return index < exitCodes.length ? exitCodes[index] : 0;
  }
}
