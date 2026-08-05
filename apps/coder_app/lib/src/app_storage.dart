import 'dart:convert';

import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Versioned device-local storage for non-secret app and host settings.
final class SharedPreferencesAppStore
    implements AppSettingsRepository, RemoteHostRepository {
  /// Creates a preferences-backed app store.
  SharedPreferencesAppStore(this._preferences);

  /// Single versioned document key; legacy singleton keys are not read.
  static const String documentKey = 'tinyrack_coder.app_document_v3';

  final SharedPreferences _preferences;
  Future<void> _writes = Future<void>.value();

  @override
  Future<AppSettings> loadSettings() async => (await _read()).settings;

  @override
  Future<List<RemoteDaemonProfile>> listProfiles() async =>
      List<RemoteDaemonProfile>.unmodifiable((await _read()).profiles);

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _enqueue((document) => document.copyWith(settings: settings));

  @override
  Future<void> upsertProfile(RemoteDaemonProfile profile) =>
      _enqueue((document) {
        final profiles = List<RemoteDaemonProfile>.of(document.profiles);
        final index = profiles.indexWhere((item) => item.id == profile.id);
        if (index < 0) {
          profiles.add(profile);
        } else {
          profiles[index] = profile;
        }
        return document.copyWith(profiles: profiles);
      });

  @override
  Future<void> deleteProfile(String profileId) => _enqueue(
    (document) => document.copyWith(
      profiles: document.profiles
          .where((profile) => profile.id != profileId)
          .toList(growable: false),
    ),
  );

  @override
  Future<void> clear() {
    // Joins the write chain so a queued update cannot rewrite the document
    // after it is removed.
    final completer = _writes.then((_) async {
      await _preferences.remove(documentKey);
    });
    _writes = completer;
    return completer;
  }

  Future<void> _enqueue(
    _AppDocument Function(_AppDocument current) update,
  ) {
    final completer = _writes.then((_) async {
      final next = update(await _read());
      await _preferences.setString(documentKey, jsonEncode(next.toJson()));
    });
    _writes = completer;
    return completer;
  }

  Future<_AppDocument> _read() async {
    final source = _preferences.getString(documentKey);
    if (source == null) return const _AppDocument();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid app settings document.');
    }
    return _AppDocument.fromJson(decoded);
  }
}

/// Secure-storage adapter containing only remote bearer tokens.
final class SecureRemoteHostCredentialStore
    implements RemoteHostCredentialStore {
  /// Creates a secure remote host credential store.
  const SecureRemoteHostCredentialStore(this._storage);

  static const String _prefix = 'tinyrack_coder.remote_host_token.';
  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteAllBearerTokens() async {
    // Deletes by prefix rather than clearing the whole store, which other
    // plugins share, and also collects tokens orphaned by an earlier crash.
    final stored = await _storage.readAll();
    // Materialized first: deleting while iterating a live keystore view fails.
    final keys = stored.keys
        .where((key) => key.startsWith(_prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }

  @override
  Future<void> deleteBearerToken(String profileId) =>
      _storage.delete(key: '$_prefix$profileId');

  @override
  Future<String?> readBearerToken(String profileId) =>
      _storage.read(key: '$_prefix$profileId');

  @override
  Future<void> writeBearerToken(String profileId, String token) =>
      _storage.write(key: '$_prefix$profileId', value: token);
}

final class _AppDocument {
  const _AppDocument({
    this.settings = const AppSettings(),
    this.profiles = const <RemoteDaemonProfile>[],
  });

  factory _AppDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 3) {
      throw const FormatException(
        'Incompatible app settings. Remove the app_document_v3 preference '
        'to reset development data.',
      );
    }
    final settingsJson = json['settings'];
    final profilesJson = json['profiles'];
    if (settingsJson is! Map<String, dynamic> || profilesJson is! List) {
      throw const FormatException('Invalid app settings document.');
    }
    return _AppDocument(
      settings: _settingsFromJson(settingsJson),
      profiles: profilesJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid remote host profile.');
            }
            return _profileFromJson(item);
          })
          .toList(growable: false),
    );
  }

  final AppSettings settings;
  final List<RemoteDaemonProfile> profiles;

  _AppDocument copyWith({
    AppSettings? settings,
    List<RemoteDaemonProfile>? profiles,
  }) => _AppDocument(
    settings: settings ?? this.settings,
    profiles: profiles ?? this.profiles,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': 3,
    'settings': <String, dynamic>{
      'embeddedDaemonEnabled': settings.embeddedDaemonEnabled,
      'embeddedDaemonExposure': settings.embeddedDaemonExposure.name,
      'embeddedDaemonPort': settings.embeddedDaemonPort,
      'lastActiveHostId': settings.lastActiveHostId,
      'lastWorktree': _selectionToJson(settings.lastWorktree),
      'localeTag': settings.localeTag,
      'sessionTabs': settings.sessionTabs.entries
          .map(
            (entry) => <String, dynamic>{
              'key': entry.key,
              'openAgentIds': entry.value.openAgentIds,
              'selectedAgentId': entry.value.selectedAgentId,
              'openTerminalIds': entry.value.openTerminalIds,
              'selectedTerminalId': entry.value.selectedTerminalId,
            },
          )
          .toList(growable: false),
      'sidebarCollapsed': settings.sidebarCollapsed,
      'startAtBoot': settings.startAtBoot,
      'startMinimizedAtBoot': settings.startMinimizedAtBoot,
    },
    'profiles': profiles.map(_profileToJson).toList(growable: false),
  };
}

