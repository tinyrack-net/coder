import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/git_workspace.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/workspace_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  test('parses git worktree porcelain without shell-dependent output', () {
    final worktrees = parseGitWorktreePorcelain('''
worktree /repo
HEAD abc123
branch refs/heads/main

worktree /repo-feature
HEAD def456
branch refs/heads/feature/settings

''');

    expect(worktrees, hasLength(2));
    expect(worktrees.first.path, '/repo');
    expect(worktrees.first.branch, 'main');
    expect(worktrees.last.branch, 'feature/settings');
  });

  test(
    'registers repository checkouts and creates a managed worktree',
    () async {
      final database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _FixedClock(),
      );
      addTearDown(database.close);
      final git = _FakeGitGateway();
      final service = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.agentDao,
        _FakeWorkspacePaths(),
        git,
        _FixedClock(),
        '/state/worktrees',
      );

      final registered = await service.register(
        const WorkspaceRegisterParamsDto(
          workspaceId: 'repo-1',
          checkoutId: 'checkout-1',
          rootPath: '/repo',
          name: 'Repository',
        ),
      );
      expect(registered.workspace.kind, WorkspaceKind.git);
      expect(
        registered.worktrees.map((item) => item.kind),
        <WorktreeKind>[WorktreeKind.checkout, WorktreeKind.external],
      );

      final managed = await service.createWorktree(
        const WorktreeCreateParamsDto(
          id: 'managed-1',
          workspaceId: 'repo-1',
          mode: WorktreeCreateMode.newBranch,
          branchName: 'Feature/User Settings',
          baseBranch: 'main',
        ),
      );
      expect(managed.kind, WorktreeKind.managed);
      expect(managed.isCoderOwned, isTrue);
      expect(managed.path, contains('/state/worktrees/'));
      expect(git.created.single.branchName, 'feature-user-settings');
    },
  );

  test(
    'archive requires confirmation and only removes managed paths',
    () async {
      final database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _FixedClock(),
      );
      addTearDown(database.close);
      final git = _FakeGitGateway()
        ..state = const GitWorktreeState(dirty: true);
      final service = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.agentDao,
        _FakeWorkspacePaths(),
        git,
        _FixedClock(),
        '/state/worktrees',
      );
      await service.register(
        const WorkspaceRegisterParamsDto(
          workspaceId: 'repo-1',
          checkoutId: 'checkout-1',
          rootPath: '/repo',
          name: 'Repository',
        ),
      );
      await service.createWorktree(
        const WorktreeCreateParamsDto(
          id: 'managed-1',
          workspaceId: 'repo-1',
          mode: WorktreeCreateMode.existingBranch,
          branchName: 'topic',
        ),
      );

      final preview = await service.previewArchive('managed-1');
      expect(preview.dirty, isTrue);
      expect(preview.removesDirectory, isTrue);
      await expectLater(
        service.archive('managed-1', force: false),
        throwsA(isA<StateError>()),
      );
      final archived = await service.archive('managed-1', force: true);
      expect(archived.archivedAt?.toUtc(), _FixedClock.now);
      expect(git.removed, hasLength(1));
    },
  );

  test(
    'supports directory lifecycle and rejects Git-only operations',
    () async {
      final database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _FixedClock(),
      );
      addTearDown(database.close);
      final git = _FakeGitGateway()..root = null;
      final paths = _FakeWorkspacePaths();
      final service = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.agentDao,
        paths,
        git,
        _FixedClock(),
        '/state/worktrees',
      );

      final registered = await service.register(
        const WorkspaceRegisterParamsDto(
          workspaceId: 'directory-1',
          checkoutId: 'directory-checkout',
          rootPath: '/plain',
          name: 'Plain folder',
        ),
      );
      expect(registered.workspace.kind, WorkspaceKind.directory);
      expect(registered.worktrees.single.kind, WorktreeKind.directory);
      expect((await service.catalog()).workspaces, hasLength(1));
      expect((await service.refresh('directory-1')).worktrees, hasLength(1));
      expect(await service.suggestDirectories('/pl', 4), hasLength(1));
      expect(paths.lastSuggestion, (query: '/pl', limit: 4));
      await expectLater(
        service.listBranches('directory-1'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.createWorktree(
          const WorktreeCreateParamsDto(
            id: 'not-allowed',
            workspaceId: 'directory-1',
            mode: WorktreeCreateMode.newBranch,
            branchName: 'topic',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      final preview = await service.previewArchive('directory-checkout');
      expect(preview.dirty, isFalse);
      expect(preview.removesDirectory, isFalse);
      await service.archive('directory-checkout', force: false);
      expect(git.removed, isEmpty);
      await service.unregister('directory-1');
      expect((await service.catalog()).workspaces, isEmpty);
    },
  );

  test(
    'worktree creation is idempotent and validates branch collisions',
    () async {
      final database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _FixedClock(),
      );
      addTearDown(database.close);
      final git = _FakeGitGateway();
      final service = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.agentDao,
        _FakeWorkspacePaths(),
        git,
        _FixedClock(),
        '/state/worktrees',
      );
      await service.register(
        const WorkspaceRegisterParamsDto(
          workspaceId: 'repo-1',
          checkoutId: 'checkout-1',
          rootPath: '/repo',
          name: 'Repository',
        ),
      );
      expect(await service.listBranches('repo-1'), hasLength(2));

      const request = WorktreeCreateParamsDto(
        id: 'managed-1',
        workspaceId: 'repo-1',
        mode: WorktreeCreateMode.newBranch,
        branchName: 'Topic Branch',
      );
      final created = await service.createWorktree(request);
      expect(created.head, 'created-head');
      expect(await service.createWorktree(request), created);
      await expectLater(
        service.createWorktree(
          const WorktreeCreateParamsDto(
            id: 'managed-2',
            workspaceId: 'repo-1',
            mode: WorktreeCreateMode.newBranch,
            branchName: 'Topic Branch',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.createWorktree(
          const WorktreeCreateParamsDto(
            id: 'managed-invalid',
            workspaceId: 'repo-1',
            mode: WorktreeCreateMode.newBranch,
            branchName: '../',
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        service.refresh('missing'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.previewArchive('missing'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('archive refuses a worktree with a running session', () async {
    final database = CoderDatabase.forTesting(
      NativeDatabase.memory(),
      clock: _FixedClock(),
    );
    addTearDown(database.close);
    final service = WorkspaceService(
      database.workspaceDao,
      database.worktreeDao,
      database.agentDao,
      _FakeWorkspacePaths(),
      _FakeGitGateway(),
      _FixedClock(),
      '/state/worktrees',
    );
    await service.register(
      const WorkspaceRegisterParamsDto(
        workspaceId: 'repo-1',
        checkoutId: 'checkout-1',
        rootPath: '/repo',
        name: 'Repository',
      ),
    );
    await database.agentDao.create(
      AgentDto(
        id: 'running-session',
        worktreeId: 'checkout-1',
        title: 'Running',
        providerConnectionId: 'openai',
        model: 'model',
        status: AgentStatus.running,
        permissionMode: PermissionMode.ask,
        createdAt: _FixedClock.now,
        updatedAt: _FixedClock.now,
      ),
    );

    expect((await service.previewArchive('checkout-1')).runningSessionCount, 1);
    await expectLater(
      service.archive('checkout-1', force: true),
      throwsA(isA<StateError>()),
    );
  });

  group('process Git workspace gateway', () {
    test(
      'discovers repositories, worktrees, and checkout branch state',
      () async {
        final commands = _FakeCommandRunner(<CommandResult>[
          _result(stdout: '/repo\n'),
          _result(stdout: _worktreePorcelain),
          _result(stdout: 'main\u0000*\ntopic\u0000\n'),
          _result(stdout: _worktreePorcelain),
        ]);
        final gateway = ProcessGitWorkspaceGateway(commands);

        expect(await gateway.repositoryRoot('/repo/child'), '/repo');
        final worktrees = await gateway.listWorktrees('/repo');
        expect(worktrees, hasLength(2));
        final branches = await gateway.listBranches('/repo');
        expect(
          branches,
          <GitBranchDto>[
            const GitBranchDto(
              name: 'main',
              current: true,
              checkedOut: true,
            ),
            const GitBranchDto(
              name: 'topic',
              current: false,
              checkedOut: false,
            ),
          ],
        );
        expect(commands.invocations.first.executable, 'git');
        expect(commands.invocations.first.workingDirectory, '/repo/child');
      },
    );

    test('returns null outside a repository and surfaces Git errors', () async {
      final commands = _FakeCommandRunner(<CommandResult>[
        _result(exitCode: 128, stderr: 'not a repository'),
        _result(exitCode: 1, stderr: 'broken repository'),
      ]);
      final gateway = ProcessGitWorkspaceGateway(commands);

      expect(await gateway.repositoryRoot('/plain'), isNull);
      await expectLater(
        gateway.listWorktrees('/repo'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('broken repository'),
          ),
        ),
      );
    });

    test('creates new and existing branch worktrees without a shell', () async {
      final commands = _FakeCommandRunner(<CommandResult>[
        _result(),
        _result(),
      ]);
      final gateway = ProcessGitWorkspaceGateway(commands);

      await gateway.createWorktree(
        const GitWorktreeCreateRequest(
          repositoryRoot: '/repo',
          path: '/managed/new',
          mode: WorktreeCreateMode.newBranch,
          branchName: 'feature',
          baseBranch: 'develop',
        ),
      );
      await gateway.createWorktree(
        const GitWorktreeCreateRequest(
          repositoryRoot: '/repo',
          path: '/managed/existing',
          mode: WorktreeCreateMode.existingBranch,
          branchName: 'topic',
        ),
      );

      expect(
        commands.invocations.first.arguments,
        <String>[
          'worktree',
          'add',
          '-b',
          'feature',
          '/managed/new',
          'develop',
        ],
      );
      expect(
        commands.invocations.last.arguments,
        <String>['worktree', 'add', '/managed/existing', 'topic'],
      );
    });

    test(
      'inspects dirty and unpushed state with and without upstream',
      () async {
        final withUpstream = ProcessGitWorkspaceGateway(
          _FakeCommandRunner(<CommandResult>[
            _result(stdout: ' M lib/main.dart\n'),
            _result(stdout: 'origin/main\n'),
            _result(stdout: '3\n'),
          ]),
        );
        expect(
          await withUpstream.inspectWorktree('/repo'),
          isA<GitWorktreeState>()
              .having((state) => state.dirty, 'dirty', isTrue)
              .having(
                (state) => state.unpushedCommitCount,
                'unpushedCommitCount',
                3,
              ),
        );

        final withoutUpstream = ProcessGitWorkspaceGateway(
          _FakeCommandRunner(<CommandResult>[
            _result(),
            _result(exitCode: 128),
          ]),
        );
        final clean = await withoutUpstream.inspectWorktree('/repo');
        expect(clean.dirty, isFalse);
        expect(clean.unpushedCommitCount, 0);
      },
    );

    test(
      'removes a worktree and validates status and count commands',
      () async {
        final commands = _FakeCommandRunner(<CommandResult>[
          _result(),
          _result(exitCode: 1, stderr: 'status failed'),
        ]);
        final gateway = ProcessGitWorkspaceGateway(commands);

        await gateway.removeWorktree('/repo', '/managed/topic');
        expect(
          commands.invocations.first.arguments,
          <String>['worktree', 'remove', '/managed/topic'],
        );
        await expectLater(
          gateway.inspectWorktree('/repo'),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}

const _worktreePorcelain = '''
worktree /repo
HEAD abc123
branch refs/heads/main

worktree /repo-feature
HEAD def456
branch refs/heads/feature/settings

''';

CommandResult _result({
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) => CommandResult(exitCode: exitCode, stdout: stdout, stderr: stderr);

final class _CommandInvocation {
  const _CommandInvocation({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String workingDirectory;
}

final class _FakeCommandRunner implements CommandRunner {
  _FakeCommandRunner(this._results);

  final List<CommandResult> _results;
  final List<_CommandInvocation> invocations = <_CommandInvocation>[];

  @override
  Future<CommandResult> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async {
    invocations.add(
      _CommandInvocation(
        executable: executable,
        arguments: List<String>.unmodifiable(arguments),
        workingDirectory: workingDirectory,
      ),
    );
    return _results.removeAt(0);
  }
}

final class _FixedClock implements Clock {
  static final DateTime now = DateTime.utc(2026, 8, 3);

  @override
  DateTime nowUtc() => now;
}

final class _FakeWorkspacePaths implements WorkspacePathGateway {
  ({String query, int limit})? lastSuggestion;

  @override
  String canonicalizeExistingDirectory(String path) => path;

  @override
  Future<void> createDirectory(String path) async {}

  @override
  Future<List<DirectorySuggestionDto>> suggest(String query, int limit) async {
    lastSuggestion = (query: query, limit: limit);
    return <DirectorySuggestionDto>[
      const DirectorySuggestionDto(path: '/repo', name: 'repo'),
    ];
  }
}

final class _FakeGitGateway implements GitWorkspaceGateway {
  String? root = '/repo';
  GitWorktreeState state = const GitWorktreeState();
  final List<GitWorktreeCreateRequest> created = <GitWorktreeCreateRequest>[];
  final List<String> removed = <String>[];
  final List<GitWorktreeSnapshot> snapshots = <GitWorktreeSnapshot>[
    const GitWorktreeSnapshot(path: '/repo', branch: 'main', head: 'abc'),
    const GitWorktreeSnapshot(path: '/other', branch: 'other', head: 'def'),
  ];

  @override
  Future<String?> repositoryRoot(String path) async => root;

  @override
  Future<List<GitWorktreeSnapshot>> listWorktrees(
    String repositoryRoot,
  ) async => List<GitWorktreeSnapshot>.unmodifiable(snapshots);

  @override
  Future<List<GitBranchDto>> listBranches(String repositoryRoot) async =>
      const <GitBranchDto>[
        GitBranchDto(name: 'main', current: true, checkedOut: true),
        GitBranchDto(name: 'topic', current: false, checkedOut: false),
      ];

  @override
  Future<void> createWorktree(GitWorktreeCreateRequest request) async {
    created.add(request);
    snapshots.add(
      GitWorktreeSnapshot(
        path: request.path,
        branch: request.branchName,
        head: 'created-head',
      ),
    );
  }

  @override
  Future<GitWorktreeState> inspectWorktree(String path) async => state;

  @override
  Future<void> removeWorktree(String repositoryRoot, String path) async {
    removed.add(path);
  }
}
