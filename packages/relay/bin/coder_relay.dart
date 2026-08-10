import 'dart:async';
import 'dart:io';

import 'package:relay/relay.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() => runRelayServer(
  shutdownSignals: ProcessSignal.sigterm.watch().map<void>((_) {}),
);

/// Runs the relay until the process receives its first shutdown signal.
///
/// The injectable signal and listening callback keep lifecycle behavior
/// deterministic in tests while concrete process and socket ownership remains
/// in this composition root.
Future<void> runRelayServer({
  required Stream<void> shutdownSignals,
  InternetAddress? address,
  int? port,
  FutureOr<void> Function(HttpServer server)? onListening,
}) async {
  final service = RelayService();
  final server = await shelf_io.serve(
    service.call,
    address ?? InternetAddress.anyIPv6,
    port ?? int.parse(Platform.environment['PORT'] ?? '8080'),
  );
  await onListening?.call(server);
  await shutdownSignals.first;
  await service.drain();
  await server.close(force: true);
}
