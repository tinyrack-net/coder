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

  /// The agent asked the user a question and cannot continue without an answer.
  waitingForInput,

  /// The failed public API member.
  failed,

  /// The closed public API member.
  closed,
}

/// Runtime lifecycle of a daemon-owned interactive terminal.
enum TerminalStatus {
  /// The shell process is accepting input.
  running,

  /// The shell process exited normally or was terminated.
  exited,

  /// The shell could not be started or failed unexpectedly.
  failed,
}

@freezed
/// Executable and arguments used to start an interactive shell.
abstract class ShellSpecDto with _$ShellSpecDto {
  /// Creates a shell specification.
  const factory ShellSpecDto({
    required String executable,
    @Default(<String>[]) List<String> arguments,
  }) = _ShellSpecDto;

  /// Decodes a shell specification.
  factory ShellSpecDto.fromJson(Map<String, dynamic> json) =>
      _$ShellSpecDtoFromJson(json);
}

@freezed
/// Current metadata for a daemon-owned interactive terminal.
abstract class TerminalDto with _$TerminalDto {
  /// Creates terminal metadata.
  const factory TerminalDto({
    required String id,
    required String worktreeId,
    required String title,
    required ShellSpecDto shell,
    required TerminalStatus status,
    required int columns,
    required int rows,
    required int lastSequence,
    int? exitCode,
    String? error,
  }) = _TerminalDto;

  /// Decodes terminal metadata.
  factory TerminalDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalDtoFromJson(json);
}

@freezed
/// One ordered terminal output chunk retained for replay.
abstract class TerminalOutputDto with _$TerminalOutputDto {
  /// Creates an ordered terminal output chunk.
  const factory TerminalOutputDto({
    required String terminalId,
    required int sequence,
    required String data,
  }) = _TerminalOutputDto;

  /// Decodes an ordered terminal output chunk.
  factory TerminalOutputDto.fromJson(Map<String, dynamic> json) =>
      _$TerminalOutputDtoFromJson(json);
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
  /// Requires each manually created session to select a provider and model.
  session,

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

/// Collaboration lifecycle of a spawned subagent session.
///
/// Maintained exclusively by the daemon. `interrupted` is not final: an
/// interrupted subagent stays messageable and can be resumed with a
/// follow-up task.
enum AgentLifecycle {
  /// The session exists but has not started its first turn.
  pendingInit,

  /// A turn is running or blocked on approval/input.
  running,

  /// The last turn was cancelled; the agent remains messageable.
  interrupted,

  /// The last turn completed and the session is idle.
  completed,

  /// The last turn failed.
  errored,
}

/// Kind of an inter-agent mailbox message.
enum InterAgentMessageType {
  /// A plain message between collaborating agents.
  message,

  /// The initial task delivered to a freshly spawned subagent.
  newTask,

  /// A finished subagent's final answer delivered to its parent.
  finalAnswer,
}

/// Values supported by TurnStatus.
enum TurnStatus {
  /// The running public API member.
  running,

  /// The waitingForApproval public API member.
  waitingForApproval,

  /// The turn is blocked on an answer to an agent question.
  waitingForInput,

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

  /// Allows every tool without asking for approval.
  fullAccess,
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

  /// Runs an external MCP tool whose effects the daemon cannot classify.
  dangerous,
}

/// Storage kind of a registered workspace repository.
enum WorkspaceKind {
  /// A Git repository whose checkouts and worktrees can be discovered.
  git,

  /// A regular directory represented by one directory checkout.
  directory,

  /// The user's home directory, provisioned by the daemon itself.
  ///
  /// Sessions that the user started without picking a project live here, so
  /// they still resolve a working directory like every other session. Clients
  /// present them as belonging to no project and keep this workspace out of
  /// every project list.
  home,
}

/// Broad rendering category of an attachment.
enum AttachmentKind {
  /// An image that can be previewed directly by clients.
  image,

  /// Any other file.
  file,
}

@freezed
/// Immutable metadata for bytes owned by the daemon attachment store.
abstract class AttachmentDto with _$AttachmentDto {
  /// Creates attachment metadata.
  const factory AttachmentDto({
    required String id,
    required String fileName,
    required String mimeType,
    required int byteSize,
    required AttachmentKind kind,
    required String sha256,
    required DateTime createdAt,
  }) = _AttachmentDto;

