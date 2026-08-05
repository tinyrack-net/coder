import 'dart:async';
import 'dart:math';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/mcp_config.dart';
import 'package:coder_daemon/src/mcp_tools.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_mcp/coder_mcp.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Schedules a callback, so backoff is testable without real time passing.
typedef McpTimerFactory = Timer Function(Duration delay, void Function() run);

Timer _realTimer(Duration delay, void Function() run) => Timer(delay, run);

/// A server that is not configured, not visible, or not connected yet.
///
/// An expected runtime condition rather than a programming error: the server
/// may still be starting, or may have dropped and be retrying.
final class McpServerUnavailable implements Exception {
  /// Creates an [McpServerUnavailable].
  const McpServerUnavailable(this.server);

  /// Configured id of the server that could not answer.
  final String server;

  @override
  String toString() => 'MCP server "$server" is not connected.';
}

/// One resource paired with the server that publishes it.
final class McpServerResource {
  /// Creates an [McpServerResource].
  const McpServerResource({required this.server, required this.descriptor});

  /// Configured id of the owning server.
  final String server;

  /// What the server published.
  final McpResourceDescriptor descriptor;
}

/// One resource template paired with the server that publishes it.
final class McpServerResourceTemplate {
  /// Creates an [McpServerResourceTemplate].
  const McpServerResourceTemplate({
    required this.server,
    required this.descriptor,
  });

  /// Configured id of the owning server.
  final String server;

  /// What the server published.
  final McpResourceTemplateDescriptor descriptor;
}

/// Connects to configured MCP servers and publishes their tools.
///
/// Connections are established in the background and never block a turn: only
/// servers that are already ready contribute tools, and a server that cannot
/// start degrades to a diagnostic rather than failing the daemon or the turn.
final class McpService implements AgentToolCatalog {
  /// Creates a service reading its servers from the daemon configuration.
  McpService({
    required this._store,
    required this._credentials,
    required this._transports,
    required this._clock,
    this.clientVersion = '0.0.0',
    this._environment = const <String, String>{},
    this._timerFactory = _realTimer,
    this.initialBackoff = const Duration(seconds: 1),
    this.maximumBackoff = const Duration(seconds: 60),
    this.projectIdleTimeout = const Duration(minutes: 30),
  });

  /// Version reported to servers during the handshake.
  final String clientVersion;

  /// Delay before the first reconnection attempt.
  final Duration initialBackoff;

  /// Upper bound on the reconnection delay.
  final Duration maximumBackoff;

  /// How long an unused worktree keeps its project servers running.
  final Duration projectIdleTimeout;

  final McpConfigStore _store;
  final CredentialRepository _credentials;
  final McpTransportFactory _transports;
  final Clock _clock;
  final Map<String, String> _environment;
  final McpTimerFactory _timerFactory;
  final Random _jitter = Random(0x6d6370);

  final Map<String, _Connection> _user = <String, _Connection>{};
  final Map<String, _Project> _projects = <String, _Project>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool _closed = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<AgentToolDefinitionDto> tools({String? workspaceRoot}) =>
      <AgentToolDefinitionDto>[
        for (final connection in _user.values) ...connection.toolDefinitions,
        if (workspaceRoot != null)
          for (final connection
              in _projects[workspaceRoot]?.connections.values ??
                  const <String, _Connection>{}.values)
            ...connection.toolDefinitions,
      ];

  /// Every server visible to [workspaceRoot], user scope first.
  ///
  /// Without a worktree only the user's own servers are reported: a caller
  /// that has not named a worktree has no business seeing what some other
  /// repository declares.
  List<McpServerStateDto> states({String? workspaceRoot}) =>
      <McpServerStateDto>[
        for (final connection in _user.values) connection.state,
        if (workspaceRoot != null)
          for (final connection
              in _projects[workspaceRoot]?.connections.values ??
                  const <String, _Connection>{}.values)
            connection.state,
      ];

  /// Ready servers visible to [workspaceRoot], user scope winning by id.
  ///
  /// A project server cannot shadow a user server of the same id, matching
  /// how [tool] resolves, so a repository cannot redirect a name the user
  /// configured for themselves.
  Map<String, _Connection> _visibleConnections({String? workspaceRoot}) {
    final visible = <String, _Connection>{};
    if (workspaceRoot != null) {
      final project = _projects[workspaceRoot]?.connections;
      if (project != null) visible.addAll(project);
    }
    visible.addAll(_user);
    return visible;
  }

