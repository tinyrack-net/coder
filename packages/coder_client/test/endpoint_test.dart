import 'package:coder_client/coder_client.dart';
import 'package:test/test.dart';

void main() {
  test('endpoint adds ws scheme and protocol path', () {
    final endpoint = HostEndpoint.parse('127.0.0.1:7337');
    expect(endpoint.websocketUri.toString(), 'ws://127.0.0.1:7337/v4/ws');
  });

  test(
    'credentials keep transport location and the single secret separate',
    () {
      const credentials = DaemonCredentials(bearerToken: 'bearer');

      expect(credentials.bearerToken, 'bearer');
      expect(credentials.toString(), isNot(contains('bearer')));
    },
    tags: const <String>['feature_test__daemon_authentication__unit'],
  );
}
