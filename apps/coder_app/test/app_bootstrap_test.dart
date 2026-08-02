import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
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
      initialLocation: '/hosts/server',
      routes: <RouteBase>[
        GoRoute(
          path: '/hosts/:hostId',
          builder: (_, state) =>
              DashboardPage(hostId: state.pathParameters['hostId']!),
          routes: <RouteBase>[
            GoRoute(
              path: 'settings',
              builder: (_, state) =>
                  SettingsPage(hostId: state.pathParameters['hostId']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coderControllerProvider.overrideWith(_SettingsTestController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('설정'), findsOneWidget);
    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();

    expect(find.text('API Providers'), findsOneWidget);
    expect(find.text('기본 모델'), findsOneWidget);
    expect(find.text('OpenAI'), findsWidgets);
    expect(find.text('Provider 활성화'), findsOneWidget);
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

class _SettingsTestController extends CoderController {
  @override
  bool get canRegisterLocalWorkspace => true;

  @override
  bool get canManageProviders => true;

  @override
  CoderState build() {
    final now = DateTime.utc(2026);
    return CoderState(
      connected: true,
      connectionLabel: '127.0.0.1:7337',
      serverInfo: const ServerInfoDto(
        serverId: 'server',
        version: 'test',
        protocolVersion: 1,
        features: <String, bool>{'providerAdmin': true},
      ),
      providerCatalog: ProviderCatalogDto(
        defaultProviderId: 'openai',
        presets: const <ProviderPresetDto>[
          ProviderPresetDto(
            id: 'openai',
            name: 'OpenAI',
            defaultBaseUrl: 'https://api.openai.com/v1',
            defaultTransport: ApiTransport.responses,
            defaultCredentialSource: CredentialSource.environment,
            strictToolSchema: true,
          ),
        ],
        providers: <ApiProviderDto>[
          ApiProviderDto(
            id: 'openai',
            name: 'OpenAI',
            presetId: 'openai',
            baseUrl: 'https://api.openai.com/v1',
            transport: ApiTransport.responses,
            credentialSource: CredentialSource.environment,
            credentialConfigured: false,
            environmentVariable: 'OPENAI_API_KEY',
            enabled: true,
            strictToolSchema: true,
            defaultModelId: 'gpt-5.6-sol',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      providerModels: const <String, List<ProviderModelDto>>{
        'openai': <ProviderModelDto>[
          ProviderModelDto(
            providerId: 'openai',
            id: 'gpt-5.6-sol',
            label: 'gpt-5.6-sol',
            source: ProviderModelSource.preset,
            capabilities: ModelCapabilitiesDto(
              streaming: CapabilitySupport.supported,
              toolCalling: CapabilitySupport.supported,
              reasoningEffort: CapabilitySupport.supported,
              source: CapabilitySource.preset,
            ),
          ),
        ],
      },
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadProviderModels(String providerId) async {}
}
