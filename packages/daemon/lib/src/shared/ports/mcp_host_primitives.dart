import 'package:daemon/src/shared/ports/request_cancellation.dart';

/// Worktree-scoped raw MCP transport exposed to Lua without model policy.
abstract interface class McpHostPrimitiveGateway {
  /// Lists raw resource descriptors or one cursor page.
  Future<Map<String, Object?>> listResources(Map<String, Object?> arguments);

  /// Lists raw resource-template descriptors or one cursor page.
  Future<Map<String, Object?>> listResourceTemplates(
    Map<String, Object?> arguments,
  );

  /// Reads one raw MCP resource result.
  Future<Map<String, Object?>> readResource(Map<String, Object?> arguments);

  /// Returns raw external tool descriptors for Lua-owned contributions.
  Future<Map<String, Object?>> catalogTools(Map<String, Object?> arguments);

  /// Invokes one raw external MCP tool.
  Future<Map<String, Object?>> invokeTool(
    Map<String, Object?> arguments, {
    RequestCancellation? cancellation,
  });
}
