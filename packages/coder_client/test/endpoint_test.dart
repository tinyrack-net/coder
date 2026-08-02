import 'package:coder_client/coder_client.dart';
import 'package:test/test.dart';

void main() {
  test('endpoint adds ws scheme and protocol path', () {
    final endpoint = HostEndpoint.parse('127.0.0.1:7337', token: 'secret');
    expect(endpoint.websocketUri.toString(), 'ws://127.0.0.1:7337/ws');
  });
}
