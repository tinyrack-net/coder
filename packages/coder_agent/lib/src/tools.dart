import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;
import 'dart:typed_data';

import 'package:coder_agent/src/model.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

/// Upper bound on the UTF-8 size of any tool result written to a turn.
///
/// Tool output is persisted verbatim into the conversation history and the
/// timeline, so every tool — built-in or external — shares this single limit.
const int maxToolOutputBytes = 1024 * 1024;

/// Truncates [output] so its UTF-8 encoding fits within [maxToolOutputBytes].
///
/// Truncation happens on a code-unit boundary, so a multi-byte character is
/// dropped whole rather than cut into an invalid sequence.
String truncateToolOutput(String output) {
  final bytes = utf8.encode(output);
  if (bytes.length <= maxToolOutputBytes) return output;
  var end = maxToolOutputBytes;
  while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
    end--;
  }
  return utf8.decode(bytes.sublist(0, end));
}

Map<String, dynamic> _strictObject(
  Map<String, Map<String, dynamic>> properties,
) => <String, dynamic>{
  'type': 'object',
  'properties': properties,
  'required': properties.keys.toList(growable: false),
  'additionalProperties': false,
};

/// WorkspacePathGuard defines a public contract.
class WorkspacePathGuard {
  /// Creates a [WorkspacePathGuard].
  WorkspacePathGuard(
    String workspaceRoot, {
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  }) : _fileSystem = fileSystem,
       _workspaceRoot = fileSystem
           .directory(workspaceRoot)
           .resolveSymbolicLinksSync();

  final file_api.FileSystem _fileSystem;
  final Platform _platform;
  final String _workspaceRoot;

  /// The resolveExisting public API member.
  String resolveExisting(String candidate) {
    final path = _fileSystem.path;
    final lexical = path.isAbsolute(candidate)
        ? candidate
        : path.join(_workspaceRoot, candidate);
    final resolved = _fileSystem.file(lexical).resolveSymbolicLinksSync();
    _assertInside(resolved);
    return resolved;
  }

  /// The resolveWritable public API member.
  String resolveWritable(String candidate) {
    final path = _fileSystem.path;
    final lexical = path.normalize(
      path.isAbsolute(candidate)
          ? candidate
          : path.join(_workspaceRoot, candidate),
    );
    var ancestor = path.dirname(lexical);
    final missingSegments = <String>[path.basename(lexical)];
    while (!_fileSystem.directory(ancestor).existsSync()) {
      final parent = path.dirname(ancestor);
      if (parent == ancestor) {
        throw FileSystemException('No existing writable ancestor.', lexical);
      }
      missingSegments.insert(0, path.basename(ancestor));
      ancestor = parent;
    }
    final resolvedAncestor = _fileSystem
        .directory(ancestor)
        .resolveSymbolicLinksSync();
    final resolved = path.joinAll(<String>[
      resolvedAncestor,
      ...missingSegments,
    ]);
    _assertInside(resolved);
    return resolved;
  }

  void _assertInside(String path) {
    final root = _platform.isWindows
        ? _workspaceRoot.toLowerCase()
        : _workspaceRoot;
    final candidate = _platform.isWindows ? path.toLowerCase() : path;
    if (candidate != root && !_fileSystem.path.isWithin(root, candidate)) {
      throw FileSystemException('Path escapes the workspace.', path);
    }
  }
}

/// ListDirectoryTool defines a public contract.
class ListDirectoryTool extends AgentTool {
  /// Creates a [ListDirectoryTool].
  ListDirectoryTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  @override
  String get name => 'list_directory';
  @override
  String get description =>
      'List direct children of a directory inside the workspace.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'path': <String, dynamic>{'type': 'string'},
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final path = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final entries = await _fileSystem
        .directory(path)
        .list(followLinks: false)
        .toList();
    entries.sort((a, b) => a.path.compareTo(b.path));
    return ToolResult(
      output: jsonEncode(
        entries
            .map(
              (entry) => <String, dynamic>{
                'name': p.basename(entry.path),
                'type': switch (entry) {
                  file_api.Directory() => 'directory',
                  file_api.File() => 'file',
                  file_api.Link() => 'link',
                  _ => 'other',
                },
              },
            )
            .toList(growable: false),
      ),
    );
  }
}

