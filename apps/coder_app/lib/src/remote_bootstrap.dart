import 'package:coder_client/coder_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'bootstrap.dart';

class RemoteBootstrap implements AppBootstrap {
  RemoteBootstrap({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _addressKey = 'tinyrack_coder.host_address';
  static const String _tokenKey = 'tinyrack_coder.host_token';

  final FlutterSecureStorage _storage;

  @override
  bool get canRegisterLocalWorkspace => false;

  @override
  Future<BootstrapConnection?> autoConnect() async {
    final address = await _storage.read(key: _addressKey);
    final token = await _storage.read(key: _tokenKey);
    if (address == null || token == null) return null;
    return _connect(HostEndpoint.parse(address, token: token), persist: false);
  }

  @override
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint) =>
      _connect(endpoint, persist: true);

  Future<BootstrapConnection> _connect(
    HostEndpoint endpoint, {
    required bool persist,
  }) async {
    final client = await CoderClient.connect(
      endpoint: endpoint,
      clientId: const Uuid().v4(),
      clientKind: 'mobile',
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
  Future<void> close() async {}
}
