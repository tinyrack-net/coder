import 'dart:async';

import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_app/src/features/hosts/application/host_controller.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/shared/presentation/settings_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_coder_api.dart';
import '../../support/localization.dart';

void main() {
  final cases =
      <
        ({
          String name,
          String location,
          FakeCoderApi Function(Future<void> gate) api,
        })
      >[
        (
          name: 'project catalog',
          location: const ProjectSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(workspaceCatalogGate: gate),
        ),
        (
          name: 'agent definitions',
          location: const AgentSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(agentDefinitionsGate: gate),
        ),
        (
          name: 'MCP servers',
          location: const McpSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(mcpListGate: gate),
        ),
        (
          name: 'skills',
          location: const SkillSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(skillListGate: gate),
        ),
        (
          name: 'providers',
          location: const ProviderSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(providerConnectionsGate: gate),
        ),
        (
          name: 'permissions',
          location: const PermissionSettingsRoute(hostId: 'server').location,
          api: (gate) => FakeCoderApi(permissionSettingsGate: gate),
        ),
      ];

  for (final testCase in cases) {
    testWidgets(
      '${testCase.name} keeps settings chrome available while loading',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final gate = Completer<void>();
        final router = await _pumpPendingRoute(
          tester,
          testCase.api(gate.future),
          testCase.location,
        );
        addTearDown(router.dispose);

        expect(find.text('설정'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('settings-sidebar-surface')),
          findsOneWidget,
        );
        expect(find.byType(TRSkeleton), findsWidgets);
        expect(find.bySemanticsLabel('설정 불러오는 중'), findsWidgets);

        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(SettingsSkeletonLayout), findsNothing);
      },
      tags: const <String>['feature_test__settings_async_loading__widget'],
    );
  }

  for (final testCase in <({String name, String location})>[
    (name: 'general', location: const GeneralSettingsRoute().location),
    (name: 'daemon', location: const DaemonSettingsRoute().location),
    (
      name: 'remote daemon editor',
      location: const EditHostRoute(hostId: 'server').location,
    ),
  ]) {
    testWidgets(
      '${testCase.name} replaces registry loading with settings content',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final gate = Completer<HostRegistryState>();
        final router = GoRouter(
          initialLocation: testCase.location,
          routes: $appRoutes,
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appServicesProvider.overrideWithValue(
                fakeAppServices(FakeCoderApi()),
              ),
              hostRegistryControllerProvider.overrideWith(
                () => _GateHostRegistryController(gate.future),
              ),
            ],
            child: MaterialApp.router(
              theme: testLightTheme,
              darkTheme: testDarkTheme,
              locale: testLocale,
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: testSupportedLocales,
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(TRSkeleton), findsWidgets);
        expect(find.bySemanticsLabel('설정 불러오는 중'), findsWidgets);

        gate.complete(
          const HostRegistryState(
            settings: AppSettings(embeddedDaemonEnabled: false),
            profiles: <RemoteDaemonProfile>[],
            runtimes: <String, HostRuntimeSnapshot>{},
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SettingsSkeletonLayout), findsNothing);
      },
      tags: const <String>['feature_test__settings_async_loading__widget'],
    );
  }
}

final class _GateHostRegistryController extends HostRegistryController {
  _GateHostRegistryController(this.gate);

  final Future<HostRegistryState> gate;

  @override
  Future<HostRegistryState> build() => gate;
}

Future<GoRouter> _pumpPendingRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location,
) async {
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
      ),
    ),
  );
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump();
  }
  return router;
}
