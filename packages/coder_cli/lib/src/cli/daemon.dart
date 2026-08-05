import 'dart:async';
import 'dart:io';

import 'package:cliweave/cliweave.dart';
import 'package:coder_cli/src/cli/context.dart';
import 'package:coder_cli/src/daemon_host.dart';
import 'package:coder_daemon/coder_daemon.dart';

/// Completes when the process is asked to shut down.
///
/// SIGTERM is not deliverable on Windows, so only SIGINT is watched there.
Future<void> processShutdownSignal() async {
  final stopping = Completer<void>();
  void request() {
    if (!stopping.isCompleted) stopping.complete();
  }

  final interrupt = ProcessSignal.sigint.watch().listen((_) => request());
  final terminate = Platform.isWindows
      ? null
      : ProcessSignal.sigterm.watch().listen((_) => request());
  try {
    await stopping.future;
  } finally {
    await interrupt.cancel();
    await terminate?.cancel();
  }
}

final Command<CoderCliContext>
_startCommand = buildLazyCommand<CoderCliContext, DaemonStartFlags, NoArgs>(
  docs: const CommandDocs(
    brief: 'Run the daemon in this process',
    fullDescription:
        'Serves plain HTTP and WebSocket. For a remote host keep it on '
        'loopback behind an operator-managed TLS proxy. The TINYRACK_CODER_* '
        'environment variables set the same options.',
  ),
  parameters: CommandParameters(
    flags:
        FlagSet.one(
              ParsedFlag.optional<String, CoderCliContext>(
                name: 'home',
                brief: 'Directory holding daemon state and credentials',
                parse: stringParser,
                placeholder: 'directory',
              ),
            )
            .and(
              ParsedFlag.optional<String, CoderCliContext>(
                name: 'listen',
                brief: 'Address to bind as host:port',
                parse: stringParser,
                placeholder: 'host:port',
              ),
            )
            .and(
              ParsedFlag.optional<String, CoderCliContext>(
                name: 'token',
                brief: 'Bearer token to require, at least 32 bytes',
                parse: stringParser,
                placeholder: 'token',
              ),
            )
            .and(
              ParsedFlag.variadic<String, CoderCliContext>(
                name: 'allowed-origin',
                brief: 'Browser origin permitted to call this daemon',
                parse: stringParser,
                placeholder: 'origin',
              ),
            )
            .map(
              (values) => (
                home: values.$1.$1.$1,
                listen: values.$1.$1.$2,
                token: values.$1.$2,
                allowedOrigins: values.$2,
              ),
            ),
    positional: PositionalSet.none(),
  ),
  // Lazy so that the daemon's database and provider stack is only constructed
  // when the operator actually asks to host one.
  loader: () async => _startDaemon,
);

/// Options accepted by `coder-cli daemon start`.
typedef DaemonStartFlags = ({
  String? home,
  String? listen,
  String? token,
  List<String> allowedOrigins,
});

Future<void> _startDaemon(
  CoderCliContext context,
  DaemonStartFlags flags,
  NoArgs args,
) async {
  final config = resolveDaemonConfig(
    defaults: DaemonConfig.fromEnvironment(),
    home: flags.home,
    listen: flags.listen,
    token: flags.token,
    allowedOrigins: flags.allowedOrigins,
  );
  context.process.exitCode = await runDaemonHost(
    config: config,
    output: context.output,
    shutdown: context.shutdownSignal(),
    printToken: flags.token == null,
    start: context.startDaemon,
  );
}

/// The `coder-cli daemon` route map.
RouteMap<CoderCliContext> buildDaemonRoutes() => buildRouteMap(
  docs: const RouteMapDocs(brief: 'Host a Tinyrack Coder daemon'),
  routes: <String, RoutingTarget<CoderCliContext>>{'start': _startCommand},
);
