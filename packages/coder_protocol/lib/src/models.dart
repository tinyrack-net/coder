import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// Runtime lifecycle of an AI session.
enum SessionStatus {
  /// The initializing public API member.
  initializing,

  /// The idle public API member.
  idle,

  /// The running public API member.
  running,

  /// The waitingForApproval public API member.
  waitingForApproval,

  /// The parent session is waiting for a delegated child session.
  waitingForSubagent,

  /// The failed public API member.
  failed,

  /// The closed public API member.
  closed,
}

/// Determines how an agent definition can be used.
enum AgentMode {
  /// May be selected when a user creates a session.
  primary,

  /// May only be invoked by an allowlisted primary agent.
  subagent,
}

/// Determines how an agent definition resolves its provider and model.
enum AgentModelSource {
  /// Resolves the daemon's current default connection and model for each turn.
  daemonDefault,

  /// Uses one explicit provider connection and model.
  fixed,
}

/// Describes whether a session was created by a user or an agent.
enum SessionOrigin {
  /// The user explicitly created the session.
  manual,

  /// A primary agent delegated work to this child session.
  delegated,
}

/// Values supported by TurnStatus.
enum TurnStatus {
  /// The running public API member.
  running,

  /// The waitingForApproval public API member.
  waitingForApproval,

  /// The completed public API member.
  completed,

  /// The failed public API member.
  failed,

  /// The interrupted public API member.
  interrupted,

  /// The cancelled public API member.
  cancelled,
}

/// Values supported by PermissionMode.
enum PermissionMode {
  /// Allows read-only tools and rejects mutations.
  readOnly,

  /// Automatically reads and asks before every mutation.
  ask,

  /// Allows workspace file writes but asks before commands.
  workspaceWrite,
}

/// Values supported by ApprovalStatus.
enum ApprovalStatus {
  /// The approval has not been resolved.
  pending,

  /// The user approved the invocation.
  approved,

  /// The user denied the invocation.
  denied,

  /// The daemon cancelled the approval.
  cancelled,
}

/// Values supported by ToolRisk.
enum ToolRisk {
  /// Reads workspace state without mutating it.
  read,

  /// Writes workspace files.
  write,

  /// Starts a child process.
  command,
}

/// Storage kind of a registered workspace repository.
enum WorkspaceKind {
  /// A Git repository whose checkouts and worktrees can be discovered.
  git,

  /// A regular directory represented by one directory checkout.
  directory,
}

/// Filesystem placement backing an agent session.
enum WorktreeKind {
  /// The workspace's original checkout.
  checkout,

  /// A Git worktree created and owned by Tinyrack Coder.
  managed,

  /// A Git worktree discovered on disk but not owned by Tinyrack Coder.
  external,

  /// The sole checkout for a non-Git directory workspace.
  directory,
}

/// Supported sources for creating a managed Git worktree.
enum WorktreeCreateMode {
  /// Creates a new branch from a base branch.
  newBranch,

  /// Checks out an existing local branch.
  existingBranch,
}

/// API formats supported by custom OpenAI-compatible connections.
enum ProviderApiFormat {
  /// Uses the OpenAI Responses API.
  responses,

  /// Uses the OpenAI-compatible Chat Completions API.
  chatCompletions,
}

/// Credential families supported by a provider connection.
enum ProviderAuthKind {
  /// A provider-issued API key.
  apiKey,

  /// An OAuth access and refresh token pair.
  oauth,

  /// No credential is required.
  none,
}

/// User-visible authorization flows supported by a provider.
enum ProviderAuthFlow {
  /// Direct API key entry.
  apiKey,

  /// Browser authorization with a loopback callback.
  oauthBrowser,

  /// Headless device-code authorization.
  oauthDevice,

  /// No authorization interaction.
  none,
}

/// The location from which a connected provider obtains credentials.
enum ProviderCredentialOrigin {
  /// Encrypted or permission-restricted local credential storage.
  stored,

  /// The daemon process environment.
  environment,

  /// Locally stored OAuth access and refresh tokens.
  oauth,

  /// No credential exists or is required.
  none,
}

/// Lifecycle state of a provider connection.
enum ProviderConnectionStatus {
  /// Initial discovery is in progress.
  connecting,

  /// Credential and model discovery succeeded.
  connected,

  /// Runtime is usable with bundled metadata after discovery failed.
  degraded,

  /// Connection setup failed.
  error,

