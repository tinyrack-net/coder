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

/// Workspace operations exposed by the v4 client.
abstract interface class WorkspacesApi {
  /// Returns repositories and active checkouts atomically.
  Future<WorkspaceCatalogDto> getWorkspaceCatalog();

  /// Registers a repository checkout.
  Future<WorkspaceRegisterResultDto> registerWorkspace({
    required String workspaceId,
    required String checkoutId,
    required String rootPath,
    required String name,
  });

  /// Refreshes Git metadata and checkout registrations.
  Future<WorkspaceCatalogDto> refreshWorkspace(String workspaceId);

  /// Removes a repository registration.
  Future<void> unregisterWorkspace(String workspaceId);

  /// Searches directories on the daemon machine.
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query, {
    int limit = 30,
  });

  /// Searches a worktree for files.
  Future<FileSearchResultDto> searchFiles({
    required String worktreeId,
    required String query,
    int limit = 50,
  });

  /// Lists local branches in a repository.
  Future<List<GitBranchDto>> listGitBranches(String workspaceId);

  /// Reads project settings.
  Future<ProjectSettingsResultDto> getProjectSettings(String workspaceId);

  /// Saves project settings.
  Future<ProjectSettingsResultDto> saveProjectSettings(
    String workspaceId,
    ProjectSettingsDto settings,
  );

  /// Creates a managed worktree.
  Future<WorktreeResultDto> createWorktree({
    required String id,
    required String workspaceId,
    required WorktreeCreateMode mode,
    required String branchName,
    String? baseBranch,
  });

  /// Previews archive safety conditions.
  Future<WorktreeArchivePreviewDto> previewWorktreeArchive(String worktreeId);

  /// Archives a managed worktree.
  Future<WorktreeResultDto> archiveWorktree(
    String worktreeId, {
    bool force = false,
  });
}

/// Session operations and updates exposed by the v4 client.
abstract interface class SessionsApi {
  /// Session lifecycle updates.
  Stream<SessionDto> get sessionUpdates;

  /// Ordered timeline events.
  Stream<TimelineEventDto> get timelineEvents;

  /// Approval requests awaiting the user.
  Stream<ApprovalRequestDto> get approvalRequests;

  /// Questions awaiting the user.
  Stream<UserQuestionRequestDto> get questionRequests;

  /// Lists persisted sessions.
  Future<List<SessionDto>> listSessions({String? worktreeId});

  /// Lists one collaboration tree.
  Future<List<SessionDto>> listSubagents(String sessionId);

  /// Creates a session.
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

  /// Atomically updates nullable session execution settings.
  Future<SessionDto> updateSettings(
    String sessionId,
    SessionSettingsPatchDto patch,
  );

  /// Starts a turn.
  Future<void> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
  });

  /// Cancels a running turn.
  Future<void> cancelTurn(String sessionId);

  /// Compacts a session context.
  Future<void> compactSession(String sessionId);

  /// Resolves a pending approval.
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  });

  /// Reports queued user input.
  Future<void> notePendingInput(String sessionId);

  /// Answers a pending user question.
  Future<UserQuestionRequestDto> answerUserQuestion({
    required String requestId,
    required List<UserQuestionAnswerDto> answers,
  });

  /// Subscribes to a session timeline.
  Future<List<TimelineEventDto>> subscribeTimeline(
    String sessionId, {
    int afterSequence = 0,
  });
}

/// Agent-definition operations exposed by the v4 client.
abstract interface class AgentsApi {
  /// Emits whenever the agent-definition catalog changes.
  Stream<void> get definitionChanges;

  /// Lists agent definitions.
  Future<List<AgentDefinitionDto>> listAgentDefinitions();

  /// Reads an agent definition.
  Future<AgentDefinitionDto> getAgentDefinition(String id);

  /// Creates an agent definition.
  Future<AgentDefinitionDto> createAgentDefinition(
    String id,
    AgentDefinitionDto definition,
  );

  /// Updates an agent definition.
  Future<AgentDefinitionDto> updateAgentDefinition(
    AgentDefinitionDto definition, {
    required String expectedContentHash,
    bool force = false,
  });

  /// Archives an agent definition.
  Future<void> archiveAgentDefinition(String id);

  /// Resets a built-in agent definition.
  Future<AgentDefinitionDto> resetAgentDefinition(String id);

  /// Validates an agent definition without saving it.
  Future<AgentDefinitionDto> validateAgentDefinition(
    String id,
    String markdown,
  );

  /// Lists tools available to an agent.
  Future<List<AgentToolDefinitionDto>> listAgentTools({String? worktreeId});

  /// Reads the daemon default permission mode.
  Future<PermissionSettingsDto> getDefaultPermissionMode();

  /// Replaces the daemon default permission mode.
  Future<PermissionSettingsDto> setDefaultPermissionMode(
    PermissionMode permissionMode,
  );
}

/// Prompt, command, and skill operations exposed by the v4 client.
abstract interface class PromptsApi {
  /// Emits whenever the skill catalog changes.
  Stream<void> get skillChanges;

  /// Emits whenever the command catalog changes.
  Stream<void> get commandChanges;

  /// Lists commands visible in a workspace.
  Future<List<AgentCommandDto>> listCommands({String? workspaceId});

  /// Lists skills visible in a workspace.
  Future<List<SkillDto>> listSkills({String? workspaceId});

  /// Reads a skill.
  Future<SkillDto> getSkill(String id, {String? workspaceId});

  /// Creates a skill.
  Future<SkillDto> createSkill({
    required String id,
    required SkillSource source,
    required String name,
    required String description,
    required String body,
    String? workspaceId,
  });

