import 'dart:io';

import 'package:coder_workspace/src/coverage_verifier.dart';
import 'package:path/path.dart' as p;

/// Enforces line and branch coverage for every workspace package.
void main(List<String> arguments) {
  final root = Directory.current.path;
  final verifier = CoverageVerifier(root);
  final scopes = <String>{};
  for (final argument in arguments) {
    if (!argument.startsWith('--scope=') || argument.length == 8) {
      stderr.writeln(
        'Usage: dart run tool/verify_coverage.dart [--scope=NAME]...',
      );
      exitCode = 64;
      return;
    }
    scopes.add(argument.substring(8));
  }
  final List<String> packageDirectories;
  try {
    packageDirectories = CoverageWorkspace(
      root,
    ).packageDirectories(scopes: scopes);
  } on UnknownCoverageScopeException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
    return;
  }
  final failures = <String>[];
  for (final directory in packageDirectories) {
    final name = p.basename(directory);
    final totals = verifier.calculate(directory);
    final result = verifier.validate(name, totals);
    stdout.writeln(
      '$name: line=${(totals.lineRate * 100).toStringAsFixed(1)}% '
      'branch=${(totals.branchRate * 100).toStringAsFixed(1)}%',
    );
    if (result != null) failures.add(result);
  }
  if (failures.isEmpty) return;
  failures.forEach(stderr.writeln);
  exitCode = 1;
}
