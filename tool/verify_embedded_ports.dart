import 'dart:io';

import 'package:coder_workspace/src/embedded_port_verifier.dart';

/// Verifies E2E daemon port isolation and exits non-zero on a violation.
void main() {
  final violations = EmbeddedPortVerifier(Directory.current.path).verify();
  if (violations.isEmpty) {
    stdout.writeln('Embedded daemon port verification passed.');
    return;
  }
  violations.forEach(stderr.writeln);
  exitCode = 1;
}
