import 'dart:async';

import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../support/fake_coder_api.dart';
import '../support/router_harness.dart';

/// Navigation-verb behaviour: pushed tasks pop back, lateral moves do not
/// change the stack, and deep links still close to a sensible destination.
void main() {
  final now = DateTime.utc(2026, 8, 5);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
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
    isCoderOwned: false,
    createdAt: now,
  );
  SessionDto session(String id, String title) => SessionDto(
    id: id,
    worktreeId: worktree.id,
    title: title,
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  final worktreeLocation = WorktreeRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: worktree.id,
  ).location;

  FakeCoderApi apiWith(List<SessionDto> sessions) => FakeCoderApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[worktree],
    agents: sessions,
  );

  Future<void> useDesktop(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
      await tester.tap(find.text('General'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects'));
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
}
