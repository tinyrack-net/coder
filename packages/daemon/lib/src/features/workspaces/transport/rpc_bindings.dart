import 'package:daemon/src/features/workspaces/infrastructure/workspace_service.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Builds the workspace feature's complete v5 RPC surface.
List<RpcBindingDescriptor> workspaceRpcBindings({
  required WorkspaceCatalogPort workspaces,
  required WorktreeLifecyclePort worktrees,
}) => <RpcBindingDescriptor>[
  RpcBinding(workspacesCatalogProcedure, (_, _) async {
    return WorkspaceCatalogResultDto(catalog: await workspaces.catalog());
  }),
  RpcBinding(workspacesRegisterProcedure, (request, _) {
    return _typedFailures(() => workspaces.register(request));
  }),
  RpcBinding(workspacesRefreshProcedure, (request, _) async {
    return WorkspaceCatalogResultDto(
      catalog: await _typedFailures(
        () => workspaces.refresh(request.workspaceId),
      ),
    );
  }),
  RpcBinding(workspacesUnregisterProcedure, (request, _) async {
    await _typedFailures(() => workspaces.unregister(request.workspaceId));
    return const WorkspaceUnregisterResultDto(unregistered: true);
  }),
  RpcBinding(workspacesSuggestDirectoriesProcedure, (request, _) async {
    return DirectorySuggestResultDto(
      suggestions: await workspaces.suggestDirectories(
        request.query,
        request.limit,
      ),
    );
  }),
  RpcBinding(workspacesSearchFilesProcedure, (request, _) {
    return workspaces.searchFiles(request);
  }),
  RpcBinding(workspacesListBranchesProcedure, (request, _) async {
    return GitBranchesListResultDto(
      branches: await _typedFailures(
        () => worktrees.listBranches(request.workspaceId),
      ),
    );
  }),
  RpcBinding(workspacesCreateWorktreeProcedure, (request, _) {
    return _typedFailures(() => worktrees.createWorktree(request));
  }),
  RpcBinding(workspacesGetProjectSettingsProcedure, (request, _) {
    return _projectSettings(
      () => worktrees.getProjectSettings(request.workspaceId),
    );
  }),
  RpcBinding(workspacesSaveProjectSettingsProcedure, (request, _) {
    return _projectSettings(() => worktrees.saveProjectSettings(request));
  }),
  RpcBinding(workspacesPreviewArchiveProcedure, (request, _) async {
    return WorktreeArchivePreviewResultDto(
      preview: await _typedFailures(
        () => worktrees.previewArchive(request.worktreeId),
      ),
    );
  }),
  RpcBinding(workspacesArchiveWorktreeProcedure, (request, _) {
    return _typedFailures(
      () => worktrees.archive(request.worktreeId, force: request.force),
    );
  }),
];

Future<T> _projectSettings<T>(Future<T> Function() operation) async {
  try {
    return await _typedFailures(operation);
  } on FormatException catch (error) {
    if (!error.message.startsWith('invalid_project_settings:')) rethrow;
    throw const RpcFailureException(
      code: RpcErrorCodes.invalidProjectSettings,
      message: 'Project settings are invalid.',
    );
  }
}

/// Translates workspace-domain failures into stable protocol codes.
///
/// Without this every one of them reaches the transport catch-all and is
/// flattened into a bare "Internal daemon error." with no code and no detail.
Future<T> _typedFailures<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on WorktreeFailure catch (failure) {
    throw RpcFailureException(
      code: switch (failure.reason) {
        WorktreeFailureReason.workspaceNotFound =>
          RpcErrorCodes.workspaceNotFound,
        WorktreeFailureReason.workspaceNotGit => RpcErrorCodes.workspaceNotGit,
        WorktreeFailureReason.worktreeNotFound =>
          RpcErrorCodes.worktreeNotFound,
        WorktreeFailureReason.invalidBranchName =>
          RpcErrorCodes.invalidBranchName,
        WorktreeFailureReason.branchAlreadyExists =>
          RpcErrorCodes.branchAlreadyExists,
        WorktreeFailureReason.pathInUse => RpcErrorCodes.worktreePathInUse,
        WorktreeFailureReason.gitFailed => RpcErrorCodes.gitCommandFailed,
        WorktreeFailureReason.archiveBlocked =>
          RpcErrorCodes.worktreeArchiveBlocked,
        WorktreeFailureReason.workspaceProtected =>
          RpcErrorCodes.workspaceProtected,
      },
      message: failure.message,
      details: failure.details,
    );
  } on GitCommandException catch (error) {
    // Git failures escaping a path this helper does not pre-check still carry
    // the only explanation that exists: the command and its stderr.
    throw RpcFailureException(
      code: RpcErrorCodes.gitCommandFailed,
      message: error.stderr.isEmpty
          ? '${error.commandLine} exited with ${error.exitCode}.'
          : error.stderr,
      details: <String, dynamic>{
        'command': error.commandLine,
        'exitCode': error.exitCode,
        'stderr': error.stderr,
      },
    );
  }
}
