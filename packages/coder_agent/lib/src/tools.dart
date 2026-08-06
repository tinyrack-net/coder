import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/gitignore.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/workspace_walk.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';

/// Upper bound on the UTF-8 size of any tool result written to a turn.
///
/// Tool output is persisted verbatim into the conversation history and the
/// timeline, so every tool — built-in or external — shares this single limit.
const int maxToolOutputBytes = 1024 * 1024;

/// Maximum size of one attachment accepted by the public contract.
const int maxAttachmentBytes = 50 * 1024 * 1024;

/// Copies a workspace file into the daemon-owned immutable attachment store.
abstract interface class AttachmentPublisher {
  /// Publishes the regular file at canonical [path].
  Future<ConversationAttachment> publish(String path);
}

/// Resolves an opaque attachment ID without accepting a filesystem path.
abstract interface class AttachmentReader {
  /// Resolves one daemon-owned attachment reference.
  Future<ConversationAttachment> read(String id);
}

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

/// Builds a schema every strict provider accepts.
///
/// Strict function schemas require every property to be listed in `required`
/// and forbid extra ones, so an optional value is modelled as a nullable type
/// rather than an absent key.
Map<String, dynamic> strictToolObject(
  Map<String, Map<String, dynamic>> properties,
) => <String, dynamic>{
  'type': 'object',
  'properties': properties,
  'required': properties.keys.toList(growable: false),
  'additionalProperties': false,
};

Map<String, dynamic> _strictObject(
  Map<String, Map<String, dynamic>> properties,
) => strictToolObject(properties);

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
                // The injected filesystem's own context, not the host's, is
                // what knows which separator these paths use.
                'name': _fileSystem.path.basename(entry.path),
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

/// Publishes one regular workspace file to the user as an attachment.
class AttachFileTool extends AgentTool {
  /// Creates an attachment publication tool.
  factory AttachFileTool({
    required AttachmentPublisher publisher,
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) => AttachFileTool._(publisher, fileSystem, platform);

  AttachFileTool._(this._publisher, this._fileSystem, this._platform);

  final AttachmentPublisher _publisher;
  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  @override
  String get name => 'attach_file';

  @override
  String get description =>
      'Attach a regular file from the workspace to the conversation.';

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
    final resolved = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final source = _fileSystem.file(resolved);
    final stat = source.statSync();
    if (stat.type != file_api.FileSystemEntityType.file) {
      throw FileSystemException('Attachment must be a regular file.', resolved);
    }
    if (stat.size > maxAttachmentBytes) {
      throw FileSystemException(
        'Attachment exceeds the 50 MB limit.',
        resolved,
      );
    }
    context.cancellation.throwIfCancelled();
    final attachment = await _publisher.publish(resolved);
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'attachmentId': attachment.id,
        'fileName': attachment.fileName,
        'mimeType': attachment.mimeType,
        'byteSize': attachment.byteSize,
      }),
      attachments: <ConversationAttachment>[attachment],
    );
  }
}

/// Resolves attachment metadata and its safe daemon-local fallback path.
class ReadAttachmentTool extends AgentTool {
  /// Creates an ID-based attachment reader.
  factory ReadAttachmentTool({required AttachmentReader reader}) =>
      ReadAttachmentTool._(reader);

  ReadAttachmentTool._(this._reader);

  final AttachmentReader _reader;

  @override
  String get name => 'read_attachment';

  @override
  String get description =>
      'Resolve an attachment ID to validated metadata and a readable path.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'id': <String, dynamic>{'type': 'string'},
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    context.cancellation.throwIfCancelled();
    final attachment = await _reader.read(arguments['id'] as String);
    return ToolResult(output: jsonEncode(attachment.toJson()));
  }
}

/// Longest match line reported before it is cut.
const int maxSearchLineLength = 500;

/// Results one search returns unless the caller asks for fewer.
const int defaultSearchResults = 200;

/// Most lines of surrounding context a match may carry on each side.
const int maxSearchContextLines = 5;

/// Largest file the search will read.
///
/// Reporting context lines means holding a whole file at once, so a file this
/// far past anything hand-written is skipped rather than paged into memory. It
/// is almost certainly data or a build artefact.
const int maxSearchFileBytes = 8 * 1024 * 1024;

