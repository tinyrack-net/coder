import 'dart:convert';

/// The coderProtocolVersion public API member.
const int coderProtocolVersion = 21;

/// Public API exposed by this library.
abstract final class RpcMethod {
  /// The hello public API member.
  static const String hello = 'hello';

  /// Returns an atomic workspace and worktree catalog.
  static const String workspaceCatalog = 'workspace.catalog';

  /// The workspaceRegister public API member.
  static const String workspaceRegister = 'workspace.register';

  /// Refreshes Git checkout and worktree metadata.
  static const String workspaceRefresh = 'workspace.refresh';

  /// Removes a workspace registration without deleting its source checkout.
  static const String workspaceUnregister = 'workspace.unregister';

  /// Searches directories on the daemon host.
  static const String directorySuggest = 'directory.suggest';

  /// Searches worktree files for a composer file mention.
  static const String fileSearch = 'file.search';

  /// Lists local branches for a Git workspace.
  static const String gitBranchesList = 'git.branches.list';

  /// Creates a managed Git worktree.
  static const String worktreeCreate = 'worktree.create';

  /// Returns archive risks without mutating a worktree.
  static const String worktreeArchivePreview = 'worktree.archive.preview';

  /// Archives a worktree and removes it only when Coder owns it.
  static const String worktreeArchive = 'worktree.archive';

  /// Reads project settings from a workspace root `coder.json`.
  static const String projectSettingsGet = 'project.settings.get';

  /// Writes worktree lifecycle hooks into a workspace root `coder.json`.
  static const String projectSettingsSave = 'project.settings.save';

  /// Lists Markdown-backed agent definitions.
  static const String agentDefinitionList = 'agentDefinition.list';

  /// Returns one Markdown-backed agent definition.
  static const String agentDefinitionGet = 'agentDefinition.get';

  /// Creates one Markdown-backed agent definition.
  static const String agentDefinitionCreate = 'agentDefinition.create';

  /// Updates one Markdown-backed agent definition.
  static const String agentDefinitionUpdate = 'agentDefinition.update';

  /// Archives one custom agent definition.
  static const String agentDefinitionArchive = 'agentDefinition.archive';

  /// Restores the built-in Coder definition.
  static const String agentDefinitionReset = 'agentDefinition.reset';

  /// Validates Markdown without saving it.
  static const String agentDefinitionValidate = 'agentDefinition.validate';

  /// Returns tools available to agent definitions.
  static const String agentToolCatalog = 'agentTool.catalog';

  /// Lists configured MCP servers and their live connection state.
  static const String mcpServerList = 'mcp.servers.list';

  /// Adds one user-scoped MCP server.
  static const String mcpServerAdd = 'mcp.servers.add';

  /// Replaces one user-scoped MCP server.
  static const String mcpServerUpdate = 'mcp.servers.update';

  /// Removes one user-scoped MCP server.
  static const String mcpServerRemove = 'mcp.servers.remove';

  /// Connects one unsaved MCP server configuration to check it works.
  static const String mcpServerTest = 'mcp.servers.test';

  /// Stores one secret an MCP configuration may reference.
  static const String mcpSecretSet = 'mcp.servers.secret.set';

  /// Lists agent-provided slash commands visible in one scope.
  static const String commandList = 'command.list';

  /// Lists skills visible in one scope.
  static const String skillList = 'skill.list';

  /// Returns one skill.
  static const String skillGet = 'skill.get';

  /// Creates one skill in a writable source.
  static const String skillCreate = 'skill.create';

  /// Updates one skill with optimistic concurrency.
  static const String skillUpdate = 'skill.update';

  /// Archives one skill.
  static const String skillDelete = 'skill.delete';

  /// Turns one skill on or off.
  static const String skillSetEnabled = 'skill.setEnabled';

  /// Lists persisted sessions.
  static const String sessionList = 'session.list';

  /// Lists all sessions of one collaboration tree ordered by agent path.
  static const String sessionSubagentList = 'session.subagents.list';

  /// Creates a persisted session.
  static const String sessionCreate = 'session.create';

  /// Sets or clears the per-session provider and model override.
  static const String sessionModelSet = 'session.model.set';

  /// Switches one session between planning and normal collaboration.
  static const String sessionModeSet = 'session.mode.set';

  /// Sets or clears the per-session reasoning effort override.
  static const String sessionReasoningEffortSet = 'session.reasoningEffort.set';

  /// Sets or clears the per-session permission mode override.
  static const String sessionPermissionModeSet = 'session.permissionMode.set';

  /// Sets or clears the per-session provider service tier.
  static const String sessionServiceTierSet = 'session.serviceTier.set';

