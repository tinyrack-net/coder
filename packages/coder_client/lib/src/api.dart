import 'package:coder_protocol/coder_protocol.dart';

/// Values supported by ClientConnectionState.
enum ClientConnectionState {
  /// The initial connection is opening.
  connecting,

  /// The JSON-RPC handshake completed.
  connected,

  /// A previously connected client is reconnecting.
  reconnecting,

  /// No transport is currently connected.
  disconnected,
}

/// ClientEvent defines a public contract.
sealed class ClientEvent {
  const ClientEvent();
}

/// TimelineClientEvent defines a public contract.
final class TimelineClientEvent extends ClientEvent {
  /// Creates a [TimelineClientEvent].
  const TimelineClientEvent(this.event);

  /// The event public API member.
  final TimelineEventDto event;
}

/// SessionUpdatedClientEvent defines a public contract.
final class SessionUpdatedClientEvent extends ClientEvent {
  /// Creates a [SessionUpdatedClientEvent].
  const SessionUpdatedClientEvent(this.session);

  /// The agent public API member.
  final SessionDto session;
}

/// Signals that the daemon's Markdown agent files changed.
final class AgentDefinitionsChangedClientEvent extends ClientEvent {
  /// Creates a catalog invalidation event.
  const AgentDefinitionsChangedClientEvent();
}

/// ApprovalRequestedClientEvent defines a public contract.
final class ApprovalRequestedClientEvent extends ClientEvent {
  /// Creates a [ApprovalRequestedClientEvent].
  const ApprovalRequestedClientEvent(this.approval);

  /// The approval public API member.
  final ApprovalRequestDto approval;
}

/// Reports state changes for an interactive provider OAuth attempt.
final class ProviderAuthUpdatedClientEvent extends ClientEvent {
  /// Creates an OAuth attempt event.
  const ProviderAuthUpdatedClientEvent(this.attempt);

  /// Current authorization attempt state.
  final ProviderAuthAttemptDto attempt;
}

/// Public API exposed by this library.
abstract interface class CoderApi {
  /// The events public API member.
  Stream<ClientEvent> get events;

  /// The states public API member.
  Stream<ClientConnectionState> get states;

  /// The serverInfo public API member.
  ServerInfoDto get serverInfo;

  /// Returns the daemon's repositories and active checkouts atomically.
  Future<WorkspaceCatalogDto> getWorkspaceCatalog();

  /// The registerWorkspace public API member.
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  });

  /// Refreshes Git metadata and checkout registrations.
  Future<WorkspaceCatalogDto> refreshWorkspace(String workspaceId);

  /// Removes one repository registration.
  Future<void> unregisterWorkspace(String workspaceId);

  /// Searches directories on the daemon machine.
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query, {
    int limit = 30,
  });

  /// Lists local branches in one Git repository.
  Future<List<GitBranchDto>> listGitBranches(String workspaceId);

  /// Creates a managed Git worktree.
  Future<WorktreeDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  });

  /// Previews archive safety conditions.
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(String worktreeId);

  /// Archives a worktree registration and optionally its managed checkout.
  Future<WorktreeDto> archiveWorktree(String worktreeId, {bool force = false});

  /// The listSessions public API member.
  Future<List<SessionDto>> listSessions({String? worktreeId});

  /// The createSession public API member.
  ///
  /// A non-null [model] pins the session to one provider connection and model
  /// instead of inheriting the model selection of its agent definition.
  Future<SessionDto> createSession({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    SessionMode mode = SessionMode.normal,
    SessionModelSelectionDto? model,
  });

  /// Switches one session between planning and normal collaboration.
  Future<SessionDto> updateSessionMode(String sessionId, SessionMode mode);

  /// Sets or clears the provider and model override of one session.
  ///
  /// Passing a null [model] restores inheritance from the agent definition.
  Future<SessionDto> updateSessionModel(
    String sessionId,
    SessionModelSelectionDto? model,
  );

  /// Lists all visible Markdown-backed agent definitions.
  Future<List<AgentDefinitionDto>> listAgentDefinitions();

  /// Returns one Markdown-backed agent definition.
  Future<AgentDefinitionDto> getAgentDefinition(String id);

  /// Creates one custom Markdown-backed agent definition.
  Future<AgentDefinitionDto> createAgentDefinition(
    String id,
    AgentDefinitionDto definition,
  );

  /// Updates one definition with optimistic concurrency control.
  Future<AgentDefinitionDto> updateAgentDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  });

  /// Archives a custom definition while preserving existing sessions.
  Future<void> archiveAgentDefinition(String id);

  /// Restores the built-in Coder definition.
  Future<AgentDefinitionDto> resetAgentDefinition(String id);

  /// Validates a Markdown document without writing it.
  Future<AgentDefinitionDto> validateAgentDefinition(
    String id,
    String markdown,
  );

  /// Lists built-in tools available to agent definitions.
  Future<List<AgentToolDefinitionDto>> listAgentTools();

  /// The listProviderCatalog public API member.
  Future<ProviderCatalogDto> listProviderCatalog();

  /// Returns configured provider connections.
  Future<List<ProviderConnectionDto>> listProviderConnections();

  /// Connects a built-in provider with an API key.
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey, {
    bool makeDefault = false,
  });

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectProviderNone(
    String definitionId, {
    bool makeDefault = false,
  });

  /// Starts an interactive provider authorization flow.
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId, {
    bool makeDefault = false,
  });

  /// Returns the latest state of an authorization attempt.
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId);

  /// Cancels a pending authorization attempt.
  Future<void> cancelProviderAuth(String attemptId);

  /// Disconnects a provider while preserving historical agent data.
  Future<void> disconnectProvider(String connectionId);

  /// Selects the daemon-wide default provider connection.
  Future<void> setDefaultProvider(String connectionId);

  /// Selects a connection's default model.
  Future<void> setDefaultProviderModel(String connectionId, String modelId);

  /// Explicitly refreshes public provider and model metadata.
  Future<ProviderCatalogDto> refreshProviderCatalog();

  /// The listProviderModels public API member.
  Future<List<ProviderModelDto>> listProviderModels(String connectionId);

  /// Creates an advanced custom provider connection.
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
    bool makeDefault = false,
  });

  /// Updates an advanced custom provider connection.
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  });

  /// Deletes an advanced custom provider connection.
  Future<void> deleteCustomProvider(String connectionId);

  /// The startTurn public API member.
  Future<void> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
  });

  /// The cancelTurn public API member.
  Future<void> cancelTurn(String sessionId);

  /// The resolveApproval public API member.
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  });

  /// The subscribeTimeline public API member.
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  });

  /// The close public API member.
  Future<void> close();
}
