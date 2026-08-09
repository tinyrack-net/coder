import 'package:protocol/protocol.dart';

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
/// Returns null when the definition's selection cannot be satisfied, which
/// hands the choice to the next step of [effectiveModelFor]. Unlike the daemon
/// this validates only the connection, because the model list of a connection
/// the composer never touches may not be loaded.
SessionModelSelectionDto? agentSelectionFor(
  AgentDefinitionDto definition,
  List<ProviderConnectionDto> connections,
) {
  final usable = usableConnections(connections);
  switch (definition.model.source) {
    case AgentModelSource.session:
      return null;
    case AgentModelSource.fixed:
      final modelId = definition.model.qualifiedModelId;
      if (modelId == null) return null;
      if (!usable.any(
        (connection) => modelId.startsWith('${connection.modelPrefix}/'),
      )) {
        return null;
      }
      return SessionModelSelectionDto(modelId: modelId);
  }
}

/// Whether one selection names a connection and model that can run a turn.
///
/// Mirrors the daemon predicate so the composer never shows a model the daemon
/// would refuse at turn start.
bool isRunnableSelection(
  SessionModelSelectionDto selection,
  List<ProviderConnectionDto> connections,
  Map<String, List<ProviderModelDto>> models,
) {
  final usable = usableConnections(connections);
  for (final connection in usable) {
    for (final model in models[connection.id] ?? const <ProviderModelDto>[]) {
      if (model.id == selection.qualifiedModelId) {
        return _isRunnableModel(model);
      }
    }
  }
  return false;
}

/// Returns the first runnable model of the first usable connection.
///
/// [connections] must arrive in daemon order (display name ascending) and the
/// lists in [models] in `listProviderModels` order (label ascending), so this
/// resolves to the same model the daemon would pick.
SessionModelSelectionDto? firstUsableModel(
  List<ProviderConnectionDto> connections,
  Map<String, List<ProviderModelDto>> models,
) {
  for (final connection in usableConnections(connections)) {
    for (final model in models[connection.id] ?? const <ProviderModelDto>[]) {
      if (!_isRunnableModel(model)) continue;
      return SessionModelSelectionDto(modelId: model.id);
    }
  }
  return null;
}

/// Resolves the model a session runs on when it has no explicit override.
///
/// Applies the agent definition, then the daemon-global [defaultModel], then
/// the first usable provider model. Returns null only when no connected
/// provider offers a runnable model.
SessionModelSelectionDto? effectiveModelFor({
  required AgentDefinitionDto? definition,
  required List<ProviderConnectionDto> connections,
  required Map<String, List<ProviderModelDto>> models,
  SessionModelSelectionDto? defaultModel,
}) {
  if (definition != null) {
    final pinned = agentSelectionFor(definition, connections);
    if (pinned != null) return pinned;
  }
  if (defaultModel != null &&
      isRunnableSelection(defaultModel, connections, models)) {
    return defaultModel;
  }
  return firstUsableModel(connections, models);
}

bool _isRunnableModel(ProviderModelDto model) =>
    model.capabilities.streaming == CapabilitySupport.supported &&
    model.capabilities.toolCalling == CapabilitySupport.supported;
