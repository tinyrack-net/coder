import 'dart:io';

import 'package:path/path.dart' as p;

/// A dependency or source-level architecture rule violation.
final class ArchitectureViolation {
  /// Creates an [ArchitectureViolation].
  const ArchitectureViolation({
    required this.path,
    required this.line,
    required this.rule,
    required this.message,
  });

  /// The file containing the violation.
  final String path;

  /// The one-based source line, or zero for pubspec violations.
  final int line;

  /// The stable architecture rule identifier.
  final String rule;

  /// A human-readable explanation.
  final String message;

  @override
  String toString() => '$path${line == 0 ? '' : ':$line'} [$rule] $message';
}

/// Verifies package boundaries and application-layer dependency rules.
final class ArchitectureVerifier {
  /// Creates a verifier rooted at [workspaceRoot].
  const ArchitectureVerifier(this.workspaceRoot);

  /// The Pub workspace root to inspect.
  final String workspaceRoot;

  static const Map<String, Set<String>> _allowedInternalDependencies =
      <String, Set<String>>{
        'coder_protocol': <String>{},
        'coder_agent': <String>{'coder_protocol'},
        'coder_provider_openai': <String>{'coder_agent', 'coder_protocol'},
        'coder_client': <String>{'coder_protocol'},
        'coder_cli': <String>{'coder_client', 'coder_protocol'},
        'coder_mcp': <String>{},
        'coder_daemon': <String>{
          'coder_agent',
          'coder_client',
          'coder_mcp',
          'coder_protocol',
          'coder_provider_openai',
        },
        'coder_app': <String>{
          'coder_client',
          'coder_daemon',
          'coder_protocol',
        },
      };

  /// Runs every architecture check and returns all violations.
  List<ArchitectureViolation> verify() {
    final violations = <ArchitectureViolation>[];
    for (final package in _allowedInternalDependencies.keys) {
      final directory = package == 'coder_app'
          ? p.join(workspaceRoot, 'apps', package)
          : p.join(workspaceRoot, 'packages', package);
      violations
        ..addAll(_verifyPubspec(package, directory))
        ..addAll(_verifySources(package, directory));
    }
    return violations;
  }

  List<ArchitectureViolation> _verifyPubspec(
    String package,
    String directory,
  ) {
    final path = p.join(directory, 'pubspec.yaml');
    final dependencies = _productionDependencies(File(path).readAsLinesSync());
    final allowed = _allowedInternalDependencies[package]!;
    return <ArchitectureViolation>[
      for (final dependency in dependencies)
        if (_allowedInternalDependencies.containsKey(dependency) &&
            !allowed.contains(dependency))
          ArchitectureViolation(
            path: p.relative(path, from: workspaceRoot),
            line: 0,
            rule: 'package_dependency_direction',
            message: '$package must not depend on $dependency.',
          ),
    ];
  }

  Set<String> _productionDependencies(List<String> lines) {
    final dependencies = <String>{};
    var inDependencies = false;
    for (final line in lines) {
      if (line == 'dependencies:') {
        inDependencies = true;
        continue;
      }
      if (inDependencies && line.isNotEmpty && !line.startsWith(' ')) break;
      if (!inDependencies) continue;
      final match = RegExp('^  ([a-zA-Z0-9_]+):').firstMatch(line);
      if (match != null) dependencies.add(match.group(1)!);
    }
    return dependencies;
  }

  List<ArchitectureViolation> _verifySources(
    String package,
    String directory,
  ) {
    final lib = Directory(p.join(directory, 'lib'));
    if (!lib.existsSync()) return const <ArchitectureViolation>[];
    final violations = <ArchitectureViolation>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart')) {
        continue;
      }
      violations.addAll(
        verifySource(
          package: package,
          path: p.relative(entity.path, from: workspaceRoot),
          source: entity.readAsStringSync(),
        ),
      );
    }
    return violations;
  }

  /// Verifies one source fixture without touching the filesystem.
  List<ArchitectureViolation> verifySource({
    required String package,
    required String path,
    required String source,
  }) {
    final violations = <ArchitectureViolation>[];
    final lines = source.split('\n');
    final applicationLayer = _isApplicationLayer(package, path);
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final importedPackage = RegExp(
        "import 'package:([a-zA-Z0-9_]+)/",
      ).firstMatch(line)?.group(1);
      if (importedPackage != null &&
          importedPackage != package &&
          _allowedInternalDependencies.containsKey(importedPackage) &&
          !_allowedInternalDependencies[package]!.contains(importedPackage)) {
        violations.add(
          ArchitectureViolation(
            path: path,
            line: index + 1,
            rule: 'source_dependency_direction',
            message: '$package must not import $importedPackage.',
          ),
        );
      }
      if (!applicationLayer) continue;
      for (final forbidden in const <String>[
        "import 'dart:io'",
        'package:dio/',
        'package:drift/',
        'package:file_selector/',
        'package:flutter_secure_storage/',
        'package:path_provider/',
        'package:uuid/',
      ]) {
        if (line.contains(forbidden)) {
          violations.add(
            ArchitectureViolation(
              path: path,
              line: index + 1,
              rule: 'application_infrastructure_import',
              message: 'Application code must not import $forbidden.',
            ),
          );
        }
      }
      for (final forbiddenCall in const <String>[
        'DateTime.now(',
        'Uuid(',
        'Dio(',
        'CoderDatabase(',
        'CoderClient.connect(',
        'Process.',
      ]) {
        if (line.contains(forbiddenCall)) {
          violations.add(
            ArchitectureViolation(
              path: path,
              line: index + 1,
              rule: 'application_concrete_dependency',
              message: 'Inject $forbiddenCall behind a port.',
            ),
          );
        }
      }
    }
    return violations;
  }

  bool _isApplicationLayer(String package, String path) {
    if (package == 'coder_app') {
      return path.endsWith('/controller.dart');
    }
    if (package == 'coder_daemon') {
      return path.endsWith('/agent_service.dart') ||
          path.endsWith('/mcp_service.dart') ||
          path.endsWith('/provider_service.dart');
    }
    return package == 'coder_agent' && path.endsWith('/runtime.dart');
  }
}
