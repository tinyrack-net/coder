import 'package:coder_client/coder_client.dart';
import 'package:test/test.dart';

void main() {
  test('endpoint adds ws scheme and protocol path', () {
    final endpoint = HostEndpoint.parse('127.0.0.1:7337');
    expect(endpoint.websocketUri.toString(), 'ws://127.0.0.1:7337/ws');
  });

  test('credentials keep transport location and secrets separate', () {
    const credentials = DaemonCredentials(
      bearerToken: 'bearer',
      adminToken: 'admin',
    );

    expect(credentials.bearerToken, 'bearer');
    expect(credentials.adminToken, 'admin');
    expect(credentials.toString(), isNot(contains('bearer')));
    expect(credentials.toString(), isNot(contains('admin')));
  });
}