  /// Decodes attachment metadata.
  factory AttachmentDto.fromJson(Map<String, dynamic> json) =>
      _$AttachmentDtoFromJson(json);
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

/// Worktree lifecycle stage that triggers a configured project hook.
enum WorktreeHookPhase {
  /// Runs after a managed worktree checkout is created.
  setup,

  /// Runs before a worktree checkout is removed.
  teardown,
}

/// Supported sources for creating a managed Git worktree.
enum WorktreeCreateMode {
  /// Creates a new branch from a base branch.
  newBranch,

  /// Checks out an existing local branch.
  existingBranch,
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
/// Project-scoped configuration stored in the repository root `coder.json`.
abstract class ProjectSettingsDto with _$ProjectSettingsDto {
  /// Creates project settings.
  const factory ProjectSettingsDto({
    @Default(<String>[]) List<String> setup,
    @Default(<String>[]) List<String> teardown,
    ShellSpecDto? shell,
  }) = _ProjectSettingsDto;

  /// Decodes project settings.
  factory ProjectSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsDtoFromJson(json);
}

@freezed
/// Outcome of one worktree lifecycle hook command.
abstract class WorktreeHookRunDto with _$WorktreeHookRunDto {
  /// Creates a hook run record.
  const factory WorktreeHookRunDto({
    required WorktreeHookPhase phase,
    required String command,
    required int exitCode,
    required String stdout,
    required String stderr,
  }) = _WorktreeHookRunDto;

  /// Decodes a hook run record.
  factory WorktreeHookRunDto.fromJson(Map<String, dynamic> json) =>
      _$WorktreeHookRunDtoFromJson(json);
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
/// One worktree entry matched by a composer file mention search.
abstract class FileMatchDto with _$FileMatchDto {
  /// Creates a file match.
  ///
  /// [relativePath] is POSIX separated and relative to the worktree root so a
  /// mention stays stable when the same worktree is opened from another host.
  const factory FileMatchDto({
    required String relativePath,
    required String absolutePath,
    required String name,
    required bool isDirectory,
    @Default(0) int score,
  }) = _FileMatchDto;

  /// Decodes a file match.
  factory FileMatchDto.fromJson(Map<String, dynamic> json) =>
      _$FileMatchDtoFromJson(json);
}

@freezed
/// One local branch available to a workspace.
abstract class GitBranchDto with _$GitBranchDto {
  /// Creates a Git branch descriptor.
  const factory GitBranchDto({
    required String name,
    required bool current,
    required bool checkedOut,
    @Default(false) bool isRemote,
    @Default(false) bool isDefault,
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
    required List<String> toolIds,
    required List<String> callableAgentIds,
    required String contentHash,
    required String sourcePath,
    PermissionMode? permissionMode,
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
    @Default(false) bool alwaysOn,
  }) = _AgentToolDefinitionDto;

  /// Decodes an agent tool definition.
  factory AgentToolDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$AgentToolDefinitionDtoFromJson(json);
}

/// Which configuration file an MCP server was declared in.
enum McpConfigScope {
  /// The daemon's own `mcp.json`, owned and edited by the user.
  user,

  /// A worktree's `.coder/config.json`, committed with the code it serves.
  project,
}

/// How the daemon reaches one MCP server.
enum McpTransportKind {
  /// Launches a child process and speaks over its stdio.
  stdio,

  /// Posts to a Streamable HTTP endpoint.
  http,
}

/// One MCP server as declared in configuration.
@freezed
abstract class McpServerConfigDto with _$McpServerConfigDto {
  /// Creates an MCP server configuration.
  const factory McpServerConfigDto({
    required String id,
    required McpTransportKind transport,
    @Default(true) bool enabled,
    String? command,
    @Default(<String>[]) List<String> args,
    @Default(<String, String>{}) Map<String, String> env,
    String? cwd,
    String? url,
    @Default(<String, String>{}) Map<String, String> headers,
  }) = _McpServerConfigDto;

  /// Decodes an MCP server configuration.
  factory McpServerConfigDto.fromJson(Map<String, dynamic> json) =>
      _$McpServerConfigDtoFromJson(json);
}

/// Where one MCP server stands in its connection lifecycle.
enum McpServerStatus {
  /// Configured but switched off, so nothing is launched.
  disabled,

