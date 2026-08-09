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

/// Application surfaces on which an E2E scenario must remain executable.
enum FeatureSurface {
  /// Linux, macOS, and Windows desktop runners.
  desktop,

  /// Android and iOS remote-only runners.
  mobile,

  /// The browser build, which is remote-only for the same reason as mobile.
  web,
}

/// One stable, user-observable E2E behavior owned by a feature.
final class FeatureScenario {
  /// Creates an immutable E2E scenario contract.
  const FeatureScenario({
    required this.id,
    required this.description,
    required this.surfaces,
  });

  /// Stable snake-case identifier used in executable test tags.
  final String id;

  /// User-observable outcome and boundary protected by the scenario.
  final String description;

  /// Product surfaces on which this behavior is supported.
  final Set<FeatureSurface> surfaces;
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
    this.e2eScenarios = const <FeatureScenario>[],
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

  /// Executable real-runner behaviors required for this feature.
  final List<FeatureScenario> e2eScenarios;
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
    this.apiPath = 'packages/client/lib/src/api.dart',
    this.routePath = 'packages/app/lib/src/app/router/app_router.dart',
    this.forbiddenProductionTerms = const <String>[],
  });

  /// Pub workspace root.
  final String workspaceRoot;

  /// Complete declared feature catalog.
  final List<FeatureContract> contracts;

  /// Source containing the `CoderApi` interface.
  final String apiPath;

  /// Source containing typed route annotations.
  final String routePath;

  /// Retired security concepts that must not return to production or docs.
  final List<String> forbiddenProductionTerms;

  /// Returns every manifest, public-surface, and test-evidence violation.
  List<FeatureViolation> verify() {
    final violations = <FeatureViolation>[];
    final contractsById = <String, FeatureContract>{};
    final scenariosByFeature = <String, Map<String, FeatureScenario>>{};
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
      if (contract.requiredLayers.contains(FeatureVerificationLayer.e2e) &&
          contract.e2eScenarios.isEmpty) {
        violations.add(
          FeatureViolation('Feature ${contract.id} has no E2E scenarios.'),
        );
      }
      final scenariosById = <String, FeatureScenario>{};
      scenariosByFeature[contract.id] = scenariosById;
      for (final scenario in contract.e2eScenarios) {
        if (scenariosById.containsKey(scenario.id)) {
          violations.add(
            FeatureViolation(
              'Duplicate E2E scenario ${scenario.id} for ${contract.id}.',
            ),
          );
        }
        scenariosById[scenario.id] = scenario;
        if (!RegExp(r'^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$').hasMatch(scenario.id)) {
          violations.add(
            FeatureViolation(
              'E2E scenario ${contract.id}/${scenario.id} must use a stable '
              'snake-case ID.',
            ),
          );
        }
        if (scenario.description.trim().isEmpty) {
          violations.add(
            FeatureViolation(
              'E2E scenario ${contract.id}/${scenario.id} has no description.',
            ),
          );
        }
        if (scenario.surfaces.isEmpty) {
          violations.add(
            FeatureViolation(
              'E2E scenario ${contract.id}/${scenario.id} has no supported '
              'surface.',
            ),
          );
        }
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
    final scenarioEvidence = <String>{};
    final routeEvidence = <String>{};
    final marker = RegExp(
      'feature_test__([a-z0-9_]+)__'
      '(unit|contract|verticalSlice|widget|e2e|platformSmoke)',
    );
    final routeMarker = RegExp('route_test__([a-z0-9_]+)__widget');
    final scenarioMarker = RegExp(
      'feature_scenario__([a-z0-9_]+)__([a-z0-9_]+)__e2e',
    );
    final routesByTag = <String, String>{
      for (final route in routes) _snakeCase(route): route,
    };
    for (final file in _testSources()) {
      final source = file.readAsStringSync();
      final hasSkip = RegExp(r'''\bskip\s*:\s*(true|["'])''').hasMatch(source);
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
        if (hasSkip) {
          violations.add(
            FeatureViolation(
              'Feature evidence for $id cannot use skip in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
        }
        evidence.putIfAbsent(id, () => <FeatureVerificationLayer>{}).add(layer);
      }
      for (final match in scenarioMarker.allMatches(source)) {
        final featureId = match.group(1)!.replaceAll('_', '.');
        final scenarioId = match.group(2)!;
        final scenario = scenariosByFeature[featureId]?[scenarioId];
        if (scenario == null) {
          violations.add(
            FeatureViolation(
              'Unknown E2E scenario tag: $featureId/$scenarioId.',
            ),
          );
          continue;
        }
        if (hasSkip) {
          violations.add(
            FeatureViolation(
              'E2E scenario $featureId/$scenarioId cannot use skip in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
        }
        if (!_hasExecutableScenario(source, match.start)) {
          violations.add(
            FeatureViolation(
              'E2E scenario $featureId/$scenarioId has no executable '
              'testWidgets behavior in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
          continue;
        }
        scenarioEvidence.add('$featureId/$scenarioId');
        evidence
            .putIfAbsent(featureId, () => <FeatureVerificationLayer>{})
            .add(FeatureVerificationLayer.e2e);
      }
      for (final match in routeMarker.allMatches(source)) {
        final tagId = match.group(1)!;
        final route = routesByTag[tagId];
        if (route == null) {
          violations.add(
            FeatureViolation(
              'Unknown route test tag: ${_upperCamelCase(tagId)}',
            ),
          );
          continue;
        }
        if (hasSkip) {
          violations.add(
            FeatureViolation(
              'Route evidence for $route cannot use skip in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
        }
        routeEvidence.add(route);
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
      for (final scenario in contract.e2eScenarios) {
        final key = '${contract.id}/${scenario.id}';
        if (!scenarioEvidence.contains(key)) {
          violations.add(
            FeatureViolation(
              'E2E scenario $key is missing E2E evidence.',
            ),
          );
        }
      }
    }
    for (final route in routes.difference(routeEvidence)) {
      violations.add(
        FeatureViolation('Route $route is missing widget evidence.'),
      );
    }
    for (final file in _productionSources()) {
      final source = file.readAsStringSync();
      for (final term in _effectiveForbiddenProductionTerms) {
        if (source.contains(term)) {
          violations.add(
            FeatureViolation(
              'Forbidden production term $term in '
              '${p.relative(file.path, from: workspaceRoot)}.',
            ),
          );
        }
      }
    }
    return violations;
  }

  List<String> get _effectiveForbiddenProductionTerms =>
      forbiddenProductionTerms.isEmpty
      ? <String>[
          <String>['admin', 'Token'].join(),
          <String>['X-Tinyrack-Coder-', 'Admin'].join(),
          <String>['TINYRACK_CODER_', 'ADMIN_TOKEN'].join(),
          <String>['local_admin_', 'required'].join(),
        ]
      : forbiddenProductionTerms;

  Iterable<File> _productionSources() sync* {
    for (final relativeRoot in <String>['apps', 'packages', 'lib', 'docs']) {
      final directory = Directory(p.join(workspaceRoot, relativeRoot));
      if (!directory.existsSync()) continue;
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File) continue;
        final normalized = p.normalize(entity.path);
        if (normalized.contains('${p.separator}test${p.separator}') ||
            normalized.contains(
              '${p.separator}integration_test${p.separator}',
            ) ||
            normalized.endsWith('.g.dart') ||
            normalized.endsWith('.freezed.dart')) {
          continue;
        }
        if (normalized.endsWith('.dart') || normalized.endsWith('.md')) {
          yield entity;
        }
      }
    }
  }

  String _snakeCase(String value) => value
      .replaceAllMapped(
        RegExp('(?<=[a-z0-9])(?=[A-Z])'),
        (_) => '_',
      )
      .toLowerCase();

  String _upperCamelCase(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();

  bool _hasExecutableScenario(String source, int markerOffset) {
    final testStart = source.lastIndexOf('testWidgets(', markerOffset);
    if (testStart < 0) return false;
    final body = source.substring(testStart, markerOffset);
    return body.contains('await ') && body.contains('expect(');
  }

  Set<String> _apiMethods(String source) {
    final methods = _interfaceMethods(source, 'CoderApi');
    const features = <String, String>{
      'WorkspacesApi': 'workspaces',
      'SessionsApi': 'sessions',
      'AgentsApi': 'agents',
      'PromptsApi': 'prompts',
      'ProvidersApi': 'providers',
      'McpApi': 'mcp',
      'TerminalsApi': 'terminals',
      'AttachmentsApi': 'attachments',
      'RelayApi': 'relay',
    };
    for (final MapEntry(key: interfaceName, value: owner) in features.entries) {
      methods.addAll(
        _interfaceMethods(
          source,
          interfaceName,
        ).map((method) => '$owner.$method'),
      );
    }
    return methods;
  }

  Set<String> _interfaceMethods(String source, String interfaceName) {
    final declaration = RegExp(
      'abstract interface class $interfaceName\\s*\\{',
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
