import 'dart:convert';

import 'package:coder_daemon/src/features/workspaces/infrastructure/project_settings.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/shared/ports/daemon_ports.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Repository and checkout lifecycle application service.
final class WorkspaceOperations {
  /// Creates a workspace service from typed persistence and host ports.
  const WorkspaceOperations(
    this._workspaces,
    this._worktrees,
    this._agents,
    this._paths,
    this._git,
    this._clock,
    this._managedWorktreeRoot,
    this._fileIndex, [
    this._projectSettings = const FileProjectSettingsStore(),
    this._hooks = const ShellWorktreeHookRunner(),
  ]);

  final WorkspaceRepository _workspaces;
  final WorktreeRepository _worktrees;
  final SessionRepository _agents;
  final WorkspacePathGateway _paths;
  final GitWorkspaceGateway _git;
  final Clock _clock;
  final String _managedWorktreeRoot;
  final WorkspaceFileIndexGateway _fileIndex;
  final ProjectSettingsStore _projectSettings;
  final WorktreeHookRunner _hooks;

  /// Returns repositories and active worktrees as one catalog snapshot.
  Future<WorkspaceCatalogDto> catalog() async => WorkspaceCatalogDto(
    workspaces: await _workspaces.list(),
    worktrees: await _worktrees.list(),
  );

  /// Identity of the implicit home workspace when this daemon creates it.
  ///
  /// A workspace the user had already registered at the home path keeps its own
  /// id and is adopted instead, so the guards below key on
  /// [WorkspaceKind.home] rather than on this constant.
  static const String homeWorkspaceId = 'home';

  /// Identity of the sole checkout of the implicit home workspace.
  static const String homeWorktreeId = 'home-checkout';

  /// Registers the user home directory as the implicit home workspace.
  ///
  /// Sessions the user starts without picking a project run in this checkout,
  /// which keeps every session bound to a real working directory. Runs on every
  /// boot and is idempotent; a workspace already registered at [userHome] is
  /// adopted rather than duplicated.
  ///
  /// Returns null when [userHome] is null, which is how tests and CI runs keep
  /// the daemon away from any real home.
  Future<WorktreeDto?> provisionHome(String? userHome) async {
    if (userHome == null) return null;
    final rootPath = _paths.canonicalizeExistingDirectory(userHome);
    final existing =
        await _workspaces.getByRootPath(rootPath) ?? await _homeWorkspace();
    final workspace = await _workspaces.upsert(
      WorkspaceDto(
        id: existing?.id ?? homeWorkspaceId,
        name: p.basename(rootPath),
        rootPath: rootPath,
        kind: WorkspaceKind.home,
        createdAt: existing?.createdAt ?? _clock.nowUtc(),
      ),
    );
    final checkout = await _worktrees.getByPath(rootPath);
    return _worktrees.upsert(
      WorktreeDto(
        id: checkout?.id ?? homeWorktreeId,
        workspaceId: workspace.id,
        name: workspace.name,
        path: rootPath,
        kind: WorktreeKind.directory,
        isCoderOwned: false,
        createdAt: checkout?.createdAt ?? _clock.nowUtc(),
      ),
    );
  }

  /// Returns the implicit home workspace, when this daemon has one.
  Future<WorkspaceDto?> _homeWorkspace() async => (await _workspaces.list())
      .where((item) => item.kind == WorkspaceKind.home)
      .firstOrNull;

  /// Registers a directory or Git repository and discovers its checkouts.
  Future<WorkspaceRegisterResultDto> register(
    WorkspaceRegisterParamsDto request,
  ) async {
    final selectedPath = _paths.canonicalizeExistingDirectory(
      request.rootPath,
    );
    // Registration merges by root path, so without this the home directory
    // would silently return the home workspace, which every project list
    // filters out.
    if ((await _workspaces.getByRootPath(selectedPath))?.kind ==
        WorkspaceKind.home) {
      throw StateError('The home directory cannot be registered as a project.');
    }
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
  ///
  /// The implicit home workspace is owned by the daemon and is never removable;
  /// dropping it would orphan every session that belongs to no project.
  Future<void> unregister(String workspaceId) async {
    final workspace = await _requireWorkspace(workspaceId);
    if (workspace.kind == WorkspaceKind.home) {
      throw StateError('The home workspace cannot be unregistered.');
    }
    await _workspaces.unregister(workspaceId);
  }

  /// Searches directories on the daemon host.
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query,
    int limit,
  ) => _paths.suggest(query, limit);

