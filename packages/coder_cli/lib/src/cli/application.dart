import 'dart:io' as io;

import 'package:cliweave/cliweave.dart';
import 'package:cliweave/terminal.dart';
import 'package:coder_cli/src/cli/agent.dart';
import 'package:coder_cli/src/cli/autocomplete.dart';
import 'package:coder_cli/src/cli/context.dart';
import 'package:coder_cli/src/cli/daemon.dart';
import 'package:coder_cli/src/cli/provider.dart';
import 'package:coder_cli/src/cli/shared_flags.dart';
import 'package:coder_cli/src/daemon_host.dart';
import 'package:coder_cli/src/version.g.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_client/local_daemon.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Exit code for a usage error, matching `sysexits.h` `EX_USAGE`.
const int usageExitCode = 64;

/// Exit code for an unreachable daemon, matching `sysexits.h` `EX_UNAVAILABLE`.
const int unavailableExitCode = 69;

/// Exit code for an internal failure, matching `sysexits.h` `EX_SOFTWARE`.
const int internalExitCode = 70;

/// Translates cliweave's structured codes into the CLI's `sysexits.h` values.
///
/// The router reports a scanner or routing failure as a negative [ExitCode],
/// which a shell would see as 251-255. Every bad command line is a usage
/// error, so they collapse onto the same code the thrown [FormatException]
/// path already uses.
int normalizeExitCode(int? code) => switch (code) {
  null || ExitCode.success => 0,
  ExitCode.unknownCommand || ExitCode.invalidArgument => usageExitCode,
  ExitCode.integrationError ||
  ExitCode.contextLoadError ||
  ExitCode.commandLoadError ||
  ExitCode.internalError => internalExitCode,
  final int other => other,
};

/// Maps a thrown value to the CLI's documented exit code.
///
/// [WebSocketChannelException] is matched before [io.SocketException] because
/// the transport wraps the latter; reversing them would let "the daemon is not
/// running" escape as an unhandled error.
int resolveExitCode(Object? error) => switch (error) {
  FormatException() => usageExitCode,
  WebSocketChannelException() => unavailableExitCode,
  io.SocketException() => unavailableExitCode,
  CoderClientException() => unavailableExitCode,
  DaemonConnectionException() => unavailableExitCode,
  _ => 1,
};

String _describe(Object? error) => switch (error) {
  FormatException(:final message) => message,
  WebSocketChannelException(:final message) =>
    'Cannot connect to the daemon: $message',
  io.SocketException(:final message) =>
    'Cannot connect to the daemon: $message',
  CoderClientException(:final message) => message,
  DaemonConnectionException(:final message) => message,
  _ => '$error',
};

/// Routes framework errors through the logger instead of raw stderr writes.
ApplicationText _coderText(CliLogger errorLogger) {
  String report(Object? error, Object? _) {
    errorLogger.error(_describe(error));
    return '';
  }

  return textEn.copyWith(
    commandErrorResult: report,
    exceptionWhileLoadingCommandContext: report,
    exceptionWhileLoadingCommandFunction: report,
    exceptionWhileRunningCommand: report,
  );
}

/// Builds the `coder-cli` routing tree.
RouteMap<CoderCliContext> buildRootRoutes() => buildRouteMap(
  docs: const RouteMapDocs(
    brief: 'Tinyrack Coder command line',
    fullDescription:
        'Hosts a daemon and administers the providers and Markdown agents of '
        'a running one.',
    hideRoute: <String, bool>{'__complete': true},
  ),
  routes: <String, RoutingTarget<CoderCliContext>>{
    'daemon': buildDaemonRoutes(),
    'provider': buildProviderRoutes(),
    'agent': buildAgentRoutes(),
    'completion': buildCompletionRoutes(),
    '__complete': completeCommand,
  },
);

