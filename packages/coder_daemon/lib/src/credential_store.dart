import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class CredentialStore {
  CredentialStore(this.configDirectory);

  final String configDirectory;
  final Map<String, String> _providerKeys = <String, String>{};
  String? _bearerToken;
  bool _loaded = false;

  File get _credentialsFile =>
      File(p.join(configDirectory, 'credentials.json'));
  File get _authFile => File(p.join(configDirectory, 'auth.json'));

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    await _ensureDirectory();
    if (await _credentialsFile.exists()) {
      final decoded = jsonDecode(await _credentialsFile.readAsString());
      if (decoded is Map && decoded['providerApiKeys'] is Map) {
        for (final entry in (decoded['providerApiKeys'] as Map).entries) {
          if (entry.key is String && entry.value is String) {
            _providerKeys[entry.key as String] = entry.value as String;
          }
        }
      }
    }
    if (await _authFile.exists()) {
      final decoded = jsonDecode(await _authFile.readAsString());
      if (decoded is Map && decoded['bearerToken'] is String) {
        _bearerToken = decoded['bearerToken'] as String;
      }
    }
  }

  String? get bearerToken => _bearerToken;
  String? providerApiKey(String providerId) => _providerKeys[providerId];

  Future<void> setBearerToken(String token) async {
    await load();
    _bearerToken = token;
    await _writeJson(_authFile, <String, dynamic>{
      'version': 1,
      'bearerToken': token,
    });
  }

  Future<void> setProviderApiKey(String providerId, String value) async {
    await load();
    if (value.isEmpty) {
      _providerKeys.remove(providerId);
    } else {
      _providerKeys[providerId] = value;
    }
    await _writeJson(_credentialsFile, <String, dynamic>{
      'version': 1,
      'providerApiKeys': _providerKeys,
    });
  }

  Future<void> removeProvider(String providerId) =>
      setProviderApiKey(providerId, '');

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
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
    if (!Platform.isWindows) {
      await Process.run('chmod', <String>['600', file.path]);
    }
  }
}
