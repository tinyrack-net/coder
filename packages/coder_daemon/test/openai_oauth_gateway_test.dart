import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coder_daemon/src/openai_oauth_gateway.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);

  test('browser OAuth validates state and exchanges PKCE code', () async {
    final adapter = _OAuthAdapter(now);
    final gateway = OpenAIOAuthGateway(
      clock: _Clock(now),
      dio: Dio()..httpClientAdapter = adapter,
      callbackServerBinder: const _EphemeralBinder(),
    );

    final session = await gateway.start(ProviderAuthFlow.oauthBrowser);
    final authorization = Uri.parse(session.authorizationUrl);
    final redirect = Uri.parse(authorization.queryParameters['redirect_uri']!);
    final state = authorization.queryParameters['state']!;
    expect(authorization.queryParameters['code_challenge_method'], 'S256');
    expect(authorization.queryParameters['code_challenge'], isNotEmpty);

    expect(
      await _callback(redirect, state: 'wrong', code: 'ignored'),
      HttpStatus.badRequest,
    );
    expect(
      await _callback(redirect, state: state, code: 'authorization-code'),
      HttpStatus.ok,
    );
    final credential = await session.completion;

    expect(credential.accessToken, adapter.accessToken);
    expect(credential.refreshToken, 'refresh-new');
    expect(credential.accountId, 'account-123');
    expect(adapter.exchangeData['code'], 'authorization-code');
    expect(adapter.exchangeData['code_verifier'], isNotEmpty);
  });

  test('device flow polls, rotates tokens, and can be cancelled', () async {
    final adapter = _OAuthAdapter(now)..pendingDevicePolls = 1;
    var delays = 0;
    final gateway = OpenAIOAuthGateway(
      clock: _Clock(now),
      dio: Dio()..httpClientAdapter = adapter,
      delay: (_) async => delays += 1,
    );

    final session = await gateway.start(ProviderAuthFlow.oauthDevice);
    expect(session.authorizationUrl, 'https://auth.openai.com/codex/device');
    expect(session.userCode, 'CODE-1234');
    final credential = await session.completion;

    expect(credential.refreshToken, 'refresh-new');
    expect(delays, 1);

    final pendingAdapter = _OAuthAdapter(now)..pendingDevicePolls = 100;
    final pending = OpenAIOAuthGateway(
      clock: _Clock(now),
      dio: Dio()..httpClientAdapter = pendingAdapter,
      delay: (_) async {},
    );
    final cancelled = await pending.start(ProviderAuthFlow.oauthDevice);
    await cancelled.cancel();
    await expectLater(cancelled.completion, throwsA(isA<StateError>()));
  });

  test('refresh preserves rotation and classifies invalid_grant', () async {
    final adapter = _OAuthAdapter(now);
    final gateway = OpenAIOAuthGateway(
      clock: _Clock(now),
      dio: Dio()..httpClientAdapter = adapter,
    );
    final refreshed = await gateway.refresh(
      OAuthCredential(
        accessToken: 'old',
        refreshToken: 'refresh-old',
        expiresAt: now,
        accountId: 'fallback-account',
      ),
    );
    expect(refreshed.refreshToken, 'refresh-new');
    expect(adapter.refreshData['refresh_token'], 'refresh-old');

    adapter.invalidGrant = true;
    await expectLater(
      gateway.refresh(refreshed),
      throwsA(
        isA<OAuthRefreshFailure>().having(
          (error) => error.reauthRequired,
          'reauthRequired',
          isTrue,
        ),
      ),
    );
  });

  test(
    'loopback callback binder falls back when its primary port is busy',
    () async {
      final occupied = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final binder = LoopbackOAuthCallbackServerBinder(
        primaryPort: occupied.port,
        fallbackPort: 0,
      );

      final server = await binder.bind();
      try {
        expect(server.port, isNot(occupied.port));
        expect(server.port, greaterThan(0));
      } finally {
        await server.close(force: true);
        await occupied.close(force: true);
      }
    },
  );
}

Future<int> _callback(
  Uri redirect, {
  required String state,
  required String code,
}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      redirect.replace(
        queryParameters: <String, String>{'state': state, 'code': code},
      ),
    );
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

final class _Clock implements Clock {
  const _Clock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _EphemeralBinder implements OAuthCallbackServerBinder {
  const _EphemeralBinder();

  @override
  Future<HttpServer> bind() => HttpServer.bind(InternetAddress.loopbackIPv4, 0);
}

final class _OAuthAdapter implements HttpClientAdapter {
  _OAuthAdapter(this.now)
    : accessToken = _jwt(<String, dynamic>{
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        'chatgpt_account_id': 'account-123',
      });

  final DateTime now;
  final String accessToken;
  int pendingDevicePolls = 0;
  bool invalidGrant = false;
  Map<String, dynamic> exchangeData = <String, dynamic>{};
  Map<String, dynamic> refreshData = <String, dynamic>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/api/accounts/deviceauth/usercode')) {
      return _json(<String, dynamic>{
        'device_auth_id': 'device-id',
        'user_code': 'CODE-1234',
        'interval': '1',
      });
    }
    if (options.path.endsWith('/api/accounts/deviceauth/token')) {
      if (pendingDevicePolls > 0) {
        pendingDevicePolls -= 1;
        return _json(<String, dynamic>{'error': 'authorization_pending'}, 403);
      }
      return _json(<String, dynamic>{
        'authorization_code': 'device-code',
        'code_verifier': 'device-verifier',
      });
    }
    if (options.path.endsWith('/oauth/token')) {
      final data = Map<String, dynamic>.from(options.data as Map);
      if (data['grant_type'] == 'refresh_token') {
        refreshData = data;
        if (invalidGrant) {
          return _json(<String, dynamic>{'error': 'invalid_grant'}, 400);
        }
      } else {
        exchangeData = data;
      }
      return _json(<String, dynamic>{
        'access_token': accessToken,
        'refresh_token': 'refresh-new',
      });
    }
    return _json(<String, dynamic>{'error': 'not_found'}, 404);
  }

  static ResponseBody _json(Map<String, dynamic> value, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(value),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

String _jwt(Map<String, dynamic> claims) =>
    '${base64Url.encode(utf8.encode('{}')).replaceAll('=', '')}.'
    '${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.';
