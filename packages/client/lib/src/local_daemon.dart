import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:protocol/local_host.dart';

export 'package:protocol/local_host.dart';

/// Production local-host environment backed by `dart:io`.
final class IoLocalDaemonEnvironment implements LocalDaemonEnvironment {
  /// Creates the production adapter.
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

/// Resolves local daemon directories on the current machine.
LocalDaemonDirectories resolveIoLocalDaemonDirectories({
  LocalDaemonEnvironment environment = const IoLocalDaemonEnvironment(),
}) => resolveLocalDaemonDirectories(environment: environment);

/// Reads a daemon bearer token from the v4 owner-restricted secret document.
Future<String?> readLocalDaemonBearerToken(String configDirectory) async {
  final file = File(p.join(configDirectory, 'v4', 'secrets.json'));
  if (!file.existsSync()) return null;
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 2) {
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
