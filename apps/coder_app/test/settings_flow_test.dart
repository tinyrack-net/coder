import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/coder_list_row.dart';
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
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

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
      expect(find.text('기본 Provider로 설정'), findsNothing);
      expect(find.text('기본 모델'), findsNothing);
      expect(find.byKey(const ValueKey('model-selector-openai')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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
      await tester.tap(find.widgetWithText(TRButton, '연결'));
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
      expect(
        find.byKey(const ValueKey<String>('provider-auth-cancel-attempt')),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pump();
      expect(api.cancelledAuthAttempts, <String>['attempt']);
    },
    tags: const <String>['feature_test__provider_oauth__widget'],
  );

  testWidgets(
    'failed OAuth remains visible so the user can recover',
    (
      tester,
    ) async {
      final events = StreamController<ClientEvent>.broadcast(sync: true);
      addTearDown(events.close);
      final api = FakeCoderApi(
        connections: <ProviderConnectionDto>[],
        eventStream: events.stream,
      );
      await _pumpSettings(tester, api);
      await tester.tap(find.byKey(const ValueKey('provider-add-openai')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with ChatGPT'));
      await tester.pump();
      events.add(
        const ProviderAuthUpdatedClientEvent(
          ProviderAuthAttemptDto(
            id: 'attempt',
            definitionId: 'openai',
            methodId: 'chatgpt-browser',
            status: ProviderAuthAttemptStatus.failed,
            error: 'planned authorization failure',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('planned authorization failure'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('provider-add-openai')), findsOneWidget);
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
      await tester.tap(find.widgetWithText(TRButton, '연결'));
      await tester.pumpAndSettle();
      expect(api.credentials['openai'], 'openai-secret');

      await tester.tap(find.byKey(const ValueKey('provider-add-ollama')));
      await tester.pumpAndSettle();
      final ollama = (await api.listProviderConnections()).singleWhere(
        (connection) => connection.id == 'ollama',
      );
      expect(ollama.credentialOrigin, ProviderCredentialOrigin.none);

      final refresh = find.byKey(
        const ValueKey<String>('provider-catalog-refresh'),
      );
      await _pumpUntilPresent(tester, refresh);
      await tester.tap(refresh);
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
    'catalog refresh shows a transient failure and retries',
    (
      tester,
    ) async {
      final api = FakeCoderApi(
        catalogRefreshError: const CoderClientException(
          'planned catalog outage',
          code: 'provider_unavailable',
        ),
      );
      await _pumpSettings(tester, api);

      final refresh = find.byKey(
        const ValueKey<String>('provider-catalog-refresh'),
      );
      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.textContaining('planned catalog outage'), findsOneWidget);

      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.textContaining('planned catalog outage'), findsNothing);
      expect(
        (await api.listProviderCatalog()).source,
        ProviderCatalogSource.refreshed,
      );
    },
    tags: const <String>['feature_test__provider_catalog__widget'],
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
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Model 자동 조회 실패'), findsOneWidget);
      await tester.enterText(_field('수동 model ID'), 'lab-model');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
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

  testWidgets('connection cards manage custom edits and removal', (
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
    await tester.tap(findAccessibleAction('연결 작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('고급 설정 편집'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TRSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '저장'));
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderConnections())
          .single
          .customConfig!
          .authenticationRequired,
      isFalse,
    );

    await tester.tap(findAccessibleAction('연결 작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '취소'));
    await tester.pumpAndSettle();
    expect(await api.listProviderConnections(), hasLength(1));

    await tester.tap(findAccessibleAction('연결 작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '삭제'));
    await tester.pumpAndSettle();
    expect(await api.listProviderConnections(), isEmpty);

    // Re-add it to cover the softer disconnect lifecycle independently.
    await api.createCustomProvider('custom-one', custom.customConfig!);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _pumpSettings(tester, api);

    await tester.tap(findAccessibleAction('연결 작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '취소'));
    await tester.pumpAndSettle();
    expect(
      (await api.listProviderConnections()).single.status,
      isNot(ProviderConnectionStatus.disconnected),
    );

    await tester.tap(findAccessibleAction('연결 작업'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '연결 해제'));
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
            .widget<CoderListRow>(
              find.byKey(const ValueKey('provider-add-deepseek')),
            )
            .onTap,
        isNotNull,
      );
      expect(find.byKey(const ValueKey('model-selector-openai')), findsNothing);
      expect(find.byKey(const ValueKey('provider-add-custom')), findsOneWidget);
    },
    tags: const <String>['feature_test__daemon_authentication__widget'],
  );

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
        child: MaterialApp(
          theme: testLightTheme,
          darkTheme: testDarkTheme,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: const SettingsPage(hostId: 'server'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('connection failed'), findsOneWidget);
  });
}

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

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
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
      child: MaterialApp(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: const SettingsPage(hostId: 'server'),
      ),
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

Future<void> _pumpUntilPresent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder.');
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
  Future<void> deleteAllBearerTokens() async {}

  @override
  Future<void> clear() async {}

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => Future<CoderApi>.error(StateError('connection failed'));
}
