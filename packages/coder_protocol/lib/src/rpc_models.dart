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
/// Filters sessions by worktree.
abstract class SessionListParamsDto with _$SessionListParamsDto {
  /// Creates session list parameters.
  const factory SessionListParamsDto({String? worktreeId}) =
      _SessionListParamsDto;

  /// Decodes session list parameters.
  factory SessionListParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionListParamsDtoFromJson(json);
}

@freezed
/// Creates a user-visible session from a primary agent definition.
abstract class SessionCreateParamsDto with _$SessionCreateParamsDto {
  /// Creates session creation parameters.
  const factory SessionCreateParamsDto({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    @Default(SessionMode.normal) SessionMode mode,
    SessionModelSelectionDto? model,
    String? reasoningEffort,
    PermissionMode? permissionMode,
    String? serviceTier,
  }) = _SessionCreateParamsDto;

  /// Decodes session creation parameters.
  factory SessionCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionCreateParamsDtoFromJson(json);
}

@freezed
/// Switches the collaboration mode of one session.
abstract class SessionModeSetParamsDto with _$SessionModeSetParamsDto {
  /// Creates session mode parameters.
  const factory SessionModeSetParamsDto({
    required String sessionId,
    required SessionMode mode,
  }) = _SessionModeSetParamsDto;

  /// Decodes session mode parameters.
  factory SessionModeSetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionModeSetParamsDtoFromJson(json);
}

@freezed
/// Sets or clears the provider and model override of one session.
abstract class SessionModelSetParamsDto with _$SessionModelSetParamsDto {
  /// Creates session model override parameters.
  ///
  /// A null [model] clears the override so the session inherits the model
  /// selection of its agent definition again.
  const factory SessionModelSetParamsDto({
    required String sessionId,
    SessionModelSelectionDto? model,
  }) = _SessionModelSetParamsDto;

  /// Decodes session model override parameters.
  factory SessionModelSetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionModelSetParamsDtoFromJson(json);
}

@freezed
/// Sets or clears the reasoning effort override of one session.
abstract class SessionReasoningEffortSetParamsDto
    with _$SessionReasoningEffortSetParamsDto {
  /// Creates session reasoning effort override parameters.
  ///
  /// A null [reasoningEffort] clears the override so the session inherits the
  /// reasoning effort of its agent definition again.
  const factory SessionReasoningEffortSetParamsDto({
    required String sessionId,
    String? reasoningEffort,
  }) = _SessionReasoningEffortSetParamsDto;

  /// Decodes session reasoning effort override parameters.
  factory SessionReasoningEffortSetParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$SessionReasoningEffortSetParamsDtoFromJson(json);
}

@freezed
/// Sets or clears the permission mode override of one session.
abstract class SessionPermissionModeSetParamsDto
    with _$SessionPermissionModeSetParamsDto {
  /// Creates session permission mode override parameters.
  ///
  /// A null [permissionMode] clears the override so the session inherits the
  /// permission mode of its agent definition again.
  const factory SessionPermissionModeSetParamsDto({
    required String sessionId,
    PermissionMode? permissionMode,
  }) = _SessionPermissionModeSetParamsDto;

  /// Decodes session permission mode override parameters.
  factory SessionPermissionModeSetParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$SessionPermissionModeSetParamsDtoFromJson(json);
}

@freezed
/// Sets or clears the provider service tier of one session.
abstract class SessionServiceTierSetParamsDto
    with _$SessionServiceTierSetParamsDto {
  /// Creates session service tier parameters.
  ///
  /// A null [serviceTier] clears the selection so the provider default applies.
  const factory SessionServiceTierSetParamsDto({
    required String sessionId,
    String? serviceTier,
  }) = _SessionServiceTierSetParamsDto;

  /// Decodes session service tier parameters.
  factory SessionServiceTierSetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionServiceTierSetParamsDtoFromJson(json);
}

