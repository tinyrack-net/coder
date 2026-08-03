import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/external_url_opener.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/settings_page.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

void main() {
  for (final size in <Size>[const Size(1200, 900), const Size(390, 760)]) {
    testWidgets('connected providers are above addable providers at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpSettings(tester, FakeCoderApi());

      final connected = find.byKey(
        const ValueKey('provider-settings-connected'),
      );
      final addable = find.byKey(const ValueKey('provider-settings-add'));
      expect(connected, findsOneWidget);
      expect(addable, findsOneWidget);
      expect(
        tester.getBottomRight(connected).dy,
        lessThanOrEqualTo(tester.getTopLeft(addable).dy),
      );
      expect(
        find.byKey(const ValueKey('provider-add-openai')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('provider-add-deepseek')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('model selector searches long labels without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const currentId =
        'vendor/reasoning-model-with-an-extremely-long-identifier-current';
    const nextId =
        'vendor/reasoning-model-with-an-extremely-long-identifier-next';
    final api = FakeCoderApi(
      connections: <ProviderConnectionDto>[
        _connection(defaultModelId: currentId),
      ],
      models: <String, List<ProviderModelDto>>{
        'provider': <ProviderModelDto>[
          _longModel(id: currentId, label: 'Current $currentId'),
          _longModel(id: nextId, label: 'Next $nextId'),
        ],
      },
    );
    await _pumpSettings(tester, api);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('model-selector-provider')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('model-search-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('model-search-field')),
      'next',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('model-option-provider-$nextId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('model-option-provider-$currentId')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('model-option-provider-$nextId')),
    );
    await tester.pumpAndSettle();
    expect((await api.listProviderConnections()).single.defaultModelId, nextId);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'model selector handles missing, empty, saving, and error states',
    (
      tester,
    ) async {
      const availableId = 'available-model';
      final saveGate = Completer<void>();
      final savingApi = FakeCoderApi(
        connections: <ProviderConnectionDto>[
          _connection(defaultModelId: 'removed-model'),
        ],
        models: <String, List<ProviderModelDto>>{
          'provider': <ProviderModelDto>[
            _longModel(id: availableId, label: 'Available model'),
          ],
        },
        defaultModelSetGate: saveGate.future,
      );
      await _pumpSettings(tester, savingApi);
      expect(find.text('카탈로그에 없음'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('model-selector-provider')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-provider-available-model')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('model-selector-saving-provider')),
        findsOneWidget,
      );
      saveGate.complete();
      await tester.pumpAndSettle();
      expect(
        (await savingApi.listProviderConnections()).single.defaultModelId,
        availableId,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final errorApi = FakeCoderApi(
        connections: <ProviderConnectionDto>[
          _connection(defaultModelId: availableId),
        ],
        models: <String, List<ProviderModelDto>>{
          'provider': <ProviderModelDto>[
            _longModel(id: availableId, label: 'Available model'),
            _longModel(id: 'other-model', label: 'Other model'),
          ],
        },
        defaultModelSetError: Exception('model update failed'),
      );
      await _pumpSettings(tester, errorApi);
      await tester.tap(find.byKey(const ValueKey('model-selector-provider')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-provider-other-model')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('model update failed'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final loadingGate = Completer<void>();
      final loadingApi = FakeCoderApi(
        connections: <ProviderConnectionDto>[_connection()],
        modelListGate: loadingGate.future,
      );
      await _pumpSettings(tester, loadingApi, settle: false);
      expect(find.text('모델을 불러오는 중…'), findsOneWidget);
      loadingGate.complete();
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final emptyApi = FakeCoderApi(
        connections: <ProviderConnectionDto>[_connection()],
        models: const <String, List<ProviderModelDto>>{
          'provider': <ProviderModelDto>[],
        },
      );
      await _pumpSettings(tester, emptyApi);
      expect(find.text('사용 가능한 모델이 없습니다.'), findsOneWidget);
    },
  );

  testWidgets(
    'preset providers hide technical settings and connect with key',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi();
      await _pumpSettings(tester, api);

      expect(find.text('연결됨'), findsWidgets);
      expect(find.text('Provider 추가'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('provider-add-deepseek')));
      await tester.pumpAndSettle();

      expect(_field('API key'), findsOneWidget);
      expect(_field('Base URL'), findsNothing);
      expect(find.text('API 형식'), findsNothing);
      await tester.enterText(_field('API key'), 'deepseek-secret');
      await tester.tap(find.widgetWithText(FilledButton, '연결'));
      await tester.pumpAndSettle();

      expect(api.credentials['deepseek'], 'deepseek-secret');
      expect(
        (await api.listProviderConnections()).map((item) => item.id),
        contains('deepseek'),
      );
      expect(find.text('DeepSeek'), findsWidgets);
    },
    tags: const <String>['feature_test__provider_catalog__widget'],
  );

  testWidgets(
    'OpenAI offers ChatGPT OAuth and API key choices',
    (
      tester,
    ) async {
      final api = FakeCoderApi(connections: <ProviderConnectionDto>[]);
      final opener = _ExternalUrlOpener();
      await _pumpSettings(tester, api, externalUrlOpener: opener);

      await tester.tap(find.byKey(const ValueKey('provider-add-openai')));
      await tester.pumpAndSettle();
      expect(find.text('Sign in with ChatGPT'), findsOneWidget);
      expect(find.text('실험적'), findsOneWidget);
      expect(find.text('API key'), findsOneWidget);
      expect(find.text('Base URL'), findsNothing);

      await tester.tap(find.text('Sign in with ChatGPT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('ChatGPT 로그인 대기 중'), findsOneWidget);
      expect(find.textContaining('auth.example'), findsOneWidget);
      expect(opener.opened.single.host, 'auth.example');

      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pump();
      expect(api.cancelledAuthAttempts, <String>['attempt']);
    },
    tags: const <String>['feature_test__provider_oauth__widget'],
  );

  testWidgets(
    'OpenAI API key and local providers connect in one step',
    (
      tester,
    ) async {
      final api = FakeCoderApi(
        connections: <ProviderConnectionDto>[],
        catalog: ProviderCatalogDto(
          definitions: <ProviderDefinitionDto>[
            ..._catalogDefinitions,
            _localDefinition,
          ],
          source: ProviderCatalogSource.bundled,
          updatedAt: DateTime.utc(2026),
        ),
      );
      await _pumpSettings(tester, api);

      await tester.tap(find.byKey(const ValueKey('provider-add-openai')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('API key'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('API key'), 'openai-secret');
      await tester.tap(find.widgetWithText(FilledButton, '연결'));
      await tester.pumpAndSettle();
      expect(api.credentials['openai'], 'openai-secret');

      await tester.tap(find.byKey(const ValueKey('provider-add-ollama')));
      await tester.pumpAndSettle();
      final ollama = (await api.listProviderConnections()).singleWhere(
        (connection) => connection.id == 'ollama',
      );
      expect(ollama.credentialOrigin, ProviderCredentialOrigin.none);

      await tester.tap(find.byTooltip('Catalog 갱신'));
      await tester.pumpAndSettle();
      expect(
        (await api.listProviderCatalog()).source,
        ProviderCatalogSource.refreshed,
      );
    },
    tags: const <String>[
      'feature_test__provider_connection_management__widget',
    ],
  );

  testWidgets(
    'custom provider opens a separate advanced wizard',
    (
      tester,
    ) async {
      final api = FakeCoderApi();
      await _pumpSettings(tester, api);

      final customButton = find.byKey(const ValueKey('provider-add-custom'));
      await tester.ensureVisible(customButton);
      await tester.pumpAndSettle();
      await tester.tap(customButton);
      await tester.pumpAndSettle();
      expect(find.text('Custom Provider 고급 설정'), findsOneWidget);
      expect(_field('Base URL'), findsOneWidget);
      expect(find.text('API 형식'), findsOneWidget);
      expect(_field('수동 model ID'), findsNothing);
      await tester.enterText(_field('이름'), 'Lab');
      await tester.enterText(_field('Base URL'), 'http://127.0.0.1:9000/v1');
      await tester.enterText(_field('API key'), 'secret');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Model 자동 조회 실패'), findsOneWidget);
      await tester.enterText(_field('수동 model ID'), 'lab-model');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      final custom = (await api.listProviderConnections()).singleWhere(
        (connection) => connection.id == 'new-provider',
      );
      expect(custom.displayName, 'Lab');
      expect(custom.customConfig!.baseUrl, 'http://127.0.0.1:9000/v1');
      expect(custom.customConfig!.manualModelIds, <String>['lab-model']);
    },
    tags: const <String>['feature_test__provider_custom__widget'],
  );

  testWidgets('connection cards manage defaults, custom edits, and removal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.utc(2026);
    final custom = ProviderConnectionDto(
      id: 'custom-one',
      definitionId: 'custom',
      displayName: 'Lab',
      status: ProviderConnectionStatus.degraded,
      authKind: ProviderAuthKind.apiKey,
      credentialOrigin: ProviderCredentialOrigin.environment,
      isDefault: false,
      defaultModelId: 'model-a',
      error: 'model discovery unavailable',
      customConfig: const CustomProviderConfigDto(
        name: 'Lab',
        baseUrl: 'http://127.0.0.1:9000/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        authenticationRequired: true,
        manualModelIds: <String>['model-a'],
      ),
      createdAt: now,
      updatedAt: now,
    );
    final api = FakeCoderApi(
      connections: <ProviderConnectionDto>[custom],
      models: const <String, List<ProviderModelDto>>{
        'custom-one': <ProviderModelDto>[
          ProviderModelDto(
            connectionId: 'custom-one',
            id: 'model-a',
            label: 'Model A',
            source: ProviderModelSource.manual,
            capabilities: ModelCapabilitiesDto(),
          ),
          ProviderModelDto(
            connectionId: 'custom-one',
            id: 'model-b',
            label: 'Model B',
            source: ProviderModelSource.discovered,
            capabilities: ModelCapabilitiesDto(),
          ),
        ],
      },
    );
    await _pumpSettings(tester, api);

    expect(find.text('제한된 연결 · Environment credential'), findsOneWidget);
    expect(find.text('model discovery unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('model-selector-custom-one')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('model-option-custom-one-model-b')),
    );
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderConnections()).single.defaultModelId,
      'model-b',
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('기본 Provider로 설정'));
    await tester.pumpAndSettle();
    expect((await api.listProviderConnections()).single.isDefault, isTrue);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고급 설정 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '저장'));
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderConnections())
          .single
          .customConfig!
          .authenticationRequired,
      isFalse,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderConnections()).single.status,
      isNot(ProviderConnectionStatus.disconnected),
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '연결 해제'));
    await tester.pumpAndSettle();
    expect(find.text('연결된 Provider가 없습니다.'), findsOneWidget);
  });

  testWidgets('connection cards render every public status and auth origin', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.utc(2026);
    final statuses = <ProviderConnectionStatus>[
      ProviderConnectionStatus.connecting,
      ProviderConnectionStatus.connected,
      ProviderConnectionStatus.error,
      ProviderConnectionStatus.reauthRequired,
    ];
    final origins = <ProviderCredentialOrigin>[
      ProviderCredentialOrigin.stored,
      ProviderCredentialOrigin.oauth,
      ProviderCredentialOrigin.none,
      ProviderCredentialOrigin.environment,
    ];
    final api = FakeCoderApi(
      connections: <ProviderConnectionDto>[
        for (var index = 0; index < statuses.length; index += 1)
          ProviderConnectionDto(
            id: 'connection-$index',
            definitionId: 'definition-$index',
            displayName: 'Connection $index',
            status: statuses[index],
            authKind: ProviderAuthKind.none,
            credentialOrigin: origins[index],
            isDefault: index == 0,
            createdAt: now,
            updatedAt: now,
          ),
      ],
    );
    await _pumpSettings(tester, api);

    expect(find.text('연결 중 · 저장된 credential'), findsOneWidget);
    expect(find.text('연결됨 · ChatGPT OAuth'), findsOneWidget);
    expect(find.text('오류 · 인증 없음'), findsOneWidget);
    expect(find.text('재로그인 필요 · Environment credential'), findsOneWidget);
  });

  testWidgets(
    'remote settings is fully editable and responsive',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        serverInfo: const ServerInfoDto(
          serverId: 'remote',
          version: 'test',
          protocolVersion: coderProtocolVersion,
          features: <String, bool>{},
        ),
      );
      await _pumpSettings(tester, api);

      expect(find.textContaining('조회만 할 수 있습니다'), findsNothing);
      expect(
        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('provider-add-deepseek')),
            )
            .onTap,
        isNotNull,
      );
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('model-selector-openai')),
            )
            .onTap,
        isNotNull,
      );
      expect(find.byKey(const ValueKey('provider-add-custom')), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_authentication__widget'],
  );

  testWidgets('switching daemons reloads models with the same connection ID', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 3);
    final first = FakeCoderApi(
      serverInfo: _serverInfo('first'),
      connections: <ProviderConnectionDto>[
        _connection(defaultModelId: 'shared-model'),
      ],
      models: <String, List<ProviderModelDto>>{
        'provider': <ProviderModelDto>[
          _longModel(id: 'shared-model', label: 'First daemon model'),
        ],
      },
    );
    final second = FakeCoderApi(
      serverInfo: _serverInfo('second'),
      connections: <ProviderConnectionDto>[
        _connection(defaultModelId: 'shared-model'),
      ],
      models: <String, List<ProviderModelDto>>{
        'provider': <ProviderModelDto>[
          _longModel(id: 'shared-model', label: 'Second daemon model'),
        ],
      },
    );
    final store = MemoryAppStore(
      settings: const AppSettings(embeddedDaemonEnabled: false),
      profiles: <RemoteDaemonProfile>[
        _remoteProfile('first', now),
        _remoteProfile('second', now),
      ],
      tokens: const <String, String>{'first': 'one', 'second': 'two'},
    );
    final harness = GlobalKey<_SettingsHostHarnessState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(
            AppServices(
              settings: store,
              profiles: store,
              credentials: store,
              clients: _MappedHostClients(<String, CoderApi>{
                'first.test': first,
                'second.test': second,
              }),
              clientKind: 'test',
            ),
          ),
          externalUrlOpenerProvider.overrideWithValue(_ExternalUrlOpener()),
        ],
        child: MaterialApp(home: _SettingsHostHarness(key: harness)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('First daemon model'), findsOneWidget);

    harness.currentState!.select('second');
    for (var attempt = 0; attempt < 10; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Second daemon model'), findsOneWidget);
  });

  testWidgets('settings renders disconnected and bootstrap error states', (
    tester,
  ) async {
    await _pumpSettings(tester, FakeCoderApi(), autoConnectEnabled: false);
    expect(find.text('Daemon 연결이 필요합니다.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(
            const AppServices(
              settings: _FailingStore(),
              profiles: _FailingStore(),
              credentials: _FailingStore(),
              clients: _FailingStore(),
              clientKind: 'test',
            ),
          ),
        ],
        child: const MaterialApp(home: SettingsPage(hostId: 'server')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('connection failed'), findsOneWidget);
  });
}