/// ReadFileTool defines a public contract.
class ReadFileTool extends AgentTool {
  /// Creates a [ReadFileTool].
  ReadFileTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  @override
  String get name => 'read_file';
  @override
  String get description => 'Read UTF-8 text from a file inside the workspace.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'path': <String, dynamic>{'type': 'string'},
        'offset': <String, dynamic>{
          'type': <String>['integer', 'null'],
        },
        'limit': <String, dynamic>{
          'type': <String>['integer', 'null'],
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final path = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final lines = const LineSplitter().convert(
      await _fileSystem.file(path).readAsString(),
    );
    final offset = (arguments['offset'] as int?) ?? 0;
    final limit = (arguments['limit'] as int?) ?? 400;
    if (offset < 0 || limit < 1) {
      throw const FormatException('Invalid offset or limit.');
    }
    final end = (offset + limit).clamp(0, lines.length);
    if (offset >= lines.length) return const ToolResult(output: '');
    return ToolResult(output: lines.sublist(offset, end).join('\n'));
  }
}

/// SearchTextTool defines a public contract.
class SearchTextTool extends AgentTool {
  /// Creates a [SearchTextTool].
  SearchTextTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  static const Set<String> _ignored = <String>{
    '.git',
    '.dart_tool',
    'build',
    'node_modules',
  };

  @override
  String get name => 'search_text';
  @override
  String get description => 'Search workspace text files for a literal string.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'query': <String, dynamic>{'type': 'string'},
        'path': <String, dynamic>{
          'type': <String>['string', 'null'],
        },
        'max_results': <String, dynamic>{
          'type': <String>['integer', 'null'],
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final query = arguments['query'] as String;
    if (query.isEmpty) throw const FormatException('query must not be empty.');
    final guard = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    );
    final root = guard.resolveExisting((arguments['path'] as String?) ?? '.');
    final maxResults = (arguments['max_results'] as int?) ?? 200;
    final matches = <Map<String, dynamic>>[];
    await for (final entity
        in _fileSystem
            .directory(root)
            .list(recursive: true, followLinks: false)) {
      context.cancellation.throwIfCancelled();
      if (entity is! file_api.File ||
          _ignored.any((name) => p.split(entity.path).contains(name))) {
        continue;
      }
      try {
        var lineNumber = 0;
        await for (final line
            in entity
                .openRead()
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
          lineNumber += 1;
          if (line.contains(query)) {
            matches.add(<String, dynamic>{
              'path': p.relative(entity.path, from: context.workspaceRoot),
              'line': lineNumber,
              'text': line.length > 500 ? line.substring(0, 500) : line,
            });
            if (matches.length >= maxResults) {
              return ToolResult(output: jsonEncode(matches));
            }
          }
        }
      } on FormatException {
        continue;
      } on FileSystemException {
        continue;
      }
    }
    return ToolResult(output: jsonEncode(matches));
  }
}

