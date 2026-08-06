import 'dart:io' show FileSystemException;

import 'package:file/file.dart' as file_api;

/// One parsed line of a gitignore file.
///
/// A pattern is compiled to a [RegExp] once, because the walker tests every
/// pattern against every entry it visits and a repository has far more entries
/// than patterns.
class GitignorePattern {
  /// Creates a [GitignorePattern].
  const GitignorePattern({
    required this.negated,
    required this.directoryOnly,
    required this.expression,
  });

  /// Parses one line, or returns null when the line carries no pattern.
  ///
  /// Blank lines and comments are the two cases git ignores outright.
  static GitignorePattern? parse(String line) {
    var body = _stripTrailingSpaces(line);
    if (body.isEmpty) return null;
    // A comment cannot be escaped away by anything but a leading backslash.
    if (body.startsWith('#')) return null;
    if (body.startsWith(r'\#')) body = body.substring(1);

    var negated = false;
    if (body.startsWith('!')) {
      negated = true;
      body = body.substring(1);
    } else if (body.startsWith(r'\!')) {
      body = body.substring(1);
    }
    if (body.isEmpty) return null;

    var directoryOnly = false;
    if (body.endsWith('/') && !body.endsWith(r'\/')) {
      directoryOnly = true;
      body = body.substring(0, body.length - 1);
    }
    if (body.isEmpty) return null;

    // A slash anywhere but the end anchors the pattern to the directory the
    // gitignore file lives in; without one it matches at any depth.
    final anchored = body.substring(0, body.length - 1).contains('/');
    if (body.startsWith('/')) body = body.substring(1);
    if (body.isEmpty) return null;

    return GitignorePattern(
      negated: negated,
      directoryOnly: directoryOnly,
      expression: RegExp('^${_toRegExp(body, anchored: anchored)}\$'),
    );
  }

  /// Whether a match re-includes the entry instead of ignoring it.
  final bool negated;

  /// Whether the pattern only ever matches directories.
  final bool directoryOnly;

  /// Compiled matcher, applied to a path relative to the owning directory.
  final RegExp expression;

  /// Whether [relativePath] matches, given whether it names a directory.
  bool matches(String relativePath, {required bool isDirectory}) {
    if (directoryOnly && !isDirectory) return false;
    return expression.hasMatch(relativePath);
  }

  /// Drops trailing whitespace unless the last space was escaped.
  static String _stripTrailingSpaces(String line) {
    var end = line.length;
    while (end > 0 && (line[end - 1] == ' ' || line[end - 1] == '\t')) {
      // An escaped space is part of the pattern, and the backslash before it
      // only counts when it is not itself escaped.
      var backslashes = 0;
      var index = end - 2;
      while (index >= 0 && line[index] == r'\') {
        backslashes += 1;
        index -= 1;
      }
      if (backslashes.isOdd) break;
      end -= 1;
    }
    return line.substring(0, end);
  }

  /// Translates gitignore glob syntax into a regular expression body.
  static String _toRegExp(String pattern, {required bool anchored}) {
    final buffer = StringBuffer();
    // An unanchored pattern may start at any depth, which git expresses as an
    // implicit leading `**/`.
    if (!anchored) buffer.write('(?:.*/)?');
    var index = 0;
    while (index < pattern.length) {
      final char = pattern[index];
      if (char == r'\') {
        // The escaped character is a literal, whatever it is.
        if (index + 1 < pattern.length) {
          buffer.write(RegExp.escape(pattern[index + 1]));
          index += 2;
        } else {
          buffer.write(RegExp.escape(char));
          index += 1;
        }
        continue;
      }
      if (char == '*') {
        final isDouble =
            index + 1 < pattern.length && pattern[index + 1] == '*';
        if (!isDouble) {
          // A single star never crosses a directory boundary.
          buffer.write('[^/]*');
          index += 1;
          continue;
        }
        final followedBySlash =
            index + 2 < pattern.length && pattern[index + 2] == '/';
        final atEnd = index + 2 >= pattern.length;
        if (atEnd) {
          // A trailing `**` matches everything below, including nothing.
          buffer.write('.*');
          index += 2;
          continue;
        }
        if (followedBySlash) {
          // `**/` collapses to "zero or more directories", so `a/**/b` also
          // matches `a/b`.
          buffer.write('(?:.*/)?');
          index += 3;
          continue;
        }
        // `**` not delimited by slashes is treated as a single star by git.
        buffer.write('[^/]*');
        index += 2;
        continue;
      }
      if (char == '?') {
        buffer.write('[^/]');
        index += 1;
        continue;
      }
      if (char == '[') {
        final closing = _findClassEnd(pattern, index);
        if (closing == -1) {
          buffer.write(RegExp.escape(char));
          index += 1;
          continue;
        }
        buffer.write(_toCharacterClass(pattern.substring(index, closing + 1)));
        index = closing + 1;
        continue;
      }
      buffer.write(RegExp.escape(char));
      index += 1;
    }
    return buffer.toString();
  }