  /// OAuth refresh failed and interactive sign-in is required.
  reauthRequired,

  /// The user explicitly disconnected the provider.
  disconnected,
}

/// Lifecycle state of an OAuth authorization attempt.
enum ProviderAuthAttemptStatus {
  /// Authorization is being initialized.
  pending,

  /// User interaction is required.
  awaitingUser,

  /// Authorization succeeded and tokens are being exchanged.
  exchanging,

  /// Credential storage and provider connection succeeded.
  succeeded,

  /// Authorization failed.
  failed,

  /// The user cancelled authorization.
  cancelled,

  /// Authorization was not completed before expiration.
  expired,
}

/// Source of the provider catalog currently used by the daemon.
enum ProviderCatalogSource {
  /// The verified snapshot bundled with the daemon.
  bundled,

  /// A user-requested catalog refresh completed.
  refreshed,
}

/// Values supported by ProviderModelSource.
enum ProviderModelSource {
  /// The model came from the catalog bundled with the application.
  bundled,

  /// The model came from an explicitly refreshed catalog.
  refreshed,

  /// The model came from the provider models endpoint.
  discovered,

  /// The user configured the model explicitly.
  manual,
}

/// Values supported by CapabilitySupport.
enum CapabilitySupport {
  /// Support has not been established.
  unknown,

  /// The capability is supported.
  supported,

  /// The capability is not supported.
  unsupported,
}

/// Values supported by CapabilitySource.
enum CapabilitySource {
  /// No capability source is available.
  unknown,

  /// The bundled catalog supplied the capability.
  bundled,

  /// An explicitly refreshed catalog supplied the capability.
  refreshed,

  /// A diagnostic request supplied the capability.
  diagnostic,

  /// The user supplied the capability.
  manual,
}

/// Values supported by DiagnosticStatus.
enum DiagnosticStatus {
  /// The model has not been diagnosed.
  unknown,

  /// The diagnostic completed successfully.
  verified,

  /// The diagnostic failed.
  failed,
}

@freezed
/// WorkspaceDto defines a public contract.
abstract class WorkspaceDto with _$WorkspaceDto {
  /// The WorkspaceDto public API member.
  const factory WorkspaceDto({
    required String id,
    required String name,
    required String rootPath,
    required WorkspaceKind kind,
    required DateTime createdAt,
  }) = _WorkspaceDto;

  /// Creates a [WorkspaceDto].
  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);
}

@freezed
/// A checkout or Git worktree belonging to a registered workspace.
abstract class WorktreeDto with _$WorktreeDto {
  /// Creates a worktree descriptor.
  const factory WorktreeDto({
    required String id,
    required String workspaceId,
    required String name,
    required String path,
    required WorktreeKind kind,
    required bool isCoderOwned,
    required DateTime createdAt,
    String? branch,
    String? head,
    DateTime? archivedAt,
  }) = _WorktreeDto;

  /// Decodes a worktree descriptor.
  factory WorktreeDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeDtoFromJson(json);
}

@freezed
/// Atomic workspace and worktree catalog owned by one daemon.
abstract class WorkspaceCatalogDto with _$WorkspaceCatalogDto {
  /// Creates a workspace catalog.
  const factory WorkspaceCatalogDto({
    required List<WorkspaceDto> workspaces,
    required List<WorktreeDto> worktrees,
  }) = _WorkspaceCatalogDto;

  /// Decodes a workspace catalog.
  factory WorkspaceCatalogDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceCatalogDtoFromJson(json);
}

@freezed
/// Risk information that must be shown before archiving a worktree.
abstract class WorktreeArchivePreviewDto with _$WorktreeArchivePreviewDto {
  /// Creates an archive preview.
  const factory WorktreeArchivePreviewDto({
    required String worktreeId,
    required bool dirty,
    required int unpushedCommitCount,
    required int runningSessionCount,
    required bool removesDirectory,
  }) = _WorktreeArchivePreviewDto;

  /// Decodes an archive preview.
  factory WorktreeArchivePreviewDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeArchivePreviewDtoFromJson(json);
}

@freezed
/// One daemon-side directory search result.
abstract class DirectorySuggestionDto with _$DirectorySuggestionDto {
  /// Creates a directory suggestion.
  const factory DirectorySuggestionDto({
    required String path,
    required String name,
  }) = _DirectorySuggestionDto;

