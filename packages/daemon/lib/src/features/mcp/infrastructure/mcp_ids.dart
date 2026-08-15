/// Separates the server and tool halves of an external MCP tool id.
const String mcpToolIdSeparator = '__';

/// Returns the stable external id for [toolName] on [serverId].
String mcpToolId(String serverId, String toolName) =>
    'mcp$mcpToolIdSeparator$serverId$mcpToolIdSeparator$toolName';
