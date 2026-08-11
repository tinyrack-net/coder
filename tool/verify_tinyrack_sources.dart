import 'dart:io';

import 'package:tinest_workspace/src/tinyrack_dependency_verifier.dart';

void main() {
  final violations = const TinyrackDependencyVerifier().verify(
    Directory.current.path,
  );
  if (violations.isEmpty) {
    stdout.writeln('Tinyrack dependency source verification passed.');
    return;
  }
  violations.forEach(stderr.writeln);
  exitCode = 1;
}
