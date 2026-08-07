import 'dart:convert';

/// The coderProtocolVersion public API member.
const int coderProtocolMajor = 3;

/// Revision of the v3 contract. Major and revision must both match.
const int coderProtocolRevision = 0;

/// Integer retained in persisted server metadata and protocol DTOs.
const int coderProtocolVersion = coderProtocolMajor;

/// Public API exposed by this library.
abstract final class RpcMethod {
  /// The hello public API member.
  static const String hello = 'system.hello';

  /// Returns an atomic workspace and worktree catalog.
  static const String workspaceCatalog = 'workspaces.catalog';

  /// The workspaceRegister public API member.
  static const String workspaceRegister = 'workspaces.register';

  /// Refreshes Git checkout and worktree metadata.
  static const String workspaceRefresh = 'workspaces.refresh';

  /// Removes a workspace registration without deleting its source checkout.
  static const String workspaceUnregister = 'workspaces.unregister';

  /// Searches directories on the daemon host.
  static const String directorySuggest = 'workspaces.suggestDirectories';

  /// Searches worktree files for a composer file mention.
  static const String fileSearch = 'workspaces.searchFiles';

  /// Lists local branches for a Git workspace.
  static const String gitBranchesList = 'workspaces.listBranches';

  /// Creates a managed Git worktree.
  static const String worktreeCreate = 'workspaces.createWorktree';

  /// Returns archive risks without mutating a worktree.
  static const String worktreeArchivePreview = 'workspaces.previewArchive';

  /// Archives a worktree and removes it only when Coder owns it.
  static const String worktreeArchive = 'workspaces.archiveWorktree';

  /// Reads project settings from a workspace root `coder.json`.
  static const String projectSettingsGet = 'workspaces.getProjectSettings';

  /// Writes worktree lifecycle hooks into a workspace root `coder.json`.
  static const String projectSettingsSave = 'workspaces.saveProjectSettings';

  /// Lists Markdown-backed agent definitions.
  static const String agentDefinitionList = 'agents.list';

  /// Returns one Markdown-backed agent definition.
  static const String agentDefinitionGet = 'agents.get';

  /// Creates one Markdown-backed agent definition.
  static const String agentDefinitionCreate = 'agents.create';

  /// Updates one Markdown-backed agent definition.
  static const String agentDefinitionUpdate = 'agents.update';

  /// Archives one custom agent definition.
  static const String agentDefinitionArchive = 'agents.archive';

  /// Restores the built-in Coder definition.
  static const String agentDefinitionReset = 'agents.reset';

  /// Validates Markdown without saving it.
  static const String agentDefinitionValidate = 'agents.validate';

  /// Returns tools available to agent definitions.
  static const String agentToolCatalog = 'agents.listTools';

  /// Lists configured MCP servers and their live connection state.
  static const String mcpServerList = 'mcp.listServers';

  /// Adds one user-scoped MCP server.
  static const String mcpServerAdd = 'mcp.addServer';

  /// Replaces one user-scoped MCP server.
  static const String mcpServerUpdate = 'mcp.updateServer';

  /// Removes one user-scoped MCP server.
  static const String mcpServerRemove = 'mcp.removeServer';

  /// Connects one unsaved MCP server configuration to check it works.
  static const String mcpServerTest = 'mcp.testServer';

  /// Stores one secret an MCP configuration may reference.
  static const String mcpSecretSet = 'mcp.setSecret';

  /// Lists agent-provided slash commands visible in one scope.
  static const String commandList = 'prompts.listCommands';

  /// Lists skills visible in one scope.
  static const String skillList = 'prompts.listSkills';

  /// Returns one skill.
  static const String skillGet = 'prompts.getSkill';

  /// Creates one skill in a writable source.
  static const String skillCreate = 'prompts.createSkill';

  /// Updates one skill with optimistic concurrency.
  static const String skillUpdate = 'prompts.updateSkill';

  /// Archives one skill.
  static const String skillDelete = 'prompts.deleteSkill';

  /// Turns one skill on or off.
  static const String skillSetEnabled = 'prompts.setSkillEnabled';

  /// Lists persisted sessions.
  static const String sessionList = 'sessions.list';

  /// Lists all sessions of one collaboration tree ordered by agent path.
  static const String sessionSubagentList = 'sessions.listAgents';

  /// Creates a persisted session.
  static const String sessionCreate = 'sessions.create';

  /// Atomically patches model, mode, reasoning, permission, and service tier.
  static const String sessionUpdateSettings = 'sessions.updateSettings';

  /// Lists live terminals in one worktree.
  static const String terminalList = 'terminals.list';

  /// Creates a daemon-owned terminal.
  static const String terminalCreate = 'terminals.create';

  /// Attaches to a terminal and returns replay output.
  static const String terminalAttach = 'terminals.attach';

  /// Writes terminal input.
  static const String terminalWrite = 'terminals.write';

  /// Resizes a terminal PTY.
  static const String terminalResize = 'terminals.resize';

  /// Terminates a terminal PTY.
  static const String terminalTerminate = 'terminals.terminate';

  /// Reads the daemon host's default terminal shell.
  static const String terminalShellGet = 'terminals.getDefaultShell';

  /// Replaces or clears the daemon host's default terminal shell.
  static const String terminalShellSet = 'terminals.setDefaultShell';

  /// Reads the daemon-global permission mode used by inheriting agents.
  static const String permissionDefaultModeGet = 'agents.getDefaultPermission';

