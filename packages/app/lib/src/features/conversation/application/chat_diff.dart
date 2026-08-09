/// Role of one rendered diff line.
enum ChatDiffLineKind {
  /// A `@@ -a,b +c,d @@` hunk header.
  hunkHeader,

  /// A line present only in the new file.
  added,

  /// A line present only in the old file.
  removed,

  /// A line shared by both sides.
  context,
}

/// One rendered diff line with its gutter numbers.
final class ChatDiffLine {
  /// Creates a diff line.
  const ChatDiffLine({
    required this.kind,
    required this.text,
    this.oldLine,
    this.newLine,
  });

  /// How the line should be colored.
  final ChatDiffLineKind kind;

  /// Line content without its leading diff marker.
  final String text;

  /// Line number in the old file, when the line exists there.
  final int? oldLine;

  /// Line number in the new file, when the line exists there.
  final int? newLine;
}

/// All rendered lines of one file inside a unified diff.
final class ChatDiffFile {
  /// Creates a diff file.
  const ChatDiffFile({
    required this.path,
    required this.lines,
    required this.added,
    required this.removed,
  });

  /// Path of the new file, or empty for unparseable input.
  final String path;

  /// Rendered lines in source order.
  final List<ChatDiffLine> lines;

  /// Number of added lines.
  final int added;

  /// Number of removed lines.
  final int removed;
}

final RegExp _hunkPattern = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

/// Parses a unified diff for display; never throws.
///
/// Input that is not a unified diff degrades to a single file of context lines
/// so a tool preview always renders something readable.
List<ChatDiffFile> parseChatDiff(String source) {
  if (source.isEmpty) return const <ChatDiffFile>[];
  final lines = source.split('\n');
  final files = <_DiffFileBuilder>[];
  _DiffFileBuilder? current;
  var oldLine = 0;
  var newLine = 0;

  for (var index = 0; index < lines.length; index += 1) {
    final line = lines[index];
    if (index == lines.length - 1 && line.isEmpty) continue;
    if (line.startsWith('--- ')) {
      final next = index + 1 < lines.length ? lines[index + 1] : '';
      if (next.startsWith('+++ ')) {
        current = _DiffFileBuilder(_stripPathPrefix(next.substring(4)));
        files.add(current);
        oldLine = 0;
        newLine = 0;
        index += 1;
        continue;
      }
    }
    current ??= _DiffFileBuilder('')..isFallback = true;
    if (files.isEmpty) files.add(current);
    final match = _hunkPattern.firstMatch(line);
    if (match != null) {
      oldLine = int.parse(match.group(1)!);
      newLine = int.parse(match.group(2)!);
      current.lines.add(
        ChatDiffLine(kind: ChatDiffLineKind.hunkHeader, text: line),
      );
      continue;
    }
    if (current.isFallback) {
      current.lines.add(
        ChatDiffLine(kind: ChatDiffLineKind.context, text: line),
      );
      continue;
    }
    if (line.startsWith('+')) {
      current.lines.add(
        ChatDiffLine(
          kind: ChatDiffLineKind.added,
          text: line.substring(1),
          newLine: newLine,
        ),
      );
      newLine += 1;
      current.added += 1;
    } else if (line.startsWith('-')) {
      current.lines.add(
        ChatDiffLine(
          kind: ChatDiffLineKind.removed,
          text: line.substring(1),
          oldLine: oldLine,
        ),
      );
      oldLine += 1;
      current.removed += 1;
    } else {
      current.lines.add(
        ChatDiffLine(
          kind: ChatDiffLineKind.context,
          text: line.startsWith(' ') ? line.substring(1) : line,
          oldLine: oldLine,
          newLine: newLine,
        ),
      );
      oldLine += 1;
      newLine += 1;
    }
  }

  return List<ChatDiffFile>.unmodifiable(
    files.map(
      (file) => ChatDiffFile(
        path: file.path,
        lines: List<ChatDiffLine>.unmodifiable(file.lines),
        added: file.added,
        removed: file.removed,
      ),
    ),
  );
}

String _stripPathPrefix(String path) {
  final trimmed = path.trim();
  if (trimmed.startsWith('a/') || trimmed.startsWith('b/')) {
    return trimmed.substring(2);
  }
  return trimmed;
}

final class _DiffFileBuilder {
  _DiffFileBuilder(this.path);

  final String path;
  final List<ChatDiffLine> lines = <ChatDiffLine>[];
  bool isFallback = false;
  int added = 0;
  int removed = 0;
}
