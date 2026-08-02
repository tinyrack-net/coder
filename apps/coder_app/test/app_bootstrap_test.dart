import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

void main() {
  test('typed routes build canonical nested locations', () {
    expect(
      const SettingsRoute(hostId: 'server').location,
      '/hosts/server/settings',
    );
    expect(
      const AgentRoute(
        hostId: 'server',
        workspaceId: 'workspace',
        agentId: 'agent',
      ).location,
      '/hosts/server/workspaces/workspace/agents/agent',
    );
  });

  testWidgets(
    'remote-only bootstrap shows host connection without starting a daemon',
    (tester) async {
      final bootstrap = _RemoteOnlyFakeBootstrap();
      await tester.pumpWidget(CoderApp(bootstrap: bootstrap));
      await tester.pump();

      expect(find.text('모바일은 원격 daemon에만 연결합니다.'), findsOneWidget);
      expect(bootstrap.autoConnectCalls, 1);
    },
  );

  testWidgets('settings button opens the provider settings screen', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: const DashboardRoute(hostId: 'server').location,
      routes: $appRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWithValue(
            FakeAppBootstrap(api: FakeCoderApi()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('설정'), findsOneWidget);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('Provider 설정'), findsOneWidget);
    expect(find.text('기본 모델'), findsOneWidget);
    expect(find.text('OpenAI'), findsWidgets);
    expect(find.text('Provider 추가'), findsOneWidget);
  });
}

class _RemoteOnlyFakeBootstrap implements AppBootstrap {
  int autoConnectCalls = 0;

  @override
  bool get canRegisterLocalWorkspace => false;

  @override
  Future<BootstrapConnection?> autoConnect() async {
    autoConnectCalls += 1;
    return null;
  }

  @override
  Future<void> close() async {}

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) {
    throw UnimplementedError();
  }
}