/// Builds the application for [text].
Application<CoderCliContext> buildCoderCliApplication(ApplicationText text) {
  return buildApplication(
    buildRootRoutes(),
    ApplicationConfiguration(
      name: 'coder-cli',
      determineExitCode: resolveExitCode,
      documentation: const DocumentationConfiguration(
        caseStyle: DisplayCaseStyle.convertCamelToKebab,
      ),
      localization: LocalizationConfiguration(
        defaultLocale: 'en',
        loadText: (_) => text,
      ),
      scanner: const ScannerConfiguration(
        caseStyle: ScannerCaseStyle.allowKebabForCamel,
      ),
      versionInfo: const VersionInformation(currentVersion: packageVersion),
    ),
  );
}

/// Runs `coder-cli` with [inputs] and returns the process exit code.
///
/// Every side effect is an injectable parameter so that a test drives the real
/// router without a socket, a terminal, or the user's home directory.
Future<int> runCli(
  List<String> inputs, {
  WriteStream? stdout,
  WriteStream? stderr,
  DaemonClientFactory? connectClient,
  Future<String> Function()? readSecret,
  Future<String> Function(String path)? readFile,
  Map<String, String>? environment,
  LocalDaemonDirectories? directories,
  DaemonStarter? startDaemon,
  Future<void> Function()? shutdownSignal,
}) async {
  final stdoutStream = stdout ?? StdioWriteStream(io.stdout);
  final stderrStream = stderr ?? StdioWriteStream(io.stderr);
  final logger = createCliLogger(stdout: stdoutStream, stderr: stderrStream);
  final errorLogger = createCliLogger(
    stdout: stderrStream,
    stderr: stderrStream,
  );
  final resolvedEnvironment = environment ?? io.Platform.environment;
  final context = CoderCliContext(
    process: RunProcess(stdout: stdoutStream, stderr: stderrStream),
    logger: logger,
    connectClient: connectClient ?? _connectCoderClient,
    readSecret: readSecret ?? _promptForSecret,
    readFile: readFile ?? _readFile,
    environment: resolvedEnvironment,
    startDaemon: startDaemon ?? DaemonApplication.start,
    shutdownSignal: shutdownSignal ?? processShutdownSignal,
    directories:
        directories ??
        resolveLocalDaemonDirectories(
          environment: _MapLocalDaemonEnvironment(resolvedEnvironment),
        ),
  );
  final application = buildCoderCliApplication(_coderText(errorLogger));
  context.application = application;
  await run(application, inputs, RunContext.direct(context));
  return normalizeExitCode(context.process.exitCode);
}

Future<CoderClient> _connectCoderClient({
  required String host,
  required int port,
  required String bearerToken,
  required String clientId,
}) {
  return CoderClient.connect(
    endpoint: HostEndpoint(
      websocketUri: Uri(scheme: 'ws', host: host, port: port, path: '/ws'),
    ),
    credentials: DaemonCredentials(bearerToken: bearerToken),
    clientId: clientId,
    clientKind: 'standalone-cli',
  );
}

Future<String> _readFile(String path) => io.File(path).readAsString();

Future<String> _promptForSecret() async {
  io.stdout.write('API key: ');
  final wasEchoing = io.stdin.echoMode;
  try {
    io.stdin.echoMode = false;
    final value = io.stdin.readLineSync();
    io.stdout.writeln();
    if (value == null || value.trim().isEmpty) {
      throw const FormatException('API key must not be empty.');
    }
    return value.trim();
  } finally {
    io.stdin.echoMode = wasEchoing;
  }
}

/// Reads platform facts from an injected environment map.
final class _MapLocalDaemonEnvironment implements LocalDaemonEnvironment {
  const _MapLocalDaemonEnvironment(this.values);

  @override
  final Map<String, String> values;

  @override
  bool get isLinux => io.Platform.isLinux;

  @override
  bool get isMacOS => io.Platform.isMacOS;

  @override
  bool get isWindows => io.Platform.isWindows;
}