  /// Index of the `]` closing the class opened at [start], or -1.
  static int _findClassEnd(String pattern, int start) {
    var index = start + 1;
    if (index < pattern.length &&
        (pattern[index] == '!' || pattern[index] == '^')) {
      index += 1;
    }
    // A `]` in the first position is a literal member, not the terminator.
    if (index < pattern.length && pattern[index] == ']') index += 1;
    while (index < pattern.length) {
      if (pattern[index] == r'\') {
        index += 2;
        continue;
      }
      if (pattern[index] == ']') return index;
      index += 1;
    }
    return -1;
  }

  /// Rewrites a glob character class as a regular-expression one.
  static String _toCharacterClass(String glob) {
    final inner = glob.substring(1, glob.length - 1);
    // Glob negates with `!`; a regular expression uses `^`.
    final negatedClass = inner.startsWith('!') || inner.startsWith('^');
    final body = negatedClass ? inner.substring(1) : inner;
    // A class must never match a separator, or `[a-z]` would cross directories.
    return '[${negatedClass ? '^/' : ''}${body.replaceAll(r'\', r'\\')}]';
  }
}

/// The patterns of one gitignore file, and the directory they apply to.
class GitignoreSource {
  /// Creates a [GitignoreSource].
  const GitignoreSource({required this.basePath, required this.patterns});

  /// Parses [contents] as a gitignore file governing [basePath].
  ///
  /// [basePath] is relative to the workspace root and uses `/` separators; the
  /// root itself is the empty string.
  factory GitignoreSource.parse(String basePath, String contents) =>
      GitignoreSource(
        basePath: basePath,
        patterns: contents
            .split('\n')
            .map((line) => GitignorePattern.parse(_stripCarriageReturn(line)))
            .whereType<GitignorePattern>()
            .toList(growable: false),
      );

  static String _stripCarriageReturn(String line) =>
      line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

  /// Workspace-relative directory this file governs.
  final String basePath;

  /// Patterns in file order; the last one that matches decides.
  final List<GitignorePattern> patterns;

  /// Whether this file ignores [relativePath], or null when it says nothing.
  ///
  /// [relativePath] is relative to the workspace root. Null is distinct from
  /// false: it lets a lower-precedence source keep its own verdict.
  bool? verdict(String relativePath, {required bool isDirectory}) {
    final scoped = _scope(relativePath);
    if (scoped == null) return null;
    bool? decision;
    // Later patterns override earlier ones, so the whole file is scanned rather
    // than short-circuiting on the first hit.
    for (final pattern in patterns) {
      if (pattern.matches(scoped, isDirectory: isDirectory)) {
        decision = !pattern.negated;
      }
    }
    return decision;
  }

  /// Re-expresses [relativePath] relative to [basePath], or null if outside.
  String? _scope(String relativePath) {
    if (basePath.isEmpty) return relativePath;
    final prefix = '$basePath/';
    if (!relativePath.startsWith(prefix)) return null;
    return relativePath.substring(prefix.length);
  }
}

/// Decides whether git would ignore a workspace path.
///
/// Sources are held lowest-precedence first, which is the order git applies
/// them: global excludes, then `.git/info/exclude`, then every `.gitignore`
/// from the workspace root down to the entry's own directory.
class GitignoreMatcher {
  /// Creates a [GitignoreMatcher] over an ordered list of [sources].
  GitignoreMatcher(this.sources);

  /// A matcher that ignores nothing.
  GitignoreMatcher.empty() : sources = const <GitignoreSource>[];

  /// Sources in ascending precedence.
  final List<GitignoreSource> sources;

  /// Returns a matcher with [source] appended at the highest precedence.
  GitignoreMatcher push(GitignoreSource source) =>
      GitignoreMatcher(<GitignoreSource>[...sources, source]);

  /// Whether git would ignore [relativePath].
  bool isIgnored(String relativePath, {required bool isDirectory}) {
    var ignored = false;
    for (final source in sources) {
      final verdict = source.verdict(relativePath, isDirectory: isDirectory);
      if (verdict != null) ignored = verdict;
    }
    return ignored;
  }
}

/// Where a loader may look for git configuration outside the workspace.
///
/// This is passed in rather than read from the ambient environment so that a
/// test can never pick up the excludes file of whoever is running it — the
/// same reason every other host boundary here is a port.
class GitignoreEnvironment {
  /// Creates a [GitignoreEnvironment].
  const GitignoreEnvironment({this.home, this.xdgConfigHome});

  /// An environment with no user-level git configuration at all.
  const GitignoreEnvironment.none() : home = null, xdgConfigHome = null;