  /// Resources published by [server], or by every visible server when null.
  ///
  /// Fan-out is sorted by server name so a model paging through the result
  /// sees a stable order across calls.
  List<McpServerResource> resources({String? server, String? workspaceRoot}) {
    final visible = _visibleConnections(workspaceRoot: workspaceRoot);
    final names = server == null
        ? (visible.keys.toList()..sort())
        : <String>[if (visible.containsKey(server)) server];
    return <McpServerResource>[
      for (final name in names)
        for (final descriptor in visible[name]!.readyResources)
          McpServerResource(server: name, descriptor: descriptor),
    ];
  }

  /// Resource templates published by [server], or by every visible server.
  List<McpServerResourceTemplate> resourceTemplates({
    String? server,
    String? workspaceRoot,
  }) {
    final visible = _visibleConnections(workspaceRoot: workspaceRoot);
    final names = server == null
        ? (visible.keys.toList()..sort())
        : <String>[if (visible.containsKey(server)) server];
    return <McpServerResourceTemplate>[
      for (final name in names)
        for (final descriptor in visible[name]!.readyResourceTemplates)
          McpServerResourceTemplate(server: name, descriptor: descriptor),
    ];
  }

  /// Whether [server] is visible to [workspaceRoot] and ready to answer.
  bool isReady(String server, {String? workspaceRoot}) =>
      _visibleConnections(
        workspaceRoot: workspaceRoot,
      )[server]?.status ==
      McpServerStatus.ready;

  /// Reads one resource from [server].
  Future<McpReadResourceResult> readResource({
    required String server,
    required String uri,
    String? workspaceRoot,
  }) async {
    final connection = _visibleConnections(
      workspaceRoot: workspaceRoot,
    )[server];
    final client = connection?.status == McpServerStatus.ready
        ? connection?.client
        : null;
    if (client == null) throw McpServerUnavailable(server);
    return client.readResource(uri);
  }

  /// Why the project configuration for [workspaceRoot] could not be read.
  String? projectError(String workspaceRoot) => _projects[workspaceRoot]?.error;

  /// Returns the tool behind [id], or null when its server is not ready.
  ///
  /// A user server always wins over a project server of the same id, so a
  /// repository cannot redirect a tool the user configured for themselves.
  AgentTool? tool(String id, {String? workspaceRoot}) {
    final parsed = parseMcpToolId(id);
    if (parsed == null) return null;
    final user = _user[parsed.server]?.toolNamed(id);
    if (user != null) return user;
    if (workspaceRoot == null) return null;
    return _projects[workspaceRoot]?.connections[parsed.server]?.toolNamed(id);
  }

  /// Connects the servers declared by [workspaceRoot], if any.
  ///
  /// Called when a turn resolves its worktree. Connections start in the
  /// background, so the first turn in a worktree runs with the user's servers
  /// and the project's join from the next one.
  Future<void> ensureProject(String workspaceRoot) async {
    if (_closed) return;
    final existing = _projects[workspaceRoot];
    if (existing != null) {
      existing.lastUsedAt = _clock.nowUtc();
      return;
    }
    final project = _Project(
      rootPath: workspaceRoot,
      lastUsedAt: _clock.nowUtc(),
    );
    _projects[workspaceRoot] = project;
    project.watch = _store
        .watch(McpConfigScope.project, rootPath: workspaceRoot)
        .listen((_) => unawaited(_reloadProject(workspaceRoot)));
    await _reloadProject(workspaceRoot);
  }

  /// Disposes project servers for worktrees no turn has touched recently.
  ///
  /// Without this, moving between repositories would accumulate stdio child
  /// processes for the lifetime of the daemon.
  void releaseIdleProjects() {
    final cutoff = _clock.nowUtc().subtract(projectIdleTimeout);
    for (final entry in _projects.entries.toList(growable: false)) {
      if (entry.value.lastUsedAt.isAfter(cutoff)) continue;
      _projects.remove(entry.key);
      unawaited(entry.value.dispose());
    }
    _announce();
  }

  /// Reads configuration and starts connecting in the background.
  ///
  /// Handshakes are deliberately not awaited: one server whose command is
  /// missing would otherwise hold up daemon startup indefinitely.
  Future<void> initialize() async {
    final document = await _store.load(McpConfigScope.user);
    _applyUserDocument(document);
  }

  /// Replaces the user-scoped servers and reconciles live connections.
  Future<void> saveUserServers(List<McpServerConfigDto> servers) async {
    await _store.save(
      McpConfigDocument(
        scope: McpConfigScope.user,
        sourcePath: _store.sourcePath(McpConfigScope.user),
        servers: servers,
      ),
    );
    _applyUserDocument(
      McpConfigDocument(
        scope: McpConfigScope.user,
        sourcePath: _store.sourcePath(McpConfigScope.user),
        servers: servers,
      ),
    );
  }

