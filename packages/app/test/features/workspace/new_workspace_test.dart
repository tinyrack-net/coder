import 'dart:async';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/presentation/new_workspace_pane.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/workspace/application/workspace_controller.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:client/client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

/// The implicit home workspace a daemon provisions for project-less sessions.
final _home = WorkspaceDto(
  id: 'home',
  name: 'user',
  rootPath: '/home/user',
  kind: WorkspaceKind.home,
  createdAt: DateTime.utc(2026, 8, 3),
);

final _homeCheckout = WorktreeDto(
  id: 'home-checkout',
  workspaceId: _home.id,
  name: _home.name,
  path: _home.rootPath,
  kind: WorktreeKind.directory,
  isTinestOwned: false,
  createdAt: DateTime.utc(2026, 8, 3),
);

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Tinest',
    rootPath: '/repos/tinest',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    kind: WorktreeKind.checkout,
    isTinestOwned: false,
    createdAt: now,
  );

  test(
    'catalogs from every daemon flatten into sorted projects',
    () {
      final state = UnifiedWorkspaceCatalogState(
        hosts: <String, HostRuntimeSnapshot>{
          'b-host': _host('b-host', 'Beta daemon'),
          'a-host': _host('a-host', 'Alpha daemon'),
        },
        catalogs: <String, WorkspaceCatalogDto>{
          'b-host': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[workspace],
            worktrees: <WorktreeDto>[checkout],
          ),
          'a-host': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[
              workspace.copyWith(id: 'zulu', name: 'Zulu'),
              workspace.copyWith(id: 'alpha', name: 'Alpha'),
            ],
            worktrees: <WorktreeDto>[
              checkout.copyWith(id: 'alpha-main', workspaceId: 'alpha'),
            ],
          ),
        },
      );

      final projects = collectProjects(testL10n, state);
      expect(
        projects.map((item) => '${item.hostLabel}/${item.workspace.name}'),
        <String>[
          'Alpha daemon/Alpha',
          'Alpha daemon/Zulu',
          'Beta daemon/Tinest',
        ],
      );
      expect(projects.first.worktrees.single.id, 'alpha-main');
      expect(projects[1].worktrees, isEmpty);
      expect(
        collectProjects(
          testL10n,
          const UnifiedWorkspaceCatalogState(
            hosts: <String, HostRuntimeSnapshot>{},
            catalogs: <String, WorkspaceCatalogDto>{},
          ),
        ),
        isEmpty,
      );
    },
    tags: const <String>['feature_test__workspace_catalog__unit'],
  );

  testWidgets(
    'new workspace follows the application UI density boundary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1100, 900);
      final router = await _pump(
        tester,
        FakeTinestApi(
          workspaces: <WorkspaceDto>[_home],
          worktrees: <WorktreeDto>[_homeCheckout],
        ),
      );
      addTearDown(router.dispose);

      final settings = find.byKey(
        const ValueKey<String>('session-composer-settings'),
      );
      final agent = find.byKey(
        const ValueKey<String>('session-composer-agent'),
      );
      final model = find.byKey(
        const ValueKey<String>('session-composer-model'),
      );

      expect(settings, findsNothing);
      expect(agent, findsOneWidget);
      expect(model, findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(768, 900));
      tester.view.physicalSize = const Size(768, 900);
      await tester.pumpAndSettle();
      expect(settings, findsNothing);
      expect(agent, findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(767, 900));
      tester.view.physicalSize = const Size(767, 900);
      await tester.pumpAndSettle();
      expect(settings, findsOneWidget);
      expect(agent, findsNothing);
      expect(model, findsNothing);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'a new worktree is created from the first prompt',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');

      expect(find.text('New workspace'), findsWidgets);
      expect(find.text('Tinest'), findsWidgets);
      expect(find.byKey(const ValueKey('new-workspace-worktree')), findsOne);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdWorktrees.single;
      expect(created.branchName, 'fix-the-parser');
      expect(created.mode, WorktreeCreateMode.newBranch);
      // The name is derived from the prompt, so the daemon resolves any
      // collision: it is the only party that sees a branch an archived
      // worktree left behind.
      expect(created.branchNaming, WorktreeBranchNaming.derive);
      expect(api.createdSessions.single.title, 'Fix the parser');
      expect(api.startedPrompts, <String>['Fix the parser']);
      expect(
        router.routeInformationProvider.value.uri.path,
        contains('/sessions/'),
      );
    },
    tags: const <String>[
      'feature_test__worktree_lifecycle__widget',
      'feature_test__session_lifecycle__widget',
    ],
  );

  testWidgets(
    'an existing worktree starts a session without creating one',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');

      await tester.tap(find.byKey(const ValueKey('new-workspace-worktree')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('new-workspace-worktree-checkout')),
      );
      await tester.pumpAndSettle();
      expect(find.text('main'), findsWidgets);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Run the tests',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(api.createdWorktrees, isEmpty);
      expect(api.createdSessions.single.worktreeId, checkout.id);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'submitting narrates worktree creation instead of freezing the composer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      )..createWorktreeGate = Completer<void>();
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pump();

      // The wait is narrated: a progress row names the running step while
      // the daemon checks out the worktree.
      expect(
        find.byKey(const ValueKey<String>('new-workspace-progress')),
        findsOneWidget,
      );
      expect(find.text('워크트리 생성 중…'), findsOneWidget);

      api.createWorktreeGate!.complete();
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        contains('/sessions/'),
      );
    },
    tags: const <String>['feature_test__workspace_async_loading__widget'],
  );

  testWidgets(
    'a failed worktree keeps the user in the composer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        createWorktreeError: const TinestClientException(
          'A worktree already uses the generated path.',
          code: 'request_failed',
        ),
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      // An unrecognized code has no localized wording, so the daemon's own
      // message is the best available explanation and is shown verbatim.
      expect(find.textContaining('A worktree already uses'), findsOneWidget);
      expect(api.createdSessions, isEmpty);
      expect(
        router.routeInformationProvider.value.uri.path,
        isNot(contains('/sessions/')),
      );
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'a typed daemon failure is explained, diagnosable, and recoverable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        createWorktreeError: const TinestClientException(
          'Internal daemon error.',
          code: RpcErrorCodes.internalError,
          details: <String, dynamic>{
            'method': 'workspaces.createWorktree',
            'errorType': 'StateError',
            'traceId': 'trace-1',
          },
        ),
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      // The raw daemon sentence is replaced by a localized explanation, and
      // the trace id that points at the daemon log record is on screen.
      final alert = find.byKey(const ValueKey<String>('new-workspace-error'));
      expect(alert, findsOneWidget);
      expect(find.text('세션을 시작하지 못했습니다'), findsOneWidget);
      expect(find.textContaining('Internal daemon error.'), findsNothing);
      expect(find.textContaining('traceId: trace-1'), findsOneWidget);
      expect(
        find.descendant(
          of: alert,
          matching: find.byKey(const ValueKey<String>('client-error-copy')),
        ),
        findsOneWidget,
      );

      // The composer is released, so once the daemon recovers the same
      // submission goes through without restarting the app.
      expect(api.createdSessions, isEmpty);
      api.createWorktreeError = null;
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();
      expect(api.createdWorktrees, hasLength(1));
      expect(
        router.routeInformationProvider.value.uri.path,
        contains('/sessions/'),
      );
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'a failed setup hook reports output without starting a session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api =
          FakeTinestApi(
              workspaces: <WorkspaceDto>[workspace],
              worktrees: <WorktreeDto>[checkout],
            )
            ..createWorktreeHookRuns = const <WorktreeHookRunDto>[
              WorktreeHookRunDto(
                phase: WorktreeHookPhase.setup,
                command: 'dart pub get',
                exitCode: 69,
                stdout: '',
                stderr: 'dependency unavailable',
              ),
            ];
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix setup cleanup',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Setup 실패'), findsOneWidget);
      expect(find.textContaining('dependency unavailable'), findsOneWidget);
      expect(api.createdSessions, isEmpty);
      expect(
        router.routeInformationProvider.value.uri.path,
        isNot(contains('/sessions/')),
      );
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'the base branch defaults to the latest remote and lists both scopes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');

      expect(find.text('origin/main'), findsOneWidget);

      final chip = find.byKey(const ValueKey('new-workspace-branch'));
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('new-workspace-branch-origin/main')),
        findsOne,
      );
      expect(
        find.byKey(const ValueKey('new-workspace-branch-feature')),
        findsOne,
      );
      await tester.tap(
        find.byKey(const ValueKey('new-workspace-branch-feature')),
      );
      await tester.pumpAndSettle();
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();
      expect(api.createdWorktrees.single.baseBranch, 'feature');
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'a chip menu opens against the chip, not the pane corner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      final chip = find.byKey(const ValueKey('new-workspace-project'));
      final chipRect = tester.getRect(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      final menuRect = tester.getRect(
        find.byKey(const ValueKey('new-workspace-project-add')),
      );
      expect(menuRect.left, greaterThan(chipRect.left - 40));
      expect(menuRect.left, lessThan(chipRect.right));
      expect(menuRect.top, greaterThan(chipRect.top - 40));
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'mobile targets stack at the leading edge and open in sheets above a '
    'bottom-aligned composer',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 780);
      addTearDown(tester.view.reset);
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      final project = find.byKey(const ValueKey('new-workspace-project'));
      await tester.tap(project);
      await tester.pumpAndSettle();
      expect(find.byType(TRDrawer), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('new-workspace-project-server\u0000workspace'),
        ),
      );
      await tester.pumpAndSettle();

      final worktree = find.byKey(const ValueKey('new-workspace-worktree'));
      final branch = find.byKey(const ValueKey('new-workspace-branch'));
      expect(tester.widget(project), isA<TRSelect<Object?>>());
      expect(tester.widget(worktree), isA<TRSelect<Object?>>());
      expect(tester.widget(branch), isA<TRSelect<Object?>>());
      final projectRect = tester.getRect(project);
      final worktreeRect = tester.getRect(worktree);
      final branchRect = tester.getRect(branch);
      expect(projectRect.left, closeTo(worktreeRect.left, 0.01));
      expect(worktreeRect.left, closeTo(branchRect.left, 0.01));
      expect(projectRect.width, closeTo(worktreeRect.width, 0.01));
      expect(worktreeRect.width, closeTo(branchRect.width, 0.01));
      expect(projectRect.bottom, lessThan(worktreeRect.top));
      expect(worktreeRect.bottom, lessThan(branchRect.top));

      final composer = tester.getRect(find.byType(SessionComposer));
      expect(composer.bottom, 780);
      expect(
        tester.getTopLeft(find.text('New workspace').first).dy,
        greaterThan(250),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(worktree);
      await tester.pumpAndSettle();
      expect(find.byType(TRDrawer), findsOneWidget);
      expect(
        find.byKey(const ValueKey('new-workspace-worktree-checkout')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'activating a hovered project chip dismisses its tooltip',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      final chip = find.byKey(const ValueKey('new-workspace-project'));
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getCenter(chip));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text('프로젝트 선택'), findsOneWidget);

      final chipCenter = tester.getCenter(chip);
      await pointer.down(chipCenter);
      await pointer.up();
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('new-workspace-project-add')),
        findsOneWidget,
      );
      expect(find.text('프로젝트 선택'), findsNothing);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'without a project the composer explains what to do first',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = await _pump(tester, FakeTinestApi());
      addTearDown(router.dispose);

      expect(find.text('먼저 프로젝트를 추가하세요.'), findsOneWidget);
      expect(
        tester
            .widget<TRIconButton>(
              find.byKey(const ValueKey('session-composer-send')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-workspace-project-add')), findsOne);
    },
    tags: const <String>['feature_test__workspace_registration__widget'],
  );

  testWidgets(
    'a session starts in the home folder when no project is registered',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[_home],
        worktrees: <WorktreeDto>[_homeCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      // The home workspace is not a project, so it never appears as one.
      expect(find.text('먼저 프로젝트를 추가하세요.'), findsNothing);
      await _selectModel(tester);
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Tidy my notes',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(api.createdWorktrees, isEmpty);
      expect(api.createdSessions.single.worktreeId, _homeCheckout.id);
      expect(api.createdSessions.single.title, 'Tidy my notes');
      expect(
        router.routeInformationProvider.value.uri.path,
        contains('/sessions/'),
      );
    },
    tags: const <String>['feature_test__session_home__widget'],
  );

  testWidgets(
    'no project is the default even when projects exist, and is switchable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace, _home],
        worktrees: <WorktreeDto>[checkout, _homeCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      // Nothing was picked, so the composer stays out of every project rather
      // than silently adopting whichever one sorts first.
      expect(find.text('프로젝트 없음 (홈 폴더)'), findsWidgets);
      expect(
        find.byKey(const ValueKey('new-workspace-worktree')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tinest ·').last);
      await tester.pumpAndSettle();

      expect(find.text('Tinest'), findsWidgets);
      expect(find.byKey(const ValueKey('new-workspace-worktree')), findsOne);
    },
    tags: const <String>['feature_test__session_home__widget'],
  );

  testWidgets(
    'a directory project skips Git targets and starts on its checkout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final directory = workspace.copyWith(
        id: 'directory',
        name: 'Plain folder',
        rootPath: '/repos/plain',
        kind: WorkspaceKind.directory,
      );
      final directoryCheckout = checkout.copyWith(
        id: 'directory-checkout',
        workspaceId: directory.id,
        name: directory.name,
        path: directory.rootPath,
        branch: null,
        kind: WorktreeKind.directory,
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[directory],
        worktrees: <WorktreeDto>[directoryCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Plain folder');

      expect(find.text('Plain folder'), findsWidgets);
      expect(
        find.byKey(const ValueKey('new-workspace-worktree')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('new-workspace-branch')), findsNothing);
      expect(api.listedGitBranchWorkspaceIds, isEmpty);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Inspect this folder',
      );
      expect(
        tester
            .widget<TRIconButton>(
              find.byKey(const ValueKey('session-composer-send')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(api.createdWorktrees, isEmpty);
      expect(api.createdSessions.single.worktreeId, directoryCheckout.id);
      expect(api.startedPrompts, <String>['Inspect this folder']);
    },
    tags: const <String>[
      'feature_test__workspace_catalog__widget',
      'feature_test__session_lifecycle__widget',
    ],
  );

  testWidgets(
    'a directory project without its checkout cannot submit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final directory = workspace.copyWith(
        id: 'directory',
        name: 'Incomplete folder',
        rootPath: '/repos/incomplete',
        kind: WorkspaceKind.directory,
      );
      final api = FakeTinestApi(workspaces: <WorkspaceDto>[directory]);
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Incomplete folder');

      expect(find.text('프로젝트 checkout을 찾을 수 없습니다.'), findsOne);
      expect(
        tester
            .widget<TRIconButton>(
              find.byKey(const ValueKey('session-composer-send')),
            )
            .onPressed,
        isNull,
      );
      expect(api.listedGitBranchWorkspaceIds, isEmpty);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the project selector is disabled while no daemon is connected',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api, connected: false);
      addTearDown(router.dispose);

      expect(find.text('연결된 Daemon이 없습니다.'), findsNothing);
      final control = tester
          .widget<TRSelect<({String? projectKey, bool addProject})>>(
            find.byKey(const ValueKey('new-workspace-project')),
          );
      expect(control.enabled, isFalse);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the composer stays quiet while the catalog is still loading',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final gate = Completer<void>();
      final api = FakeTinestApi(workspaceCatalogGate: gate.future);
      final router = await _pump(tester, api, settle: false);
      addTearDown(router.dispose);
      await tester.pump();
      await tester.pump();

      expect(find.text('먼저 프로젝트를 추가하세요.'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('먼저 프로젝트를 추가하세요.'), findsOneWidget);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the home composer offers the commands it can carry out',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[_home],
        worktrees: <WorktreeDto>[_homeCheckout],
        commands: const <AgentCommandDto>[
          AgentCommandDto(
            id: 'review',
            name: 'review',
            description: 'Reviews the working diff.',
            source: AgentCommandSource.config,
            sourcePath: '/config/commands/review.md',
            body: 'Review the diff.',
          ),
        ],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/',
      );
      await tester.pumpAndSettle();

      // All three sources reach the one catalog: the app's own commands, the
      // daemon's authored commands, and its enabled skills.
      expect(find.text('mode'), findsOneWidget);
      expect(find.text('agents'), findsOneWidget);
      expect(find.text('review'), findsOneWidget);
      expect(find.text('commit'), findsOneWidget);
      // A session only exists once the first prompt starts one, so there is
      // nothing for `/new` to be new relative to.
      expect(find.text('new'), findsNothing);
    },
    tags: const <String>['feature_test__composer_slash_command__widget'],
  );

  testWidgets(
    'a client command typed in the home composer runs instead of sending',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[_home],
        worktrees: <WorktreeDto>[_homeCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectModel(tester);

      expect(find.text('Plan'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/mode',
      );
      await tester.pumpAndSettle();
      // Escape hands the token back so Enter submits rather than completing.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final compactSettings = find.byKey(
        const ValueKey<String>('session-composer-settings'),
      );
      if (compactSettings.evaluate().isNotEmpty) {
        await tester.tap(compactSettings);
        await tester.pumpAndSettle();
      }
      expect(find.text('Plan'), findsOneWidget);
      expect(api.createdSessions, isEmpty);
      expect(api.startedPrompts, isEmpty);
    },
    tags: const <String>['feature_test__composer_slash_command__widget'],
  );

  testWidgets(
    'a settings command from the home composer opens that screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[_home],
        worktrees: <WorktreeDto>[_homeCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/agents',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/settings/agents',
      );
      expect(api.createdSessions, isEmpty);
    },
    tags: const <String>['feature_test__composer_slash_command__widget'],
  );

  testWidgets(
    'the home composer completes a file mention from the home folder',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[_home],
        worktrees: <WorktreeDto>[_homeCheckout],
        files: <String, List<String>>{
          _homeCheckout.id: <String>['notes/todo.md'],
        },
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'read @todo',
      );
      await tester.pumpAndSettle();
      expect(find.text('notes/todo.md'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TRTextField>(
              find.byKey(const ValueKey('session-composer-input')),
            )
            .controller!
            .text,
        'read @notes/todo.md ',
      );
      expect(api.startedPrompts, isEmpty);
    },
    tags: const <String>['feature_test__composer_file_mention__widget'],
  );

  testWidgets(
    'a project whose checkout does not exist yet offers no file mentions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        files: <String, List<String>>{
          checkout.id: <String>['lib/parser.dart'],
        },
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectProject(tester, 'Tinest');
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'read @parser',
      );
      await tester.pumpAndSettle();

      // The worktree is created on submit, so there is nothing to search yet.
      expect(find.text('lib/parser.dart'), findsNothing);
      expect(api.searchedQueries, isEmpty);

      // Commands still complete without a checkout.
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/mo',
      );
      await tester.pumpAndSettle();
      expect(find.text('mode'), findsOneWidget);
    },
    tags: const <String>['feature_test__composer_file_mention__widget'],
  );
}

