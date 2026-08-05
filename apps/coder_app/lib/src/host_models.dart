import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:meta/meta.dart';

/// Stable identifier reserved for the app-owned desktop daemon.
const String embeddedHostId = 'embedded';

/// Fallback name for the app-owned daemon.
///
/// The UI substitutes a localized name through `hostLabel`, so this value
/// only surfaces where no localizations are in scope.
const String embeddedDaemonFallbackLabel = 'Embedded daemon';

/// Default TCP port used by the app-owned daemon.
const int defaultEmbeddedDaemonPort = 7337;

/// Failure causes the app itself raises, so the UI can localize them.
///
/// Failures reported by a daemon keep their server-supplied text instead,
/// which is why [HostConnectionFailure.reason] is nullable.
enum HostFailureReason {
  /// The remote daemon form was submitted without a bearer token.
  missingBearerToken,

  /// A connection was attempted with no bearer token in secure storage.
  noStoredBearerToken,

  /// Another profile already resolved to the same daemon server ID.
  duplicateDaemon,

  /// The daemon answered the handshake with 401 or 403.
  rejectedBearerToken,

  /// The configured embedded-daemon port is owned by another process.
  embeddedPortInUse,
}

/// Network interfaces exposed by the app-owned desktop daemon.
enum EmbeddedDaemonExposure {
  /// Accept connections only from this machine.
  loopback('127.0.0.1'),

  /// Accept IPv4 connections on every network interface.
  allInterfaces('0.0.0.0');

  const EmbeddedDaemonExposure(this.bindHost);

  /// Concrete IPv4 address passed to the daemon listener.
  final String bindHost;
}

/// Settings that are meaningful before any daemon connection exists.
final class AppSettings {
  /// Creates application settings.
  const AppSettings({
    this.embeddedDaemonEnabled = true,
    this.embeddedDaemonExposure = EmbeddedDaemonExposure.loopback,
    this.embeddedDaemonPort = defaultEmbeddedDaemonPort,
    this.lastActiveHostId,
    this.lastWorktree,
    this.localeTag,
    this.sessionTabs = const <String, SessionTabPreference>{},
    this.sidebarCollapsed = false,
    this.startAtBoot = true,
    this.startMinimizedAtBoot = true,
  }) : assert(
         embeddedDaemonPort >= 1 && embeddedDaemonPort <= 65535,
         'embeddedDaemonPort must be between 1 and 65535.',
       );

  /// Whether desktop should manage an app-owned daemon.
  final bool embeddedDaemonEnabled;

  /// Listener exposure selected for the app-owned desktop daemon.
  final EmbeddedDaemonExposure embeddedDaemonExposure;

  /// TCP port selected for the app-owned desktop daemon.
  final int embeddedDaemonPort;

  /// Last host selected by the user, including an offline host.
  final String? lastActiveHostId;

  /// Last selected worktree in the unified workspace tree.
  final WorkspaceSelection? lastWorktree;

  /// Language tag selected for the app UI, or null to follow the system.
  final String? localeTag;

  /// Locally-open session tabs keyed by [WorkspaceSelection.storageKey].
  final Map<String, SessionTabPreference> sessionTabs;

  /// Whether the workspace sidebar is hidden on wide layouts.
  final bool sidebarCollapsed;

  /// Whether the operating system launches the app when the user logs in.
  final bool startAtBoot;

  /// Whether a login-time launch starts hidden in the tray.
  ///
  /// A launch the user started themselves always shows a window, so this only
  /// applies to the registered login item.
  final bool startMinimizedAtBoot;

  /// Returns settings with selected fields replaced.
  AppSettings copyWith({
    bool? embeddedDaemonEnabled,
    EmbeddedDaemonExposure? embeddedDaemonExposure,
    int? embeddedDaemonPort,
    String? lastActiveHostId,
    bool clearLastActiveHost = false,
    WorkspaceSelection? lastWorktree,
    bool clearLastWorktree = false,
    String? localeTag,
    bool clearLocaleTag = false,
    Map<String, SessionTabPreference>? sessionTabs,
    bool? sidebarCollapsed,
    bool? startAtBoot,
    bool? startMinimizedAtBoot,
  }) => AppSettings(
    embeddedDaemonEnabled: embeddedDaemonEnabled ?? this.embeddedDaemonEnabled,
    embeddedDaemonExposure:
        embeddedDaemonExposure ?? this.embeddedDaemonExposure,
    embeddedDaemonPort: embeddedDaemonPort ?? this.embeddedDaemonPort,
    lastActiveHostId: clearLastActiveHost
        ? null
        : lastActiveHostId ?? this.lastActiveHostId,
    lastWorktree: clearLastWorktree ? null : lastWorktree ?? this.lastWorktree,
    localeTag: clearLocaleTag ? null : localeTag ?? this.localeTag,
    sessionTabs: sessionTabs ?? this.sessionTabs,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    startAtBoot: startAtBoot ?? this.startAtBoot,
    startMinimizedAtBoot: startMinimizedAtBoot ?? this.startMinimizedAtBoot,
  );
}

