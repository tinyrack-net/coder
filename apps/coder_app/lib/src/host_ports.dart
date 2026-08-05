import 'package:coder_app/src/host_models.dart';
import 'package:coder_client/coder_client.dart';

export 'package:coder_app/src/ports.dart';

/// Stores daemon-independent application settings.
abstract interface class AppSettingsRepository {
  /// Loads settings, returning stable defaults for a fresh install.
  Future<AppSettings> loadSettings();

  /// Persists the complete settings value.
  Future<void> saveSettings(AppSettings settings);
}

/// Stores non-secret remote daemon profiles.
abstract interface class RemoteHostRepository {
  /// Lists every configured remote daemon.
  Future<List<RemoteDaemonProfile>> listProfiles();

  /// Creates or replaces one profile by ID.
  Future<void> upsertProfile(RemoteDaemonProfile profile);

  /// Deletes one profile by ID.
  Future<void> deleteProfile(String profileId);
}

/// Stores bearer tokens separately from non-secret profiles.
abstract interface class RemoteHostCredentialStore {
  /// Reads the bearer token for one profile.
  Future<String?> readBearerToken(String profileId);

  /// Writes the bearer token for one profile.
  Future<void> writeBearerToken(String profileId, String token);

  /// Deletes the bearer token for one profile.
  Future<void> deleteBearerToken(String profileId);
}

/// Opens one typed daemon API without owning profile persistence.
abstract interface class HostClientFactory {
  /// Connects and completes after the daemon handshake succeeds.
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  });
}

/// Running app-owned daemon information passed to the host registry.
abstract interface class EmbeddedDaemonSession {
  /// Bound local endpoint.
  HostEndpoint get endpoint;

  /// Full-access daemon credential.
  DaemonCredentials get credentials;

  /// Daemon identity known before the client handshake.
  String get serverId;

  /// Stops only this app-owned daemon.
  Future<void> stop();
}

/// Optional desktop port for starting an app-owned daemon.
abstract interface class EmbeddedDaemonLauncher {
  /// Starts one daemon session.
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  });
}

/// Injectable asynchronous delay used by reconnect loops.
abstract interface class AppDelay {
  /// Completes after [duration].
  Future<void> wait(Duration duration);
}

/// Production wall-clock delay.
final class SystemAppDelay implements AppDelay {
  /// Creates the system delay adapter.
  const SystemAppDelay();

  @override
  Future<void> wait(Duration duration) => Future<void>.delayed(duration);
}

/// Produces a capped retry delay for one-based attempts.
abstract interface class RetryDelayPolicy {
  /// Returns the delay for [attempt].
  Duration delayFor(int attempt);
}

/// Capped exponential retry policy shared by every host runtime.
final class ExponentialRetryDelayPolicy implements RetryDelayPolicy {
  /// Creates the default retry policy.
  const ExponentialRetryDelayPolicy();

  @override
  Duration delayFor(int attempt) => Duration(
    seconds: (1 << (attempt - 1).clamp(0, 5)).clamp(1, 30),
  );
}

/// Deterministic in-memory adapter used by unit and widget compositions.
final class MemoryAppStore
    implements
        AppSettingsRepository,
        RemoteHostRepository,
        RemoteHostCredentialStore {
  /// Creates an in-memory store.
  MemoryAppStore({
    this.settings = const AppSettings(),
    List<RemoteDaemonProfile> profiles = const <RemoteDaemonProfile>[],
    Map<String, String> tokens = const <String, String>{},
  }) : profiles = List<RemoteDaemonProfile>.of(profiles),
       tokens = Map<String, String>.of(tokens);

  /// Current settings value.
  AppSettings settings;

  /// Current profile values.
  final List<RemoteDaemonProfile> profiles;

  /// Current bearer tokens keyed by profile ID.
  final Map<String, String> tokens;

  @override
  Future<void> deleteBearerToken(String profileId) async {
    tokens.remove(profileId);
  }

  @override
  Future<void> deleteProfile(String profileId) async {
    profiles.removeWhere((profile) => profile.id == profileId);
  }

  @override
  Future<List<RemoteDaemonProfile>> listProfiles() async =>
      List<RemoteDaemonProfile>.unmodifiable(profiles);

  @override
  Future<AppSettings> loadSettings() async => settings;

  @override
  Future<String?> readBearerToken(String profileId) async => tokens[profileId];

  @override
  Future<void> saveSettings(AppSettings settings) async {
    this.settings = settings;
  }

  @override
  Future<void> upsertProfile(RemoteDaemonProfile profile) async {
    final index = profiles.indexWhere((item) => item.id == profile.id);
    if (index < 0) {
      profiles.add(profile);
    } else {
      profiles[index] = profile;
    }
  }

  @override
  Future<void> writeBearerToken(String profileId, String token) async {
    tokens[profileId] = token;
  }
}
