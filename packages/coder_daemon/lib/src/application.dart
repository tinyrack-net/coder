import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_daemon/src/config.dart';
import 'package:coder_daemon/src/credential_store.dart';
import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/git_workspace.dart';
import 'package:coder_daemon/src/openai_oauth_gateway.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/project_settings.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/provider_catalog.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/server.dart';
import 'package:coder_daemon/src/skills.dart';
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
    ProjectSettingsStore projectSettings = const FileProjectSettingsStore(),
    WorktreeHookRunner worktreeHooks = const ShellWorktreeHookRunner(),
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
      if (utf8.encode(token).length < 32) {
        throw ArgumentError(
          'Bearer token must contain at least 256 bits (32 bytes).',
        );
      }
      await database.settingsDao.setValue(
        'auth.tokenHash',
        sha256.convert(utf8.encode(token)).toString(),
      );
      if (credentials.bearerToken != token) {
        await credentials.setDaemonToken(token);
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
      final builtInTools = <AgentTool>[
        ListDirectoryTool(),
        ReadFileTool(),
        SearchTextTool(),
        ApplyPatchTool(),
        RunCommandTool(),
      ];
      final toolById = <String, AgentTool>{
        for (final tool in builtInTools) tool.name: tool,
      };
      final agentDefinitions = AgentDefinitionService(
        store: FileAgentDefinitionStore(config.configDirectory),
        tools: builtInTools.map(
          (tool) => AgentToolDefinitionDto(
            id: tool.name,
            name: tool.name,
            description: tool.description,
            risk: tool.risk,
          ),
        ),
      );
      await agentDefinitions.initialize();
      final userHome = config.userHomeDirectory;
      final skills = SkillService(
        store: FileSkillStore(
          roots: <SkillFiles>[
            // A daemon without a resolved user home stays away from any
            // `~/.agents` tree instead of guessing one.
            if (userHome != null)
              NativeSkillFiles(
                p.join(userHome, '.agents', 'skills'),
                source: SkillSource.userHome,
              ),
            NativeSkillFiles(
              p.join(config.configDirectory, 'skills'),
              source: SkillSource.config,
              createIfMissing: true,
            ),
          ],
          settings: database.settingsDao,
        ),
      );
      await skills.initialize();
      final service = SessionService(
        sessions: database.sessionDao,
        definitions: agentDefinitions,
        worktrees: database.worktreeDao,
        timeline: database.timelineDao,
        providers: providers,
        events: events.add,
        safetyIdentifier: sha256.convert(utf8.encode(serverId)).toString(),
        clock: clock,
        ids: ids,
        toolsFactory: (ids) =>
            ids.map((id) => toolById[id]).whereType<AgentTool>(),
        skills: skills,
      );
      final workspaceService = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.sessionDao,
        workspacePaths,
        git ?? const ProcessGitWorkspaceGateway(IoCommandRunner()),
        clock,
        p.join(home.path, 'worktrees'),
        projectSettings,
        worktreeHooks,
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
          'agentDefinitions': true,
          'subagents': true,
          'skills': true,
        },
      );
      final rpc = DaemonRpcServer(
        workspaces: workspaceService,
        sessionRepository: database.sessionDao,
        timeline: database.timelineDao,
        agents: service,
        agentDefinitions: agentDefinitions,
        skills: skills,
        providers: providers,
        providerAuth: providerAuth,
        clock: clock,
        serverInfo: info,
        token: token,
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
        http: http,
        rpc: rpc,
        database: database,
        events: events,
        agentDefinitions: agentDefinitions,
        skills: skills,
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
    required this._http,
    required this._rpc,
    required this._database,
    required this._events,
    required this._agentDefinitions,
    required this._skills,
    required this._lock,
  }) : _serverId = serverIdValue;

  final Uri _endpoint;
  final String _serverId;
  final String _token;
  final HttpServer _http;
  final DaemonRpcServer _rpc;
  final CoderDatabase _database;
  final StreamController<WireEnvelope> _events;
  final AgentDefinitionService _agentDefinitions;
  final SkillService _skills;
  final RandomAccessFile _lock;
  bool _stopped = false;

  @override
  Uri get boundEndpoint => _endpoint;
  @override
  String get serverId => _serverId;
  @override
  String get bearerToken => _token;
  @override
  Future<void> get ready => Future<void>.value();

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _http.close(force: true);
    await _rpc.close();
    await _agentDefinitions.close();
    await _skills.close();
    await _events.close();
    await _database.close();
    await _lock.unlock();
    await _lock.close();
  }
}
