import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/app_storage.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates remote-only mobile services; no daemon launcher is reachable.
Future<AppServices> createRemoteServices({
  HostClientFactory clients = const WebSocketHostClientFactory(),
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
}) async {
  final store = SharedPreferencesAppStore(
    await SharedPreferences.getInstance(),
  );
  return AppServices(
    settings: store,
    profiles: store,
    credentials: SecureRemoteHostCredentialStore(secureStorage),
    clients: clients,
    clientKind: 'mobile',
  );
}
