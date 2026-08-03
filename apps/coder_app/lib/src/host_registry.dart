import 'dart:async';

import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';

final class _RuntimeResource {
  _RuntimeResource({required this.generation});

  int generation;
  int retryAttempt = 0;
  CoderApi? api;
  // The owning HostRegistry cancels this subscription in _stopRuntime and
  // close.
  // ignore: cancel_subscriptions
  StreamSubscription<ClientConnectionState>? states;
}

/// Owns every daemon runtime while keeping connection failures independent.
final class HostRegistry {
  /// Creates a host registry from typed persistence and transport ports.
  factory HostRegistry({
    required AppSettingsRepository store,
    required HostClientFactory clientFactory,
    required AppIdGenerator ids,
    required AppClock clock,
    required AppDelay delay,
    required String clientKind,
    RemoteHostRepository? profiles,
    RemoteHostCredentialStore? credentials,
    EmbeddedDaemonLauncher? embeddedLauncher,
    RetryDelayPolicy retryPolicy = const ExponentialRetryDelayPolicy(),
  }) => HostRegistry._(
    settings: store,
    profiles: profiles ?? _requireProfiles(store),
    credentials: credentials ?? _requireCredentials(store),
    clientFactory: clientFactory,
    embeddedLauncher: embeddedLauncher,
    ids: ids,
    clock: clock,
    delay: delay,
    clientKind: clientKind,
    retryPolicy: retryPolicy,
  );

  HostRegistry._({
    required this._settings,
    required this._profiles,
    required this._credentials,
    required this._clientFactory,
    required this._embeddedLauncher,
    required this._ids,
    required this._clock,
    required this._delay,
    required this._clientKind,
    required this._retryPolicy,
  });

  final AppSettingsRepository _settings;
  final RemoteHostRepository _profiles;
  final RemoteHostCredentialStore _credentials;
  final HostClientFactory _clientFactory;
  final EmbeddedDaemonLauncher? _embeddedLauncher;
  final AppIdGenerator _ids;
  final AppClock _clock;
  final AppDelay _delay;
  final String _clientKind;
  final RetryDelayPolicy _retryPolicy;
  final Map<String, _RuntimeResource> _resources = <String, _RuntimeResource>{};
  final Map<String, String> _serverOwners = <String, String>{};
  final StreamController<HostRegistryState> _changes =
      StreamController<HostRegistryState>.broadcast(sync: true);
  EmbeddedDaemonSession? _embeddedSession;
  Future<void> _embeddedLifecycle = Future<void>.value();
  HostRegistryState? _state;
  bool _closed = false;

  /// Latest loaded registry state.
  HostRegistryState get value =>
      _state ?? (throw StateError('HostRegistry.load must complete first.'));

  /// State changes after the initial [load].
  Stream<HostRegistryState> get changes => _changes.stream;

  /// Hydrates local settings without awaiting daemon startup or connections.
  Future<HostRegistryState> load() async {
    if (_state != null) return value;
    final settings = await _settings.loadSettings();
    final profiles = await _profiles.listProfiles();
    final runtimes = <String, HostRuntimeSnapshot>{
      if (settings.embeddedDaemonEnabled && _embeddedLauncher != null)
        embeddedHostId: const HostRuntimeSnapshot(
          id: embeddedHostId,
          label: '내장 daemon',
          kind: HostKind.embedded,
          status: HostRuntimeStatus.connecting,
        ),
      for (final profile in profiles)
        profile.id: HostRuntimeSnapshot(
          id: profile.id,
          label: profile.label,
          kind: HostKind.remote,
          status: profile.autoConnect
              ? HostRuntimeStatus.connecting
              : HostRuntimeStatus.idle,
          endpoint: HostEndpoint(websocketUri: profile.websocketUri),
        ),
    };
    _state = HostRegistryState(
      settings: settings,
      profiles: List<RemoteDaemonProfile>.unmodifiable(profiles),
      runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(runtimes),
    );
    scheduleMicrotask(() {
      if (_closed) return;
      if (settings.embeddedDaemonEnabled && _embeddedLauncher != null) {
        unawaited(
          _serializeEmbedded(
            () => _startEmbedded(settings.embeddedDaemonExposure),
          ),
        );
      }
      for (final profile in profiles.where((profile) => profile.autoConnect)) {
        unawaited(_connectRemote(profile.id));
      }
    });
    return value;
  }

