import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_coder_api.dart';
import '../support/localization.dart';

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
    head: 'abc123',
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
  final routes = <({String name, String location})>[
    (name: 'workspace_home', location: const WorkspaceHomeRoute().location),
    (
      name: 'worktree',
      location: WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: worktree.id,
      ).location,
    ),
    (
      name: 'session',
      location: SessionRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: worktree.id,
        sessionId: session.id,
      ).location,
    ),
    (
      name: 'general_settings',
      location: const GeneralSettingsRoute().location,
    ),
    (
      name: 'mcp_settings',
      location: const McpSettingsRoute(hostId: 'server').location,
    ),
    (
      name: 'provider_settings',
      location: const ProviderSettingsRoute(hostId: 'server').location,
    ),
    (
      name: 'project_settings',
      location: const ProjectSettingsRoute(hostId: 'server').location,
    ),
    (
      name: 'agent_settings',
      location: const AgentSettingsRoute(hostId: 'server').location,
    ),
    (
      name: 'permission_settings',
      location: const PermissionSettingsRoute(hostId: 'server').location,
    ),
    (
      name: 'skill_settings',
      location: const SkillSettingsRoute(hostId: 'server').location,
    ),
    (name: 'daemon_settings', location: const DaemonSettingsRoute().location),
    (
      name: 'advanced_settings',
      location: const AdvancedSettingsRoute().location,
    ),
    (name: 'new_host', location: const NewHostRoute().location),
    (
      name: 'edit_host',
      location: const EditHostRoute(hostId: 'server').location,
    ),
  ];

  for (final route in routes) {
    for (final viewport in _viewports) {
      for (final mode in ThemeMode.values) {
        if (mode == ThemeMode.system) continue;
        final modeName = mode.name;
        unawaited(
          goldenTest(
            '${route.name} ${viewport.name} $modeName route',
            fileName: '${route.name}_${viewport.name}_$modeName',
            constraints: BoxConstraints.tight(viewport.size),
            builder: () => _RouteGoldenHost(
              location: route.location,
              mode: mode,
              size: viewport.size,
              api: FakeCoderApi(
                workspaces: <WorkspaceDto>[workspace],
                worktrees: <WorktreeDto>[worktree],
                agents: <SessionDto>[session],
              ),
            ),
          ),
        );
      }
    }
  }
}

const _viewports = <({String name, Size size})>[
  (name: 'desktop', size: Size(1200, 900)),
  (name: 'mobile', size: Size(390, 760)),
];

class _RouteGoldenHost extends StatefulWidget {
  const _RouteGoldenHost({
    required this.location,
    required this.mode,
    required this.size,
    required this.api,
  });

  final String location;
  final ThemeMode mode;
  final Size size;
  final FakeCoderApi api;

  @override
  State<_RouteGoldenHost> createState() => _RouteGoldenHostState();
}

class _RouteGoldenHostState extends State<_RouteGoldenHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.location,
    routes: $appRoutes,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: widget.size,
    child: ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(fakeAppServices(widget.api)),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        themeMode: widget.mode,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: _router,
      ),
    ),
  );
}
