import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/bootstrap/config.dart';
import 'package:coder_daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:coder_daemon/src/features/agents/infrastructure/built_in_tools.dart';
import 'package:coder_daemon/src/features/agents/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/attachments/infrastructure/attachment_service.dart';
import 'package:coder_daemon/src/features/attachments/transport/http_transport.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_config.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_resource_tools.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_server_service.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_service.dart';
import 'package:coder_daemon/src/features/mcp/infrastructure/mcp_transports.dart';
import 'package:coder_daemon/src/features/mcp/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/prompts/infrastructure/commands.dart';
import 'package:coder_daemon/src/features/prompts/infrastructure/skills.dart';
import 'package:coder_daemon/src/features/prompts/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/credential_store.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/openai/openai.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_adapters.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_auth.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_catalog.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:coder_daemon/src/features/providers/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/agent_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/exec_session_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/lua_code_mode_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/multi_agent.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/session_interactions.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/session_settings.dart';
import 'package:coder_daemon/src/features/sessions/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/terminals/application/terminal_service.dart';
import 'package:coder_daemon/src/features/terminals/domain/terminal.dart';
import 'package:coder_daemon/src/features/terminals/infrastructure/portable_terminal.dart';
import 'package:coder_daemon/src/features/terminals/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/features/terminals/transport/terminal_mapper.dart';
import 'package:coder_daemon/src/features/workspaces/infrastructure/file_index.dart';
import 'package:coder_daemon/src/features/workspaces/infrastructure/git_workspace.dart';
import 'package:coder_daemon/src/features/workspaces/infrastructure/project_settings.dart';
import 'package:coder_daemon/src/features/workspaces/infrastructure/workspace_service.dart';
import 'package:coder_daemon/src/features/workspaces/transport/rpc_bindings.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/database.dart';
import 'package:coder_daemon/src/shared/ports/agent_protocol_mapping.dart';
import 'package:coder_daemon/src/shared/ports/daemon_ports.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_daemon/src/transport/rpc/rpc_dispatch.dart';
import 'package:coder_daemon/src/transport/rpc/server.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:crypto/crypto.dart';
import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;
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

/// Typed host ports that customize daemon composition without exposing
/// infrastructure adapters or feature services.
final class DaemonHostOptions {
  /// Creates optional host overrides.
  const DaemonHostOptions({
    this.provider,
    this.clock,
    this.ids,
    this.modelDiscovery,
    this.oauthGateway,
    this.providerCatalogMetadataSource,
    this.workspacePaths,
    this.git,
    this.projectSettings,
    this.worktreeHooks,
    this.gitignoreEnvironment,
  });

  /// Fixed provider used by deterministic embedded/test hosts.
  final ModelProvider? provider;

  /// Host clock.
  final Clock? clock;

  /// Host identifier generator.
  final IdGenerator? ids;

  /// Provider model discovery port.
  final ProviderModelDiscovery? modelDiscovery;

  /// Provider authorization port.
  final ProviderOAuthGateway? oauthGateway;

  /// Provider catalog metadata port.
  final ProviderCatalogMetadataSource? providerCatalogMetadataSource;

  /// Workspace path access port.
  final WorkspacePathGateway? workspacePaths;

  /// Git workspace port.
  final GitWorkspaceGateway? git;

  /// Project-settings persistence port.
  final ProjectSettingsStore? projectSettings;

  /// Worktree hook execution port.
  final WorktreeHookRunner? worktreeHooks;

  /// Gitignore environment supplied to search tools.
  final GitignoreEnvironment? gitignoreEnvironment;
}

