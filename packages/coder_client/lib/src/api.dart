import 'package:coder_protocol/coder_protocol.dart';

/// Authenticated streaming attachment download.
final class AttachmentDownload {
  /// Creates a download stream and response metadata.
  const AttachmentDownload({
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.bytes,
  });

  /// Server-provided display filename.
  final String fileName;

  /// Validated response media type.
  final String mimeType;

  /// Exact response length.
  final int byteSize;

  /// Payload bytes.
  final Stream<List<int>> bytes;
}

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

/// Reports ordered output from a terminal.
final class TerminalOutputClientEvent extends ClientEvent {
  /// Creates a terminal output event.
  const TerminalOutputClientEvent(this.output);

  /// Ordered output received from the daemon.
  final TerminalOutputDto output;
}

/// Reports terminal metadata changes.
final class TerminalUpdatedClientEvent extends ClientEvent {
  /// Creates a terminal metadata event.
  const TerminalUpdatedClientEvent(this.terminal);

  /// Updated daemon-owned terminal.
  final TerminalDto terminal;
}

/// Signals that the daemon's Markdown agent files changed.
final class AgentDefinitionsChangedClientEvent extends ClientEvent {
  /// Creates a catalog invalidation event.
  const AgentDefinitionsChangedClientEvent();
}

/// Signals that an MCP server's configuration or connection changed.
final class McpServersChangedClientEvent extends ClientEvent {
  /// Creates an MCP server invalidation event.
  const McpServersChangedClientEvent();
}

/// Signals that the daemon's skill catalog changed.
final class SkillsChangedClientEvent extends ClientEvent {
  /// Creates a catalog invalidation event.
  const SkillsChangedClientEvent();
}

/// Signals that the daemon's agent command catalog changed.
final class CommandsChangedClientEvent extends ClientEvent {
  /// Creates a command catalog invalidation event.
  const CommandsChangedClientEvent();
}

/// ApprovalRequestedClientEvent defines a public contract.
final class ApprovalRequestedClientEvent extends ClientEvent {
  /// Creates a [ApprovalRequestedClientEvent].
  const ApprovalRequestedClientEvent(this.approval);

  /// The approval public API member.
  final ApprovalRequestDto approval;
}

/// Reports that the agent is blocked on a question for the user.
final class UserQuestionRequestedClientEvent extends ClientEvent {
  /// Creates a [UserQuestionRequestedClientEvent].
  const UserQuestionRequestedClientEvent(this.request);

  /// The pending question.
  final UserQuestionRequestDto request;
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

  /// Searches one worktree for files a composer mention can reference.
  ///
  /// An empty [query] returns the head of the index rather than no results.
  Future<FileSearchResultDto> searchFiles({
    required String worktreeId,
    required String query,
    int limit = 50,
  });

  /// Lists local branches in one Git repository.
  Future<List<GitBranchDto>> listGitBranches(String workspaceId);

  /// Reads worktree lifecycle hooks from a repository root `coder.json`.
  Future<ProjectSettingsResultDto> getProjectSettings(String workspaceId);

  /// Writes worktree lifecycle hooks into a repository root `coder.json`.
  Future<ProjectSettingsResultDto> saveProjectSettings(
    String workspaceId,
    ProjectSettingsDto settings,
  );

