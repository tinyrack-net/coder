import 'dart:io';

import 'package:coder_client/coder_client.dart';
import 'package:coder_client/src/web_socket_connector_io.dart';
import 'package:coder_client/src/web_socket_connector_web.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late Uri endpoint;
  HttpHeaders? seen;

  setUp(() async {
    seen = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    endpoint = Uri.parse('ws://127.0.0.1:${server.port}/ws');
    server.listen((request) async {
      seen = request.headers;
      final socket = await WebSocketTransformer.upgrade(
        request,
        // Mirrors the daemon: only the versioned protocol is offered back.
        protocolSelector: (protocols) =>
            protocols.contains(coderWebSocketProtocol)
            ? coderWebSocketProtocol
            : null,
      );
      await socket.close();
    });
  });

  tearDown(() => server.close(force: true));

  String? header(String name) => seen?.value(name);

  test('the IO connector presents the bearer header', () async {
    final channel = await const IoWebSocketConnector().connect(
      endpoint,
      headers: const <String, String>{'Authorization': 'Bearer secret'},
    );
    await channel.sink.close();

    expect(header('authorization'), 'Bearer secret');
    expect(header('sec-websocket-protocol'), isNull);
  });

  test('the web connector moves the bearer into a subprotocol', () async {
    // A browser cannot set headers, so the credential has to travel here.
    final channel = await const WebWebSocketConnector().connect(
      endpoint,
      headers: const <String, String>{'Authorization': 'Bearer secret'},
    );
    await channel.sink.close();

    expect(header('authorization'), isNull);
    final protocols = header('sec-websocket-protocol')!;
    expect(protocols, contains(coderWebSocketProtocol));
    final token = protocols
        .split(',')
        .map((value) => decodeWebSocketTokenProtocol(value.trim()))
        .whereType<String>()
        .single;
    expect(token, 'secret');
  });

  test('the web connector accepts a lowercased header name', () async {
    final channel = await const WebWebSocketConnector().connect(
      endpoint,
      headers: const <String, String>{'authorization': 'Bearer secret'},
    );
    await channel.sink.close();

    expect(header('sec-websocket-protocol'), contains('tinyrack.coder.token.'));
  });

  test('the web connector omits the token when there is none', () async {
    final channel = await const WebWebSocketConnector().connect(
      endpoint,
      headers: const <String, String>{},
    );
    await channel.sink.close();

    expect(header('sec-websocket-protocol'), coderWebSocketProtocol);
  });

  test(
    'a non-bearer authorization is not smuggled into a subprotocol',
    () async {
      final channel = await const WebWebSocketConnector().connect(
        endpoint,
        headers: const <String, String>{'Authorization': 'Basic dXNlcjpwYXNz'},
      );
      await channel.sink.close();

      expect(header('sec-websocket-protocol'), coderWebSocketProtocol);
    },
  );

  test('the default connector on this platform uses dart:io', () {
    expect(createWebSocketConnector(), isA<IoWebSocketConnector>());
  });
}
