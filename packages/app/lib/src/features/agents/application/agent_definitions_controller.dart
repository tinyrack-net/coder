import 'dart:async';

import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:protocol/protocol.dart';
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
  final List<StreamSubscription<void>> _events = <StreamSubscription<void>>[];

  @override
  Future<AgentDefinitionsState> build(String hostId) async {
    final api = await watchHostApi(ref, hostId);
    _events
      ..add(api.agents.definitionChanges.listen((_) => unawaited(refresh())))
      ..add(api.mcp.serverChanges.listen((_) => unawaited(refresh())));
    ref.onDispose(() {
      for (final subscription in _events) {
        unawaited(subscription.cancel());
      }
    });
    return AgentDefinitionsState(
      definitions: await api.agents.listAgentDefinitions(),
      tools: await api.agents.listAgentTools(),
    );
  }

  /// Reloads files, diagnostics, and the tool catalog from the daemon.
  ///
  /// The catalog is re-read rather than reused: MCP servers publish and
  /// withdraw tools while the daemon runs, so a cached list goes stale.
  Future<void> refresh() async {
    final api = await requireHostApi(ref, hostId);
    final definitions = await api.agents.listAgentDefinitions();
    final tools = await api.agents.listAgentTools();
    if (!ref.mounted) return;
    state = AsyncData<AgentDefinitionsState>(
      AgentDefinitionsState(
        definitions: definitions,
        tools: tools,
      ),
    );
  }

  /// Creates a custom Markdown-backed definition.
  Future<AgentDefinitionDto> create(
    String id,
    AgentDefinitionDto definition,
  ) async {
    final api = await requireHostApi(ref, hostId);
    final created = await api.agents.createAgentDefinition(id, definition);
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
    final updated = await api.agents.updateAgentDefinition(
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
    await api.agents.archiveAgentDefinition(id);
    await refresh();
  }

  /// Restores the built-in Coder definition.
  Future<AgentDefinitionDto> resetCoder() async {
    final api = await requireHostApi(ref, hostId);
    final reset = await api.agents.resetAgentDefinition('coder');
    await refresh();
    return reset;
  }
}
