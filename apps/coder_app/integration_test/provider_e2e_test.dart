import 'dart:async';

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/pump_until.dart';
import 'support/real_daemon_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'catalog failure remains visible and a retry refreshes daemon metadata',
    (tester) async {
      final metadata = _RetryingMetadataSource();
      final fixture = await RealDaemonFixture.start(
        id: 'provider-catalog',
        providerCatalogMetadataSource: metadata,
      );
      addTearDown(fixture.dispose);
      final assertions = await fixture.connect();
      addTearDown(assertions.close);

      await _pumpProviderSettings(tester, fixture);
      final refresh = find.byKey(
        const ValueKey<String>('provider-catalog-refresh'),
      );

      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.textContaining('planned catalog outage'), findsOneWidget);
      expect(
        (await assertions.listProviderCatalog()).source,
        ProviderCatalogSource.bundled,
      );

      await tester.tap(refresh);
      await tester.pumpAndSettle();
      expect(find.textContaining('planned catalog outage'), findsNothing);
      expect(metadata.calls, 2);
      expect(
        (await assertions.listProviderCatalog()).source,
        ProviderCatalogSource.refreshed,
      );
      expect(
        (await assertions.refreshProviderCatalog()).source,
        ProviderCatalogSource.refreshed,
      );
    },
    tags: const <String>[
      'feature_scenario__provider_catalog__catalog_failure_retry__e2e',
    ],
  );

  testWidgets(
    'OAuth recovers from failure and cancellation before connecting',
    (tester) async {
      final oauth = _ControlledOAuthGateway();
      final fixture = await RealDaemonFixture.start(
        id: 'provider-oauth',
        modelDiscovery: const _StaticModelDiscovery(),
        oauthGateway: oauth,
        providerCatalogMetadataSource: _SuccessfulMetadataSource(),
      );
      addTearDown(fixture.dispose);
      final assertions = await fixture.connect();
      addTearDown(assertions.close);

      await _pumpProviderSettings(tester, fixture);

      await _startDeviceOAuth(tester);
      oauth.sessions.single.fail('planned authorization failure');
      await pumpUntilCondition(
        tester,
        () => find
            .textContaining('planned authorization failure')
            .evaluate()
            .isNotEmpty,
        'the failed authorization message',
      );
      // The tile shows the reason itself, never a transport exception name.
      expect(find.textContaining('Exception'), findsNothing);

      await _startDeviceOAuth(tester);
      final cancelled = oauth.sessions.last;
      final cancel = _authCancelButton();
      expect(cancel, findsOneWidget);
      await tester.tap(cancel);
      await pumpUntilCondition(
        tester,
        () => cancelled.cancelled,
        'the cancelled device authorization to report it',
      );
      expect(cancelled.cancelled, isTrue);

      await _startDeviceOAuth(tester);
      oauth.sessions.last.succeed(
        OAuthCredential(
          accessToken: 'oauth-access-token',
          refreshToken: 'oauth-refresh-token',
          expiresAt: DateTime.utc(2026, 8, 5, 13),
          accountId: 'e2e-account',
        ),
      );
      await pumpUntilCondition(
        tester,
        () async {
          final connections = await assertions.listProviderConnections();
          return connections.any(
            (connection) =>
                connection.definitionId == 'openai' &&
                connection.status == ProviderConnectionStatus.connected,
          );
        },
        'the OAuth connection to report connected',
      );

      final connection = (await assertions.listProviderConnections())
          .singleWhere((item) => item.definitionId == 'openai');
      expect(connection.credentialOrigin, ProviderCredentialOrigin.oauth);
      expect(connection.status, ProviderConnectionStatus.connected);
      // The ChatGPT endpoint has no `/models` listing, so the connected
      // catalog is the bundled one and discovery never runs.
      final oauthModels = (await assertions.listProviderModels(
        connection.id,
      )).map((model) => model.id);
      expect(oauthModels, contains('gpt-5.6-sol'));
      expect(oauthModels, isNot(contains('oauth-e2e-model')));

      await tester.tap(
        find.byKey(const ValueKey<String>('provider-catalog-refresh')),
      );
      await tester.pumpAndSettle();
      expect(
        (await assertions.listProviderCatalog()).source,
        ProviderCatalogSource.refreshed,
      );
    },
    tags: const <String>[
      'feature_scenario__provider_oauth__authorize_and_refresh__e2e',
      'feature_scenario__provider_oauth__cancel_and_error_recovery__e2e',
    ],
  );
}

