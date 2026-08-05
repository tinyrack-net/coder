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
  for (final shard in _shards) {
    stdout.writeln('Running Linux E2E shard: $shard');
    final process = await Process.start(
      'flutter',
      <String>['test', shard, '-d', 'linux'],
      mode: ProcessStartMode.inheritStdio,
    );
    final shardExitCode = await process.exitCode;
    if (shardExitCode != 0) {
      stderr.writeln('Linux E2E shard failed: $shard');
      exitCode = shardExitCode;
      return;
    }
  }
}