/// SearchTextTool defines a public contract.
class SearchTextTool extends AgentTool {
  /// Creates a [SearchTextTool].
  SearchTextTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
    this._gitignoreEnvironment = const GitignoreEnvironment.none(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Where user-level git configuration lives.
  ///
  /// Empty by default so nothing reads the running user's home unless a
  /// composition root deliberately says to.
  final GitignoreEnvironment _gitignoreEnvironment;

  @override
  String get name => 'search_text';
  @override
  String get description =>
      'Search workspace text file contents. Matches a literal string by '
      'default, or a regular expression when regex is true. Files git ignores '
      'are skipped unless include_ignored is set. Use glob to search by file '
      'name instead.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'query': <String, dynamic>{
          'type': 'string',
          'description': 'Text to find, or a regular expression when regex.',
        },
        'path': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description':
              'Directory to search, relative to the workspace root. Null '
              'searches the whole workspace.',
        },
        'regex': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether query is a regular expression. Null and false treat it '
              'as a literal string.',
        },
        'case_sensitive': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether case matters. Null and true match case exactly.',
        },
        'context_lines': <String, dynamic>{
          'type': <String>['integer', 'null'],
          'description':
              'Lines of surrounding context on each side of a match. Null '
              'returns none; values are clamped to $maxSearchContextLines.',
        },
        'include_ignored': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether to search files git ignores, such as build output and '
              'generated code. Null and false skip them.',
        },
        'max_results': <String, dynamic>{
          'type': <String>['integer', 'null'],
          'description':
              'Most matches to return. Null uses $defaultSearchResults.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final query = arguments['query'] as String;
    if (query.isEmpty) throw const FormatException('query must not be empty.');
    final caseSensitive = arguments['case_sensitive'] != false;
    final RegExp? pattern;
    if (arguments['regex'] == true) {
      try {
        pattern = RegExp(query, caseSensitive: caseSensitive);
      } on FormatException catch (error) {
        // A bad expression is something the model can fix on the next call, so
        // it is reported as tool output rather than failing the turn.
        return ToolResult(
          output: jsonEncode(<String, dynamic>{
            'error': 'query is not a valid regular expression.',
            'detail': error.message,
          }),
          isError: true,
        );
      }
    } else {
      pattern = null;
    }

    final root = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting((arguments['path'] as String?) ?? '.');
    final maxResults =
        (arguments['max_results'] as int?) ?? defaultSearchResults;
    final contextLines = ((arguments['context_lines'] as int?) ?? 0).clamp(
      0,
      maxSearchContextLines,
    );
    final needle = caseSensitive ? query : query.toLowerCase();

    final matches = <Map<String, dynamic>>[];
    var filesSearched = 0;
    var truncated = false;
    final walker = WorkspaceWalker(
      fileSystem: _fileSystem,
      workspaceRoot: context.workspaceRoot,
      respectGitignore: arguments['include_ignored'] != true,
      gitignoreEnvironment: _gitignoreEnvironment,
    );

    await for (final walked in walker.walk(root, context.cancellation)) {
      final List<String> lines;
      try {
        if (await walked.file.length() > maxSearchFileBytes) continue;
        lines = const LineSplitter().convert(await walked.file.readAsString());
      } on FormatException {
        // Binary and non-UTF-8 files are skipped, not reported.
        continue;
      } on FileSystemException {
        continue;
      }
      filesSearched += 1;
      for (var index = 0; index < lines.length; index += 1) {
        final line = lines[index];
        final hit = pattern != null
            ? pattern.hasMatch(line)
            : (caseSensitive ? line : line.toLowerCase()).contains(needle);
        if (!hit) continue;
        matches.add(<String, dynamic>{
          'path': walked.relativePath,
          'line': index + 1,
          'text': _clip(line),
          if (contextLines > 0) ...<String, dynamic>{
            'before': _slice(lines, index - contextLines, index),
            'after': _slice(lines, index + 1, index + 1 + contextLines),
          },
        });
        if (matches.length >= maxResults) {
          truncated = true;
          break;
        }
      }
      // The cap ends the whole walk, not just this file.
      if (truncated) break;
    }

    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'matches': matches,
          'matchCount': matches.length,
          'filesSearched': filesSearched,
          // Without this the model cannot tell "no more matches" from "the cap
          // hid the rest", which are opposite conclusions.
          'truncated': truncated,
        }),
      ),
    );
  }

  static String _clip(String line) => line.length > maxSearchLineLength
      ? line.substring(0, maxSearchLineLength)
      : line;

  static List<String> _slice(List<String> lines, int start, int end) => lines
      .sublist(start.clamp(0, lines.length), end.clamp(0, lines.length))
      .map(_clip)
      .toList(growable: false);
}

