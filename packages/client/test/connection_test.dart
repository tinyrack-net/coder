import 'package:client/client.dart';
import 'package:test/test.dart';

void main() {
  test('direct and relay paths reference separate credential keys', () {
    final direct = DirectHostConnection(
      id: 'direct',
      credentialKey: 'host/direct',
      endpoint: HostEndpoint.parse('ws://127.0.0.1:7337/v4/ws'),
    );
    final relay = RelayHostConnection(
      id: 'relay',
      credentialKey: 'host/relay',
      serverId: 'daemon-1',
      relayUri: Uri.parse('wss://relay.coder.tinyrack.net/v1/ws'),
      daemonIdentityPublicKey: List<int>.filled(32, 1),
    );

    expect(direct.credentialKey, isNot(relay.credentialKey));
    expect(relay.serverId, 'daemon-1');
  });

  test('relay routes reject non-WebSocket endpoints and malformed keys', () {
    expect(
      () => RelayHostConnection(
        id: 'relay',
        credentialKey: 'host/relay',
        serverId: 'daemon-1',
        relayUri: Uri.parse('https://relay.tinyrack.net/v1/ws'),
        daemonIdentityPublicKey: const <int>[1],
      ),
      throwsFormatException,
    );
  });
}
