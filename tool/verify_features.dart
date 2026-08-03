import 'dart:io';

import 'package:coder_workspace/src/feature_manifest.dart';
import 'package:coder_workspace/src/feature_verifier.dart';

void main() {
  final violations = FeatureVerifier(
    Directory.current.path,
    contracts: coderFeatureManifest,
  ).verify();
  if (violations.isEmpty) {
    stdout.writeln(
      'Feature verification passed (${coderFeatureManifest.length} features).',
    );
    return;
  }
  stderr.writeln('Feature verification failed:');
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  exitCode = 1;
}