/// GlobTool defines a public contract.
class GlobTool extends AgentTool {
  /// Creates a [GlobTool].
  GlobTool({
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
    this._gitignoreEnvironment = const GitignoreEnvironment.none(),
  });

  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Where user-level git configuration lives.
  final GitignoreEnvironment _gitignoreEnvironment;

  @override
  String get name => 'glob';
  @override
  String get description =>
      'Find workspace files by name using a glob pattern such as '
      '`**/*_test.dart`. Files git ignores are skipped unless include_ignored '
      'is set. Use search_text to search file contents instead.';
  @override
  ToolRisk get risk => ToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema => _strictObject(
    <String, Map<String, dynamic>>{
      'pattern': <String, dynamic>{
        'type': 'string',
        'description':
            'Glob matched against paths relative to the searched directory, '
            'for example `**/*.dart` or `lib/**/model_*.dart`.',
      },
      'path': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'Directory to search, relative to the workspace root. Null '
            'searches the whole workspace.',
      },
      'include_ignored': <String, dynamic>{
        'type': <String>['boolean', 'null'],
        'description':
            'Whether to include files git ignores. Null and false skip them.',
      },
      'max_results': <String, dynamic>{
        'type': <String>['integer', 'null'],
        'description': 'Most paths to return. Null uses $defaultSearchResults.',
      },
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final rawPattern = arguments['pattern'] as String;
    if (rawPattern.isEmpty) {
      throw const FormatException('pattern must not be empty.');
    }
    final List<Glob> globs;
    try {
      // Walked paths are always `/`-separated, so the pattern is compiled in
      // that same context rather than the host's.
      globs = <Glob>[
        Glob(rawPattern, context: p.posix),
        // `**/` means "one or more directories" to package:glob, so a plain
        // `**/*.dart` would silently miss every top-level file. Everyone who
        // writes that pattern means "at any depth, including here", so the
        // prefix-free form is matched as well.
        if (rawPattern.startsWith('**/'))
          Glob(rawPattern.substring(3), context: p.posix),
      ];
    } on FormatException catch (error) {
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'pattern is not a valid glob.',
          'detail': error.message,
        }),
        isError: true,
      );
    }

    final root = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting((arguments['path'] as String?) ?? '.');
    final maxResults =
        (arguments['max_results'] as int?) ?? defaultSearchResults;
    final walker = WorkspaceWalker(
      fileSystem: _fileSystem,
      workspaceRoot: context.workspaceRoot,
      respectGitignore: arguments['include_ignored'] != true,
      gitignoreEnvironment: _gitignoreEnvironment,
    );
    // Matching happens against the path the caller asked about, so a pattern
    // written for a subdirectory does not have to repeat that subdirectory.
    final scope = _scopeOf(root, context.workspaceRoot);

    final paths = <String>[];
    var truncated = false;
    await for (final walked in walker.walk(root, context.cancellation)) {
      final candidate = scope.isEmpty
          ? walked.relativePath
          : walked.relativePath.substring(scope.length + 1);
      // Glob.matches is used rather than Glob.list, which reaches for dart:io
      // directly and would bypass the injected filesystem.
      if (!globs.any((glob) => glob.matches(candidate))) continue;
      paths.add(walked.relativePath);
      if (paths.length >= maxResults) {
        truncated = true;
        break;
      }
    }

    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'paths': paths,
          'truncated': truncated,
        }),
      ),
    );
  }

  String _scopeOf(String root, String workspaceRoot) {
    final relative = _fileSystem.path.relative(root, from: workspaceRoot);
    if (relative == '.') return '';
    return _fileSystem.path.split(relative).join('/');
  }
}

/// Media types every supported provider accepts as model-visible images.
const Set<String> supportedContextImageTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/webp',
  'image/gif',
};

/// Fidelity levels a provider understands for a model-visible image.
const Set<String> contextImageDetails = <String>{'auto', 'low', 'high'};

/// Largest size of one image loaded into the model's context.
///
/// Base64 inflates the payload by four thirds, so 10 MiB of image is about
/// 13.3 MB of request body.
const int maxContextImageBytes = 10 * 1024 * 1024;