  /// Starting up or retrying after a failure.
  connecting,

  /// Handshake complete; its tools are published.
  ready,

  /// Could not connect; the daemon is backing off before retrying.
  failed,
}

/// One tool published by a connected MCP server.
@freezed
abstract class McpToolSummaryDto with _$McpToolSummaryDto {
  /// Creates an MCP tool summary.
  const factory McpToolSummaryDto({
    required String toolId,
    required String name,
    required String description,
    String? title,
  }) = _McpToolSummaryDto;

  /// Decodes an MCP tool summary.
  factory McpToolSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$McpToolSummaryDtoFromJson(json);
}

/// One resource an MCP server publishes.
@freezed
abstract class McpResourceSummaryDto with _$McpResourceSummaryDto {
  /// Creates an MCP resource summary.
  const factory McpResourceSummaryDto({
    required String uri,
    String? name,
    String? title,
    String? description,
    String? mimeType,
    int? sizeBytes,
  }) = _McpResourceSummaryDto;

  /// Decodes an MCP resource summary.
  factory McpResourceSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$McpResourceSummaryDtoFromJson(json);
}

/// One parameterized resource template an MCP server publishes.
@freezed
abstract class McpResourceTemplateSummaryDto
    with _$McpResourceTemplateSummaryDto {
  /// Creates an MCP resource template summary.
  const factory McpResourceTemplateSummaryDto({
    required String uriTemplate,
    String? name,
    String? title,
    String? description,
    String? mimeType,
  }) = _McpResourceTemplateSummaryDto;

  /// Decodes an MCP resource template summary.
  factory McpResourceTemplateSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$McpResourceTemplateSummaryDtoFromJson(json);
}

/// One configured MCP server and its live connection state.
@freezed
abstract class McpServerStateDto with _$McpServerStateDto {
  /// Creates an MCP server state.
  const factory McpServerStateDto({
    required McpServerConfigDto config,
    required McpServerStatus status,
    required McpConfigScope scope,
    required String sourcePath,
    @Default(false) bool shadowed,
    String? protocolVersion,
    String? serverName,
    String? serverVersion,
    @Default(<McpToolSummaryDto>[]) List<McpToolSummaryDto> tools,
    @Default(<McpResourceSummaryDto>[]) List<McpResourceSummaryDto> resources,
    @Default(<McpResourceTemplateSummaryDto>[])
    List<McpResourceTemplateSummaryDto> resourceTemplates,
    String? error,
    @Default(<String>[]) List<String> diagnostics,
    DateTime? lastConnectedAt,
    DateTime? nextRetryAt,
    @Default(0) int attempt,
  }) = _McpServerStateDto;

  /// Decodes an MCP server state.
  factory McpServerStateDto.fromJson(Map<String, dynamic> json) =>
      _$McpServerStateDtoFromJson(json);
}

/// Where one agent command was loaded from, ordered by ascending precedence.
enum AgentCommandSource {
  /// Lives in the shared `~/.agents/commands` tree.
  userHome,

  /// Lives in the daemon configuration directory.
  config,

  /// Lives in `<workspace root>/.agents/commands`.
  project,
}

@freezed
/// One Markdown-defined command the composer offers behind `/`.
abstract class AgentCommandDto with _$AgentCommandDto {
  /// Creates an agent command.
  ///
  /// [body] is the prompt template sent in place of the typed command, and
  /// [argumentHint] documents the trailing arguments the template expects.
  const factory AgentCommandDto({
    required String id,
    required String name,
    required String description,
    required AgentCommandSource source,
    required String sourcePath,
    required String body,
    String? argumentHint,
  }) = _AgentCommandDto;

  /// Decodes an agent command.
  factory AgentCommandDto.fromJson(Map<String, dynamic> json) =>
      _$AgentCommandDtoFromJson(json);
}

/// Where one skill was loaded from, ordered by ascending precedence.
enum SkillSource {
  /// Ships inside the daemon and cannot be edited.
  builtIn,

  /// Lives in the shared `~/.agents/skills` tree.
  userHome,

  /// Lives in the daemon configuration directory.
  config,

