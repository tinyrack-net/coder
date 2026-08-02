import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('wire envelope round-trips and ignores additive fields', () {
    final envelope = WireEnvelope.fromJson(<String, dynamic>{
      'version': 1,
      'type': 'future.event',
      'requestId': 'request-1',
      'payload': <String, dynamic>{'value': 42, 'futureField': true},
      'unknownEnvelopeField': 'ignored',
    });

    expect(envelope.type, 'future.event');
    expect(envelope.payload['futureField'], isTrue);
    expect(WireEnvelope.decode(envelope.encode()).requestId, 'request-1');
  });

  test('invalid payload is rejected', () {
    expect(
      () => WireEnvelope.fromJson(<String, dynamic>{
        'version': 1,
        'type': 'broken',
        'payload': 'not-an-object',
      }),
      throwsA(isA<ProtocolException>()),
    );
  });
}
