import 'dart:io';

import 'package:path/path.dart' as p;

/// Selects the Dart sources the formatter should visit.
///
/// The Dart formatter has no exclude mechanism, so it must be handed an
/// explicit file list. [gitOutput] is the output of
/// `git ls-files --cached --others --exclude-standard -- '*.dart'`, which is
/// every tracked file plus every untracked file Git does not ignore. Deriving
/// the list this way keeps the formatter exactly in step with `.gitignore`, so
/// generated Flutter build output under `build/` stays out without a
/// hand-maintained path list.
///
/// Paths are returned relative to [workspaceRoot], deduplicated, and sorted.
List<String> dartSourcesToFormat({
  required String gitOutput,
  required String workspaceRoot,
}) {
  final sources = <String>{};
  for (final line in gitOutput.split('\n')) {
    final path = line.trim();
    if (path.isEmpty || p.extension(path) != '.dart') continue;
    // A path staged for deletion is still in the index but already gone from
    // the worktree, and the formatter fails on arguments it cannot read.
    if (!File(p.join(workspaceRoot, path)).existsSync()) continue;
    sources.add(path);
  }
  return sources.toList()..sort();
}

/// Splits [sources] into batches of at most [batchSize] paths.
///
/// Windows caps a command line near 32k characters, which this workspace's file
/// count would otherwise approach in a single formatter invocation.
List<List<String>> chunkForCommandLine(
  List<String> sources, {
  required int batchSize,
}) => <List<String>>[
  for (var start = 0; start < sources.length; start += batchSize)
    sources.sublist(
      start,
      start + batchSize < sources.length ? start + batchSize : sources.length,
    ),
];
