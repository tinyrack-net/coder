import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';

/// Opens and handshakes one daemon client.
typedef CoderClientOpener =
    Future<CoderApi> Function({
      required HostEndpoint endpoint,
      required DaemonCredentials credentials,
      required String clientId,
      required String clientKind,
    });

/// Composition-root dependencies required by the daemon-independent app shell.
final class AppServices {
  /// Creates application services.
  const AppServices({
    required this.settings,
    required this.profiles,
    required this.credentials,
    required this.clients,
    required this.clientKind,
    this.embeddedLauncher,
    this.delay = const SystemAppDelay(),
  });

  /// Device-local app settings repository.
  final AppSettingsRepository settings;

  /// Non-secret remote profile repository.
  final RemoteHostRepository profiles;

  /// Secure remote bearer-token store.
  final RemoteHostCredentialStore credentials;

  /// WebSocket client factory.
  final HostClientFactory clients;

  /// Handshake client kind for diagnostics and feature policy.
  final String clientKind;

  /// Desktop-only app-owned daemon launcher.
  final EmbeddedDaemonLauncher? embeddedLauncher;

  /// Delay adapter used by independent initial reconnect loops.
  final AppDelay delay;

  /// Whether this platform can own an embedded daemon.
  bool get supportsEmbeddedDaemon => embeddedLauncher != null;
}

/// Production WebSocket implementation of [HostClientFactory].
final class WebSocketHostClientFactory implements HostClientFactory {
  /// Creates the production host client factory.
  const WebSocketHostClientFactory({this.openClient = _openCoderClient});

  /// Injected typed client opener.
  final CoderClientOpener openClient;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) async {
    try {
      return await openClient(
        endpoint: endpoint,
        credentials: credentials,
        clientId: clientId,
        clientKind: clientKind,
      );
    } on CoderClientException catch (error) {
      if (error.code == 'protocol_mismatch') {
        throw HostConnectionFailure.protocolMismatch(error.message);
      }
      rethrow;
    } on Exception catch (error) {
      final message = '$error';
      if (message.contains('401') || message.contains('403')) {
        throw const HostConnectionFailure.authentication(
          'Daemon이 bearer token을 거부했습니다.',
        );
      }
      throw HostConnectionFailure.network(message);
    }
  }
}

Future<CoderApi> _openCoderClient({
  required HostEndpoint endpoint,
  required DaemonCredentials credentials,
  required String clientId,
  required String clientKind,
}) => CoderClient.connect(
  endpoint: endpoint,
  credentials: credentials,
  clientId: clientId,
  clientKind: clientKind,
);
