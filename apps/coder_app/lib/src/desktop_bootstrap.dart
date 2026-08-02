import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'bootstrap.dart';

class DesktopBootstrap implements AppBootstrap {
  DesktopBootstrap({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _addressKey = 'tinyrack_coder.host_address';
  static const String _tokenKey = 'tinyrack_coder.host_token';

  final FlutterSecureStorage _storage;
  EmbeddedDaemonHandle? _embedded;

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
      } catch (_) {
        // A previous embedded process is expected to be gone after an app restart.
      }
    }
    _embedded = await EmbeddedDaemonHandle.start(
      DaemonConfig.fromEnvironment(),
    );
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
    final client = await CoderClient.connect(
      endpoint: endpoint,
      clientId: const Uuid().v4(),
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