  /// Adds one user-scoped server and returns its state.
  Future<McpServerStateDto> addUserServer(McpServerConfigDto server) async {
    if (_user.containsKey(server.id)) {
      throw FormatException('mcp_server_exists: "${server.id}".');
    }
    await saveUserServers(<McpServerConfigDto>[
      for (final connection in _user.values) connection.config,
      server,
    ]);
    return _user[server.id]!.state;
  }

  /// Replaces one user-scoped server and returns its state.
  Future<McpServerStateDto> updateUserServer(McpServerConfigDto server) async {
    if (!_user.containsKey(server.id)) {
      throw FormatException('mcp_server_not_found: "${server.id}".');
    }
    await saveUserServers(<McpServerConfigDto>[
      for (final connection in _user.values)
        if (connection.config.id == server.id) server else connection.config,
    ]);
    return _user[server.id]!.state;
  }

  /// Removes one user-scoped server.
  Future<void> removeUserServer(String id) async {
    if (!_user.containsKey(id)) {
      throw FormatException('mcp_server_not_found: "$id".');
    }
    await saveUserServers(<McpServerConfigDto>[
      for (final connection in _user.values)
        if (connection.config.id != id) connection.config,
    ]);
  }

  /// Connects [server] once to report what it publishes, saving nothing.
  Future<McpServerStateDto> testServer(
    McpServerConfigDto server, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final probe = _Connection(
      config: server,
      sourcePath: _store.sourcePath(McpConfigScope.user),
      scope: McpConfigScope.user,
      service: this,
    );
    try {
      await probe.connectOnce().timeout(timeout);
    } on TimeoutException {
      probe
        ..status = McpServerStatus.failed
        ..error = 'the server did not answer within ${timeout.inSeconds}s';
    }
    final state = probe.state;
    await probe.dispose();
    return state;
  }

  /// Stores one secret an MCP configuration may reference.
  Future<void> setSecret(String key, String value) =>
      _credentials.setMcpSecret(key, value);

  /// Restarts one server immediately, resetting its backoff.
  void retry(String id) {
    final connection = _user[id];
    if (connection == null) return;
    connection.attempt = 0;
    unawaited(connection.reconnectNow());
  }

  /// Releases every connection and timer the service holds.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await Future.wait(<Future<void>>[
      ..._user.values.map((connection) => connection.dispose()),
      ..._projects.values.map((project) => project.dispose()),
    ]);
    _user.clear();
    _projects.clear();
    await _changes.close();
  }

  Future<void> _reloadProject(String workspaceRoot) async {
    final project = _projects[workspaceRoot];
    if (project == null || _closed) return;
    List<McpServerConfigDto> declared;
    try {
      final document = await _store.load(
        McpConfigScope.project,
        rootPath: workspaceRoot,
      );
      declared = document.servers;
      project
        ..sourcePath = document.sourcePath
        ..error = null;
    } on Object catch (failure) {
      // A repository with a broken .mcp.json still has to be workable, so the
      // failure is recorded against the worktree instead of thrown at a turn.
      project
        ..error = '$failure'
        ..sourcePath = _store.sourcePath(
          McpConfigScope.project,
          rootPath: workspaceRoot,
        );
      declared = const <McpServerConfigDto>[];
    }
    _applyProjectDocument(project, declared);
  }

  void _applyProjectDocument(
    _Project project,
    List<McpServerConfigDto> servers,
  ) {
    final desired = <String, McpServerConfigDto>{
      for (final server in servers) server.id: server,
    };
    for (final id in project.connections.keys.toList(growable: false)) {
      final wanted = desired[id];
      final existing = project.connections[id]!;
      final stillShadowed = _user.containsKey(id);
      if (wanted == null ||
          wanted != existing.config ||
          stillShadowed != existing.shadowed) {
        project.connections.remove(id);
        unawaited(existing.dispose());
      }
    }
    for (final server in servers) {
      if (project.connections.containsKey(server.id)) continue;
      final connection = _Connection(
        config: server,
        sourcePath: project.sourcePath,
        scope: McpConfigScope.project,
        service: this,
        // A repository may not take over an id the user already configured.
        shadowed: _user.containsKey(server.id),
      );
      project.connections[server.id] = connection;
      connection.start();
    }
    _announce();
  }

  void _applyUserDocument(McpConfigDocument document) {
    final desired = <String, McpServerConfigDto>{
      for (final server in document.servers) server.id: server,
    };
    // Reconcile rather than restart: a server whose configuration did not
    // change keeps its live connection and its already-published tools.
    for (final id in _user.keys.toList(growable: false)) {
      final wanted = desired[id];
      final existing = _user[id]!;
      if (wanted == null) {
        _user.remove(id);
        unawaited(existing.dispose());
      } else if (wanted != existing.config) {
        _user.remove(id);
        unawaited(existing.dispose());
      }
    }
    for (final server in document.servers) {
      if (_user.containsKey(server.id)) continue;
      final connection = _Connection(
        config: server,
        sourcePath: document.sourcePath,
        scope: document.scope,
        service: this,
      );
      _user[server.id] = connection;
      connection.start();
    }
    _announce();
  }

  void _announce() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Duration _backoffFor(int attempt) {
    final exponential = initialBackoff.inMilliseconds * (1 << min(attempt, 16));
    final capped = min(exponential, maximumBackoff.inMilliseconds);
    // ±20% jitter keeps a fleet of servers from retrying in lockstep.
    final spread = (capped * 0.2).round();
    final offset = spread == 0 ? 0 : _jitter.nextInt(spread * 2) - spread;
    return Duration(milliseconds: max(1, capped + offset));
  }

  McpTransportSpec _specFor(McpServerConfigDto config) {
    String resolve(String value) => resolveMcpSecrets(
      value,
      environment: _environment,
      secrets: _credentials.mcpSecrets,
    );

    if (config.transport == McpTransportKind.stdio) {
      return McpStdioSpec(
        command: config.command!,
        args: config.args,
        env: <String, String>{
          for (final entry in config.env.entries)
            entry.key: resolve(entry.value),
        },
        workingDirectory: config.cwd,
      );
    }
    return McpHttpSpec(
      url: Uri.parse(config.url!),
      headers: <String, String>{
        for (final entry in config.headers.entries)
          entry.key: resolve(entry.value),
      },
    );
  }
}

