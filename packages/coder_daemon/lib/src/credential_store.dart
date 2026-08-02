import 'dart:convert';
import 'dart:io';

import 'package:coder_daemon/src/repositories.dart';
import 'package:path/path.dart' as p;

/// CredentialStore defines a public contract.
class CredentialStore implements CredentialRepository {
  /// Creates a [CredentialStore].
  CredentialStore(this.configDirectory);

  /// The configDirectory public API member.
  final String configDirectory;
  final Map<String, ProviderCredential> _providerCredentials =
      <String, ProviderCredential>{};
  String? _bearerToken;
  bool _loaded = false;

  File get _credentialsFile =>
      File(p.join(configDirectory, 'credentials.json'));
  File get _authFile => File(p.join(configDirectory, 'auth.json'));

  @override
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await _ensureDirectory();
    if (_credentialsFile.existsSync()) {
      final decoded = jsonDecode(await _credentialsFile.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['version'] != 2) {
        throw FormatException(
          'incompatible_credentials: explicitly remove '
          '${_credentialsFile.path} to reset development credentials.',
        );
      }
      final credentials = decoded['providerCredentials'];
      if (credentials is Map<String, dynamic>) {
        for (final entry in credentials.entries) {
          if (entry.value case final Map<String, dynamic> value) {
            _providerCredentials[entry.key] = _credentialFromJson(value);
          }
        }
      }
    }
    if (_authFile.existsSync()) {
      final decoded = jsonDecode(await _authFile.readAsString());
      if (decoded is Map && decoded['bearerToken'] is String) {
        _bearerToken = decoded['bearerToken'] as String;
      }
    }
  }

  @override
  String? get bearerToken => _bearerToken;

  @override
  ProviderCredential? credential(String connectionId) =>
      _providerCredentials[connectionId];

  @override
  Future<void> setBearerToken(String token) async {
    await load();
    _bearerToken = token;
    await _writeJson(_authFile, <String, dynamic>{
      'version': 1,
      'bearerToken': token,
    });
  }

  @override
  Future<void> setCredential(
    String connectionId,
    ProviderCredential credential,
  ) async {
    await load();
    _providerCredentials[connectionId] = credential;
    await _writeCredentials();
  }

  @override
  Future<void> removeCredential(String connectionId) async {
    await load();
    _providerCredentials.remove(connectionId);
    await _writeCredentials();
  }

  Future<void> _writeCredentials() =>
      _writeJson(_credentialsFile, <String, dynamic>{
        'version': 2,
        'providerCredentials': <String, dynamic>{
          for (final entry in _providerCredentials.entries)
            entry.key: _credentialToJson(entry.value),
        },
      });

  Future<void> _ensureDirectory() async {
    final directory = Directory(configDirectory);
    await directory.create(recursive: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['700', directory.path]);
    }
  }

  Future<void> _writeJson(File file, Map<String, dynamic> value) async {
    await _ensureDirectory();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(value), flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['600', temporary.path]);
    }
    if (Platform.isWindows && file.existsSync()) await file.delete();
    await temporary.rename(file.path);
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['600', file.path]);
    }
  }

  static ProviderCredential _credentialFromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'apiKey' when json['key'] is String => ApiKeyCredential(
          json['key']! as String,
        ),
        'oauth'
            when json['accessToken'] is String &&
                json['refreshToken'] is String &&
                json['expiresAt'] is String =>
          OAuthCredential(
            accessToken: json['accessToken']! as String,
            refreshToken: json['refreshToken']! as String,
            expiresAt: DateTime.parse(json['expiresAt']! as String).toUtc(),
            accountId: json['accountId'] as String?,
          ),
        _ => throw const FormatException('Invalid provider credential data.'),
      };

  static Map<String, dynamic> _credentialToJson(
    ProviderCredential credential,
  ) => switch (credential) {
    ApiKeyCredential(:final key) => <String, dynamic>{
      'type': 'apiKey',
      'key': key,
    },
    OAuthCredential(
      :final accessToken,
      :final refreshToken,
      :final expiresAt,
      :final accountId,
    ) =>
      <String, dynamic>{
        'type': 'oauth',
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'accountId': ?accountId,
      },
  };
}
