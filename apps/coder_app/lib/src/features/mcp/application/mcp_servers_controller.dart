import 'dart:async';

import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mcp_servers_controller.g.dart';

/// MCP server editor data owned by one daemon.
final class McpServersState {
  /// Creates immutable MCP server state.
  const McpServersState({required this.servers});

  /// Every server visible to this daemon and the selected worktree.
  final List<McpServerStateDto> servers;

  /// Servers the user configured, which are the editable ones.
  List<McpServerStateDto> get userServers => servers
      .where((server) => server.scope == McpConfigScope.user)
      .toList(growable: false);

  /// Servers the selected repository declares, which are read-only.
  List<McpServerStateDto> get projectServers => servers
      .where((server) => server.scope == McpConfigScope.project)
      .toList(growable: false);
}

@riverpod
/// Loads and edits one daemon's MCP server configuration.
class McpServersController extends _$McpServersController {
  StreamSubscription<void>? _events;
  int _refreshGeneration = 0;

  @override
  Future<McpServersState> build(String hostId, String? worktreeId) async {
    final api = await watchHostApi(ref, hostId);
    _events = api.mcp.serverChanges.listen((_) => unawaited(refresh()));
    ref.onDispose(() => unawaited(_events?.cancel()));
    return McpServersState(
      servers: await api.mcp.listMcpServers(worktreeId: worktreeId),
    );
  }

  /// Re-reads every server and its live connection state.
  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    final api = await requireHostApi(ref, hostId);
    final servers = await api.mcp.listMcpServers(worktreeId: worktreeId);
    if (!ref.mounted || generation != _refreshGeneration) return;
    state = AsyncData<McpServersState>(
      McpServersState(servers: servers),
    );
  }

  /// Adds one user-scoped server.
  Future<void> add(McpServerConfigDto server) async {
    final api = await requireHostApi(ref, hostId);
    await api.mcp.addMcpServer(server);
    await refresh();
  }

  /// Replaces one user-scoped server.
  Future<void> save(McpServerConfigDto server) async {
    final api = await requireHostApi(ref, hostId);
    await api.mcp.updateMcpServer(server);
    await refresh();
  }

  /// Removes one user-scoped server.
  Future<void> remove(String id) async {
    final api = await requireHostApi(ref, hostId);
    await api.mcp.removeMcpServer(id);
    await refresh();
  }

  /// Connects an unsaved configuration to report what it publishes.
  Future<McpServerStateDto> test(McpServerConfigDto server) async {
    final api = await requireHostApi(ref, hostId);
    return api.mcp.testMcpServer(server);
  }

  /// Stores one secret an MCP configuration may reference.
  Future<void> setSecret(String key, String value) async {
    final api = await requireHostApi(ref, hostId);
    await api.mcp.setMcpSecret(key, value);
  }
}