  /// Replaces the daemon-global permission mode.
  static const String permissionDefaultModeSet = 'agents.setDefaultPermission';

  /// Returns immutable built-in provider definitions.
  static const String providerCatalog = 'providers.catalog';

  /// Returns configured provider connections.
  static const String providerConnectionsList = 'providers.listConnections';

  /// Connects a built-in provider with an API key.
  static const String providerConnectApiKey = 'providers.connectApiKey';

  /// Connects a built-in provider that requires no credential.
  static const String providerConnectNone = 'providers.connectNone';

  /// Starts an OAuth authorization flow.
  static const String providerAuthStart = 'providers.startAuth';

  /// Returns one OAuth authorization attempt.
  static const String providerAuthStatus = 'providers.getAuth';

  /// Cancels one OAuth authorization attempt.
  static const String providerAuthCancel = 'providers.cancelAuth';

  /// Disconnects a configured provider connection.
  static const String providerDisconnect = 'providers.disconnect';

  /// Explicitly refreshes model metadata from the catalog source.
  static const String providerCatalogRefresh = 'providers.refreshCatalog';

  /// The providerModelsList public API member.
  static const String providerModelsList = 'providers.listModels';

  /// Reads the daemon-global default model used when nothing else resolves.
  static const String providerDefaultModelGet = 'providers.getDefaultModel';

  /// Replaces or clears the daemon-global default model.
  static const String providerDefaultModelSet = 'providers.setDefaultModel';

  /// Creates an advanced custom connection speaking a registered wire format.
  static const String providerCustomCreate = 'providers.createCustom';

  /// Updates an advanced custom connection.
  static const String providerCustomUpdate = 'providers.updateCustom';

  /// Deletes an advanced custom connection.
  static const String providerCustomDelete = 'providers.deleteCustom';

  /// The turnStart public API member.
  static const String turnStart = 'sessions.startTurn';

  /// The turnCancel public API member.
  static const String turnCancel = 'sessions.cancelTurn';

  /// Summarizes a session's context window and starts the next one.
  static const String sessionCompact = 'sessions.compact';

  /// The approvalResolve public API member.
  static const String approvalResolve = 'sessions.resolveApproval';

  /// Answers a pending agent question and unblocks its turn.
  static const String userQuestionAnswer = 'sessions.answerQuestion';

  /// Reports that the client has queued input for a session.
  static const String sessionPendingInput = 'sessions.notePendingInput';

  /// The timelineSubscribe public API member.
  static const String timelineSubscribe = 'sessions.subscribeTimeline';
}

/// Public API exposed by this library.
abstract final class RpcNotification {
  /// The timelineEvent public API member.
  static const String timelineEvent = 'sessions.timelineEvent';

  /// Reports one session lifecycle change.
  static const String sessionUpdated = 'sessions.updated';

  /// Streams one ordered terminal output chunk.
  static const String terminalOutput = 'terminals.output';

  /// Reports terminal lifecycle or size changes.
  static const String terminalUpdated = 'terminals.updated';

  /// Reports a Markdown agent catalog change.
  static const String agentDefinitionsChanged = 'agents.changed';

  /// Reports a skill catalog change.
  static const String skillsChanged = 'prompts.skillsChanged';

  /// Reports an agent command catalog change.
  static const String commandsChanged = 'prompts.commandsChanged';

  /// The approvalRequested public API member.
  static const String approvalRequested = 'sessions.approvalRequested';

  /// Reports that the agent is blocked on a question for the user.
  static const String userQuestionRequested = 'sessions.questionRequested';

  /// Reports OAuth authorization attempt state changes.
  static const String providerAuthUpdated = 'providers.authUpdated';

  /// Reports an MCP server connection or configuration change.
  static const String mcpServersChanged = 'mcp.changed';
}

/// ProtocolException defines a public contract.
class ProtocolException implements Exception {
  /// Creates a [ProtocolException].
  const ProtocolException(this.message);

  /// The message public API member.
  final String message;

  @override
  String toString() => 'ProtocolException: $message';
}

/// WireEnvelope defines a public contract.
class WireEnvelope {
  /// Creates a [WireEnvelope].
  const WireEnvelope({
    required this.type,
    required this.payload,
    this.version = coderProtocolVersion,
    this.requestId,
  });

  /// Creates a [WireEnvelope].
  factory WireEnvelope.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final type = json['type'];
    final payload = json['payload'];
    final requestId = json['requestId'];
    if (version is! int || type is! String || payload is! Map) {
      throw const ProtocolException('Invalid wire envelope.');
    }
    if (requestId != null && requestId is! String) {
      throw const ProtocolException('requestId must be a string.');
    }
    return WireEnvelope(
      version: version,
      type: type,
      requestId: requestId as String?,
      payload: Map<String, dynamic>.from(payload),
    );
  }

  /// Creates a [WireEnvelope].
  factory WireEnvelope.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const ProtocolException('Wire message must be a JSON object.');
    }
    return WireEnvelope.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// The version public API member.
  final int version;

  /// The type public API member.
  final String type;

  /// The requestId public API member.
  final String? requestId;

  /// The payload public API member.
  final Map<String, dynamic> payload;

  /// The toJson public API member.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'type': type,
    'requestId': ?requestId,
    'payload': payload,
  };

  /// The encode public API member.
  String encode() => jsonEncode(toJson());
}
