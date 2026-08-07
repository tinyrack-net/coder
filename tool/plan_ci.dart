import 'dart:io';

import 'package:coder_workspace/src/ci_impact_planner.dart';

const String _usage =
    'Usage: dart run tool/plan_ci.dart '
    '[--base=REF | --full] [--github-output=PATH] [--summary=PATH]';

/// Decides which CI jobs a change requires and publishes the decision.
void main(List<String> arguments) {
  String? base;
  String? githubOutput;
  String? summaryPath;
  var full = false;
  for (final argument in arguments) {
    if (argument == '--full') {
      full = true;
    } else if (argument.startsWith('--base=') && argument.length > 7) {
      base = argument.substring(7);
    } else if (argument.startsWith('--github-output=') &&
        argument.length > 16) {
      githubOutput = argument.substring(16);
    } else if (argument.startsWith('--summary=') && argument.length > 10) {
      summaryPath = argument.substring(10);
    } else {
      stderr.writeln(_usage);
      exitCode = 64;
      return;
    }
  }
  if (full == (base != null)) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final planner = CiImpactPlanner(WorkspaceGraph.load(Directory.current.path));
  final CiImpactPlan plan;
  if (full) {
    plan = planner.fullPlan();
  } else {
    final changed = _changedFiles(base!);
    if (changed == null) {
      // A diff this tool cannot read is a diff it cannot scope. Falling back
      // to the full plan keeps a broken base ref from skipping a gate.
      stderr.writeln('Could not diff against $base; running every job.');
      plan = planner.fullPlan();
    } else {
      changed.forEach(stdout.writeln);
      plan = planner.plan(changedFiles: changed);
    }
  }

  final lines =
      plan.outputs.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .toList()
        ..forEach(stdout.writeln);
  if (githubOutput != null) {
    File(githubOutput).writeAsStringSync(
      '${lines.join('\n')}\n',
      mode: FileMode.append,
    );
  }
  if (summaryPath != null) {
    File(summaryPath).writeAsStringSync(plan.summary, mode: FileMode.append);
  }
}

/// The files that differ between [base] and `HEAD`, or `null` when unknown.
List<String>? _changedFiles(String base) {
  final result = Process.runSync('git', <String>[
    'diff',
    '--name-only',
    '--no-renames',
    '$base...HEAD',
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    return null;
  }
  return (result.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
