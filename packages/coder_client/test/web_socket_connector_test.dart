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

  test('a failed local-network connection reports its own code', () async {
    // Bind then release a port so nothing is listening on a known-free one.
    final idle = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final closed = Uri.parse('ws://127.0.0.1:${idle.port}/ws');
    await idle.close(force: true);

    await expectLater(
      const WebWebSocketConnector().connect(
        closed,
        headers: const <String, String>{},
      ),
      throwsA(
        isA<CoderClientException>()
            .having((e) => e.code, 'code', localNetworkUnreachableCode)
            .having((e) => e.retryable, 'retryable', isTrue),
      ),
    );
  });

  group('targetsLocalNetwork', () {
    // A browser reaching any of these from a public page needs the user's
    // Local Network Access permission, so a failure there is worth explaining
    // differently from an ordinary unreachable host.
    const local = <String>[
      'ws://localhost:7337/ws',
      'ws://LocalHost:7337/ws',
      'ws://127.0.0.1:7337/ws',
      'ws://127.1.2.3:7337/ws',
      'ws://[::1]:7337/ws',
      'ws://10.0.0.4:7337/ws',
      'ws://172.16.0.1:7337/ws',
      'ws://172.31.255.254:7337/ws',
      'ws://192.168.1.10:7337/ws',
      'ws://169.254.10.20:7337/ws',
      'ws://coder.local:7337/ws',
      'ws://[fe80::1]:7337/ws',
      'ws://[fd12:3456::1]:7337/ws',
    ];
    for (final address in local) {
      test('treats $address as local', () {
        expect(targetsLocalNetwork(Uri.parse(address)), isTrue);
      });
    }

    // 172.15 and 172.32 sit just outside 172.16/12, and a host merely
    // containing "local" is not a `.local` name.
    const public = <String>[
      'wss://coder.tinyrack.net/ws',
      'ws://172.15.0.1:7337/ws',
      'ws://172.32.0.1:7337/ws',
      'ws://11.0.0.1:7337/ws',
      'ws://193.168.1.10:7337/ws',
      'ws://8.8.8.8:7337/ws',
      'wss://mylocal.example.com/ws',
      'wss://local.example.com/ws',
      'ws://[2001:db8::1]:7337/ws',
      // Names that merely start like a unique-local or link-local v6 prefix.
      'wss://fdsomething.com/ws',
      'wss://fc-hosting.example/ws',
      'wss://feb.example.com/ws',
    ];
    for (final address in public) {
      test('treats $address as public', () {
        expect(targetsLocalNetwork(Uri.parse(address)), isFalse);
      });
    }

    test('does not mistake a dotted name for an address', () {
      // `int.tryParse` accepts leading signs and whitespace, which would make
      // a hostname look like an octet quad.
      expect(targetsLocalNetwork(Uri.parse('wss://10.0.0.a/ws')), isFalse);
      expect(targetsLocalNetwork(Uri.parse('wss://+10.0.0.1/ws')), isFalse);
    });
  });
}
