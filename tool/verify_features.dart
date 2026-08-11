import 'dart:io';

import 'package:tinest_workspace/src/feature_manifest.dart';
import 'package:tinest_workspace/src/feature_verifier.dart';

void main() {
  final violations = FeatureVerifier(
    Directory.current.path,
    contracts: tinestFeatureManifest,
    uiContracts: tinestUiReachabilityManifest,
    uiJourneys: tinestUiJourneyManifest,
  ).verify();
  if (violations.isEmpty) {
    stdout.writeln(
      'Feature verification passed (${tinestFeatureManifest.length} features).',
    );
    return;
  }
  stderr.writeln('Feature verification failed:');
  for (final violation in violations) {
    stderr.writeln('  - $violation');
  }
  exitCode = 1;
}
