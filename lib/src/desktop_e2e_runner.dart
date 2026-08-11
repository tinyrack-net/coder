import 'package:tinest_workspace/src/desktop_host.dart';

/// One process invocation in a desktop E2E run.
final class DesktopE2eCommand {
  /// Creates a process invocation.
  const DesktopE2eCommand({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    this.environment = const <String, String>{},
    this.runInShell = false,
  });

  /// Executable passed to the process runtime.
  final String executable;

  /// Ordered process arguments.
  final List<String> arguments;

  /// Directory from which the process starts.
  final String workingDirectory;

  /// Environment overrides applied to the child process.
  final Map<String, String> environment;

  /// Whether the host shell resolves the executable.
  final bool runInShell;

  /// Returns this command with the supplied environment overrides.
  DesktopE2eCommand withEnvironment(Map<String, String> value) =>
      DesktopE2eCommand(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: value,
        runInShell: runInShell,
      );
}

/// Platform-specific command plan for the complete desktop E2E suite.
final class DesktopE2ePlan {
  const DesktopE2ePlan._({required this.host, required this.device});

  /// Creates the command plan for [host].
  factory DesktopE2ePlan.forHost(DesktopHost host) => DesktopE2ePlan._(
    host: host,
    device: host.name,
  );

  /// Host operating system.
  final DesktopHost host;

  /// Flutter device identifier.
  final String device;

  /// Integration-test shards, in deterministic execution order.
  List<String> get shards => const <String>[
    'daemon_workspace_e2e_test.dart',
    'project_worktree_e2e_test.dart',
    'relay_e2e_test.dart',
    'debug_e2e_test.dart',
    'provider_e2e_test.dart',
    'settings_desktop_e2e_test.dart',
    'remote_bootstrap_smoke_test.dart',
  ];

  /// Builds the process command for one integration-test [shard].
  DesktopE2eCommand commandFor(String shard) {
    final flutterArguments = <String>[
      'test',
      'integration_test/$shard',
      '-d',
      device,
    ];
    return DesktopE2eCommand(
      executable: host == DesktopHost.linux ? 'xvfb-run' : 'flutter',
      arguments: host == DesktopHost.linux
          ? <String>['-a', 'flutter', ...flutterArguments]
          : flutterArguments,
      workingDirectory: 'packages/app',
      // Flutter is a batch file on Windows and requires cmd.exe resolution.
      runInShell: host == DesktopHost.windows,
    );
  }
}

/// Runtime boundary for filesystem and process operations used by E2E.
abstract interface class DesktopE2eRuntime {
  /// Creates one isolated application home for the complete run.
  Future<String> createTemporaryHome();

  /// Executes [command] and returns its process exit code.
  Future<int> run(DesktopE2eCommand command);

  /// Deletes the isolated application home at [path].
  Future<void> deleteTemporaryHome(String path);
}

/// Runs desktop E2E shards sequentially with one isolated application home.
final class DesktopE2eRunner {
  /// Creates a runner backed by [runtime].
  const DesktopE2eRunner({
    required this.runtime,
    this.environment = const <String, String>{},
  });

  /// Filesystem and process boundary.
  final DesktopE2eRuntime runtime;

  /// Host build-tool environment inherited by every shard.
  final Map<String, String> environment;

  /// Runs [plan], stopping at the first failed shard.
  Future<int> run(DesktopE2ePlan plan) async {
    final home = await runtime.createTemporaryHome();
    try {
      for (final shard in plan.shards) {
        final command = plan.commandFor(shard).withEnvironment(
          <String, String>{
            ...environment,
            'TINYRACK_TINEST_HOME': home,
            'TINYRACK_TINEST_ALLOW_MULTIPLE_INSTANCES': '1',
          },
        );
        final shardExitCode = await runtime.run(command);
        if (shardExitCode != 0) return shardExitCode;
      }
      return 0;
    } finally {
      await runtime.deleteTemporaryHome(home);
    }
  }
}
