import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Supplies process environment and operating-system information.
///
/// The daemon and the standalone CLI must agree byte for byte on where the
/// configuration lives, so both resolve it through this one implementation.
abstract interface class LocalDaemonEnvironment {
  /// Environment variables visible to the process.
  Map<String, String> get values;

  /// Whether the process runs on Linux.
  bool get isLinux;

  /// Whether the process runs on macOS.
  bool get isMacOS;

  /// Whether the process runs on Windows.
  bool get isWindows;
}

/// Production [LocalDaemonEnvironment] backed by `dart:io`.
final class IoLocalDaemonEnvironment implements LocalDaemonEnvironment {
  /// Creates the production environment adapter.
  const IoLocalDaemonEnvironment();

  @override
  Map<String, String> get values => Platform.environment;

  @override
  bool get isLinux => Platform.isLinux;

  @override
  bool get isMacOS => Platform.isMacOS;

  @override
  bool get isWindows => Platform.isWindows;
}

/// Platform-specific locations the local daemon reads and writes.
final class LocalDaemonDirectories {
  /// Creates one resolved directory set.
  const LocalDaemonDirectories({
    required this.configDirectory,
    required this.stateDirectory,
    required this.userHomeDirectory,
  });

  /// Holds `credentials.json`.
  final String configDirectory;

  /// Holds the database and other recoverable state.
  final String stateDirectory;

  /// Real user home used to locate the shared `~/.agents` tree.
  final String userHomeDirectory;
}

/// Default listening endpoint when nothing overrides it.
const String defaultLocalDaemonListen = '127.0.0.1:7337';

/// Resolves the daemon directories for the current platform.
///
/// `TINYRACK_CODER_HOME` collapses configuration and state into one directory,
/// which is what tests and portable installations use.
LocalDaemonDirectories resolveLocalDaemonDirectories({
  LocalDaemonEnvironment environment = const IoLocalDaemonEnvironment(),
}) {
  final values = environment.values;
  final defaults = _defaultDirectories(values, environment);
  final override = values['TINYRACK_CODER_HOME'];
  return LocalDaemonDirectories(
    configDirectory: override ?? defaults.configDirectory,
    stateDirectory: override ?? defaults.stateDirectory,
    userHomeDirectory:
        values['TINYRACK_CODER_AGENTS_HOME'] ?? defaults.userHomeDirectory,
  );
}

/// Splits a `host:port` listen string.
///
/// Throws a [FormatException] when [listen] carries no port, because silently
/// falling back would connect the caller to the wrong daemon.
(String, int) parseLocalDaemonListen(String listen) {
  final separator = listen.lastIndexOf(':');
  if (separator < 1) {
    throw FormatException('A listen address must be host:port, got "$listen".');
  }
  final port = int.tryParse(listen.substring(separator + 1));
  if (port == null) {
    throw FormatException('A listen address must be host:port, got "$listen".');
  }
  return (listen.substring(0, separator), port);
}

/// Reads the daemon bearer token written by a running daemon.
///
/// Returns null when no daemon has ever provisioned a token in
/// [configDirectory]. Writing credentials stays with the daemon; clients only
/// ever read.
Future<String?> readLocalDaemonBearerToken(String configDirectory) async {
  final file = File(p.join(configDirectory, 'credentials.json'));
  if (!file.existsSync()) return null;
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic> || decoded['version'] != 5) {
    throw FormatException(
      'incompatible_credentials: explicitly remove ${file.path} to reset '
      'development credentials.',
    );
  }
  final daemon = decoded['daemon'];
  if (daemon == null) return null;
  if (daemon is! Map<String, dynamic> || daemon['bearerToken'] is! String) {
    throw const FormatException('Invalid daemon credential data.');
  }
  return daemon['bearerToken'] as String;
}

LocalDaemonDirectories _defaultDirectories(
  Map<String, String> environment,
  LocalDaemonEnvironment platform,
) {
  final userHome =
      environment[platform.isWindows ? 'USERPROFILE' : 'HOME'] ?? '.';
  if (platform.isLinux) {
    final config =
        environment['XDG_CONFIG_HOME'] ?? p.join(userHome, '.config');
    final state =
        environment['XDG_STATE_HOME'] ?? p.join(userHome, '.local', 'state');
    return LocalDaemonDirectories(
      configDirectory: p.join(config, 'tinyrack-coder'),
      stateDirectory: p.join(state, 'tinyrack-coder'),
      userHomeDirectory: userHome,
    );
  }
  if (platform.isMacOS) {
    final support = p.join(
      userHome,
      'Library',
      'Application Support',
      'Tinyrack Coder',
    );
    return LocalDaemonDirectories(
      configDirectory: support,
      stateDirectory: support,
      userHomeDirectory: userHome,
    );
  }
  if (platform.isWindows) {
    final config = environment['APPDATA'] ?? userHome;
    final state = environment['LOCALAPPDATA'] ?? config;
    return LocalDaemonDirectories(
      configDirectory: p.join(config, 'Tinyrack Coder'),
      stateDirectory: p.join(state, 'Tinyrack Coder'),
      userHomeDirectory: userHome,
    );
  }
  return LocalDaemonDirectories(
    configDirectory: p.join(userHome, '.config', 'tinyrack-coder'),
    stateDirectory: p.join(userHome, '.local', 'state', 'tinyrack-coder'),
    userHomeDirectory: userHome,
  );
}
