import 'dart:async';
import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

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
  AgentToolRisk get risk => AgentToolRisk.read;
  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
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

/// Registers the workspace directory listing.
final class ListDirectoryToolProvider extends SelectableToolProvider {
  /// Creates a [ListDirectoryToolProvider].
  const ListDirectoryToolProvider();

  @override
  String get id => 'list_directory';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: ListDirectoryTool().description,
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ListDirectoryTool(),
  ];
}
