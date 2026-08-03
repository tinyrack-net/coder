import 'dart:convert';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Repository and checkout lifecycle application service.
final class WorkspaceService {
  /// Creates a workspace service from typed persistence and host ports.
  const WorkspaceService(
    this._workspaces,
    this._worktrees,
    this._agents,
    this._paths,
    this._git,
    this._clock,
    this._managedWorktreeRoot,
  );

  final WorkspaceRepository _workspaces;
  final WorktreeRepository _worktrees;
  final AgentRepository _agents;
  final WorkspacePathGateway _paths;
  final GitWorkspaceGateway _git;
  final Clock _clock;
  final String _managedWorktreeRoot;

  /// Returns repositories and active worktrees as one catalog snapshot.
  Future<WorkspaceCatalogDto> catalog() async => WorkspaceCatalogDto(
    workspaces: await _workspaces.list(),
    worktrees: await _worktrees.list(),
  );

  /// Registers a directory or Git repository and discovers its checkouts.
  Future<WorkspaceRegisterResultDto> register(
    WorkspaceRegisterParamsDto request,
  ) async {
    final selectedPath = _paths.canonicalizeExistingDirectory(
      request.rootPath,
    );
    final discoveredRoot = await _git.repositoryRoot(selectedPath);
    if (discoveredRoot == null) {
      final existing = await _workspaces.getByRootPath(selectedPath);
      final workspace =
          existing ??
          await _workspaces.register(
            WorkspaceDto(
              id: request.workspaceId,
              name: request.name,
              rootPath: selectedPath,
              kind: WorkspaceKind.directory,
              createdAt: _clock.nowUtc(),
            ),
          );
      final checkout = await _worktrees.upsert(
        WorktreeDto(
          id: request.checkoutId,
          workspaceId: workspace.id,
          name: request.name,
          path: selectedPath,
          kind: WorktreeKind.directory,
          isCoderOwned: false,
          createdAt: _clock.nowUtc(),
        ),
      );
      return WorkspaceRegisterResultDto(
        workspace: workspace,
        worktrees: <WorktreeDto>[checkout],
      );
    }

    final snapshots = await _git.listWorktrees(discoveredRoot);
    final repositoryRoot = snapshots.isEmpty
        ? discoveredRoot
        : snapshots.first.path;
    final canonicalRoot = _paths.canonicalizeExistingDirectory(repositoryRoot);
    final existing = await _workspaces.getByRootPath(canonicalRoot);
    final workspace =
        existing ??
        await _workspaces.register(
          WorkspaceDto(
            id: request.workspaceId,
            name: request.name,
            rootPath: canonicalRoot,
            kind: WorkspaceKind.git,
            createdAt: _clock.nowUtc(),
          ),
        );
    final discovered = await _upsertGitSnapshots(
      workspace,
      snapshots,
      checkoutId: request.checkoutId,
    );
    return WorkspaceRegisterResultDto(
      workspace: workspace,
      worktrees: discovered,
    );
  }

  /// Refreshes worktree metadata for one repository.
  Future<WorkspaceCatalogDto> refresh(String workspaceId) async {
    final workspace = await _requireWorkspace(workspaceId);
    if (workspace.kind == WorkspaceKind.git) {
      await _upsertGitSnapshots(
        workspace,
        await _git.listWorktrees(workspace.rootPath),
      );
    }
    return catalog();
  }

  /// Removes a workspace registration when no session history references it.
  Future<void> unregister(String workspaceId) =>
      _workspaces.unregister(workspaceId);

