import 'dart:async';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/app/platform/external_url_opener.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/providers/presentation/pages/provider_settings_page.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

void main() {
  testWidgets(
    'configured providers occupy the collection pane',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpSettings(tester, FakeTinestApi());

      expect(
        find.byKey(const ValueKey<String>('provider-connection-openai')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('provider-add-openai')), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('provider-add-openai')), findsOneWidget);
      expect(find.byType(TRAlertDialog), findsNothing);
    },
    tags: const <String>['feature_test__provider_catalog__widget'],
  );

  testWidgets(
    'API key and prefix stay inline in the third pane',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(connections: <ProviderConnectionDto>[]);
      await _pumpSettings(tester, api);

      await _openCatalog(tester);
      await tester.tap(find.byKey(const ValueKey('provider-add-deepseek')));
      await tester.pumpAndSettle();
      expect(_field('모델 Prefix'), findsOneWidget);
      expect(_field('API 키'), findsOneWidget);
      expect(find.byType(TRAlertDialog), findsNothing);

      await tester.enterText(_field('API 키'), 'deepseek-secret');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-connect-submit')),
      );
      await tester.pumpAndSettle();
      expect(api.credentials['deepseek'], 'deepseek-secret');
      expect(
        find.byKey(const ValueKey<String>('provider-connection-deepseek')),
        findsOneWidget,
      );
    },
    tags: const <String>[
      'feature_test__provider_connection_management__widget',
    ],
  );

  testWidgets(
    'OAuth keeps progress and browser recovery in the detail pane',
    (
      tester,
    ) async {
      final api = FakeTinestApi(connections: <ProviderConnectionDto>[]);
      final opener = _ExternalUrlOpener();
      await _pumpSettings(tester, api, externalUrlOpener: opener);

      await _openCatalog(tester);
      await tester.tap(find.byKey(const ValueKey('provider-add-openai')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-connect-submit')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('로그인 대기 중'), findsWidgets);
      expect(find.textContaining('auth.example'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('provider-oauth-open-browser'),
        ),
        findsOneWidget,
      );
      expect(opener.opened, hasLength(1));
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-oauth-open-browser')),
      );
      await tester.pump();
      expect(opener.opened, hasLength(2));
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-auth-cancel-attempt')),
      );
      await tester.pump();
      expect(api.cancelledAuthAttempts, <String>['attempt']);
      expect(find.byType(TRAlertDialog), findsNothing);
    },
    tags: const <String>['feature_test__provider_oauth__widget'],
  );

  testWidgets(
    'custom provider configuration is one inline form',
    (
      tester,
    ) async {
      await _pumpSettings(
        tester,
        FakeTinestApi(connections: <ProviderConnectionDto>[]),
      );

      await _openCatalog(tester);
      await tester.tap(find.byKey(const ValueKey('provider-add-custom')));
      await tester.pumpAndSettle();

      expect(_field('이름'), findsOneWidget);
      expect(_field('Base URL'), findsOneWidget);
      expect(_field('모델 Prefix'), findsOneWidget);
      expect(_field('API 키'), findsOneWidget);
      expect(_field('수동 model ID'), findsOneWidget);
      expect(find.byType(TRAlertDialog), findsNothing);
    },
    tags: const <String>['feature_test__provider_custom__widget'],
  );

  testWidgets(
    'connection detail manages prefix and daemon default model',
    (
      tester,
    ) async {
      final api = FakeTinestApi();
      await _pumpSettings(tester, api);
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-connection-openai')),
      );
      await tester.pumpAndSettle();

      expect(_field('모델 Prefix'), findsOneWidget);
      expect(find.text('자동'), findsOneWidget);
      final defaultModel = find.byKey(
        const ValueKey<String>('provider-default-model'),
      );
      await tester.ensureVisible(defaultModel);
      await tester.tap(defaultModel);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('provider-model-openai/gpt-5.6-sol')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<String>('provider-model-openai/gpt-5.6-sol'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        api.defaultModel,
        const SessionModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
      );
    },
    tags: const <String>[
      'feature_test__provider_default_model__widget',
      'feature_test__provider_connection_management__widget',
    ],
  );

  testWidgets('catalog and prefix failures recover inline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeTinestApi(
      connections: <ProviderConnectionDto>[],
      catalogRefreshError: const TinestClientException(
        'planned catalog outage',
        code: 'provider_unavailable',
      ),
      providerConnectError: const TinestClientException(
        'prefix conflict',
        code: 'model_prefix_conflict',
      ),
    );
    await _pumpSettings(tester, api);
    await _openCatalog(tester);

    final refresh = find.byKey(
      const ValueKey<String>('provider-catalog-refresh'),
    );
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(find.textContaining('planned catalog outage'), findsOneWidget);
    await tester.tap(refresh);
    await tester.pumpAndSettle();
    expect(find.textContaining('planned catalog outage'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('provider-add-deepseek')));
    await tester.pumpAndSettle();
    await tester.enterText(_field('API 키'), 'secret');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-connect-submit')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('이미 사용 중인 모델 Prefix'), findsOneWidget);
    expect(
      tester.widget<EditableText>(_field('모델 Prefix')).controller.text,
      'deepseek-2',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-connect-submit')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('provider-connection-deepseek')),
      findsOneWidget,
    );
  });

  testWidgets('existing connection reauthenticates without duplication', (
    tester,
  ) async {
    final api = FakeTinestApi();
    await _pumpSettings(tester, api);
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-connection-openai')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '다시 연결'));
    await tester.pumpAndSettle();

    expect(_field('API 키'), findsOneWidget);
    expect(
      tester.widget<EditableText>(_field('API 키')).controller.text,
      isEmpty,
    );
    await tester.enterText(_field('API 키'), 'replacement-secret');
    await tester.pump();
    expect(
      tester
          .widget<TRButton>(
            find.byKey(const ValueKey<String>('provider-connect-submit')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-connect-submit')),
    );
    await tester.pumpAndSettle();

    expect(api.credentials['openai'], 'replacement-secret');
    expect(await api.providers.listProviderConnections(), hasLength(1));
    expect(
      (await api.providers.listProviderConnections()).single.id,
      'openai',
    );
  });

  testWidgets('failed OAuth stays in its pane and returns to the form', (
    tester,
  ) async {
    final events = StreamController<ClientEvent>.broadcast(sync: true);
    addTearDown(events.close);
    final api = FakeTinestApi(
      connections: <ProviderConnectionDto>[],
      eventStream: events.stream,
    );
    await _pumpSettings(tester, api);
    await _openCatalog(tester);
    await tester.tap(find.byKey(const ValueKey('provider-add-openai')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-connect-submit')),
    );
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
    expect(find.byType(TRAlertDialog), findsNothing);
    await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(_field('모델 Prefix'), findsOneWidget);
  });

  testWidgets('custom provider creates, edits, disconnects, and deletes', (
    tester,
  ) async {
    final api = FakeTinestApi(connections: <ProviderConnectionDto>[]);
    await _pumpSettings(tester, api);
    await _openCatalog(tester);
    await tester.tap(find.byKey(const ValueKey('provider-add-custom')));
    await tester.pumpAndSettle();

    await tester.enterText(_field('이름'), 'Lab');
    await tester.enterText(
      _field('Base URL'),
      'http://127.0.0.1:9000/v1',
    );
    await tester.enterText(_field('API 키'), 'lab-secret');
    await tester.enterText(_field('수동 model ID'), 'model-a, model-b');
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-custom-save')),
    );
    await tester.pumpAndSettle();
    expect(
      (await api.providers.listProviderConnections()).single.displayName,
      'Lab',
    );

    await tester.enterText(_field('이름'), 'Lab Edited');
    await tester.enterText(_field('모델 Prefix'), 'lab-edited');
    await tester.tap(
      find.byKey(const ValueKey<String>('provider-custom-save')),
    );
    await tester.pumpAndSettle();
    final edited = (await api.providers.listProviderConnections()).single;
    expect(edited.displayName, 'Lab Edited');
    expect(edited.modelPrefix, 'lab-edited');

    await tester.tap(find.widgetWithText(TRButton, '연결 해제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '취소').last);
    await tester.pumpAndSettle();
    expect(
      (await api.providers.listProviderConnections()).single.status,
      ProviderConnectionStatus.connected,
    );

    await tester.tap(find.widgetWithText(TRButton, '삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TRButton, '삭제').last);
    await tester.pumpAndSettle();
    expect(await api.providers.listProviderConnections(), isEmpty);
  });

  testWidgets('provider list renders every connection status', (tester) async {
    final now = DateTime.utc(2026);
    const statuses = ProviderConnectionStatus.values;
    await _pumpSettings(
      tester,
      FakeTinestApi(
        connections: <ProviderConnectionDto>[
          for (var index = 0; index < statuses.length; index += 1)
            ProviderConnectionDto(
              id: 'status-$index',
              definitionId: 'definition-$index',
              modelPrefix: 'prefix-$index',
              displayName: 'Provider $index',
              status: statuses[index],
              authKind: ProviderAuthKind.none,
              credentialOrigin: ProviderCredentialOrigin.none,
              createdAt: now,
              updatedAt: now,
            ),
        ],
      ),
    );

    expect(find.textContaining('연결 중'), findsOneWidget);
    expect(find.textContaining('연결됨'), findsWidgets);
    expect(find.textContaining('제한된 연결'), findsOneWidget);
    expect(find.textContaining('오류'), findsOneWidget);
    expect(find.textContaining('재로그인 필요'), findsOneWidget);
    expect(find.textContaining('연결 해제됨'), findsOneWidget);
  });

  testWidgets(
    'mobile add and Back move between collection and detail panes',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpSettings(tester, FakeTinestApi());

      expect(
        find.byKey(const ValueKey<String>('provider-connection-openai')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('provider-add-openai')), findsOneWidget);
    },
    tags: const <String>['feature_test__provider_catalog__widget'],
  );

  testWidgets(
    'settings renders disconnected and bootstrap error states',
    (tester) async {
      await _pumpSettings(tester, FakeTinestApi(), autoConnectEnabled: false);
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
    },
    tags: const <String>['feature_test__daemon_authentication__widget'],
  );
}

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
  ),
  matching: find.byType(EditableText),
);

Future<void> _openCatalog(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('provider-add-button')));
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeTinestApi api, {
  bool autoConnectEnabled = true,
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
  await tester.pumpAndSettle();
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
  Future<TinestApi> connect({
    required HostConnection connection,
    required HostConnectionCredential credential,
    required String clientId,
    required String clientKind,
  }) => Future<TinestApi>.error(StateError('connection failed'));
}
