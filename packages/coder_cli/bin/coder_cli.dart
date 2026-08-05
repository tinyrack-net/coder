import 'dart:io';

import 'package:args/args.dart';
import 'package:coder_cli/coder_cli.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_client/local_daemon.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'home',
      help: 'Configuration directory holding credentials.json.',
    )
    ..addOption('listen', help: 'Daemon address as host:port.')
    ..addOption('token', help: 'Daemon bearer token.')
    ..addFlag('help', abbr: 'h', negatable: false)
    ..addFlag('version', negatable: false);
  // Global options are parsed only from the leading arguments so that a
  // subcommand keeps its own flags, such as `provider connect --method`.
  final split = _splitGlobalOptions(arguments);
  final ArgResults options;
  try {
    options = parser.parse(split.$1);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage(parser));
    exitCode = 64;
    return;
  }
  if (options.flag('version')) {
    stdout.writeln(packageVersion);
    return;
  }
  final command = split.$2;
  if (options.flag('help') || command.isEmpty) {
    stdout.writeln(_usage(parser));
    return;
  }
  try {
    exitCode = await _run(command, options);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on WebSocketChannelException catch (error) {
    // The transport wraps the SocketException, so catching only the latter
    // would let "daemon is not running" escape as an unhandled exception.
    stderr.writeln('Cannot connect to the daemon: ${error.message}');
    exitCode = 69;
  } on SocketException catch (error) {
    stderr.writeln('Cannot connect to the daemon: ${error.message}');
    exitCode = 69;
  } on CoderClientException catch (error) {
    stderr.writeln(error.message);
    exitCode = 69;
  }
}

Future<int> _run(List<String> command, ArgResults options) async {
  // Usage is answered before connecting, because asking how a command works
  // must not require a running daemon.
  final rest = command.skip(1).toList(growable: false);
  if (rest.isEmpty || rest.first == 'help') {
    stdout.writeln(switch (command.first) {
      'provider' => providerUsage,
      'agent' => agentUsage,
      _ => throw FormatException('Unknown command: ${command.first}'),
    });
    return 0;
  }
  final client = await _connect(options, clientId: 'coder-cli');
  if (client == null) return 69;
  try {
    return switch (command.first) {
      'provider' => await runProviderCommand(
        rest,
        backend: CoderApiProviderCliBackend(client),
        output: stdout,
        readSecret: _readSecret,
      ),
      'agent' => await runAgentCommand(
        rest,
        backend: CoderApiAgentCliBackend(client),
        output: stdout,
        readFile: (path) => File(path).readAsString(),
      ),
      _ => throw FormatException('Unknown command: ${command.first}'),
    };
  } finally {
    await client.close();
  }
}

/// Connects to the local daemon, or returns null after reporting why it could
/// not: a missing token is an operator mistake, not an unexpected failure.
Future<CoderClient?> _connect(
  ArgResults options, {
  required String clientId,
}) async {
  final environment = Platform.environment;
  final directories = resolveLocalDaemonDirectories();
  final configDirectory = options.option('home') ?? directories.configDirectory;
  final (host, port) = parseLocalDaemonListen(
    options.option('listen') ??
        environment['TINYRACK_CODER_LISTEN'] ??
        defaultLocalDaemonListen,
  );
  final token =
      options.option('token') ??
      environment['TINYRACK_CODER_TOKEN'] ??
      await readLocalDaemonBearerToken(configDirectory);
  if (token == null) {
    stderr.writeln(
      'No daemon connection token found in $configDirectory. Start the daemon '
      'first, or pass --token.',
    );
    return null;
  }
  return CoderClient.connect(
    endpoint: HostEndpoint(
      websocketUri: Uri(
        // A daemon bound to every interface is still reached over loopback.
        scheme: 'ws',
        host: host == '0.0.0.0' ? '127.0.0.1' : host,
        port: port,
        path: '/ws',
      ),
    ),
    credentials: DaemonCredentials(bearerToken: token),
    clientId: clientId,
    clientKind: 'standalone-cli',
  );
}

/// Splits leading global options from the subcommand and its own arguments.
(List<String>, List<String>) _splitGlobalOptions(List<String> arguments) {
  const commands = <String>{'provider', 'agent'};
  final index = arguments.indexWhere(commands.contains);
  if (index < 0) return (arguments, const <String>[]);
  return (
    arguments.sublist(0, index),
    arguments.sublist(index),
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

String _usage(ArgParser parser) => '''
Tinyrack Coder command-line client.

Usage: coder-cli [options] <command> [arguments]

Commands:
  provider   Manage provider connections.
  agent      Manage Markdown agent definitions.

Run `coder-cli provider help` or `coder-cli agent help` for their commands.

Options:
${parser.usage}''';
