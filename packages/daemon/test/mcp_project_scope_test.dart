@Tags(<String>['feature_test__mcp_tool_execution__unit'])
library;

import 'dart:async';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_config.dart';
import 'package:daemon/src/features/mcp/infrastructure/mcp_service.dart';
import 'package:daemon/src/features/mcp/infrastructure/testing.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  const projectServer = McpServerConfigDto(
    id: 'repo',
    transport: McpTransportKind.stdio,
    command: './tools/mcp',
  );

  late _MemoryConfigStore store;
  late _FakeTransports transports;
  late _MutableClock clock;

  McpRuntime build() => McpRuntime(
    store: store,
    credentials: _FakeCredentials(),
    transports: transports,
    clock: clock,
    timerFactory: (delay, run) => _InertTimer(),
  );

  setUp(() {
    store = _MemoryConfigStore();
    transports = _FakeTransports();
    clock = _MutableClock();
  });

  test(
    'a project server stays unlaunched until its worktree is used',
    () async {
      store.project['/repo'] = <McpServerConfigDto>[projectServer];
      final service = build();
      addTearDown(service.close);
      await service.initialize();
      await pumpEventQueue();

      expect(transports.specs, isEmpty);
      expect(service.tools(workspaceRoot: '/repo'), isEmpty);

      await service.ensureProject('/repo');
      await pumpEventQueue();

      expect(transports.specs, hasLength(1));
      expect(
        service.tools(workspaceRoot: '/repo').single.id,
        'mcp__repo__echo',
      );
    },
  );

  test('project tools are invisible outside their own worktree', () async {
    store.project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();

    expect(service.tools(), isEmpty);
    expect(service.tools(workspaceRoot: '/other'), isEmpty);
    // A caller that has not named a worktree sees only user-scoped servers,
    // never what some other repository happens to declare.
    expect(service.states(), isEmpty);
    expect(service.states(workspaceRoot: '/other'), isEmpty);
    expect(service.states(workspaceRoot: '/repo'), hasLength(1));
    expect(service.tool('mcp__repo__echo'), isNull);
    expect(service.tool('mcp__repo__echo', workspaceRoot: '/other'), isNull);
    expect(
      service.tool('mcp__repo__echo', workspaceRoot: '/repo'),
      isNotNull,
    );
  });

  test('two worktrees declaring one id stay independent', () async {
    store.project
      ..['/a'] = <McpServerConfigDto>[projectServer]
      ..['/b'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/a');
    await service.ensureProject('/b');
    await pumpEventQueue();

    expect(transports.specs, hasLength(2));
    expect(service.tools(workspaceRoot: '/a'), hasLength(1));
    expect(service.tools(workspaceRoot: '/b'), hasLength(1));
    expect(service.states(workspaceRoot: '/a'), hasLength(1));
    expect(service.states(workspaceRoot: '/b'), hasLength(1));
    expect(
      service.states(workspaceRoot: '/a').single.sourcePath,
      '/a/.mcp.json',
    );
  });

  test('ensuring the same worktree twice reuses its connections', () async {
    store.project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();

    await service.ensureProject('/repo');
    await service.ensureProject('/repo');
    await pumpEventQueue();

    expect(transports.specs, hasLength(1));
  });

  test('a user server of the same id shadows the project one', () async {
    store
      ..user = <McpServerConfigDto>[
        const McpServerConfigDto(
          id: 'repo',
          transport: McpTransportKind.stdio,
          command: 'user-owned',
        ),
      ]
      ..project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();

    // The project server is never launched, and says why.
    expect(transports.specs, hasLength(1));
    expect((transports.specs.single as McpStdioSpec).command, 'user-owned');

    final shadowed = service
        .states(workspaceRoot: '/repo')
        .firstWhere((state) => state.scope == McpConfigScope.project);
    expect(shadowed.shadowed, isTrue);
    expect(shadowed.status, McpServerStatus.disabled);
    expect(
      service.states().where((state) => state.scope == McpConfigScope.user),
      hasLength(1),
    );

    // The user server's tool is the one a turn resolves.
    expect(
      service.tool('mcp__repo__echo', workspaceRoot: '/repo'),
      isNotNull,
    );
    expect(service.tools(workspaceRoot: '/repo'), hasLength(1));
  });

  test('an edited .mcp.json is reconciled, not restarted wholesale', () async {
    store.project['/repo'] = <McpServerConfigDto>[
      projectServer,
      const McpServerConfigDto(
        id: 'docs',
        transport: McpTransportKind.stdio,
        command: 'docs',
      ),
    ];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();
    expect(transports.specs, hasLength(2));

    store.project['/repo'] = <McpServerConfigDto>[
      projectServer,
      const McpServerConfigDto(
        id: 'docs',
        transport: McpTransportKind.stdio,
        command: 'docs-v2',
      ),
    ];
    store.announce(McpConfigScope.project, '/repo');
    await pumpEventQueue();

    expect(transports.specs, hasLength(3));
    expect((transports.specs.last as McpStdioSpec).command, 'docs-v2');
  });

  test(
    'an invalid .mcp.json is reported without breaking the daemon',
    () async {
      store.projectFailure['/repo'] = const FormatException(
        'invalid_mcp_config: /repo/.mcp.json server "x" needs a "command".',
      );
      final service = build();
      addTearDown(service.close);
      await service.initialize();

      await service.ensureProject('/repo');
      await pumpEventQueue();

      expect(service.tools(workspaceRoot: '/repo'), isEmpty);
      expect(service.projectError('/repo'), contains('invalid_mcp_config'));
    },
  );

  test('an idle worktree is released after its timeout', () async {
    store.project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();
    expect(service.tools(workspaceRoot: '/repo'), hasLength(1));

    clock.advance(const Duration(minutes: 31));
    service.releaseIdleProjects();
    await pumpEventQueue();

    expect(service.tools(workspaceRoot: '/repo'), isEmpty);
    expect(service.states(workspaceRoot: '/repo'), isEmpty);

    // Using it again reconnects from scratch.
    await service.ensureProject('/repo');
    await pumpEventQueue();
    expect(service.tools(workspaceRoot: '/repo'), hasLength(1));
  });

  test('a recently used worktree survives the idle sweep', () async {
    store.project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();

    clock.advance(const Duration(minutes: 20));
    service.releaseIdleProjects();
    await pumpEventQueue();

    expect(service.tools(workspaceRoot: '/repo'), hasLength(1));
  });

  test('closing releases the project connections too', () async {
    store.project['/repo'] = <McpServerConfigDto>[projectServer];
    final service = build();
    await service.initialize();
    await service.ensureProject('/repo');
    await pumpEventQueue();

    await service.close();

    expect(service.states(), isEmpty);
    expect(service.tools(workspaceRoot: '/repo'), isEmpty);
  });
}

