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

  /// Finds a workspace by its canonical repository root.
  Future<WorkspaceDto?> getByRootPath(String rootPath);

  /// The register public API member.
  Future<WorkspaceDto> register(WorkspaceDto workspace);

  /// Inserts one workspace or replaces the registration it already has.
  ///
  /// Unlike [register] this rewrites name, root path, and kind, which is what
  /// re-provisioning the implicit home workspace on every boot needs.
  Future<WorkspaceDto> upsert(WorkspaceDto workspace);

  /// Removes a workspace registration and its archived worktrees.
  Future<void> unregister(String id);
}

/// Persistence port for concrete checkouts.
abstract interface class WorktreeRepository {
  /// Lists active worktrees, optionally for one workspace.
  Future<List<WorktreeDto>> list({String? workspaceId});

  /// Returns one worktree, including archived records.
  Future<WorktreeDto?> getById(String id);

  /// Finds an active worktree by canonical checkout path.
  Future<WorktreeDto?> getByPath(String path);

  /// Creates or updates a worktree registration.
  Future<WorktreeDto> upsert(WorktreeDto worktree);

  /// Marks a worktree as archived without deleting session history.
  Future<void> archive(String id, DateTime archivedAt);
}

/// Public API exposed by this library.
abstract interface class SessionRepository {
  /// The list public API member.
  Future<List<SessionDto>> list({String? worktreeId});

  /// The getById public API member.
  Future<SessionDto?> getById(String id);

  /// Counts sessions with a turn currently running or awaiting approval.
  Future<int> countActive(String worktreeId);

  /// The create public API member.
  Future<SessionDto> create(SessionDto session);

  /// Switches one session between planning and normal collaboration.
  Future<SessionDto> updateMode(String id, SessionMode mode);

  /// Sets or clears the provider and model override of one session.
  Future<SessionDto> updateModel(String id, SessionModelSelectionDto? model);

  /// Sets or clears the reasoning effort override of one session.
  Future<SessionDto> updateReasoningEffort(String id, String? reasoningEffort);

  /// Sets or clears the permission mode override of one session.
  Future<SessionDto> updatePermissionMode(
    String id,
    PermissionMode? permissionMode,
  );

  /// Sets or clears the provider service tier of one session.
  Future<SessionDto> updateServiceTier(String id, String? serviceTier);

  /// Records what the last response reported for the live context window.
  Future<SessionDto> recordContextTokens(String id, int tokens);

  /// Caches the context window of the model last resolved for this session.
  Future<SessionDto> recordContextWindow(String id, int? window);

  /// The updateStatus public API member.
  Future<SessionDto> updateStatus(
    String id,
    SessionStatus status, {
    String? activeTurnId,
    String? error,
  });

  /// The createTurn public API member.
  Future<bool> createTurn({
    required String id,
    required String sessionId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
  });

  /// The updateTurn public API member.
  Future<void> updateTurn(String id, TurnStatus status, {String? error});

  /// Lists one collaboration tree (root included) ordered by agent path.
  Future<List<SessionDto>> listByRoot(String rootSessionId);

  /// Returns the tree member with [agentPath], or null.
  ///
  /// The tree root itself is addressed by `/root` even though its stored
  /// `agentPath` is null.
  Future<SessionDto?> getByAgentPath(String rootSessionId, String agentPath);

  /// Sets the collaboration lifecycle of one session.
  Future<SessionDto> updateLifecycle(String id, AgentLifecycle lifecycle);
}

/// One queued mailbox message with its delivery trigger flag.
typedef QueuedAgentMail = ({AgentMailboxMessageDto message, bool triggerTurn});

/// Persistence boundary for inter-agent mailbox messages.
abstract interface class AgentMailboxRepository {
  /// Persists one queued message.
  Future<void> enqueue(
    AgentMailboxMessageDto message, {
    required bool triggerTurn,
  });

  /// Returns undelivered messages for [sessionId] oldest first.
  Future<List<QueuedAgentMail>> undeliveredFor(String sessionId);

  /// Marks messages as folded into a recipient turn.
  Future<void> markDelivered(List<String> ids, DateTime deliveredAt);

  /// Whether [sessionId] has an undelivered turn-triggering message.
  Future<bool> hasUndeliveredTrigger(String sessionId);
}

/// Persistence boundary for attachment metadata and turn relationships.
abstract interface class AttachmentRepository {
  /// Persists one completed immutable upload.
  Future<void> insert(AttachmentDto attachment);

  /// Returns one attachment metadata record.
  Future<AttachmentDto?> getById(String id);

  /// Returns records in the same order as [ids], rejecting unknown IDs.
  Future<List<AttachmentDto>> getByIds(List<String> ids);