  /// Decodes a directory suggestion.
  factory DirectorySuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$DirectorySuggestionDtoFromJson(json);
}

@freezed
/// One local branch available to a workspace.
abstract class GitBranchDto with _$GitBranchDto {
  /// Creates a Git branch descriptor.
  const factory GitBranchDto({
    required String name,
    required bool current,
    required bool checkedOut,
  }) = _GitBranchDto;

  /// Decodes a Git branch descriptor.
  factory GitBranchDto.fromJson(Map<String, dynamic> json) =>
      _$GitBranchDtoFromJson(json);
}

@freezed
/// Provider and model selection stored in an agent Markdown file.
abstract class AgentModelSelectionDto with _$AgentModelSelectionDto {
  /// Creates an agent model selection.
  const factory AgentModelSelectionDto({
    required AgentModelSource source,
    String? providerConnectionId,
    String? modelId,
  }) = _AgentModelSelectionDto;

  /// Decodes an agent model selection.
  factory AgentModelSelectionDto.fromJson(Map<String, dynamic> json) =>
      _$AgentModelSelectionDtoFromJson(json);
}

@freezed
/// A source diagnostic produced while loading an agent Markdown file.
abstract class AgentDefinitionDiagnosticDto
    with _$AgentDefinitionDiagnosticDto {
  /// Creates an agent definition diagnostic.
  const factory AgentDefinitionDiagnosticDto({
    required String code,
    required String message,
    int? line,
    int? column,
  }) = _AgentDefinitionDiagnosticDto;

  /// Decodes an agent definition diagnostic.
  factory AgentDefinitionDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionDiagnosticDtoFromJson(json);
}

@freezed
/// Markdown-backed configuration for a primary agent or subagent.
abstract class AgentDefinitionDto with _$AgentDefinitionDto {
  /// Creates an agent definition.
  const factory AgentDefinitionDto({
    required String id,
    required String name,
    required String description,
    required AgentMode mode,
    required bool promptEnabled,
    required String systemPrompt,
    required AgentModelSelectionDto model,
    required String reasoningEffort,
    required PermissionMode permissionMode,
    required List<String> toolIds,
    required List<String> callableAgentIds,
    required String contentHash,
    required String sourcePath,
    @Default(false) bool isBuiltIn,
    @Default(false) bool isArchived,
    @Default(false) bool isStale,
    @Default(<AgentDefinitionDiagnosticDto>[])
    List<AgentDefinitionDiagnosticDto> diagnostics,
  }) = _AgentDefinitionDto;

  /// Decodes an agent definition.
  factory AgentDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$AgentDefinitionDtoFromJson(json);
}

@freezed
/// One tool that can be enabled by an agent definition.
abstract class AgentToolDefinitionDto with _$AgentToolDefinitionDto {
  /// Creates an agent tool definition.
  const factory AgentToolDefinitionDto({
    required String id,
    required String name,
    required String description,
    required ToolRisk risk,
    @Default(true) bool available,
  }) = _AgentToolDefinitionDto;

  /// Decodes an agent tool definition.
  factory AgentToolDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$AgentToolDefinitionDtoFromJson(json);
}

@freezed
/// Explicit provider and model chosen for one session.
///
/// A session without this override inherits the model selection of its agent
/// definition. Both fields are required so a half-specified override cannot be
/// represented.
abstract class SessionModelSelectionDto with _$SessionModelSelectionDto {
  /// Creates a session model selection.
  const factory SessionModelSelectionDto({
    required String providerConnectionId,
    required String modelId,
  }) = _SessionModelSelectionDto;

  /// Decodes a session model selection.
  factory SessionModelSelectionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionModelSelectionDtoFromJson(json);
}

@freezed
/// Persistent conversation session using a Markdown agent definition.
abstract class SessionDto with _$SessionDto {
  /// Creates a session descriptor.
  const factory SessionDto({
    required String id,
    required String worktreeId,
    required String title,
    required String agentDefinitionId,
    required SessionOrigin origin,
    required SessionStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    SessionModelSelectionDto? model,
    String? parentSessionId,
    String? activeTurnId,
    String? lastError,
  }) = _SessionDto;

  /// Decodes a session descriptor.
  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);
}

