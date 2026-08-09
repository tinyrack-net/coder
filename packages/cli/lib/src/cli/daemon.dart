import 'dart:async';
import 'dart:io';

import 'package:cli/src/cli/context.dart';
import 'package:cli/src/cli/shared_flags.dart';
import 'package:cli/src/daemon_host.dart';
import 'package:cli/src/relay_cli.dart';
import 'package:cliweave/cliweave.dart';
import 'package:daemon/daemon.dart';

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
            )
            .and(
              BooleanFlag.optional<CoderCliContext>(
                name: 'relay',
                brief: 'Enable or disable the outbound relay connection',
              ),
            )
            .and(
              ParsedFlag.optional<String, CoderCliContext>(
                name: 'relay-endpoint',
                brief: 'Advanced self-hosted relay WebSocket endpoint',
                parse: stringParser,
                placeholder: 'wss://host/path',
              ),
            )
            .map(
              (values) => (
                home: values.$1.$1.home,
                listen: values.$1.$1.listen,
                token: values.$1.$1.token,
                allowedOrigins: values.$1.$1.allowedOrigins,
                relay: values.$1.$2,
                relayEndpoint: values.$2,
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
  bool? relay,
  String? relayEndpoint,
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
    relayEnabled: flags.relay,
    relayEndpoint: flags.relayEndpoint,
  );
  context.process.exitCode = await runDaemonHost(
    config: config,
    output: context.output,
    shutdown: context.shutdownSignal(),
    printToken: flags.token == null,
    start: context.startDaemon,
  );
}

FlagSet<({DaemonConnectionFlags daemon, bool json}), CoderCliContext>
_daemonJsonFlags() => daemonConnectionFlagSet()
    .and(
      BooleanFlag.required<CoderCliContext>(
        name: 'json',
        brief: 'Print machine-readable JSON',
        withNegated: false,
      ),
    )
    .map((values) => (daemon: values.$1, json: values.$2));

final Command<CoderCliContext> _relayStatusCommand = buildCommand(
  docs: const CommandDocs(brief: 'Show outbound relay status'),
  parameters: CommandParameters(
    flags: _daemonJsonFlags(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags.daemon,
    (client) => relayStatus(
      relay: client.relay,
      output: context.output,
      json: flags.json,
    ),
  ),
);

Command<CoderCliContext> _relayToggleCommand(bool enabled) => buildCommand(
  docs: CommandDocs(brief: enabled ? 'Enable the relay' : 'Disable the relay'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => relaySetEnabled(
      relay: client.relay,
      output: context.output,
      enabled: enabled,
    ),
  ),
);

final Command<CoderCliContext> _pairCommand = buildCommand(
  docs: const CommandDocs(brief: 'Create a ten-minute device pairing link'),
  parameters: CommandParameters(
    flags: _daemonJsonFlags()
        .and(
          BooleanFlag.required<CoderCliContext>(
            name: 'relay',
            brief: 'Enable relay when currently disabled',
            withNegated: false,
          ),
        )
        .map(
          (values) => (
            daemon: values.$1.daemon,
            json: values.$1.json,
            relay: values.$2,
          ),
        ),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags.daemon,
    (client) => relayPair(
      relay: client.relay,
      output: context.output,
      enableRelay: flags.relay,
      json: flags.json,
    ),
  ),
);

final Command<CoderCliContext> _devicesListCommand = buildCommand(
  docs: const CommandDocs(brief: 'List approved relay devices'),
  parameters: CommandParameters(
    flags: _daemonJsonFlags(),
    positional: PositionalSet.none(),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags.daemon,
    (client) => relayDevicesList(
      relay: client.relay,
      output: context.output,
      json: flags.json,
    ),
  ),
);

final Command<CoderCliContext> _deviceRevokeCommand = buildCommand(
  docs: const CommandDocs(brief: 'Revoke an approved relay device'),
  parameters: CommandParameters(
    flags: daemonConnectionFlagSet(),
    positional: PositionalSet.one(
      Positional.required<String, CoderCliContext>(
        brief: 'Approved device ID',
        parse: stringParser,
        placeholder: 'device-id',
      ),
    ).map((id) => (id: id)),
  ),
  func: (context, flags, args) => withDaemon(
    context,
    flags,
    (client) => relayDeviceRevoke(
      relay: client.relay,
      output: context.output,
      deviceId: args.id,
    ),
  ),
);

/// The `coder-cli daemon` route map.
RouteMap<CoderCliContext> buildDaemonRoutes() => buildRouteMap(
  docs: const RouteMapDocs(brief: 'Host a Tinyrack Coder daemon'),
  routes: <String, RoutingTarget<CoderCliContext>>{
    'start': _startCommand,
    'pair': _pairCommand,
    'relay': buildRouteMap(
      docs: const RouteMapDocs(brief: 'Manage outbound relay operation'),
      routes: <String, RoutingTarget<CoderCliContext>>{
        'status': _relayStatusCommand,
        'enable': _relayToggleCommand(true),
        'disable': _relayToggleCommand(false),
      },
    ),
    'devices': buildRouteMap(
      docs: const RouteMapDocs(brief: 'Manage approved relay devices'),
      routes: <String, RoutingTarget<CoderCliContext>>{
        'list': _devicesListCommand,
        'revoke': _deviceRevokeCommand,
      },
    ),
  },
);
