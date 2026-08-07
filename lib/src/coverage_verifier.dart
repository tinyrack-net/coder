import 'dart:io';

import 'package:path/path.dart' as p;

/// Coverage totals for one package or application.
final class CoverageTotals {
  /// Creates [CoverageTotals].
  const CoverageTotals({
    required this.linesFound,
    required this.linesHit,
    required this.branchesFound,
    required this.branchesHit,
    required this.missingFiles,
  });

  /// The number of executable lines in the report.
  final int linesFound;

  /// The number of executable lines hit by tests.
  final int linesHit;

  /// The number of branches in the report.
  final int branchesFound;

  /// The number of branches hit by tests.
  final int branchesHit;

  /// Production sources absent from the LCOV report.
  final List<String> missingFiles;

  /// The fraction of executable lines hit.
  double get lineRate => linesFound == 0 ? 0 : linesHit / linesFound;

  /// The fraction of branches hit.
  double get branchRate => branchesFound == 0 ? 0 : branchesHit / branchesFound;
}

/// Reads LCOV data and enforces per-package coverage thresholds.
final class CoverageVerifier {
  /// Creates a verifier rooted at [workspaceRoot].
  const CoverageVerifier(
    this.workspaceRoot, {
    this.minimumLineRate = 0.9,
    this.minimumBranchRate = 0.8,
  });

  /// The Pub workspace root.
  final String workspaceRoot;

  /// The minimum accepted line coverage fraction.
  final double minimumLineRate;

  /// The minimum accepted branch coverage fraction.
  final double minimumBranchRate;

  /// Calculates coverage for [packageDirectory].
  CoverageTotals calculate(String packageDirectory) {
    final root = p.normalize(p.absolute(packageDirectory));
    final lcov = File(p.join(root, 'coverage', 'lcov.info'));
    if (!lcov.existsSync()) {
      throw StateError('Coverage report not found: ${lcov.path}');
    }
    final records = _parseLcov(lcov.readAsLinesSync(), root);
    final sources = _productionSources(root);
    var linesFound = 0;
    var linesHit = 0;
    var branchesFound = 0;
    var branchesHit = 0;
    final missing = <String>[];
    for (final source in sources) {
      final record = records[source];
      if (record == null) {
        final estimatedLines = _estimatedExecutableLines(File(source));
        if (estimatedLines > 0) {
          missing.add(p.relative(source, from: root));
          linesFound += estimatedLines;
        }
        continue;
      }
      linesFound += record.linesFound;
      linesHit += record.linesHit;
      branchesFound += record.branchesFound;
      branchesHit += record.branchesHit;
    }
    return CoverageTotals(
      linesFound: linesFound,
      linesHit: linesHit,
      branchesFound: branchesFound,
      branchesHit: branchesHit,
      missingFiles: missing,
    );
  }

  /// Returns an error message when [totals] do not meet the thresholds.
  String? validate(String packageName, CoverageTotals totals) {
    if (totals.lineRate >= minimumLineRate &&
        totals.branchRate >= minimumBranchRate &&
        totals.missingFiles.isEmpty) {
      return null;
    }
    final missing = totals.missingFiles.isEmpty
        ? ''
        : ' missing=${totals.missingFiles.join(',')}';
    return '$packageName: line=${_percent(totals.lineRate)} '
        'branch=${_percent(totals.branchRate)}$missing';
  }

