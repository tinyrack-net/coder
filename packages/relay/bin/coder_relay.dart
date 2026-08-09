import 'dart:async';
import 'dart:io';

import 'package:relay/relay.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final service = RelayService();
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(
    service.call,
    InternetAddress.anyIPv6,
    port,
  );
  ProcessSignal.sigterm.watch().listen((_) async {
    await service.drain();
    await server.close(force: true);
  });
}
