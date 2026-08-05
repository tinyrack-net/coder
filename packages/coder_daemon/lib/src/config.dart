import 'dart:convert';
import 'dart:math';

import 'package:coder_client/local_daemon.dart';
import 'package:coder_daemon/src/version.g.dart';

/// Supplies process environment and operating-system information to config.
///
/// Shared with the standalone CLI so both resolve the same directories.
typedef DaemonEnvironment = LocalDaemonEnvironment;

/// Production [DaemonEnvironment] backed by `dart:io`.
typedef IoDaemonEnvironment = IoLocalDaemonEnvironment;

/// DaemonConfig defines a public contract.
class DaemonConfig {
  /// Creates a [DaemonConfig].
  const DaemonConfig({
    required this.homeDirectory,
    String? configDirectory,
    this.userHomeDirectory,
    this.host = '127.0.0.1',
    this.port = 7337,
    this.apiKey,
    this.bearerToken,
    this.version = packageVersion,
    this.useEnvironmentCredentials = true,
  }) : configDirectory = configDirectory ?? homeDirectory;

  /// Creates a [DaemonConfig].
  factory DaemonConfig.fromIsolateMessage(Map<Object?, Object?> value) =>
      DaemonConfig(
        homeDirectory: value['homeDirectory']! as String,
        configDirectory: value['configDirectory'] as String?,
        userHomeDirectory: value['userHomeDirectory'] as String?,
        host: value['host']! as String,
        port: value['port']! as int,
        apiKey: value['apiKey'] as String?,
        bearerToken: value['bearerToken'] as String?,
        version: value['version']! as String,
        useEnvironmentCredentials: value['useEnvironmentCredentials']! as bool,
      );

  /// Creates a [DaemonConfig].
  factory DaemonConfig.fromEnvironment({
    String? apiKey,
    DaemonEnvironment environment = const IoDaemonEnvironment(),
  }) {
    final values = environment.values;
    final directories = resolveLocalDaemonDirectories(environment: environment);
    final (host, port) = parseLocalDaemonListen(
      values['TINYRACK_CODER_LISTEN'] ?? defaultLocalDaemonListen,
    );
    return DaemonConfig(
      homeDirectory: directories.stateDirectory,
      configDirectory: directories.configDirectory,
      userHomeDirectory: directories.userHomeDirectory,
      host: host,
      port: port,
      apiKey: apiKey,
      bearerToken: values['TINYRACK_CODER_TOKEN'],
    );
  }

  /// The homeDirectory public API member.
  final String homeDirectory;

  /// The configDirectory public API member.
  final String configDirectory;

  /// Real user home used to locate the shared `~/.agents` tree.
  ///
  /// Null keeps the daemon away from any user home, which is what tests and
  /// CI runs need.
  final String? userHomeDirectory;

  /// The host public API member.
  final String host;

  /// The port public API member.
  final int port;

  /// The apiKey public API member.
  final String? apiKey;

  /// The bearerToken public API member.
  final String? bearerToken;

  /// The version public API member.
  final String version;

  /// Whether built-in providers may use credentials from daemon environment.
  final bool useEnvironmentCredentials;

  /// The copyWith public API member.
  DaemonConfig copyWith({
    String? homeDirectory,
    String? configDirectory,
    String? userHomeDirectory,
    String? host,
    int? port,
    String? apiKey,
    String? bearerToken,
    bool? useEnvironmentCredentials,
  }) => DaemonConfig(
    homeDirectory: homeDirectory ?? this.homeDirectory,
    configDirectory: configDirectory ?? this.configDirectory,
    userHomeDirectory: userHomeDirectory ?? this.userHomeDirectory,
    host: host ?? this.host,
    port: port ?? this.port,
    apiKey: apiKey ?? this.apiKey,
    bearerToken: bearerToken ?? this.bearerToken,
    version: version,
    useEnvironmentCredentials:
        useEnvironmentCredentials ?? this.useEnvironmentCredentials,
  );

  /// The toIsolateMessage public API member.
  Map<String, Object?> toIsolateMessage() => <String, Object?>{
    'homeDirectory': homeDirectory,
    'configDirectory': configDirectory,
    'userHomeDirectory': userHomeDirectory,
    'host': host,
    'port': port,
    'apiKey': apiKey,
    'bearerToken': bearerToken,
    'version': version,
    'useEnvironmentCredentials': useEnvironmentCredentials,
  };
}

/// The generateBearerToken public API member.
String generateBearerToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(
    32,
    (_) => random.nextInt(256),
    growable: false,
  );
  return base64UrlEncode(bytes).replaceAll('=', '');
}
