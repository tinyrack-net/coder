import 'dart:async';

import 'package:app/src/app/presentation/settings_page.dart';
import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/models/presentation/pages/model_settings_page.dart';
import 'package:app/src/features/permissions/presentation/pages/permission_settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_tinest_api.dart';
import '../support/router_harness.dart';

/// Navigation-verb behaviour: pushed tasks pop back, lateral moves do not
/// change the stack, and deep links still close to a sensible destination.
void main() {
  final now = DateTime.utc(2026, 8, 5);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Tinest',
    rootPath: '/repos/tinest',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final worktree = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    kind: WorktreeKind.checkout,
    isTinestOwned: false,
    createdAt: now,
  );
  SessionDto session(String id, String title) => SessionDto(
    id: id,
    worktreeId: worktree.id,
    title: title,
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );
  final worktreeLocation = WorktreeRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: worktree.id,
  ).location;

  FakeTinestApi apiWith(List<SessionDto> sessions) => FakeTinestApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[worktree],
    agents: sessions,
  );

  Future<void> useDesktop(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);
  }

  Future<void> useMobile(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 780);
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'system Back closes the new-workspace composer to the workspace list',
    (tester) async {
      await useMobile(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[]),
        initialLocation: const WorkspaceHomeRoute().location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.byKey(const ValueKey('workspace-new-button')));
      await tester.pumpAndSettle();
      expect(
        currentLocation(router),
        const WorkspaceHomeRoute(compose: true).location,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(currentLocation(router), const WorkspaceHomeRoute().location);
      expect(
        find.byKey(const ValueKey('workspace-new-button')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'system Back closes a directly opened mobile session to the workspace list',
    (tester) async {
      await useMobile(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[session('session', 'Route session')]),
        initialLocation: SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
          sessionId: 'session',
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.text('Route session'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(currentLocation(router), const WorkspaceHomeRoute().location);
      expect(
        find.byKey(const ValueKey('workspace-new-button')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'system Back closes a session selected from the mobile workspace list',
    (tester) async {
      await useMobile(tester);
      final homeWorkspace = workspace.copyWith(
        id: 'home',
        name: 'Home',
        rootPath: '/home/user',
        kind: WorkspaceKind.home,
      );
      final homeWorktree = worktree.copyWith(
        id: 'home-checkout',
        workspaceId: homeWorkspace.id,
        name: 'Home',
        path: homeWorkspace.rootPath,
        branch: null,
        kind: WorktreeKind.directory,
      );
      final homeSession = session('home-session', 'Home session').copyWith(
        worktreeId: homeWorktree.id,
      );
      final router = await pumpRoutedApp(
        tester,
        FakeTinestApi(
          workspaces: <WorkspaceDto>[homeWorkspace],
          worktrees: <WorktreeDto>[homeWorktree],
          agents: <SessionDto>[homeSession],
        ),
        initialLocation: const WorkspaceHomeRoute().location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.text('Home session'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), contains('/sessions/home-session'));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(currentLocation(router), const WorkspaceHomeRoute().location);
      expect(
        find.byKey(const ValueKey('workspace-new-button')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'system Back closes a restored mobile worktree to the workspace list',
    (tester) async {
      await useMobile(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[]),
        initialLocation: const WorkspaceHomeRoute().location,
        store: MemoryAppStore(
          settings: AppSettings(
            embeddedDaemonEnabled: false,
            lastWorktree: WorkspaceSelection(
              hostId: 'server',
              workspaceId: workspace.id,
              worktreeId: worktree.id,
            ),
          ),
        ),
      );
      addTearDown(router.dispose);

      expect(currentLocation(router), worktreeLocation);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(currentLocation(router), const WorkspaceHomeRoute().location);
      expect(
        find.byKey(const ValueKey('workspace-new-button')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  Future<void> useTwoPane(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 900);
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'settings opened from a worktree closes back to that worktree',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[session('session', 'Route session')]),
        initialLocation: worktreeLocation,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      expect(
        currentLocation(router),
        const ProviderSettingsRoute(hostId: 'server').location,
      );
      expect(router.canPop(), isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), worktreeLocation);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'settings entered by deep link closes to the workspace home',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[]),
        initialLocation: const GeneralSettingsRoute().location,
      );
      addTearDown(router.dispose);

      expect(router.canPop(), isFalse);
      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), const WorkspaceHomeRoute().location);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'switching settings categories keeps the entry screen on the stack',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[session('session', 'Route session')]),
        initialLocation: worktreeLocation,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('일반'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('프로젝트'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), const ProjectSettingsRoute().location);
      expect(router.canPop(), isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), worktreeLocation);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'two-pane settings category changes keep the shell mounted',
    (tester) async {
      await useTwoPane(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[session('session', 'Route session')]),
        initialLocation: worktreeLocation,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('settings-category-row-model')),
      );
      await tester.pumpAndSettle();
      expect(
        currentLocation(router),
        const ModelSettingsRoute().location,
      );

      final modelShell = find.byType(UnifiedSettingsPage);
      final modelState = tester.state<State<UnifiedSettingsPage>>(modelShell);
      final modelSidebar = find.descendant(
        of: modelShell,
        matching: find.byKey(
          const ValueKey<String>('settings-sidebar-surface'),
        ),
      );
      final modelSidebarElement = tester.element(modelSidebar);
      final modelSidebarRect = tester.getRect(modelSidebar);
      final modelRoute = ModalRoute.of(
        tester.element(find.byType(ModelSettingsPage)),
      );
      final modelPage = tester
          .widget<Navigator>(find.byType(Navigator))
          .pages
          .last;
      expect(modelRoute?.animation?.status, AnimationStatus.completed);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('settings-category-row-permission'),
        ),
      );
      await tester.pump();
      await tester.pump(TRMotion.slow ~/ 2);

      expect(
        currentLocation(router),
        const PermissionSettingsRoute().location,
      );
      final permissionShell = find.ancestor(
        of: find.byType(PermissionSettingsPage),
        matching: find.byType(UnifiedSettingsPage),
      );
      expect(permissionShell, findsOneWidget);
      expect(
        tester.state<State<UnifiedSettingsPage>>(permissionShell),
        same(modelState),
        reason: 'a category replacement must preserve the settings shell',
      );
      final permissionRoute = ModalRoute.of(
        tester.element(find.byType(PermissionSettingsPage)),
      );
      expect(permissionRoute, same(modelRoute));
      expect(permissionRoute?.animation?.status, AnimationStatus.completed);
      final permissionPage = tester
          .widget<Navigator>(find.byType(Navigator))
          .pages
          .last;
      expect(permissionPage.runtimeType, modelPage.runtimeType);
      expect(permissionPage.key, modelPage.key);
      expect(permissionPage.key, const ValueKey<String>('settings-shell'));

      final permissionSidebar = find.descendant(
        of: permissionShell,
        matching: find.byKey(
          const ValueKey<String>('settings-sidebar-surface'),
        ),
      );
      expect(tester.element(permissionSidebar), same(modelSidebarElement));
      expect(tester.getRect(permissionSidebar), modelSidebarRect);

      expect(find.byType(ModelSettingsPage), findsNothing);
      expect(find.byType(PermissionSettingsPage), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(ModelSettingsPage), findsNothing);
      expect(find.byType(PermissionSettingsPage), findsOneWidget);

      expect(router.canPop(), isTrue);
      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), worktreeLocation);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'selecting a session keeps the workspace page mounted',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[
          session('one', 'Session one'),
          session('two', 'Session two'),
        ]),
        initialLocation: SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
          sessionId: 'one',
        ).location,
      );
      addTearDown(router.dispose);

      final before = tester.state<State<WorkspacePage>>(
        find.byType(WorkspacePage),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-all-sessions-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Session two'));
      await tester.pumpAndSettle();

      expect(currentLocation(router), contains('two'));
      expect(
        tester.state<State<WorkspacePage>>(find.byType(WorkspacePage)),
        same(before),
      );
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'a later session location opens that session',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[
          session('one', 'Session one'),
          session('two', 'Session two'),
        ]),
        initialLocation: SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
          sessionId: 'one',
        ).location,
      );
      addTearDown(router.dispose);
      expect(find.text('Session two'), findsNothing);

      // Selecting a session replaces the location instead of pushing, so the
      // page survives and has to react to the new session itself.
      unawaited(
        router.replace<void>(
          SessionRoute(
            hostId: 'server',
            workspaceId: workspace.id,
            worktreeId: worktree.id,
            sessionId: 'two',
          ).location,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session two'), findsWidgets);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'adding a remote daemon closes back to the daemon list',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[]),
        initialLocation: const DaemonSettingsRoute().location,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey<String>('app-settings-add-remote')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), const ConnectDaemonRoute().location);
      expect(router.canPop(), isTrue);

      await tester.tap(
        find.byKey(const ValueKey<String>('remote-host-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), const DaemonSettingsRoute().location);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'reopening settings from the shell does not stack duplicates',
    (tester) async {
      await useDesktop(tester);
      final router = await pumpRoutedApp(
        tester,
        apiWith(<SessionDto>[]),
        initialLocation: const WorkspaceHomeRoute().location,
      );
      addTearDown(router.dispose);

      openSettingsTask(router);
      await tester.pumpAndSettle();
      openSettingsTask(router);
      await tester.pumpAndSettle();
      expect(
        currentLocation(router),
        const SettingsHomeRoute().location,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), const WorkspaceHomeRoute().location);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );

  testWidgets(
    'a delayed workspace restore cannot replace an open settings task',
    (tester) async {
      await useDesktop(tester);
      final catalogGate = Completer<void>();
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[worktree],
        workspaceCatalogGate: catalogGate.future,
      );
      final store = MemoryAppStore(
        settings: AppSettings(
          embeddedDaemonEnabled: false,
          lastWorktree: WorkspaceSelection(
            hostId: 'server',
            workspaceId: workspace.id,
            worktreeId: worktree.id,
          ),
        ),
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: const WorkspaceHomeRoute().location,
        store: store,
        settle: false,
      );
      addTearDown(router.dispose);

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      for (var frame = 0; frame < 4; frame += 1) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(currentLocation(router), const DaemonSettingsRoute().location);

      catalogGate.complete();
      await tester.pumpAndSettle();

      expect(currentLocation(router), const DaemonSettingsRoute().location);
      expect(find.byType(Navigator), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('일반'));
      await tester.pumpAndSettle();
      expect(currentLocation(router), const GeneralSettingsRoute().location);
      expect(find.byType(Navigator), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('settings-back-button')),
      );
      await tester.pumpAndSettle();
      expect(currentLocation(router), const WorkspaceHomeRoute().location);
    },
    tags: const <String>['feature_test__app_navigation__widget'],
  );
}
