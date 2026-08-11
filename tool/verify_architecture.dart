import 'dart:io';

import 'package:tinest_workspace/src/architecture_verifier.dart';

/// Verifies the repository architecture and exits non-zero on a violation.
void main() {
  final violations = ArchitectureVerifier(Directory.current.path).verify();
  if (violations.isEmpty) {
    stdout.writeln('Architecture verification passed.');
    return;
  }
  violations.forEach(stderr.writeln);
  exitCode = 1;
}