ProviderConnectionDto _connection({String? defaultModelId}) =>
    ProviderConnectionDto(
      id: 'provider',
      definitionId: 'provider',
      displayName: 'Provider',
      status: ProviderConnectionStatus.connected,
      authKind: ProviderAuthKind.apiKey,
      credentialOrigin: ProviderCredentialOrigin.stored,
      isDefault: true,
      defaultModelId: defaultModelId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

ProviderModelDto _longModel({required String id, required String label}) =>
    ProviderModelDto(
      connectionId: 'provider',
      id: id,
      label: label,
      source: ProviderModelSource.discovered,
      capabilities: const ModelCapabilitiesDto(),
    );

const List<ProviderDefinitionDto> _catalogDefinitions = <ProviderDefinitionDto>[
  ProviderDefinitionDto(
    id: 'openai',
    name: 'OpenAI',
    description: 'OpenAI Platform API or ChatGPT subscription.',
    authMethods: <ProviderAuthMethodDto>[
      ProviderAuthMethodDto(
        id: 'chatgpt-browser',
        label: 'Sign in with ChatGPT',
        kind: ProviderAuthKind.oauth,
        flow: ProviderAuthFlow.oauthBrowser,
        experimental: true,
      ),
      ProviderAuthMethodDto(
        id: 'api-key',
        label: 'API key',
        kind: ProviderAuthKind.apiKey,
        flow: ProviderAuthFlow.apiKey,
      ),
    ],
  ),
];

const ProviderDefinitionDto _localDefinition = ProviderDefinitionDto(
  id: 'ollama',
  name: 'Ollama',
  description: 'Local Ollama service.',
  authMethods: <ProviderAuthMethodDto>[
    ProviderAuthMethodDto(
      id: 'none',
      label: 'Connect',
      kind: ProviderAuthKind.none,
      flow: ProviderAuthFlow.none,
    ),
  ],
  recommendedModelIds: <String>['qwen3-coder'],
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeCoderApi api, {
  bool autoConnectEnabled = true,
  bool settle = true,
  ExternalUrlOpener? externalUrlOpener,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, connected: autoConnectEnabled),
        ),
        appIdGeneratorProvider.overrideWithValue(const _Ids()),
        externalUrlOpenerProvider.overrideWithValue(
          externalUrlOpener ?? _ExternalUrlOpener(),
        ),
      ],
      child: const MaterialApp(home: SettingsPage(hostId: 'server')),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }
}

