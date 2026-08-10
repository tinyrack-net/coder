import 'dart:async';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/prompts/named_prompts.dart';
import 'package:agent/src/tools/patch/codex_patch.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';
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
      'Apply a patch to UTF-8 files inside the workspace. The input must use '
      'the *** Begin Patch format with Add, Update, Delete, and Move sections.';
  @override
  AgentToolRisk get risk => AgentToolRisk.write;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      throw StateError('apply_patch accepts freeform input.');

  @override
  ModelToolDefinition get modelSpec => const ModelFreeformToolDefinition(
    name: 'apply_patch',
    description:
        'Apply a patch to UTF-8 files inside the workspace using the '
        '*** Begin Patch format.',
    format: ModelFreeformToolFormat(
      type: 'grammar',
      syntax: 'lark',
      definition: _applyPatchGrammar,
    ),
  );

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => arguments['patch'] as String;

  @override
  Future<String?> previewFreeform(
    String input,
    ToolExecutionContext context,
  ) async => input;

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    throw StateError('apply_patch accepts freeform input.');
  }

  @override
  Future<ToolResult> executeFreeform(
    String input,
    ToolExecutionContext context,
  ) async {
    final patch = CodexPatch.parse(input);
    final guard = WorkspacePathGuard(
      context.workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    );

    // Every change is planned, and every patch context validated, before a
    // single byte is written. A patch that cannot apply must leave the
    // workspace exactly as it found it.
    final plan = <_PlannedChange>[];
    for (final operation in patch.operations) {
      context.cancellation.throwIfCancelled();
      plan.add(await _plan(operation, guard));
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
      value: <String, dynamic>{'changed_files': applied.length},
    );
  }

  /// Works out what one file header asks for, and reads what it needs.
  Future<_PlannedChange> _plan(
    CodexPatchOperation operation,
    WorkspacePathGuard guard,
  ) async {
    if (operation case CodexDeleteFile(:final path)) {
      final source = guard.resolveWritable(path);
      if (!_fileSystem.file(source).existsSync()) {
        throw FormatException('Cannot delete a missing file: $path');
      }
      return _PlannedChange(
        source: source,
        sourceContents: await _fileSystem.file(source).readAsString(),
      );
    }

    if (operation case CodexAddFile(:final path, :final content)) {
      final target = guard.resolveWritable(path);
      if (_fileSystem.file(target).existsSync()) {
        throw FormatException('Cannot add an existing file: $path');
      }
      return _PlannedChange(
        target: target,
        targetContents: content.isEmpty ? '' : '$content\n',
      );
    }

    final update = operation as CodexUpdateFile;
    final source = guard.resolveWritable(update.path);
    final target = guard.resolveWritable(update.moveTo ?? update.path);
    final moving = source != target;

    final originalExists = _fileSystem.file(source).existsSync();
    if (!originalExists) {
      throw FormatException('Cannot update a missing file: ${update.path}');
    }
    final original = await _fileSystem.file(source).readAsString();

    if (moving && _fileSystem.file(target).existsSync()) {
      // Silently clobbering the destination would lose a file the patch never
      // mentioned, so the move is refused instead.
      throw FormatException(
        'Cannot move onto an existing file: ${update.moveTo}',
      );
    }

    return _PlannedChange(
      source: moving ? source : null,
      sourceContents: moving ? original : null,
      target: target,
      targetContents: update.apply(original),
      targetExisted: !moving && originalExists,
      targetOriginal: !moving && originalExists ? original : null,
    );
  }
}

const String _applyPatchGrammar = r'''
start: begin operation+ end
begin: "*** Begin Patch" NEWLINE
end: "*** End Patch" NEWLINE?
operation: add_file | delete_file | update_file
add_file: "*** Add File: " PATH NEWLINE add_line*
delete_file: "*** Delete File: " PATH NEWLINE
update_file: "*** Update File: " PATH NEWLINE move_to? chunk*
move_to: "*** Move to: " PATH NEWLINE
chunk: "@@" /[^\n]*/ NEWLINE patch_line*
add_line: "+" /[^\n]*/ NEWLINE
patch_line: /[ +\-][^\n]*/ NEWLINE
PATH: /[^\n]+/
%import common.NEWLINE
''';

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

/// Registers the modern freeform patch writer.
final class ApplyPatchToolProvider extends SelectableToolProvider {
  /// Creates a [ApplyPatchToolProvider].
  const ApplyPatchToolProvider();

  @override
  String get id => 'apply_patch';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: ApplyPatchTool().description,
    risk: AgentToolRisk.write,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ApplyPatchTool(),
  ];

  // The schema says what the argument is; a patch that applies cleanly on the
  // first try needs the conventions around it too, which do not fit a
  // description a settings list also renders.
  @override
  String? promptFragment(AgentToolScope scope) => applyPatchToolInstructions;
}
