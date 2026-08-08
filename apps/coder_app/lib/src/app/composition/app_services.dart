import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_client/coder_client.dart';

/// Opens and handshakes one daemon client.
typedef CoderClientOpener =
    Future<CoderApi> Function({
      required HostEndpoint endpoint,
      required DaemonCredentials credentials,
      required String clientId,
      required String clientKind,
    });

/// Injectable relay client opener used by the production composition root.
typedef RelayCoderClientOpener =
    Future<CoderApi> Function({
      required RelayHostConnection connection,
      required RelayHostCredential credential,
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
    this.embeddedDataEraser,
    this.delay = const SystemAppDelay(),
    this.pathProbeScheduler = const SystemHostPathProbeScheduler(),
    this.relayPairer = const CoderHostRelayPairer(),
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

  /// Desktop-only eraser for the app-owned daemon's stored data.
  final EmbeddedDaemonDataEraser? embeddedDataEraser;

  /// Delay adapter used by independent initial reconnect loops.
  final AppDelay delay;

  /// Periodic direct/relay path probe scheduler.
  final HostPathProbeScheduler pathProbeScheduler;

  /// One-time relay device registration adapter.
  final HostRelayPairer relayPairer;

  /// Whether this platform can own an embedded daemon.
  bool get supportsEmbeddedDaemon => embeddedLauncher != null;

  /// Whether a reset also erases stored daemon data on this platform.
  bool get erasesEmbeddedDaemonData => embeddedDataEraser != null;
}

/// Production pairing adapter backed by the E2E relay client package.
final class CoderHostRelayPairer implements HostRelayPairer {
  /// Creates the stateless pairing adapter.
  const CoderHostRelayPairer();

  @override
  Future<RelayPairingResult> pair({
    required Uri pairingUrl,
    required String deviceId,
    required String deviceName,
    required String connectionId,
    required String credentialKey,
  }) => RelayDevicePairer().pair(
    pairingUrl: pairingUrl,
    deviceId: deviceId,
    deviceName: deviceName,
    connectionId: connectionId,
    credentialKey: credentialKey,
  );
}

/// Production WebSocket implementation of [HostClientFactory].
final class WebSocketHostClientFactory implements HostClientFactory {
  /// Creates the production host client factory.
  const WebSocketHostClientFactory({
    this.openClient = _openCoderClient,
    this.openRelayClient = _openRelayCoderClient,
  });

  /// Injected typed client opener.
  final CoderClientOpener openClient;

  /// Injected encrypted relay client opener.
  final RelayCoderClientOpener openRelayClient;

  @override
  Future<CoderApi> connect({
    required HostConnection connection,
    required HostConnectionCredential credential,
    required String clientId,
    required String clientKind,
  }) async {
    try {
      return switch ((connection, credential)) {
        (
          DirectHostConnection(:final endpoint),
          DirectHostCredential(:final credentials),
        ) =>
          await openClient(
            endpoint: endpoint,
            credentials: credentials,
            clientId: clientId,
            clientKind: clientKind,
          ),
        (
          final RelayHostConnection relayConnection,
          final RelayHostCredential relayCredential,
        ) =>
          await openRelayClient(
            connection: relayConnection,
            credential: relayCredential,
            clientId: clientId,
            clientKind: clientKind,
          ),
        _ => throw const HostConnectionFailure.authentication(
          'The stored credential does not match this connection path.',
        ),
      };
    } on CoderClientException catch (error) {
      if (error.code == 'protocol_mismatch') {
        throw HostConnectionFailure.protocolMismatch(error.message);
      }
      rethrow;
    } on Exception catch (error) {
      final message = '$error';
      if (message.contains('401') || message.contains('403')) {
        throw const HostConnectionFailure.authentication(
          'The daemon rejected the bearer token.',
          reason: HostFailureReason.rejectedBearerToken,
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

Future<CoderApi> _openRelayCoderClient({
  required RelayHostConnection connection,
  required RelayHostCredential credential,
  required String clientId,
  required String clientKind,
}) async {
  final client = await CoderClient.connect(
    endpoint: HostEndpoint(websocketUri: connection.relayUri),
    credentials: const DaemonCredentials(
      bearerToken: 'relay-device-authentication-is-e2e',
    ),
    clientId: clientId,
    clientKind: clientKind,
    connector: RelayWebSocketConnector(
      connection: connection,
      credential: credential,
    ),
  );
  if (client.serverInfo.serverId != connection.serverId) {
    await client.close();
    throw const HostConnectionFailure.authentication(
      'Relay path resolved to a different daemon identity.',
    );
  }
  return client;
}
