import 'package:coder_protocol/src/models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'rpc_models.freezed.dart';
part 'rpc_models.g.dart';

@freezed
/// HelloParamsDto defines a public contract.
abstract class HelloParamsDto with _$HelloParamsDto {
  /// The HelloParamsDto public API member.
  const factory HelloParamsDto({
    required String clientId,
    required String clientKind,
    required int protocolVersion,
    required Map<String, bool> capabilities,
  }) = _HelloParamsDto;

  /// Creates a [HelloParamsDto].
  factory HelloParamsDto.fromJson(Map<String, dynamic> json) =>
      _$HelloParamsDtoFromJson(json);
}

@freezed
/// WorkspaceRegisterParamsDto defines a public contract.
abstract class WorkspaceRegisterParamsDto with _$WorkspaceRegisterParamsDto {
  /// The WorkspaceRegisterParamsDto public API member.
  const factory WorkspaceRegisterParamsDto({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  }) = _WorkspaceRegisterParamsDto;

  /// Creates a [WorkspaceRegisterParamsDto].
  factory WorkspaceRegisterParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceRegisterParamsDtoFromJson(json);
}

@freezed
/// Selects one registered workspace for refresh or removal.
abstract class WorkspaceIdParamsDto with _$WorkspaceIdParamsDto {
  /// Creates workspace identifier parameters.
  const factory WorkspaceIdParamsDto({required String workspaceId}) =
      _WorkspaceIdParamsDto;

  /// Decodes workspace identifier parameters.
  factory WorkspaceIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceIdParamsDtoFromJson(json);
}

@freezed
/// Searches directories on the daemon host.
abstract class DirectorySuggestParamsDto with _$DirectorySuggestParamsDto {
  /// Creates directory search parameters.
  const factory DirectorySuggestParamsDto({
    required String query,
    @Default(30) int limit,
  }) = _DirectorySuggestParamsDto;

  /// Decodes directory search parameters.
  factory DirectorySuggestParamsDto.fromJson(Map<String, dynamic> json) =>
      _$DirectorySuggestParamsDtoFromJson(json);
}

@freezed
/// Requests local branches for one Git workspace.
abstract class GitBranchesListParamsDto with _$GitBranchesListParamsDto {
  /// Creates branch-list parameters.
  const factory GitBranchesListParamsDto({required String workspaceId}) =
      _GitBranchesListParamsDto;

  /// Decodes branch-list parameters.
  factory GitBranchesListParamsDto.fromJson(Map<String, dynamic> json) =>
      _$GitBranchesListParamsDtoFromJson(json);
}

@freezed
/// Creates a managed Git worktree from a new or existing local branch.
abstract class WorktreeCreateParamsDto with _$WorktreeCreateParamsDto {
  /// Creates managed-worktree parameters.
  const factory WorktreeCreateParamsDto({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  }) = _WorktreeCreateParamsDto;

  /// Decodes managed-worktree parameters.
  factory WorktreeCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeCreateParamsDtoFromJson(json);
}

@freezed
/// Identifies one worktree.
abstract class WorktreeIdParamsDto with _$WorktreeIdParamsDto {
  /// Creates worktree identifier parameters.
  const factory WorktreeIdParamsDto({required String worktreeId}) =
      _WorktreeIdParamsDto;

  /// Decodes worktree identifier parameters.
  factory WorktreeIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeIdParamsDtoFromJson(json);
}

@freezed
/// Confirms archive risks for one worktree.
abstract class WorktreeArchiveParamsDto with _$WorktreeArchiveParamsDto {
  /// Creates worktree archive parameters.
  const factory WorktreeArchiveParamsDto({
    required String worktreeId,
    required bool force,
  }) = _WorktreeArchiveParamsDto;

  /// Decodes worktree archive parameters.
  factory WorktreeArchiveParamsDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeArchiveParamsDtoFromJson(json);
}

@freezed
/// AgentListParamsDto defines a public contract.
abstract class AgentListParamsDto with _$AgentListParamsDto {
  /// The AgentListParamsDto public API member.
  const factory AgentListParamsDto({String? worktreeId}) = _AgentListParamsDto;

