import 'dart:async';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/workspace/new_workspace_pane.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';

import 'support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
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
    isCoderOwned: false,
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
          'Beta daemon/Coder',
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
    'a new worktree is created from the first prompt',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      expect(find.text('New workspace'), findsWidgets);
      expect(find.text('Coder'), findsWidgets);
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
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

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
    'a failed worktree keeps the user in the composer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        createWorktreeError: const CoderClientException(
          'A worktree already uses the generated path.',
          code: 'request_failed',
        ),
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);
      await _selectModel(tester);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Fix the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('A worktree already uses'),
        findsOneWidget,
      );
      expect(api.createdSessions, isEmpty);
      expect(
        router.routeInformationProvider.value.uri.path,
        isNot(contains('/sessions/')),
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
          FakeCoderApi(
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
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

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
      final api = FakeCoderApi(
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
    'activating a hovered project chip dismisses its tooltip',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
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
      final router = await _pump(tester, FakeCoderApi());
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
      expect(
        find.byKey(const ValueKey('new-workspace-project-add')),
        findsOne,
      );
    },
    tags: const <String>['feature_test__workspace_registration__widget'],
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
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[directory],
        worktrees: <WorktreeDto>[directoryCheckout],
      );
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

      expect(find.text('Plain folder'), findsWidgets);
      expect(
        find.byKey(const ValueKey('new-workspace-worktree')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('new-workspace-branch')),
        findsNothing,
      );
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
      final api = FakeCoderApi(workspaces: <WorkspaceDto>[directory]);
      final router = await _pump(tester, api);
      addTearDown(router.dispose);

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
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final router = await _pump(tester, api, connected: false);
      addTearDown(router.dispose);

      expect(find.text('연결된 Daemon이 없습니다.'), findsNothing);
      final control = tester.widget<TRButton>(
        find.byKey(const ValueKey('new-workspace-project')),
      );
      expect(control.onPressed, isNull);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the composer stays quiet while the catalog is still loading',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final gate = Completer<void>();
      final api = FakeCoderApi(workspaceCatalogGate: gate.future);
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
}

HostRuntimeSnapshot _host(String id, String label) => HostRuntimeSnapshot(
  id: id,
  label: label,
  kind: HostKind.remote,
  status: HostRuntimeStatus.online,
);

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeCoderApi api, {
  bool connected = true,
  bool settle = true,
}) async {
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
        builder: (context, child) => TRTooltipProvider(child: child!),
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

Future<void> _selectModel(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('session-composer-model')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
  );
  await tester.pumpAndSettle();
}
