import 'dart:io';

import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_relay_protocol/coder_relay_protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'relay status, pairing offer, and activation cross the real daemon',
    () async {
      final state = await Directory.systemTemp.createTemp('coder-relay-state-');
      final config = DaemonConfig(
        homeDirectory: state.path,
        configDirectory: state.path,
        port: 0,
        bearerToken: 'relay-test-token-0123456789abcdef012345',
        useEnvironmentCredentials: false,
      );
      var handle = await DaemonApplication.start(config);
      var client = await _connect(handle);
      try {
        expect(client.serverInfo.features['relay'], isTrue);
        expect((await client.getRelayStatus()).enabled, isFalse);
        final offer = await client.createRelayPairingOffer();
        final parsed = RelayPairingOffer.parseUrl(Uri.parse(offer.url));
        expect(parsed.serverId, handle.serverId);
        expect(parsed.expiresAt, offer.expiresAt);
        expect(await client.listRelayDevices(), isEmpty);
        expect(
          (await client.setRelayEnabled(enabled: true)).enabled,
          isTrue,
        );

        await client.close();
        await handle.stop();
        handle = await DaemonApplication.start(config);
        client = await _connect(handle);
        expect((await client.getRelayStatus()).enabled, isTrue);
      } finally {
        await client.close();
        await handle.stop();
        await state.delete(recursive: true);
      }
    },
    tags: const <String>['feature_test__daemon_relay__verticalSlice'],
  );
}

Future<CoderClient> _connect(DaemonHandle handle) => CoderClient.connect(
  endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
  credentials: const DaemonCredentials(
    bearerToken: 'relay-test-token-0123456789abcdef012345',
  ),
  clientId: 'relay-test',
  clientKind: 'test',
);
