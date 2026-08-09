import 'package:client/local_daemon.dart';
import 'package:daemon/daemon.dart';

/// Starts a daemon and returns the handle that owns its lifetime.
typedef DaemonStarter = Future<DaemonHandle> Function(DaemonConfig config);

/// Applies the `daemon start` options to [defaults].
///
/// [listen] is parsed with the same helper every client uses, so an operator
/// and a client can never disagree about what `host:port` means.
DaemonConfig resolveDaemonConfig({
  required DaemonConfig defaults,
  String? home,
  String? listen,
  String? token,
  List<String> allowedOrigins = const <String>[],
}) {
  final (host, port) = parseLocalDaemonListen(
    listen ?? '${defaults.host}:${defaults.port}',
  );
  return defaults.copyWith(
    homeDirectory: home,
    configDirectory: home,
    host: host,
    port: port,
    bearerToken: token,
    // An empty allowlist means "unset", which keeps the shipped defaults
    // rather than locking every browser out.
    allowedOrigins: allowedOrigins.isEmpty ? null : allowedOrigins.toSet(),
  );
}

/// Runs a daemon until [shutdown] completes, then stops it.
///
/// The generated token is printed only when the operator did not supply one,
/// because echoing a secret they already hold serves no purpose.
Future<int> runDaemonHost({
  required DaemonConfig config,
  required StringSink output,
  required Future<void> shutdown,
  required bool printToken,
  DaemonStarter start = DaemonApplication.start,
}) async {
  final handle = await start(config);
  output.writeln('Tinyrack Coder daemon listening on ${handle.boundEndpoint}');
  if (printToken) {
    output.writeln('Connection token: ${handle.bearerToken}');
  }
  try {
    await shutdown;
  } finally {
    await handle.stop();
  }
  return 0;
}