  /// Creates a [AgentListParamsDto].
  factory AgentListParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentListParamsDtoFromJson(json);
}

@freezed
/// AgentCreateParamsDto defines a public contract.
abstract class AgentCreateParamsDto with _$AgentCreateParamsDto {
  /// The AgentCreateParamsDto public API member.
  const factory AgentCreateParamsDto({
    required String id,
    required String worktreeId,
    required String title,
    required String providerConnectionId,
    required String model,
    required String reasoningEffort,
    required PermissionMode permissionMode,
  }) = _AgentCreateParamsDto;

  /// Creates a [AgentCreateParamsDto].
  factory AgentCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCreateParamsDtoFromJson(json);
}

@freezed
/// AgentConfigurationUpdateParamsDto defines a public contract.
abstract class AgentConfigurationUpdateParamsDto
    with _$AgentConfigurationUpdateParamsDto {
  /// The AgentConfigurationUpdateParamsDto public API member.
  const factory AgentConfigurationUpdateParamsDto({
    required String agentId,
    required String providerConnectionId,
    required String model,
    required String reasoningEffort,
  }) = _AgentConfigurationUpdateParamsDto;

  /// Creates a [AgentConfigurationUpdateParamsDto].
  factory AgentConfigurationUpdateParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentConfigurationUpdateParamsDtoFromJson(json);
}

@freezed
/// Parameters for connecting a built-in provider with an API key.
abstract class ProviderConnectApiKeyParamsDto
    with _$ProviderConnectApiKeyParamsDto {
  /// Creates API-key connection parameters.
  const factory ProviderConnectApiKeyParamsDto({
    required String definitionId,
    required String apiKey,
    required bool makeDefault,
  }) = _ProviderConnectApiKeyParamsDto;

  /// Decodes API-key connection parameters.
  factory ProviderConnectApiKeyParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectApiKeyParamsDtoFromJson(json);
}

@freezed
/// Parameters for connecting a provider that needs no credentials.
abstract class ProviderConnectNoneParamsDto
    with _$ProviderConnectNoneParamsDto {
  /// Creates no-auth connection parameters.
  const factory ProviderConnectNoneParamsDto({
    required String definitionId,
    required bool makeDefault,
  }) = _ProviderConnectNoneParamsDto;

  /// Decodes no-auth connection parameters.
  factory ProviderConnectNoneParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectNoneParamsDtoFromJson(json);
}

@freezed
/// Parameters identifying one provider connection.
abstract class ProviderConnectionIdParamsDto
    with _$ProviderConnectionIdParamsDto {
  /// Creates provider connection identifier parameters.
  const factory ProviderConnectionIdParamsDto({required String connectionId}) =
      _ProviderConnectionIdParamsDto;

  /// Decodes provider connection identifier parameters.
  factory ProviderConnectionIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectionIdParamsDtoFromJson(json);
}

@freezed
/// ProviderModelParamsDto defines a public contract.
abstract class ProviderModelParamsDto with _$ProviderModelParamsDto {
  /// The ProviderModelParamsDto public API member.
  const factory ProviderModelParamsDto({
    required String connectionId,
    required String modelId,
  }) = _ProviderModelParamsDto;

  /// Creates a [ProviderModelParamsDto].
  factory ProviderModelParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelParamsDtoFromJson(json);
}

@freezed
/// Parameters for starting a provider OAuth flow.
abstract class ProviderAuthStartParamsDto with _$ProviderAuthStartParamsDto {
  /// Creates OAuth start parameters.
  const factory ProviderAuthStartParamsDto({
    required String definitionId,
    required String methodId,
    required bool makeDefault,
  }) = _ProviderAuthStartParamsDto;

  /// Decodes OAuth start parameters.
  factory ProviderAuthStartParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthStartParamsDtoFromJson(json);
}

@freezed
/// Parameters identifying a provider authorization attempt.
abstract class ProviderAuthAttemptParamsDto
    with _$ProviderAuthAttemptParamsDto {
  /// Creates authorization attempt parameters.
  const factory ProviderAuthAttemptParamsDto({required String attemptId}) =
      _ProviderAuthAttemptParamsDto;

  /// Decodes authorization attempt parameters.
  factory ProviderAuthAttemptParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthAttemptParamsDtoFromJson(json);
}

