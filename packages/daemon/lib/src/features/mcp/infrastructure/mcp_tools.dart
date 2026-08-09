import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';

/// Separates the server and tool halves of a namespaced MCP tool id.
const String mcpToolIdSeparator = '__';

/// Returns the agent-facing id for [toolName] on [serverId].
String mcpToolId(String serverId, String toolName) =>
    'mcp$mcpToolIdSeparator$serverId$mcpToolIdSeparator$toolName';

/// Splits a namespaced MCP tool id, or returns null when [id] is not one.
({String server, String tool})? parseMcpToolId(String id) {
  const prefix = 'mcp$mcpToolIdSeparator';
  if (!id.startsWith(prefix)) return null;
  final rest = id.substring(prefix.length);
  final separator = rest.indexOf(mcpToolIdSeparator);
  if (separator <= 0) return null;
  final tool = rest.substring(separator + mcpToolIdSeparator.length);
  if (tool.isEmpty) return null;
  return (server: rest.substring(0, separator), tool: tool);
}

/// Adapts a published MCP tool to the schema shape a provider will accept.
///
/// The schema is authored by the server, so this normalizes only what would
/// otherwise be rejected outright. It never strips keys or forces properties
/// to be required: silently rewriting the contract the server declared would
/// make the model call the tool wrongly.
Map<String, dynamic> normalizeMcpInputSchema(Map<String, dynamic>? schema) {
  const empty = <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{},
    'additionalProperties': false,
  };
  if (schema == null || schema.isEmpty) return empty;
  final normalized = Map<String, dynamic>.from(schema);
  if (!normalized.containsKey('type') && normalized['properties'] != null) {
    normalized['type'] = 'object';
  }
  if (normalized['type'] != 'object') {
    throw const FormatException(
      'invalid_mcp_tool_schema: a tool must accept an object.',
    );
  }
  normalized['properties'] ??= <String, dynamic>{};
  return normalized;
}

/// Renders one MCP call result as the text a turn records.
///
/// Binary payloads are reduced to a descriptor: tool output is persisted
/// verbatim into the conversation history and the timeline, so passing a
/// multi-megabyte base64 image through would blow up both.
String renderMcpToolOutput(McpCallToolResult result) {
  if (result.structuredContent case final structured?) {
    return truncateToolOutput(jsonEncode(structured));
  }
  final rendered = result.content
      .map(_renderBlock)
      .where((text) => text.isNotEmpty)
      .join('\n\n');
  return truncateToolOutput(rendered);
}

String _renderBlock(McpContentBlock block) => switch (block) {
  McpTextContent(:final text) => text,
  McpEmbeddedResource(:final uri, :final text?) => '$uri\n$text',
  McpEmbeddedResource(:final uri, :final mimeType, :final blob) =>
    '[resource uri=$uri${_mime(mimeType)}${_bytes(_base64Bytes(blob))}]',
  McpResourceLink(:final uri, :final name, :final mimeType) =>
    '[resource_link uri=$uri${_named(name)}${_mime(mimeType)}]',
  McpImageContent(:final mimeType, :final data) =>
    '[image mimeType=$mimeType${_bytes(_base64Bytes(data))}]',
  McpAudioContent(:final mimeType, :final data) =>
    '[audio mimeType=$mimeType${_bytes(_base64Bytes(data))}]',
  McpUnknownContent(:final type) => '[unsupported content type=$type]',
};

String _mime(String? mimeType) => mimeType == null ? '' : ' mimeType=$mimeType';

String _named(String? name) => name == null ? '' : ' name=$name';

String _bytes(int? byteLength) =>
    byteLength == null ? '' : ' bytes=$byteLength';

int? _base64Bytes(String? data) {
  if (data == null) return null;
  try {
    return base64Decode(data).length;
  } on FormatException {
    return null;
  }
}

