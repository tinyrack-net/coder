import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:relay_protocol/relay_protocol.dart';
import 'package:test/test.dart';

import '../bin/tinest_relay.dart' as relay_server;

void main() {
  test(
    'shutdown drains peers and lets the server process return cleanly',
    () async {
      final shutdown = StreamController<void>();
      final listening = Completer<HttpServer>();
      addTearDown(shutdown.close);

      final running = relay_server.runRelayServer(
        shutdownSignals: shutdown.stream,
        address: InternetAddress.loopbackIPv4,
        port: 0,
        onListening: listening.complete,
      );
      final server = await listening.future;
      final base = Uri.parse('ws://127.0.0.1:${server.port}/v1/ws');
      final daemon = await WebSocket.connect(
        base
            .replace(
              queryParameters: <String, String>{
                'role': 'daemon',
                'serverId': 'lifecycle',
              },
            )
            .toString(),
      );
      final client = await WebSocket.connect(
        base
            .replace(
              queryParameters: <String, String>{
                'role': 'client',
                'serverId': 'lifecycle',
              },
            )
            .toString(),
      );
      final daemonMessages = StreamIterator<dynamic>(daemon);
      final clientMessages = StreamIterator<dynamic>(client);

      client.add(Uint8List.fromList(<int>[1, 2, 3]));
      expect(await daemonMessages.moveNext(), isTrue);
      final envelope = RelayEnvelope.decode(
        Uint8List.fromList(daemonMessages.current as List<int>),
      );
      daemon.add(
        RelayEnvelope(
          connectionId: envelope.connectionId,
          payload: Uint8List.fromList(<int>[4, 5, 6]),
        ).encode(),
      );
      expect(await clientMessages.moveNext(), isTrue);
      expect(clientMessages.current, <int>[4, 5, 6]);

      shutdown.add(null);
      await running.timeout(const Duration(seconds: 2));
      expect(await daemonMessages.moveNext(), isFalse);
      expect(await clientMessages.moveNext(), isFalse);
      expect(daemon.closeCode, 4002);
      expect(client.closeCode, 4002);
    },
  );
}
