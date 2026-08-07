import 'dart:async';

import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_definitions_controller.g.dart';

/// Agent definition editor data owned by one daemon.
final class AgentDefinitionsState {
  /// Creates an immutable Markdown agent catalog snapshot.
  const AgentDefinitionsState({
    required this.definitions,
    required this.tools,
  });

  /// Visible primary and subagent definitions.
  final List<AgentDefinitionDto> definitions;

  /// Tools this daemon can execute.
  final List<AgentToolDefinitionDto> tools;
}

@riverpod
/// Loads and edits one daemon's Markdown agent files.
class AgentDefinitionsController extends _$AgentDefinitionsController {
  StreamSubscription<ClientEvent>? _events;

  @override
  Future<AgentDefinitionsState> build(String hostId) async {
    final api = await watchHostApi(ref, hostId);
    _events = api.events.listen((event) {
      // An MCP server coming up changes the tool catalog, so both events
      // invalidate this state.
      if (event is AgentDefinitionsChangedClientEvent ||
          event is McpServersChangedClientEvent) {
        unawaited(refresh());
      }
    });
    ref.onDispose(() => unawaited(_events?.cancel()));
    return AgentDefinitionsState(
      definitions: await api.listAgentDefinitions(),
      tools: await api.listAgentTools(),
    );
  }

  /// Reloads files, diagnostics, and the tool catalog from the daemon.
  ///
  /// The catalog is re-read rather than reused: MCP servers publish and
  /// withdraw tools while the daemon runs, so a cached list goes stale.
  Future<void> refresh() async {
    final api = await requireHostApi(ref, hostId);
    state = AsyncData<AgentDefinitionsState>(
      AgentDefinitionsState(
        definitions: await api.listAgentDefinitions(),
        tools: await api.listAgentTools(),
      ),
    );
  }

  /// Creates a custom Markdown-backed definition.
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final api = await requireHostApi(ref, hostId);
    final created = await api.createAgentDefinition(id, definition);
    await refresh();
    return created;
  }

  /// Saves an edit, rejecting external-file races by default.
  Future<AgentDefinitionDto> saveDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  }) async {
    final api = await requireHostApi(ref, hostId);
    final updated = await api.updateAgentDefinition(
      definition,
      expectedContentHash: expectedContentHash,
      force: force,
    );
    await refresh();
    return updated;
  }

  /// Archives one custom definition.
  Future<void> archive(String id) async {
    final api = await requireHostApi(ref, hostId);
    await api.archiveAgentDefinition(id);
    await refresh();
  }

  /// Restores the built-in Coder definition.
  Future<AgentDefinitionDto> resetCoder() async {
    final api = await requireHostApi(ref, hostId);
    final reset = await api.resetAgentDefinition('coder');
    await refresh();
    return reset;
  }
}
