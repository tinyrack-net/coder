import 'package:coder_daemon/src/ports.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Git CLI adapter that never invokes a shell.
final class ProcessGitWorkspaceGateway implements GitWorkspaceGateway {
  /// Creates a Git adapter using the injected process boundary.
  const ProcessGitWorkspaceGateway(this._commands);

  final CommandRunner _commands;

  @override
  Future<String?> repositoryRoot(String path) async {
    final result = await _commands.run(
      'git',
      const <String>['rev-parse', '--show-toplevel'],
      workingDirectory: path,
    );
    return result.exitCode == 0 ? result.stdout.trim() : null;
  }

  @override
  Future<List<GitWorktreeSnapshot>> listWorktrees(
    String repositoryRoot,
  ) async {
    final result = await _commands.run(
      'git',
      const <String>['worktree', 'list', '--porcelain'],
      workingDirectory: repositoryRoot,
    );
    _requireSuccess(result, 'Unable to list Git worktrees.');
    return parseGitWorktreePorcelain(result.stdout);
  }

  @override
  Future<List<GitBranchDto>> listBranches(String repositoryRoot) async {
    final result = await _commands.run(
      'git',
      const <String>[
        'for-each-ref',
        '--format=%(refname:short)%00%(HEAD)',
        'refs/heads',
      ],
      workingDirectory: repositoryRoot,
    );
    _requireSuccess(result, 'Unable to list local branches.');
    final checkedOut = (await listWorktrees(
      repositoryRoot,
    )).map((item) => item.branch).nonNulls.toSet();
    return result.stdout
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) {
          final fields = line.split('\u0000');
          final name = fields.first;
          return GitBranchDto(
            name: name,
            current: fields.length > 1 && fields[1] == '*',
            checkedOut: checkedOut.contains(name),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> createWorktree(GitWorktreeCreateRequest request) async {
    final arguments = <String>['worktree', 'add'];
    if (request.mode == WorktreeCreateMode.newBranch) {
      arguments
        ..add('-b')
        ..add(request.branchName)
        ..add(request.path)
        ..add(request.baseBranch ?? 'HEAD');
    } else {
      arguments
        ..add(request.path)
        ..add(request.branchName);
    }
    final result = await _commands.run(
      'git',
      arguments,
      workingDirectory: request.repositoryRoot,
    );
    _requireSuccess(result, 'Unable to create Git worktree.');
  }

  @override
  Future<GitWorktreeState> inspectWorktree(String path) async {
    final status = await _commands.run(
      'git',
      const <String>['status', '--porcelain=v1'],
      workingDirectory: path,
    );
    _requireSuccess(status, 'Unable to inspect Git worktree.');
    final upstream = await _commands.run(
      'git',
      const <String>['rev-parse', '--abbrev-ref', '@{upstream}'],
      workingDirectory: path,
    );
    var unpushed = 0;
    if (upstream.exitCode == 0) {
      final count = await _commands.run(
        'git',
        const <String>['rev-list', '--count', '@{upstream}..HEAD'],
        workingDirectory: path,
      );
      _requireSuccess(count, 'Unable to inspect unpushed commits.');
      unpushed = int.tryParse(count.stdout.trim()) ?? 0;
    }
    return GitWorktreeState(
      dirty: status.stdout.trim().isNotEmpty,
      unpushedCommitCount: unpushed,
    );
  }

  @override
  Future<void> removeWorktree(String repositoryRoot, String path) async {
    final result = await _commands.run(
      'git',
      <String>['worktree', 'remove', path],
      workingDirectory: repositoryRoot,
    );
    _requireSuccess(result, 'Unable to remove Git worktree.');
  }
}

/// Parses the stable porcelain output of `git worktree list`.
List<GitWorktreeSnapshot> parseGitWorktreePorcelain(String output) {
  final result = <GitWorktreeSnapshot>[];
  String? path;
  String? branch;
  String? head;
  void flush() {
    if (path == null) return;
    result.add(GitWorktreeSnapshot(path: path!, branch: branch, head: head));
    path = null;
    branch = null;
    head = null;
  }

  for (final line in '${output.trimRight()}\n\n'.split('\n')) {
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('worktree ')) {
      path = line.substring('worktree '.length);
    } else if (line.startsWith('HEAD ')) {
      head = line.substring('HEAD '.length);
    } else if (line.startsWith('branch refs/heads/')) {
      branch = line.substring('branch refs/heads/'.length);
    }
  }
  return List<GitWorktreeSnapshot>.unmodifiable(result);
}

void _requireSuccess(CommandResult result, String message) {
  if (result.exitCode != 0) {
    throw StateError('$message ${result.stderr.trim()}');
  }
}