  /// Creates a managed Git worktree and runs its configured setup hooks.
  Future<WorktreeResultDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  });

  /// Previews archive safety conditions.
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(String worktreeId);

  /// Archives a worktree after running its configured teardown hooks.
  Future<WorktreeResultDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  });

  /// The listSessions public API member.
  Future<List<SessionDto>> listSessions({String? worktreeId});

  /// Lists the collaboration tree containing [sessionId], root first,
  /// ordered by agent path.
  Future<List<SessionDto>> listSubagents(String sessionId);

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
    String? reasoningEffort,
    PermissionMode? permissionMode,
    String? serviceTier,
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

  /// Sets or clears the reasoning effort override of one session.
  ///
  /// Passing a null [reasoningEffort] restores inheritance from the agent
  /// definition.
  Future<SessionDto> updateSessionReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  );

  /// Sets or clears the permission mode override of one session.
  ///
  /// Passing a null [permissionMode] restores inheritance from the agent
  /// definition.
  Future<SessionDto> updateSessionPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  );

  /// Sets or clears the provider service tier of one session.
  ///
  /// Passing a null [serviceTier] restores the provider default tier.
  Future<SessionDto> updateSessionServiceTier(
    String sessionId,
    String? serviceTier,
  );

  /// Lists live terminals for a worktree.
  Future<List<TerminalDto>> listTerminals(String worktreeId);

  /// Creates and starts a terminal.
  Future<TerminalDto> createTerminal({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  });

  /// Attaches to a terminal and replays output after a sequence.
  Future<TerminalAttachResultDto> attachTerminal(
    String terminalId, {
    int afterSequence = 0,
  });

  /// Writes user input to a terminal.
  Future<void> writeTerminal(String terminalId, String data);

  /// Changes terminal character-cell dimensions.
  Future<TerminalDto> resizeTerminal(
    String terminalId, {
    required int columns,
    required int rows,
  });

  /// Terminates a terminal and its shell process.
  Future<void> terminateTerminal(String terminalId);

  /// Reads the daemon host shell override, or null for the OS default.
  Future<ShellSpecDto?> getTerminalShell();

  /// Replaces or clears the daemon host shell override.
  Future<void> setTerminalShell(ShellSpecDto? shell);

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

  /// Lists tools available to agent definitions.
  ///
  /// A worktree adds the tools its own MCP servers publish, so a caller with
  /// no worktree in hand sees only the daemon-wide set.
  Future<List<AgentToolDefinitionDto>> listAgentTools({String? worktreeId});

  /// Lists configured MCP servers and their live connection state.
  Future<List<McpServerStateDto>> listMcpServers({String? worktreeId});

  /// Adds one user-scoped MCP server.
  Future<McpServerStateDto> addMcpServer(McpServerConfigDto server);

  /// Replaces one user-scoped MCP server.
  Future<McpServerStateDto> updateMcpServer(McpServerConfigDto server);

  /// Removes one user-scoped MCP server.
  Future<void> removeMcpServer(String id);

  /// Connects an unsaved configuration to check it works.
  Future<McpServerStateDto> testMcpServer(McpServerConfigDto server);

  /// Stores one secret an MCP configuration may reference.
  Future<void> setMcpSecret(String key, String value);

  /// Lists agent commands from the global sources plus one workspace.
  Future<List<AgentCommandDto>> listCommands({String? workspaceId});

  /// Lists skills from the global sources plus one optional workspace.
  Future<List<SkillDto>> listSkills({String? workspaceId});

  /// Returns one skill visible in the requested scope.
  Future<SkillDto> getSkill(String id, {String? workspaceId});

  /// Creates one skill in a writable source.
  Future<SkillDto> createSkill({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    String? workspaceId,
  });

  /// Updates one skill using optimistic concurrency.
  Future<SkillDto> updateSkill(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    String? workspaceId,
  });

  /// Archives one skill.
  Future<void> deleteSkill(String id, {String? workspaceId});

  /// Turns one skill on or off.
  Future<SkillDto> setSkillEnabled(
    String id, {
    required bool enabled,
    String? workspaceId,
  });

  /// The listProviderCatalog public API member.
  Future<ProviderCatalogDto> listProviderCatalog();

  /// Returns configured provider connections.
  Future<List<ProviderConnectionDto>> listProviderConnections();

  /// Connects a built-in provider with an API key.
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey,
  );

  /// Connects a local built-in provider without authentication.
  Future<ProviderConnectionDto> connectProviderNone(String definitionId);

  /// Starts an interactive provider authorization flow.
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId,
  );

  /// Returns the latest state of an authorization attempt.
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId);

  /// Cancels a pending authorization attempt.
  Future<void> cancelProviderAuth(String attemptId);

  /// Disconnects a provider while preserving historical agent data.
  Future<void> disconnectProvider(String connectionId);

  /// Explicitly refreshes public provider and model metadata.
  Future<ProviderCatalogDto> refreshProviderCatalog();

  /// The listProviderModels public API member.
  Future<List<ProviderModelDto>> listProviderModels(String connectionId);

  /// Reads the daemon-global default model, or null when unset.
  ///
  /// A null result means the daemon resolves the first usable provider model.
  Future<SessionModelSelectionDto?> getDefaultModel();

  /// Replaces or clears the daemon-global default model.
  Future<void> setDefaultModel(SessionModelSelectionDto? model);

  /// Creates an advanced custom provider connection.
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
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
    List<String> attachmentIds = const <String>[],
  });

  /// Streams one file into the daemon-owned attachment store.
  Future<AttachmentDto> uploadAttachment({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> bytes,
  });

  /// Opens an authenticated attachment download stream.
  Future<AttachmentDownload> downloadAttachment(String id);

  /// The cancelTurn public API member.
  Future<void> cancelTurn(String sessionId);

  /// The resolveApproval public API member.
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  });

  /// Tells the daemon a prompt is queued, so a sleeping agent wakes early.
  ///
  /// Best-effort: a lost notice only means a longer wait.
  Future<void> notePendingInput(String sessionId);

  /// Answers a pending agent question and lets its turn continue.
  Future<UserQuestionRequestDto> answerUserQuestion({
    required String requestId,
    required List<UserQuestionAnswerDto> answers,
  });

  /// The subscribeTimeline public API member.
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  });

  /// The close public API member.
  Future<void> close();
}