@freezed
/// Parameters for selecting the daemon-wide default provider connection.
abstract class ProviderDefaultSetParamsDto with _$ProviderDefaultSetParamsDto {
  /// Creates default provider parameters.
  const factory ProviderDefaultSetParamsDto({required String connectionId}) =
      _ProviderDefaultSetParamsDto;

  /// Decodes default provider parameters.
  factory ProviderDefaultSetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDefaultSetParamsDtoFromJson(json);
}

@freezed
/// Parameters for selecting a connection's default model.
abstract class ProviderDefaultModelSetParamsDto
    with _$ProviderDefaultModelSetParamsDto {
  /// Creates default model parameters.
  const factory ProviderDefaultModelSetParamsDto({
    required String connectionId,
    required String modelId,
  }) = _ProviderDefaultModelSetParamsDto;

  /// Decodes default model parameters.
  factory ProviderDefaultModelSetParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$ProviderDefaultModelSetParamsDtoFromJson(json);
}

@freezed
/// Parameters for creating an advanced custom provider connection.
abstract class ProviderCustomCreateParamsDto
    with _$ProviderCustomCreateParamsDto {
  /// Creates custom provider parameters.
  const factory ProviderCustomCreateParamsDto({
    required String id,
    required CustomProviderConfigDto config,
    required bool makeDefault,
    String? apiKey,
  }) = _ProviderCustomCreateParamsDto;

  /// Decodes custom provider parameters.
  factory ProviderCustomCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCustomCreateParamsDtoFromJson(json);
}

@freezed
/// Parameters for updating an advanced custom provider connection.
abstract class ProviderCustomUpdateParamsDto
    with _$ProviderCustomUpdateParamsDto {
  /// Creates custom provider update parameters.
  const factory ProviderCustomUpdateParamsDto({
    required String connectionId,
    required CustomProviderConfigDto config,
    String? apiKey,
  }) = _ProviderCustomUpdateParamsDto;

  /// Decodes custom provider update parameters.
  factory ProviderCustomUpdateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCustomUpdateParamsDtoFromJson(json);
}

@freezed
/// TurnStartParamsDto defines a public contract.
abstract class TurnStartParamsDto with _$TurnStartParamsDto {
  /// The TurnStartParamsDto public API member.
  const factory TurnStartParamsDto({
    required String agentId,
    required String turnId,
    required String prompt,
  }) = _TurnStartParamsDto;

  /// Creates a [TurnStartParamsDto].
  factory TurnStartParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TurnStartParamsDtoFromJson(json);
}

@freezed
/// AgentIdParamsDto defines a public contract.
abstract class AgentIdParamsDto with _$AgentIdParamsDto {
  /// The AgentIdParamsDto public API member.
  const factory AgentIdParamsDto({required String agentId}) = _AgentIdParamsDto;

  /// Creates a [AgentIdParamsDto].
  factory AgentIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentIdParamsDtoFromJson(json);
}

@freezed
/// ApprovalResolveParamsDto defines a public contract.
abstract class ApprovalResolveParamsDto with _$ApprovalResolveParamsDto {
  /// The ApprovalResolveParamsDto public API member.
  const factory ApprovalResolveParamsDto({
    required String approvalId,
    required bool approved,
  }) = _ApprovalResolveParamsDto;

  /// Creates a [ApprovalResolveParamsDto].
  factory ApprovalResolveParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalResolveParamsDtoFromJson(json);
}

@freezed
/// TimelineSubscribeParamsDto defines a public contract.
abstract class TimelineSubscribeParamsDto with _$TimelineSubscribeParamsDto {
  /// The TimelineSubscribeParamsDto public API member.
  const factory TimelineSubscribeParamsDto({
    required String agentId,
    required int afterSequence,
  }) = _TimelineSubscribeParamsDto;

