import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_daemon/src/config.dart';
import 'package:coder_daemon/src/credential_store.dart';
import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/git_workspace.dart';
import 'package:coder_daemon/src/openai_oauth_gateway.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/provider_catalog.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/server.dart';
import 'package:coder_daemon/src/workspace_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Public API exposed by this library.
abstract interface class DaemonHandle {
  /// The ready public API member.
  Future<void> get ready;

  /// The boundEndpoint public API member.
  Uri get boundEndpoint;

  /// The serverId public API member.
  String get serverId;

  /// The bearerToken public API member.
  String get bearerToken;

  /// Secret granting provider administration to trusted local clients.
  String get adminToken;

  /// The stop public API member.
  Future<void> stop();
}

/// Public API exposed by this library.
abstract final class DaemonApplication {
  /// The start public API member.
  static Future<DaemonHandle> start(
    DaemonConfig config, {
    ModelProvider? provider,
    Clock clock = const SystemClock(),
    IdGenerator ids = const UuidIdGenerator(),
    ProviderModelDiscovery modelDiscovery = const DioProviderModelDiscovery(),
    ModelProviderFactory providerFactory =
        const OpenAICompatibleProviderFactory(),
    ProviderOAuthGateway? oauthGateway,
    WorkspacePathGateway workspacePaths = const IoWorkspacePathGateway(),
    GitWorkspaceGateway? git,
  }) async {
    final home = Directory(config.homeDirectory);
    await home.create(recursive: true);
    final lockFile = File(p.join(home.path, 'daemon.lock'));
    final lock = await lockFile.open(mode: FileMode.append);
    try {
      await lock.lock();
    } catch (_) {
      await lock.close();
      rethrow;
    }

    final database = CoderDatabase(
      p.join(home.path, 'coder.sqlite'),
      clock: clock,
    );
    try {
      await database.runtimeDao.recoverInterruptedRuns();
      var serverId = await database.settingsDao.getValue('server.id');
      if (serverId == null) {
        serverId = ids.generate();
        await database.settingsDao.setValue('server.id', serverId);
      }
      final credentials = CredentialStore(config.configDirectory);
      await credentials.load();
      final token =
          config.bearerToken ??
          credentials.bearerToken ??
          generateBearerToken();
      final adminToken =
          config.adminToken ?? credentials.adminToken ?? generateBearerToken();
      if (utf8.encode(token).length < 32) {
        throw ArgumentError(
          'Bearer token must contain at least 256 bits (32 bytes).',
        );
      }
      if (utf8.encode(adminToken).length < 32) {
        throw ArgumentError(
          'Admin token must contain at least 256 bits (32 bytes).',
        );
      }
      await database.settingsDao.setValue(
        'auth.tokenHash',
        sha256.convert(utf8.encode(token)).toString(),
      );
      if (credentials.bearerToken != token ||
          credentials.adminToken != adminToken) {
        await credentials.setDaemonTokens(
          bearerToken: token,
          adminToken: adminToken,
        );
      }
      final events = StreamController<WireEnvelope>.broadcast(sync: true);
      final effectiveOAuthGateway =
          oauthGateway ?? OpenAIOAuthGateway(clock: clock);
      final providers = ProviderService(
        repository: database.providerDao,
        credentials: credentials,
        environment: config.useEnvironmentCredentials
            ? Platform.environment
            : const <String, String>{},
        clock: clock,
        modelDiscovery: modelDiscovery,
        providerFactory: providerFactory,
        catalog: BuiltInProviderCatalog(clock: clock),
        oauthRefresher: OAuthCredentialRefresher(
          gateway: effectiveOAuthGateway,
        ),
        fixedProvider: provider,
      );
      await providers.initialize();
      if (config.apiKey?.isNotEmpty == true &&
          await database.providerDao.getConnection('openai') == null) {
        await providers.connectApiKey('openai', config.apiKey!);
      }
      final providerAuth = ProviderAuthCoordinator(
        gateway: effectiveOAuthGateway,
        connector: providers,
        ids: ids,
      );
      final service = AgentService(
        agents: database.agentDao,
        worktrees: database.worktreeDao,
        timeline: database.timelineDao,
        providers: providers,
        events: events.add,
        safetyIdentifier: sha256.convert(utf8.encode(serverId)).toString(),
        clock: clock,
        ids: ids,
        toolsFactory: () => <AgentTool>[
          ListDirectoryTool(),
          ReadFileTool(),
          SearchTextTool(),
          ApplyPatchTool(),
          RunCommandTool(),
        ],
      );
      final workspaceService = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.agentDao,
        workspacePaths,
        git ?? const ProcessGitWorkspaceGateway(IoCommandRunner()),
        clock,
        p.join(home.path, 'worktrees'),
      );
      final info = ServerInfoDto(
        serverId: serverId,
        version: config.version,
        protocolVersion: coderProtocolVersion,
        features: <String, bool>{
          'timelineCatchup': true,
          'approvals': true,
          'embeddedDaemon': true,
          'providerCatalog': true,
        },
      );
      final rpc = DaemonRpcServer(
        workspaces: workspaceService,
        agentRepository: database.agentDao,
        timeline: database.timelineDao,
        agents: service,
        providers: providers,
        providerAuth: providerAuth,
        clock: clock,
        serverInfo: info,
        token: token,
        adminToken: adminToken,
        events: events.stream,
      );
      final http = await shelf_io.serve(
        rpc.call,
        config.host,
        config.port,
      );
      final presentationHost = config.host == '0.0.0.0'
          ? '127.0.0.1'
          : config.host;
      return _LocalDaemonHandle(
        endpoint: Uri(
          scheme: 'ws',
          host: presentationHost,
          port: http.port,
          path: '/ws',
        ),
        serverIdValue: serverId,
        token: token,
        adminTokenValue: adminToken,
        http: http,
        rpc: rpc,
        database: database,
        events: events,
        lock: lock,
      );
    } catch (_) {
      await database.close();
      await lock.unlock();
      await lock.close();
      rethrow;
    }
  }
}

class _LocalDaemonHandle implements DaemonHandle {
  _LocalDaemonHandle({
    required this._endpoint,
    required String serverIdValue,
    required this._token,
    required String adminTokenValue,
    required this._http,
    required this._rpc,
    required this._database,
    required this._events,
    required this._lock,
  }) : _serverId = serverIdValue,
       _adminToken = adminTokenValue;

  final Uri _endpoint;
  final String _serverId;
  final String _token;
  final String _adminToken;
  final HttpServer _http;
  final DaemonRpcServer _rpc;
  final CoderDatabase _database;
  final StreamController<WireEnvelope> _events;
  final RandomAccessFile _lock;
  bool _stopped = false;

  @override
  Uri get boundEndpoint => _endpoint;
  @override
  String get serverId => _serverId;
  @override
  String get bearerToken => _token;
  @override
  String get adminToken => _adminToken;
  @override
  Future<void> get ready => Future<void>.value();

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _http.close(force: true);
    await _rpc.close();
    await _events.close();
    await _database.close();
    await _lock.unlock();
    await _lock.close();
  }
}