Future<void> _pumpProviderSettings(
  WidgetTester tester,
  RealDaemonFixture fixture,
) async {
  tester.binding.platformDispatcher.localeTestValue = const Locale('en');
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
  await tester.pumpWidget(CoderApp(services: fixture.services));
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(CoderIcons.settings));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Provider'));
  await tester.pumpAndSettle();
}

Future<void> _startDeviceOAuth(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('provider-add-openai')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in with device code'));
  await tester.pump();
  await pumpUntilCondition(
    tester,
    () => _authCancelButton().evaluate().isNotEmpty,
    'the device authorization prompt',
  );
}

Finder _authCancelButton() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('provider-auth-cancel-');
});

final class _RetryingMetadataSource implements ProviderCatalogMetadataSource {
  int calls = 0;

  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async {
    calls += 1;
    if (calls == 1) throw StateError('planned catalog outage');
    return _metadata(providerIds);
  }
}

final class _SuccessfulMetadataSource implements ProviderCatalogMetadataSource {
  @override
  Future<Map<String, List<ProviderCatalogMetadata>>> fetch(
    Set<String> providerIds,
  ) async => _metadata(providerIds);
}

Map<String, List<ProviderCatalogMetadata>> _metadata(
  Set<String> providerIds,
) => <String, List<ProviderCatalogMetadata>>{
  if (providerIds.contains('openai'))
    'openai': const <ProviderCatalogMetadata>[
      ProviderCatalogMetadata(
        id: 'refreshed-e2e-model',
        label: 'Refreshed E2E model',
        capabilities: ModelCapabilitiesDto(
          streaming: CapabilitySupport.supported,
          toolCalling: CapabilitySupport.supported,
          reasoningEffort: CapabilitySupport.supported,
          source: CapabilitySource.refreshed,
        ),
      ),
    ],
};

final class _StaticModelDiscovery implements ProviderModelDiscovery {
  const _StaticModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  ) async => const <String>['oauth-e2e-model'];
}

final class _ControlledOAuthGateway implements ProviderOAuthGateway {
  final List<_ControlledOAuthSession> sessions = <_ControlledOAuthSession>[];

  @override
  Future<OAuthCredential> refresh(OAuthCredential credential) async =>
      credential;

  @override
  Future<ProviderOAuthSession> start(ProviderAuthFlow flow) async {
    final session = _ControlledOAuthSession(flow);
    sessions.add(session);
    return session;
  }
}

final class _ControlledOAuthSession implements ProviderOAuthSession {
  _ControlledOAuthSession(this.flow);

  final ProviderAuthFlow flow;
  final Completer<({OAuthCredential? credential, String? error})> _result =
      Completer<({OAuthCredential? credential, String? error})>();
  bool cancelled = false;

  void fail(String message) => _result.complete(
    (credential: null, error: message),
  );

  void succeed(OAuthCredential credential) => _result.complete(
    (credential: credential, error: null),
  );

  @override
  String get authorizationUrl => 'https://auth.invalid/${flow.name}';

  @override
  Future<OAuthCredential> get completion async {
    final result = await _result.future;
    // Mirrors the real gateway, which reports a plain sentence rather than a
    // transport exception the user cannot act on.
    if (result.error case final error?) throw OAuthAuthorizationFailure(error);
    return result.credential!;
  }

  @override
  DateTime get expiresAt => DateTime.utc(2026, 8, 5, 13);

  @override
  String? get instructions => 'Complete deterministic authorization.';

  @override
  String? get userCode => 'E2E-CODE';

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!_result.isCompleted) {
      _result.complete((credential: null, error: 'authorization cancelled'));
    }
  }
}
