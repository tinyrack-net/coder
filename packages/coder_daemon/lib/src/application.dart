import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/agent_service.dart';
import 'package:coder_daemon/src/attachment_service.dart';
import 'package:coder_daemon/src/built_in_tools.dart';
import 'package:coder_daemon/src/commands.dart';
import 'package:coder_daemon/src/config.dart';
import 'package:coder_daemon/src/credential_store.dart';
import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/exec_session_service.dart';
import 'package:coder_daemon/src/file_index.dart';
import 'package:coder_daemon/src/git_workspace.dart';
import 'package:coder_daemon/src/mcp_config.dart';
import 'package:coder_daemon/src/mcp_resource_tools.dart';
import 'package:coder_daemon/src/mcp_service.dart';
import 'package:coder_daemon/src/mcp_transports.dart';
import 'package:coder_daemon/src/multi_agent.dart';
import 'package:coder_daemon/src/portable_terminal.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/project_settings.dart';
import 'package:coder_daemon/src/provider_adapters.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_daemon/src/provider_catalog.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/server.dart';
import 'package:coder_daemon/src/skills.dart';
import 'package:coder_daemon/src/terminal_service.dart';
import 'package:coder_daemon/src/workspace_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Raised when another daemon already holds the lock on a daemon home.
///
/// The daemon home is exclusive, so a second daemon over the same directory is
/// a lifecycle conflict rather than a filesystem fault. The operating system
/// only reports it as a lock error on `daemon.lock`, which reads as data
/// corruption to a user, so the cause is named here instead.
final class DaemonAlreadyRunningException implements Exception {
  /// Creates a conflict for the daemon home another daemon still owns.
  const DaemonAlreadyRunningException({
    required this.homeDirectory,
    required this.diagnostic,
  });

  /// Daemon home whose lock could not be taken.
  final String homeDirectory;

  /// Operating-system diagnostic kept for a bug report.
  final String diagnostic;

