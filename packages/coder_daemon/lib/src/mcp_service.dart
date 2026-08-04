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
  });

  /// Version reported to servers during the handshake.
  final String clientVersion;

  /// Delay before the first reconnection attempt.
  final Duration initialBackoff;

  /// Upper bound on the reconnection delay.
  final Duration maximumBackoff;

  final McpConfigStore _store;
  final CredentialRepository _credentials;
  final McpTransportFactory _transports;
  final Clock _clock;
  final Map<String, String> _environment;
  final McpTimerFactory _timerFactory;
  final Random _jitter = Random(0x6d6370);

  final Map<String, _Connection> _user = <String, _Connection>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  bool _closed = false;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  List<AgentToolDefinitionDto> tools({String? workspaceRoot}) =>
      <AgentToolDefinitionDto>[
        for (final connection in _user.values) ...connection.toolDefinitions,
      ];

  /// Every configured server and its live state, user scope first.
  List<McpServerStateDto> states() => <McpServerStateDto>[
    for (final connection in _user.values) connection.state,
  ];

  /// Returns the tool behind [id], or null when its server is not ready.
  AgentTool? tool(String id, {String? workspaceRoot}) {
    final parsed = parseMcpToolId(id);
    if (parsed == null) return null;
    return _user[parsed.server]?.toolNamed(id);
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
    await Future.wait(_user.values.map((connection) => connection.dispose()));
    _user.clear();
    await _changes.close();
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

final class _Connection {
  _Connection({
    required this.config,
    required this.sourcePath,
    required this.scope,
    required this.service,
  });

  final McpServerConfigDto config;
  final String sourcePath;
  final McpConfigScope scope;
  final McpService service;

  final List<String> diagnostics = <String>[];

  McpClient? client;
  StreamSubscription<void>? _toolsChanged;
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
    error: error,
    diagnostics: List<String>.unmodifiable(diagnostics),
    lastConnectedAt: lastConnectedAt,
    nextRetryAt: nextRetryAt,
    attempt: attempt,
  );

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
    if (!config.enabled) {
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

  Future<void> _connect() async {
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
      _scheduleRetry();
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
    await _diagnostics?.cancel();
    _toolsChanged = null;
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
