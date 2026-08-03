import 'dart:io';

import 'package:path/path.dart' as p;

/// Verification layers supported by the feature traceability gate.
enum FeatureVerificationLayer {
  /// Pure domain and state-transition tests.
  unit,

  /// Typed protocol and client codec tests.
  contract,

  /// Production service adapters exercised without Flutter UI.
  verticalSlice,

  /// Flutter interaction tests with deterministic ports.
  widget,

  /// Real Flutter runner tests against a real daemon.
  e2e,

  /// Platform bootstrap or compilation smoke tests.
  platformSmoke,
}

/// Declares one user-visible capability and its mandatory evidence.
final class FeatureContract {
  /// Creates an immutable feature contract.
  const FeatureContract({
    required this.id,
    required this.description,
    required this.requiredLayers,
    this.apiMethods = const <String>[],
    this.routes = const <String>[],
  });

  /// Stable dotted identifier used by test tags and reports.
  final String id;

  /// User outcome protected by this contract.
  final String description;

  /// Public client methods owned by the feature.
  final List<String> apiMethods;

  /// Typed Flutter routes owned by the feature.
  final List<String> routes;

  /// Test layers that must contain tagged evidence.
  final Set<FeatureVerificationLayer> requiredLayers;
}

/// One actionable feature verification failure.
final class FeatureViolation {
  /// Creates a violation.
  const FeatureViolation(this.message);

  /// Human-readable failure detail.
  final String message;

  @override
  String toString() => message;
}

/// Checks public surfaces and tagged tests against typed feature contracts.
final class FeatureVerifier {
  /// Creates a verifier rooted at [workspaceRoot].
  const FeatureVerifier(
    this.workspaceRoot, {
    required this.contracts,
    this.apiPath = 'packages/coder_client/lib/src/api.dart',
    this.routePath = 'apps/coder_app/lib/src/app.dart',
  });

  /// Pub workspace root.
  final String workspaceRoot;

  /// Complete declared feature catalog.
  final List<FeatureContract> contracts;

  /// Source containing the `CoderApi` interface.
  final String apiPath;

  /// Source containing typed route annotations.
  final String routePath;

  /// Returns every manifest, public-surface, and test-evidence violation.
  List<FeatureViolation> verify() {
    final violations = <FeatureViolation>[];
    final contractsById = <String, FeatureContract>{};
    final methodOwners = <String, String>{};
    final routeOwners = <String, String>{};
    for (final contract in contracts) {
      if (contractsById.containsKey(contract.id)) {
        violations.add(
          FeatureViolation('Duplicate feature ID: ${contract.id}'),
        );
      }
      contractsById[contract.id] = contract;
      if (contract.description.trim().isEmpty) {
        violations.add(
          FeatureViolation('Feature ${contract.id} has no description.'),
        );
      }
      if (contract.requiredLayers.isEmpty) {
        violations.add(
          FeatureViolation('Feature ${contract.id} has no required layers.'),
        );
      }
      for (final method in contract.apiMethods) {
        final previous = methodOwners[method];
        if (previous != null) {
          violations.add(
            FeatureViolation(
              'CoderApi method $method belongs to both $previous and '
              '${contract.id}.',
            ),
          );
        }
        methodOwners[method] = contract.id;
      }
      for (final route in contract.routes) {
        final previous = routeOwners[route];
        if (previous != null) {
          violations.add(
            FeatureViolation(
              'Route $route belongs to both $previous and ${contract.id}.',
            ),
          );
        }
        routeOwners[route] = contract.id;
      }
    }

    final apiMethods = _apiMethods(
      File(p.join(workspaceRoot, apiPath)).readAsStringSync(),
    );
    for (final method in apiMethods.difference(methodOwners.keys.toSet())) {
      violations.add(FeatureViolation('Unregistered CoderApi method: $method'));
    }
    for (final method in methodOwners.keys.toSet().difference(apiMethods)) {
      violations.add(FeatureViolation('Missing CoderApi method: $method'));
    }

    final routes = _routes(
      File(p.join(workspaceRoot, routePath)).readAsStringSync(),
    );
    for (final route in routes.difference(routeOwners.keys.toSet())) {
      violations.add(FeatureViolation('Unregistered typed route: $route'));
    }
    for (final route in routeOwners.keys.toSet().difference(routes)) {
      violations.add(FeatureViolation('Missing typed route: $route'));
    }

    final evidence = <String, Set<FeatureVerificationLayer>>{};
    final marker = RegExp(
      'feature_test__([a-z0-9_]+)__'
      '(unit|contract|verticalSlice|widget|e2e|platformSmoke)',
    );
    for (final file in _testSources()) {
      final source = file.readAsStringSync();
      for (final match in marker.allMatches(source)) {
        final id = match.group(1)!.replaceAll('_', '.');
        final layerName = match.group(2)!;
        final contract = contractsById[id];
        if (contract == null) {
          violations.add(FeatureViolation('Unknown feature test tag: $id'));
          continue;
        }
        final layer = FeatureVerificationLayer.values
            .where((candidate) => candidate.name == layerName)
            .firstOrNull;
        if (layer == null) {
          violations.add(
            FeatureViolation('Unknown verification layer $layerName for $id.'),
          );
          continue;
        }
        if (RegExp(r'''\bskip\s*:\s*(true|["'])''').hasMatch(source)) {
          violations.add(
            FeatureViolation(
              'Feature evidence for $id cannot use skip in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
        }
        evidence.putIfAbsent(id, () => <FeatureVerificationLayer>{}).add(layer);
      }
    }
    for (final contract in contracts) {
      final observed = evidence[contract.id] ?? <FeatureVerificationLayer>{};
      for (final layer in contract.requiredLayers.difference(observed)) {
        violations.add(
          FeatureViolation(
            'Feature ${contract.id} is missing ${layer.name} evidence.',
          ),
        );
      }
    }
    return violations;
  }

  Set<String> _apiMethods(String source) {
    final declaration = RegExp(
      r'abstract interface class CoderApi\s*\{',
    ).firstMatch(source);
    if (declaration == null) return <String>{};
    var depth = 1;
    var cursor = declaration.end;
    while (cursor < source.length && depth > 0) {
      final character = source[cursor];
      if (character == '{') depth += 1;
      if (character == '}') depth -= 1;
      cursor += 1;
    }
    if (depth != 0) return <String>{};
    final interfaceBody = source.substring(declaration.end, cursor - 1);
    return RegExp(
      r'\bFuture(?:<[^;]+>)?\s+(\w+)\s*\(',
    ).allMatches(interfaceBody).map((match) => match.group(1)!).toSet();
  }

  Set<String> _routes(String source) => RegExp(
    r'@TypedGoRoute<(\w+)>',
  ).allMatches(source).map((match) => match.group(1)!).toSet();

  List<File> _testSources() {
    final files = <File>[];
    for (final root in <Directory>[
      Directory(p.join(workspaceRoot, 'test')),
      Directory(p.join(workspaceRoot, 'packages')),
      Directory(p.join(workspaceRoot, 'apps')),
    ]) {
      if (!root.existsSync()) continue;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = p.normalize(entity.path);
        if (p
            .split(normalized)
            .any(
              (segment) => segment == 'test' || segment == 'integration_test',
            )) {
          files.add(entity);
        }
      }
    }
    return files;
  }
}