  /// Saves an offline-capable remote profile and optionally starts connecting.
  Future<RemoteDaemonProfile> addRemote({
    required String label,
    required String address,
    required String bearerToken,
    required bool autoConnect,
  }) async {
    _ensureLoaded();
    final endpoint = _parseEndpoint(address);
    final token = bearerToken.trim();
    if (token.isEmpty) {
      throw const HostConnectionFailure.authentication(
        'Bearer token을 입력하세요.',
      );
    }
    final now = _clock.nowUtc();
    final profile = RemoteDaemonProfile(
      id: _ids.generate(),
      label: label.trim().isEmpty
          ? endpoint.websocketUri.authority
          : label.trim(),
      websocketUri: endpoint.websocketUri,
      autoConnect: autoConnect,
      createdAt: now,
      updatedAt: now,
    );
    await _credentials.writeBearerToken(profile.id, token);
    try {
      await _profiles.upsertProfile(profile);
    } on Exception {
      await _credentials.deleteBearerToken(profile.id);
      rethrow;
    }
    final nextProfiles = <RemoteDaemonProfile>[...value.profiles, profile];
    final nextRuntimes = Map<String, HostRuntimeSnapshot>.of(value.runtimes)
      ..[profile.id] = HostRuntimeSnapshot(
        id: profile.id,
        label: profile.label,
        kind: HostKind.remote,
        status: autoConnect
            ? HostRuntimeStatus.connecting
            : HostRuntimeStatus.idle,
        endpoint: endpoint,
      );
    _emit(
      value.copyWith(
        profiles: List<RemoteDaemonProfile>.unmodifiable(nextProfiles),
        runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(nextRuntimes),
      ),
    );
    if (autoConnect) unawaited(_connectRemote(profile.id));
    return profile;
  }

  /// Updates one remote profile and restarts only its runtime.
  Future<void> updateRemote({
    required String profileId,
    required String label,
    required String address,
    required bool autoConnect,
    String? replacementBearerToken,
  }) async {
    final previous = _profile(profileId);
    final endpoint = _parseEndpoint(address);
    if (replacementBearerToken case final token? when token.trim().isNotEmpty) {
      await _credentials.writeBearerToken(profileId, token.trim());
    }
    final updated = previous.copyWith(
      label: label.trim().isEmpty
          ? endpoint.websocketUri.authority
          : label.trim(),
      websocketUri: endpoint.websocketUri,
      autoConnect: autoConnect,
      updatedAt: _clock.nowUtc(),
    );
    await _profiles.upsertProfile(updated);
    await _stopRuntime(profileId);
    _replaceProfile(updated);
    _replaceRuntime(
      HostRuntimeSnapshot(
        id: profileId,
        label: updated.label,
        kind: HostKind.remote,
        status: autoConnect
            ? HostRuntimeStatus.connecting
            : HostRuntimeStatus.idle,
        endpoint: endpoint,
      ),
    );
    if (autoConnect) unawaited(_connectRemote(profileId));
  }

  /// Enables or disables startup connection for one remote profile.
  Future<void> setAutoConnect(
    String profileId, {
    required bool enabled,
  }) async {
    final profile = _profile(profileId);
    await updateRemote(
      profileId: profileId,
      label: profile.label,
      address: profile.websocketUri.toString(),
      autoConnect: enabled,
    );
  }

  /// Retries one host immediately and resets its backoff.
  Future<void> reconnect(String hostId) async {
    if (hostId == embeddedHostId) {
      await _serializeEmbedded(() async {
        await _stopEmbedded();
        _replaceRuntime(
          const HostRuntimeSnapshot(
            id: embeddedHostId,
            label: '내장 daemon',
            kind: HostKind.embedded,
            status: HostRuntimeStatus.connecting,
          ),
        );
        await _startEmbedded(value.settings.embeddedDaemonExposure);
      });
      return;
    }
    await _stopRuntime(hostId);
    final profile = _profile(hostId);
    _replaceRuntime(
      HostRuntimeSnapshot(
        id: hostId,
        label: profile.label,
        kind: HostKind.remote,
        status: HostRuntimeStatus.connecting,
        endpoint: HostEndpoint(websocketUri: profile.websocketUri),
      ),
    );
    await _connectRemote(hostId, manual: true);
  }

