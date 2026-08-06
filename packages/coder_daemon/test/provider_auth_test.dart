import 'dart:async';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test(
    'coordinator publishes attempt state and stores completed OAuth',
    () async {
      final gateway = _Gateway(now);
      final connector = _OAuthConnector();
      final coordinator = ProviderAuthCoordinator(
        gateway: gateway,
        connector: connector,
        ids: const _Ids(),
      );
      addTearDown(coordinator.close);
      final events = <ProviderAuthAttemptDto>[];
      final subscription = coordinator.events.listen(events.add);
      addTearDown(subscription.cancel);

      final attempt = await coordinator.start(
        definitionId: 'openai',
        methodId: 'chatgpt-device',
      );

      expect(attempt.id, 'auth-attempt');
      expect(attempt.status, ProviderAuthAttemptStatus.awaitingUser);
      expect(attempt.authorizationUrl, 'https://auth.example/device');
      expect(attempt.userCode, 'CODE-1234');
      gateway.session.completer.complete(
        OAuthCredential(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(
        (await coordinator.status(attempt.id)).status,
        ProviderAuthAttemptStatus.succeeded,
      );
      expect(connector.connectionId, 'openai');
      expect(connector.credential, isA<OAuthCredential>());
      expect(events.last.status, ProviderAuthAttemptStatus.succeeded);
    },
    tags: const <String>['feature_test__provider_oauth__unit'],
  );

  test('cancel stops the session and ignores late completion', () async {
    final gateway = _Gateway(now);
    final connector = _OAuthConnector();
    final coordinator = ProviderAuthCoordinator(
      gateway: gateway,
      connector: connector,
      ids: const _Ids(),
    );
    addTearDown(coordinator.close);
    final attempt = await coordinator.start(
      definitionId: 'openai',
      methodId: 'chatgpt-browser',
    );

    await coordinator.cancel(attempt.id);

    expect(gateway.session.cancelled, isTrue);
    expect(
      (await coordinator.status(attempt.id)).status,
      ProviderAuthAttemptStatus.cancelled,
    );
    expect(connector.credential, isNull);
  });

  test(
    'timeout expires an attempt and rejects unsupported OAuth routes',
    () async {
      final gateway = _Gateway(now);
      final coordinator = ProviderAuthCoordinator(
        gateway: gateway,
        connector: _OAuthConnector(),
        ids: const _Ids(),
      );
      addTearDown(coordinator.close);
      final attempt = await coordinator.start(
        definitionId: 'openai',
        methodId: 'chatgpt-device',
      );
      gateway.session.completer.completeError(TimeoutException('expired'));
      await Future<void>.delayed(Duration.zero);

      expect(
        (await coordinator.status(attempt.id)).status,
        ProviderAuthAttemptStatus.expired,
      );
      await expectLater(
        coordinator.start(
          definitionId: 'deepseek',
          methodId: 'chatgpt-device',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'credential refresher is single-flight and rotates refresh token',
    () async {
      final gateway = _Gateway(now);
      final refresher = OAuthCredentialRefresher(gateway: gateway);
      final expired = OAuthCredential(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
        expiresAt: now,
      );

      final first = refresher.refresh('openai', expired);
      final second = refresher.refresh('openai', expired);
      expect(identical(first, second), isTrue);
      gateway.refreshCompleter.complete(
        OAuthCredential(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
          expiresAt: now.add(const Duration(hours: 1)),
        ),
      );

      final refreshed = await first;
      expect(refreshed.accessToken, 'new-access');
      expect(refreshed.refreshToken, 'new-refresh');
      expect(gateway.refreshCalls, 1);
    },
  );

  test(
    'failed authorization, missing IDs, and terminal cancellation are safe',
    () async {
      expect(
        const OAuthRefreshFailure(
          'invalid grant',
          reauthRequired: true,
        ).toString(),
        'OAuthRefreshFailure: invalid grant',
      );
      final gateway = _Gateway(now);
      final coordinator = ProviderAuthCoordinator(
        gateway: gateway,
        connector: _OAuthConnector(),
        ids: const _Ids(),
      );
      addTearDown(coordinator.close);

      await expectLater(
        coordinator.start(definitionId: 'openai', methodId: 'unknown'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        coordinator.status('missing'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        coordinator.cancel('missing'),
        throwsA(isA<StateError>()),
      );

      final attempt = await coordinator.start(
        definitionId: 'openai',
        methodId: 'chatgpt-browser',
      );
      gateway.session.completer.completeError(
        const OAuthAuthorizationFailure('The user denied the request.'),
      );
      await Future<void>.delayed(Duration.zero);
      final failed = await coordinator.status(attempt.id);
      expect(failed.status, ProviderAuthAttemptStatus.failed);
      // The attempt tile shows this verbatim, so it must stay a plain sentence.
      expect(failed.error, 'The user denied the request.');
      await coordinator.cancel(attempt.id);
      expect(gateway.session.cancelled, isFalse);
    },
  );

  test('failed refresh is removed from the single-flight cache', () async {
    final gateway = _RetryGateway(now);
    final refresher = OAuthCredentialRefresher(gateway: gateway);
    final credential = OAuthCredential(
      accessToken: 'old',
      refreshToken: 'refresh',
      expiresAt: now,
    );

    await expectLater(
      refresher.refresh('openai', credential),
      throwsA(isA<StateError>()),
    );
    final refreshed = await refresher.refresh('openai', credential);
    expect(refreshed.accessToken, 'fresh');
    expect(gateway.calls, 2);
  });
}

final class _RetryGateway implements ProviderOAuthGateway {
  _RetryGateway(this.now);

  final DateTime now;
  int calls = 0;

  @override
  Future<OAuthCredential> refresh(OAuthCredential credential) async {
    calls += 1;
    if (calls == 1) throw StateError('temporary');
    return OAuthCredential(
      accessToken: 'fresh',
      refreshToken: credential.refreshToken,
      expiresAt: now.add(const Duration(hours: 1)),
    );
  }

  @override
  Future<ProviderOAuthSession> start(ProviderAuthFlow flow) =>
      Future<ProviderOAuthSession>.error(UnsupportedError('not used'));
}

final class _Ids implements IdGenerator {
  const _Ids();

  @override
  String generate() => 'auth-attempt';
}

final class _Gateway implements ProviderOAuthGateway {
  _Gateway(this.now);

  final DateTime now;
  late _Session session;
  final Completer<OAuthCredential> refreshCompleter =
      Completer<OAuthCredential>();
  int refreshCalls = 0;

  @override
  Future<ProviderOAuthSession> start(ProviderAuthFlow flow) async =>
      session = _Session(
        flow: flow,
        expiresAt: now.add(const Duration(minutes: 15)),
      );

  @override
  Future<OAuthCredential> refresh(OAuthCredential credential) {
    refreshCalls += 1;
    return refreshCompleter.future;
  }
}

final class _Session implements ProviderOAuthSession {
  _Session({required this.flow, required this.expiresAt});

  final ProviderAuthFlow flow;
  final Completer<OAuthCredential> completer = Completer<OAuthCredential>();
  bool cancelled = false;

  @override
  String get authorizationUrl => flow == ProviderAuthFlow.oauthDevice
      ? 'https://auth.example/device'
      : 'https://auth.example/authorize';

  @override
  Future<OAuthCredential> get completion => completer.future;

  @override
  final DateTime expiresAt;

  @override
  String? get instructions => 'Complete sign in';

  @override
  String? get userCode =>
      flow == ProviderAuthFlow.oauthDevice ? 'CODE-1234' : null;

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

final class _OAuthConnector implements ProviderOAuthConnector {
  String? connectionId;
  OAuthCredential? credential;

  @override
  Future<void> connectOAuth(
    String definitionId,
    OAuthCredential credential,
  ) async {
    connectionId = definitionId;
    this.credential = credential;
  }
}