  Map<String, _CoverageRecord> _parseLcov(List<String> lines, String root) {
    final records = <String, _CoverageRecord>{};
    String? source;
    var linesFound = 0;
    var linesHit = 0;
    var branchesFound = 0;
    var branchesHit = 0;
    void finish() {
      if (source == null) return;
      records[p.normalize(
        p.isAbsolute(source!) ? source! : p.join(root, source),
      )] = _CoverageRecord(
        linesFound: linesFound,
        linesHit: linesHit,
        branchesFound: branchesFound,
        branchesHit: branchesHit,
      );
      source = null;
      linesFound = 0;
      linesHit = 0;
      branchesFound = 0;
      branchesHit = 0;
    }

    for (final line in lines) {
      if (line.startsWith('SF:')) {
        finish();
        source = line.substring(3);
      } else if (line.startsWith('LF:')) {
        linesFound = int.parse(line.substring(3));
      } else if (line.startsWith('LH:')) {
        linesHit = int.parse(line.substring(3));
      } else if (line.startsWith('BRF:')) {
        branchesFound = int.parse(line.substring(4));
      } else if (line.startsWith('BRH:')) {
        branchesHit = int.parse(line.substring(4));
      } else if (line.startsWith('BRDA:')) {
        branchesFound += 1;
        final count = line.substring(line.lastIndexOf(',') + 1);
        if (count != '-' && int.parse(count) > 0) branchesHit += 1;
      } else if (line == 'end_of_record') {
        finish();
      }
    }
    finish();
    return records;
  }

  List<String> _productionSources(String root) {
    final lib = Directory(p.join(root, 'lib'));
    // Generated sources are excluded for the same reason the analyzer skips
    // them: they are the generator's output, not code anyone can test.
    final generatedDirectory =
        '${p.separator}l10n${p.separator}gen'
        '${p.separator}';
    return <String>[
      for (final entity in lib.listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('.g.dart') &&
            !entity.path.endsWith('.freezed.dart') &&
            !entity.path.contains(generatedDirectory))
          p.normalize(p.absolute(entity.path)),
    ]..sort();
  }

  int _estimatedExecutableLines(File file) {
    final lines = file.readAsLinesSync();
    // Comments are prose: a doc sentence containing "for" must not make an
    // interface-only file count as untested production code.
    final code = lines
        .where((line) => !line.trim().startsWith('//'))
        .join('\n');
    final hasExecutableBody = RegExp(
      r'=>|\b(await|return|throw|if|switch|try|for|while)\b|\bmain\s*\(',
    ).hasMatch(code);
    if (!hasExecutableBody) return 0;
    return lines.where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty &&
          !trimmed.startsWith('//') &&
          trimmed != '{' &&
          trimmed != '}' &&
          trimmed != ');' &&
          !trimmed.startsWith('import ') &&
          !trimmed.startsWith('export ') &&
          !trimmed.startsWith('part ');
    }).length;
  }

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
}

/// Discovers package and application directories for coverage verification.
final class CoverageWorkspace {
  /// Creates a workspace rooted at [workspaceRoot].
  const CoverageWorkspace(this.workspaceRoot);

  /// Pub workspace root.
  final String workspaceRoot;

  /// Returns all packages, or only the requested package [scopes].
  List<String> packageDirectories({Set<String> scopes = const <String>{}}) {
    final directories = <String>[
      ..._childDirectories('apps'),
      ..._childDirectories('packages'),
    ]..sort();
    if (scopes.isEmpty) return directories;
    final available = <String>{
      for (final path in directories) p.basename(path),
    };
    final unknown = scopes.difference(available).toList()..sort();
    if (unknown.isNotEmpty) {
      throw UnknownCoverageScopeException(unknown);
    }
    return directories
        .where((path) => scopes.contains(p.basename(path)))
        .toList(growable: false);
  }

  Iterable<String> _childDirectories(String name) {
    final directory = Directory(p.join(workspaceRoot, name));
    if (!directory.existsSync()) return const <String>[];
    return directory
        .listSync()
        .whereType<Directory>()
        .where((entry) => File(p.join(entry.path, 'pubspec.yaml')).existsSync())
        .map((entry) => entry.path);
  }
}

/// Indicates that coverage verification requested unknown workspace packages.
final class UnknownCoverageScopeException implements Exception {
  /// Creates an exception for sorted [scopes].
  const UnknownCoverageScopeException(this.scopes);

  /// Unknown package names.
  final List<String> scopes;

  @override
  String toString() => 'Unknown coverage package scope: ${scopes.join(', ')}';
}

final class _CoverageRecord {
  const _CoverageRecord({
    required this.linesFound,
    required this.linesHit,
    required this.branchesFound,
    required this.branchesHit,
  });

  final int linesFound;
  final int linesHit;
  final int branchesFound;
  final int branchesHit;
}
