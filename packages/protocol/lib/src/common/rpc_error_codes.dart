/// Stable machine-readable failure codes carried by `RpcFailureDto.code`.
///
/// The code, not the message, is the contract: a client maps a code to its own
/// localized text and only falls back to the daemon-supplied message for a code
/// it does not recognize. Codes are therefore append-only — renaming one breaks
/// every client that already translates it.
abstract final class RpcErrorCodes {
  /// A request arrived before the client completed the handshake.
  static const String handshakeRequired = 'handshake_required';

  /// The client speaks a protocol revision this daemon cannot serve.
  static const String protocolMismatch = 'protocol_mismatch';

  /// The requested procedure is not part of this daemon's surface.
  static const String unknownMethod = 'unknown_method';

  /// The request payload did not decode into the procedure's parameters.
  static const String invalidParams = 'invalid_params';

  /// An unexpected daemon-side exception escaped a procedure handler.
  ///
  /// Every occurrence is a defect. The accompanying details carry a trace id
  /// that ties the failure to the daemon log record holding the stack trace.
  static const String internalError = 'internal_error';

  /// The daemon did not answer a request before the client's deadline.
  static const String requestTimeout = 'request_timeout';

  /// The referenced workspace is not registered with this daemon.
  static const String workspaceNotFound = 'workspace_not_found';

  /// The operation requires a Git repository and the workspace is not one.
  static const String workspaceNotGit = 'workspace_not_git';

  /// The referenced worktree is not registered with this daemon.
  static const String worktreeNotFound = 'worktree_not_found';

  /// The requested branch name cannot be used as a Git ref.
  static const String invalidBranchName = 'invalid_branch_name';

  /// A local branch already uses the requested name.
  static const String branchAlreadyExists = 'branch_already_exists';

  /// Another active checkout already occupies the generated worktree path.
  static const String worktreePathInUse = 'worktree_path_in_use';

  /// A Git command exited non-zero; details carry the command and its stderr.
  static const String gitCommandFailed = 'git_command_failed';

  /// The checkout cannot be archived in its current state.
  static const String worktreeArchiveBlocked = 'worktree_archive_blocked';

  /// The daemon owns this workspace and refuses to register or remove it.
  static const String workspaceProtected = 'workspace_protected';

  /// The referenced agent definition no longer exists.
  static const String agentDefinitionNotFound = 'agent_definition_not_found';

  /// The referenced agent definition exists but cannot start a session.
  static const String agentDefinitionUnusable = 'agent_definition_unusable';

  /// A terminal request named a worktree that is not available.
  static const String worktreeUnavailable = 'worktree_unavailable';

  /// The terminal shell process failed to start.
  static const String terminalStartFailed = 'terminal_start_failed';

  /// A project `.tinest/config.json` file could not be parsed.
  static const String invalidProjectSettings = 'invalid_project_settings';

  /// A setting was changed on a session whose turn is still running.
  ///
  /// The mode, the model, and its controls are read when a turn starts, so the
  /// daemon refuses to move them underneath one that is already streaming.
  /// Waiting for the turn to finish, or cancelling it, makes the same change
  /// succeed.
  static const String sessionTurnActive = 'session_turn_active';

  /// Every code this protocol revision defines.
  ///
  /// Clients use this to assert their translation table stays exhaustive.
  static const Set<String> all = <String>{
    handshakeRequired,
    protocolMismatch,
    unknownMethod,
    invalidParams,
    internalError,
    requestTimeout,
    workspaceNotFound,
    workspaceNotGit,
    worktreeNotFound,
    invalidBranchName,
    branchAlreadyExists,
    worktreePathInUse,
    gitCommandFailed,
    worktreeArchiveBlocked,
    workspaceProtected,
    agentDefinitionNotFound,
    agentDefinitionUnusable,
    worktreeUnavailable,
    terminalStartFailed,
    invalidProjectSettings,
    sessionTurnActive,
  };
}
