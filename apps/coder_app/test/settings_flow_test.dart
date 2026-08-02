import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/ports.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);
  final presets = <ProviderPresetDto>[
    const ProviderPresetDto(
      id: 'openai',
      name: 'OpenAI',
      defaultBaseUrl: 'https://api.openai.com/v1',
      defaultTransport: ApiTransport.responses,
      defaultCredentialSource: CredentialSource.environment,
      strictToolSchema: true,
      defaultEnvironmentVariable: 'OPENAI_API_KEY',
      defaultModelId: 'gpt-test',
      modelIds: <String>['gpt-test'],
    ),
    const ProviderPresetDto(
      id: 'custom',
      name: 'Custom',
      defaultBaseUrl: 'http://localhost:8080/v1',
      defaultTransport: ApiTransport.chatCompletions,
      defaultCredentialSource: CredentialSource.stored,
      strictToolSchema: false,
    ),
  ];
  ApiProviderDto provider({
    required String id,
    required String name,
    required String presetId,
    required CredentialSource credentialSource,
    String? defaultModelId,
  }) => ApiProviderDto(
    id: id,
    name: name,
    presetId: presetId,
    baseUrl: id == 'openai'
        ? 'https://api.openai.com/v1'
        : 'http://localhost:8080/v1',
    transport: id == 'openai'
        ? ApiTransport.responses
        : ApiTransport.chatCompletions,
    credentialSource: credentialSource,
    credentialConfigured: credentialSource == CredentialSource.stored,
    environmentVariable: credentialSource == CredentialSource.environment
        ? 'OPENAI_API_KEY'
        : null,
    enabled: true,
    strictToolSchema: id == 'openai',
    defaultModelId: defaultModelId,
    createdAt: now,
    updatedAt: now,
  );
  ProviderModelDto model(
    String id, {
    ProviderModelSource source = ProviderModelSource.manual,
  }) => ProviderModelDto(
    providerId: 'custom',
    id: id,
    label: id,
    source: source,
    capabilities: const ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
      source: CapabilitySource.manual,
    ),
  );

  testWidgets('provider settings supports the full local admin workflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final custom = provider(
      id: 'custom-provider',
      name: 'Local API',
      presetId: 'custom',
      credentialSource: CredentialSource.stored,
      defaultModelId: 'manual-model',
    );
    final api = FakeCoderApi(
      catalog: ProviderCatalogDto(
        defaultProviderId: 'openai',
        presets: presets,
        providers: <ApiProviderDto>[
          provider(
            id: 'openai',
            name: 'OpenAI',
            presetId: 'openai',
            credentialSource: CredentialSource.environment,
            defaultModelId: 'gpt-test',
          ),
          custom,
        ],
      ),
      models: <String, List<ProviderModelDto>>{
        custom.id: <ProviderModelDto>[model('manual-model')],
      },
    );
    await _pumpSettings(tester, api);

    expect(find.text('API Providers'), findsOneWidget);
    await tester.tap(find.text('Local API'));
    await tester.pumpAndSettle();
    expect(_field('API key'), findsOneWidget);
    expect(find.text('manual-model'), findsWidgets);

    await tester.enterText(_field('이름'), 'Local Updated');
    await tester.enterText(_field('Base URL'), 'http://127.0.0.1:9000/v1');
    await tester.enterText(_field('API key'), 'secret-value');
    await tester.enterText(_field('표시할 model ID'), 'manual-model, second');
    await _reveal(tester, find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final saved = (await api.listProviderCatalog()).providers
        .where((item) => item.id == custom.id)
        .single;
    expect(saved.name, 'Local Updated');
    expect(saved.visibleModelIds, <String>['manual-model', 'second']);
    expect(api.credentials[custom.id], 'secret-value');

    await _reveal(tester, find.byTooltip('/models 새로고침'));
    await tester.tap(find.byTooltip('/models 새로고침'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('수동 model 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Model ID'), 'second-model');
    await tester.tap(find.text('Streaming 지원'));
    await tester.tap(find.text('Tool calling 지원'));
    await tester.tap(find.text('Reasoning effort 지원'));
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(find.text('second-model'), findsOneWidget);

    await _reveal(tester, find.byTooltip('기능 진단').last);
    await tester.tap(find.byTooltip('기능 진단').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('과금이 발생'), findsOneWidget);
    await tester.tap(find.text('진단 실행'));
    await tester.pumpAndSettle();
    expect(find.textContaining('확인되었습니다'), findsOneWidget);

    await _reveal(tester, find.byTooltip('수동 model 삭제').last);
    await tester.tap(find.byTooltip('수동 model 삭제').last);
    await tester.pumpAndSettle();
    expect(find.text('second-model'), findsNothing);

    await tester.tap(find.byTooltip('수동 model 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가'));
    expect(find.text('수동 model 추가'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Provider 추가'));
    await tester.pumpAndSettle();
    expect(find.text('OpenAI Compatible'), findsWidgets);
    expect((await api.listProviderCatalog()).providers, hasLength(3));

    await tester.tap(find.text('Local Updated'));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('삭제'));
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('Local Updated'), findsWidgets);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '삭제'));
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderCatalog()).providers.any(
        (item) => item.id == custom.id,
      ),
      isFalse,
    );
  });

  testWidgets('remote settings is read-only and uses the mobile layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      serverInfo: const ServerInfoDto(
        serverId: 'remote',
        version: 'test',
        protocolVersion: coderProtocolVersion,
        features: <String, bool>{'providerAdmin': false},
      ),
      catalog: ProviderCatalogDto(
        defaultProviderId: 'openai',
        presets: presets,
        providers: <ApiProviderDto>[
          provider(
            id: 'openai',
            name: 'OpenAI',
            presetId: 'openai',
            credentialSource: CredentialSource.environment,
            defaultModelId: 'gpt-test',
          ),
        ],
      ),
    );
    await _pumpSettings(tester, api);

    expect(find.textContaining('조회만 할 수 있습니다'), findsOneWidget);
    expect(find.byTooltip('Provider 추가'), findsNothing);
    expect(find.byTooltip('/models 새로고침'), findsNothing);
    expect(find.text('저장'), findsNothing);
  });

  testWidgets('settings renders disconnected and empty catalog states', (
    tester,
  ) async {
    final disconnectedApi = FakeCoderApi();
    await _pumpSettings(
      tester,
      disconnectedApi,
      autoConnectEnabled: false,
    );
    expect(find.text('Daemon 연결이 필요합니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final emptyApi = FakeCoderApi(
      catalog: const ProviderCatalogDto(
        providers: <ApiProviderDto>[],
        presets: <ProviderPresetDto>[],
      ),
    );
    await _pumpSettings(tester, emptyApi);
    expect(find.text('Provider를 선택하세요.'), findsOneWidget);
    expect(find.byTooltip('Provider 추가'), findsOneWidget);
    await tester.tap(find.byTooltip('Provider 추가'));
    await tester.pumpAndSettle();
    expect((await emptyApi.listProviderCatalog()).providers, isEmpty);
  });

  testWidgets('settings surfaces bootstrap errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWithValue(const _FailingBootstrap()),
        ],
        child: const MaterialApp(home: SettingsPage(hostId: 'server')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('connection failed'), findsOneWidget);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeCoderApi api, {
  bool autoConnectEnabled = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(
          FakeAppBootstrap(
            api: api,
            autoConnectEnabled: autoConnectEnabled,
          ),
        ),
        appClockProvider.overrideWithValue(_Clock(DateTime.utc(2026, 8, 2))),
        appIdGeneratorProvider.overrideWithValue(const _Ids()),
      ],
      child: const MaterialApp(home: SettingsPage(hostId: 'server')),
    ),
  );
  await tester.pumpAndSettle();
}

final class _Ids implements AppIdGenerator {
  const _Ids();

  @override
  String generate() => 'new-provider';
}

final class _Clock implements AppClock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _FailingBootstrap implements AppBootstrap {
  const _FailingBootstrap();

  @override
  bool get canRegisterLocalWorkspace => false;

  @override
  Future<BootstrapConnection?> autoConnect() =>
      Future<BootstrapConnection?>.error(StateError('connection failed'));

  @override
  Future<void> close() async {}

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) =>
      Future<BootstrapConnection>.error(StateError('connection failed'));
}