/// Largest number of images one turn may load into the model's context.
const int maxContextImagesPerTurn = 8;

/// Loads a workspace image into the model's conversation context.
///
/// Distinct from [AttachFileTool], which publishes a file for the user to see:
/// this one makes the model actually look at the image.
class ViewImageTool extends AgentTool {
  /// Creates a [ViewImageTool].
  factory ViewImageTool({
    required AttachmentPublisher publisher,
    file_api.FileSystem fileSystem = const LocalFileSystem(),
    Platform platform = const LocalPlatform(),
  }) => ViewImageTool._(publisher, fileSystem, platform);

  ViewImageTool._(this._publisher, this._fileSystem, this._platform);

  final AttachmentPublisher _publisher;
  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  /// Images loaded so far; the tool instance is scoped to one turn.
  int _loaded = 0;

  @override
  String get name => 'view_image';

  @override
  String get description =>
      'Look at an image file in the workspace. Use it for screenshots, '
      'diagrams, and design mock-ups whose content you need to reason about. '
      'Accepts PNG, JPEG, WebP, and GIF up to '
      '${maxContextImageBytes ~/ (1024 * 1024)} MB, at most '
      '$maxContextImagesPerTurn per turn.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'path': <String, dynamic>{
          'type': 'string',
          'description': 'Workspace-relative path of the image.',
        },
        'detail': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description':
              'How closely to read the image: auto, low, or high. Null uses '
              'the provider default.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final detail = arguments['detail'];
    if (detail != null &&
        (detail is! String || !contextImageDetails.contains(detail))) {
      return _reject(
        'detail must be one of ${contextImageDetails.join(', ')}, or null.',
      );
    }
    if (_loaded >= maxContextImagesPerTurn) {
      return _reject(
        'At most $maxContextImagesPerTurn images can be viewed in one turn.',
      );
    }
    final resolved = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(arguments['path'] as String);
    final source = _fileSystem.file(resolved);
    final stat = source.statSync();
    if (stat.type != file_api.FileSystemEntityType.file) {
      return _reject('An image must be a regular file.');
    }
    if (stat.size > maxContextImageBytes) {
      return _reject(
        'The image exceeds the '
        '${maxContextImageBytes ~/ (1024 * 1024)} MB limit.',
      );
    }
    // Sniffing the header keeps a mislabelled file from reaching the provider,
    // which would fail the whole turn rather than this one call.
    final mimeType = _sniffImageType(
      await source.openRead(0, 12).expand((chunk) => chunk).toList(),
    );
    if (mimeType == null) {
      return _reject(
        'Not a supported image. Use PNG, JPEG, WebP, or GIF.',
      );
    }
    context.cancellation.throwIfCancelled();
    final published = await _publisher.publish(resolved);
    _loaded += 1;
    // Hydrate here rather than relying on the publisher: the model has to see
    // the image on this very turn, and later turns refill bytes from the
    // attachment store when the history is replayed.
    final attachment = ConversationAttachment(
      id: published.id,
      fileName: published.fileName,
      mimeType: mimeType,
      byteSize: published.byteSize,
      path: published.path,
      bytes: published.bytes ?? await source.readAsBytes(),
      kind: published.kind,
      sha256: published.sha256,
      createdAt: published.createdAt,
      imageDetail: detail as String?,
    );
    return ToolResult(
      output: jsonEncode(<String, dynamic>{
        'attachmentId': attachment.id,
        'fileName': attachment.fileName,
        'mimeType': attachment.mimeType,
        'byteSize': attachment.byteSize,
        'detail': detail,
      }),
      attachments: <ConversationAttachment>[attachment],
      contextImages: <ConversationAttachment>[attachment],
    );
  }

  /// Returns the media type [header] actually starts with, or null.
  static String? _sniffImageType(List<int> header) {
    bool matches(int offset, List<int> magic) {
      if (header.length < offset + magic.length) return false;
      for (var index = 0; index < magic.length; index += 1) {
        if (header[offset + index] != magic[index]) return false;
      }
      return true;
    }

    if (matches(0, <int>[0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (matches(0, <int>[0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (matches(0, <int>[0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    // WebP is a RIFF container whose form type sits after the 4-byte length.
    if (matches(0, <int>[0x52, 0x49, 0x46, 0x46]) &&
        matches(8, <int>[0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    return null;
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Largest number of questions one `ask_user` call may raise.
const int maxUserQuestions = 3;

/// Bounds on the fixed choices one question may offer.
const int minUserQuestionOptions = 2;

/// Largest number of fixed choices one question may offer.
const int maxUserQuestionOptions = 3;

/// Largest number of characters a question header may use.
const int maxUserQuestionHeader = 12;

/// Asks the user structured multiple-choice questions and blocks for answers.
///
/// The schema cannot express the bounds — strict provider schemas reject
/// `minItems` and `maxItems` — so they are enforced here and a violation comes
/// back as a correctable tool error instead of a failed turn.
class AskUserTool extends AgentTool {
  /// Creates an [AskUserTool].
  factory AskUserTool({required UserQuestionCoordinator coordinator}) =>
      AskUserTool._(coordinator);

  AskUserTool._(this._coordinator);

  final UserQuestionCoordinator _coordinator;

  @override
  String get name => 'ask_user';

  @override
  String get description =>
      'Ask the user up to $maxUserQuestions multiple-choice questions and '
      "wait for the answers. Use it when a decision is genuinely the user's "
      'to make and proceeding on a guess would waste work. Each question '
      'needs $minUserQuestionOptions to $maxUserQuestionOptions options; the '
      'client always adds a free-form option, so never write one yourself.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'questions': <String, dynamic>{
          'type': 'array',
          'description':
              'Between 1 and $maxUserQuestions questions, most important '
              'first.',
          'items': _strictObject(<String, Map<String, dynamic>>{
            'id': <String, dynamic>{
              'type': 'string',
              'description': 'Identifier unique within this call.',
            },
            'header': <String, dynamic>{
              'type': 'string',
              'description':
                  'A label of at most $maxUserQuestionHeader characters, for '
                  'example "Storage".',
            },
            'question': <String, dynamic>{
              'type': 'string',
              'description':
                  'The complete question, ending in a question '
                  'mark.',
            },
            'options': <String, dynamic>{
              'type': 'array',
              'description':
                  'Between $minUserQuestionOptions and $maxUserQuestionOptions '
                  'mutually exclusive choices.',
              'items': _strictObject(<String, Map<String, dynamic>>{
                'label': <String, dynamic>{
                  'type': 'string',
                  'description': 'The choice, in one to five words.',
                },
                'description': <String, dynamic>{
                  'type': 'string',
                  'description': 'What choosing this option means.',
                },
              }),
            },
          }),
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['questions'];
    if (raw is! List || raw.isEmpty || raw.length > maxUserQuestions) {
      return _reject(
        'Ask between 1 and $maxUserQuestions questions.',
      );
    }
    final questions = <UserQuestion>[];
    final ids = <String>{};
    for (final entry in raw) {
      if (entry is! Map) return _reject('Every question must be an object.');
      final id = entry['id'];
      if (id is! String || id.trim().isEmpty) {
        return _reject('Every question needs a non-empty "id".');
      }
      if (!ids.add(id)) return _reject('Duplicate question id "$id".');
      final header = entry['header'];
      if (header is! String ||
          header.trim().isEmpty ||
          header.length > maxUserQuestionHeader) {
        return _reject(
          'Question "$id" needs a header of 1 to $maxUserQuestionHeader '
          'characters.',
        );
      }
      final question = entry['question'];
      if (question is! String || question.trim().isEmpty) {
        return _reject('Question "$id" needs non-empty question text.');
      }
      final rawOptions = entry['options'];
      if (rawOptions is! List ||
          rawOptions.length < minUserQuestionOptions ||
          rawOptions.length > maxUserQuestionOptions) {
        return _reject(
          'Question "$id" needs $minUserQuestionOptions to '
          '$maxUserQuestionOptions options.',
        );
      }
      final options = <UserQuestionOption>[];
      for (final rawOption in rawOptions) {
        if (rawOption is! Map) {
          return _reject('Every option of "$id" must be an object.');
        }
        final label = rawOption['label'];
        final optionDescription = rawOption['description'];
        if (label is! String ||
            label.trim().isEmpty ||
            optionDescription is! String) {
          return _reject(
            'Every option of "$id" needs a non-empty label and a description.',
          );
        }
        options.add(
          UserQuestionOption(
            label: label.trim(),
            description: optionDescription,
          ),
        );
      }
      questions.add(
        UserQuestion(
          id: id,
          header: header.trim(),
          question: question.trim(),
          options: List<UserQuestionOption>.unmodifiable(options),
        ),
      );
    }
    context.cancellation.throwIfCancelled();
    final answers = await _coordinator.ask(
      context.callId,
      List<UserQuestion>.unmodifiable(questions),
      context.cancellation,
    );
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<Map<String, dynamic>>[
          for (final answer in answers)
            <String, dynamic>{
              'questionId': answer.questionId,
              'answer': answer.answer,
              'isFreeForm': answer.isFreeForm,
            },
        ]),
      ),
    );
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Lifecycle of one step in an agent-authored plan.
enum PlanStepStatus {
  /// The step has not been started.
  pending,

  /// The step is the one the agent is working on right now.
  inProgress,

  /// The step is finished.
  completed;

  /// The wire name the model writes and the client reads.
  String get wireName => switch (this) {
    PlanStepStatus.pending => 'pending',
    PlanStepStatus.inProgress => 'in_progress',
    PlanStepStatus.completed => 'completed',
  };

  /// Resolves [wireName] back to a status, or null when it is unknown.
  static PlanStepStatus? fromWireName(String wireName) => PlanStepStatus.values
      .where((status) => status.wireName == wireName)
      .firstOrNull;
}

/// Records the agent's ordered plan so the client can render its progress.
///
/// The tool is deliberately side-effect free: the emitted `tool.requested` and
/// `tool.completed` timeline events already persist and replay the plan, so
/// storing it a second time on the session would create a rival source of
/// truth.
class UpdatePlanTool extends AgentTool {
  /// Creates an [UpdatePlanTool].
  UpdatePlanTool();

  @override
  String get name => 'update_plan';

  @override
  String get description =>
      'Record the ordered plan for the current task and the progress of each '
      'step. Call it once the plan is settled and again whenever a step '
      'starts or finishes. Keep at most one step in_progress.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      _strictObject(<String, Map<String, dynamic>>{
        'plan': <String, dynamic>{
          'type': 'array',
          'description': 'The ordered steps, at least one, in execution order.',
          'items': _strictObject(<String, Map<String, dynamic>>{
            'step': <String, dynamic>{
              'type': 'string',
              'description': 'One short imperative step, unique in the plan.',
            },
            'status': <String, dynamic>{
              'type': 'string',
              'enum': PlanStepStatus.values
                  .map((status) => status.wireName)
                  .toList(growable: false),
            },
          }),
        },
        'explanation': <String, dynamic>{
          'type': 'string',
          'description':
              'Why the plan looks like this; empty when it needs no rationale.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['plan'];
    if (raw is! List || raw.isEmpty) {
      return _reject('A plan must contain at least one step.');
    }
    final steps = <Map<String, dynamic>>[];
    final seen = <String>{};
    var active = 0;
    for (final entry in raw) {
      if (entry is! Map) return _reject('Every plan entry must be an object.');
      final step = entry['step'];
      if (step is! String || step.trim().isEmpty) {
        return _reject('Every step needs a non-empty "step" description.');
      }
      final statusName = entry['status'];
      if (statusName is! String) {
        return _reject('Every step needs a "status".');
      }
      final status = PlanStepStatus.fromWireName(statusName);
      if (status == null) {
        return _reject(
          'Unknown status "$statusName". Use pending, in_progress, or '
          'completed.',
        );
      }
      final normalized = step.trim();
      if (!seen.add(normalized)) {
        return _reject('Duplicate step "$normalized".');
      }
      if (status == PlanStepStatus.inProgress) active += 1;
      steps.add(<String, dynamic>{
        'step': normalized,
        'status': status.wireName,
      });
    }
    if (active > 1) {
      return _reject('At most one step may be in_progress; found $active.');
    }
    final explanation = arguments['explanation'];
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'plan': steps,
          'explanation': explanation is String ? explanation : '',
        }),
      ),
    );
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
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
      'Apply a unified diff to UTF-8 files inside the workspace. Create a file '
      'with a /dev/null source, delete one with a /dev/null target, and move '
      'or rename one by naming different paths in the --- and +++ headers.';
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

    // Every change is planned, and every patch context validated, before a
    // single byte is written. A patch that cannot apply must leave the
    // workspace exactly as it found it.
    final plan = <_PlannedChange>[];
    for (final filePatch in patch.files) {
      context.cancellation.throwIfCancelled();
      plan.add(await _plan(filePatch, guard));
    }

    final applied = <_PlannedChange>[];
    try {
      for (final change in plan) {
        await change.apply(_fileSystem, _temporarySuffix);
        applied.add(change);
      }
    } catch (_) {
      for (final change in applied.reversed) {
        await change.revert(_fileSystem);
      }
      rethrow;
    }
    return ToolResult(
      output: jsonEncode(<String, dynamic>{'changedFiles': applied.length}),
    );
  }

  /// Works out what one file header asks for, and reads what it needs.
  Future<_PlannedChange> _plan(
    FilePatch filePatch,
    WorkspacePathGuard guard,
  ) async {
    final from = _cleanPath(filePatch.oldPath);
    final to = _cleanPath(filePatch.newPath);
    if (from == null && to == null) {
      throw const FormatException('A patch cannot move /dev/null to itself.');
    }

    if (to == null) {
      final source = guard.resolveWritable(from!);
      if (!_fileSystem.file(source).existsSync()) {
        throw FormatException('Cannot delete a missing file: $from');
      }
      return _PlannedChange(
        source: source,
        sourceContents: await _fileSystem.file(source).readAsString(),
      );
    }

    final target = guard.resolveWritable(to);
    // A creation names /dev/null as its source; a plain edit names the same
    // path on both sides. Anything else is a move.
    final source = from == null ? null : guard.resolveWritable(from);
    final moving = source != null && source != target;

    final readFrom = source ?? target;
    final originalExists = _fileSystem.file(readFrom).existsSync();
    if (moving && !originalExists) {
      throw FormatException('Cannot move a missing file: $from');
    }
    final original = originalExists
        ? await _fileSystem.file(readFrom).readAsString()
        : '';

    if (moving && _fileSystem.file(target).existsSync()) {
      // Silently clobbering the destination would lose a file the patch never
      // mentioned, so the move is refused instead.
      throw FormatException('Cannot move onto an existing file: $to');
    }

    return _PlannedChange(
      source: moving ? source : null,
      sourceContents: moving ? original : null,
      target: target,
      targetContents: filePatch.apply(original),
      targetExisted: !moving && originalExists,
      targetOriginal: !moving && originalExists ? original : null,
    );
  }

  /// Strips the `a/` and `b/` prefixes, mapping `/dev/null` to null.
  static String? _cleanPath(String path) {
    if (path == '/dev/null') return null;
    return path.startsWith('a/') || path.startsWith('b/')
        ? path.substring(2)
        : path;
  }
}

/// One file's worth of work, and everything needed to undo it.
class _PlannedChange {
  _PlannedChange({
    this.source,
    this.sourceContents,
    this.target,
    this.targetContents,
    this.targetExisted = false,
    this.targetOriginal,
  });

  /// Path to remove, for a delete or the origin half of a move.
  final String? source;

  /// What [source] held, so a failure can put it back.
  final String? sourceContents;

  /// Path to write, absent for a delete.
  final String? target;

  /// What [target] should hold afterwards.
  final String? targetContents;

  /// Whether [target] existed before this change.
  final bool targetExisted;

  /// What [target] held before, when it existed.
  final String? targetOriginal;

  Future<void> apply(
    file_api.FileSystem fileSystem,
    String Function() temporarySuffix,
  ) async {
    if (target case final path?) {
      await fileSystem
          .directory(fileSystem.path.dirname(path))
          .create(recursive: true);
      // Written beside the target and renamed over it, so a reader never sees
      // a half-written file.
      final temporary = fileSystem.file(
        '$path.coder-tmp-${temporarySuffix()}',
      );
      await temporary.writeAsString(targetContents ?? '', flush: true);
      await temporary.rename(path);
    }
    // The removal comes last: until it happens the content still exists
    // somewhere, whichever half of a move fails.
    if (source case final path?) {
      if (fileSystem.file(path).existsSync()) {
        await fileSystem.file(path).delete();
      }
    }
  }

  Future<void> revert(file_api.FileSystem fileSystem) async {
    if (source case final path?) {
      await fileSystem
          .file(path)
          .writeAsString(sourceContents ?? '', flush: true);
    }
    if (target case final path?) {
      if (targetExisted) {
        await fileSystem
            .file(path)
            .writeAsString(
              targetOriginal ?? '',
              flush: true,
            );
      } else if (fileSystem.file(path).existsSync()) {
        await fileSystem.file(path).delete();
      }
    }
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
