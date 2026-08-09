import 'package:app/src/features/hosts/application/host_path_policy.dart';
import 'package:client/client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final direct = DirectHostConnection(
    id: 'direct',
    credentialKey: 'direct-secret',
    endpoint: HostEndpoint.parse('ws://127.0.0.1:7337/v4/ws'),
  );
  final relay = RelayHostConnection(
    id: 'relay',
    credentialKey: 'relay-secret',
    serverId: 'daemon-1',
    relayUri: Uri.parse('wss://relay.tinyrack.net/v1/ws'),
    daemonIdentityPublicKey: List<int>.filled(32, 1),
  );

  test(
    'failed active path switches immediately after server ID validation',
    () {
      final policy = HostPathPolicy(authoritativeServerId: 'daemon-1')
        ..selectInitial(direct);
      final selected = policy.evaluate(<HostPathObservation>[
        HostPathObservation.failure(direct),
        HostPathObservation.success(
          relay,
          latency: const Duration(milliseconds: 80),
          serverId: 'daemon-1',
        ),
      ]);
      expect(selected, same(relay));
    },
    tags: const <String>['feature_test__daemon_relay__unit'],
  );

  test('performance switch needs a 40ms advantage three times', () {
    final policy = HostPathPolicy(authoritativeServerId: 'daemon-1')
      ..selectInitial(relay);
    final observations = <HostPathObservation>[
      HostPathObservation.success(
        relay,
        latency: const Duration(milliseconds: 100),
        serverId: 'daemon-1',
      ),
      HostPathObservation.success(
        direct,
        latency: const Duration(milliseconds: 59),
        serverId: 'daemon-1',
      ),
    ];
    expect(policy.evaluate(observations), same(relay));
    expect(policy.evaluate(observations), same(relay));
    expect(policy.evaluate(observations), same(direct));
  });

  test('never selects a path that resolves to another daemon', () {
    final policy = HostPathPolicy(authoritativeServerId: 'daemon-1')
      ..selectInitial(direct);
    expect(
      policy.evaluate(<HostPathObservation>[
        HostPathObservation.failure(direct),
        HostPathObservation.success(
          relay,
          latency: const Duration(milliseconds: 1),
          serverId: 'daemon-2',
        ),
      ]),
      same(direct),
    );
  });

  test('initial selection and hysteresis reset cover unavailable samples', () {
    final policy = HostPathPolicy(authoritativeServerId: 'daemon-1');
    expect(
      policy.evaluate(<HostPathObservation>[
        HostPathObservation.failure(direct),
      ]),
      isNull,
    );
    expect(
      policy.evaluate(<HostPathObservation>[
        HostPathObservation.success(
          relay,
          latency: const Duration(milliseconds: 20),
          serverId: 'daemon-1',
        ),
      ]),
      same(relay),
    );
    expect(
      policy.evaluate(<HostPathObservation>[
        HostPathObservation.success(
          relay,
          latency: const Duration(milliseconds: 50),
          serverId: 'daemon-1',
        ),
        HostPathObservation.success(
          direct,
          latency: const Duration(milliseconds: 20),
          serverId: 'daemon-1',
        ),
      ]),
      same(relay),
    );
  });
}