  /// Searches directories on the daemon host.
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query,
    int limit,
  ) => _paths.suggest(query, limit);

  /// Lists local branches in one Git workspace.
  Future<List<GitBranchDto>> listBranches(String workspaceId) async {
    final workspace = await _requireWorkspace(workspaceId);
    if (workspace.kind != WorkspaceKind.git) {
      throw StateError('Workspace is not a Git repository.');
    }
    return _git.listBranches(workspace.rootPath);
  }

  /// Creates a managed checkout from a new or existing local branch.
  Future<WorktreeDto> createWorktree(WorktreeCreateParamsDto request) async {
    final workspace = await _requireWorkspace(request.workspaceId);
    if (workspace.kind != WorkspaceKind.git) {
      throw StateError('Managed worktrees require a Git repository.');
    }
    if (await _worktrees.getById(request.id) case final existing?) {
      return existing;
    }
    final branch = _normalizeBranch(request.branchName);
    final repositoryHash = sha256
        .convert(utf8.encode(workspace.rootPath))
        .toString()
        .substring(0, 12);
    final checkoutPath = p.join(
      _managedWorktreeRoot,
      repositoryHash,
      branch,
    );
    if (await _worktrees.getByPath(checkoutPath) != null) {
      throw StateError('A worktree already uses the generated path.');
    }
    await _paths.createDirectory(p.dirname(checkoutPath));
    await _git.createWorktree(
      GitWorktreeCreateRequest(
        repositoryRoot: workspace.rootPath,
        path: checkoutPath,
        mode: request.mode,
        branchName: branch,
        baseBranch: request.baseBranch,
      ),
    );
    final snapshots = await _git.listWorktrees(workspace.rootPath);
    final snapshot = snapshots
        .where((item) => item.path == checkoutPath)
        .firstOrNull;
    return _worktrees.upsert(
      WorktreeDto(
        id: request.id,
        workspaceId: workspace.id,
        name: branch,
        path: checkoutPath,
        branch: snapshot?.branch ?? branch,
        head: snapshot?.head,
        kind: WorktreeKind.managed,
        isCoderOwned: true,
        createdAt: _clock.nowUtc(),
      ),
    );
  }

  /// Returns current archive safety conditions.
  Future<WorktreeArchivePreviewDto> previewArchive(String worktreeId) async {
    final worktree = await _requireWorktree(worktreeId);
    final state = worktree.kind == WorktreeKind.directory
        ? const GitWorktreeState()
        : await _git.inspectWorktree(worktree.path);
    return WorktreeArchivePreviewDto(
      worktreeId: worktree.id,
      dirty: state.dirty,
      unpushedCommitCount: state.unpushedCommitCount,
      runningSessionCount: await _agents.countActive(worktree.id),
      removesDirectory: worktree.isCoderOwned,
    );
  }

  /// Archives one worktree and removes only Coder-owned managed checkouts.
  Future<WorktreeDto> archive(
    String worktreeId, {
    required bool force,
  }) async {
    final worktree = await _requireWorktree(worktreeId);
    final preview = await previewArchive(worktreeId);
    if (preview.runningSessionCount > 0) {
      throw StateError('A session is still running in this worktree.');
    }
    if (!force && (preview.dirty || preview.unpushedCommitCount > 0)) {
      throw StateError('Archive confirmation is required for local changes.');
    }
    if (worktree.isCoderOwned) {
      final workspace = await _requireWorkspace(worktree.workspaceId);
      await _git.removeWorktree(workspace.rootPath, worktree.path);
    }
    final archivedAt = _clock.nowUtc();
    await _worktrees.archive(worktree.id, archivedAt);
    return (await _worktrees.getById(worktree.id))!;
  }

  Future<List<WorktreeDto>> _upsertGitSnapshots(
    WorkspaceDto workspace,
    List<GitWorktreeSnapshot> snapshots, {
    String? checkoutId,
  }) async {
    final result = <WorktreeDto>[];
    for (var index = 0; index < snapshots.length; index += 1) {
      final snapshot = snapshots[index];
      final existing = await _worktrees.getByPath(snapshot.path);
      final isCheckout = index == 0;
      final worktree = await _worktrees.upsert(
        WorktreeDto(
          id:
              existing?.id ??
              (isCheckout && checkoutId != null
                  ? checkoutId
                  : _stableWorktreeId(workspace.id, snapshot.path)),
          workspaceId: workspace.id,
          name: snapshot.branch ?? p.basename(snapshot.path),
          path: snapshot.path,
          branch: snapshot.branch,
          head: snapshot.head,
          kind:
              existing?.kind ??
              (isCheckout ? WorktreeKind.checkout : WorktreeKind.external),
          isCoderOwned: existing?.isCoderOwned ?? false,
          createdAt: existing?.createdAt ?? _clock.nowUtc(),
        ),
      );
      result.add(worktree);
    }
    return result;
  }

  Future<WorkspaceDto> _requireWorkspace(String id) async =>
      await _workspaces.getById(id) ??
      (throw StateError('Workspace not found: $id'));

  Future<WorktreeDto> _requireWorktree(String id) async =>
      await _worktrees.getById(id) ??
      (throw StateError('Worktree not found: $id'));
}

String _normalizeBranch(String input) {
  final slug = input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^[-/.]+|[-/.]+$'), '');
  if (slug.isEmpty || slug.contains('..') || slug.endsWith('.lock')) {
    throw const FormatException('Invalid branch name.');
  }
  return slug;
}

String _stableWorktreeId(String workspaceId, String path) => sha256
    .convert(utf8.encode('$workspaceId\u0000$path'))
    .toString()
    .substring(0, 24);