  /// Searches one worktree for files a composer mention can reference.
  Future<FileSearchResultDto> searchFiles(FileSearchParamsDto request) async {
    final worktree = await _worktrees.getById(request.worktreeId);
    if (worktree == null || worktree.archivedAt != null) {
      throw const FormatException('Active worktree not found.');
    }
    return _fileIndex.search(
      FileSearchRequest(
        root: worktree.path,
        query: request.query,
        limit: request.limit.clamp(1, 100),
      ),
    );
  }

  /// Updates the remote a base ref belongs to so the new branch starts from
  /// the latest upstream commit; a failed fetch falls back to the cached ref.
  Future<void> _fetchBaseRemote(
    String repositoryRoot,
    WorktreeCreateParamsDto request,
  ) async {
    final base = request.baseBranch;
    if (request.mode != WorktreeCreateMode.newBranch || base == null) return;
    final separator = base.indexOf('/');
    if (separator <= 0) return;
    final remote = base.substring(0, separator);
    if (!(await _git.listRemotes(repositoryRoot)).contains(remote)) return;
    await _git.fetchRemote(repositoryRoot, remote);
  }

  /// Lists local branches in one Git workspace.
  Future<List<GitBranchDto>> listBranches(String workspaceId) async {
    final workspace = await _requireWorkspace(workspaceId);
    if (workspace.kind != WorkspaceKind.git) {
      throw StateError('Workspace is not a Git repository.');
    }
    return _git.listBranches(workspace.rootPath);
  }

  /// Returns the `coder.json` settings of one registered workspace.
  Future<ProjectSettingsResultDto> getProjectSettings(
    String workspaceId,
  ) async {
    final workspace = await _requireWorkspace(workspaceId);
    return ProjectSettingsResultDto(
      settings: await _projectSettings.load(workspace.rootPath),
      sourcePath: _projectSettings.sourcePath(workspace.rootPath),
    );
  }

  /// Replaces the worktree hook section of one workspace's `coder.json`.
  Future<ProjectSettingsResultDto> saveProjectSettings(
    ProjectSettingsSaveParamsDto request,
  ) async {
    final workspace = await _requireWorkspace(request.workspaceId);
    await _projectSettings.save(workspace.rootPath, request.settings);
    return getProjectSettings(workspace.id);
  }

