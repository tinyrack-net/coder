import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/mcp_service.dart';
import 'package:coder_mcp/coder_mcp.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Resources one turn may reach, already scoped to its worktree.
///
/// The tools see only this, so a turn can never read a resource from a server
/// some other repository declared.
abstract interface class McpResourceHost {
  /// Resources published by [server], or by every visible server when null.
  List<McpServerResource> resources({String? server});

  /// Resource templates published by [server], or by every visible server.
  List<McpServerResourceTemplate> resourceTemplates({String? server});

  /// Reads one resource, throwing when the server is unknown or offline.
  Future<McpReadResourceResult> readResource({
    required String server,
    required String uri,
  });
}

/// A worktree-scoped view of [McpService] for the resource tools.
final class SessionMcpResourceHost implements McpResourceHost {
  /// Creates a [SessionMcpResourceHost].
  const SessionMcpResourceHost(this._service, this._workspaceRoot);

  final McpService _service;
  final String _workspaceRoot;

  @override
  List<McpServerResource> resources({String? server}) =>
      _service.resources(server: server, workspaceRoot: _workspaceRoot);

  @override
  List<McpServerResourceTemplate> resourceTemplates({String? server}) =>
      _service.resourceTemplates(
        server: server,
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

/// How many entries one page of a server-scoped listing returns.
const int mcpResourcePageSize = 100;

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
  output: jsonEncode(<String, dynamic>{'error': reason}),
  isError: true,
);

/// Slices [items] for a server-scoped page, or rejects an unusable cursor.
///
/// Returns a record of the page and the cursor that follows it. The cursor is
/// an offset into the client-side cache rather than the server's own cursor,
/// because the MCP client already drained every page at connect time.
({List<T> page, String? nextCursor})? _page<T>(
  List<T> items,
  String? cursor,
) {
  final offset = cursor == null ? 0 : int.tryParse(cursor);
  if (offset == null || offset < 0 || offset > items.length) return null;
  final end = (offset + mcpResourcePageSize).clamp(0, items.length);
  return (
    page: items.sublist(offset, end),
    nextCursor: end < items.length ? '$end' : null,
  );
}

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
  ToolRisk get risk => ToolRisk.read;

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
    final all = _host.resources(server: server);
    final entries = <Map<String, dynamic>>[
      for (final item in all)
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
        },
    ];
    if (server == null) {
      return ToolResult(
        output: truncateToolOutput(
          jsonEncode(<String, dynamic>{
            'resources': entries,
            'truncated': false,
          }),
        ),
      );
    }
    final paged = _page(entries, cursor);
    if (paged == null) return _reject('Unknown cursor "$cursor".');
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'server': server,
          'resources': paged.page,
          if (paged.nextCursor != null) 'nextCursor': paged.nextCursor,
          'truncated': paged.nextCursor != null,
        }),
      ),
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
  ToolRisk get risk => ToolRisk.read;

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
    final entries = <Map<String, dynamic>>[
      for (final item in _host.resourceTemplates(server: server))
        <String, dynamic>{
          'server': item.server,
          'uriTemplate': item.descriptor.uriTemplate,
          if (item.descriptor.name != null) 'name': item.descriptor.name,
          if (item.descriptor.title != null) 'title': item.descriptor.title,
          if (item.descriptor.description != null)
            'description': item.descriptor.description,
          if (item.descriptor.mimeType != null)
            'mimeType': item.descriptor.mimeType,
        },
    ];
    if (server == null) {
      return ToolResult(
        output: truncateToolOutput(
          jsonEncode(<String, dynamic>{
            'resourceTemplates': entries,
            'truncated': false,
          }),
        ),
      );
    }
    final paged = _page(entries, cursor);
    if (paged == null) return _reject('Unknown cursor "$cursor".');
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'server': server,
          'resourceTemplates': paged.page,
          if (paged.nextCursor != null) 'nextCursor': paged.nextCursor,
          'truncated': paged.nextCursor != null,
        }),
      ),
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
  ToolRisk get risk => ToolRisk.read;

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
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
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
                  },
                McpBlobResourceContents(:final mimeType, :final byteLength) =>
                  <String, dynamic>{
                    'uri': content.uri,
                    'mimeType': mimeType,
                    'byteLength': ?byteLength,
                  },
              },
          ],
        }),
      ),
    );
  }
}
