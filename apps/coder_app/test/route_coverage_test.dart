import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  final session = SessionDto(
    id: 'session',
    worktreeId: worktree.id,
    title: 'Route session',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  final api = FakeCoderApi(
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
      find.text('Route session'),
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
      find.text('Provider 추가'),
    ),
    tags: const <String>['route_test__provider_settings_route__widget'],
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
    'NewHostRoute renders at desktop and mobile sizes',
    (tester) => _verifyRoute(
      tester,
      api,
      const NewHostRoute().location,
      find.text('원격 daemon 추가'),
    ),
    tags: const <String>['route_test__new_host_route__widget'],
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
  FakeCoderApi api,
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
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          routerConfig: router,
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
