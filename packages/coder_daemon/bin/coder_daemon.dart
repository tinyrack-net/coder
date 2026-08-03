import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_daemon/src/agent_cli.dart';
import 'package:coder_daemon/src/credential_store.dart';
import 'package:coder_daemon/src/provider_cli.dart';

Future<void> main(List<String> arguments) async {
  final defaults = DaemonConfig.fromEnvironment();
  if (arguments.firstOrNull == 'provider') {
    await _runProvider(arguments.skip(1).toList(growable: false), defaults);
    return;
  }
  if (arguments.firstOrNull == 'agent') {
    await _runAgent(arguments.skip(1).toList(growable: false), defaults);
    return;
  }
  final parser = ArgParser()
    ..addOption('home', defaultsTo: defaults.homeDirectory)
    ..addOption('listen', defaultsTo: '${defaults.host}:${defaults.port}')
    ..addOption('token', defaultsTo: defaults.bearerToken)
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(arguments);
  if (options.flag('help')) {
    stdout.writeln('Tinyrack Coder daemon\n${parser.usage}');
    return;
  }
  final listen = options.option('listen')!;
  final separator = listen.lastIndexOf(':');
  if (separator < 1) throw const FormatException('--listen must be host:port.');
  final handle = await DaemonApplication.start(
    defaults.copyWith(
      homeDirectory: options.option('home'),
      configDirectory: options.option('home'),
      host: listen.substring(0, separator),
      port: int.parse(listen.substring(separator + 1)),
      bearerToken: options.option('token'),
    ),
  );
  stdout.writeln('Tinyrack Coder daemon listening on ${handle.boundEndpoint}');
  if (options.option('token') == null) {
    stdout.writeln('Connection token: ${handle.bearerToken}');
  }
  final stopping = Completer<void>();
  late final StreamSubscription<ProcessSignal> interrupt;
  StreamSubscription<ProcessSignal>? terminate;
  interrupt = ProcessSignal.sigint.watch().listen((_) => stopping.complete());
  if (!Platform.isWindows) {
    terminate = ProcessSignal.sigterm.watch().listen((_) {
      if (!stopping.isCompleted) stopping.complete();
    });
  }
  await stopping.future;
  await interrupt.cancel();
  await terminate?.cancel();
  await handle.stop();
}

Future<void> _runProvider(
  List<String> arguments,
  DaemonConfig config,
) async {
  final credentials = CredentialStore(config.configDirectory);
  await credentials.load();
  final token = config.bearerToken ?? credentials.bearerToken;
  final adminToken = config.adminToken ?? credentials.adminToken;
  if (token == null || adminToken == null) {
    throw StateError(
      'No daemon connection token found. Start coder_daemon first.',
    );
  }
  final client = await CoderClient.connect(
    endpoint: HostEndpoint(
      websocketUri: Uri(
        scheme: 'ws',
        host: config.host == '0.0.0.0' ? '127.0.0.1' : config.host,
        port: config.port,
        path: '/ws',
      ),
    ),
    credentials: DaemonCredentials(
      bearerToken: token,
      adminToken: adminToken,
    ),
    clientId: 'coder-daemon-cli',
    clientKind: 'standalone-cli',
  );
  try {
    final result = await runProviderCommand(
      arguments,
      backend: CoderApiProviderCliBackend(client),
      output: stdout,
      readSecret: _readSecret,
    );
    if (result != 0) exitCode = result;
  } finally {
    await client.close();
  }
}

Future<void> _runAgent(List<String> arguments, DaemonConfig config) async {
  final client = await _connectAdminClient(config);
  try {
    final result = await runAgentCommand(
      arguments,
      backend: CoderApiAgentCliBackend(client),
      output: stdout,
      readFile: (path) => File(path).readAsString(),
    );
    if (result != 0) exitCode = result;
  } finally {
    await client.close();
  }
}

Future<CoderClient> _connectAdminClient(DaemonConfig config) async {
  final credentials = CredentialStore(config.configDirectory);
  await credentials.load();
  final token = config.bearerToken ?? credentials.bearerToken;
  final adminToken = config.adminToken ?? credentials.adminToken;
  if (token == null || adminToken == null) {
    throw StateError(
      'No daemon connection token found. Start coder_daemon first.',
    );
  }
  return CoderClient.connect(
    endpoint: HostEndpoint(
      websocketUri: Uri(
        scheme: 'ws',
        host: config.host == '0.0.0.0' ? '127.0.0.1' : config.host,
        port: config.port,
        path: '/ws',
      ),
    ),
    credentials: DaemonCredentials(
      bearerToken: token,
      adminToken: adminToken,
    ),
    clientId: 'coder-daemon-agent-cli',
    clientKind: 'standalone-cli',
  );
}

Future<String> _readSecret() async {
  stdout.write('API key: ');
  final wasEchoing = stdin.echoMode;
  try {
    stdin.echoMode = false;
    final value = stdin.readLineSync();
    stdout.writeln();
    if (value == null || value.trim().isEmpty) {
      throw const FormatException('API key must not be empty.');
    }
    return value.trim();
  } finally {
    stdin.echoMode = wasEchoing;
  }
}
