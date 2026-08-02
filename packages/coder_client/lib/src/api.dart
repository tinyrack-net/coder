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

/// AgentUpdatedClientEvent defines a public contract.
final class AgentUpdatedClientEvent extends ClientEvent {
  /// Creates a [AgentUpdatedClientEvent].
  const AgentUpdatedClientEvent(this.agent);

  /// The agent public API member.
  final AgentDto agent;
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

  /// The listWorkspaces public API member.
  Future<List<WorkspaceDto>> listWorkspaces();

  /// The registerWorkspace public API member.
  Future<WorkspaceDto> registerWorkspace({
    required String id,
    required String rootPath,
    required String name,
  });

  /// The listAgents public API member.
  Future<List<AgentDto>> listAgents({String? workspaceId});

  /// The createAgent public API member.
  Future<AgentDto> createAgent({
    required String id,
    required String workspaceId,
    required String title,
    required String providerConnectionId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  });

  /// The updateAgentConfiguration public API member.
  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerConnectionId,
    required String model,
    String reasoningEffort = 'medium',
  });

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
    required String agentId,
    required String turnId,
    required String prompt,
  });

  /// The cancelTurn public API member.
  Future<void> cancelTurn(String agentId);

  /// The resolveApproval public API member.
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  });

  /// The subscribeTimeline public API member.
  Future<List<TimelineEventDto>> subscribeTimeline(
    String agentId, {
    int afterSequence = 0,
  });

  /// The close public API member.
  Future<void> close();
}
