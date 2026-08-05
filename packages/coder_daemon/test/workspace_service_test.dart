import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/git_workspace.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/project_settings.dart';
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
        database.sessionDao,
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
      expect(managed.worktree.kind, WorktreeKind.managed);
      expect(managed.worktree.isCoderOwned, isTrue);
      // The configured root is preserved verbatim and the branch names the
      // leaf; only the separator between them follows the host.
      expect(managed.worktree.path, startsWith('/state/worktrees'));
      expect(managed.worktree.path, endsWith('feature-user-settings'));
      expect(managed.hookRuns, isEmpty);
      expect(git.created.single.branchName, 'feature-user-settings');
    },
    tags: const <String>[
      'feature_test__workspace_catalog__unit',
      'feature_test__workspace_registration__unit',
      'feature_test__worktree_lifecycle__unit',
    ],
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
        database.sessionDao,
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
      expect(archived.worktree.archivedAt?.toUtc(), _FixedClock.now);
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
        database.sessionDao,
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
        database.sessionDao,
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
      final branches = await service.listBranches('repo-1');
      expect(branches, hasLength(3));
      expect(
        branches.where((branch) => branch.isRemote).single.name,
        'origin/main',
      );

      // A remote base ref is refreshed before the worktree is created.
      await service.createWorktree(
        const WorktreeCreateParamsDto(
          id: 'managed-remote',
          workspaceId: 'repo-1',
          mode: WorktreeCreateMode.newBranch,
          branchName: 'from-remote',
          baseBranch: 'origin/main',
        ),
      );
      expect(git.fetched, <String>['origin']);
      expect(git.created.single.baseBranch, 'origin/main');

      // A local base ref and an unknown remote never trigger a fetch.
      git
        ..fetched.clear()
        ..created.clear()
        ..fetchSucceeds = false;
      await service.createWorktree(
        const WorktreeCreateParamsDto(
          id: 'managed-local',
          workspaceId: 'repo-1',
          mode: WorktreeCreateMode.newBranch,
          branchName: 'from-local',
          baseBranch: 'main',
        ),
      );
      expect(git.fetched, isEmpty);

      // A failing fetch still creates the worktree from the cached ref.
      final offline = await service.createWorktree(
        const WorktreeCreateParamsDto(
          id: 'managed-offline',
          workspaceId: 'repo-1',
          mode: WorktreeCreateMode.newBranch,
          branchName: 'offline',
          baseBranch: 'origin/main',
        ),
      );
      expect(git.fetched, <String>['origin']);
      expect(offline.worktree.branch, 'offline');
      git
        ..fetched.clear()
        ..created.clear()
        ..fetchSucceeds = true;

      const request = WorktreeCreateParamsDto(
        id: 'managed-1',
        workspaceId: 'repo-1',
        mode: WorktreeCreateMode.newBranch,
        branchName: 'Topic Branch',
      );
      final created = await service.createWorktree(request);
      expect(created.worktree.head, 'created-head');
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
      database.sessionDao,
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
    await database.sessionDao.create(
      SessionDto(
        id: 'running-session',
        worktreeId: 'checkout-1',
        title: 'Running',
        agentDefinitionId: 'coder',
        origin: SessionOrigin.manual,
        status: SessionStatus.running,
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

  group('worktree lifecycle hooks', () {
    late CoderDatabase database;
    late _FakeProjectSettings projectSettings;
    late _FakeHookRunner hooks;
    late _FakeGitGateway git;
    late List<String> log;
    late WorkspaceService service;

    setUp(() async {
      database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _FixedClock(),
      );
      addTearDown(database.close);
      log = <String>[];
      projectSettings = _FakeProjectSettings();
      hooks = _FakeHookRunner(log);
      git = _FakeGitGateway(log);
      service = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.sessionDao,
        _FakeWorkspacePaths(),
        git,
        _FixedClock(),
        '/state/worktrees',
        projectSettings,
        hooks,
      );
      await service.register(
        const WorkspaceRegisterParamsDto(
          workspaceId: 'repo-1',
          checkoutId: 'checkout-1',
          rootPath: '/repo',
          name: 'Repository',
        ),
      );
    });

    Future<WorktreeResultDto> createManaged({String id = 'managed-1'}) =>
        service.createWorktree(
          WorktreeCreateParamsDto(
            id: id,
            workspaceId: 'repo-1',
            mode: WorktreeCreateMode.existingBranch,
            branchName: 'topic',
          ),
        );

    test(
      'reads and writes project settings through the workspace root',
      () async {
        expect(
          await service.getProjectSettings('repo-1'),
          const ProjectSettingsResultDto(
            settings: ProjectSettingsDto(),
            sourcePath: '/repo/coder.json',
          ),
        );

        const settings = ProjectSettingsDto(
          setup: <String>['npm ci'],
          teardown: <String>['docker compose down'],
        );
        expect(
          await service.saveProjectSettings(
            const ProjectSettingsSaveParamsDto(
              workspaceId: 'repo-1',
              settings: settings,
            ),
          ),
          const ProjectSettingsResultDto(
            settings: settings,
            sourcePath: '/repo/coder.json',
          ),
        );
        expect(projectSettings.saved, <ProjectSettingsDto>[settings]);
        await expectLater(
          service.getProjectSettings('missing'),
          throwsA(isA<StateError>()),
        );
      },
      tags: const <String>['feature_test__project_settings__unit'],
    );

    test(
      'runs setup hooks in the new checkout with worktree environment',
      () async {
        projectSettings.settings = const ProjectSettingsDto(
          setup: <String>['npm ci', 'npm run build'],
        );

        final created = await createManaged();

        expect(
          created.hookRuns.map((run) => run.command),
          <String>['npm ci', 'npm run build'],
        );
        expect(
          created.hookRuns.every(
            (run) => run.phase == WorktreeHookPhase.setup && run.exitCode == 0,
          ),
          isTrue,
        );
        expect(
          hooks.invocations.first.workingDirectory,
          created.worktree.path,
        );
        expect(hooks.invocations.first.environment, <String, String>{
          'CODER_PROJECT_PATH': '/repo',
          'CODER_WORKTREE_PATH': created.worktree.path,
          'CODER_BRANCH': 'topic',
        });
      },
      tags: const <String>['feature_test__worktree_lifecycle__unit'],
    );

    test(
      'removes and archives the worktree after a failing setup hook',
      () async {
        projectSettings.settings = const ProjectSettingsDto(
          setup: <String>['npm ci', 'npm run build'],
        );
        hooks.failures['npm ci'] = const CommandResult(
          exitCode: 2,
          stdout: 'partial',
          stderr: 'network down',
        );

        final created = await createManaged();

        expect(created.hookRuns, hasLength(1));
        expect(created.hookRuns.single.exitCode, 2);
        expect(created.hookRuns.single.stderr, 'network down');
        expect(created.worktree.archivedAt?.toUtc(), _FixedClock.now);
        expect(git.removed, <String>[created.worktree.path]);
        expect(
          (await service.catalog()).worktrees.map((item) => item.id),
          isNot(contains('managed-1')),
        );
        expect(log, <String>['hook:npm ci', 'git:remove:force']);
      },
      tags: const <String>['feature_test__worktree_lifecycle__unit'],
    );

    test('reports unreadable project settings as a failed hook', () async {
      projectSettings.loadFailure = const FormatException(
        'invalid_project_settings: broken',
      );

      final created = await createManaged();

      expect(created.hookRuns.single.exitCode, -1);
      expect(created.hookRuns.single.command, '/repo/coder.json');
      expect(created.hookRuns.single.stderr, contains('broken'));
      expect(hooks.invocations, isEmpty);
    });

    test('does not rerun setup hooks for an existing worktree', () async {
      projectSettings.settings = const ProjectSettingsDto(
        setup: <String>['npm ci'],
      );

      await createManaged();
      final repeated = await createManaged();

      expect(hooks.invocations, hasLength(1));
      expect(repeated.hookRuns, isEmpty);
    });

    test(
      'runs teardown hooks before the checkout is removed',
      () async {
        projectSettings.settings = const ProjectSettingsDto(
          teardown: <String>['docker compose down'],
        );
        final created = await createManaged();
        log.clear();

        final archived = await service.archive('managed-1', force: true);

        expect(log, <String>[
          'hook:docker compose down',
          'git:remove:force',
        ]);
        expect(
          archived.hookRuns.single.phase,
          WorktreeHookPhase.teardown,
        );
        expect(archived.worktree.archivedAt?.toUtc(), _FixedClock.now);
        expect(
          hooks.invocations.single.workingDirectory,
          created.worktree.path,
        );
      },
      tags: const <String>['feature_test__worktree_lifecycle__unit'],
    );

    test('archives even when a teardown hook fails', () async {
      projectSettings.settings = const ProjectSettingsDto(
        teardown: <String>['docker compose down'],
      );
      hooks.failures['docker compose down'] = const CommandResult(
        exitCode: 1,
        stdout: '',
        stderr: 'no such service',
      );
      await createManaged();

      final archived = await service.archive('managed-1', force: true);

      expect(archived.hookRuns.single.exitCode, 1);
      expect(archived.worktree.archivedAt, isNotNull);
      expect(git.removed, hasLength(1));
    });

    test('does not run teardown hooks for a refused archive', () async {
      projectSettings.settings = const ProjectSettingsDto(
        teardown: <String>['docker compose down'],
      );
      await createManaged();
      git.state = const GitWorktreeState(dirty: true);

      await expectLater(
        service.archive('managed-1', force: false),
        throwsA(isA<StateError>()),
      );
      expect(hooks.invocations, isEmpty);
    });
  });

  group('process Git workspace gateway', () {
    test(
      'discovers repositories, worktrees, and checkout branch state',
      () async {
        final commands = _FakeCommandRunner(<CommandResult>[
          _result(stdout: '/repo\n'),
          _result(stdout: _worktreePorcelain),
          _result(
            stdout:
                'refs/heads/main\u0000main\u0000*\u0000\n'
                'refs/heads/topic\u0000topic\u0000\u0000\n'
                'refs/remotes/origin/HEAD\u0000origin/HEAD'
                '\u0000\u0000origin/main\n'
                'refs/remotes/origin/main\u0000origin/main\u0000\u0000\n',
          ),
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
            const GitBranchDto(
              name: 'origin/main',
              current: false,
              checkedOut: false,
              isRemote: true,
              isDefault: true,
            ),
          ],
        );
        expect(
          commands.invocations[2].arguments,
          containsAll(<String>['refs/heads', 'refs/remotes']),
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
          _result(),
          _result(exitCode: 1, stderr: 'status failed'),
        ]);
        final gateway = ProcessGitWorkspaceGateway(commands);

        await gateway.removeWorktree('/repo', '/managed/topic');
        expect(
          commands.invocations.first.arguments,
          <String>['worktree', 'remove', '/managed/topic'],
        );
        await gateway.removeWorktree('/repo', '/managed/topic', force: true);
        expect(
          commands.invocations[1].arguments,
          <String>['worktree', 'remove', '--force', '/managed/topic'],
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

final class _FakeProjectSettings implements ProjectSettingsStore {
  ProjectSettingsDto settings = const ProjectSettingsDto();
  FormatException? loadFailure;
  final List<ProjectSettingsDto> saved = <ProjectSettingsDto>[];

  @override
  String sourcePath(String rootPath) => '$rootPath/coder.json';

  @override
  Future<ProjectSettingsDto> load(String rootPath) async {
    if (loadFailure case final failure?) throw failure;
    return settings;
  }

  @override
  Future<void> save(String rootPath, ProjectSettingsDto value) async {
    saved.add(value);
    settings = value;
  }
}

final class _HookInvocation {
  const _HookInvocation(this.command, this.workingDirectory, this.environment);

  final String command;
  final String workingDirectory;
  final Map<String, String> environment;
}

final class _FakeHookRunner implements WorktreeHookRunner {
  _FakeHookRunner(this.log);

  final List<String> log;
  final List<_HookInvocation> invocations = <_HookInvocation>[];
  final Map<String, CommandResult> failures = <String, CommandResult>{};

  @override
  Future<CommandResult> run(
    String command, {
    required String workingDirectory,
    required Map<String, String> environment,
  }) async {
    log.add('hook:$command');
    invocations.add(_HookInvocation(command, workingDirectory, environment));
    return failures[command] ??
        const CommandResult(exitCode: 0, stdout: '', stderr: '');
  }
}

final class _FakeGitGateway implements GitWorkspaceGateway {
  _FakeGitGateway([List<String>? log]) : log = log ?? <String>[];

  /// Shared call log used to assert hook ordering against Git operations.
  final List<String> log;

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
        GitBranchDto(
          name: 'origin/main',
          current: false,
          checkedOut: false,
          isRemote: true,
          isDefault: true,
        ),
      ];

  /// Remote names reported to the service.
  List<String> remotes = <String>['origin'];

  /// Remotes fetched through this gateway, in call order.
  final List<String> fetched = <String>[];

  /// Whether the next fetch reports a network failure.
  bool fetchSucceeds = true;

  @override
  Future<List<String>> listRemotes(String repositoryRoot) async => remotes;

  @override
  Future<bool> fetchRemote(String repositoryRoot, String remote) async {
    fetched.add(remote);
    return fetchSucceeds;
  }

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
  Future<void> removeWorktree(
    String repositoryRoot,
    String path, {
    bool force = false,
  }) async {
    log.add('git:remove${force ? ':force' : ''}');
    removed.add(path);
  }
}