  /// Creates a [TimelineSubscribeParamsDto].
  factory TimelineSubscribeParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineSubscribeParamsDtoFromJson(json);
}

@freezed
/// Result containing an atomic workspace catalog.
abstract class WorkspaceCatalogResultDto with _$WorkspaceCatalogResultDto {
  /// Creates a workspace catalog result.
  const factory WorkspaceCatalogResultDto({
    required WorkspaceCatalogDto catalog,
  }) = _WorkspaceCatalogResultDto;

  /// Decodes a workspace catalog result.
  factory WorkspaceCatalogResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceCatalogResultDtoFromJson(json);
}

@freezed
/// Result of registering one workspace and its discovered checkouts.
abstract class WorkspaceRegisterResultDto with _$WorkspaceRegisterResultDto {
  /// Creates a workspace registration result.
  const factory WorkspaceRegisterResultDto({
    required WorkspaceDto workspace,
    required List<WorktreeDto> worktrees,
  }) = _WorkspaceRegisterResultDto;

  /// Decodes a workspace registration result.
  factory WorkspaceRegisterResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceRegisterResultDtoFromJson(json);
}

@freezed
/// Boolean result for unregistering a workspace.
abstract class WorkspaceUnregisterResultDto
    with _$WorkspaceUnregisterResultDto {
  /// Creates an unregister result.
  const factory WorkspaceUnregisterResultDto({required bool unregistered}) =
      _WorkspaceUnregisterResultDto;

  /// Decodes an unregister result.
  factory WorkspaceUnregisterResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceUnregisterResultDtoFromJson(json);
}

@freezed
/// Result of daemon-side directory search.
abstract class DirectorySuggestResultDto with _$DirectorySuggestResultDto {
  /// Creates directory suggestions.
  const factory DirectorySuggestResultDto({
    required List<DirectorySuggestionDto> suggestions,
  }) = _DirectorySuggestResultDto;

  /// Decodes directory suggestions.
  factory DirectorySuggestResultDto.fromJson(Map<String, dynamic> json) =>
      _$DirectorySuggestResultDtoFromJson(json);
}

@freezed
/// Result containing local Git branches.
abstract class GitBranchesListResultDto with _$GitBranchesListResultDto {
  /// Creates a branch-list result.
  const factory GitBranchesListResultDto({
    required List<GitBranchDto> branches,
  }) = _GitBranchesListResultDto;

  /// Decodes a branch-list result.
  factory GitBranchesListResultDto.fromJson(Map<String, dynamic> json) =>
      _$GitBranchesListResultDtoFromJson(json);
}

@freezed
/// Result containing one worktree.
abstract class WorktreeResultDto with _$WorktreeResultDto {
  /// Creates a worktree result.
  const factory WorktreeResultDto({required WorktreeDto worktree}) =
      _WorktreeResultDto;

  /// Decodes a worktree result.
  factory WorktreeResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeResultDtoFromJson(json);
}

@freezed
/// Result containing archive risk information.
abstract class WorktreeArchivePreviewResultDto
    with _$WorktreeArchivePreviewResultDto {
  /// Creates an archive preview result.
  const factory WorktreeArchivePreviewResultDto({
    required WorktreeArchivePreviewDto preview,
  }) = _WorktreeArchivePreviewResultDto;

  /// Decodes an archive preview result.
  factory WorktreeArchivePreviewResultDto.fromJson(
    Map<String, dynamic> json,
  ) => _$WorktreeArchivePreviewResultDtoFromJson(json);
}

@freezed
/// AgentListResultDto defines a public contract.
abstract class AgentListResultDto with _$AgentListResultDto {
  /// The AgentListResultDto public API member.
  const factory AgentListResultDto({required List<AgentDto> agents}) =
      _AgentListResultDto;

  /// Creates a [AgentListResultDto].
  factory AgentListResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentListResultDtoFromJson(json);
}

@freezed
/// AgentResultDto defines a public contract.
abstract class AgentResultDto with _$AgentResultDto {
  /// The AgentResultDto public API member.
  const factory AgentResultDto({required AgentDto agent}) = _AgentResultDto;