  /// Lives in `<workspace root>/.agents/skills`.
  project,
}

@freezed
/// A source diagnostic produced while loading a skill.
abstract class SkillDiagnosticDto with _$SkillDiagnosticDto {
  /// Creates a skill diagnostic.
  const factory SkillDiagnosticDto({
    required String code,
    required String message,
  }) = _SkillDiagnosticDto;

  /// Decodes a skill diagnostic.
  factory SkillDiagnosticDto.fromJson(Map<String, dynamic> json) =>
      _$SkillDiagnosticDtoFromJson(json);
}

@freezed
/// One file bundled next to a skill document.
abstract class SkillResourceDto with _$SkillResourceDto {
  /// Creates a skill resource.
  const factory SkillResourceDto({
    required String path,
    required int sizeBytes,
  }) = _SkillResourceDto;

  /// Decodes a skill resource.
  factory SkillResourceDto.fromJson(Map<String, dynamic> json) =>
      _$SkillResourceDtoFromJson(json);
}

@freezed
/// One Markdown-backed skill offered to agents through the `skill` tool.
abstract class SkillDto with _$SkillDto {
  /// Creates a skill.
  const factory SkillDto({
    required String id,
    required String name,
    required String description,
    required SkillSource source,
    required String sourcePath,
    required String contentHash,
    required String body,
    @Default(<SkillResourceDto>[]) List<SkillResourceDto> resources,
    @Default(true) bool isEnabled,
    @Default(false) bool isMandatory,
    @Default(false) bool isEditable,
    @Default(false) bool isShadowed,
    @Default(false) bool isStale,
    @Default(<SkillDiagnosticDto>[]) List<SkillDiagnosticDto> diagnostics,
  }) = _SkillDto;

  /// Decodes a skill.
  factory SkillDto.fromJson(Map<String, dynamic> json) =>
      _$SkillDtoFromJson(json);
}

/// How a session collaborates: planning first, or working directly.
enum SessionMode {
  /// Explores and proposes a plan instead of doing the work.
  plan,

  /// Carries out the request directly.
  normal,
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
    @Default(SessionMode.normal) SessionMode mode,
    SessionModelSelectionDto? model,

    /// Overrides the reasoning effort of the agent definition; null inherits.
    String? reasoningEffort,

    /// Overrides the permission mode of the agent definition; null inherits.
    PermissionMode? permissionMode,

    /// Provider service tier for this session; null uses the provider default.
    String? serviceTier,
    String? parentSessionId,

    /// Leaf task name of a spawned subagent, e.g. `task_3`; null for roots.
    String? taskName,

    /// Canonical collaboration path, e.g. `/root/task1/task_3`; null for
    /// manually created root sessions (implicitly `/root`).
    String? agentPath,

    /// Root session of the collaboration tree; null for root sessions.
    String? rootSessionId,

    /// Collaboration lifecycle; null for sessions outside a tree.
    AgentLifecycle? lifecycle,
    String? activeTurnId,
    String? lastError,

    /// Tokens the last response reported for the live context window.
    @Default(0) int contextTokens,

    /// Context window of the resolved model; null when it is not advertised.
    int? contextWindow,
  }) = _SessionDto;

  /// Decodes a session descriptor.
  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);
}

@freezed
/// One queued inter-agent mailbox message.
abstract class AgentMailboxMessageDto with _$AgentMailboxMessageDto {
  /// Creates a mailbox message descriptor.
  const factory AgentMailboxMessageDto({
    required String id,

    /// Recipient session.
    required String sessionId,
    required String senderPath,
    required String recipientPath,
    required InterAgentMessageType type,
    required String payload,
    required DateTime createdAt,

    /// Sender session; null when the daemon itself authored the message.
    String? senderSessionId,

    /// When the message was folded into a recipient turn; null while queued.
    DateTime? deliveredAt,
  }) = _AgentMailboxMessageDto;

