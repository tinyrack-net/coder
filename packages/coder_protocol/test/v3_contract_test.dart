import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('v3 exposes one typed procedure catalog', () {
    expect(coderProtocolMajor, 3);
    expect(coderProtocolRevision, 0);
    expect(rpcProcedures.map((procedure) => procedure.name), isNotEmpty);
    expect(
      rpcProcedures.map((procedure) => procedure.name).toSet(),
      hasLength(rpcProcedures.length),
    );
    expect(systemHelloProcedure.name, 'system.hello');
  });

  test('v3 notification names use plural feature namespaces', () {
    expect(
      rpcNotifications.map((notification) => notification.name),
      containsAll(<String>[
        'sessions.updated',
        'terminals.output',
        'providers.authUpdated',
      ]),
    );
  });
}
