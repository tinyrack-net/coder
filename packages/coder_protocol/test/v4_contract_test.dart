import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('v4 exposes one genuinely typed procedure catalog', () {
    expect(coderProtocolMajor, 4);
    expect(coderProtocolRevision, 0);
    expect(rpcProcedures.map((procedure) => procedure.name), isNotEmpty);
    expect(
      rpcProcedures.map((procedure) => procedure.name).toSet(),
      hasLength(rpcProcedures.length),
    );
    expect(systemHelloProcedure.name, 'system.hello');
    expect(systemHelloProcedure.paramsType, HelloParamsDto);
    expect(systemHelloProcedure.resultType, ServerInfoDto);
    expect(
      systemHelloProcedure.decodeParams(
        const HelloParamsDto(
          clientId: 'client',
          clientKind: 'test',
          protocolMajor: 4,
          clientVersion: '1.0.0',
          capabilities: <String, bool>{},
        ).toJson(),
      ),
      isA<HelloParamsDto>(),
    );
    expect(
      rpcProcedures.where(
        (procedure) =>
            procedure.paramsType.toString().startsWith('Map<') ||
            procedure.resultType.toString().startsWith('Map<'),
      ),
      isEmpty,
    );
  });

  test('v4 notification names use plural feature namespaces', () {
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
