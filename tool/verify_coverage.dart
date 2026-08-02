import 'dart:io';

import 'package:coder_workspace/src/coverage_verifier.dart';
import 'package:path/path.dart' as p;

/// Enforces line and branch coverage for every workspace package.
void main() {
  final root = Directory.current.path;
  final verifier = CoverageVerifier(root);
  final packageDirectories = <String>[
    ...Directory(
      p.join(root, 'packages'),
    ).listSync().whereType<Directory>().map((directory) => directory.path),
    ...Directory(
      p.join(root, 'apps'),
    ).listSync().whereType<Directory>().map((directory) => directory.path),
  ]..sort();
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