/// Composite identity for a checkout owned by one daemon profile.
@immutable
final class WorkspaceSelection {
  /// Creates a worktree selection.
  const WorkspaceSelection({
    required this.hostId,
    required this.workspaceId,
    required this.worktreeId,
  });

  /// App-local daemon profile identity.
  final String hostId;

  /// Daemon-local repository identity.
  final String workspaceId;

  /// Daemon-local checkout identity.
  final String worktreeId;

  /// Stable device-local key for tab preferences.
  String get storageKey => '$hostId\u0000$workspaceId\u0000$worktreeId';

  @override
  bool operator ==(Object other) =>
      other is WorkspaceSelection &&
      other.hostId == hostId &&
      other.workspaceId == workspaceId &&
      other.worktreeId == worktreeId;

  @override
  int get hashCode => Object.hash(hostId, workspaceId, worktreeId);
}

/// Device-local visible session tabs for one checkout.
final class SessionTabPreference {
  /// Creates session-tab preferences.
  const SessionTabPreference({
    this.openAgentIds = const <String>[],
    this.selectedAgentId,
  });

  /// Session IDs visible as tabs, in display order.
  final List<String> openAgentIds;

  /// Active session tab.
  final String? selectedAgentId;
}

/// Persisted, non-secret configuration for one remote daemon.
final class RemoteDaemonProfile {
  /// Creates a remote daemon profile.
  const RemoteDaemonProfile({
    required this.id,
    required this.label,
    required this.websocketUri,
    required this.autoConnect,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.lastConnectedAt,
  });

  /// App-generated identity used by routes even while offline.
  final String id;

  /// User-visible daemon label.
  final String label;

  /// WebSocket endpoint without credentials.
  final Uri websocketUri;

  /// Whether this daemon connects when the app starts.
  final bool autoConnect;

  /// Authoritative identity learned from a successful handshake.
  final String? serverId;

  /// Creation time in UTC.
  final DateTime createdAt;

  /// Last profile update time in UTC.
  final DateTime updatedAt;

  /// Last successful handshake time in UTC.
  final DateTime? lastConnectedAt;

  /// Returns a profile with selected fields replaced.
  RemoteDaemonProfile copyWith({
    String? label,
    Uri? websocketUri,
    bool? autoConnect,
    String? serverId,
    DateTime? updatedAt,
    DateTime? lastConnectedAt,
  }) => RemoteDaemonProfile(
    id: id,
    label: label ?? this.label,
    websocketUri: websocketUri ?? this.websocketUri,
    autoConnect: autoConnect ?? this.autoConnect,
    serverId: serverId ?? this.serverId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
  );
}

/// Origin of a daemon runtime displayed by the app.
enum HostKind {
  /// App-owned desktop isolate.
  embedded,

  /// User-configured WebSocket endpoint.
  remote,
}

/// Connection lifecycle for one independent host runtime.
enum HostRuntimeStatus {
  /// Persisted but not currently configured to connect.
  idle,

  /// Initial connection is in progress.
  connecting,

  /// Handshake completed and RPCs are available.
  online,

  /// An established client is reconnecting.
  reconnecting,

  /// A retryable connection failed.
  offline,

  /// A permanent configuration or authentication error occurred.
  error,

  /// Another profile already resolved to the same daemon server ID.
  conflict,
}

/// Immutable state for one embedded or remote daemon runtime.
final class HostRuntimeSnapshot {
  /// Creates one host runtime snapshot.
  const HostRuntimeSnapshot({
    required this.id,
    required this.label,
    required this.kind,
    required this.status,
    this.endpoint,
    this.api,
    this.serverInfo,
    this.error,
    this.errorReason,
    this.conflictingHostId,
  });