  /// Updates a skill.
  Future<SkillDto> updateSkill(
    SkillDto skill, {
    required String expectedContentHash,
    bool force = false,
    String? workspaceId,
  });

  /// Archives a skill.
  Future<void> deleteSkill(String id, {String? workspaceId});

  /// Changes whether a skill is enabled.
  Future<SkillDto> setSkillEnabled(
    String id, {
    required bool enabled,
    String? workspaceId,
  });
}

/// Provider operations exposed by the v4 client.
abstract interface class ProvidersApi {
  /// Provider authorization updates.
  Stream<ProviderAuthAttemptDto> get authUpdates;

  /// Lists built-in provider definitions.
  Future<ProviderCatalogDto> listProviderCatalog();

  /// Lists configured provider connections.
  Future<List<ProviderConnectionDto>> listProviderConnections();

  /// Connects a provider with an API key.
  Future<ProviderConnectionDto> connectProviderApiKey(
    String definitionId,
    String apiKey,
  );

  /// Connects a provider without credentials.
  Future<ProviderConnectionDto> connectProviderNone(String definitionId);

  /// Starts provider authorization.
  Future<ProviderAuthAttemptDto> startProviderAuth(
    String definitionId,
    String methodId,
  );

  /// Reads provider authorization state.
  Future<ProviderAuthAttemptDto> providerAuthStatus(String attemptId);

  /// Cancels provider authorization.
  Future<void> cancelProviderAuth(String attemptId);

  /// Disconnects a provider.
  Future<void> disconnectProvider(String connectionId);

  /// Refreshes provider metadata.
  Future<ProviderCatalogDto> refreshProviderCatalog();

  /// Lists models for a connection.
  Future<List<ProviderModelDto>> listProviderModels(String connectionId);

  /// Reads the default model.
  Future<SessionModelSelectionDto?> getDefaultModel();

  /// Replaces the default model.
  Future<void> setDefaultModel(SessionModelSelectionDto? model);

  /// Creates a custom provider.
  Future<ProviderConnectionDto> createCustomProvider(
    String id,
    CustomProviderConfigDto config, {
    String? apiKey,
  });

  /// Updates a custom provider.
  Future<ProviderConnectionDto> updateCustomProvider(
    String connectionId,
    CustomProviderConfigDto config, {
    String? apiKey,
  });

  /// Deletes a custom provider.
  Future<void> deleteCustomProvider(String connectionId);
}

/// MCP operations exposed by the v4 client.
abstract interface class McpApi {
  /// Emits whenever MCP server state changes.
  Stream<void> get serverChanges;

  /// Lists MCP server state.
  Future<List<McpServerStateDto>> listMcpServers({String? worktreeId});

  /// Adds an MCP server.
  Future<McpServerStateDto> addMcpServer(McpServerConfigDto server);

  /// Updates an MCP server.
  Future<McpServerStateDto> updateMcpServer(McpServerConfigDto server);

  /// Removes an MCP server.
  Future<void> removeMcpServer(String id);

  /// Tests an MCP server configuration.
  Future<McpServerStateDto> testMcpServer(McpServerConfigDto server);

  /// Stores an MCP secret.
  Future<void> setMcpSecret(String key, String value);
}

/// Terminal operations and output exposed by the v4 client.
abstract interface class TerminalsApi {
  /// Ordered terminal output chunks.
  Stream<TerminalOutputDto> get output;

  /// Terminal lifecycle and size updates.
  Stream<TerminalDto> get terminalUpdates;

  /// Lists live terminals.
  Future<List<TerminalDto>> listTerminals(String worktreeId);

  /// Creates a terminal.
  Future<TerminalDto> createTerminal({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  });

  /// Attaches to a terminal.
  Future<TerminalAttachResultDto> attachTerminal(
    String terminalId, {
    int afterSequence = 0,
  });

  /// Writes terminal input.
  Future<void> writeTerminal(String terminalId, String data);

  /// Resizes a terminal.
  Future<TerminalDto> resizeTerminal(
    String terminalId, {
    required int columns,
    required int rows,
  });

  /// Terminates a terminal.
  Future<void> terminateTerminal(String terminalId);

  /// Reads the terminal shell override.
  Future<ShellSpecDto?> getTerminalShell();

  /// Replaces the terminal shell override.
  Future<void> setTerminalShell(ShellSpecDto? shell);
}

/// Attachment transfer operations exposed by the v4 client.
abstract interface class AttachmentsApi {
  /// Uploads an attachment.
  Future<AttachmentDto> uploadAttachment({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> bytes,
  });

  /// Downloads an attachment.
  Future<AttachmentDownload> downloadAttachment(String id);
}

/// Root client API for connection lifecycle and feature-scoped operations.
abstract interface class CoderApi {
  /// Workspace-scoped operations.
  WorkspacesApi get workspaces;

  /// Session-scoped operations.
  SessionsApi get sessions;

  /// Agent-definition operations.
  AgentsApi get agents;

  /// Prompt, command, and skill operations.
  PromptsApi get prompts;

  /// Provider operations.
  ProvidersApi get providers;

  /// MCP server operations.
  McpApi get mcp;

  /// Terminal operations.
  TerminalsApi get terminals;

  /// Attachment operations.
  AttachmentsApi get attachments;

  /// Connection-state changes.
  Stream<ClientConnectionState> get states;

  /// Metadata returned by the v4 handshake.
  ServerInfoDto get serverInfo;

  /// Closes the connection and all feature streams.
  Future<void> close();
}
