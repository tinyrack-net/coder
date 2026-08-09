import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_service.dart';

/// Resources one turn may reach, already scoped to its worktree.
///
/// The tools see only this, so a turn can never read a resource from a server
/// some other repository declared.
abstract interface class McpResourceHost {
  /// Resources published by [server], or by every visible server when null.
  Future<McpListPage<McpServerResource>> resources({
    String? server,
    String? cursor,
  });

  /// Resource templates published by [server], or by every visible server.
  Future<McpListPage<McpServerResourceTemplate>> resourceTemplates({
    String? server,
    String? cursor,
  });

  /// Reads one resource, throwing when the server is unknown or offline.
  Future<McpReadResourceResult> readResource({
    required String server,
    required String uri,
  });
}

/// A worktree-scoped view of [McpRuntime] for the resource tools.
final class SessionMcpResourceHost implements McpResourceHost {
  /// Creates a [SessionMcpResourceHost].
  const SessionMcpResourceHost(this._service, this._workspaceRoot);

  final McpRuntime _service;
  final String _workspaceRoot;

  @override
  Future<McpListPage<McpServerResource>> resources({
    String? server,
    String? cursor,
  }) => server == null
      ? Future<McpListPage<McpServerResource>>.value(
          McpListPage<McpServerResource>(
            items: _service.resources(workspaceRoot: _workspaceRoot),
          ),
        )
      : _service.resourcePage(
          server: server,
          cursor: cursor,
          workspaceRoot: _workspaceRoot,
        );

  @override
  Future<McpListPage<McpServerResourceTemplate>> resourceTemplates({
    String? server,
    String? cursor,
  }) => server == null
      ? Future<McpListPage<McpServerResourceTemplate>>.value(
          McpListPage<McpServerResourceTemplate>(
            items: _service.resourceTemplates(workspaceRoot: _workspaceRoot),
          ),
        )
      : _service.resourceTemplatePage(
          server: server,
          cursor: cursor,
          workspaceRoot: _workspaceRoot,
        );

  @override
  Future<McpReadResourceResult> readResource({
    required String server,
    required String uri,
  }) => _service.readResource(
    server: server,
    uri: uri,
    workspaceRoot: _workspaceRoot,
  );
}

/// Reads [key] as a non-blank string, treating blank and absent alike.
///
/// Models routinely send `""` where they mean "unset", and an empty server
/// name would otherwise select nothing instead of fanning out.
String? _optional(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

ToolResult _reject(String reason) => ToolResult(
  value: jsonEncode(<String, dynamic>{'error': reason}),
  isError: true,
);

Map<String, Map<String, dynamic>> _listSchema() =>
    <String, Map<String, dynamic>>{
      'server': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'MCP server name exactly as configured. Null lists every '
            'server, unpaginated.',
      },
      'cursor': <String, dynamic>{
        'type': <String>['string', 'null'],
        'description':
            'Cursor from a previous call; only valid together with a server.',
      },
    };

/// Lists the resources MCP servers publish.
class ListMcpResourcesTool extends AgentTool {
  /// Creates a [ListMcpResourcesTool].
  factory ListMcpResourcesTool({required McpResourceHost host}) =>
      ListMcpResourcesTool._(host);

  ListMcpResourcesTool._(this._host);

  final McpResourceHost _host;

  @override
  String get name => 'list_mcp_resources';

  @override
  String get description =>
      'List resources published by MCP servers. Resources are data a server '
      'shares for context — files, schemas, or application state. Prefer them '
      'over guessing, and read one with read_mcp_resource.';

  // Reading a resource is side-effect free by specification, unlike tools/call
  // which runs whatever the server decided a tool should do.
  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject(_listSchema());

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final server = _optional(arguments, 'server');
    final cursor = _optional(arguments, 'cursor');
    if (server == null && cursor != null) {
      return _reject('cursor is only valid together with a server.');
    }
    final McpListPage<McpServerResource> page;
    try {
      page = await _host.resources(server: server, cursor: cursor);
    } on McpServerUnavailable catch (error) {
      return _reject('$error');
    } on McpServerException catch (error) {
      return _reject('$error');
    } on McpProtocolException catch (error) {
      return _reject(error.message);
    } on McpTransportClosed catch (error) {
      return _reject('$error');
    }
    final entries = <Map<String, dynamic>>[
      for (final item in page.items)
        <String, dynamic>{
          'server': item.server,
          'uri': item.descriptor.uri,
          if (item.descriptor.name != null) 'name': item.descriptor.name,
          if (item.descriptor.title != null) 'title': item.descriptor.title,
          if (item.descriptor.description != null)
            'description': item.descriptor.description,
          if (item.descriptor.mimeType != null)
            'mimeType': item.descriptor.mimeType,
          if (item.descriptor.sizeBytes != null)
            'sizeBytes': item.descriptor.sizeBytes,
          if (item.descriptor.annotations.isNotEmpty)
            'annotations': item.descriptor.annotations,
          if (item.descriptor.meta.isNotEmpty) '_meta': item.descriptor.meta,
        },
    ];
    return ToolResult(
      value: <String, dynamic>{
        'server': ?server,
        'resources': entries,
        if (page.nextCursor != null) 'nextCursor': page.nextCursor,
      },
    );
  }
}

/// Lists the parameterized resource templates MCP servers publish.
class ListMcpResourceTemplatesTool extends AgentTool {
  /// Creates a [ListMcpResourceTemplatesTool].
  factory ListMcpResourceTemplatesTool({required McpResourceHost host}) =>
      ListMcpResourceTemplatesTool._(host);

