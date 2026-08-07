import 'package:coder_app/src/app/composition/app_services.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_app/src/features/hosts/infrastructure/app_storage.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts one embedded daemon from a resolved configuration.
typedef EmbeddedDaemonStarter =
    Future<DaemonHandle> Function(DaemonConfig config);

/// Resolves the directories and listener the embedded daemon owns.
typedef DaemonConfigResolver = DaemonConfig Function();

/// Creates production desktop services after local settings storage is ready.
Future<AppServices> createDesktopServices({
  EmbeddedDaemonLauncher? embeddedLauncher,
  EmbeddedDaemonDataEraser? embeddedDataEraser,
  HostClientFactory clients = const WebSocketHostClientFactory(),
  FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
}) async {
  final store = SharedPreferencesAppStore(
    await SharedPreferences.getInstance(),
  );
  // One memoized resolution shared by the launcher and the eraser: an
  // environment change mid-run must never point them at different trees.
  DaemonConfig? resolved;
  DaemonConfig resolveConfig() => resolved ??= DaemonConfig.fromEnvironment();
  return AppServices(
    settings: store,
    profiles: store,
    credentials: SecureRemoteHostCredentialStore(secureStorage),
    clients: clients,
    clientKind: 'desktop',
    embeddedLauncher:
        embeddedLauncher ??
        IsolateEmbeddedDaemonLauncher(resolveConfig: resolveConfig),
    embeddedDataEraser:
        embeddedDataEraser ??
        IsolateEmbeddedDaemonDataEraser(resolveConfig: resolveConfig),
  );
}

/// Starts an embedded daemon isolate without connecting the GUI client.
final class IsolateEmbeddedDaemonLauncher implements EmbeddedDaemonLauncher {
  /// Creates the production embedded daemon launcher.
  const IsolateEmbeddedDaemonLauncher({
    this.resolveConfig = DaemonConfig.fromEnvironment,
    this.startDaemon = _startEmbeddedDaemon,
  });

  /// Resolves the base configuration; tests substitute a temporary tree.
  final DaemonConfigResolver resolveConfig;

  /// Injected isolate starter used by deterministic tests.
  final EmbeddedDaemonStarter startDaemon;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) async {
    try {
      final baseConfig = resolveConfig();
      return _EmbeddedSession(
        await startDaemon(
          baseConfig.copyWith(host: exposure.bindHost, port: port),
        ),
      );
    } on EmbeddedDaemonStartupException catch (error) {
      throw HostConnectionFailure.network(
        error.message,
        reason: switch (error.reason) {
          EmbeddedDaemonStartupFailureReason.portInUse =>
            HostFailureReason.embeddedPortInUse,
          EmbeddedDaemonStartupFailureReason.alreadyRunning =>
            HostFailureReason.embeddedAlreadyRunning,
          EmbeddedDaemonStartupFailureReason.unknown => null,
        },
      );
    } on Exception catch (error) {
      throw HostConnectionFailure.network('$error');
    }
  }
}

/// Erases the app-owned daemon's stored data from disk.
final class IsolateEmbeddedDaemonDataEraser
    implements EmbeddedDaemonDataEraser {
  /// Creates the production embedded daemon data eraser.
  const IsolateEmbeddedDaemonDataEraser({
    this.resolveConfig = DaemonConfig.fromEnvironment,
  });

  /// Resolves the directories to erase; tests substitute a temporary tree.
  final DaemonConfigResolver resolveConfig;

  @override
  Future<void> eraseAll() async {
    final config = resolveConfig();
    try {
      await DaemonDataReset(
        configDirectory: config.configDirectory,
        homeDirectory: config.homeDirectory,
      ).eraseAll();
    } on DaemonDataResetException catch (error) {
      throw FactoryResetFailure(
        error.message,
        reason: switch (error.reason) {
          DaemonDataResetFailureReason.daemonRunning =>
            FactoryResetFailureReason.daemonStillRunning,
          DaemonDataResetFailureReason.filesystem =>
            FactoryResetFailureReason.filesystem,
        },
      );
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
