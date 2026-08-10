import 'dart:async';
import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

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
  AgentToolRisk get risk => AgentToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
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
    if (offset >= lines.length) return const ToolResult(value: '');
    return ToolResult(value: lines.sublist(offset, end).join('\n'));
  }
}

/// Registers the workspace file reader.
final class ReadFileToolProvider extends SelectableToolProvider {
  /// Creates a [ReadFileToolProvider].
  const ReadFileToolProvider();

  @override
  String get id => 'read_file';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: ReadFileTool().description,
    risk: AgentToolRisk.read,
    group: AgentToolGroup.filesystem,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ReadFileTool(),
  ];
}
