/// UnifiedPatch defines a public contract.
class UnifiedPatch {
  /// Creates a [UnifiedPatch].
  const UnifiedPatch(this.files);

  /// Creates a [UnifiedPatch].
  factory UnifiedPatch.parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final files = <FilePatch>[];
    var index = 0;
    while (index < lines.length) {
      if (!lines[index].startsWith('--- ')) {
        index += 1;
        continue;
      }
      final oldPath = lines[index].substring(4).split('\t').first.trim();
      index += 1;
      if (index >= lines.length || !lines[index].startsWith('+++ ')) {
        throw const FormatException('Missing +++ file header.');
      }
      final newPath = lines[index].substring(4).split('\t').first.trim();
      index += 1;
      final hunks = <PatchHunk>[];
      while (index < lines.length && !lines[index].startsWith('--- ')) {
        if (!lines[index].startsWith('@@ ')) {
          index += 1;
          continue;
        }
        final match = RegExp(
          r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',
        ).firstMatch(lines[index]);
        if (match == null) {
          throw FormatException('Invalid hunk header: ${lines[index]}');
        }
        final oldStart = int.parse(match.group(1)!);
        index += 1;
        final body = <String>[];
        while (index < lines.length &&
            !lines[index].startsWith('@@ ') &&
            !lines[index].startsWith('--- ')) {
          if (lines[index].startsWith(r'\ No newline')) {
            index += 1;
            continue;
          }
          final line = lines[index];
          if (line.isEmpty && index == lines.length - 1) break;
          if (line.isEmpty ||
              !const <String>{' ', '+', '-'}.contains(line[0])) {
            throw FormatException('Invalid patch line: $line');
          }
          body.add(line);
          index += 1;
        }
        hunks.add(PatchHunk(oldStart: oldStart, lines: body));
      }
      files.add(FilePatch(oldPath: oldPath, newPath: newPath, hunks: hunks));
    }
    if (files.isEmpty) throw const FormatException('Patch contains no files.');
    return UnifiedPatch(files);
  }

  /// The files public API member.
  final List<FilePatch> files;
}

/// FilePatch defines a public contract.
class FilePatch {
  /// Creates a [FilePatch].
  const FilePatch({
    required this.oldPath,
    required this.newPath,
    required this.hunks,
  });

  /// The oldPath public API member.
  final String oldPath;

  /// The newPath public API member.
  final String newPath;

  /// The hunks public API member.
  final List<PatchHunk> hunks;

  /// The apply public API member.
  String apply(String original) {
    final source = original.replaceAll('\r\n', '\n').split('\n');
    if (source.isNotEmpty && source.last.isEmpty) source.removeLast();
    final output = <String>[];
    var cursor = 0;
    for (final hunk in hunks) {
      final target = hunk.oldStart == 0 ? 0 : hunk.oldStart - 1;
      if (target < cursor || target > source.length) {
        throw const FormatException('Patch hunk is outside the source file.');
      }
      output.addAll(source.sublist(cursor, target));
      cursor = target;
      for (final line in hunk.lines) {
        final marker = line.isEmpty ? ' ' : line[0];
        final content = line.isEmpty ? '' : line.substring(1);
        if (marker == ' ' || marker == '-') {
          if (cursor >= source.length || source[cursor] != content) {
            throw FormatException(
              'Patch context mismatch near line ${cursor + 1}.',
            );
          }
          if (marker == ' ') output.add(content);
          cursor += 1;
        } else if (marker == '+') {
          output.add(content);
        }
      }
    }
    output.addAll(source.sublist(cursor));
    return '${output.join('\n')}\n';
  }
}

/// PatchHunk defines a public contract.
class PatchHunk {
  /// Creates a [PatchHunk].
  const PatchHunk({required this.oldStart, required this.lines});

  /// The oldStart public API member.
  final int oldStart;

  /// The lines public API member.
  final List<String> lines;
}