@freezed
/// ModelCapabilitiesDto defines a public contract.
abstract class ModelCapabilitiesDto with _$ModelCapabilitiesDto {
  /// The ModelCapabilitiesDto public API member.
  const factory ModelCapabilitiesDto({
    @Default(CapabilitySupport.unknown) CapabilitySupport streaming,
    @Default(CapabilitySupport.unknown) CapabilitySupport toolCalling,
    @Default(CapabilitySupport.unknown) CapabilitySupport reasoningEffort,
    @Default(<String>[]) List<String> supportedReasoningEfforts,
    @Default(CapabilitySource.unknown) CapabilitySource source,
  }) = _ModelCapabilitiesDto;

  /// Creates a [ModelCapabilitiesDto].
  factory ModelCapabilitiesDto.fromJson(Map<String, dynamic> json) =>
      _$ModelCapabilitiesDtoFromJson(json);
}

@freezed
/// Provider model token prices in USD per million tokens.
abstract class ModelPricingDto with _$ModelPricingDto {
  /// Creates optional model pricing metadata.
  const factory ModelPricingDto({
    double? input,
    double? output,
    double? cacheRead,
    double? cacheWrite,
  }) = _ModelPricingDto;

  /// Decodes model pricing metadata.
  factory ModelPricingDto.fromJson(Map<String, dynamic> json) =>
      _$ModelPricingDtoFromJson(json);
}

@freezed
/// Provider model token limits.
abstract class ModelLimitsDto with _$ModelLimitsDto {
  /// Creates optional model limit metadata.
  const factory ModelLimitsDto({int? context, int? input, int? output}) =
      _ModelLimitsDto;

  /// Decodes model limit metadata.
  factory ModelLimitsDto.fromJson(Map<String, dynamic> json) =>
      _$ModelLimitsDtoFromJson(json);
}

@freezed
/// ProviderAuthMethodDto describes one simple way to connect a provider.
abstract class ProviderAuthMethodDto with _$ProviderAuthMethodDto {
  /// Creates a provider authorization method.
  const factory ProviderAuthMethodDto({
    required String id,
    required String label,
    required ProviderAuthKind kind,
    required ProviderAuthFlow flow,
    @Default(false) bool experimental,
  }) = _ProviderAuthMethodDto;

  /// Decodes a provider authorization method.
  factory ProviderAuthMethodDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthMethodDtoFromJson(json);
}

@freezed
/// ProviderDefinitionDto is immutable built-in provider metadata.
abstract class ProviderDefinitionDto with _$ProviderDefinitionDto {
  /// Creates an immutable provider definition.
  const factory ProviderDefinitionDto({
    required String id,
    required String name,
    required String description,
    required List<ProviderAuthMethodDto> authMethods,
    @Default(<String>[]) List<String> recommendedModelIds,
    @Default(false) bool local,
    @Default(false) bool experimental,
    String? documentationUrl,
  }) = _ProviderDefinitionDto;

  /// Decodes immutable provider metadata.
  factory ProviderDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDefinitionDtoFromJson(json);
}

@freezed
/// CustomProviderConfigDto contains the advanced custom endpoint settings.
abstract class CustomProviderConfigDto with _$CustomProviderConfigDto {
  /// Creates custom OpenAI-compatible endpoint configuration.
  const factory CustomProviderConfigDto({
    required String name,
    required String baseUrl,
    required ProviderApiFormat apiFormat,
    required bool authenticationRequired,
    @Default(false) bool strictToolSchema,
    @Default(<String>[]) List<String> manualModelIds,
  }) = _CustomProviderConfigDto;

  /// Decodes custom endpoint configuration.
  factory CustomProviderConfigDto.fromJson(Map<String, dynamic> json) =>
      _$CustomProviderConfigDtoFromJson(json);
}

@freezed
/// ProviderConnectionDto is the user-owned state of a provider connection.
abstract class ProviderConnectionDto with _$ProviderConnectionDto {
  /// Creates provider connection state.
  const factory ProviderConnectionDto({
    required String id,
    required String definitionId,
    required String displayName,
    required ProviderConnectionStatus status,
    required ProviderAuthKind authKind,
    required ProviderCredentialOrigin credentialOrigin,
    required bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? defaultModelId,
    String? error,
    CustomProviderConfigDto? customConfig,
  }) = _ProviderConnectionDto;

  /// Decodes provider connection state.
  factory ProviderConnectionDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderConnectionDtoFromJson(json);
}