@freezed
/// Identifies one Markdown-backed agent definition.
abstract class AgentDefinitionIdParamsDto with _$AgentDefinitionIdParamsDto {
  /// Creates agent definition identifier parameters.
  const factory AgentDefinitionIdParamsDto({required String id}) =
      _AgentDefinitionIdParamsDto;

  /// Decodes agent definition identifier parameters.
  factory AgentDefinitionIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionIdParamsDtoFromJson(json);
}

@freezed
/// Creates one Markdown-backed agent definition.
abstract class AgentDefinitionCreateParamsDto
    with _$AgentDefinitionCreateParamsDto {
  /// Creates agent definition creation parameters.
  const factory AgentDefinitionCreateParamsDto({
    required String id,
    required AgentDefinitionDto definition,
  }) = _AgentDefinitionCreateParamsDto;

  /// Decodes agent definition creation parameters.
  factory AgentDefinitionCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionCreateParamsDtoFromJson(json);
}

@freezed
/// Updates one Markdown-backed agent definition with optimistic concurrency.
abstract class AgentDefinitionUpdateParamsDto
    with _$AgentDefinitionUpdateParamsDto {
  /// Creates agent definition update parameters.
  const factory AgentDefinitionUpdateParamsDto({
    required AgentDefinitionDto definition,
    required String expectedContentHash,
    @Default(false) bool force,
  }) = _AgentDefinitionUpdateParamsDto;

  /// Decodes agent definition update parameters.
  factory AgentDefinitionUpdateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionUpdateParamsDtoFromJson(json);
}

@freezed
/// Validates an agent Markdown document without saving it.
abstract class AgentDefinitionValidateParamsDto
    with _$AgentDefinitionValidateParamsDto {
  /// Creates agent definition validation parameters.
  const factory AgentDefinitionValidateParamsDto({
    required String id,
    required String markdown,
  }) = _AgentDefinitionValidateParamsDto;

  /// Decodes agent definition validation parameters.
  factory AgentDefinitionValidateParamsDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AgentDefinitionValidateParamsDtoFromJson(json);
}

@freezed
/// Scopes a skill request to the global sources plus one workspace.
abstract class SkillScopeParamsDto with _$SkillScopeParamsDto {
  /// Creates skill scope parameters.
  const factory SkillScopeParamsDto({String? workspaceId}) =
      _SkillScopeParamsDto;

  /// Decodes skill scope parameters.
  factory SkillScopeParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SkillScopeParamsDtoFromJson(json);
}

@freezed
/// Identifies one skill within a scope.
abstract class SkillIdParamsDto with _$SkillIdParamsDto {
  /// Creates skill identifier parameters.
  const factory SkillIdParamsDto({required String id, String? workspaceId}) =
      _SkillIdParamsDto;

  /// Decodes skill identifier parameters.
  factory SkillIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SkillIdParamsDtoFromJson(json);
}

@freezed
/// Creates one skill in a writable source.
abstract class SkillCreateParamsDto with _$SkillCreateParamsDto {
  /// Creates skill creation parameters.
  const factory SkillCreateParamsDto({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    String? workspaceId,
  }) = _SkillCreateParamsDto;

  /// Decodes skill creation parameters.
  factory SkillCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SkillCreateParamsDtoFromJson(json);
}

@freezed
/// Updates one skill with optimistic concurrency.
abstract class SkillUpdateParamsDto with _$SkillUpdateParamsDto {
  /// Creates skill update parameters.
  const factory SkillUpdateParamsDto({
    required SkillDto skill,
    required String expectedContentHash,
    String? workspaceId,
    @Default(false) bool force,
  }) = _SkillUpdateParamsDto;

  /// Decodes skill update parameters.
  factory SkillUpdateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SkillUpdateParamsDtoFromJson(json);
}

@freezed
/// Turns one skill on or off.
abstract class SkillSetEnabledParamsDto with _$SkillSetEnabledParamsDto {
  /// Creates skill enablement parameters.
  const factory SkillSetEnabledParamsDto({
    required String id,
    required bool enabled,
    String? workspaceId,
  }) = _SkillSetEnabledParamsDto;