  /// Stable app host ID.
  final String id;

  /// User-visible label.
  final String label;

  /// Embedded or remote origin.
  final HostKind kind;

  /// Current lifecycle state.
  final HostRuntimeStatus status;

  /// Transport endpoint when known.
  final HostEndpoint? endpoint;

  /// Connected daemon API, available only while online or reconnecting.
  final CoderApi? api;

  /// Handshake metadata from the daemon.
  final ServerInfoDto? serverInfo;

  /// Safe user-facing failure message, used when [errorReason] is null.
  final String? error;

  /// App-authored cause the UI localizes in place of [error].
  final HostFailureReason? errorReason;

  /// Existing profile that resolved to the same server ID.
  final String? conflictingHostId;

  /// Whether RPC calls may currently be issued.
  bool get connected => status == HostRuntimeStatus.online && api != null;

  /// Returns a snapshot with selected fields replaced.
  HostRuntimeSnapshot copyWith({
    String? label,
    HostRuntimeStatus? status,
    HostEndpoint? endpoint,
    CoderApi? api,
    ServerInfoDto? serverInfo,
    String? error,
    HostFailureReason? errorReason,
    String? conflictingHostId,
    bool clearApi = false,
    bool clearError = false,
    bool clearConflict = false,
  }) => HostRuntimeSnapshot(
    id: id,
    label: label ?? this.label,
    kind: kind,
    status: status ?? this.status,
    endpoint: endpoint ?? this.endpoint,
    api: clearApi ? null : api ?? this.api,
    serverInfo: serverInfo ?? this.serverInfo,
    error: clearError ? null : error ?? this.error,
    errorReason: clearError ? null : errorReason ?? this.errorReason,
    conflictingHostId: clearConflict
        ? null
        : conflictingHostId ?? this.conflictingHostId,
  );
}

/// Complete daemon-independent state consumed by the app shell.
final class HostRegistryState {
  /// Creates registry state.
  const HostRegistryState({
    required this.settings,
    required this.profiles,
    required this.runtimes,
  });

  /// Device-local app settings.
  final AppSettings settings;

  /// Persisted remote daemon profiles.
  final List<RemoteDaemonProfile> profiles;

  /// Runtime state keyed by stable app host ID.
  final Map<String, HostRuntimeSnapshot> runtimes;

  /// Returns state with selected fields replaced.
  HostRegistryState copyWith({
    AppSettings? settings,
    List<RemoteDaemonProfile>? profiles,
    Map<String, HostRuntimeSnapshot>? runtimes,
  }) => HostRegistryState(
    settings: settings ?? this.settings,
    profiles: profiles ?? this.profiles,
    runtimes: runtimes ?? this.runtimes,
  );
}

/// Stable classification for failures before an API connection exists.
enum HostConnectionFailureKind {
  /// Invalid user-entered endpoint.
  invalidEndpoint,

  /// Bearer authentication was rejected.
  authentication,

  /// Daemon and client protocol versions differ.
  protocolMismatch,

  /// Retryable socket, DNS, or service availability failure.
  network,
}

/// Typed failure used by connection adapters and retry policy.
final class HostConnectionFailure implements Exception {
  /// Creates an invalid-endpoint failure.
  const HostConnectionFailure.invalidEndpoint(this.message, {this.reason})
    : kind = HostConnectionFailureKind.invalidEndpoint;

  /// Creates an authentication failure.
  const HostConnectionFailure.authentication(this.message, {this.reason})
    : kind = HostConnectionFailureKind.authentication;

  /// Creates a protocol mismatch failure.
  const HostConnectionFailure.protocolMismatch(this.message, {this.reason})
    : kind = HostConnectionFailureKind.protocolMismatch;

  /// Creates a retryable network failure.
  const HostConnectionFailure.network(this.message, {this.reason})
    : kind = HostConnectionFailureKind.network;

  /// Failure category.
  final HostConnectionFailureKind kind;

  /// Safe display message, used when [reason] is null.
  final String message;

  /// App-authored cause the UI localizes in place of [message].
  final HostFailureReason? reason;

  /// Whether automatic connection attempts may continue.
  bool get retryable => kind == HostConnectionFailureKind.network;

  @override
  String toString() => message;
}
