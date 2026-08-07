import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// One violation of the repository's pinned Tinyrack dependency policy.
final class TinyrackDependencyViolation {
  /// Creates a violation for [path], [package], and [rule].
  const TinyrackDependencyViolation({
    required this.path,
    required this.package,
    required this.rule,
    required this.message,
  });

  /// File containing the invalid declaration.
  final String path;

  /// Package whose source is invalid.
  final String package;

  /// Stable rule identifier used by tests and CI output.
  final String rule;

  /// Human-readable remediation guidance.
  final String message;

  @override
  String toString() => '$path: [$rule] $package: $message';
}

/// Verifies that Tinyrack packages use immutable GitHub commit sources.
final class TinyrackDependencyVerifier {
  /// Creates a stateless verifier.
  const TinyrackDependencyVerifier();

  static final RegExp _commit = RegExp(r'^[0-9a-f]{40}$');
  static const Map<String, _TinyrackSource> _knownSources =
      <String, _TinyrackSource>{
        'tinyrack_ui': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/design.git',
          packagePath: 'packages/ui_flutter',
        ),
        'cliweave': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/dart-packages.git',
          packagePath: 'packages/cliweave',
        ),
        'ptyworld': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/dart-packages.git',
          packagePath: 'packages/ptyworld',
        ),
        'dartage': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/dart-packages.git',
          packagePath: 'packages/dartage',
        ),
        'shipworld': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/dart-packages.git',
          packagePath: 'packages/shipworld',
        ),
        'dropwell': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/flutter-packages.git',
          packagePath: 'packages/dropwell',
        ),
        'termworld': _TinyrackSource(
          repository: 'https://github.com/tinyrack-net/flutter-packages.git',
          packagePath: 'packages/termworld',
        ),
      };
  static const Set<String> _ignoredDirectories = <String>{
    '.dart_tool',
    '.git',
    'build',
    'coverage',
  };

  /// Checks every tracked-style pub manifest and lockfile below [rootPath].
  List<TinyrackDependencyViolation> verify(String rootPath) {
    final violations = <TinyrackDependencyViolation>[];
    final root = Directory(rootPath);
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || _isIgnored(rootPath, entity.path)) continue;
      final basename = p.basename(entity.path);
      if (basename == 'pubspec.yaml') {
        violations.addAll(_verifyManifest(entity));
      } else if (basename == 'pubspec.lock') {
        violations.addAll(_verifyLockfile(entity));
      }
    }
    violations.sort((left, right) {
      final pathOrder = left.path.compareTo(right.path);
      return pathOrder != 0 ? pathOrder : left.package.compareTo(right.package);
    });
    return List<TinyrackDependencyViolation>.unmodifiable(violations);
  }

  bool _isIgnored(String rootPath, String filePath) {
    final relative = p.relative(filePath, from: rootPath);
    return p.split(relative).any(_ignoredDirectories.contains);
  }

  Iterable<TinyrackDependencyViolation> _verifyManifest(File file) sync* {
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) return;
    for (final sectionName in const <String>[
      'dependencies',
      'dev_dependencies',
      'dependency_overrides',
    ]) {
      final section = document[sectionName];
      if (section is! YamlMap) continue;
      for (final entry in section.entries) {
        final package = entry.key;
        if (package is! String) continue;
        final expected = _knownSources[package];
        final git = _gitDescription(entry.value);
        if (expected != null && git == null) {
          yield _violation(
            file,
            package,
            'tinyrack_manifest_source',
            'must use its pinned tinyrack-net Git source, not hosted or path',
          );
          continue;
        }
        if (git == null ||
            (expected == null && !_isTinyrackRepository(git.url))) {
          continue;
        }
        yield* _verifyGitDescription(
          file: file,
          package: package,
          git: git,
          expected: expected,
        );
      }
    }
  }

  Iterable<TinyrackDependencyViolation> _verifyLockfile(File file) sync* {
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) return;
    final packages = document['packages'];
    if (packages is! YamlMap) return;
    for (final entry in packages.entries) {
      final package = entry.key;
      final packageData = entry.value;
      if (package is! String || packageData is! YamlMap) continue;
      final expected = _knownSources[package];
      final source = packageData['source'];
      final description = packageData['description'];
      final git = _lockGitDescription(description);
      if (expected != null && source != 'git') {
        yield _violation(
          file,
          package,
          'tinyrack_lock_source',
          'resolved from $source; expected the pinned tinyrack-net Git source',
        );
        continue;
      }
      if (source != 'git' ||
          git == null ||
          (expected == null && !_isTinyrackRepository(git.url))) {
        continue;
      }
      yield* _verifyGitDescription(
        file: file,
        package: package,
        git: git,
        expected: expected,
      );
      if (!_commit.hasMatch(git.resolvedRef ?? '') ||
          git.resolvedRef != git.ref) {
        yield _violation(
          file,
          package,
          'tinyrack_lock_ref',
          'resolved-ref must equal the declared 40-character commit SHA',
        );
      }
    }
  }

  Iterable<TinyrackDependencyViolation> _verifyGitDescription({
    required File file,
    required String package,
    required _GitDescription git,
    required _TinyrackSource? expected,
  }) sync* {
    if (!_commit.hasMatch(git.ref ?? '')) {
      yield _violation(
        file,
        package,
        'tinyrack_git_ref',
        'ref must be an immutable 40-character lowercase commit SHA',
      );
    }
    final expectedRepository = expected?.repository;
    if (expectedRepository != null && git.url != expectedRepository) {
      yield _violation(
        file,
        package,
        'tinyrack_git_repository',
        'repository must be $expectedRepository',
      );
    }
    final expectedPath = expected?.packagePath ?? 'packages/$package';
    if (git.packagePath != expectedPath) {
      yield _violation(
        file,
        package,
        'tinyrack_git_path',
        'path must be $expectedPath',
      );
    }
  }

  _GitDescription? _gitDescription(Object? dependency) {
    if (dependency is! YamlMap) return null;
    final git = dependency['git'];
    if (git is String) return _GitDescription(url: git);
    if (git is! YamlMap) return null;
    return _GitDescription(
      url: _string(git['url']),
      ref: _string(git['ref']),
      packagePath: _string(git['path']),
    );
  }

  _GitDescription? _lockGitDescription(Object? description) {
    if (description is! YamlMap) return null;
    return _GitDescription(
      url: _string(description['url']),
      ref: _string(description['ref']),
      resolvedRef: _string(description['resolved-ref']),
      packagePath: _string(description['path']),
    );
  }

  String? _string(Object? value) => value is String ? value : null;

  bool _isTinyrackRepository(String? url) =>
      url?.startsWith('https://github.com/tinyrack-net/') ?? false;

  TinyrackDependencyViolation _violation(
    File file,
    String package,
    String rule,
    String message,
  ) => TinyrackDependencyViolation(
    path: file.path,
    package: package,
    rule: rule,
    message: message,
  );
}

final class _TinyrackSource {
  const _TinyrackSource({
    required this.repository,
    required this.packagePath,
  });

  final String repository;
  final String packagePath;
}

final class _GitDescription {
  const _GitDescription({
    this.url,
    this.ref,
    this.resolvedRef,
    this.packagePath,
  });

  final String? url;
  final String? ref;
  final String? resolvedRef;
  final String? packagePath;
}