  /// Deletes one remote profile, runtime, and secret credential.
  Future<void> removeRemote(String profileId) async {
    await _stopRuntime(profileId);
    await _profiles.deleteProfile(profileId);
    await _credentials.deleteBearerToken(profileId);
    var settings = value.settings;
    if (settings.lastActiveHostId == profileId) {
      settings = settings.copyWith(clearLastActiveHost: true);
      await _settings.saveSettings(settings);
    }
    if (settings.lastWorktree?.hostId == profileId ||
        settings.sessionTabs.keys.any(
          (key) => key.startsWith('$profileId\u0000'),
        )) {
      settings = settings.copyWith(
        clearLastWorktree: settings.lastWorktree?.hostId == profileId,
        sessionTabs: Map<String, SessionTabPreference>.unmodifiable(
          Map<String, SessionTabPreference>.of(settings.sessionTabs)
            ..removeWhere((key, value) => key.startsWith('$profileId\u0000')),
        ),
      );
      await _settings.saveSettings(settings);
    }
    _emit(
      value.copyWith(
        settings: settings,
        profiles: List<RemoteDaemonProfile>.unmodifiable(
          value.profiles.where((profile) => profile.id != profileId),
        ),
        runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(
          Map<String, HostRuntimeSnapshot>.of(value.runtimes)
            ..remove(profileId),
        ),
      ),
    );
  }

  /// Persists a host selection without requiring it to be online.
  Future<void> selectHost(String hostId) async {
    final settings = value.settings.copyWith(lastActiveHostId: hostId);
    await _settings.saveSettings(settings);
    _emit(value.copyWith(settings: settings));
  }

  /// Persists the selected checkout and its locally-visible session tabs.
  Future<void> saveWorkspaceUi({
    required WorkspaceSelection selection,
    required SessionTabPreference tabs,
  }) async {
    final settings = value.settings.copyWith(
      lastActiveHostId: selection.hostId,
      lastWorktree: selection,
      sessionTabs: Map<String, SessionTabPreference>.unmodifiable(
        <String, SessionTabPreference>{
          ...value.settings.sessionTabs,
          selection.storageKey: tabs,
        },
      ),
    );
    await _settings.saveSettings(settings);
    _emit(value.copyWith(settings: settings));
  }

  /// Starts or stops only the app-owned desktop daemon.
  Future<void> setEmbeddedDaemonEnabled({required bool enabled}) async {
    if (_embeddedLauncher == null) return;
    await _serializeEmbedded(() async {
      final settings = value.settings.copyWith(
        embeddedDaemonEnabled: enabled,
        clearLastActiveHost:
            !enabled && value.settings.lastActiveHostId == embeddedHostId,
      );
      await _settings.saveSettings(settings);
      if (!enabled) {
        await _stopEmbedded();
        final runtimes = Map<String, HostRuntimeSnapshot>.of(value.runtimes)
          ..remove(embeddedHostId);
        _emit(
          value.copyWith(
            settings: settings,
            runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(runtimes),
          ),
        );
        return;
      }
      _emit(
        value.copyWith(
          settings: settings,
          runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(
            <String, HostRuntimeSnapshot>{
              ...value.runtimes,
              embeddedHostId: const HostRuntimeSnapshot(
                id: embeddedHostId,
                label: '내장 daemon',
                kind: HostKind.embedded,
                status: HostRuntimeStatus.connecting,
              ),
            },
          ),
        ),
      );
      await _startEmbedded(settings.embeddedDaemonExposure);
    });
  }

  /// Persists and applies a listener exposure to the app-owned daemon.
  Future<void> setEmbeddedDaemonExposure(
    EmbeddedDaemonExposure exposure,
  ) async {
    if (_embeddedLauncher == null) return;
    await _serializeEmbedded(() async {
      final settings = value.settings.copyWith(
        embeddedDaemonExposure: exposure,
      );
      await _settings.saveSettings(settings);
      if (!settings.embeddedDaemonEnabled) {
        _emit(value.copyWith(settings: settings));
        return;
      }
      await _stopEmbedded();
      _emit(
        value.copyWith(
          settings: settings,
          runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(
            <String, HostRuntimeSnapshot>{
              ...value.runtimes,
              embeddedHostId: const HostRuntimeSnapshot(
                id: embeddedHostId,
                label: '내장 daemon',
                kind: HostKind.embedded,
                status: HostRuntimeStatus.connecting,
              ),
            },
          ),
        ),
      );
      await _startEmbedded(exposure);
    });
  }

