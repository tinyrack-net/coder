import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('v5 exposes one genuinely typed procedure catalog', () {
    expect(tinestProtocolMajor, 5);
    expect(tinestProtocolRevision, 4);
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
          protocolMajor: 5,
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

  test('v5 has no fixed Goal RPC or notification surface', () {
    expect(
      rpcProcedures.map((procedure) => procedure.name),
      isNot(contains(matches(RegExp(r'^sessions\..*Goal$')))),
    );
    expect(
      rpcNotifications.map((notification) => notification.name),
      isNot(contains(matches(RegExp(r'^sessions\.goal')))),
    );
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