final class _MutableClock implements Clock {
  DateTime _now = DateTime.utc(2026, 8, 4, 12);

  void advance(Duration by) => _now = _now.add(by);

  @override
  DateTime nowUtc() => _now;
}

final class _MemoryConfigStore implements McpConfigStore {
  List<McpServerConfigDto> user = <McpServerConfigDto>[];
  final Map<String, List<McpServerConfigDto>> project =
      <String, List<McpServerConfigDto>>{};
  final Map<String, Exception> projectFailure = <String, Exception>{};
  final Map<String, StreamController<void>> _watchers =
      <String, StreamController<void>>{};

  void announce(McpConfigScope scope, String rootPath) =>
      _watchers['${scope.name}:$rootPath']?.add(null);

  @override
  String sourcePath(McpConfigScope scope, {String? rootPath}) =>
      scope == McpConfigScope.user
      ? '/config/mcp.json'
      : '${rootPath ?? ''}/.mcp.json';

  @override
  Future<McpConfigDocument> load(
    McpConfigScope scope, {
    String? rootPath,
  }) async {
    if (scope == McpConfigScope.project) {
      final failure = projectFailure[rootPath];
      if (failure != null) throw failure;
    }
    return McpConfigDocument(
      scope: scope,
      sourcePath: sourcePath(scope, rootPath: rootPath),
      servers: scope == McpConfigScope.user
          ? user
          : project[rootPath] ?? const <McpServerConfigDto>[],
    );
  }

  @override
  Future<void> save(McpConfigDocument document) async {
    user = document.servers;
  }

  @override
  Stream<void> watch(McpConfigScope scope, {String? rootPath}) {
    final key = '${scope.name}:${rootPath ?? ''}';
    final controller = _watchers.putIfAbsent(
      key,
      StreamController<void>.broadcast,
    );
    return controller.stream;
  }
}

final class _FakeCredentials implements CredentialRepository {
  @override
  final Map<String, String> mcpSecrets = <String, String>{};

  @override
  String? get bearerToken => null;

  @override
  ProviderCredential? credential(String connectionId) => null;

  @override
  Future<void> load() async {}

  @override
  Future<void> removeCredential(String connectionId) async {}

  @override
  Future<void> removeMcpSecret(String key) async {}

  @override
  Future<void> setCredential(
    String connectionId,
    ProviderCredential credential,
  ) async {}

  @override
  Future<void> setDaemonToken(String bearerToken) async {}

  @override
  Future<void> setMcpSecret(String key, String value) async {}
}

final class _FakeTransports implements McpTransportFactory {
  final List<McpTransportSpec> specs = <McpTransportSpec>[];
  final List<ScriptedMcpServer> servers = <ScriptedMcpServer>[];

  @override
  McpTransport create(McpTransportSpec spec) {
    specs.add(spec);
    final server = ScriptedMcpServer();
    servers.add(server);
    return server.transport;
  }
}

final class _InertTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => true;

  @override
  int get tick => 0;
}
