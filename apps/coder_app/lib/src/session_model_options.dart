import 'package:coder_protocol/coder_protocol.dart';

/// Agent definitions a user may start a session with.
///
/// Unlike the daemon, this does not require the definition's own model to
/// resolve: the composer can pin an explicit provider and model instead.
List<AgentDefinitionDto> selectableAgentDefinitions(
  List<AgentDefinitionDto> definitions,
) => definitions
    .where(
      (definition) =>
          definition.mode == AgentMode.primary &&
          !definition.isArchived &&
          !definition.isStale,
    )
    .toList(growable: false);

/// Provider connections that can currently run a turn.
List<ProviderConnectionDto> usableConnections(
  List<ProviderConnectionDto> connections,
) => connections
    .where(
      (connection) =>
          connection.status == ProviderConnectionStatus.connected ||
          connection.status == ProviderConnectionStatus.degraded,
    )
    .toList(growable: false);

/// Resolves the provider and model a definition would use on its own.
///
/// Returns null when the definition's selection cannot be satisfied, which the
/// composer surfaces as "pick a model before sending".
SessionModelSelectionDto? defaultSelectionFor(
  AgentDefinitionDto definition,
  List<ProviderConnectionDto> connections,
) {
  final usable = usableConnections(connections);
  switch (definition.model.source) {
    case AgentModelSource.daemonDefault:
      for (final connection in usable) {
        final modelId = connection.defaultModelId;
        if (connection.isDefault && modelId != null) {
          return SessionModelSelectionDto(
            providerConnectionId: connection.id,
            modelId: modelId,
          );
        }
      }
      return null;
    case AgentModelSource.fixed:
      final connectionId = definition.model.providerConnectionId;
      final modelId = definition.model.modelId;
      if (connectionId == null || modelId == null) return null;
      if (!usable.any((connection) => connection.id == connectionId)) {
        return null;
      }
      return SessionModelSelectionDto(
        providerConnectionId: connectionId,
        modelId: modelId,
      );
  }
}
