import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/workspace/workspace_sidebar.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  WorkspaceDto workspace(String id, String name) => WorkspaceDto(
    id: id,
    name: name,
    rootPath: '/repos/$id',
    kind: WorkspaceKind.git,
    createdAt: now,
  );

  WorktreeDto worktree(String id, String workspaceId, String branch) =>
      WorktreeDto(
        id: id,
        workspaceId: workspaceId,
        name: branch,
        path: '/repos/$workspaceId',
        branch: branch,
        head: 'abc',
        kind: WorktreeKind.checkout,
        isCoderOwned: false,
        createdAt: now,
      );

  HostRuntimeSnapshot host(
    String id,
    String label, {
    HostRuntimeStatus status = HostRuntimeStatus.online,
  }) => HostRuntimeSnapshot(
    id: id,
    label: label,
    kind: HostKind.remote,
    status: status,
    endpoint: HostEndpoint(
      websocketUri: Uri.parse('ws://127.0.0.1:7337/ws'),
    ),
    // `connected` requires an API, so only online hosts get one.
    api: status == HostRuntimeStatus.online ? FakeCoderApi() : null,
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<HostRuntimeSnapshot> hosts,
    required Map<String, WorkspaceCatalogDto> catalogs,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: testLightTheme,
          darkTheme: testDarkTheme,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: Scaffold(
            body: WorkspaceSidebar(
              registry: HostRegistryState(
                settings: const AppSettings(embeddedDaemonEnabled: false),
                profiles: const <RemoteDaemonProfile>[],
                runtimes: <String, HostRuntimeSnapshot>{
                  for (final item in hosts) item.id: item,
                },
              ),
              catalog: AsyncValue<UnifiedWorkspaceCatalogState>.data(
                UnifiedWorkspaceCatalogState(
                  hosts: <String, HostRuntimeSnapshot>{
                    for (final item in hosts) item.id: item,
                  },
                  catalogs: catalogs,
                ),
              ),
              selected: null,
              onNewWorkspace: () {},
              onSelect: (_) {},
              onOpenDaemonSettings: () {},
              onArchivedSelection: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'workspaces from every daemon share one flat list sorted by name',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final zed = workspace('zed', 'Zed');
      final alpha = workspace('alpha', 'Alpha');
      await pump(
        tester,
        hosts: <HostRuntimeSnapshot>[
          host('first', 'First daemon'),
          host('second', 'Second daemon'),
        ],
        catalogs: <String, WorkspaceCatalogDto>{
          'first': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[zed],
            worktrees: <WorktreeDto>[worktree('zed-main', zed.id, 'main')],
          ),
          'second': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[alpha],
            worktrees: <WorktreeDto>[worktree('alpha-main', alpha.id, 'main')],
          ),
        },
      );

      // No daemon tree level: each daemon only names its workspace's subtitle.
      expect(find.text('First daemon'), findsNothing);
      expect(find.text('Second daemon · /repos/alpha'), findsOneWidget);
      expect(find.text('First daemon · /repos/zed'), findsOneWidget);
      final names = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(TRCollapsible),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .where((data) => data == 'Alpha' || data == 'Zed')
          .toList(growable: false);
      expect(names, <String>['Alpha', 'Zed']);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'a disconnected daemon drops out of the sidebar entirely',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final online = workspace('online', 'Online repo');
      final stale = workspace('stale', 'Stale repo');
      await pump(
        tester,
        hosts: <HostRuntimeSnapshot>[
          host('up', 'Up daemon'),
          host('down', 'Down daemon', status: HostRuntimeStatus.offline),
        ],
        catalogs: <String, WorkspaceCatalogDto>{
          'up': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[online],
            worktrees: <WorktreeDto>[
              worktree('online-main', online.id, 'main'),
            ],
          ),
          // A stale catalog from before the daemon dropped must not leak.
          'down': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[stale],
            worktrees: <WorktreeDto>[worktree('stale-main', stale.id, 'main')],
          ),
        },
      );

      expect(find.text('Online repo'), findsOneWidget);
      expect(find.text('Stale repo'), findsNothing);
      expect(find.text('Down daemon'), findsNothing);
      expect(find.text(testL10n.hostStatusOffline), findsNothing);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'the sidebar explains when every configured daemon is offline',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(
        tester,
        hosts: <HostRuntimeSnapshot>[
          host('down', 'Down daemon', status: HostRuntimeStatus.offline),
        ],
        catalogs: const <String, WorkspaceCatalogDto>{},
      );

      expect(find.text(testL10n.workspaceNoConnectedDaemons), findsOneWidget);
      expect(find.text(testL10n.workspaceOpenDaemonSettings), findsOneWidget);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'a connected daemon without workspaces shows the empty workspace state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pump(
        tester,
        hosts: <HostRuntimeSnapshot>[host('up', 'Up daemon')],
        catalogs: const <String, WorkspaceCatalogDto>{
          'up': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[],
            worktrees: <WorktreeDto>[],
          ),
        },
      );

      expect(find.text(testL10n.workspaceNoWorkspaces), findsOneWidget);
      // Daemon settings are not what the user needs here.
      expect(find.text(testL10n.workspaceOpenDaemonSettings), findsNothing);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );
}