ToolContent _toolContent(McpContentBlock block) => switch (block) {
  McpTextContent(:final text, :final annotations, :final meta) =>
    ToolTextContent(text, annotations: annotations, meta: meta),
  McpImageContent(
    :final mimeType,
    :final data,
    :final annotations,
    :final meta,
  ) =>
    ToolImageContent(
      imageUrl: 'data:$mimeType;base64,$data',
      annotations: annotations,
      meta: meta,
    ),
  McpAudioContent(
    :final mimeType,
    :final data,
    :final annotations,
    :final meta,
  ) =>
    ToolAudioContent(
      audioUrl: 'data:$mimeType;base64,$data',
      annotations: annotations,
      meta: meta,
    ),
  McpEmbeddedResource(
    :final uri,
    :final mimeType,
    :final text,
    :final blob,
    :final annotations,
    :final meta,
  ) =>
    ToolEmbeddedResourceContent(
      uri: uri,
      mimeType: mimeType,
      text: text,
      blob: blob,
      annotations: annotations,
      meta: meta,
    ),
  McpResourceLink(
    :final uri,
    :final name,
    :final title,
    :final description,
    :final mimeType,
    :final size,
    :final annotations,
    :final meta,
  ) =>
    ToolResourceLinkContent(
      name: name ?? uri,
      uri: uri,
      title: title,
      description: description,
      mimeType: mimeType,
      size: size,
      annotations: annotations,
      meta: meta,
    ),
  McpUnknownContent(:final raw, :final annotations, :final meta) =>
    ToolTextContent(jsonEncode(raw), annotations: annotations, meta: meta),
};

/// Resolves the live client for one MCP server, or null when it is not ready.
typedef McpClientLookup = McpClient? Function(String serverId);

/// Presents one tool published by an MCP server as an [AgentTool].
final class McpAgentTool extends AgentTool {
  /// Creates a tool bound to [serverId] and [descriptor].
  McpAgentTool({
    required this.serverId,
    required this.descriptor,
    required this._lookup,
    this.exposure = ToolExposure.advertised,
  });

  /// Which configured server publishes this tool.
  final String serverId;

  /// What the server said about the tool.
  final McpToolDescriptor descriptor;

  // A lookup rather than a client: the connection is replaced on every
  // reconnect, and a tool held by the model must follow the live one.
  final McpClientLookup _lookup;

  @override
  String get name => mcpToolId(serverId, descriptor.name);

  @override
  String get description => descriptor.description ?? descriptor.name;

  /// Grades the tool from what the server said about it.
  ///
  /// A name tells you nothing about external effects, so the default stays
  /// [AgentToolRisk.dangerous]. A server that declares a tool read-only is
  /// taken at its word only far enough to drop it to [AgentToolRisk.read];
  /// that spares the
  /// user an approval dialog for every lookup without granting anything a
  /// permission mode withheld, because `readOnly` still denies everything
  /// above `read`. A tool that is not read-only stays dangerous even when the
  /// server calls it non-destructive: "changes something, but gently" is still
  /// a change the user should see.
  @override
  AgentToolRisk get risk => AgentToolRisk.dangerous;

  @override
  bool get strict => false;

  /// Whether this tool is advertised up front or found through a search.
  @override
  final ToolExposure exposure;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      normalizeMcpInputSchema(descriptor.inputSchema);

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => '$serverId.${descriptor.title ?? descriptor.name}';

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final client = _lookup(serverId);
    if (client == null || !client.isConnected) {
      return _failure('MCP server "$serverId" is not connected.');
    }
    try {
      final result = await client.callTool(descriptor.name, arguments);
      return ToolResult(
        value: result.structuredContent ?? renderMcpToolOutput(result),
        content: result.content.map(_toolContent).toList(growable: false),
        structuredContent: result.structuredContent,
        meta: result.meta,
        isError: result.isError,
      );
    } on Object catch (error) {
      // An exception escaping here would fail the whole turn. Reporting the
      // failure as tool output lets the model recover or explain instead.
      return _failure('$error');
    }
  }

  ToolResult _failure(String message) => ToolResult(
    value: jsonEncode(<String, dynamic>{'error': message}),
    isError: true,
  );
}