  /// Decodes a mailbox message descriptor.
  factory AgentMailboxMessageDto.fromJson(Map<String, dynamic> json) =>
      _$AgentMailboxMessageDtoFromJson(json);
}

@freezed
/// ModelCapabilitiesDto defines a public contract.
abstract class ModelCapabilitiesDto with _$ModelCapabilitiesDto {
  /// The ModelCapabilitiesDto public API member.
  const factory ModelCapabilitiesDto({
    @Default(CapabilitySupport.unknown) CapabilitySupport streaming,
    @Default(CapabilitySupport.unknown) CapabilitySupport toolCalling,
    @Default(CapabilitySupport.unknown) CapabilitySupport reasoningEffort,
    @Default(CapabilitySupport.unknown) CapabilitySupport imageInput,
    @Default(CapabilitySupport.unknown) CapabilitySupport fileInput,
    @Default(CapabilitySupport.unknown) CapabilitySupport serviceTier,
    @Default(<String>[]) List<String> supportedReasoningEfforts,
    @Default(<String>[]) List<String> supportedServiceTiers,
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
/// One wire protocol a custom connection may speak.
///
/// Served by the daemon from its registered adapter packages, so the set a
/// client offers grows with the daemon instead of with a client release.
abstract class ProviderWireFormatDto with _$ProviderWireFormatDto {
  /// Creates one selectable wire protocol.
  const factory ProviderWireFormatDto({
    required String id,
    required String label,
  }) = _ProviderWireFormatDto;

  /// Decodes one selectable wire protocol.
  factory ProviderWireFormatDto.fromJson(Map<String, dynamic> json) =>
      _$ProviderWireFormatDtoFromJson(json);
}

@freezed
/// CustomProviderConfigDto contains the advanced custom endpoint settings.
abstract class CustomProviderConfigDto with _$CustomProviderConfigDto {
  /// Creates custom endpoint configuration.
  const factory CustomProviderConfigDto({
    required String name,
    required String baseUrl,
    required String wireFormatId,
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
    required DateTime createdAt,
    required DateTime updatedAt,
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
    // The first entry is what a new custom connection defaults to.
    @Default(<ProviderWireFormatDto>[]) List<ProviderWireFormatDto> wireFormats,
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

/// Lifecycle of one question the agent asked the user.
enum UserQuestionStatus {
  /// The question is waiting for an answer.
  pending,

  /// The user answered every question.
  answered,

  /// The daemon withdrew the question without an answer.
  cancelled,
}

@freezed
/// One fixed choice offered for a [UserQuestionItemDto].
abstract class UserQuestionOptionDto with _$UserQuestionOptionDto {
  /// The UserQuestionOptionDto public API member.
  const factory UserQuestionOptionDto({
    required String label,
    required String description,
  }) = _UserQuestionOptionDto;

  /// Creates a [UserQuestionOptionDto].
  factory UserQuestionOptionDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionOptionDtoFromJson(json);
}

@freezed
/// One multiple-choice question the agent asked.
///
/// [options] holds only the choices the agent wrote; the client always offers a
/// free-form answer alongside them, so the agent never has to invent one.
abstract class UserQuestionItemDto with _$UserQuestionItemDto {
  /// The UserQuestionItemDto public API member.
  const factory UserQuestionItemDto({
    required String id,
    required String header,
    required String question,
    required List<UserQuestionOptionDto> options,
  }) = _UserQuestionItemDto;

  /// Creates a [UserQuestionItemDto].
  factory UserQuestionItemDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionItemDtoFromJson(json);
}

@freezed
/// The user's answer to one [UserQuestionItemDto].
abstract class UserQuestionAnswerDto with _$UserQuestionAnswerDto {
  /// The UserQuestionAnswerDto public API member.
  const factory UserQuestionAnswerDto({
    required String questionId,
    required String answer,
    required bool isFreeForm,
  }) = _UserQuestionAnswerDto;

  /// Creates a [UserQuestionAnswerDto].
  factory UserQuestionAnswerDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionAnswerDtoFromJson(json);
}

@freezed
/// A blocking question the agent asked mid-turn.
abstract class UserQuestionRequestDto with _$UserQuestionRequestDto {
  /// The UserQuestionRequestDto public API member.
  const factory UserQuestionRequestDto({
    required String id,
    required String sessionId,
    required String turnId,
    required String toolCallId,
    required List<UserQuestionItemDto> questions,
    required UserQuestionStatus status,
    required DateTime createdAt,
    @Default(<UserQuestionAnswerDto>[]) List<UserQuestionAnswerDto> answers,
  }) = _UserQuestionRequestDto;

  /// Creates a [UserQuestionRequestDto].
  factory UserQuestionRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UserQuestionRequestDtoFromJson(json);
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
    String? homeDirectory,
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
