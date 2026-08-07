import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_app/src/features/hosts/infrastructure/app_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates remote-only services; no daemon launcher is reachable.
///
/// Mobile and the web share this path: neither can host a daemon, so both
/// only ever connect to one the user runs elsewhere.
Future<AppServices> createRemoteServices({
  HostClientFactory clients = const WebSocketHostClientFactory(),
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  String clientKind = 'mobile',
}) async {
  final store = SharedPreferencesAppStore(
    await SharedPreferences.getInstance(),
  );
  return AppServices(
    settings: store,
    profiles: store,
    credentials: SecureRemoteHostCredentialStore(secureStorage),
    clients: clients,
    clientKind: clientKind,
  );
}
