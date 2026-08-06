import 'dart:io';

const _shards = <String>[
  'integration_test/daemon_workspace_e2e_test.dart',
  'integration_test/project_worktree_e2e_test.dart',
  'integration_test/debug_e2e_test.dart',
  'integration_test/provider_e2e_test.dart',
  'integration_test/settings_desktop_e2e_test.dart',
  'integration_test/remote_bootstrap_smoke_test.dart',
];

Future<void> main() async {
  // `DaemonConfig.fromEnvironment` otherwise resolves the real user daemon
  // home, whose `daemon.lock` is exclusive machine-wide. Pointing it at a
  // per-run directory lets two checkouts verify at the same time and keeps a
  // shard from ever touching the developer's own daemon state.
  final home = await Directory.systemTemp.createTemp('coder-e2e-home-');
  try {
    for (final shard in _shards) {
      stdout.writeln('Running Linux E2E shard: $shard');
      final process = await Process.start(
        'flutter',
        <String>['test', shard, '-d', 'linux'],
        environment: <String, String>{
          'TINYRACK_CODER_HOME': home.path,
          // The runner is a unique GApplication, so a Coder already running on
          // this machine would take this launch over and leave the tester
          // without a debug connection.
          'TINYRACK_CODER_ALLOW_MULTIPLE_INSTANCES': '1',
        },
        mode: ProcessStartMode.inheritStdio,
      );
      final shardExitCode = await process.exitCode;
      if (shardExitCode != 0) {
        stderr.writeln('Linux E2E shard failed: $shard');
        exitCode = shardExitCode;
        return;
      }
    }
  } finally {
    if (home.existsSync()) home.deleteSync(recursive: true);
  }
}
