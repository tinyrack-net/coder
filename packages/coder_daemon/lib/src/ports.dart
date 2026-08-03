import 'dart:io';

import 'package:coder_protocol/coder_protocol.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Public API exposed by this library.
abstract interface class Clock {
  /// The nowUtc public API member.
  DateTime nowUtc();
}

/// SystemClock defines a public contract.
final class SystemClock implements Clock {
  /// Creates a [SystemClock].
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Public API exposed by this library.
abstract interface class IdGenerator {
  /// The generate public API member.
  String generate();
}

/// UuidIdGenerator defines a public contract.
final class UuidIdGenerator implements IdGenerator {
  /// Creates a [UuidIdGenerator].
  const UuidIdGenerator();

  @override
  String generate() => const Uuid().v4();
}

/// Public API exposed by this library.
abstract interface class WorkspaceCanonicalizer {
  /// The canonicalizeExistingDirectory public API member.
  String canonicalizeExistingDirectory(String path);
}

/// IoWorkspaceCanonicalizer defines a public contract.
final class IoWorkspaceCanonicalizer implements WorkspaceCanonicalizer {
  /// Creates a [IoWorkspaceCanonicalizer].
  const IoWorkspaceCanonicalizer();

  @override
  String canonicalizeExistingDirectory(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) {
      throw const FormatException('Workspace directory not found.');
    }
    return directory.resolveSymbolicLinksSync();
  }
}

/// Filesystem operations needed by the workspace application service.
abstract interface class WorkspacePathGateway {
  /// Resolves an existing directory and rejects missing paths.
  String canonicalizeExistingDirectory(String path);

  /// Creates a directory and missing parents.
  Future<void> createDirectory(String path);

  /// Returns matching directories on the daemon host.
  Future<List<DirectorySuggestionDto>> suggest(String query, int limit);
}

/// Production workspace filesystem adapter.
final class IoWorkspacePathGateway implements WorkspacePathGateway {
  /// Creates the production workspace filesystem adapter.
  const IoWorkspacePathGateway();

  @override
  String canonicalizeExistingDirectory(String path) =>
      const IoWorkspaceCanonicalizer().canonicalizeExistingDirectory(path);

  @override
  Future<void> createDirectory(String path) =>
      Directory(path).create(recursive: true);

  @override
  Future<List<DirectorySuggestionDto>> suggest(String query, int limit) async {
    if (limit <= 0) return const <DirectorySuggestionDto>[];
    final expanded = query.trim();
    if (expanded.isEmpty) return const <DirectorySuggestionDto>[];
    final candidate = Directory(expanded);
    final parent = candidate.existsSync() ? candidate : candidate.parent;
    if (!parent.existsSync()) return const <DirectorySuggestionDto>[];
    final needle = candidate.existsSync()
        ? ''
        : p.basename(expanded).toLowerCase();
    final suggestions = <DirectorySuggestionDto>[];
    try {
      await for (final entity in parent.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final name = p.basename(entity.path);
        if (needle.isNotEmpty && !name.toLowerCase().contains(needle)) {
          continue;
        }
        suggestions.add(DirectorySuggestionDto(path: entity.path, name: name));
        if (suggestions.length == limit) break;
      }
    } on FileSystemException {
      return const <DirectorySuggestionDto>[];
    }
    suggestions.sort((left, right) => left.name.compareTo(right.name));
    return suggestions;
  }
}

/// One checkout reported by `git worktree list --porcelain`.
final class GitWorktreeSnapshot {
  /// Creates a Git worktree snapshot.
  const GitWorktreeSnapshot({
    required this.path,
    this.branch,
    this.head,
  });

  /// Checkout path.
  final String path;

  /// Short local branch name.
  final String? branch;

  /// Checked-out commit.
  final String? head;
}

/// State that may make archiving destructive.
final class GitWorktreeState {
  /// Creates worktree safety state.
  const GitWorktreeState({this.dirty = false, this.unpushedCommitCount = 0});

  /// Whether tracked or untracked files have changes.
  final bool dirty;

  /// Number of commits not present on the configured upstream.
  final int unpushedCommitCount;
}

/// Typed request for `git worktree add`.
final class GitWorktreeCreateRequest {
  /// Creates a managed-worktree request.
  const GitWorktreeCreateRequest({
    required this.repositoryRoot,
    required this.path,
    required this.mode,
    required this.branchName,
    this.baseBranch,
  });

  /// Repository root used as the Git working directory.
  final String repositoryRoot;

  /// New checkout path.
  final String path;

  /// Whether a branch is created or an existing branch is checked out.
  final WorktreeCreateMode mode;

  /// Normalized local branch name.
  final String branchName;

  /// Base revision for a newly-created branch.
  final String? baseBranch;
}

/// Git operations used by workspace lifecycle logic.
abstract interface class GitWorkspaceGateway {
  /// Resolves a repository root, or null for a non-Git directory.
  Future<String?> repositoryRoot(String path);

  /// Lists active Git worktrees.
  Future<List<GitWorktreeSnapshot>> listWorktrees(String repositoryRoot);

  /// Lists local branches and checkout state.
  Future<List<GitBranchDto>> listBranches(String repositoryRoot);

  /// Creates a managed checkout.
  Future<void> createWorktree(GitWorktreeCreateRequest request);

  /// Inspects dirty and unpushed state.
  Future<GitWorktreeState> inspectWorktree(String path);

  /// Removes a managed checkout through Git.
  Future<void> removeWorktree(String repositoryRoot, String path);
}

/// Result returned by a process invocation.
final class CommandResult {
  /// Creates an immutable command result.
  const CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Process exit code.
  final int exitCode;

  /// Standard output.
  final String stdout;

  /// Standard error.
  final String stderr;
}

/// Process boundary used by the Git adapter.
abstract interface class CommandRunner {
  /// Runs an executable with an argument list and no shell interpolation.
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  });
}

/// Production process adapter.
final class IoCommandRunner implements CommandRunner {
  /// Creates the production process adapter.
  const IoCommandRunner();

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
    return CommandResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }
}
