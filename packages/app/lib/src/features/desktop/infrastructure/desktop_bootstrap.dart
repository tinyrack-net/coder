import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/features/hosts/infrastructure/app_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates desktop services around daemon adapters supplied by the desktop
/// composition root.
Future<AppServices> createDesktopServices({
  required EmbeddedDaemonLauncher embeddedLauncher,
  required EmbeddedDaemonDataEraser embeddedDataEraser,
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
    clientKind: 'desktop',
    embeddedLauncher: embeddedLauncher,
    embeddedDataEraser: embeddedDataEraser,
  );
}
