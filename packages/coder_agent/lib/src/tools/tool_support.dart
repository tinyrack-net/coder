import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:coder_agent/src/model.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Upper bound on the UTF-8 size of any tool result written to a turn.
///
/// Tool output is persisted verbatim into the conversation history and the
/// timeline, so every tool — built-in or external — shares this single limit.
const int maxToolOutputBytes = 1024 * 1024;

/// Maximum size of one attachment accepted by the public contract.
const int maxAttachmentBytes = 50 * 1024 * 1024;

/// Results one listing returns unless the caller asks for fewer.
///
/// Shared by every tool that pages a workspace scan, so a result page is
/// the same size whether the agent searched by content or by file name.
const int defaultSearchResults = 200;

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
