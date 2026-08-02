import 'package:coder_client/coder_client.dart';

/// Opens the transport-neutral daemon API used by application bootstraps.
abstract interface class AppClientConnector {
  /// Connects one client identity to [endpoint].
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
  });
}

/// Production [AppClientConnector] backed by a WebSocket [CoderClient].
final class WebSocketAppClientConnector implements AppClientConnector {
  /// Creates the production client connector.
  const WebSocketAppClientConnector();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required String clientId,
    required String clientKind,
  }) => CoderClient.connect(
    endpoint: endpoint,
    clientId: clientId,
    clientKind: clientKind,
  );
}

/// BootstrapConnection defines a public contract.
class BootstrapConnection {
  /// Creates a [BootstrapConnection].
  const BootstrapConnection({required this.client, required this.endpoint});

  /// The client public API member.
  final CoderApi client;

  /// The endpoint public API member.
  final HostEndpoint endpoint;
}

/// Public API exposed by this library.
abstract interface class AppBootstrap {
  /// The canRegisterLocalWorkspace public API member.
  bool get canRegisterLocalWorkspace;

  /// The autoConnect public API member.
  Future<BootstrapConnection?> autoConnect();

  /// The connectRemote public API member.
  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint);

  /// The close public API member.
  Future<void> close();
}
