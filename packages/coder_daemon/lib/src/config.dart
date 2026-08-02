import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// Supplies process environment and operating-system information to config.
abstract interface class DaemonEnvironment {
  /// Environment variables visible to the daemon process.
  Map<String, String> get values;

  /// Whether the daemon runs on Linux.
  bool get isLinux;

  /// Whether the daemon runs on macOS.
  bool get isMacOS;

  /// Whether the daemon runs on Windows.
  bool get isWindows;
}

/// Production [DaemonEnvironment] backed by `dart:io`.
final class IoDaemonEnvironment implements DaemonEnvironment {
  /// Creates the production environment adapter.
  const IoDaemonEnvironment();

  @override
  Map<String, String> get values => Platform.environment;

  @override
  bool get isLinux => Platform.isLinux;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isWindows => Platform.isWindows;
}

/// DaemonConfig defines a public contract.
class DaemonConfig {
  /// Creates a [DaemonConfig].
  const DaemonConfig({
    required this.homeDirectory,
    String? configDirectory,
    this.host = '127.0.0.1',
    this.port = 7337,
    this.apiKey,
    this.bearerToken,
    this.version = '0.1.0',
  }) : configDirectory = configDirectory ?? homeDirectory;

  /// Creates a [DaemonConfig].
  factory DaemonConfig.fromIsolateMessage(Map<Object?, Object?> value) =>
      DaemonConfig(
        homeDirectory: value['homeDirectory']! as String,
        configDirectory: value['configDirectory'] as String?,
        host: value['host']! as String,
        port: value['port']! as int,
        apiKey: value['apiKey'] as String?,
        bearerToken: value['bearerToken'] as String?,
        version: value['version']! as String,
      );

  /// Creates a [DaemonConfig].
  factory DaemonConfig.fromEnvironment({
    String? apiKey,
    DaemonEnvironment environment = const IoDaemonEnvironment(),
  }) {
    final values = environment.values;
    final override = values['TINYRACK_CODER_HOME'];
    final directories = _defaultDirectories(values, environment);
    final home = override ?? directories.$2;
    final configHome = override ?? directories.$1;
    final listen = values['TINYRACK_CODER_LISTEN'] ?? '127.0.0.1:7337';
    final separator = listen.lastIndexOf(':');
    if (separator < 1) {
      throw const FormatException('TINYRACK_CODER_LISTEN must be host:port.');
    }
    return DaemonConfig(
      homeDirectory: home,
      configDirectory: configHome,
      host: listen.substring(0, separator),
      port: int.parse(listen.substring(separator + 1)),
      apiKey: apiKey,
      bearerToken: values['TINYRACK_CODER_TOKEN'],
    );
  }

  /// The homeDirectory public API member.
  final String homeDirectory;

  /// The configDirectory public API member.
  final String configDirectory;

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

  /// The copyWith public API member.
  DaemonConfig copyWith({
    String? homeDirectory,
    String? configDirectory,
    String? host,
    int? port,
    String? apiKey,
    String? bearerToken,
  }) => DaemonConfig(
    homeDirectory: homeDirectory ?? this.homeDirectory,
    configDirectory: configDirectory ?? this.configDirectory,
    host: host ?? this.host,
    port: port ?? this.port,
    apiKey: apiKey ?? this.apiKey,
    bearerToken: bearerToken ?? this.bearerToken,
    version: version,
  );

  /// The toIsolateMessage public API member.
  Map<String, Object?> toIsolateMessage() => <String, Object?>{
    'homeDirectory': homeDirectory,
    'configDirectory': configDirectory,
    'host': host,
    'port': port,
    'apiKey': apiKey,
    'bearerToken': bearerToken,
    'version': version,
  };
}

(String, String) _defaultDirectories(
  Map<String, String> environment,
  DaemonEnvironment platform,
) {
  final userHome =
      environment[platform.isWindows ? 'USERPROFILE' : 'HOME'] ?? '.';
  if (platform.isLinux) {
    final config =
        environment['XDG_CONFIG_HOME'] ?? p.join(userHome, '.config');
    final state =
        environment['XDG_STATE_HOME'] ?? p.join(userHome, '.local', 'state');
    return (p.join(config, 'tinyrack-coder'), p.join(state, 'tinyrack-coder'));
  }
  if (platform.isMacOS) {
    final support = p.join(
      userHome,
      'Library',
      'Application Support',
      'Tinyrack Coder',
    );
    return (support, support);
  }
  if (platform.isWindows) {
    final config = environment['APPDATA'] ?? userHome;
    final state = environment['LOCALAPPDATA'] ?? config;
    return (p.join(config, 'Tinyrack Coder'), p.join(state, 'Tinyrack Coder'));
  }
  return (
    p.join(userHome, '.config', 'tinyrack-coder'),
    p.join(userHome, '.local', 'state', 'tinyrack-coder'),
  );
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
