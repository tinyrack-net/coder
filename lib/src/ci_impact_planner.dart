import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Rewrites [path] with forward slashes, whatever the host separator is.
String toPosixPath(String path) => path.replaceAll(r'\', '/');

/// One package in the Pub workspace.
final class WorkspacePackage {
  /// Creates a [WorkspacePackage].
  const WorkspacePackage({
    required this.name,
    required this.directory,
    required this.isFlutter,
    required this.usesBuildRunner,
    required this.dependencies,
  });

  /// The `name:` field of the package manifest.
  final String name;

  /// The package directory relative to the workspace root, `.` for the root.
  final String directory;

  /// Whether the package depends on the Flutter SDK and needs `flutter test`.
  final bool isFlutter;

  /// Whether the package participates in `melos generate`.
  final bool usesBuildRunner;

  /// Intra-workspace dependencies from both dependency sections.
  final Set<String> dependencies;
}

/// The intra-workspace dependency graph, read from the package manifests.
///
/// The graph is derived rather than declared so it cannot drift from the
/// manifests the way the allowlist in `architecture_verifier.dart` could.
final class WorkspaceGraph {
  /// Creates a graph over [packages], keyed by package name.
  WorkspaceGraph(Map<String, WorkspacePackage> packages)
    : _packages = Map<String, WorkspacePackage>.unmodifiable(packages);

  /// Reads every manifest under `apps/`, `packages/` and [root] itself.
  factory WorkspaceGraph.load(String root) {
    final packages = <String, WorkspacePackage>{};
    final directories = <String>[
      root,
      ...<String>['apps', 'packages'].expand((group) {
        final directory = Directory(p.join(root, group));
        if (!directory.existsSync()) return const <String>[];
        return directory
            .listSync()
            .whereType<Directory>()
            .map((entry) => entry.path)
            .toList()
          ..sort();
      }),
    ];
    for (final directory in directories) {
      final manifest = File(p.join(directory, 'pubspec.yaml'));
      if (!manifest.existsSync()) continue;
      final package = _readManifest(
        manifest.readAsStringSync(),
        toPosixPath(p.relative(directory, from: root)),
      );
      packages[package.name] = package;
    }
    // A dependency on a package outside the workspace is not a graph edge.
    return WorkspaceGraph(<String, WorkspacePackage>{
      for (final entry in packages.entries)
        entry.key: WorkspacePackage(
          name: entry.value.name,
          directory: entry.value.directory,
          isFlutter: entry.value.isFlutter,
          usesBuildRunner: entry.value.usesBuildRunner,
          dependencies: entry.value.dependencies
              .where(packages.containsKey)
              .toSet(),
        ),
    });
  }

  static WorkspacePackage _readManifest(String source, String directory) {
    final document = loadYaml(source);
    final manifest = document is YamlMap ? document : YamlMap();
    final dependencies = <String>{};
    var isFlutter = false;
    var usesBuildRunner = false;
    for (final section in <String>['dependencies', 'dev_dependencies']) {
      final entries = manifest[section];
      if (entries is! YamlMap) continue;
      for (final key in entries.keys) {
        final name = key.toString();
        if (name == 'flutter' && section == 'dependencies') isFlutter = true;
        if (name == 'build_runner') usesBuildRunner = true;
        dependencies.add(name);
      }
    }
    return WorkspacePackage(
      name: manifest['name'].toString(),
      directory: directory == '.' ? '.' : directory,
      isFlutter: isFlutter,
      usesBuildRunner: usesBuildRunner,
      dependencies: dependencies,
    );
  }

  final Map<String, WorkspacePackage> _packages;

  /// Every package name, sorted.
  List<String> get packageNames => _packages.keys.toList()..sort();

  /// The package registered under [name].
  WorkspacePackage package(String name) {
    final package = _packages[name];
    if (package == null) throw ArgumentError.value(name, 'name', 'Unknown');
    return package;
  }

  /// The package owning [directory], or `null` when nothing owns it.
  ///
  /// Both sides are normalised to forward slashes: a manifest path comes from
  /// `p.relative`, which uses the host separator, while a changed path comes
  /// from Git, which always uses `/`.
  String? packageForDirectory(String directory) {
    final wanted = toPosixPath(directory);
    for (final package in _packages.values) {
      if (toPosixPath(package.directory) == wanted) return package.name;
    }
    return null;
  }

  /// [seeds] plus every package that transitively depends on one of them.
  Set<String> dependentsClosure(Iterable<String> seeds) {
    final closure = <String>{...seeds};
    var changed = true;
    while (changed) {
      changed = false;
      for (final package in _packages.values) {
        if (closure.contains(package.name)) continue;
        if (package.dependencies.any(closure.contains)) {
          closure.add(package.name);
          changed = true;
        }
      }
    }
    return closure;
  }
}

/// Which CI jobs a set of changed files requires.
final class CiImpactPlan {
  /// Creates a plan.
  const CiImpactPlan({
    required this.full,
    required this.affectedPackages,
    required this.dartScopes,
    required this.dartCoverageScopes,
    required this.runGenerated,
    required this.runFlutter,
    required this.runCli,
  });

  /// Whether every job runs regardless of the change.
  final bool full;

  /// The changed packages plus their transitive dependents.
  final Set<String> affectedPackages;

  /// Affected non-Flutter packages, sorted, for `dart test`.
  final List<String> dartScopes;

  /// Affected packages the coverage gate covers today, sorted.
  final List<String> dartCoverageScopes;

  /// Whether an affected package participates in `melos generate`.
  final bool runGenerated;

  /// Whether `coder_app` is affected.
  final bool runFlutter;

  /// Whether `coder_cli` is affected.
  final bool runCli;

  /// Whether any Dart package test job has work to do.
  bool get runDartTests => dartScopes.isNotEmpty;

  /// Whether the Dart coverage gate has a package to measure.
  bool get runDartCoverage => dartCoverageScopes.isNotEmpty;

  /// Whether the Linux golden job runs.
  bool get runGolden => runFlutter;

  /// Whether the Linux Debug E2E shards run.
  bool get runE2e => runFlutter;

  /// Whether the web release build runs.
  bool get runWeb => runFlutter;

  /// Whether the Android and iOS Debug builds run.
  bool get runMobileBuild => runFlutter;

  /// Whether the macOS and Windows Debug builds run.
  bool get runDesktopBuild => runFlutter;

  /// The `MELOS_PACKAGES` filter that narrows a Melos script to [dartScopes].
  String get melosPackages => dartScopes.join(',');

  /// The repeated `--scope=` flags `tool/verify_coverage.dart` expects.
  String get coverageScopeFlags =>
      dartCoverageScopes.map((name) => '--scope=$name').join(' ');

  /// The `GITHUB_OUTPUT` key/value pairs this plan publishes.
  Map<String, String> get outputs => <String, String>{
    'full': '$full',
    'melos_packages': melosPackages,
    'coverage_scope_flags': coverageScopeFlags,
    'run_dart_tests': '$runDartTests',
    'run_dart_coverage': '$runDartCoverage',
    'run_generated': '$runGenerated',
    'run_flutter': '$runFlutter',
    'run_golden': '$runGolden',
    'run_e2e': '$runE2e',
    'run_web': '$runWeb',
    'run_mobile_build': '$runMobileBuild',
    'run_desktop_build': '$runDesktopBuild',
    'run_cli': '$runCli',
  };

  /// A Markdown report explaining which jobs run and why.
  String get summary {
    final packages = affectedPackages.isEmpty
        ? '_none_'
        : (affectedPackages.toList()..sort()).join(', ');
    final buffer = StringBuffer('## CI plan\n\n')
      ..writeln(
        full
            ? 'Running every job: the change is workspace-wide or this is not '
                  'a pull request.'
            : 'Running the jobs affected by the change only.',
      )
      ..writeln()
      ..writeln('Affected packages: $packages')
      ..writeln()
      ..writeln('| output | value |')
      ..writeln('| --- | --- |');
    for (final entry in outputs.entries) {
      buffer.writeln('| `${entry.key}` | `${entry.value}` |');
    }
    return buffer.toString();
  }
}

/// Turns a list of changed files into a [CiImpactPlan].
final class CiImpactPlanner {
  /// Creates a planner over [graph].
  const CiImpactPlanner(this.graph);

  /// Packages whose coverage the workflow gates.
  ///
  /// `coder_cli`, `coder_mcp` and `tinyrack_pty` are absent because the
  /// workflow has never gated them; selecting jobs must not widen the gate.
  static const Set<String> coverageGatedPackages = <String>{
    'coder_agent',
    'coder_client',
    'coder_daemon',
    'coder_protocol',
    'coder_provider_openai',
  };

  /// Paths whose change invalidates the whole workspace.
  ///
  /// The root `lib/`, `test/` and `tool/` trees are the verification tooling
  /// itself, so a change there is exactly the change this planner cannot be
  /// trusted to scope.
  static const List<String> workspaceWidePaths = <String>[
    'pubspec.yaml',
    'pubspec.lock',
    'analysis_options.yaml',
    'dart_test.yaml',
    'lib/',
    'test/',
    'tool/',
    '.github/',
  ];

  /// Paths that carry no executable behaviour.
  static const List<String> ignoredPaths = <String>[
    'docs/',
    '.agents/',
    '.vscode/',
    '.idea/',
  ];

  /// The workspace graph the plan closes over.
  final WorkspaceGraph graph;

  /// A plan that runs every job.
  CiImpactPlan fullPlan() => _plan(graph.packageNames.toSet(), full: true);

  /// The plan required by [changedFiles], each repository-relative.
  CiImpactPlan plan({required Iterable<String> changedFiles}) {
    final seeds = <String>{};
    for (final file in changedFiles) {
      final path = p.posix.normalize(toPosixPath(file));
      if (_isIgnored(path)) continue;
      if (_isWorkspaceWide(path)) return fullPlan();
      final owner = _ownerOf(path);
      // An unrecognised path is a path this planner does not model. Running
      // everything is the only answer that cannot silently skip a gate.
      if (owner == null) return fullPlan();
      seeds.add(owner);
    }
    return _plan(graph.dependentsClosure(seeds), full: false);
  }

  bool _isIgnored(String path) =>
      ignoredPaths.any(path.startsWith) ||
      (!path.contains('/') && path.endsWith('.md'));

  bool _isWorkspaceWide(String path) => workspaceWidePaths.any(
    (candidate) => candidate.endsWith('/')
        ? path.startsWith(candidate)
        : path == candidate,
  );

  String? _ownerOf(String path) {
    final segments = p.posix.split(path);
    if (segments.length < 2) return null;
    if (segments.first != 'apps' && segments.first != 'packages') return null;
    return graph.packageForDirectory('${segments[0]}/${segments[1]}');
  }

  CiImpactPlan _plan(Set<String> affected, {required bool full}) {
    final sorted = affected.toList()..sort();
    return CiImpactPlan(
      full: full,
      affectedPackages: affected,
      dartScopes: sorted
          .where((name) => !graph.package(name).isFlutter)
          .toList(),
      dartCoverageScopes: sorted.where(coverageGatedPackages.contains).toList(),
      runGenerated: sorted.any((name) => graph.package(name).usesBuildRunner),
      runFlutter: affected.contains('coder_app'),
      runCli: affected.contains('coder_cli'),
    );
  }
}
