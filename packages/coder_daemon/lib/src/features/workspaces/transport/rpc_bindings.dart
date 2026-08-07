import 'package:coder_daemon/src/features/workspaces/infrastructure/workspace_service.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Builds the workspace feature's complete v4 RPC surface.
List<RpcBindingDescriptor> workspaceRpcBindings({
  required WorkspaceCatalogPort workspaces,
  required WorktreeLifecyclePort worktrees,
}) => <RpcBindingDescriptor>[
  RpcBinding(workspacesCatalogProcedure, (_, _) async {
    return WorkspaceCatalogResultDto(catalog: await workspaces.catalog());
  }),
  RpcBinding(workspacesRegisterProcedure, (request, _) {
    return workspaces.register(request);
  }),
  RpcBinding(workspacesRefreshProcedure, (request, _) async {
    return WorkspaceCatalogResultDto(
      catalog: await workspaces.refresh(request.workspaceId),
    );
  }),
  RpcBinding(workspacesUnregisterProcedure, (request, _) async {
    await workspaces.unregister(request.workspaceId);
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
      branches: await worktrees.listBranches(request.workspaceId),
    );
  }),
  RpcBinding(workspacesCreateWorktreeProcedure, (request, _) {
    return worktrees.createWorktree(request);
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
      preview: await worktrees.previewArchive(request.worktreeId),
    );
  }),
  RpcBinding(workspacesArchiveWorktreeProcedure, (request, _) {
    return worktrees.archive(request.worktreeId, force: request.force);
  }),
];

Future<T> _projectSettings<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on FormatException catch (error) {
    if (!error.message.startsWith('invalid_project_settings:')) rethrow;
    throw const RpcFailureException(
      code: 'invalid_project_settings',
      message: 'Project settings are invalid.',
    );
  }
}
