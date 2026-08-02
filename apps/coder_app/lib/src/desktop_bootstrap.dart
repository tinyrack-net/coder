import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A running embedded daemon exposed without leaking its concrete handle.
abstract interface class EmbeddedDaemonSession {
  /// The WebSocket endpoint bound by the daemon.
  Uri get boundEndpoint;

  /// The bearer token generated for this daemon.
  String get bearerToken;

  /// Stops the embedded daemon.
  Future<void> stop();
}

/// Starts an embedded daemon session for the desktop bootstrap.
abstract interface class EmbeddedDaemonLauncher {
  /// Starts a daemon using the current process environment.
  Future<EmbeddedDaemonSession> start();
}

/// Production launcher backed by [EmbeddedDaemonHandle].
final class IsolateEmbeddedDaemonLauncher implements EmbeddedDaemonLauncher {
  /// Creates the production embedded daemon launcher.
  const IsolateEmbeddedDaemonLauncher();

  @override
  Future<EmbeddedDaemonSession> start() async => _DaemonSession(
    await EmbeddedDaemonHandle.start(DaemonConfig.fromEnvironment()),
  );
}

final class _DaemonSession implements EmbeddedDaemonSession {
  const _DaemonSession(this._handle);

  final EmbeddedDaemonHandle _handle;

  @override
  String get bearerToken => _handle.bearerToken;

  @override
  Uri get boundEndpoint => _handle.boundEndpoint;

  @override
  Future<void> stop() => _handle.stop();
}

/// DesktopBootstrap defines a public contract.
class DesktopBootstrap implements AppBootstrap {
  /// Creates a [DesktopBootstrap].
  DesktopBootstrap({
    FlutterSecureStorage? storage,
    this._ids = const UuidAppIdGenerator(),
    this._connector = const WebSocketAppClientConnector(),
    this._launcher = const IsolateEmbeddedDaemonLauncher(),
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const String _addressKey = 'tinyrack_coder.host_address';
  static const String _tokenKey = 'tinyrack_coder.host_token';

  final FlutterSecureStorage _storage;
  final AppIdGenerator _ids;
  final AppClientConnector _connector;
  final EmbeddedDaemonLauncher _launcher;
  EmbeddedDaemonSession? _embedded;

  @override
  bool get canRegisterLocalWorkspace => true;

  @override
  Future<BootstrapConnection?> autoConnect() async {
    final savedAddress = await _storage.read(key: _addressKey);
    final savedToken = await _storage.read(key: _tokenKey);
    if (savedAddress != null && savedToken != null) {
      try {
        return await _connect(
          HostEndpoint.parse(savedAddress, token: savedToken),
          persist: false,
        );
      } on Exception {
        // A previous embedded process is expected to be gone after an app
        // restart.
      }
    }
    _embedded = await _launcher.start();
    final endpoint = HostEndpoint(
      websocketUri: _embedded!.boundEndpoint,
      token: _embedded!.bearerToken,
    );
    await _storage.write(
      key: _addressKey,
      value: endpoint.websocketUri.toString(),
    );
    await _storage.write(key: _tokenKey, value: endpoint.token);
    return _connect(endpoint, persist: false);
  }

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) async {
    await _embedded?.stop();
    _embedded = null;
    return _connect(endpoint, persist: true);
  }

  Future<BootstrapConnection> _connect(
    HostEndpoint endpoint, {
    required bool persist,
  }) async {
    final client = await _connector.connect(
      endpoint: endpoint,
      clientId: _ids.generate(),
      clientKind: 'desktop',
    );
    if (persist) {
      await _storage.write(
        key: _addressKey,
        value: endpoint.websocketUri.toString(),
      );
      await _storage.write(key: _tokenKey, value: endpoint.token);
    }
    return BootstrapConnection(client: client, endpoint: endpoint);
  }

  @override
  Future<void> close() async {
    await _embedded?.stop();
    _embedded = null;
  }
}