  Future<void> _startEmbedded(EmbeddedDaemonExposure exposure) async {
    final launcher = _embeddedLauncher;
    if (launcher == null || _closed) return;
    try {
      final session = await launcher.start(exposure: exposure);
      if (_closed || !value.settings.embeddedDaemonEnabled) {
        await session.stop();
        return;
      }
      _embeddedSession = session;
      await _connect(
        hostId: embeddedHostId,
        endpoint: session.endpoint,
        credentials: session.credentials,
        retry: false,
      );
    } on Exception catch (error) {
      if (_closed) return;
      _setFailure(embeddedHostId, _failureFrom(error), retry: false);
    }
  }

  Future<void> _connectRemote(String profileId, {bool manual = false}) async {
    if (_closed) return;
    final profile = _profileOrNull(profileId);
    if (profile == null || (!manual && !profile.autoConnect)) return;
    final token = await _credentials.readBearerToken(profileId);
    if (token == null || token.isEmpty) {
      _setFailure(
        profileId,
        const HostConnectionFailure.authentication('Bearer token이 없습니다.'),
        retry: false,
      );
      return;
    }
    await _connect(
      hostId: profileId,
      endpoint: HostEndpoint(websocketUri: profile.websocketUri),
      credentials: DaemonCredentials(bearerToken: token),
      retry: profile.autoConnect,
    );
  }

  Future<void> _connect({
    required String hostId,
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required bool retry,
  }) async {
    final resource = _resources.putIfAbsent(
      hostId,
      () => _RuntimeResource(generation: 0),
    );
    final generation = resource.generation;
    _updateRuntime(
      hostId,
      (runtime) => runtime.copyWith(
        status: HostRuntimeStatus.connecting,
        endpoint: endpoint,
        clearError: true,
        clearConflict: true,
      ),
    );
    try {
      final api = await _clientFactory.connect(
        endpoint: endpoint,
        credentials: credentials,
        clientId: _ids.generate(),
        clientKind: _clientKind,
      );
      if (_closed || resource.generation != generation) {
        await api.close();
        return;
      }
      final conflictingHostId = _serverOwners[api.serverInfo.serverId];
      if (conflictingHostId != null && conflictingHostId != hostId) {
        await api.close();
        _updateRuntime(
          hostId,
          (runtime) => runtime.copyWith(
            status: HostRuntimeStatus.conflict,
            conflictingHostId: conflictingHostId,
            error: '같은 daemon이 이미 등록되어 있습니다.',
            clearApi: true,
          ),
        );
        return;
      }
      _serverOwners[api.serverInfo.serverId] = hostId;
      resource
        ..api = api
        ..retryAttempt = 0;
      await resource.states?.cancel();
      resource.states = api.states.listen(
        (state) => _handleClientState(hostId, api, state),
      );
      _updateRuntime(
        hostId,
        (runtime) => runtime.copyWith(
          status: HostRuntimeStatus.online,
          api: api,
          serverInfo: api.serverInfo,
          clearError: true,
        ),
      );
      if (hostId != embeddedHostId) {
        final profile = _profile(hostId).copyWith(
          serverId: api.serverInfo.serverId,
          lastConnectedAt: _clock.nowUtc(),
          updatedAt: _clock.nowUtc(),
        );
        await _profiles.upsertProfile(profile);
        _replaceProfile(profile);
      }
    } on Exception catch (error) {
      if (_closed || resource.generation != generation) return;
      final failure = _failureFrom(error);
      _setFailure(hostId, failure, retry: retry && failure.retryable);
      if (retry && failure.retryable) {
        resource.retryAttempt += 1;
        await _delay.wait(_retryPolicy.delayFor(resource.retryAttempt));
        if (_closed || resource.generation != generation) return;
        await _connectRemote(hostId);
      }
    }
  }

