import 'package:coder_client/coder_client.dart';

class BootstrapConnection {
  const BootstrapConnection({required this.client, required this.endpoint});

  final CoderClient client;
  final HostEndpoint endpoint;
}

abstract interface class AppBootstrap {
  bool get canRegisterLocalWorkspace;

  Future<BootstrapConnection?> autoConnect();

  Future<BootstrapConnection> connectRemote(HostEndpoint endpoint);

  Future<void> close();
}
