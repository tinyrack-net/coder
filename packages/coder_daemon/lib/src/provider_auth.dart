import 'dart:async';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_protocol/coder_protocol.dart';

// The OAuth port types moved to the vendor-neutral port layer so a vendor
// package can implement its own gateway; daemon consumers keep this path.
export 'package:coder_agent/coder_agent.dart'
    show
        OAuthAuthorizationFailure,
        OAuthRefreshFailure,
        ProviderOAuthGateway,
        ProviderOAuthSession;

/// Refreshes one connection credential while preserving token rotation.
abstract interface class ProviderCredentialRefresher {
  /// Returns a fresh credential for one connection.
  Future<OAuthCredential> refresh(
    String connectionId,
    OAuthCredential credential,
  );
}

/// Connects a successfully authorized OAuth credential to a provider.
abstract interface class ProviderOAuthConnector {
  /// Stores and activates one OAuth-backed provider connection.
  Future<void> connectOAuth(
    String definitionId,
    OAuthCredential credential,
  );
}

/// Coordinates transient OAuth state without persisting authorization attempts.
final class ProviderAuthCoordinator {
  /// Creates an authorization coordinator from typed ports.
  factory ProviderAuthCoordinator({
    required ProviderOAuthGateway gateway,
    required ProviderOAuthConnector connector,
    required IdGenerator ids,
  }) => ProviderAuthCoordinator._(
    gateway: gateway,
    connector: connector,
    ids: ids,
  );

  ProviderAuthCoordinator._({
    required this._gateway,
    required this._connector,
    required this._ids,
  });

  final ProviderOAuthGateway _gateway;
  final ProviderOAuthConnector _connector;
  final IdGenerator _ids;
  final Map<String, _PendingAuth> _attempts = <String, _PendingAuth>{};
  final StreamController<ProviderAuthAttemptDto> _events =
      StreamController<ProviderAuthAttemptDto>.broadcast(sync: true);

  /// Authorization attempt updates safe to broadcast to clients.
  Stream<ProviderAuthAttemptDto> get events => _events.stream;

  /// Starts an OpenAI browser or device-code OAuth flow.
  Future<ProviderAuthAttemptDto> start({
    required String definitionId,
    required String methodId,
  }) async {
    if (definitionId != 'openai') {
      throw StateError('OAuth is only available for the OpenAI definition.');
    }
    final flow = switch (methodId) {
      'chatgpt-browser' => ProviderAuthFlow.oauthBrowser,
      'chatgpt-device' => ProviderAuthFlow.oauthDevice,
      _ => throw StateError('Unknown OpenAI OAuth method: $methodId'),
    };
    final session = await _gateway.start(flow);
    final attempt = ProviderAuthAttemptDto(
      id: _ids.generate(),
      definitionId: definitionId,
      methodId: methodId,
      status: ProviderAuthAttemptStatus.awaitingUser,
      authorizationUrl: session.authorizationUrl,
      userCode: session.userCode,
      instructions: session.instructions,
      expiresAt: session.expiresAt,
    );
    final pending = _PendingAuth(
      attempt: attempt,
      session: session,
    );
    _attempts[attempt.id] = pending;
    _events.add(attempt);
    unawaited(_complete(pending));
    return attempt;
  }

  /// Returns the current state of one authorization attempt.
  Future<ProviderAuthAttemptDto> status(String attemptId) async {
    final pending = _attempts[attemptId];
    if (pending == null) {
      throw StateError('Provider authorization attempt not found: $attemptId');
    }
    return pending.attempt;
  }

  /// Cancels one pending authorization attempt.
  Future<void> cancel(String attemptId) async {
    final pending = _attempts[attemptId];
    if (pending == null) {
      throw StateError('Provider authorization attempt not found: $attemptId');
    }
    if (_isTerminal(pending.attempt.status)) return;
    pending.attempt = pending.attempt.copyWith(
      status: ProviderAuthAttemptStatus.cancelled,
    );
    await pending.session.cancel();
    _events.add(pending.attempt);
  }

  Future<void> _complete(_PendingAuth pending) async {
    try {
      final credential = await pending.session.completion;
      if (pending.attempt.status == ProviderAuthAttemptStatus.cancelled) return;
      pending.attempt = pending.attempt.copyWith(
        status: ProviderAuthAttemptStatus.exchanging,
      );
      _events.add(pending.attempt);
      await _connector.connectOAuth(
        pending.attempt.definitionId,
        credential,
      );
      pending.attempt = pending.attempt.copyWith(
        status: ProviderAuthAttemptStatus.succeeded,
      );
    } on TimeoutException catch (error) {
      if (pending.attempt.status == ProviderAuthAttemptStatus.cancelled) return;
      pending.attempt = pending.attempt.copyWith(
        status: ProviderAuthAttemptStatus.expired,
        error: '$error',
      );
    } on Exception catch (error) {
      if (pending.attempt.status == ProviderAuthAttemptStatus.cancelled) return;
      pending.attempt = pending.attempt.copyWith(
        status: ProviderAuthAttemptStatus.failed,
        error: '$error',
      );
    }
    _events.add(pending.attempt);
  }

  /// Cancels active sessions and closes the update stream.
  Future<void> close() async {
    for (final pending in _attempts.values) {
      if (!_isTerminal(pending.attempt.status)) await pending.session.cancel();
    }
    await _events.close();
  }

  static bool _isTerminal(ProviderAuthAttemptStatus status) =>
      status == ProviderAuthAttemptStatus.succeeded ||
      status == ProviderAuthAttemptStatus.failed ||
      status == ProviderAuthAttemptStatus.cancelled ||
      status == ProviderAuthAttemptStatus.expired;
}

/// Deduplicates concurrent refreshes because OpenAI rotates refresh tokens.
final class OAuthCredentialRefresher implements ProviderCredentialRefresher {
  /// Creates a single-flight token refresher.
  factory OAuthCredentialRefresher({required ProviderOAuthGateway gateway}) =>
      OAuthCredentialRefresher._(gateway);

  OAuthCredentialRefresher._(this._gateway);

  final ProviderOAuthGateway _gateway;
  final Map<String, Future<OAuthCredential>> _inFlight =
      <String, Future<OAuthCredential>>{};

  /// Refreshes at most once concurrently for each provider connection.
  @override
  Future<OAuthCredential> refresh(
    String connectionId,
    OAuthCredential credential,
  ) {
    final existing = _inFlight[connectionId];
    if (existing != null) return existing;
    final operation = _gateway.refresh(credential);
    _inFlight[connectionId] = operation;
    unawaited(
      operation.then<void>(
        (_) {
          final _ = _inFlight.remove(connectionId);
        },
        onError: (Object _, StackTrace _) {
          final _ = _inFlight.remove(connectionId);
        },
      ),
    );
    return operation;
  }
}

final class _PendingAuth {
  _PendingAuth({
    required this.attempt,
    required this.session,
  });

  ProviderAuthAttemptDto attempt;
  final ProviderOAuthSession session;
}
