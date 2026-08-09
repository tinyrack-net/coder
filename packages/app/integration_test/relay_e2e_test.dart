import 'dart:convert';

import 'package:app/src/features/hosts/application/host_path_policy.dart';
import 'package:client/client.dart';
import 'package:daemon/src/features/relay/application/relay_pairing_service.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:relay_protocol/relay_protocol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a ten-minute offer is consumed idempotently by one device',
    (tester) async {
      final service = _pairingService();
      final offer = service.createOffer();
      final key = List<int>.filled(32, 7);
      final first = await service.registerDevice(
        offerId: offer.offerId,
        offerSecret: offer.secret,
        deviceId: 'phone',
        deviceName: 'Phone',
        devicePublicKey: key,
      );
      final retry = await service.registerDevice(
        offerId: offer.offerId,
        offerSecret: offer.secret,
        deviceId: 'phone',
        deviceName: 'Phone retry',
        devicePublicKey: key,
      );
      await tester.pump();
      expect(retry.id, first.id);
    },
    tags: const <String>[
      'feature_scenario__daemon_relay__pairing__e2e',
    ],
  );

  testWidgets(
    'a failed direct path immediately selects the authenticated relay',
    (tester) async {
      final direct = DirectHostConnection(
        id: 'direct',
        credentialKey: 'direct-key',
        endpoint: HostEndpoint.parse('ws://direct.invalid/v4/ws'),
      );
      final relay = RelayHostConnection(
        id: 'relay',
        credentialKey: 'relay-key',
        serverId: 'daemon-1',
        relayUri: Uri.parse('wss://relay.tinyrack.net/v1/ws'),
        daemonIdentityPublicKey: List<int>.filled(32, 1),
      );
      final selected =
          (HostPathPolicy(
            authoritativeServerId: 'daemon-1',
          )..selectInitial(direct)).evaluate(<HostPathObservation>[
            HostPathObservation.failure(direct),
            HostPathObservation.success(
              relay,
              latency: const Duration(milliseconds: 80),
              serverId: 'daemon-1',
            ),
          ]);
      await tester.pump();
      expect(selected, same(relay));
    },
    tags: const <String>[
      'feature_scenario__daemon_relay__failover__e2e',
    ],
  );

  testWidgets(
    'revoking a device deletes authorization and terminates its session',
    (tester) async {
      final terminated = <String>[];
      final service = _pairingService(
        terminate: (deviceId) async => terminated.add(deviceId),
      );
      final offer = service.createOffer();
      await service.registerDevice(
        offerId: offer.offerId,
        offerSecret: offer.secret,
        deviceId: 'tablet',
        deviceName: 'Tablet',
        devicePublicKey: List<int>.filled(32, 9),
      );
      await service.revokeDevice('tablet');
      await tester.pump();
      expect(await service.listDevices(), isEmpty);
      expect(terminated, <String>['tablet']);
    },
    tags: const <String>[
      'feature_scenario__daemon_relay__revocation__e2e',
    ],
  );

  testWidgets(
    'attachment metadata and content cross only as bounded ciphertext records',
    (tester) async {
      final sender = await RelayCipherState.create(
        sharedSecret: List<int>.generate(32, (index) => index),
        transcript: utf8.encode('attachment-e2e'),
        direction: RelayDirection.clientToDaemon,
      );
      final receiver = await RelayCipherState.create(
        sharedSecret: List<int>.generate(32, (index) => index),
        transcript: utf8.encode('attachment-e2e'),
        direction: RelayDirection.clientToDaemon,
      );
      final open = RelayRecord(
        type: RelayRecordType.attachmentOpen,
        streamId: 1,
        payload: RelayAttachmentOpen.upload(
          fileName: 'private-name.txt',
          mimeType: 'text/plain',
          byteSize: 50 * 1024 * 1024,
        ).encode(),
      );
      final encrypted = await sender.encrypt(open.encode());
      final wireText = latin1.decode(encrypted, allowInvalid: true);
      expect(wireText, isNot(contains('private-name.txt')));
      final decoded = RelayRecord.decode(await receiver.decrypt(encrypted));
      expect(
        decoded.encode().length,
        lessThanOrEqualTo(maxRelayPlaintextRecordBytes),
      );
      expect(
        decodeRelayAttachmentCredit(
          encodeRelayAttachmentCredit(relayAttachmentCreditWindowBytes),
        ),
        relayAttachmentCreditWindowBytes,
      );
      await tester.pump();
    },
    tags: const <String>[
      'feature_test__daemon_relay__e2e',
      'feature_scenario__daemon_relay__relay_attachment__e2e',
    ],
  );
}

RelayPairingService _pairingService({
  Future<void> Function(String deviceId)? terminate,
}) => RelayPairingService(
  serverId: 'daemon-1',
  relayUri: Uri.parse('wss://relay.tinyrack.net/v1/ws'),
  daemonIdentityPublicKey: List<int>.filled(32, 3),
  devices: MemoryRelayDeviceRepository(),
  clock: const _Clock(),
  ids: _Ids(),
  randomBytes: (length) => List<int>.generate(length, (index) => index),
  terminateDeviceSessions: terminate,
);

final class _Clock implements Clock {
  const _Clock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 8, 12);
}

final class _Ids implements IdGenerator {
  int _next = 0;

  @override
  String generate() => 'offer-${++_next}';
}