  /// Reads the locations out of [environment], for use in a composition root.
  factory GitignoreEnvironment.fromEnvironment(
    Map<String, String> environment,
  ) {
    String? nonEmpty(String? value) =>
        value != null && value.isNotEmpty ? value : null;
    return GitignoreEnvironment(
      home:
          nonEmpty(environment['HOME']) ?? nonEmpty(environment['USERPROFILE']),
      xdgConfigHome: nonEmpty(environment['XDG_CONFIG_HOME']),
    );
  }

  /// The user's home directory, or null when there is none to consult.
  final String? home;

  /// `XDG_CONFIG_HOME`, which outranks [home] when set.
  final String? xdgConfigHome;
}

/// Loads the gitignore sources that apply outside the working tree.
///
/// These are the two git consults before any `.gitignore`: the user's global
/// excludes file and the repository's own `.git/info/exclude`.
class GitignoreLoader {
  /// Creates a [GitignoreLoader].
  const GitignoreLoader({
    required this._fileSystem,
    this.environment = const GitignoreEnvironment.none(),
  });

  /// Where user-level git configuration lives.
  final GitignoreEnvironment environment;

  final file_api.FileSystem _fileSystem;

  /// Sources that apply to every path in the workspace at [workspaceRoot].
  GitignoreMatcher baseMatcher(String workspaceRoot) {
    final sources = <GitignoreSource>[];
    final global = _globalExcludesFile(workspaceRoot);
    if (global != null) {
      final contents = _read(global);
      if (contents != null) sources.add(GitignoreSource.parse('', contents));
    }
    final info = _read(
      _fileSystem.path.join(workspaceRoot, '.git', 'info', 'exclude'),
    );
    if (info != null) sources.add(GitignoreSource.parse('', info));
    return GitignoreMatcher(sources);
  }

  /// The `.gitignore` governing [directory], or null when there is none.
  ///
  /// [relativeBase] is the workspace-relative, `/`-separated form of
  /// [directory], which is the coordinate space patterns are matched in.
  GitignoreSource? sourceForDirectory(String directory, String relativeBase) {
    final contents = _read(_fileSystem.path.join(directory, '.gitignore'));
    return contents == null
        ? null
        : GitignoreSource.parse(relativeBase, contents);
  }

  /// Resolves `core.excludesFile`, falling back to git's documented default.
  String? _globalExcludesFile(String workspaceRoot) {
    final configured = _configuredExcludesFile(workspaceRoot);
    if (configured != null) return _expandHome(configured);
    final xdg = environment.xdgConfigHome;
    if (xdg != null) return _fileSystem.path.join(xdg, 'git', 'ignore');
    final home = environment.home;
    return home == null
        ? null
        : _fileSystem.path.join(home, '.config', 'git', 'ignore');
  }

  /// Reads `core.excludesFile` from the config files git would consult.
  ///
  /// Later files win, matching git's precedence: system and user config are
  /// overridden by the repository's own.
  String? _configuredExcludesFile(String workspaceRoot) {
    final home = environment.home;
    final xdg = environment.xdgConfigHome;
    final candidates = <String>[
      if (xdg != null) _fileSystem.path.join(xdg, 'git', 'config'),
      if (home != null) _fileSystem.path.join(home, '.gitconfig'),
      _fileSystem.path.join(workspaceRoot, '.git', 'config'),
    ];
    String? found;
    for (final candidate in candidates) {
      final contents = _read(candidate);
      if (contents == null) continue;
      final value = _readCoreExcludesFile(contents);
      if (value != null) found = value;
    }
    return found;
  }

  /// Extracts `excludesfile` from the `[core]` section of a git config.
  ///
  /// Only that one key is understood; anything else in the file is skipped
  /// rather than parsed, because nothing here needs it.
  static String? _readCoreExcludesFile(String contents) {
    var inCore = false;
    String? value;
    for (final raw in contents.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }
      if (line.startsWith('[')) {
        final close = line.indexOf(']');
        final header = close > 1 ? line.substring(1, close).trim() : '';
        inCore = header.toLowerCase() == 'core';
        continue;
      }
      if (!inCore) continue;
      final separator = line.indexOf('=');
      if (separator == -1) continue;
      final key = line.substring(0, separator).trim().toLowerCase();
      if (key != 'excludesfile') continue;
      value = _unquote(line.substring(separator + 1).trim());
    }
    return value;
  }

  static String _unquote(String value) =>
      value.length >= 2 && value.startsWith('"') && value.endsWith('"')
      ? value.substring(1, value.length - 1)
      : value;

  String _expandHome(String path) {
    final home = environment.home;
    if (home == null) return path;
    if (path == '~') return home;
    // Only `~/` is expanded; `~user` names another account, which nothing here
    // can resolve and git itself only supports through the OS.
    return path.startsWith('~/')
        ? _fileSystem.path.join(home, path.substring(2))
        : path;
  }

  String? _read(String path) {
    try {
      final file = _fileSystem.file(path);
      return file.existsSync() ? file.readAsStringSync() : null;
    } on FileSystemException {
      return null;
    }
  }
}
