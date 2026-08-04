import 'dart:convert';

/// The coderProtocolVersion public API member.
const int coderProtocolVersion = 13;

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

  /// Creates a persisted session.
  static const String sessionCreate = 'session.create';

  /// Sets or clears the per-session provider and model override.
  static const String sessionModelSet = 'session.model.set';

  /// Switches one session between planning and normal collaboration.
  static const String sessionModeSet = 'session.mode.set';

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

  /// The approvalResolve public API member.
  static const String approvalResolve = 'approval.resolve';

  /// The timelineSubscribe public API member.
  static const String timelineSubscribe = 'timeline.subscribe';
}

/// Public API exposed by this library.
abstract final class RpcNotification {
  /// The timelineEvent public API member.
  static const String timelineEvent = 'timeline.event';

  /// Reports one session lifecycle change.
  static const String sessionUpdated = 'session.updated';

  /// Reports a Markdown agent catalog change.
  static const String agentDefinitionsChanged = 'agentDefinitions.changed';

  /// Reports a skill catalog change.
  static const String skillsChanged = 'skills.changed';

  /// The approvalRequested public API member.
  static const String approvalRequested = 'approval.requested';

  /// Reports OAuth authorization attempt state changes.
  static const String providerAuthUpdated = 'provider.auth.updated';
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
