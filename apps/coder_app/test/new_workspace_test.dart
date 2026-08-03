import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/workspace/new_workspace_pane.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

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

      final projects = collectProjects(state);
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
    'without a project the composer explains what to do first',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = await _pump(tester, FakeCoderApi());
      addTearDown(router.dispose);

      expect(find.text('먼저 프로젝트를 추가하세요.'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
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
}

HostRuntimeSnapshot _host(String id, String label) => HostRuntimeSnapshot(
  id: id,
  label: label,
  kind: HostKind.remote,
  status: HostRuntimeStatus.online,
);

Future<GoRouter> _pump(WidgetTester tester, FakeCoderApi api) async {
  final router = GoRouter(
    initialLocation: const WorkspaceHomeRoute(compose: true).location,
    routes: $appRoutes,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appServicesProvider.overrideWithValue(fakeAppServices(api))],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