final class _Project {
  _Project({required this.rootPath, required this.lastUsedAt});

  final String rootPath;
  final Map<String, _Connection> connections = <String, _Connection>{};

  DateTime lastUsedAt;
  String sourcePath = '';
  String? error;
  StreamSubscription<void>? watch;

  Future<void> dispose() async {
    await watch?.cancel();
    watch = null;
    await Future.wait(
      connections.values.map((connection) => connection.dispose()),
    );
    connections.clear();
  }
}

final class _Connection {
  _Connection({
    required this.config,
    required this.sourcePath,
    required this.scope,
    required this.service,
    this.shadowed = false,
  });

  final McpServerConfigDto config;
  final String sourcePath;
  final McpConfigScope scope;
  final McpService service;

  /// Whether a user server of the same id already owns this name.
  final bool shadowed;

  final List<String> diagnostics = <String>[];

  McpClient? client;
  StreamSubscription<void>? _toolsChanged;
  StreamSubscription<void>? _resourcesChanged;
  StreamSubscription<String>? _diagnostics;
  Timer? _retryTimer;
  McpServerStatus status = McpServerStatus.disabled;
  String? error;
  DateTime? lastConnectedAt;
  DateTime? nextRetryAt;
  int attempt = 0;
  bool disposed = false;

  List<AgentToolDefinitionDto> get toolDefinitions {
    final connected = client;
    if (status != McpServerStatus.ready || connected == null) {
      return const <AgentToolDefinitionDto>[];
    }
    return <AgentToolDefinitionDto>[
      for (final descriptor in connected.tools)
        AgentToolDefinitionDto(
          id: mcpToolId(config.id, descriptor.name),
          name: mcpToolId(config.id, descriptor.name),
          description: descriptor.description ?? descriptor.name,
          risk: ToolRisk.dangerous,
        ),
    ];
  }

  McpServerStateDto get state => McpServerStateDto(
    config: config,
    status: status,
    scope: scope,
    sourcePath: sourcePath,
    shadowed: shadowed,
    protocolVersion: client?.identity?.protocolVersion,
    serverName: client?.identity?.name,
    serverVersion: client?.identity?.version,
    tools: <McpToolSummaryDto>[
      for (final descriptor in client?.tools ?? const <McpToolDescriptor>[])
        McpToolSummaryDto(
          toolId: mcpToolId(config.id, descriptor.name),
          name: descriptor.name,
          title: descriptor.title,
          description: descriptor.description ?? '',
        ),
    ],
    resources: <McpResourceSummaryDto>[
      for (final descriptor in readyResources)
        McpResourceSummaryDto(
          uri: descriptor.uri,
          name: descriptor.name,
          title: descriptor.title,
          description: descriptor.description,
          mimeType: descriptor.mimeType,
          sizeBytes: descriptor.sizeBytes,
        ),
    ],
    resourceTemplates: <McpResourceTemplateSummaryDto>[
      for (final descriptor in readyResourceTemplates)
        McpResourceTemplateSummaryDto(
          uriTemplate: descriptor.uriTemplate,
          name: descriptor.name,
          title: descriptor.title,
          description: descriptor.description,
          mimeType: descriptor.mimeType,
        ),
    ],
    error: error,
    diagnostics: List<String>.unmodifiable(diagnostics),
    lastConnectedAt: lastConnectedAt,
    nextRetryAt: nextRetryAt,
    attempt: attempt,
  );