AppSettings _settingsFromJson(Map<String, dynamic> json) {
  final embedded = json['embeddedDaemonEnabled'];
  final exposure = json['embeddedDaemonExposure'];
  final port = json['embeddedDaemonPort'];
  final lastHost = json['lastActiveHostId'];
  final lastWorktree = json['lastWorktree'];
  // Absent in documents written before the language setting existed, which
  // read back as the system default rather than failing the whole document.
  final localeTag = json['localeTag'];
  final tabs = json['sessionTabs'];
  final collapsed = json['sidebarCollapsed'];
  // Absent in documents written before the startup settings existed, which
  // keep the enabled defaults rather than failing the whole document.
  final startAtBoot = json['startAtBoot'];
  final startMinimized = json['startMinimizedAtBoot'];
  if (embedded is! bool ||
      collapsed is! bool ||
      (startAtBoot != null && startAtBoot is! bool) ||
      (startMinimized != null && startMinimized is! bool) ||
      (exposure != null && exposure is! String) ||
      (port != null && (port is! int || port < 1 || port > 65535)) ||
      (lastHost != null && lastHost is! String) ||
      (lastWorktree != null && lastWorktree is! Map<String, dynamic>) ||
      (localeTag != null && localeTag is! String) ||
      tabs is! List) {
    throw const FormatException('Invalid app settings values.');
  }
  final sessionTabs = <String, SessionTabPreference>{};
  for (final item in tabs) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Invalid session tab preference.');
    }
    final key = item['key'];
    final openAgentIds = item['openAgentIds'];
    final selectedAgentId = item['selectedAgentId'];
    final openTerminalIds = item['openTerminalIds'] ?? const <dynamic>[];
    final selectedTerminalId = item['selectedTerminalId'];
    if (key is! String ||
        openAgentIds is! List ||
        openAgentIds.any((id) => id is! String) ||
        (selectedAgentId != null && selectedAgentId is! String) ||
        openTerminalIds is! List ||
        openTerminalIds.any((id) => id is! String) ||
        (selectedTerminalId != null && selectedTerminalId is! String)) {
      throw const FormatException('Invalid session tab preference values.');
    }
    sessionTabs[key] = SessionTabPreference(
      openAgentIds: openAgentIds.cast<String>(),
      selectedAgentId: selectedAgentId as String?,
      openTerminalIds: openTerminalIds.cast<String>(),
      selectedTerminalId: selectedTerminalId as String?,
    );
  }
  return AppSettings(
    embeddedDaemonEnabled: embedded,
    embeddedDaemonExposure: _exposureFromJson(exposure),
    embeddedDaemonPort: port as int? ?? defaultEmbeddedDaemonPort,
    lastActiveHostId: lastHost as String?,
    lastWorktree: lastWorktree == null
        ? null
        : _selectionFromJson(lastWorktree as Map<String, dynamic>),
    localeTag: localeTag as String?,
    sessionTabs: Map<String, SessionTabPreference>.unmodifiable(sessionTabs),
    sidebarCollapsed: collapsed,
    startAtBoot: startAtBoot as bool? ?? true,
    startMinimizedAtBoot: startMinimized as bool? ?? true,
  );
}

EmbeddedDaemonExposure _exposureFromJson(Object? value) => switch (value) {
  null || 'loopback' => EmbeddedDaemonExposure.loopback,
  'allInterfaces' => EmbeddedDaemonExposure.allInterfaces,
  _ => throw const FormatException('Invalid embedded daemon exposure.'),
};

WorkspaceSelection _selectionFromJson(Map<String, dynamic> json) {
  final hostId = json['hostId'];
  final workspaceId = json['workspaceId'];
  final worktreeId = json['worktreeId'];
  if (hostId is! String || workspaceId is! String || worktreeId is! String) {
    throw const FormatException('Invalid workspace selection.');
  }
  return WorkspaceSelection(
    hostId: hostId,
    workspaceId: workspaceId,
    worktreeId: worktreeId,
  );
}

Map<String, dynamic>? _selectionToJson(WorkspaceSelection? selection) =>
    selection == null
    ? null
    : <String, dynamic>{
        'hostId': selection.hostId,
        'workspaceId': selection.workspaceId,
        'worktreeId': selection.worktreeId,
      };

RemoteDaemonProfile _profileFromJson(Map<String, dynamic> json) {
  final id = json['id'];
  final label = json['label'];
  final address = json['websocketUri'];
  final autoConnect = json['autoConnect'];
  final serverId = json['serverId'];
  final createdAt = json['createdAt'];
  final updatedAt = json['updatedAt'];
  final lastConnectedAt = json['lastConnectedAt'];
  if (id is! String ||
      label is! String ||
      address is! String ||
      autoConnect is! bool ||
      (serverId != null && serverId is! String) ||
      createdAt is! String ||
      updatedAt is! String ||
      (lastConnectedAt != null && lastConnectedAt is! String)) {
    throw const FormatException('Invalid remote host profile values.');
  }
  return RemoteDaemonProfile(
    id: id,
    label: label,
    websocketUri: HostEndpoint.parse(address).websocketUri,
    autoConnect: autoConnect,
    serverId: serverId as String?,
    createdAt: DateTime.parse(createdAt).toUtc(),
    updatedAt: DateTime.parse(updatedAt).toUtc(),
    lastConnectedAt: lastConnectedAt == null
        ? null
        : DateTime.parse(lastConnectedAt as String).toUtc(),
  );
}

Map<String, dynamic> _profileToJson(RemoteDaemonProfile profile) =>
    <String, dynamic>{
      'id': profile.id,
      'label': profile.label,
      'websocketUri': profile.websocketUri.toString(),
      'autoConnect': profile.autoConnect,
      'serverId': profile.serverId,
      'createdAt': profile.createdAt.toIso8601String(),
      'updatedAt': profile.updatedAt.toIso8601String(),
      'lastConnectedAt': profile.lastConnectedAt?.toIso8601String(),
    };