/// ApplyPatchTool defines a public contract.
class ApplyPatchTool extends AgentTool {
  /// Creates a [ApplyPatchTool].
  ApplyPatchTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
    String Function()? temporarySuffix,
  }) : _temporarySuffix = temporarySuffix ?? _nextTemporarySuffix;

  static int _temporaryCounter = 0;

  static String _nextTemporarySuffix() =>
      'process-${(++_temporaryCounter).toRadixString(16)}';

  final file_api.FileSystem _fileSystem;
  final Platform _platform;
  final String Function() _temporarySuffix;

  @override
  String get name => 'apply_patch';
  @override
  String get description =>
      'Apply a unified diff to UTF-8 files inside the workspace.';
  @override
  ToolRisk get risk => ToolRisk.write;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'patch': <String, dynamic>{'type': 'string'},
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => arguments['patch'] as String;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final patch = UnifiedPatch.parse(arguments['patch'] as String);
    final guard = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    );
    final writes = <String, String>{};
    final deletes = <String>{};
    final originals = <String, String?>{};
    for (final filePatch in patch.files) {
      context.cancellation.throwIfCancelled();
      final relative = filePatch.newPath == '/dev/null'
          ? filePatch.oldPath
          : filePatch.newPath;
      final clean = relative.startsWith('a/') || relative.startsWith('b/')
          ? relative.substring(2)
          : relative;
      final target = guard.resolveWritable(clean);
      final exists = _fileSystem.file(target).existsSync();
      if (filePatch.newPath == '/dev/null' && !exists) {
        throw FormatException('Cannot delete a missing file: $clean');
      }
      final original = exists
          ? await _fileSystem.file(target).readAsString()
          : '';
      originals[target] = exists ? original : null;
      writes[target] = filePatch.newPath == '/dev/null'
          ? ''
          : filePatch.apply(original);
      if (filePatch.newPath == '/dev/null') deletes.add(target);
    }

    final applied = <String>[];
    try {
      for (final entry in writes.entries) {
        final original = originals[entry.key];
        if (deletes.contains(entry.key) && original != null) {
          await _fileSystem.file(entry.key).delete();
        } else {
          await _fileSystem
              .directory(p.dirname(entry.key))
              .create(recursive: true);
          final temporary = _fileSystem.file(
            '${entry.key}.coder-tmp-${_temporarySuffix()}',
          );
          await temporary.writeAsString(entry.value, flush: true);
          await temporary.rename(entry.key);
        }
        applied.add(entry.key);
      }
    } catch (_) {
      for (final target in applied.reversed) {
        final original = originals[target];
        if (original == null) {
          if (_fileSystem.file(target).existsSync()) {
            await _fileSystem.file(target).delete();
          }
        } else {
          await _fileSystem.file(target).writeAsString(original, flush: true);
        }
      }
      rethrow;
    }
    return ToolResult(
      output: jsonEncode(<String, dynamic>{'changedFiles': applied.length}),
    );
  }
}

/// RunCommandTool defines a public contract.
class RunCommandTool extends AgentTool {
  /// Creates a [RunCommandTool].
  RunCommandTool({
    this._processManager = const LocalProcessManager(),
    this._platform = const LocalPlatform(),
  });

  final ProcessManager _processManager;
  final Platform _platform;

  @override
  String get name => 'run_command';
  @override
  String get description =>
      'Run a shell command in the workspace and return bounded output.';
  @override
  ToolRisk get risk => ToolRisk.command;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'command': <String, dynamic>{'type': 'string'},
        'timeout_seconds': <String, dynamic>{
          'type': <String>['integer', 'null'],
        },
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => arguments['command'] as String;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final command = arguments['command'] as String;
    final timeout = Duration(
      seconds: (arguments['timeout_seconds'] as int?) ?? 600,
    );
    final executable = _platform.isWindows ? 'powershell.exe' : '/bin/sh';
    final shellArguments = _platform.isWindows
        ? <String>['-NoProfile', '-NonInteractive', '-Command', command]
        : <String>['-lc', command];
    final process = await _processManager.start(
      <String>[executable, ...shellArguments],
      workingDirectory: context.workspaceRoot,
    );
    context.cancellation.onCancel(process.kill);
    final output = BytesBuilder(copy: false);
    final subscriptions = <StreamSubscription<List<int>>>[
      process.stdout.listen((bytes) => _appendBounded(output, bytes)),
      process.stderr.listen((bytes) => _appendBounded(output, bytes)),
    ];
    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();
          throw TimeoutException(
            'Command exceeded ${timeout.inSeconds} seconds.',
          );
        },
      );
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
    final text = utf8.decode(output.takeBytes(), allowMalformed: true);
    context.cancellation.throwIfCancelled();
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'exitCode': exitCode,
        'output': text,
      }),
      isError: exitCode != 0,
    );
  }

  void _appendBounded(BytesBuilder builder, List<int> bytes) {
    final remaining = maxToolOutputBytes - builder.length;
    if (remaining <= 0) return;
    builder.add(
      bytes.length <= remaining ? bytes : bytes.sublist(0, remaining),
    );
  }
}

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
