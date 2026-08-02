import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Public API exposed by this library.
abstract interface class SettingsRepository {
  /// The getValue public API member.
  Future<String?> getValue(String key);

  /// The setValue public API member.
  Future<void> setValue(String key, String value);
}

/// Public API exposed by this library.
abstract interface class WorkspaceRepository {
  /// The list public API member.
  Future<List<WorkspaceDto>> list();

  /// The getById public API member.
  Future<WorkspaceDto?> getById(String id);

  /// The register public API member.
  Future<WorkspaceDto> register(WorkspaceDto workspace);
}

/// Public API exposed by this library.
abstract interface class AgentRepository {
  /// The list public API member.
  Future<List<AgentDto>> list({String? workspaceId});

  /// The getById public API member.
  Future<AgentDto?> getById(String id);

  /// The create public API member.
  Future<AgentDto> create(AgentDto agent);

  /// The updateStatus public API member.
  Future<AgentDto> updateStatus(
    String id,
    AgentStatus status, {
    String? activeTurnId,
    String? error,
  });

  /// The updateConfiguration public API member.
  Future<AgentDto> updateConfiguration({
    required String id,
    required String providerId,
    required String model,
    required String reasoningEffort,
  });

  /// The createTurn public API member.
  Future<bool> createTurn({
    required String id,
    required String agentId,
    required String prompt,
  });

  /// The updateTurn public API member.
  Future<void> updateTurn(String id, TurnStatus status, {String? error});
}

/// Public API exposed by this library.
abstract interface class TimelineRepository {
  /// The append public API member.
  Future<TimelineEventDto> append({
    required String agentId,
    required String type,
    required Map<String, dynamic> data,
    String? turnId,
  });

  /// The after public API member.
  Future<List<TimelineEventDto>> after(String agentId, int sequence);

  /// The appendProviderItems public API member.
  Future<void> appendProviderItems(
    String agentId,
    List<ConversationItem> items,
  );

  /// The providerHistory public API member.
  Future<List<ConversationItem>> providerHistory(String agentId);

  /// The createApproval public API member.
  Future<void> createApproval(ApprovalRequestDto approval);

  /// The resolveApproval public API member.
  Future<ApprovalRequestDto?> resolveApproval(String id, ApprovalStatus status);
}

/// Public API exposed by this library.
abstract interface class ProviderRepository {
  /// The listProviders public API member.
  Future<List<ApiProviderDto>> listProviders();

  /// The getProvider public API member.
  Future<ApiProviderDto?> getProvider(String id);

  /// The upsertProvider public API member.
  Future<ApiProviderDto> upsertProvider(ApiProviderDto provider);

  /// The deleteProvider public API member.
  Future<void> deleteProvider(String id);

  /// The listModels public API member.
  Future<List<ProviderModelDto>> listModels(String providerId);

  /// The getModel public API member.
  Future<ProviderModelDto?> getModel(String providerId, String modelId);

  /// The upsertModel public API member.
  Future<ProviderModelDto> upsertModel(ProviderModelDto model);

  /// The replaceDiscoveredModels public API member.
  Future<void> replaceDiscoveredModels(
    String providerId,
    Iterable<ProviderModelDto> models,
  );

  /// The deleteModel public API member.
  Future<void> deleteModel(String providerId, String modelId);
}

/// Public API exposed by this library.
abstract interface class RecoveryRepository {
  /// The recoverInterruptedRuns public API member.
  Future<void> recoverInterruptedRuns();
}

/// Public API exposed by this library.
abstract interface class CredentialRepository {
  /// The load public API member.
  Future<void> load();

  /// The bearerToken public API member.
  String? get bearerToken;

  /// The setBearerToken public API member.
  Future<void> setBearerToken(String token);

  /// The providerApiKey public API member.
  String? providerApiKey(String providerId);

  /// The setProviderApiKey public API member.
  Future<void> setProviderApiKey(String providerId, String value);

  /// The removeProvider public API member.
  Future<void> removeProvider(String providerId);
}
