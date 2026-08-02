import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
          bootstrapProvider.overrideWithValue(_SettingsFakeBootstrap()),
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

class _SettingsFakeBootstrap implements AppBootstrap {
  _SettingsFakeBootstrap() : api = _SettingsFakeApi();

  final _SettingsFakeApi api;

  @override
  bool get canRegisterLocalWorkspace => true;

  @override
  Future<BootstrapConnection?> autoConnect() async => BootstrapConnection(
    client: api,
    endpoint: HostEndpoint.parse('ws://127.0.0.1:7337/ws', token: 'test-token'),
  );

  @override
  Future<void> close() async {}

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) async =>
      BootstrapConnection(client: api, endpoint: endpoint);
}

class _SettingsFakeApi implements CoderApi {
  _SettingsFakeApi()
    : _now = DateTime.utc(2026),
      _events = const Stream<ClientEvent>.empty(),
      _states = const Stream<ClientConnectionState>.empty();

  final DateTime _now;
  final Stream<ClientEvent> _events;
  final Stream<ClientConnectionState> _states;

  @override
  Stream<ClientEvent> get events => _events;

  @override
  Stream<ClientConnectionState> get states => _states;

  @override
  ServerInfoDto get serverInfo => const ServerInfoDto(
    serverId: 'server',
    version: 'test',
    protocolVersion: coderProtocolVersion,
    features: <String, bool>{'providerAdmin': true},
  );

  @override
  Future<ProviderCatalogDto> listProviderCatalog() async => ProviderCatalogDto(
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
        createdAt: _now,
        updatedAt: _now,
      ),
    ],
  );

  @override
  Future<List<ProviderModelDto>> listProviderModels(String providerId) async =>
      const <ProviderModelDto>[
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
      ];

  @override
  Future<List<WorkspaceDto>> listWorkspaces() async => const <WorkspaceDto>[];

  @override
  Future<List<AgentDto>> listAgents({String? workspaceId}) async =>
      const <AgentDto>[];

  @override
  Future<void> close() async {}

  @override
  Future<void> cancelTurn(String agentId) => _unsupported();

  @override
  Future<void> clearProviderCredential(String providerId) => _unsupported();

  @override
  Future<AgentDto> createAgent({
    required String id,
    required String workspaceId,
    required String title,
    required String providerId,
    required String model,
    required PermissionMode permissionMode,
    String reasoningEffort = 'medium',
  }) => _unsupported();

  @override
  Future<void> deleteProvider(String providerId) => _unsupported();

  @override
  Future<void> deleteProviderModel(String providerId, String modelId) =>
      _unsupported();

  @override
  Future<ProviderDiagnosticDto> diagnoseProviderModel(
    String providerId,
    String modelId,
  ) => _unsupported();

  @override
  Future<List<ProviderModelDto>> refreshProviderModels(String providerId) =>
      _unsupported();

  @override
  Future<WorkspaceDto> registerWorkspace({
    required String id,
    required String rootPath,
    required String name,
  }) => _unsupported();

  @override
  Future<void> resolveApproval({
    required String approvalId,
    required bool approved,
  }) => _unsupported();

  @override
  Future<void> setProviderCredential(String providerId, String apiKey) =>
      _unsupported();

  @override
  Future<void> startTurn({
    required String agentId,
    required String turnId,
    required String prompt,
  }) => _unsupported();

  @override
  Future<List<TimelineEventDto>> subscribeTimeline(
    String agentId, {
    int afterSequence = 0,
  }) => _unsupported();

  @override
  Future<AgentDto> updateAgentConfiguration({
    required String agentId,
    required String providerId,
    required String model,
    String reasoningEffort = 'medium',
  }) => _unsupported();

  @override
  Future<ApiProviderDto> upsertProvider(
    ApiProviderDto provider, {
    bool makeDefault = false,
  }) => _unsupported();

  @override
  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model) =>
      _unsupported();

  Future<T> _unsupported<T>() =>
      Future<T>.error(UnsupportedError('Not used by this widget test.'));
}