  /// Creates a [AgentResultDto].
  factory AgentResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentResultDtoFromJson(json);
}

@freezed
/// ProviderCatalogResultDto defines a public contract.
abstract class ProviderCatalogResultDto with _$ProviderCatalogResultDto {
  /// The ProviderCatalogResultDto public API member.
  const factory ProviderCatalogResultDto({
    required ProviderCatalogDto catalog,
  }) = _ProviderCatalogResultDto;

  /// Creates a [ProviderCatalogResultDto].
  factory ProviderCatalogResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCatalogResultDtoFromJson(json);
}

@freezed
/// Result containing all configured provider connections.
abstract class ProviderConnectionsResultDto
    with _$ProviderConnectionsResultDto {
  /// Creates a provider connections result.
  const factory ProviderConnectionsResultDto({
    required List<ProviderConnectionDto> connections,
  }) = _ProviderConnectionsResultDto;

  /// Decodes a provider connections result.
  factory ProviderConnectionsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectionsResultDtoFromJson(json);
}

@freezed
/// Result containing one configured provider connection.
abstract class ProviderConnectionResultDto with _$ProviderConnectionResultDto {
  /// Creates a provider connection result.
  const factory ProviderConnectionResultDto({
    required ProviderConnectionDto connection,
  }) = _ProviderConnectionResultDto;

  /// Decodes a provider connection result.
  factory ProviderConnectionResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectionResultDtoFromJson(json);
}

@freezed
/// ProviderModelsResultDto defines a public contract.
abstract class ProviderModelsResultDto with _$ProviderModelsResultDto {
  /// The ProviderModelsResultDto public API member.
  const factory ProviderModelsResultDto({
    required List<ProviderModelDto> models,
  }) = _ProviderModelsResultDto;

  /// Creates a [ProviderModelsResultDto].
  factory ProviderModelsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelsResultDtoFromJson(json);
}

@freezed
/// Result containing one provider authorization attempt.
abstract class ProviderAuthAttemptResultDto
    with _$ProviderAuthAttemptResultDto {
  /// Creates an authorization attempt result.
  const factory ProviderAuthAttemptResultDto({
    required ProviderAuthAttemptDto attempt,
  }) = _ProviderAuthAttemptResultDto;

  /// Decodes an authorization attempt result.
  factory ProviderAuthAttemptResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthAttemptResultDtoFromJson(json);
}

@freezed
/// ProviderDiagnosticResultDto defines a public contract.
abstract class ProviderDiagnosticResultDto with _$ProviderDiagnosticResultDto {
  /// The ProviderDiagnosticResultDto public API member.
  const factory ProviderDiagnosticResultDto({
    required ProviderDiagnosticDto diagnostic,
  }) = _ProviderDiagnosticResultDto;

  /// Creates a [ProviderDiagnosticResultDto].
  factory ProviderDiagnosticResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDiagnosticResultDtoFromJson(json);
}

@freezed
/// TurnStartResultDto defines a public contract.
abstract class TurnStartResultDto with _$TurnStartResultDto {
  /// The TurnStartResultDto public API member.
  const factory TurnStartResultDto({required bool created}) =
      _TurnStartResultDto;

  /// Creates a [TurnStartResultDto].
  factory TurnStartResultDto.fromJson(Map<String, dynamic> json) =>
      _$TurnStartResultDtoFromJson(json);
}

@freezed
/// ApprovalResultDto defines a public contract.
abstract class ApprovalResultDto with _$ApprovalResultDto {
  /// The ApprovalResultDto public API member.
  const factory ApprovalResultDto({required ApprovalRequestDto approval}) =
      _ApprovalResultDto;

  /// Creates a [ApprovalResultDto].
  factory ApprovalResultDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalResultDtoFromJson(json);
}

@freezed
/// TimelineResultDto defines a public contract.
abstract class TimelineResultDto with _$TimelineResultDto {
  /// The TimelineResultDto public API member.
  const factory TimelineResultDto({required List<TimelineEventDto> events}) =
      _TimelineResultDto;

  /// Creates a [TimelineResultDto].
  factory TimelineResultDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineResultDtoFromJson(json);
}