  /// Resources this server published, empty until it is ready.
  List<McpResourceDescriptor> get readyResources =>
      status == McpServerStatus.ready
      ? client?.resources ?? const <McpResourceDescriptor>[]
      : const <McpResourceDescriptor>[];

  /// Resource templates this server published, empty until it is ready.
  List<McpResourceTemplateDescriptor> get readyResourceTemplates =>
      status == McpServerStatus.ready
      ? client?.resourceTemplates ?? const <McpResourceTemplateDescriptor>[]
      : const <McpResourceTemplateDescriptor>[];

  AgentTool? toolNamed(String id) {
    final connected = client;
    if (status != McpServerStatus.ready || connected == null) return null;
    for (final descriptor in connected.tools) {
      if (mcpToolId(config.id, descriptor.name) != id) continue;
      return McpAgentTool(
        serverId: config.id,
        descriptor: descriptor,
        lookup: (_) => client,
      );
    }
    return null;
  }

  void start() {
    if (shadowed || !config.enabled) {
      status = McpServerStatus.disabled;
      return;
    }
    status = McpServerStatus.connecting;
    unawaited(_connect());
  }

  Future<void> reconnectNow() async {
    _retryTimer?.cancel();
    nextRetryAt = null;
    await _releaseClient();
    start();
    service._announce();
  }

  /// Runs one connection attempt without scheduling a retry.
  ///
  /// Used by the unsaved-configuration probe, which reports the outcome once
  /// rather than living long enough to reconnect.
  Future<void> connectOnce() async {
    status = McpServerStatus.connecting;
    await _connect(retryOnFailure: false);
  }

  Future<void> _connect({bool retryOnFailure = true}) async {
    if (disposed) return;
    try {
      final transport = service._transports.create(service._specFor(config));
      final connected = McpClient(
        transport: transport,
        clientVersion: service.clientVersion,
      );
      client = connected;
      _diagnostics = connected.diagnostics.listen(_record);
      await connected.connect();
      if (disposed) {
        await connected.close();
        return;
      }
      _toolsChanged = connected.toolsChanged.listen((_) {
        service._announce();
      });
      _resourcesChanged = connected.resourcesChanged.listen((_) {
        service._announce();
      });
      unawaited(connected.closed.then((_) => _handleLost()));
      status = McpServerStatus.ready;
      error = null;
      attempt = 0;
      lastConnectedAt = service._clock.nowUtc();
    } on Object catch (failure) {
      if (disposed) return;
      error = '$failure';
      _record('$failure');
      status = McpServerStatus.failed;
      await _releaseClient();
      if (retryOnFailure) _scheduleRetry();
    }
    service._announce();
  }

  void _handleLost() {
    if (disposed || status != McpServerStatus.ready) return;
    status = McpServerStatus.failed;
    error ??= 'the connection ended';
    _scheduleRetry();
    service._announce();
  }

  void _scheduleRetry() {
    if (disposed) return;
    final delay = service._backoffFor(attempt);
    attempt += 1;
    nextRetryAt = service._clock.nowUtc().add(delay);
    _retryTimer?.cancel();
    _retryTimer = service._timerFactory(delay, () {
      if (disposed) return;
      nextRetryAt = null;
      status = McpServerStatus.connecting;
      unawaited(_connect());
    });
  }

  void _record(String note) {
    diagnostics.add(note);
    // Bounded so a chatty server cannot grow the daemon's memory without end.
    while (diagnostics.length > 100) {
      diagnostics.removeAt(0);
    }
  }

  Future<void> _releaseClient() async {
    await _toolsChanged?.cancel();
    await _resourcesChanged?.cancel();
    await _diagnostics?.cancel();
    _toolsChanged = null;
    _resourcesChanged = null;
    _diagnostics = null;
    await client?.close();
    client = null;
  }

  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    _retryTimer?.cancel();
    await _releaseClient();
  }
}
