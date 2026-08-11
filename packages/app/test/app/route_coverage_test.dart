import 'dart:async';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/presentation/workspace_page.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';

import '../support/fake_tinest_api.dart';
import '../support/localization.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
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
  final session = SessionDto(
    id: 'session',
    worktreeId: worktree.id,
    title: 'Route session',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  final api = FakeTinestApi(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[worktree],
    agents: <SessionDto>[session],
  );

  testWidgets(
    'WorkspaceHomeRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const WorkspaceHomeRoute().location,
      find.text('Workspaces'),
    ),
    tags: const <String>['route_test__workspace_home_route__widget'],
  );

  testWidgets(
    'WorktreeRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: worktree.id,
      ).location,
      find.text('새 탭'),
    ),
    tags: const <String>['route_test__worktree_route__widget'],
  );

  testWidgets(
    'SessionRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      SessionRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: worktree.id,
        sessionId: session.id,
      ).location,
      find.text('Route session'),
    ),
    tags: const <String>['route_test__session_route__widget'],
  );

  testWidgets(
    'every workspace route shares one page at desktop and mobile sizes',
    (tester) async {
      const terminal = TerminalDto(
        id: 'terminal',
        worktreeId: 'checkout',
        title: 'Route terminal',
        shell: ShellSpecDto(executable: '/bin/sh'),
        status: TerminalStatus.running,
        columns: 80,
        rows: 24,
        lastSequence: 0,
      );
      // Home, checkout, session, and terminal are one surface. A separate page
      // per path pattern would rebuild the sidebar on every lateral move.
      final locations = <String>[
        const WorkspaceHomeRoute().location,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
        ).location,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
          sessionId: session.id,
        ).location,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: worktree.id,
          terminalId: terminal.id,
        ).location,
      ];
      for (final size in <Size>[const Size(1200, 900), const Size(390, 760)]) {
        await tester.binding.setSurfaceSize(size);
        final routed = FakeTinestApi(
          workspaces: <WorkspaceDto>[workspace],
          worktrees: <WorktreeDto>[worktree],
          agents: <SessionDto>[session],
          terminals: const <TerminalDto>[terminal],
        );
        final router = GoRouter(
          initialLocation: locations.first,
          routes: $appRoutes,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appServicesProvider.overrideWithValue(fakeAppServices(routed)),
            ],
            child: MaterialApp.router(
              theme: testLightTheme,
              darkTheme: testDarkTheme,
              locale: testLocale,
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: testSupportedLocales,
              routerConfig: router,
              builder: (context, child) => TinestUiDensity(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final page = tester.state(find.byType(WorkspacePage));
        for (final location in locations.skip(1)) {
          unawaited(router.replace<void>(location));
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            Uri.parse(location).path,
          );
          expect(tester.state(find.byType(WorkspacePage)), same(page));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        router.dispose();
      }
      await tester.binding.setSurfaceSize(null);
    },
    tags: const <String>[
      'route_test__workspace_home_route__widget',
      'route_test__worktree_route__widget',
      'route_test__session_route__widget',
      'route_test__terminal_route__widget',
    ],
  );

  testWidgets(
    'SettingsHomeRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const SettingsHomeRoute().location,
      find.text('설정'),
    ),
    tags: const <String>['route_test__settings_home_route__widget'],
  );

  testWidgets(
    'DaemonCategoriesRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const DaemonCategoriesRoute(hostId: 'server').location,
      find.text('Provider'),
    ),
    tags: const <String>['route_test__daemon_categories_route__widget'],
  );

  testWidgets(
    'GeneralSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const GeneralSettingsRoute().location,
      find.text('표시 언어'),
    ),
    tags: const <String>[
      'route_test__general_settings_route__widget',
      'feature_test__settings_language__widget',
    ],
  );

  testWidgets(
    'McpSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const McpSettingsRoute(hostId: 'server').location,
      find.text('MCP 서버'),
    ),
    tags: const <String>[
      'route_test__mcp_settings_route__widget',
      'feature_test__mcp_server_management__widget',
    ],
  );

  testWidgets(
    'ProviderSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const ProviderSettingsRoute(hostId: 'server').location,
      find.text('연결됨'),
    ),
    tags: const <String>['route_test__provider_settings_route__widget'],
  );

  testWidgets(
    'PermissionSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const PermissionSettingsRoute(hostId: 'server').location,
      find.byKey(const ValueKey<String>('permission-settings-change')),
    ),
    tags: const <String>[
      'route_test__permission_settings_route__widget',
      'feature_test__permission_settings__widget',
    ],
  );

  testWidgets(
    'ProjectSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const ProjectSettingsRoute(hostId: 'server').location,
      find.text('Projects'),
    ),
    tags: const <String>['route_test__project_settings_route__widget'],
  );

  testWidgets(
    'AgentSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const AgentSettingsRoute(hostId: 'server').location,
      find.text('Agents'),
    ),
    tags: const <String>['route_test__agent_settings_route__widget'],
  );

  testWidgets(
    'SkillSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const SkillSettingsRoute(hostId: 'server').location,
      find.text('스킬'),
    ),
    tags: const <String>['route_test__skill_settings_route__widget'],
  );

  testWidgets(
    'DaemonSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const DaemonSettingsRoute().location,
      find.text('원격 daemons'),
    ),
    tags: const <String>['route_test__daemon_settings_route__widget'],
  );

  testWidgets(
    'AdvancedSettingsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const AdvancedSettingsRoute().location,
      find.byKey(const ValueKey<String>('advanced-settings-reset-button')),
    ),
    tags: const <String>[
      'route_test__advanced_settings_route__widget',
      'feature_test__settings_reset__widget',
    ],
  );

  testWidgets(
    'ConnectDaemonRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const ConnectDaemonRoute().location,
      find.byKey(const ValueKey<String>('connect-daemon-paste')),
    ),
    tags: const <String>[
      'route_test__connect_daemon_route__widget',
      'feature_test__daemon_relay__widget',
    ],
  );

  testWidgets(
    'PairingLinkRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const PairingLinkRoute().location,
      find.byKey(const ValueKey<String>('relay-pair-link')),
    ),
    tags: const <String>[
      'route_test__pairing_link_route__widget',
      'feature_test__daemon_relay__widget',
    ],
  );

  testWidgets(
    'PairingScanRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const PairingScanRoute().location,
      find.text('QR 코드 스캔'),
    ),
    tags: const <String>[
      'route_test__pairing_scan_route__widget',
      'feature_test__daemon_relay__widget',
    ],
  );

  testWidgets(
    'PairOfferRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const PairOfferRoute().location,
      find.text('Daemon 연결 확인'),
    ),
    tags: const <String>[
      'route_test__pair_offer_route__widget',
      'feature_test__daemon_relay__widget',
    ],
  );

  testWidgets(
    'AdvancedNewHostRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const AdvancedNewHostRoute().location,
      find.text('원격 daemon 추가'),
    ),
    tags: const <String>['route_test__advanced_new_host_route__widget'],
  );

  testWidgets(
    'DaemonConnectionsRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const DaemonConnectionsRoute(hostId: 'server').location,
      find.text('연결'),
    ),
    tags: const <String>[
      'route_test__daemon_connections_route__widget',
      'feature_test__daemon_relay__widget',
      'feature_test__daemon_relay__platformSmoke',
    ],
  );

  testWidgets(
    'EditHostRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const EditHostRoute(hostId: 'server').location,
      find.text('원격 daemon 편집'),
    ),
    tags: const <String>['route_test__edit_host_route__widget'],
  );
}

Future<void> _verifyRoute(
  WidgetTester tester,
  FakeTinestApi api,
  String location,
  Finder expected,
) async {
  for (final size in <Size>[const Size(1200, 900), const Size(390, 760)]) {
    await tester.binding.setSurfaceSize(size);
    final router = GoRouter(initialLocation: location, routes: $appRoutes);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
        ],
        child: MaterialApp.router(
          theme: testLightTheme,
          darkTheme: testDarkTheme,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          routerConfig: router,
          builder: (context, child) => TinestUiDensity(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      Uri.parse(location).path,
    );
    expect(expected, findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    router.dispose();
  }
  await tester.binding.setSurfaceSize(null);
}