  /// Whether an attachment is linked to a turn in [sessionId].
  Future<bool> isLinkedToSession(String id, String sessionId);

  /// Links an agent-produced attachment to a turn.
  Future<void> bindAssistant(String turnId, String attachmentId);

  /// Deletes and returns unbound uploads older than [cutoff].
  Future<List<String>> deleteOrphansBefore(DateTime cutoff);
}

/// Public API exposed by this library.
abstract interface class TimelineRepository {
  /// The append public API member.
  Future<TimelineEventDto> append({
    required String sessionId,
    required String type,
    required Map<String, dynamic> data,
    String? turnId,
  });

  /// The after public API member.
  Future<List<TimelineEventDto>> after(String sessionId, int sequence);

  /// The appendProviderItems public API member.
  Future<void> appendProviderItems(
    String sessionId,
    List<ConversationItem> items,
  );

  /// Replays only the live context window of one session.
  ///
  /// Items from a window that `new_context` retired stay on disk for the
  /// timeline but are never sent to a provider again.
  Future<List<ConversationItem>> providerHistory(String sessionId);

  /// Retires the current context window and starts the next one.
  ///
  /// [retain] is appended to the new window, so the assistant item that called
  /// `new_context` keeps the tool results of its own round: both provider APIs
  /// reject a `function_call_output` whose `function_call` is missing.
  Future<void> resetContextWindow(
    String sessionId,
    List<ConversationItem> retain,
  );

  /// The createApproval public API member.
  Future<void> createApproval(ApprovalRequestDto approval);

  /// The resolveApproval public API member.
  Future<ApprovalRequestDto?> resolveApproval(String id, ApprovalStatus status);

  /// Persists a question the agent raised, in its pending state.
  Future<void> createUserQuestion(UserQuestionRequestDto request);

  /// Reads one question, or null when it does not exist.
  Future<UserQuestionRequestDto?> getUserQuestion(String id);

  /// Resolves a pending question, returning null when it is already resolved.
  Future<UserQuestionRequestDto?> answerUserQuestion(
    String id,
    UserQuestionStatus status,
    List<UserQuestionAnswerDto> answers,
  );
}

/// Public API exposed by this library.
abstract interface class ProviderRepository {
  /// Returns all configured provider connections.
  Future<List<ProviderConnectionDto>> listConnections();

  /// Returns one configured provider connection.
  Future<ProviderConnectionDto?> getConnection(String id);

  /// Creates or replaces a configured provider connection.
  Future<ProviderConnectionDto> upsertConnection(
    ProviderConnectionDto connection,
  );

  /// Deletes one configured provider connection.
  Future<void> deleteConnection(String id);

  /// The listModels public API member.
  Future<List<ProviderModelDto>> listModels(String connectionId);

  /// The getModel public API member.
  Future<ProviderModelDto?> getModel(String connectionId, String modelId);

  /// The upsertModel public API member.
  Future<ProviderModelDto> upsertModel(ProviderModelDto model);

  /// Replaces all cached model metadata for one connection.
  Future<void> replaceModels(
    String connectionId,
    Iterable<ProviderModelDto> models,
  );

  /// The deleteModel public API member.
  Future<void> deleteModel(String connectionId, String modelId);
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

  /// Atomically persists the daemon access token.
  Future<void> setDaemonToken(String bearerToken);

  /// Returns the secret credential for one provider connection.
  ProviderCredential? credential(String connectionId);

  /// Atomically stores one provider connection credential.
  Future<void> setCredential(
    String connectionId,
    ProviderCredential credential,
  );

  /// Removes one provider connection credential.
  Future<void> removeCredential(String connectionId);

  /// Secrets referenced from MCP configuration, keyed by reference name.
  Map<String, String> get mcpSecrets;

  /// Atomically stores one MCP secret.
  Future<void> setMcpSecret(String key, String value);

  /// Removes one MCP secret.
  Future<void> removeMcpSecret(String key);
}

/// Secret credential material held only inside the daemon.
sealed class ProviderCredential {
  const ProviderCredential();
}

/// API key credential material.
final class ApiKeyCredential extends ProviderCredential {
  /// Creates API key credential material.
  const ApiKeyCredential(this.key);

  /// Secret provider API key.
  final String key;
}

/// OAuth credential material for a subscription-backed provider.
final class OAuthCredential extends ProviderCredential {
  /// Creates OAuth credential material.
  const OAuthCredential({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.accountId,
  });

  /// Short-lived OAuth access token.
  final String accessToken;

  /// Rotating OAuth refresh token.
  final String refreshToken;

  /// UTC expiration instant for [accessToken].
  final DateTime expiresAt;

  /// ChatGPT account identifier sent to the Codex backend when available.
  final String? accountId;
}
