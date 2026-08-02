import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

class DaemonConfig {
  const DaemonConfig({
    required this.homeDirectory,
    String? configDirectory,
    this.host = '127.0.0.1',
    this.port = 7337,
    this.apiKey,
    this.bearerToken,
    this.version = '0.1.0',
  }) : configDirectory = configDirectory ?? homeDirectory;

  factory DaemonConfig.fromEnvironment({String? apiKey}) {
    final environment = Platform.environment;
    final override = environment['TINYRACK_CODER_HOME'];
    final directories = _defaultDirectories(environment);
    final home = override ?? directories.$2;
    final configHome = override ?? directories.$1;
    final listen = environment['TINYRACK_CODER_LISTEN'] ?? '127.0.0.1:7337';
    final separator = listen.lastIndexOf(':');
    if (separator < 1)
      throw const FormatException('TINYRACK_CODER_LISTEN must be host:port.');
    return DaemonConfig(
      homeDirectory: home,
      configDirectory: configHome,
      host: listen.substring(0, separator),
      port: int.parse(listen.substring(separator + 1)),
      apiKey: apiKey,
      bearerToken: environment['TINYRACK_CODER_TOKEN'],
    );
  }

  final String homeDirectory;
  final String configDirectory;
  final String host;
  final int port;
  final String? apiKey;
  final String? bearerToken;
  final String version;

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

  Map<String, Object?> toIsolateMessage() => <String, Object?>{
    'homeDirectory': homeDirectory,
    'configDirectory': configDirectory,
    'host': host,
    'port': port,
    'apiKey': apiKey,
    'bearerToken': bearerToken,
    'version': version,
  };

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
}

(String, String) _defaultDirectories(Map<String, String> environment) {
  final userHome =
      environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'] ?? '.';
  if (Platform.isLinux) {
    final config =
        environment['XDG_CONFIG_HOME'] ?? p.join(userHome, '.config');
    final state =
        environment['XDG_STATE_HOME'] ?? p.join(userHome, '.local', 'state');
    return (p.join(config, 'tinyrack-coder'), p.join(state, 'tinyrack-coder'));
  }
  if (Platform.isMacOS) {
    final support = p.join(
      userHome,
      'Library',
      'Application Support',
      'Tinyrack Coder',
    );
    return (support, support);
  }
  if (Platform.isWindows) {
    final config = environment['APPDATA'] ?? userHome;
    final state = environment['LOCALAPPDATA'] ?? config;
    return (p.join(config, 'Tinyrack Coder'), p.join(state, 'Tinyrack Coder'));
  }
  return (
    p.join(userHome, '.config', 'tinyrack-coder'),
    p.join(userHome, '.local', 'state', 'tinyrack-coder'),
  );
}

String generateBearerToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(
    32,
    (_) => random.nextInt(256),
    growable: false,
  );
  return base64UrlEncode(bytes).replaceAll('=', '');
}