  @override
  String toString() =>
      'A daemon is already running on $homeDirectory ($diagnostic).';
}

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
    ProviderModelDiscovery? modelDiscovery,
    ProviderOAuthGateway? oauthGateway,
    ProviderCatalogMetadataSource? providerCatalogMetadataSource,
    WorkspacePathGateway workspacePaths = const IoWorkspacePathGateway(),
    GitWorkspaceGateway? git,
    ProjectSettingsStore projectSettings = const FileProjectSettingsStore(),
    WorktreeHookRunner worktreeHooks = const ShellWorktreeHookRunner(),
    GitignoreEnvironment? gitignoreEnvironment,
  }) async {
    final home = Directory(config.homeDirectory);
    await home.create(recursive: true);
    final lockFile = File(p.join(home.path, 'daemon.lock'));
    final lock = await lockFile.open(mode: FileMode.append);
    try {
      await lock.lock();
    } on FileSystemException catch (error) {
      // Every failure of this call is contention: the file is already open, so
      // the only thing left to refuse is the lock itself. Matching on errno
      // would mean tracking 33 on Windows, 11 on Linux, and 35 on macOS.
      await lock.close();
      throw DaemonAlreadyRunningException(
        homeDirectory: home.path,
        diagnostic: '$error',
      );
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
      // The whole vendor surface of this daemon: adding a vendor package
      // means adding its plugins and wire protocols to these two lists.
      final providerRegistry = ProviderRegistry(
        plugins: openAIFamilyPlugins(clock: clock, openAIOAuth: oauthGateway),
        wireProtocols: openAIWireProtocols(),
      );
      final providers = ProviderService(
        repository: database.providerDao,
        credentials: credentials,
        settings: database.settingsDao,
        environment: config.useEnvironmentCredentials
            ? Platform.environment
            : const <String, String>{},
        clock: clock,
        registry: providerRegistry,
        catalog: BuiltInProviderCatalog(
          clock: clock,
          registry: providerRegistry,
          metadataSource: providerCatalogMetadataSource,
        ),
        modelDiscovery: modelDiscovery,
        oauthRefresher: OAuthCredentialRefresher(registry: providerRegistry),
        fixedProvider: provider,
      );
      await providers.initialize();
      // A bare API key in daemon config has always meant the first vendor's
      // platform key; the composition root is where that convention lives.
      final apiKeyDefinition = providerRegistry.plugins.first.id;
      if (config.apiKey?.isNotEmpty == true &&
          await database.providerDao.getConnection(apiKeyDefinition) == null) {
        await providers.connectApiKey(apiKeyDefinition, config.apiKey!);
      }
      final providerAuth = ProviderAuthCoordinator(
        registry: providerRegistry,
        connector: providers,
        ids: ids,
      );
      final attachments = AttachmentService(
        repository: database.attachmentDao,
        blobs: NativeAttachmentBlobStore(p.join(home.path, 'attachments')),
        clock: clock,
        ids: ids,
      );
      await attachments.cleanupOrphans();
      // The composition root is the one place allowed to read the ambient
      // environment, which is how the search tools learn where the user's
      // global git excludes live without any of them reaching for it. A test
      // passes its own so it never inherits the running user's.
      final gitignore =
          gitignoreEnvironment ??
          GitignoreEnvironment.fromEnvironment(Platform.environment);
      final mcp = McpService(
        store: FileMcpConfigStore(config.configDirectory),
        credentials: credentials,
        transports: IoMcpTransportFactory(clientVersion: config.version),
        clock: clock,
        environment: config.useEnvironmentCredentials
            ? Platform.environment
            : const <String, String>{},
        clientVersion: config.version,
      );
      // Reads mcp.json only; every handshake runs in the background so one
      // unstartable server cannot hold up daemon boot.
      await mcp.initialize();
      // Assigned once the session service it drives exists; the registry reads
      // it per turn rather than capturing null here.
      MultiAgentService? multiAgent;
      final toolRegistry = builtInAgentToolRegistry(
        gitignoreEnvironment: gitignore,
        mcpResourceHostFor: (workspaceRoot) =>
            SessionMcpResourceHost(mcp, workspaceRoot),
        multiAgent: () => multiAgent,
      );
      final builtInCatalog = StaticAgentToolCatalog(toolRegistry.catalog);
      final agentDefinitions = AgentDefinitionService(
        store: FileAgentDefinitionStore(config.configDirectory),
        tools: CompositeAgentToolCatalog(<AgentToolCatalog>[
          builtInCatalog,
          mcp,
        ]),
        alwaysOnToolIds: toolRegistry.alwaysOnIds,
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
      final commands = CommandService(
        globalSources: <CommandFiles>[
          // A daemon without a resolved user home stays away from any
          // `~/.agents` tree instead of guessing one.
          if (userHome != null)
            NativeCommandFiles(
              p.join(userHome, '.agents', 'commands'),
              source: AgentCommandSource.userHome,
            ),
          NativeCommandFiles(
            p.join(config.configDirectory, 'commands'),
            source: AgentCommandSource.config,
          ),
        ],
        projectFiles: (root) => NativeCommandFiles(
          p.join(root, '.agents', 'commands'),
          source: AgentCommandSource.project,
        ),
      );
      await commands.initialize();
      final execSessions = ExecSessionService(
        gateway: const PtyworldTerminalGateway(),
        pipes: const IoPipeGateway(),
        ids: ids,
        clock: clock,
      );
      final execSweep = Timer.periodic(
        const Duration(minutes: 5),
        (_) => execSessions.sweepIdle(),
      );
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
        attachments: attachments,
        toolRegistry: toolRegistry,
        externalTools: _McpToolSource(mcp),
        execHostFor: (id) => SessionExecHost(execSessions, id),
        skills: skills,
        settings: database.settingsDao,
      );
      multiAgent = MultiAgentService(
        sessions: database.sessionDao,
        mailbox: database.agentMailboxDao,
        timeline: database.timelineDao,
        getDefinition: agentDefinitions.get,
        validateModel: providers.validateAgentModel,
        fallbackModel: providers.fallbackModel,
        events: events.add,
        clock: clock,
        ids: ids,
      )..runtime = service;
      service.multiAgent = multiAgent;
      final fileIndex = GitAwareFileIndexGateway(
        const IoCommandRunner(),
        clock,
      );
      final workspaceService = WorkspaceService(
        database.workspaceDao,
        database.worktreeDao,
        database.sessionDao,
        workspacePaths,
        git ?? const ProcessGitWorkspaceGateway(IoCommandRunner()),
        clock,
        p.join(home.path, 'worktrees'),
        fileIndex,
        projectSettings,
        worktreeHooks,
      );
      // Sessions that belong to no project run here, so the home checkout has
      // to exist before the first client connects.
      await workspaceService.provisionHome(config.userHomeDirectory);
      final terminals = TerminalService(
        gateway: const PtyworldTerminalGateway(),
        worktreePath: (worktreeId) async {
          final worktree = await database.worktreeDao.getById(worktreeId);
          if (worktree == null || worktree.archivedAt != null) {
            throw const FormatException('Active worktree not found.');
          }
          return worktree.path;
        },
        shellFor: (worktreeId) async {
          final worktree = await database.worktreeDao.getById(worktreeId);
          if (worktree == null || worktree.archivedAt != null) {
            throw const FormatException('Active worktree not found.');
          }
          final workspace = await database.workspaceDao.getById(
            worktree.workspaceId,
          );
          if (workspace == null) {
            throw const FormatException('Workspace not found.');
          }
          final project = await projectSettings.load(workspace.rootPath);
          if (project.shell case final shell?) return shell;
          final stored = await database.settingsDao.getValue('terminal.shell');
          if (stored != null) {
            return ShellSpecDto.fromJson(
              Map<String, dynamic>.from(jsonDecode(stored) as Map),
            );
          }
          if (Platform.isWindows) {
            return const ShellSpecDto(executable: 'powershell.exe');
          }
          return ShellSpecDto(
            executable: Platform.environment['SHELL'] ?? '/bin/sh',
            arguments: const <String>['-l'],
          );
        },
      );
      final info = ServerInfoDto(
        serverId: serverId,
        version: config.version,
        protocolVersion: coderProtocolVersion,
        homeDirectory: config.osHomeDirectory,
        features: <String, bool>{
          'timelineCatchup': true,
          'approvals': true,
          'embeddedDaemon': true,
          'providerCatalog': true,
          'agentDefinitions': true,
          'multiAgent': true,
          'mcp': true,
          'skills': true,
          'attachments': true,
          'terminals': true,
        },
      );
      final rpc = DaemonRpcServer(
        workspaces: workspaceService,
        sessionRepository: database.sessionDao,
        timeline: database.timelineDao,
        agents: service,
        attachments: attachments,
        agentDefinitions: agentDefinitions,
        mcp: mcp,
        worktrees: database.worktreeDao,
        skills: skills,
        commands: commands,
        providers: providers,
        providerAuth: providerAuth,
        terminals: terminals,
        settings: database.settingsDao,
        clock: clock,
        serverInfo: info,
        token: token,
        events: events.stream,
        allowedOrigins: config.allowedOrigins,
      );
      final http = await shelf_io.serve(
        rpc.call,
        config.host,
        config.port,
      );
      final presentationHost = config.host == '0.0.0.0'
          ? '127.0.0.1'
          : config.host;
      final attachmentCleanup = Timer.periodic(
        const Duration(hours: 1),
        (_) => unawaited(attachments.cleanupOrphans()),
      );
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
        mcp: mcp,
        skills: skills,
        lock: lock,
        attachmentCleanup: attachmentCleanup,
        execSweep: execSweep,
        execSessions: execSessions,
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
    required this._mcp,
    required this._skills,
    required this._lock,
    required this._attachmentCleanup,
    required this._execSweep,
    required this._execSessions,
  }) : _serverId = serverIdValue;

  final Uri _endpoint;
  final String _serverId;
  final String _token;
  final HttpServer _http;
  final DaemonRpcServer _rpc;
  final CoderDatabase _database;
  final StreamController<WireEnvelope> _events;
  final AgentDefinitionService _agentDefinitions;
  final McpService _mcp;
  final SkillService _skills;
  final RandomAccessFile _lock;
  final Timer _attachmentCleanup;
  final Timer _execSweep;
  final ExecSessionService _execSessions;
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
    _attachmentCleanup.cancel();
    _execSweep.cancel();
    await _execSessions.close();
    await _http.close(force: true);
    await _rpc.close();
    await _mcp.close();
    await _agentDefinitions.close();
    await _skills.close();
    await _events.close();
    await _database.close();
    await _lock.unlock();
    await _lock.close();
  }
}

/// Resolves MCP tools for one turn, and marks the worktree as in use.
///
/// Starting a turn is what marks a worktree as in use: its project servers
/// connect in the background and join from the next turn, and worktrees nothing
/// has touched lately are released.
final class _McpToolSource implements ExternalToolSource {
  const _McpToolSource(this._mcp);

  final McpService _mcp;

  @override
  AgentTool? Function(String id) lookupFor(String workspaceRoot) {
    unawaited(_mcp.ensureProject(workspaceRoot));
    _mcp.releaseIdleProjects();
    // Withhold MCP tools only once there are enough of them to crowd the
    // context; below the threshold nothing changes for the user.
    final exposure =
        _mcp.tools(workspaceRoot: workspaceRoot).length > mcpDeferralThreshold
        ? ToolExposure.deferred
        : ToolExposure.advertised;
    return (id) =>
        _mcp.tool(id, workspaceRoot: workspaceRoot, exposure: exposure);
  }
}