HostRuntimeSnapshot _host(String id, String label) => HostRuntimeSnapshot(
  id: id,
  label: label,
  kind: HostKind.remote,
  status: HostRuntimeStatus.online,
);

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeTinestApi api, {
  bool connected = true,
  bool settle = true,
}) async {
  final logicalSize = tester
      .binding
      .renderViews
      .single
      .configuration
      .logicalConstraints
      .biggest;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: const WorkspaceHomeRoute(compose: true).location,
    routes: $appRoutes,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, connected: connected),
        ),
      ],
      child: MaterialApp.router(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: router,
        builder: (context, child) => TinestUiDensity(
          child: TRTooltipProvider(child: child!),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

/// Picks [name] in the project chip menu.
///
/// The composer starts out in no project, so a test that exercises a project
/// has to choose it the way the user does.
Future<void> _selectProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('$name ·').last);
  await tester.pumpAndSettle();
}

Future<void> _selectModel(WidgetTester tester) async {
  final direct = find.byKey(const ValueKey<String>('session-composer-model'));
  if (direct.evaluate().isNotEmpty) {
    await tester.tap(direct);
  } else {
    await tester.tap(
      find.byKey(const ValueKey<String>('session-composer-settings')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('session-composer-settings-model')),
    );
  }
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
  );
  await tester.pumpAndSettle();
  if (find
      .byKey(const ValueKey<String>('session-composer-settings-sheet'))
      .evaluate()
      .isNotEmpty) {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }
}
