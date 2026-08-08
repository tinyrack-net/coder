import 'package:stream_channel/stream_channel.dart';

/// Opens authenticated external channels against the daemon's shared RPC host.
abstract interface class RpcSessionHost {
  /// Opens one JSON-RPC session after transport authentication completes.
  void openSessionChannel(
    StreamChannel<String> channel, {
    String? relayDeviceId,
  });

  /// Terminates live sessions immediately after relay device revocation.
  Future<void> terminateRelayDeviceSessions(String deviceId);
}