  void _handleClientState(
    String hostId,
    CoderApi api,
    ClientConnectionState state,
  ) {
    if (_closed || value.runtimes[hostId]?.api != api) return;
    final status = switch (state) {
      ClientConnectionState.connected => HostRuntimeStatus.online,
      ClientConnectionState.connecting ||
      ClientConnectionState.reconnecting => HostRuntimeStatus.reconnecting,
      ClientConnectionState.disconnected => HostRuntimeStatus.offline,
    };
    _updateRuntime(hostId, (runtime) => runtime.copyWith(status: status));
  }

  void _setFailure(
    String hostId,
    HostConnectionFailure failure, {
    required bool retry,
  }) {
    _updateRuntime(
      hostId,
      (runtime) => runtime.copyWith(
        status: retry ? HostRuntimeStatus.offline : HostRuntimeStatus.error,
        error: failure.message,
        clearApi: true,
      ),
    );
  }

  HostConnectionFailure _failureFrom(Object error) {
    if (error is HostConnectionFailure) return error;
    if (error is CoderClientException && error.code == 'protocol_mismatch') {
      return HostConnectionFailure.protocolMismatch(error.message);
    }
    return HostConnectionFailure.network('$error');
  }

  HostEndpoint _parseEndpoint(String address) {
    try {
      return HostEndpoint.parse(address);
    } on FormatException catch (error) {
      throw HostConnectionFailure.invalidEndpoint(error.message);
    }
  }

  Future<void> _stopEmbedded() async {
    await _stopRuntime(embeddedHostId);
    final session = _embeddedSession;
    _embeddedSession = null;
    await session?.stop();
  }

  Future<void> _stopRuntime(String hostId) async {
    final resource = _resources.remove(hostId);
    if (resource == null) return;
    resource.generation += 1;
    await resource.states?.cancel();
    await resource.api?.close();
    _serverOwners.removeWhere((serverId, owner) => owner == hostId);
  }

  Future<void> _serializeEmbedded(
    Future<void> Function() operation,
  ) {
    final result = _embeddedLifecycle.then<void>((_) => operation());
    _embeddedLifecycle = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        // The caller observes the failure through result; recovering this tail
        // allows later lifecycle operations to continue safely.
      },
    );
    return result;
  }

  void _replaceProfile(RemoteDaemonProfile profile) {
    _emit(
      value.copyWith(
        profiles: List<RemoteDaemonProfile>.unmodifiable(<RemoteDaemonProfile>[
          for (final item in value.profiles)
            if (item.id == profile.id) profile else item,
        ]),
      ),
    );
  }

  void _replaceRuntime(HostRuntimeSnapshot runtime) {
    final runtimes = Map<String, HostRuntimeSnapshot>.of(value.runtimes)
      ..[runtime.id] = runtime;
    _emit(
      value.copyWith(
        runtimes: Map<String, HostRuntimeSnapshot>.unmodifiable(runtimes),
      ),
    );
  }

  void _updateRuntime(
    String hostId,
    HostRuntimeSnapshot Function(HostRuntimeSnapshot current) update,
  ) {
    final current = value.runtimes[hostId];
    if (current == null) return;
    _replaceRuntime(update(current));
  }

  void _emit(HostRegistryState next) {
    if (_closed) return;
    _state = next;
    _changes.add(next);
  }

  RemoteDaemonProfile _profile(String id) =>
      _profileOrNull(id) ?? (throw StateError('Unknown remote host: $id'));

  RemoteDaemonProfile? _profileOrNull(String id) {
    for (final profile in value.profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  void _ensureLoaded() {
    if (_state == null) {
      throw StateError('HostRegistry.load must complete first.');
    }
  }

  /// Closes every client and the app-owned daemon.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _embeddedLifecycle;
    for (final hostId in List<String>.of(_resources.keys)) {
      await _stopRuntime(hostId);
    }
    final session = _embeddedSession;
    _embeddedSession = null;
    await session?.stop();
    await _changes.close();
  }

  static RemoteHostRepository _requireProfiles(AppSettingsRepository store) {
    if (store case final RemoteHostRepository profiles) return profiles;
    throw ArgumentError('A RemoteHostRepository must be provided.');
  }

  static RemoteHostCredentialStore _requireCredentials(
    AppSettingsRepository store,
  ) {
    if (store case final RemoteHostCredentialStore credentials) {
      return credentials;
    }
    throw ArgumentError('A RemoteHostCredentialStore must be provided.');
  }
}