  /// Decodes skill enablement parameters.
  factory SkillSetEnabledParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SkillSetEnabledParamsDtoFromJson(json);
}

@freezed
/// Parameters for connecting a built-in provider with an API key.
abstract class ProviderConnectApiKeyParamsDto
    with _$ProviderConnectApiKeyParamsDto {
  /// Creates API-key connection parameters.
  const factory ProviderConnectApiKeyParamsDto({
    required String definitionId,
    required String apiKey,
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
/// Parameters for creating an advanced custom provider connection.
abstract class ProviderCustomCreateParamsDto
    with _$ProviderCustomCreateParamsDto {
  /// Creates custom provider parameters.
  const factory ProviderCustomCreateParamsDto({
    required String id,
    required CustomProviderConfigDto config,
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
    required String sessionId,
    required String turnId,
    required String prompt,
    @Default(<String>[]) List<String> attachmentIds,
  }) = _TurnStartParamsDto;

  /// Creates a [TurnStartParamsDto].
  factory TurnStartParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TurnStartParamsDtoFromJson(json);
}

@freezed
/// Identifies one session.
abstract class SessionIdParamsDto with _$SessionIdParamsDto {
  /// Creates session identifier parameters.
  const factory SessionIdParamsDto({required String sessionId}) =
      _SessionIdParamsDto;

  /// Decodes session identifier parameters.
  factory SessionIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionIdParamsDtoFromJson(json);
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
/// Announces that the client has a prompt waiting for one session.
abstract class SessionPendingInputParamsDto
    with _$SessionPendingInputParamsDto {
  /// Creates a [SessionPendingInputParamsDto].
  const factory SessionPendingInputParamsDto({required String sessionId}) =
      _SessionPendingInputParamsDto;

  /// Decodes a [SessionPendingInputParamsDto].
  factory SessionPendingInputParamsDto.fromJson(Map<String, dynamic> json) =>
      _$SessionPendingInputParamsDtoFromJson(json);
}

@freezed
/// Answers to every question of one pending [UserQuestionRequestDto].
abstract class UserQuestionAnswerParamsDto with _$UserQuestionAnswerParamsDto {
  /// The UserQuestionAnswerParamsDto public API member.
  const factory UserQuestionAnswerParamsDto({
    required String requestId,
    required List<UserQuestionAnswerDto> answers,
  }) = _UserQuestionAnswerParamsDto;

  /// Creates a [UserQuestionAnswerParamsDto].
  factory UserQuestionAnswerParamsDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionAnswerParamsDtoFromJson(json);
}

@freezed
/// TimelineSubscribeParamsDto defines a public contract.
abstract class TimelineSubscribeParamsDto with _$TimelineSubscribeParamsDto {
  /// The TimelineSubscribeParamsDto public API member.
  const factory TimelineSubscribeParamsDto({
    required String sessionId,
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
/// Result containing one worktree and the lifecycle hooks it ran.
abstract class WorktreeResultDto with _$WorktreeResultDto {
  /// Creates a worktree result.
  const factory WorktreeResultDto({
    required WorktreeDto worktree,
    @Default(<WorktreeHookRunDto>[]) List<WorktreeHookRunDto> hookRuns,
  }) = _WorktreeResultDto;

  /// Decodes a worktree result.
  factory WorktreeResultDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeResultDtoFromJson(json);
}

@freezed
/// Requests the `coder.json` settings of one registered workspace.
abstract class ProjectSettingsGetParamsDto with _$ProjectSettingsGetParamsDto {
  /// Creates project settings read parameters.
  const factory ProjectSettingsGetParamsDto({required String workspaceId}) =
      _ProjectSettingsGetParamsDto;

  /// Decodes project settings read parameters.
  factory ProjectSettingsGetParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsGetParamsDtoFromJson(json);
}

@freezed
/// Replaces the worktree hook section of one workspace's `coder.json`.
abstract class ProjectSettingsSaveParamsDto
    with _$ProjectSettingsSaveParamsDto {
  /// Creates project settings write parameters.
  const factory ProjectSettingsSaveParamsDto({
    required String workspaceId,
    required ProjectSettingsDto settings,
  }) = _ProjectSettingsSaveParamsDto;

  /// Decodes project settings write parameters.
  factory ProjectSettingsSaveParamsDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsSaveParamsDtoFromJson(json);
}

@freezed
/// Result containing project settings and the file backing them.
abstract class ProjectSettingsResultDto with _$ProjectSettingsResultDto {
  /// Creates a project settings result.
  const factory ProjectSettingsResultDto({
    required ProjectSettingsDto settings,
    required String sourcePath,
  }) = _ProjectSettingsResultDto;

  /// Decodes a project settings result.
  factory ProjectSettingsResultDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsResultDtoFromJson(json);
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
/// Returns sessions visible in a worktree.
abstract class SessionListResultDto with _$SessionListResultDto {
  /// Creates a session list result.
  const factory SessionListResultDto({required List<SessionDto> sessions}) =
      _SessionListResultDto;

  /// Decodes a session list result.
  factory SessionListResultDto.fromJson(Map<String, dynamic> json) =>
      _$SessionListResultDtoFromJson(json);
}

@freezed
/// Returns one session.
abstract class SessionResultDto with _$SessionResultDto {
  /// Creates a session result.
  const factory SessionResultDto({required SessionDto session}) =
      _SessionResultDto;

  /// Decodes a session result.
  factory SessionResultDto.fromJson(Map<String, dynamic> json) =>
      _$SessionResultDtoFromJson(json);
}

@freezed
/// Requests live terminals for a worktree.
abstract class TerminalListParamsDto with _$TerminalListParamsDto {
  /// Creates terminal-list parameters.
  const factory TerminalListParamsDto({required String worktreeId}) =
      _TerminalListParamsDto;

  /// Decodes terminal-list parameters.
  factory TerminalListParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalListParamsDtoFromJson(json);
}

@freezed
/// Returns live terminals for a worktree.
abstract class TerminalListResultDto with _$TerminalListResultDto {
  /// Creates a terminal-list result.
  const factory TerminalListResultDto({required List<TerminalDto> terminals}) =
      _TerminalListResultDto;

  /// Decodes a terminal-list result.
  factory TerminalListResultDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalListResultDtoFromJson(json);
}

@freezed
/// Parameters used to start a terminal.
abstract class TerminalCreateParamsDto with _$TerminalCreateParamsDto {
  /// Creates terminal-create parameters.
  const factory TerminalCreateParamsDto({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  }) = _TerminalCreateParamsDto;

  /// Decodes terminal-create parameters.
  factory TerminalCreateParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalCreateParamsDtoFromJson(json);
}

@freezed
/// Identifies one terminal.
abstract class TerminalIdParamsDto with _$TerminalIdParamsDto {
  /// Creates terminal identifier parameters.
  const factory TerminalIdParamsDto({required String terminalId}) =
      _TerminalIdParamsDto;

  /// Decodes terminal identifier parameters.
  factory TerminalIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalIdParamsDtoFromJson(json);
}

@freezed
/// Requests replay output while attaching to a terminal.
abstract class TerminalAttachParamsDto with _$TerminalAttachParamsDto {
  /// Creates terminal-attach parameters.
  const factory TerminalAttachParamsDto({
    required String terminalId,
    @Default(0) int afterSequence,
  }) = _TerminalAttachParamsDto;

  /// Decodes terminal-attach parameters.
  factory TerminalAttachParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalAttachParamsDtoFromJson(json);
}

@freezed
/// Terminal metadata and replay returned by attach.
abstract class TerminalAttachResultDto with _$TerminalAttachResultDto {
  /// Creates a terminal-attach result.
  const factory TerminalAttachResultDto({
    required TerminalDto terminal,
    required List<TerminalOutputDto> replay,
  }) = _TerminalAttachResultDto;

  /// Decodes a terminal-attach result.
  factory TerminalAttachResultDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalAttachResultDtoFromJson(json);
}

@freezed
/// Returns one terminal.
abstract class TerminalResultDto with _$TerminalResultDto {
  /// Creates a terminal result.
  const factory TerminalResultDto({required TerminalDto terminal}) =
      _TerminalResultDto;

  /// Decodes a terminal result.
  factory TerminalResultDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalResultDtoFromJson(json);
}

@freezed
/// Terminal input parameters.
abstract class TerminalWriteParamsDto with _$TerminalWriteParamsDto {
  /// Creates terminal-write parameters.
  const factory TerminalWriteParamsDto({
    required String terminalId,
    required String data,
  }) = _TerminalWriteParamsDto;

  /// Decodes terminal-write parameters.
  factory TerminalWriteParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalWriteParamsDtoFromJson(json);
}

@freezed
/// Terminal resize parameters.
abstract class TerminalResizeParamsDto with _$TerminalResizeParamsDto {
  /// Creates terminal-resize parameters.
  const factory TerminalResizeParamsDto({
    required String terminalId,
    required int columns,
    required int rows,
  }) = _TerminalResizeParamsDto;

  /// Decodes terminal-resize parameters.
  factory TerminalResizeParamsDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalResizeParamsDtoFromJson(json);
}

@freezed
/// Reads or writes the optional daemon-host shell override.
abstract class TerminalShellDto with _$TerminalShellDto {
  /// Creates a terminal-shell payload.
  const factory TerminalShellDto({ShellSpecDto? shell}) = _TerminalShellDto;

  /// Decodes a terminal-shell payload.
  factory TerminalShellDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalShellDtoFromJson(json);
}

@freezed
/// Returns agent definitions and source diagnostics.
abstract class AgentDefinitionListResultDto
    with _$AgentDefinitionListResultDto {
  /// Creates an agent definition list result.
  const factory AgentDefinitionListResultDto({
    required List<AgentDefinitionDto> definitions,
  }) = _AgentDefinitionListResultDto;

  /// Decodes an agent definition list result.
  factory AgentDefinitionListResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionListResultDtoFromJson(json);
}

@freezed
/// Returns one agent definition.
abstract class AgentDefinitionResultDto with _$AgentDefinitionResultDto {
  /// Creates an agent definition result.
  const factory AgentDefinitionResultDto({
    required AgentDefinitionDto definition,
  }) = _AgentDefinitionResultDto;

  /// Decodes an agent definition result.
  factory AgentDefinitionResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionResultDtoFromJson(json);
}

@freezed
/// Scopes an agent tool catalog request to one worktree.
abstract class AgentToolCatalogParamsDto with _$AgentToolCatalogParamsDto {
  /// Creates agent tool catalog parameters.
  const factory AgentToolCatalogParamsDto({String? worktreeId}) =
      _AgentToolCatalogParamsDto;

  /// Decodes agent tool catalog parameters.
  factory AgentToolCatalogParamsDto.fromJson(Map<String, dynamic> json) =>
      _$AgentToolCatalogParamsDtoFromJson(json);
}

@freezed
/// Scopes an MCP server listing to one worktree.
abstract class McpServersParamsDto with _$McpServersParamsDto {
  /// Creates MCP server listing parameters.
  const factory McpServersParamsDto({String? worktreeId}) =
      _McpServersParamsDto;

  /// Decodes MCP server listing parameters.
  factory McpServersParamsDto.fromJson(Map<String, dynamic> json) =>
      _$McpServersParamsDtoFromJson(json);
}

@freezed
/// Returns every configured MCP server and its state.
abstract class McpServersResultDto with _$McpServersResultDto {
  /// Creates an MCP server listing result.
  const factory McpServersResultDto({
    required List<McpServerStateDto> servers,
  }) = _McpServersResultDto;

  /// Decodes an MCP server listing result.
  factory McpServersResultDto.fromJson(Map<String, dynamic> json) =>
      _$McpServersResultDtoFromJson(json);
}

@freezed
/// Carries one MCP server configuration.
abstract class McpServerParamsDto with _$McpServerParamsDto {
  /// Creates MCP server parameters.
  const factory McpServerParamsDto({required McpServerConfigDto server}) =
      _McpServerParamsDto;

  /// Decodes MCP server parameters.
  factory McpServerParamsDto.fromJson(Map<String, dynamic> json) =>
      _$McpServerParamsDtoFromJson(json);
}

@freezed
/// Identifies one configured MCP server.
abstract class McpServerIdParamsDto with _$McpServerIdParamsDto {
  /// Creates MCP server id parameters.
  const factory McpServerIdParamsDto({required String id}) =
      _McpServerIdParamsDto;

  /// Decodes MCP server id parameters.
  factory McpServerIdParamsDto.fromJson(Map<String, dynamic> json) =>
      _$McpServerIdParamsDtoFromJson(json);
}

@freezed
/// Returns one MCP server's state.
abstract class McpServerStateResultDto with _$McpServerStateResultDto {
  /// Creates an MCP server state result.
  const factory McpServerStateResultDto({required McpServerStateDto state}) =
      _McpServerStateResultDto;

  /// Decodes an MCP server state result.
  factory McpServerStateResultDto.fromJson(Map<String, dynamic> json) =>
      _$McpServerStateResultDtoFromJson(json);
}

@freezed
/// Stores one secret an MCP configuration may reference.
abstract class McpSecretParamsDto with _$McpSecretParamsDto {
  /// Creates MCP secret parameters.
  const factory McpSecretParamsDto({
    required String key,
    required String value,
  }) = _McpSecretParamsDto;

  /// Decodes MCP secret parameters.
  factory McpSecretParamsDto.fromJson(Map<String, dynamic> json) =>
      _$McpSecretParamsDtoFromJson(json);
}

@freezed
/// Returns the daemon's agent tool catalog.
abstract class AgentToolCatalogResultDto with _$AgentToolCatalogResultDto {
  /// Creates an agent tool catalog result.
  const factory AgentToolCatalogResultDto({
    required List<AgentToolDefinitionDto> tools,
  }) = _AgentToolCatalogResultDto;

  /// Decodes an agent tool catalog result.
  factory AgentToolCatalogResultDto.fromJson(Map<String, dynamic> json) =>
      _$AgentToolCatalogResultDtoFromJson(json);
}

@freezed
/// Returns every skill visible in one scope.
abstract class SkillListResultDto with _$SkillListResultDto {
  /// Creates a skill list result.
  const factory SkillListResultDto({required List<SkillDto> skills}) =
      _SkillListResultDto;

  /// Decodes a skill list result.
  factory SkillListResultDto.fromJson(Map<String, dynamic> json) =>
      _$SkillListResultDtoFromJson(json);
}

@freezed
/// Returns one skill.
abstract class SkillResultDto with _$SkillResultDto {
  /// Creates a skill result.
  const factory SkillResultDto({required SkillDto skill}) = _SkillResultDto;

  /// Decodes a skill result.
  factory SkillResultDto.fromJson(Map<String, dynamic> json) =>
      _$SkillResultDtoFromJson(json);
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
/// The resolved question returned by an answer call.
abstract class UserQuestionResultDto with _$UserQuestionResultDto {
  /// The UserQuestionResultDto public API member.
  const factory UserQuestionResultDto({
    required UserQuestionRequestDto request,
  }) = _UserQuestionResultDto;

  /// Creates a [UserQuestionResultDto].
  factory UserQuestionResultDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionResultDtoFromJson(json);
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