  ListMcpResourceTemplatesTool._(this._host);

  final McpResourceHost _host;

  @override
  String get name => 'list_mcp_resource_templates';

  @override
  String get description =>
      'List parameterized resource templates published by MCP servers. Expand '
      'a template into a concrete URI, then read it with read_mcp_resource.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject(_listSchema());

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final server = _optional(arguments, 'server');
    final cursor = _optional(arguments, 'cursor');
    if (server == null && cursor != null) {
      return _reject('cursor is only valid together with a server.');
    }
    final McpListPage<McpServerResourceTemplate> page;
    try {
      page = await _host.resourceTemplates(server: server, cursor: cursor);
    } on McpServerUnavailable catch (error) {
      return _reject('$error');
    } on McpServerException catch (error) {
      return _reject('$error');
    } on McpProtocolException catch (error) {
      return _reject(error.message);
    } on McpTransportClosed catch (error) {
      return _reject('$error');
    }
    final entries = <Map<String, dynamic>>[
      for (final item in page.items)
        <String, dynamic>{
          'server': item.server,
          'uriTemplate': item.descriptor.uriTemplate,
          if (item.descriptor.name != null) 'name': item.descriptor.name,
          if (item.descriptor.title != null) 'title': item.descriptor.title,
          if (item.descriptor.description != null)
            'description': item.descriptor.description,
          if (item.descriptor.mimeType != null)
            'mimeType': item.descriptor.mimeType,
          if (item.descriptor.annotations.isNotEmpty)
            'annotations': item.descriptor.annotations,
          if (item.descriptor.meta.isNotEmpty) '_meta': item.descriptor.meta,
        },
    ];
    return ToolResult(
      value: <String, dynamic>{
        'server': ?server,
        'resourceTemplates': entries,
        if (page.nextCursor != null) 'nextCursor': page.nextCursor,
      },
    );
  }
}

/// Reads one resource an MCP server publishes.
class ReadMcpResourceTool extends AgentTool {
  /// Creates a [ReadMcpResourceTool].
  factory ReadMcpResourceTool({required McpResourceHost host}) =>
      ReadMcpResourceTool._(host);

  ReadMcpResourceTool._(this._host);

  final McpResourceHost _host;

  @override
  String get name => 'read_mcp_resource';

  @override
  String get description =>
      'Read one resource from an MCP server. Use a server name and URI that '
      'list_mcp_resources returned, or a URI expanded from a template.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'server': <String, dynamic>{
          'type': 'string',
          'description': 'MCP server name exactly as configured.',
        },
        'uri': <String, dynamic>{
          'type': 'string',
          'description': 'Resource URI to read.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final server = _optional(arguments, 'server');
    final uri = _optional(arguments, 'uri');
    if (server == null || uri == null) {
      return _reject('server and uri must both be non-empty.');
    }
    context.cancellation.throwIfCancelled();
    final McpReadResourceResult result;
    try {
      result = await _host.readResource(server: server, uri: uri);
    } on McpServerUnavailable catch (error) {
      // Recoverable: the model can list again once the server connects.
      return _reject('$error');
    } on McpServerException catch (error) {
      return _reject('$error');
    } on McpProtocolException catch (error) {
      return _reject(error.message);
    } on McpTransportClosed catch (error) {
      return _reject('$error');
    }
    return ToolResult(
      value: <String, dynamic>{
        'server': server,
        'uri': uri,
        'contents': <Map<String, dynamic>>[
          for (final content in result.contents)
            switch (content) {
              McpTextResourceContents(:final mimeType, :final text) =>
                <String, dynamic>{
                  'uri': content.uri,
                  'mimeType': mimeType,
                  'text': text,
                  if (content.meta.isNotEmpty) '_meta': content.meta,
                },
              McpBlobResourceContents(:final mimeType, :final blob) =>
                <String, dynamic>{
                  'uri': content.uri,
                  'mimeType': mimeType,
                  'blob': blob,
                  if (content.meta.isNotEmpty) '_meta': content.meta,
                },
            },
        ],
      },
      content: <ToolContent>[
        for (final content in result.contents)
          switch (content) {
            McpTextResourceContents(:final mimeType, :final text) =>
              ToolEmbeddedResourceContent(
                uri: content.uri,
                mimeType: mimeType,
                text: text,
                meta: content.meta,
              ),
            McpBlobResourceContents(:final mimeType, :final blob) =>
              ToolEmbeddedResourceContent(
                uri: content.uri,
                mimeType: mimeType,
                blob: blob,
                meta: content.meta,
              ),
          },
      ],
    );
  }
}

/// Registers one MCP resource capability over a workspace-scoped host.
///
/// The three resource capabilities differ only in which tool they build, so
/// they share one provider rather than three near-identical ones.
final class McpResourceToolProvider extends SelectableToolProvider {
  /// Creates a provider building [_tool] from a host scoped to the worktree.
  const McpResourceToolProvider({
    required this.id,
    required this.description,
    required this._tool,
    required this._hostFor,
  });

  @override
  final String id;

  /// What clients show for this capability.
  final String description;

  final AgentTool Function(McpResourceHost host) _tool;
  final McpResourceHost Function(String workspaceRoot) _hostFor;

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description: description,
    risk: AgentToolRisk.read,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    _tool(_hostFor(scope.workspaceRoot)),
  ];
}
