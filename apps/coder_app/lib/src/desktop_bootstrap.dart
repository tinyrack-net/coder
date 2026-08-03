import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/app_storage.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts one embedded daemon from a resolved configuration.
typedef EmbeddedDaemonStarter =
    Future<DaemonHandle> Function(DaemonConfig config);

/// Creates production desktop services after local settings storage is ready.
Future<AppServices> createDesktopServices({
  EmbeddedDaemonLauncher embeddedLauncher =
      const IsolateEmbeddedDaemonLauncher(),
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
  );
}

/// Starts an embedded daemon isolate without connecting the GUI client.
final class IsolateEmbeddedDaemonLauncher implements EmbeddedDaemonLauncher {
  /// Creates the production embedded daemon launcher.
  const IsolateEmbeddedDaemonLauncher({
    this.config,
    this.startDaemon = _startEmbeddedDaemon,
  });

  /// Explicit configuration used by deterministic integration tests.
  final DaemonConfig? config;

  /// Injected isolate starter used by deterministic tests.
  final EmbeddedDaemonStarter startDaemon;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
  }) async {
    try {
      final baseConfig = config ?? DaemonConfig.fromEnvironment();
      return _EmbeddedSession(
        await startDaemon(baseConfig.copyWith(host: exposure.bindHost)),
      );
    } on Exception catch (error) {
      throw HostConnectionFailure.network('$error');
    }
  }
}

Future<DaemonHandle> _startEmbeddedDaemon(DaemonConfig config) =>
    EmbeddedDaemonHandle.start(config);

final class _EmbeddedSession implements EmbeddedDaemonSession {
  const _EmbeddedSession(this._handle);

  final DaemonHandle _handle;

  @override
  DaemonCredentials get credentials => DaemonCredentials(
    bearerToken: _handle.bearerToken,
  );

  @override
  HostEndpoint get endpoint => HostEndpoint(
    websocketUri: _handle.boundEndpoint,
  );

  @override
  String get serverId => _handle.serverId;

  @override
  Future<void> stop() => _handle.stop();
}
