import 'dart:async';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// One running OAuth browser or device-code session.
abstract interface class ProviderOAuthSession {
  /// URL the user must open to continue authorization.
  String get authorizationUrl;

  /// Optional code shown for device authorization.
  String? get userCode;

  /// Optional user-facing instructions.
  String? get instructions;

  /// UTC expiration instant for the attempt.
  DateTime get expiresAt;

  /// Completes with tokens after the remote authorization succeeds.
  Future<OAuthCredential> get completion;

  /// Cancels the callback server or device polling loop.
  Future<void> cancel();
}

/// Starts OpenAI OAuth sessions and refreshes rotating tokens.
abstract interface class ProviderOAuthGateway {
  /// Starts one browser or device-code authorization session.
  Future<ProviderOAuthSession> start(ProviderAuthFlow flow);

  /// Refreshes one OAuth credential, preserving refresh-token rotation.
  Future<OAuthCredential> refresh(OAuthCredential credential);
}

/// Typed OAuth refresh failure with an explicit reauthentication decision.
final class OAuthRefreshFailure implements Exception {
  /// Creates a refresh failure safe to persist as connection status metadata.
  const OAuthRefreshFailure(this.message, {required this.reauthRequired});

  /// Human-readable failure without credential material.
  final String message;

  /// Whether the refresh token is permanently unusable.
  final bool reauthRequired;

  @override
  String toString() => 'OAuthRefreshFailure: $message';
}

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
    OAuthCredential credential, {
    required bool makeDefault,
  });
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
    bool makeDefault = false,
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
      makeDefault: makeDefault,
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
        makeDefault: pending.makeDefault,
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
    required this.makeDefault,
  });

  ProviderAuthAttemptDto attempt;
  final ProviderOAuthSession session;
  final bool makeDefault;
}