  /// Lists live terminals in one worktree.
  static const String terminalList = 'terminal.list';

  /// Creates a daemon-owned terminal.
  static const String terminalCreate = 'terminal.create';

  /// Attaches to a terminal and returns replay output.
  static const String terminalAttach = 'terminal.attach';

  /// Writes terminal input.
  static const String terminalWrite = 'terminal.write';

  /// Resizes a terminal PTY.
  static const String terminalResize = 'terminal.resize';

  /// Terminates a terminal PTY.
  static const String terminalTerminate = 'terminal.terminate';

  /// Reads the daemon host's default terminal shell.
  static const String terminalShellGet = 'terminal.shell.get';

  /// Replaces or clears the daemon host's default terminal shell.
  static const String terminalShellSet = 'terminal.shell.set';

  /// Reads the daemon-global permission mode used by inheriting agents.
  static const String permissionDefaultModeGet = 'permission.defaultMode.get';

  /// Replaces the daemon-global permission mode.
  static const String permissionDefaultModeSet = 'permission.defaultMode.set';

  /// Returns immutable built-in provider definitions.
  static const String providerCatalog = 'provider.catalog';

  /// Returns configured provider connections.
  static const String providerConnectionsList = 'provider.connections.list';

  /// Connects a built-in provider with an API key.
  static const String providerConnectApiKey = 'provider.connect.apiKey';

  /// Connects a built-in provider that requires no credential.
  static const String providerConnectNone = 'provider.connect.none';

  /// Starts an OAuth authorization flow.
  static const String providerAuthStart = 'provider.auth.start';

  /// Returns one OAuth authorization attempt.
  static const String providerAuthStatus = 'provider.auth.status';

  /// Cancels one OAuth authorization attempt.
  static const String providerAuthCancel = 'provider.auth.cancel';

  /// Disconnects a configured provider connection.
  static const String providerDisconnect = 'provider.disconnect';

  /// Explicitly refreshes model metadata from the catalog source.
  static const String providerCatalogRefresh = 'provider.catalog.refresh';

  /// The providerModelsList public API member.
  static const String providerModelsList = 'provider.models.list';

  /// Reads the daemon-global default model used when nothing else resolves.
  static const String providerDefaultModelGet = 'provider.defaultModel.get';

  /// Replaces or clears the daemon-global default model.
  static const String providerDefaultModelSet = 'provider.defaultModel.set';

  /// Creates an advanced custom OpenAI-compatible connection.
  static const String providerCustomCreate = 'provider.custom.create';

  /// Updates an advanced custom OpenAI-compatible connection.
  static const String providerCustomUpdate = 'provider.custom.update';

  /// Deletes an advanced custom OpenAI-compatible connection.
  static const String providerCustomDelete = 'provider.custom.delete';

  /// The turnStart public API member.
  static const String turnStart = 'turn.start';

  /// The turnCancel public API member.
  static const String turnCancel = 'turn.cancel';

  /// Summarizes a session's context window and starts the next one.
  static const String sessionCompact = 'session.compact';

  /// The approvalResolve public API member.
  static const String approvalResolve = 'approval.resolve';

  /// Answers a pending agent question and unblocks its turn.
  static const String userQuestionAnswer = 'userQuestion.answer';

  /// Reports that the client has queued input for a session.
  static const String sessionPendingInput = 'session.pendingInput';

  /// The timelineSubscribe public API member.
  static const String timelineSubscribe = 'timeline.subscribe';
}

/// Public API exposed by this library.
abstract final class RpcNotification {
  /// The timelineEvent public API member.
  static const String timelineEvent = 'timeline.event';

  /// Reports one session lifecycle change.
  static const String sessionUpdated = 'session.updated';

  /// Streams one ordered terminal output chunk.
  static const String terminalOutput = 'terminal.output';

  /// Reports terminal lifecycle or size changes.
  static const String terminalUpdated = 'terminal.updated';

  /// Reports a Markdown agent catalog change.
  static const String agentDefinitionsChanged = 'agentDefinitions.changed';

  /// Reports a skill catalog change.
  static const String skillsChanged = 'skills.changed';

  /// Reports an agent command catalog change.
  static const String commandsChanged = 'commands.changed';

  /// The approvalRequested public API member.
  static const String approvalRequested = 'approval.requested';

  /// Reports that the agent is blocked on a question for the user.
  static const String userQuestionRequested = 'userQuestion.requested';

  /// Reports OAuth authorization attempt state changes.
  static const String providerAuthUpdated = 'provider.auth.updated';

  /// Reports an MCP server connection or configuration change.
  static const String mcpServersChanged = 'mcp.servers.changed';
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