final class _ExternalUrlOpener implements ExternalUrlOpener {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

final class _Ids implements AppIdGenerator {
  const _Ids();

  @override
  String generate() => 'new-provider';
}

final class _SettingsHostHarness extends StatefulWidget {
  const _SettingsHostHarness({super.key});

  @override
  State<_SettingsHostHarness> createState() => _SettingsHostHarnessState();
}

final class _SettingsHostHarnessState extends State<_SettingsHostHarness> {
  String _hostId = 'first';

  void select(String hostId) => setState(() => _hostId = hostId);

  @override
  Widget build(BuildContext context) => SettingsPage(hostId: _hostId);
}

final class _MappedHostClients implements HostClientFactory {
  const _MappedHostClients(this.apis);

  final Map<String, CoderApi> apis;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) async => apis[endpoint.websocketUri.host]!;
}

RemoteDaemonProfile _remoteProfile(String id, DateTime now) =>
    RemoteDaemonProfile(
      id: id,
      label: id,
      websocketUri: Uri.parse('ws://$id.test/ws'),
      autoConnect: true,
      createdAt: now,
      updatedAt: now,
    );

ServerInfoDto _serverInfo(String id) => ServerInfoDto(
  serverId: id,
  version: 'test',
  protocolVersion: coderProtocolVersion,
  features: const <String, bool>{},
);

final class _FailingStore
    implements
        AppSettingsRepository,
        RemoteHostRepository,
        RemoteHostCredentialStore,
        HostClientFactory {
  const _FailingStore();

  @override
  Future<AppSettings> loadSettings() =>
      Future<AppSettings>.error(StateError('connection failed'));

  @override
  Future<List<RemoteDaemonProfile>> listProfiles() async =>
      const <RemoteDaemonProfile>[];

  @override
  Future<void> saveSettings(AppSettings settings) async {}

  @override
  Future<void> upsertProfile(RemoteDaemonProfile profile) async {}

  @override
  Future<void> deleteProfile(String profileId) async {}

  @override
  Future<String?> readBearerToken(String profileId) async => null;

  @override
  Future<void> writeBearerToken(String profileId, String token) async {}

  @override
  Future<void> deleteBearerToken(String profileId) async {}

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => Future<CoderApi>.error(StateError('connection failed'));
}