  /// Creates a managed checkout from a new or existing local branch.
  Future<WorktreeResultDto> createWorktree(
    WorktreeCreateParamsDto request,
  ) async {
    final workspace = await _requireWorkspace(request.workspaceId);
    if (workspace.kind != WorkspaceKind.git) {
      throw StateError('Managed worktrees require a Git repository.');
    }
    if (await _worktrees.getById(request.id) case final existing?) {
      return WorktreeResultDto(worktree: existing);
    }
    final branch = _normalizeBranch(request.branchName);
    await _fetchBaseRemote(workspace.rootPath, request);
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
    final worktree = await _worktrees.upsert(
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
    final hookRuns = await _runHooks(
      WorktreeHookPhase.setup,
      workspace: workspace,
      worktree: worktree,
    );
    if (hookRuns.any((run) => run.exitCode != 0)) {
      // A setup failure means the checkout is not safe to use. Remove the
      // Coder-owned path before hiding it from the active catalog so a failed
      // bootstrap cannot leave an apparently usable worktree behind.
      await _git.removeWorktree(
        workspace.rootPath,
        worktree.path,
        force: true,
      );
      final archivedAt = _clock.nowUtc();
      await _worktrees.archive(worktree.id, archivedAt);
      return WorktreeResultDto(
        worktree: worktree.copyWith(archivedAt: archivedAt),
        hookRuns: hookRuns,
      );
    }
    return WorktreeResultDto(worktree: worktree, hookRuns: hookRuns);
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
  Future<WorktreeResultDto> archive(
    String worktreeId, {
    required bool force,
  }) async {
    final worktree = await _requireWorktree(worktreeId);
    if ((await _workspaces.getById(worktree.workspaceId))?.kind ==
        WorkspaceKind.home) {
      throw StateError('The home checkout cannot be archived.');
    }
    final preview = await previewArchive(worktreeId);
    if (preview.runningSessionCount > 0) {
      throw StateError('A session is still running in this worktree.');
    }
    if (!force && (preview.dirty || preview.unpushedCommitCount > 0)) {
      throw StateError('Archive confirmation is required for local changes.');
    }
    final workspace = await _requireWorkspace(worktree.workspaceId);
    final hookRuns = await _runHooks(
      WorktreeHookPhase.teardown,
      workspace: workspace,
      worktree: worktree,
    );
    if (worktree.isCoderOwned) {
      await _git.removeWorktree(
        workspace.rootPath,
        worktree.path,
        force: force,
      );
    }
    final archivedAt = _clock.nowUtc();
    await _worktrees.archive(worktree.id, archivedAt);
    return WorktreeResultDto(
      worktree: (await _worktrees.getById(worktree.id))!,
      hookRuns: hookRuns,
    );
  }

  /// Runs configured hooks in order and stops at the first failing command.
  ///
  /// A failing hook never rolls back or blocks the surrounding lifecycle
  /// operation; the outcome is reported to the caller instead.
  Future<List<WorktreeHookRunDto>> _runHooks(
    WorktreeHookPhase phase, {
    required WorkspaceDto workspace,
    required WorktreeDto worktree,
  }) async {
    final ProjectSettingsDto settings;
    try {
      settings = await _projectSettings.load(workspace.rootPath);
    } on FormatException catch (error) {
      return <WorktreeHookRunDto>[
        WorktreeHookRunDto(
          phase: phase,
          command: _projectSettings.sourcePath(workspace.rootPath),
          exitCode: -1,
          stdout: '',
          stderr: error.message,
        ),
      ];
    }
    final commands = switch (phase) {
      WorktreeHookPhase.setup => settings.setup,
      WorktreeHookPhase.teardown => settings.teardown,
    };
    final environment = <String, String>{
      'CODER_PROJECT_PATH': workspace.rootPath,
      'CODER_WORKTREE_PATH': worktree.path,
      'CODER_BRANCH': ?worktree.branch,
    };
    final runs = <WorktreeHookRunDto>[];
    for (final command in commands) {
      final result = await _hooks.run(
        command,
        workingDirectory: worktree.path,
        environment: environment,
      );
      runs.add(
        WorktreeHookRunDto(
          phase: phase,
          command: command,
          exitCode: result.exitCode,
          stdout: result.stdout,
          stderr: result.stderr,
        ),
      );
      if (result.exitCode != 0) break;
    }
    return runs;
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

  /// Returns the checkout root of one registered workspace.
  Future<String> workspaceRoot(String workspaceId) async =>
      (await _requireWorkspace(workspaceId)).rootPath;

  Future<WorkspaceDto> _requireWorkspace(String id) async =>
      await _workspaces.getById(id) ??
      (throw StateError('Workspace not found: $id'));

  Future<WorktreeDto> _requireWorktree(String id) async =>
      await _worktrees.getById(id) ??
      (throw StateError('Worktree not found: $id'));
}

/// Repository registration and discovery operations used by RPC callers.
abstract interface class WorkspaceCatalogPort {
  /// Returns every registered workspace and active checkout.
  Future<WorkspaceCatalogDto> catalog();

  /// Ensures the optional user-home workspace exists.
  Future<WorktreeDto?> provisionHome(String? userHome);

  /// Registers a directory or repository.
  Future<WorkspaceRegisterResultDto> register(
    WorkspaceRegisterParamsDto request,
  );

  /// Refreshes discovered checkout metadata.
  Future<WorkspaceCatalogDto> refresh(String workspaceId);

  /// Removes a project registration.
  Future<void> unregister(String workspaceId);

  /// Suggests host directories matching a query.
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query,
    int limit,
  );

  /// Searches files within an active worktree.
  Future<FileSearchResultDto> searchFiles(FileSearchParamsDto request);

  /// Resolves the root directory of a registered workspace.
  Future<String> workspaceRoot(String workspaceId);
}

/// Worktree and project-settings operations used by RPC callers.
abstract interface class WorktreeLifecyclePort {
  /// Lists branches available to a Git workspace.
  Future<List<GitBranchDto>> listBranches(String workspaceId);

  /// Reads project settings from a workspace root.
  Future<ProjectSettingsResultDto> getProjectSettings(String workspaceId);

  /// Writes project settings to a workspace root.
  Future<ProjectSettingsResultDto> saveProjectSettings(
    ProjectSettingsSaveParamsDto request,
  );

  /// Creates one managed checkout.
  Future<WorktreeResultDto> createWorktree(WorktreeCreateParamsDto request);

  /// Reports archive risks without changing the checkout.
  Future<WorktreeArchivePreviewDto> previewArchive(String worktreeId);

  /// Archives a checkout after enforcing safety rules.
  Future<WorktreeResultDto> archive(
    String worktreeId, {
    required bool force,
  });
}

/// Cohesive workspace catalog view over shared workspace operations.
final class WorkspaceCatalogService implements WorkspaceCatalogPort {
  /// Creates the workspace catalog service.
  const WorkspaceCatalogService(this._operations);

  final WorkspaceOperations _operations;

  @override
  Future<WorkspaceCatalogDto> catalog() => _operations.catalog();
  @override
  Future<WorktreeDto?> provisionHome(String? userHome) =>
      _operations.provisionHome(userHome);
  @override
  Future<WorkspaceRegisterResultDto> register(
    WorkspaceRegisterParamsDto request,
  ) => _operations.register(request);
  @override
  Future<WorkspaceCatalogDto> refresh(String workspaceId) =>
      _operations.refresh(workspaceId);
  @override
  Future<void> unregister(String workspaceId) =>
      _operations.unregister(workspaceId);
  @override
  Future<List<DirectorySuggestionDto>> suggestDirectories(
    String query,
    int limit,
  ) => _operations.suggestDirectories(query, limit);
  @override
  Future<FileSearchResultDto> searchFiles(FileSearchParamsDto request) =>
      _operations.searchFiles(request);
  @override
  Future<String> workspaceRoot(String workspaceId) =>
      _operations.workspaceRoot(workspaceId);
}

/// Cohesive managed-worktree lifecycle view over shared workspace operations.
final class WorktreeLifecycleService implements WorktreeLifecyclePort {
  /// Creates the managed-worktree lifecycle service.
  const WorktreeLifecycleService(this._operations);

  final WorkspaceOperations _operations;

  @override
  Future<List<GitBranchDto>> listBranches(String workspaceId) =>
      _operations.listBranches(workspaceId);
  @override
  Future<ProjectSettingsResultDto> getProjectSettings(String workspaceId) =>
      _operations.getProjectSettings(workspaceId);
  @override
  Future<ProjectSettingsResultDto> saveProjectSettings(
    ProjectSettingsSaveParamsDto request,
  ) => _operations.saveProjectSettings(request);
  @override
  Future<WorktreeResultDto> createWorktree(WorktreeCreateParamsDto request) =>
      _operations.createWorktree(request);
  @override
  Future<WorktreeArchivePreviewDto> previewArchive(String worktreeId) =>
      _operations.previewArchive(worktreeId);
  @override
  Future<WorktreeResultDto> archive(
    String worktreeId, {
    required bool force,
  }) => _operations.archive(worktreeId, force: force);
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