/// Public API exposed by this library.
abstract final class DaemonApplication {
  /// The start public API member.
  static Future<DaemonHandle> start(
    DaemonConfig config, {
    DaemonHostOptions options = const DaemonHostOptions(),
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
    final effectiveProvider = options.provider ?? provider;
    final effectiveClock = options.clock ?? clock;
    final effectiveIds = options.ids ?? ids;
    final effectiveModelDiscovery = options.modelDiscovery ?? modelDiscovery;
    final effectiveOAuthGateway = options.oauthGateway ?? oauthGateway;
    final effectiveCatalogMetadataSource =
        options.providerCatalogMetadataSource ?? providerCatalogMetadataSource;
    final effectiveWorkspacePaths = options.workspacePaths ?? workspacePaths;
    final effectiveGit = options.git ?? git;
    final effectiveProjectSettings = options.projectSettings ?? projectSettings;
    final effectiveWorktreeHooks = options.worktreeHooks ?? worktreeHooks;
    final effectiveGitignoreEnvironment =
        options.gitignoreEnvironment ?? gitignoreEnvironment;
    final home = Directory(p.join(config.homeDirectory, 'v4'));
    final configDirectory = p.join(config.configDirectory, 'v4');
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
      clock: effectiveClock,
    );
    try {
      await database.runtimeDao.recoverInterruptedRuns();
      var serverId = await database.settingsDao.getValue('server.id');
      if (serverId == null) {
        serverId = effectiveIds.generate();
        await database.settingsDao.setValue('server.id', serverId);
      }
      final credentials = CredentialStore(configDirectory);
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
      final events = StreamController<OutboundNotification>.broadcast(
        sync: true,
      );
      // The whole vendor surface of this daemon: adding a vendor package
      // means adding its plugins and wire protocols to these two lists.
      final providerRegistry = ProviderRegistry(
        plugins: openAIFamilyPlugins(
          clock: effectiveClock,
          openAIOAuth: effectiveOAuthGateway,
        ),
        wireProtocols: openAIWireProtocols(),
      );
      final providers = ProviderConnectionService(
        repository: database.providerDao,
        credentials: credentials,
        settings: database.settingsDao,
        environment: config.useEnvironmentCredentials
            ? Platform.environment
            : const <String, String>{},
        clock: effectiveClock,
        registry: providerRegistry,
        catalog: BuiltInProviderCatalog(
          clock: effectiveClock,
          registry: providerRegistry,
          metadataSource: effectiveCatalogMetadataSource,
        ),
        modelDiscovery: effectiveModelDiscovery,
        oauthRefresher: OAuthCredentialRefresher(registry: providerRegistry),
        fixedProvider: effectiveProvider,
      );
      await providers.initialize();
      final models = ProviderModelResolver(providers);
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
        ids: effectiveIds,
      );
      final attachments = AttachmentService(
        repository: database.attachmentDao,
        blobs: NativeAttachmentBlobStore(p.join(home.path, 'attachments')),
        clock: effectiveClock,
        ids: effectiveIds,
      );
      await attachments.cleanupOrphans();
      // The composition root is the one place allowed to read the ambient
      // environment, which is how the search tools learn where the user's
      // global git excludes live without any of them reaching for it. A test
      // passes its own so it never inherits the running user's.
      final gitignore =
          effectiveGitignoreEnvironment ??
          GitignoreEnvironment.fromEnvironment(Platform.environment);
      final mcp = McpRuntime(
        store: FileMcpConfigStore(configDirectory),
        credentials: credentials,
        transports: IoMcpTransportFactory(clientVersion: config.version),
        clock: effectiveClock,
        environment: config.useEnvironmentCredentials
            ? Platform.environment
            : const <String, String>{},
        clientVersion: config.version,
      );
      // Reads mcp.json only; every handshake runs in the background so one
      // unstartable server cannot hold up daemon boot.
      await mcp.initialize();
      final mcpServers = McpServerService(mcp);
      // Assigned once the session service it drives exists; the registry reads
      // it per turn rather than capturing null here.
      MultiAgentService? multiAgent;
      final toolRegistry = builtInAgentToolRegistry(
        gitignoreEnvironment: gitignore,
        mcpResourceHostFor: (workspaceRoot) =>
            SessionMcpResourceHost(mcp, workspaceRoot),
        multiAgent: () => multiAgent,
      );
      final builtInCatalog = StaticAgentToolCatalog(
        toolRegistry.catalog.map(protocolToolDefinition).toList(),
      );
      final agentDefinitions = AgentDefinitionService(
        store: FileAgentDefinitionStore(configDirectory),
        tools: CompositeAgentToolCatalog(<AgentToolCatalog>[
          builtInCatalog,
          mcp,
        ]),
        alwaysOnToolIds: toolRegistry.alwaysOnIds,
      );
      await agentDefinitions.initialize();
      final userHome = config.userHomeDirectory;
      final skills = SkillCatalogService(
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
              p.join(configDirectory, 'skills'),
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
            p.join(configDirectory, 'commands'),
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
        ids: effectiveIds,
        clock: effectiveClock,
      );
      final execSweep = Timer.periodic(
        const Duration(minutes: 5),
        (_) => execSessions.sweepIdle(),
      );
      final luaCodeMode = LuaCodeModeService(
        lua.LuaToolRuntime<ConversationAttachment>(
          host: discoverLuaHostCommand(sourceRoot: Directory.current.path),
          processLauncher: const lua.IoLuaHostProcessLauncher(),
          clock: _CoderLuaClock(effectiveClock),
          ids: _CoderLuaIds(effectiveIds),
        ),
      );
      final luaSweep = Timer.periodic(
        const Duration(minutes: 5),
        (_) => luaCodeMode.sweep(),
      );
      final sessionInteractions = SessionInteractionCoordinator(
        timeline: database.timelineDao,
        events: events.add,
        ids: effectiveIds,
        clock: effectiveClock,
      );
      final service = SessionTurnCoordinator(
        sessions: database.sessionDao,
        definitions: agentDefinitions,
        worktrees: database.worktreeDao,
        timeline: database.timelineDao,
        models: models,
        events: events.add,
        safetyIdentifier: sha256.convert(utf8.encode(serverId)).toString(),
        clock: effectiveClock,
        attachments: attachments,
        toolRegistry: toolRegistry,
        externalTools: _McpToolSource(mcp),
        execHostFor: (id) => SessionExecHost(execSessions, id),
        luaHostFor: (id, workingDirectory) =>
            SessionLuaCodeModeHost(luaCodeMode, id, workingDirectory),
        skills: skills,
        settings: database.settingsDao,
        interactions: sessionInteractions,
      );
      multiAgent = MultiAgentService(
        sessions: database.sessionDao,
        mailbox: database.agentMailboxDao,
        timeline: database.timelineDao,
        getDefinition: agentDefinitions.get,
        validateModel: models.validateAgentModel,
        fallbackModel: models.fallbackModel,
        events: events.add,
        clock: effectiveClock,
        ids: effectiveIds,
      )..runtime = service;
      service.multiAgent = multiAgent;
      final sessionSettings = SessionSettingsService(
        sessions: database.sessionDao,
        models: models,
        hasActiveTurn: service.hasActiveTurn,
        events: events.add,
      );
      final fileIndex = GitAwareFileIndexGateway(
        const IoCommandRunner(),
        effectiveClock,
      );
      final workspaceOperations = WorkspaceOperations(
        database.workspaceDao,
        database.worktreeDao,
        database.sessionDao,
        effectiveWorkspacePaths,
        effectiveGit ?? const ProcessGitWorkspaceGateway(IoCommandRunner()),
        effectiveClock,
        p.join(home.path, 'worktrees'),
        fileIndex,
        effectiveProjectSettings,
        effectiveWorktreeHooks,
      );
      // Sessions that belong to no project run here, so the home checkout has
      // to exist before the first client connects.
      final workspaceCatalog = WorkspaceCatalogService(workspaceOperations);
      final worktreeLifecycle = WorktreeLifecycleService(workspaceOperations);
      await workspaceCatalog.provisionHome(config.userHomeDirectory);
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
          final project = await effectiveProjectSettings.load(
            workspace.rootPath,
          );
          if (project.shell case final shell?) {
            return TerminalShell(
              executable: shell.executable,
              arguments: shell.arguments,
            );
          }
          final stored = await database.settingsDao.getValue('terminal.shell');
          if (stored != null) {
            final shell = ShellSpecDto.fromJson(
              Map<String, dynamic>.from(jsonDecode(stored) as Map),
            );
            return TerminalShell(
              executable: shell.executable,
              arguments: shell.arguments,
            );
          }
          if (Platform.isWindows) {
            return const TerminalShell(executable: 'powershell.exe');
          }
          return TerminalShell(
            executable: Platform.environment['SHELL'] ?? '/bin/sh',
            arguments: const <String>['-l'],
          );
        },
      );
      final info = ServerInfoDto(
        serverId: serverId,
        version: config.version,
        protocolVersion: coderProtocolMajor,
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
      final notificationSubscriptions = <StreamSubscription<Object?>>[
        providerAuth.events.listen((attempt) {
          events.add(
            OutboundNotification(providersAuthUpdatedNotification, attempt),
          );
        }),
        agentDefinitions.changes.listen((_) {
          events.add(
            OutboundNotification(
              agentsChangedNotification,
              const EmptyResultDto(),
            ),
          );
        }),
        mcp.changes.listen((_) {
          events.add(
            OutboundNotification(
              mcpChangedNotification,
              const EmptyResultDto(),
            ),
          );
        }),
        skills.changes.listen((_) {
          events.add(
            OutboundNotification(
              promptsSkillsChangedNotification,
              const EmptyResultDto(),
            ),
          );
        }),
        commands.changes.listen((_) {
          events.add(
            OutboundNotification(
              promptsCommandsChangedNotification,
              const EmptyResultDto(),
            ),
          );
        }),
        terminals.events.listen((event) {
          switch (event) {
            case final TerminalOutput output:
              events.add(
                OutboundNotification(
                  terminalsOutputNotification,
                  terminalOutputToDto(output),
                ),
              );
            case final Terminal terminal:
              events.add(
                OutboundNotification(
                  terminalsUpdatedNotification,
                  terminalToDto(terminal),
                ),
              );
          }
        }),
      ];
      final bindings = RpcBindingRegistry(
        <RpcBindingDescriptor>[
          ...workspaceRpcBindings(
            workspaces: workspaceCatalog,
            worktrees: worktreeLifecycle,
          ),
          ...agentRpcBindings(
            definitions: agentDefinitions,
            worktrees: database.worktreeDao,
            settings: database.settingsDao,
          ),
          ...promptRpcBindings(
            skills: skills,
            commands: commands,
            workspaces: workspaceCatalog,
          ),
          ...providerRpcBindings(
            providers: providers,
            auth: providerAuth,
            agentDefinitions: agentDefinitions,
          ),
          ...mcpRpcBindings(
            runtime: mcp,
            servers: mcpServers,
            worktrees: database.worktreeDao,
          ),
          ...sessionRpcBindings(
            sessions: database.sessionDao,
            timeline: database.timelineDao,
            turns: service,
            settings: sessionSettings,
            interactions: sessionInteractions,
            agentDefinitions: agentDefinitions,
            models: models,
            clock: effectiveClock,
          ),
          ...terminalRpcBindings(
            terminals: terminals,
            settings: database.settingsDao,
          ),
        ],
        procedures: daemonRpcProcedures,
      );
      final rpc = DaemonRpcServer(
        bindings: bindings,
        attachments: AttachmentHttpTransport(attachments),
        serverInfo: info,
        token: token,
        events: events.stream,
        allowedOrigins: config.allowedOrigins,
      );
      final http = await shelf_io.serve(rpc.call, config.host, config.port);
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
          path: '/v4/ws',
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
        luaSweep: luaSweep,
        luaCodeMode: luaCodeMode,
        providerAuth: providerAuth,
        terminals: terminals,
        notificationSubscriptions: notificationSubscriptions,
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
    required this._luaSweep,
    required this._luaCodeMode,
    required this._providerAuth,
    required this._terminals,
    required this._notificationSubscriptions,
  }) : _serverId = serverIdValue;

  final Uri _endpoint;
  final String _serverId;
  final String _token;
  final HttpServer _http;
  final DaemonRpcServer _rpc;
  final CoderDatabase _database;
  final StreamController<OutboundNotification> _events;
  final AgentDefinitionService _agentDefinitions;
  final McpRuntime _mcp;
  final SkillCatalogService _skills;
  final RandomAccessFile _lock;
  final Timer _attachmentCleanup;
  final Timer _execSweep;
  final ExecSessionService _execSessions;
  final Timer _luaSweep;
  final LuaCodeModeService _luaCodeMode;
  final ProviderAuthCoordinator _providerAuth;
  final TerminalService _terminals;
  final List<StreamSubscription<Object?>> _notificationSubscriptions;
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
    _luaSweep.cancel();
    await _execSessions.close();
    await _luaCodeMode.close();
    for (final subscription in _notificationSubscriptions) {
      await subscription.cancel();
    }
    await _http.close(force: true);
    await _rpc.close();
    await _terminals.close();
    await _providerAuth.close();
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

  final McpRuntime _mcp;

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

final class _CoderLuaClock implements lua.LuaClock {
  const _CoderLuaClock(this._clock);

  final Clock _clock;

  @override
  DateTime nowUtc() => _clock.nowUtc();
}

final class _CoderLuaIds implements lua.LuaIdGenerator {
  const _CoderLuaIds(this._ids);

  final IdGenerator _ids;

  @override
  String generate() => _ids.generate();
}
