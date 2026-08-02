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
    required String providerId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  });

  /// The updateAgentConfiguration public API member.
  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
  });

  /// The listProviderCatalog public API member.
  Future<ProviderCatalogDto> listProviderCatalog();

  /// The upsertProvider public API member.
  Future<ApiProviderDto> upsertProvider(
    ApiProviderDto provider, {
    bool makeDefault = false,
  });

  /// The deleteProvider public API member.
  Future<void> deleteProvider(String providerId);

  /// The listProviderModels public API member.
  Future<List<ProviderModelDto>> listProviderModels(String providerId);

  /// The refreshProviderModels public API member.
  Future<List<ProviderModelDto>> refreshProviderModels(String providerId);

  /// The upsertProviderModel public API member.
  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model);

  /// The deleteProviderModel public API member.
  Future<void> deleteProviderModel(String providerId, String modelId);

  /// The diagnoseProviderModel public API member.
  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  );

  /// The setProviderCredential public API member.
  Future<void> setProviderCredential(String providerId, String apiKey);

  /// The clearProviderCredential public API member.
  Future<void> clearProviderCredential(String providerId);

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
