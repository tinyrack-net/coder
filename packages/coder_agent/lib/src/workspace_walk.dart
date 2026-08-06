import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/gitignore.dart';
import 'package:coder_agent/src/model.dart';
import 'package:file/file.dart' as file_api;

/// One file found by a [WorkspaceWalker].
class WalkedFile {
  /// Creates a [WalkedFile].
  const WalkedFile({required this.file, required this.relativePath});

  /// The file itself, on the walker's filesystem.
  final file_api.File file;

  /// Path relative to the workspace root, always `/`-separated.
  ///
  /// Tool output and gitignore patterns both speak this one coordinate space,
  /// so the host separator never leaks into either.
  final String relativePath;
}

/// Walks a workspace directory the way git sees it.
///
/// Shared by the search and glob tools: both need the same traversal, the same
/// ignore rules, and the same cancellation behaviour, and they would drift if
/// each kept its own copy.
class WorkspaceWalker {
  /// Creates a [WorkspaceWalker].
  WorkspaceWalker({
    required file_api.FileSystem fileSystem,
    required this.workspaceRoot,
    required this.respectGitignore,
    GitignoreEnvironment gitignoreEnvironment =
        const GitignoreEnvironment.none(),
  }) : _fileSystem = fileSystem,
       _loader = GitignoreLoader(
         fileSystem: fileSystem,
         environment: gitignoreEnvironment,
       );

  /// Directory every reported path is relative to.
  final String workspaceRoot;

  /// Whether gitignore rules prune the walk.
  final bool respectGitignore;

  final file_api.FileSystem _fileSystem;
  final GitignoreLoader _loader;

  /// Directories skipped whatever the ignore rules say.
  ///
  /// `.git` is not merely noise: walking it can be enormous, and no tool here
  /// has any business reading object storage.
  static const Set<String> _alwaysSkipped = <String>{'.git'};

  /// Emits every file under [start], depth-first and sorted within a level.
  ///
  /// Sorting makes results reproducible across filesystems, which matters
  /// because the callers cap their output and an unstable order would change
  /// which matches survive.
  Stream<WalkedFile> walk(
    String start,
    CancellationToken cancellation,
  ) async* {
    final relativeStart = _relative(start);
    var matcher = respectGitignore
        ? _loader.baseMatcher(workspaceRoot)
        : GitignoreMatcher.empty();
    if (respectGitignore) {
      // The starting directory may sit below the root, so every `.gitignore`
      // on the way down still governs it and has to be collected first.
      for (final ancestor in _ancestorsOf(relativeStart)) {
        final source = _loader.sourceForDirectory(
          _absolute(ancestor),
          ancestor,
        );
        if (source != null) matcher = matcher.push(source);
      }
    }
    yield* _walk(start, relativeStart, matcher, cancellation);
  }

  Stream<WalkedFile> _walk(
    String directory,
    String relativeDirectory,
    GitignoreMatcher inherited,
    CancellationToken cancellation,
  ) async* {
    var matcher = inherited;
    if (respectGitignore) {
      final source = _loader.sourceForDirectory(directory, relativeDirectory);
      if (source != null) matcher = matcher.push(source);
    }

    List<file_api.FileSystemEntity> entries;
    try {
      entries = await _fileSystem
          .directory(directory)
          .list(followLinks: false)
          .toList();
    } on FileSystemException {
      // A directory that vanished or cannot be read is skipped rather than
      // failing the whole walk.
      return;
    }
    entries.sort((left, right) => left.path.compareTo(right.path));

    for (final entry in entries) {
      cancellation.throwIfCancelled();
      final name = _fileSystem.path.basename(entry.path);
      if (_alwaysSkipped.contains(name)) continue;
      final relativePath = relativeDirectory.isEmpty
          ? name
          : '$relativeDirectory/$name';
      if (entry is file_api.Directory) {
        // Pruning here is what makes git's rule hold: nothing inside an
        // ignored directory can be re-included by a later negation.
        if (matcher.isIgnored(relativePath, isDirectory: true)) continue;
        yield* _walk(entry.path, relativePath, matcher, cancellation);
        continue;
      }
      if (entry is! file_api.File) continue;
      if (matcher.isIgnored(relativePath, isDirectory: false)) continue;
      yield WalkedFile(file: entry, relativePath: relativePath);
    }
  }

  /// Every directory between the workspace root and [relativePath], inclusive
  /// of the root and exclusive of [relativePath] itself.
  Iterable<String> _ancestorsOf(String relativePath) sync* {
    yield '';
    if (relativePath.isEmpty) return;
    final segments = relativePath.split('/');
    final walked = <String>[];
    // The last segment is the starting directory, whose own `.gitignore` is
    // pushed by the traversal itself.
    for (final segment in segments.take(segments.length - 1)) {
      walked.add(segment);
      yield walked.join('/');
    }
  }

  String _absolute(String relativePath) => relativePath.isEmpty
      ? workspaceRoot
      : _fileSystem.path.joinAll(<String>[
          workspaceRoot,
          ...relativePath.split('/'),
        ]);

  String _relative(String absolutePath) {
    final relative = _fileSystem.path.relative(
      absolutePath,
      from: workspaceRoot,
    );
    if (relative == '.') return '';
    return _fileSystem.path.split(relative).join('/');
  }
}
