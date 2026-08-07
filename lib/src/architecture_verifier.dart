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
        'coder_agent': <String>{},
        'coder_client': <String>{'coder_protocol'},
        // The CLI hosts the daemon through `coder-cli daemon start`, so it
        // reaches the daemon's composition root and everything the daemon
        // itself is allowed to use.
        'coder_cli': <String>{
          'coder_agent',
          'coder_client',
          'coder_daemon',
          'coder_protocol',
        },
        'coder_daemon': <String>{
          'coder_agent',
          'coder_client',
          'coder_protocol',
        },
        'coder_app': <String>{
          'coder_client',
          'coder_daemon',
          'coder_protocol',
        },
      };

  // Vendor identifiers that must never appear outside an adapter package.
  //
  // A vendor's name in shared code is how the last refactor's leaks began: a
  // ChatGPT gateway in the daemon, an id switch in the settings page, an enum
  // of one vendor's flows in the CLI. Everything vendor-specific now lives in
  // coder_provider_* packages; the one legitimate mention elsewhere is the
  // daemon's composition root, which assembles the registry.
  static final RegExp _vendorIdentifier = RegExp(
    'openai|chatgpt|anthropic|deepseek|openrouter|groq|ollama|lmstudio'
    '|vllm|gemini|claude',
    caseSensitive: false,
  );

  // Built-in tool names that must never appear as string literals in the app
  // outside the presenter tree that owns them.
  //
  // One tool's name used to reach the UI through six literal sites; the
  // presenters in chat/tools/ are now the single place a tool name may be
  // spelled, with the timeline's dedicated card builders as the documented
  // exception because they hold per-turn state a presenter cannot.
  static final RegExp _quotedToolName = RegExp(
    "'(list_directory|read_file|search_text|glob|update_plan|apply_patch"
    '|attach_file|read_attachment|view_image|ask_user|current_time|sleep'
    '|exec_command|write_stdin|tool_search|list_skills|get_context_remaining'
    '|new_context|list_mcp_resources|list_mcp_resource_templates'
    '|read_mcp_resource|spawn_agent|followup_task|wait_agent|interrupt_agent'
    "|list_agents)'",
  );

  static bool _mayNameVendors(String package, String path) =>
      package == 'coder_daemon' &&
      (path.contains('/features/providers/infrastructure/') ||
          path.contains('/bootstrap/'));

  static bool _mayNameTools(String package, String path) {
    if (package != 'coder_app') return true;
    return path.contains('/features/conversation/presentation/tools/') ||
        path.endsWith(
          '/features/conversation/application/chat_timeline_model.dart',
        );
  }

  // Packages resolved from outside this workspace that must still stay behind
  // one boundary. `ptyworld` spawns native pseudo-terminals, so only the
  // daemon's terminal gateway may reach it; every other package goes through
  // the daemon. Without this map those imports would be unrestricted, because
  // enforcement is otherwise keyed off `_allowedInternalDependencies`, and
  // that failure would be silent.
  static const Map<String, Set<String>> _restrictedExternalPackages =
      <String, Set<String>>{
        'ptyworld': <String>{'coder_daemon'},
      };

  /// Whether [consumer] is forbidden from depending on [dependency].
  static bool _isForbidden(String consumer, String dependency) {
    if (_allowedInternalDependencies.containsKey(dependency)) {
      return !(_allowedInternalDependencies[consumer] ?? const <String>{})
          .contains(dependency);
    }
    final allowedConsumers = _restrictedExternalPackages[dependency];
    return allowedConsumers != null && !allowedConsumers.contains(consumer);
  }

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
    return <ArchitectureViolation>[
      for (final dependency in dependencies)
        if (_isForbidden(package, dependency))
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
          entity.path.endsWith('.freezed.dart') ||
          entity.path.contains('${p.separator}l10n${p.separator}gen')) {
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
      if (package == 'coder_app') {
        violations.addAll(
          _verifyCoderAppLayerImport(path: path, line: index + 1, source: line),
        );
      }
      if (importedPackage != null &&
          importedPackage != package &&
          _isForbidden(package, importedPackage)) {
        violations.add(
          ArchitectureViolation(
            path: path,
            line: index + 1,
            rule: 'source_dependency_direction',
            message: '$package must not import $importedPackage.',
          ),
        );
      }
      if (package == 'coder_daemon' &&
          (path.contains('/domain/') || path.contains('/application/')) &&
          importedPackage == 'coder_protocol') {
        violations.add(
          ArchitectureViolation(
            path: path,
            line: index + 1,
            rule: 'application_protocol_dependency',
            message:
                'Daemon domain and application code must map protocol DTOs '
                'at a transport boundary.',
          ),
        );
      }
      if (!_mayNameVendors(package, path) && _vendorIdentifier.hasMatch(line)) {
        violations.add(
          ArchitectureViolation(
            path: path,
            line: index + 1,
            rule: 'vendor_literal',
            message:
                'Vendor names belong in a coder_provider_* package or the '
                'daemon composition root, not in shared code.',
          ),
        );
      }
      if (!_mayNameTools(package, path) && _quotedToolName.hasMatch(line)) {
        violations.add(
          ArchitectureViolation(
            path: path,
            line: index + 1,
            rule: 'tool_name_literal',
            message:
                'Tool names in the app belong to their chat/tools/ '
                'presenter, not to shared code.',
          ),
        );
      }
      if (!applicationLayer) continue;
      for (final forbidden in const <String>[
        "import 'dart:io'",
        'package:dio/',
        'package:drift/',
        'package:file_selector/',
        'package:flutter/material.dart',
        'package:flutter/services.dart',
        'package:flutter/widgets.dart',
        'package:flutter_secure_storage/',
        'package:go_router/',
        'package:launch_at_startup/',
        'package:path_provider/',
        'package:share_plus/',
        'package:shared_preferences/',
        'package:tinyrack_ui/',
        'package:tray_manager/',
        'package:url_launcher/',
        'package:uuid/',
        'package:window_manager/',
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
      return path.contains('/src/features/') && path.contains('/application/');
    }
    if (package == 'coder_daemon') {
      return path.contains('/application/') ||
          path.endsWith('/agent_service.dart') ||
          path.endsWith('/session_interactions.dart') ||
          path.endsWith('/session_settings.dart') ||
          path.endsWith('/mcp_service.dart') ||
          path.endsWith('/mcp_server_service.dart') ||
          path.endsWith('/provider_service.dart') ||
          path.endsWith('/workspace_service.dart');
    }
    return package == 'coder_agent' && path.endsWith('/runtime.dart');
  }

  Iterable<ArchitectureViolation> _verifyCoderAppLayerImport({
    required String path,
    required int line,
    required String source,
  }) sync* {
    final import = RegExp(
      "import 'package:coder_app/src/([^']+)';",
    ).firstMatch(source);
    final importedPath = import?.group(1);

    if (path.contains('/src/shared/') &&
        importedPath?.startsWith('features/') == true) {
      yield ArchitectureViolation(
        path: path,
        line: line,
        rule: 'shared_feature_dependency',
        message: 'Shared code must not depend on a product feature.',
      );
    }

    final sourceFeature = RegExp(
      '/src/features/([^/]+)/',
    ).firstMatch(path)?.group(1);
    final importedFeature = importedPath == null
        ? null
        : RegExp('^features/([^/]+)/').firstMatch(importedPath)?.group(1);
    final importsFeatureView =
        importedPath != null &&
        RegExp(
          '^features/[^/]+/presentation/(pages|widgets)/',
        ).hasMatch(importedPath);
    if (sourceFeature != null &&
        importedFeature != null &&
        sourceFeature != importedFeature &&
        importsFeatureView) {
      yield ArchitectureViolation(
        path: path,
        line: line,
        rule: 'feature_presentation_dependency',
        message:
            "A feature must not import another feature's page or widget; "
            'compose it in app/ or promote a feature-neutral component to '
            'shared/.',
      );
    }

    if (!path.contains('/src/features/') || !path.contains('/domain/')) {
      return;
    }
    final frameworkPackage = RegExp(
      "import 'package:(flutter|flutter_riverpod|riverpod_annotation|go_router|"
      'tinyrack_ui|file_selector|flutter_secure_storage|launch_at_startup|'
      'share_plus|shared_preferences|tray_manager|url_launcher|uuid|'
      'window_manager)/',
    ).hasMatch(source);
    if (frameworkPackage) {
      yield ArchitectureViolation(
        path: path,
        line: line,
        rule: 'domain_framework_dependency',
        message: 'Feature domain code must stay independent of frameworks.',
      );
    }
  }
}