@freezed
/// ProviderAuthAttemptDto describes a pending or completed OAuth flow.
abstract class ProviderAuthAttemptDto with _$ProviderAuthAttemptDto {
  /// Creates an OAuth authorization attempt.
  const factory ProviderAuthAttemptDto({
    required String id,
    required String definitionId,
    required String methodId,
    required ProviderAuthAttemptStatus status,
    String? authorizationUrl,
    String? userCode,
    String? instructions,
    DateTime? expiresAt,
    String? error,
  }) = _ProviderAuthAttemptDto;

  /// Decodes an OAuth authorization attempt.
  factory ProviderAuthAttemptDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderAuthAttemptDtoFromJson(json);
}

@freezed
/// ProviderModelDto defines a public contract.
abstract class ProviderModelDto with _$ProviderModelDto {
  /// The ProviderModelDto public API member.
  const factory ProviderModelDto({
    required String connectionId,
    required String id,
    required String label,
    required ProviderModelSource source,
    required ModelCapabilitiesDto capabilities,
    ModelPricingDto? pricing,
    ModelLimitsDto? limits,
    @Default(DiagnosticStatus.unknown) DiagnosticStatus diagnosticStatus,
    DateTime? verifiedAt,
    String? diagnosticError,
  }) = _ProviderModelDto;

  /// Creates a [ProviderModelDto].
  factory ProviderModelDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderModelDtoFromJson(json);
}

@freezed
/// ProviderCatalogDto defines a public contract.
abstract class ProviderCatalogDto with _$ProviderCatalogDto {
  /// The ProviderCatalogDto public API member.
  const factory ProviderCatalogDto({
    required List<ProviderDefinitionDto> definitions,
    required ProviderCatalogSource source,
    required DateTime updatedAt,
  }) = _ProviderCatalogDto;

  /// Creates a [ProviderCatalogDto].
  factory ProviderCatalogDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderCatalogDtoFromJson(json);
}

@freezed
/// ProviderDiagnosticDto defines a public contract.
abstract class ProviderDiagnosticDto with _$ProviderDiagnosticDto {
  /// The ProviderDiagnosticDto public API member.
  const factory ProviderDiagnosticDto({
    required String connectionId,
    required String model,
    required DiagnosticStatus status,
    required bool endpointReachable,
    required bool streaming,
    required bool toolCalling,
    required DateTime checkedAt,
    String? error,
  }) = _ProviderDiagnosticDto;

  /// Creates a [ProviderDiagnosticDto].
  factory ProviderDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderDiagnosticDtoFromJson(json);
}

@freezed
/// TimelineEventDto defines a public contract.
abstract class TimelineEventDto with _$TimelineEventDto {
  /// The TimelineEventDto public API member.
  const factory TimelineEventDto({
    required String sessionId,
    required int sequence,
    required String type,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    String? turnId,
  }) = _TimelineEventDto;

  /// Creates a [TimelineEventDto].
  factory TimelineEventDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventDtoFromJson(json);
}

@freezed
/// ApprovalRequestDto defines a public contract.
abstract class ApprovalRequestDto with _$ApprovalRequestDto {
  /// The ApprovalRequestDto public API member.
  const factory ApprovalRequestDto({
    required String id,
    required String sessionId,
    required String turnId,
    required String toolCallId,
    required String toolName,
    required ToolRisk risk,
    required Map<String, dynamic> arguments,
    required ApprovalStatus status,
    required DateTime createdAt,
    String? preview,
  }) = _ApprovalRequestDto;

  /// Creates a [ApprovalRequestDto].
  factory ApprovalRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ApprovalRequestDtoFromJson(json);
}

@freezed
/// ServerInfoDto defines a public contract.
abstract class ServerInfoDto with _$ServerInfoDto {
  /// The ServerInfoDto public API member.
  const factory ServerInfoDto({
    required String serverId,
    required String version,
    required int protocolVersion,
    required Map<String, bool> features,
  }) = _ServerInfoDto;

  /// Creates a [ServerInfoDto].
  factory ServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ServerInfoDtoFromJson(json);
}

@freezed
/// RpcErrorDto defines a public contract.
abstract class RpcErrorDto with _$RpcErrorDto {
  /// The RpcErrorDto public API member.
  const factory RpcErrorDto({
    required String code,
    required String message,
    required bool retryable,
    Map<String, dynamic>? details,
  }) = _RpcErrorDto;

  /// Creates a [RpcErrorDto].
  factory RpcErrorDto.fromJson(Map<String, dynamic> json) =>
      _$RpcErrorDtoFromJson(json);
}
