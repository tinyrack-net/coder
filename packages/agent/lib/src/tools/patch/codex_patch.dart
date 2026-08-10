/// One modern Codex `apply_patch` document.
final class CodexPatch {
  /// Creates a parsed patch.
  const CodexPatch(this.operations);

  /// Parses the raw `*** Begin Patch` format without accepting unified diffs.
  factory CodexPatch.parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    if (lines.isEmpty || lines.first != '*** Begin Patch') {
      throw const FormatException('Patch must start with *** Begin Patch.');
    }
    final operations = <CodexPatchOperation>[];
    var index = 1;
    while (index < lines.length && lines[index] != '*** End Patch') {
      final header = lines[index];
      if (header.startsWith('*** Add File: ')) {
        final path = header.substring('*** Add File: '.length).trim();
        index += 1;
        final content = <String>[];
        while (index < lines.length && !lines[index].startsWith('*** ')) {
          final line = lines[index];
          if (!line.startsWith('+')) {
            throw FormatException('Add-file lines must start with +: $line');
          }
          content.add(line.substring(1));
          index += 1;
        }
        operations.add(CodexAddFile(path: path, content: content.join('\n')));
        continue;
      }
      if (header.startsWith('*** Delete File: ')) {
        operations.add(
          CodexDeleteFile(
            path: header.substring('*** Delete File: '.length).trim(),
          ),
        );
        index += 1;
        continue;
      }
      if (header.startsWith('*** Update File: ')) {
        final path = header.substring('*** Update File: '.length).trim();
        index += 1;
        String? moveTo;
        if (index < lines.length && lines[index].startsWith('*** Move to: ')) {
          moveTo = lines[index].substring('*** Move to: '.length).trim();
          index += 1;
        }
        final chunks = <CodexPatchChunk>[];
        while (index < lines.length && !lines[index].startsWith('*** ')) {
          if (!lines[index].startsWith('@@')) {
            throw const FormatException('Expected an @@ update section.');
          }
          index += 1;
          final body = <String>[];
          while (index < lines.length &&
              !lines[index].startsWith('@@') &&
              !lines[index].startsWith('*** ')) {
            final line = lines[index];
            if (line.isEmpty && index == lines.length - 1) break;
            if (line.isEmpty ||
                !const <String>{' ', '+', '-'}.contains(line[0])) {
              throw FormatException('Invalid update line: $line');
            }
            body.add(line);
            index += 1;
          }
          chunks.add(CodexPatchChunk(body));
        }
        if (chunks.isEmpty && moveTo == null) {
          throw FormatException('Update for $path contains no sections.');
        }
        operations.add(
          CodexUpdateFile(path: path, moveTo: moveTo, chunks: chunks),
        );
        continue;
      }
      throw FormatException('Unknown patch operation: $header');
    }
    if (index >= lines.length || lines[index] != '*** End Patch') {
      throw const FormatException('Patch must end with *** End Patch.');
    }
    if (operations.isEmpty) {
      throw const FormatException('Patch contains no operations.');
    }
    if (lines.skip(index + 1).any((line) => line.isNotEmpty)) {
      throw const FormatException('Unexpected content after *** End Patch.');
    }
    return CodexPatch(List<CodexPatchOperation>.unmodifiable(operations));
  }

  /// Ordered operations.
  final List<CodexPatchOperation> operations;
}

/// One file operation in a modern patch.
sealed class CodexPatchOperation {
  /// Creates an operation for [path].
  const CodexPatchOperation(this.path);

  /// Workspace-relative path.
  final String path;
}

/// Creates a new file.
final class CodexAddFile extends CodexPatchOperation {
  /// Creates an add operation.
  const CodexAddFile({required String path, required this.content})
    : super(path);

  /// New file contents without the final newline.
  final String content;
}

/// Deletes an existing file.
final class CodexDeleteFile extends CodexPatchOperation {
  /// Creates a delete operation.
  const CodexDeleteFile({required String path}) : super(path);
}

/// Updates and optionally moves an existing file.
final class CodexUpdateFile extends CodexPatchOperation {
  /// Creates an update operation.
  const CodexUpdateFile({
    required String path,
    required this.moveTo,
    required this.chunks,
  }) : super(path);

  /// Optional destination path.
  final String? moveTo;

  /// Ordered context chunks.
  final List<CodexPatchChunk> chunks;

  /// Applies all context-based chunks to [original].
  String apply(String original) {
    final source = original.replaceAll('\r\n', '\n').split('\n');
    if (source.isNotEmpty && source.last.isEmpty) source.removeLast();
    var searchFrom = 0;
    for (final chunk in chunks) {
      final before = <String>[
        for (final line in chunk.lines)
          if (line.startsWith(' ') || line.startsWith('-')) line.substring(1),
      ];
      final after = <String>[
        for (final line in chunk.lines)
          if (line.startsWith(' ') || line.startsWith('+')) line.substring(1),
      ];
      final at = _find(source, before, searchFrom);
      if (at < 0) {
        throw FormatException('Patch context mismatch in $path.');
      }
      source.replaceRange(at, at + before.length, after);
      searchFrom = at + after.length;
    }
    return '${source.join('\n')}\n';
  }

  static int _find(List<String> source, List<String> pattern, int start) {
    if (pattern.isEmpty) return start;
    for (
      var index = start;
      index + pattern.length <= source.length;
      index += 1
    ) {
      var matches = true;
      for (var offset = 0; offset < pattern.length; offset += 1) {
        if (source[index + offset] != pattern[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return index;
    }
    return -1;
  }
}

/// One context-based update section.
final class CodexPatchChunk {
  /// Creates a patch chunk.
  const CodexPatchChunk(this.lines);

  /// Context, removed, and added lines including their prefix marker.
  final List<String> lines;
}
