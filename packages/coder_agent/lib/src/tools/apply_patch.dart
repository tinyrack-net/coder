import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/patch/unified_diff.dart';
import 'package:coder_agent/src/tools/tool_support.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

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
      strictToolObject(<String, Map<String, dynamic>>{
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
