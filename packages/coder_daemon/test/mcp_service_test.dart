@Tags(<String>['feature_test__mcp_server_management__unit'])
library;

import 'dart:async';

import 'package:coder_daemon/src/mcp_config.dart';
import 'package:coder_daemon/src/mcp_service.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_mcp/coder_mcp.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

import 'support/scripted_mcp_server.dart';

void main() {
  const stdioServer = McpServerConfigDto(
    id: 'github',
    transport: McpTransportKind.stdio,
    command: 'npx',
    env: <String, String>{'TOKEN': r'${secret:github.token}'},
  );

  late _MemoryConfigStore store;
  late _FakeTransports transports;
  late _FakeCredentials credentials;

  McpService build({
    Map<String, String> environment = const <String, String>{},
    McpTimerFactory? timerFactory,
  }) => McpService(
    store: store,
    credentials: credentials,
    transports: transports,
    clock: _FixedClock(),
    environment: environment,
    timerFactory: timerFactory ?? Timer.new,
  );

  setUp(() {
    store = _MemoryConfigStore();
    transports = _FakeTransports();
    credentials = _FakeCredentials()
      ..mcpSecrets['github.token'] = 'stored-secret';
  });

  test('an empty configuration publishes nothing', () async {
    final service = build();
    addTearDown(service.close);

    await service.initialize();

    expect(service.tools(), isEmpty);
    expect(service.states(), isEmpty);
    expect(service.tool('mcp__github__echo'), isNull);
  });

  test('a connected server publishes its tools and state', () async {
    store.user = <McpServerConfigDto>[stdioServer];
    final service = build();
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    expect(service.tools().single.id, 'mcp__github__echo');
    expect(service.tools().single.risk, ToolRisk.dangerous);
    expect(service.tool('mcp__github__echo'), isNotNull);

    final state = service.states().single;
    expect(state.status, McpServerStatus.ready);
    expect(state.scope, McpConfigScope.user);
    expect(state.sourcePath, store.sourcePath(McpConfigScope.user));
    expect(state.serverName, 'fake');
    expect(state.protocolVersion, preferredMcpProtocolVersion);
    expect(state.tools.single.toolId, 'mcp__github__echo');
    expect(state.tools.single.name, 'echo');
    expect(state.error, isNull);
    expect(state.lastConnectedAt, isNotNull);
  });

  test(
    'a ready server publishes its resources, scoped and sorted',
    tags: const <String>['feature_test__mcp_resource_access__verticalSlice'],
    () async {
      transports.nextServer = ScriptedMcpServer(
        publishesResources: true,
        resourcePages: <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[
            <String, dynamic>{'uri': 'file:///b.txt', 'name': 'b'},
            <String, dynamic>{'uri': 'file:///a.txt', 'name': 'a'},
          ],
        ],
        resourceTemplates: <Map<String, dynamic>>[
          <String, dynamic>{'uriTemplate': 'file:///{path}'},
        ],
      );
      store.user = <McpServerConfigDto>[stdioServer];
      final service = build();
      addTearDown(service.close);

      await service.initialize();
      await pumpEventQueue();

      // The state DTO carries them, so the settings UI needs no new RPC.
      final state = service.states().single;
      expect(state.resources.map((item) => item.uri), <String>[
        'file:///b.txt',
        'file:///a.txt',
      ]);
      expect(state.resourceTemplates.single.uriTemplate, 'file:///{path}');

      expect(
        service.resources().map((item) => item.descriptor.uri),
        <String>['file:///b.txt', 'file:///a.txt'],
      );
      expect(
        service.resources().every((item) => item.server == 'github'),
        isTrue,
      );
      expect(service.resourceTemplates(), hasLength(1));
      expect(service.isReady('github'), isTrue);
      expect(service.isReady('absent'), isFalse);

      final read = await service.readResource(
        server: 'github',
        uri: 'file:///a.txt',
      );
      expect((read.contents.single as McpTextResourceContents).text, 'body');

      await expectLater(
        service.readResource(server: 'absent', uri: 'file:///a.txt'),
        throwsA(isA<McpServerUnavailable>()),
      );
    },
  );

  test(
    'a server that is still connecting publishes no resources',
    tags: const <String>['feature_test__mcp_resource_access__verticalSlice'],
    () async {
      transports.nextServer = ScriptedMcpServer(
        publishesResources: true,
        resourcePages: <List<Map<String, dynamic>>>[
          <Map<String, dynamic>>[
            <String, dynamic>{'uri': 'file:///a.txt'},
          ],
        ],
      );
      store.user = <McpServerConfigDto>[stdioServer];
      transports.stall = true;
      final service = build();
      addTearDown(service.close);

      await service.initialize();

      expect(service.states().single.resources, isEmpty);
      expect(service.resources(), isEmpty);
      await expectLater(
        service.readResource(server: 'github', uri: 'file:///a.txt'),
        throwsA(isA<McpServerUnavailable>()),
      );
    },
  );

  test('initialization returns before any handshake completes', () async {
    store.user = <McpServerConfigDto>[stdioServer];
    transports.stall = true;
    final service = build();
    addTearDown(service.close);

    await service.initialize();

    expect(service.states().single.status, McpServerStatus.connecting);
    expect(service.tools(), isEmpty);
  });

  test('secrets and environment expand into the transport spec', () async {
    store.user = <McpServerConfigDto>[
      stdioServer,
      const McpServerConfigDto(
        id: 'linear',
        transport: McpTransportKind.http,
        url: 'https://mcp.linear.test/mcp',
        headers: <String, String>{'authorization': r'Bearer ${env:LINEAR}'},
      ),
    ];
    final service = build(
      environment: const <String, String>{'LINEAR': 'env-secret'},
    );
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    final stdio = transports.specs.first as McpStdioSpec;
    expect(stdio.command, 'npx');
    expect(stdio.env, <String, String>{'TOKEN': 'stored-secret'});
    final http = transports.specs.last as McpHttpSpec;
    expect(http.url, Uri.parse('https://mcp.linear.test/mcp'));
    expect(http.headers, <String, String>{
      'authorization': 'Bearer env-secret',
    });
  });

  test('a disabled server is never launched', () async {
    store.user = <McpServerConfigDto>[stdioServer.copyWith(enabled: false)];
    final service = build();
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    expect(transports.specs, isEmpty);
    expect(service.states().single.status, McpServerStatus.disabled);
    expect(service.tools(), isEmpty);
  });

  test('a server that cannot start fails without taking the rest', () async {
    store.user = <McpServerConfigDto>[
      stdioServer,
      const McpServerConfigDto(
        id: 'broken',
        transport: McpTransportKind.stdio,
        command: 'missing',
      ),
    ];
    transports.failFor.add('missing');
    final service = build();
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    final broken = service.states().firstWhere(
      (state) => state.config.id == 'broken',
    );
    expect(broken.status, McpServerStatus.failed);
    expect(broken.error, contains('cannot start'));
    expect(broken.diagnostics, isNotEmpty);
    expect(broken.nextRetryAt, isNotNull);
    // The healthy server still published its tools.
    expect(service.tools().single.id, 'mcp__github__echo');
  });

  test('an unresolvable secret fails only its own server', () async {
    store.user = <McpServerConfigDto>[
      const McpServerConfigDto(
        id: 'needy',
        transport: McpTransportKind.stdio,
        command: 'x',
        env: <String, String>{'TOKEN': r'${env:ABSENT}'},
      ),
    ];
    final service = build();
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    expect(service.states().single.status, McpServerStatus.failed);
    expect(service.states().single.error, contains('mcp_missing_env'));
  });

  test('a tool list change re-publishes and announces', () async {
    store.user = <McpServerConfigDto>[stdioServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await pumpEventQueue();

    final changes = <void>[];
    final subscription = service.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    transports.servers.single
      ..toolPages = <List<Map<String, dynamic>>>[
        <Map<String, dynamic>>[
          <String, dynamic>{'name': 'renamed'},
        ],
      ]
      ..announceToolListChanged();
    await pumpEventQueue();

    expect(changes, isNotEmpty);
    expect(service.tools().single.id, 'mcp__github__renamed');
  });

  test('saving reconciles instead of restarting everything', () async {
    store.user = <McpServerConfigDto>[
      stdioServer,
      const McpServerConfigDto(
        id: 'linear',
        transport: McpTransportKind.stdio,
        command: 'linear',
      ),
    ];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await pumpEventQueue();
    expect(transports.specs, hasLength(2));

    await service.saveUserServers(<McpServerConfigDto>[
      stdioServer,
      const McpServerConfigDto(
        id: 'linear',
        transport: McpTransportKind.stdio,
        command: 'linear-v2',
      ),
    ]);
    await pumpEventQueue();

    // Only the changed server was relaunched.
    expect(transports.specs, hasLength(3));
    expect((transports.specs.last as McpStdioSpec).command, 'linear-v2');
    expect(store.user, hasLength(2));

    await service.saveUserServers(<McpServerConfigDto>[stdioServer]);
    await pumpEventQueue();

    expect(service.states().map((state) => state.config.id), <String>[
      'github',
    ]);
  });

  test('a failed server retries with a capped, jittered backoff', () async {
    store.user = <McpServerConfigDto>[
      const McpServerConfigDto(
        id: 'broken',
        transport: McpTransportKind.stdio,
        command: 'missing',
      ),
    ];
    transports.failFor.add('missing');
    final scheduled = <_ScheduledRetry>[];
    final service = build(
      timerFactory: (delay, run) {
        scheduled.add(_ScheduledRetry(delay, run));
        return _InertTimer();
      },
    );
    addTearDown(service.close);

    await service.initialize();
    await pumpEventQueue();

    // Drive the retries by hand so the schedule is observed exactly rather
    // than raced against real time.
    for (var round = 0; round < 9; round += 1) {
      scheduled.last.run();
      await pumpEventQueue();
    }

    final delays = scheduled.map((retry) => retry.delay).toList();
    expect(delays, hasLength(10));
    // Exponential from one second, ±20% jitter, capped at a minute.
    expect(delays[0].inMilliseconds, closeTo(1000, 200));
    expect(delays[1].inMilliseconds, closeTo(2000, 400));
    expect(delays[2].inMilliseconds, closeTo(4000, 800));
    expect(delays[3].inMilliseconds, closeTo(8000, 1600));
    for (final delay in delays) {
      expect(delay, lessThanOrEqualTo(const Duration(seconds: 72)));
    }
    expect(delays.last.inMilliseconds, closeTo(60000, 12000));
    expect(service.states().single.attempt, 10);
    expect(service.states().single.status, McpServerStatus.failed);
  });

  test('a manual retry resets the backoff and reconnects', () async {
    store.user = <McpServerConfigDto>[
      const McpServerConfigDto(
        id: 'broken',
        transport: McpTransportKind.stdio,
        command: 'missing',
      ),
    ];
    transports.failFor.add('missing');
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await pumpEventQueue();
    expect(service.states().single.attempt, 1);

    transports.failFor.clear();
    service.retry('broken');
    await pumpEventQueue();

    expect(service.states().single.status, McpServerStatus.ready);
    expect(service.states().single.attempt, 0);
    // Retrying an id that is not configured is a no-op, not a crash.
    service.retry('absent');
  });

  test('a lost connection is reported and retried', () async {
    store.user = <McpServerConfigDto>[stdioServer];
    final service = build();
    addTearDown(service.close);
    await service.initialize();
    await pumpEventQueue();
    expect(service.states().single.status, McpServerStatus.ready);

    transports.servers.single.transport.dropPeer('exited with code 1');
    await pumpEventQueue();

    expect(service.states().single.status, McpServerStatus.failed);
    expect(service.tools(), isEmpty);
    expect(service.states().single.nextRetryAt, isNotNull);
  });

  test('closing disposes every connection and is safe to repeat', () async {
    store.user = <McpServerConfigDto>[stdioServer];
    final service = build();
    await service.initialize();
    await pumpEventQueue();

    await service.close();
    await service.close();

    expect(service.states(), isEmpty);
    expect(service.tools(), isEmpty);
  });
}

final class _ScheduledRetry {
  const _ScheduledRetry(this.delay, this.run);

  final Duration delay;
  final void Function() run;
}

final class _InertTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => true;

  @override
  int get tick => 0;
}

final class _FixedClock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 8, 4, 12);
}

final class _MemoryConfigStore implements McpConfigStore {
  List<McpServerConfigDto> user = <McpServerConfigDto>[];

  @override
  String sourcePath(McpConfigScope scope, {String? rootPath}) =>
      scope == McpConfigScope.user
      ? '/config/mcp.json'
      : '${rootPath ?? ''}/.mcp.json';

  @override
  Future<McpConfigDocument> load(
    McpConfigScope scope, {
    String? rootPath,
  }) async => McpConfigDocument(
    scope: scope,
    sourcePath: sourcePath(scope, rootPath: rootPath),
    servers: scope == McpConfigScope.user ? user : const <McpServerConfigDto>[],
  );

  @override
  Future<void> save(McpConfigDocument document) async {
    user = document.servers;
  }

  @override
  Stream<void> watch(McpConfigScope scope, {String? rootPath}) =>
      const Stream<void>.empty();
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
  final Set<String> failFor = <String>{};
  bool stall = false;

  /// Answers the next connection with this server instead of a default one.
  ScriptedMcpServer? nextServer;

  @override
  McpTransport create(McpTransportSpec spec) {
    specs.add(spec);
    final command = spec is McpStdioSpec ? spec.command : '';
    if (failFor.contains(command)) return _UnstartableTransport();
    if (stall) return _StalledTransport();
    final server = nextServer ?? ScriptedMcpServer();
    nextServer = null;
    servers.add(server);
    return server.transport;
  }
}

final class _UnstartableTransport implements McpTransport {
  @override
  Stream<Map<String, dynamic>> get incoming =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Stream<String> get diagnostics => const Stream<String>.empty();

  @override
  Future<void> get done => Completer<void>().future;

  @override
  Future<void> start() async =>
      throw const McpTransportClosed('the server cannot start');

  @override
  Future<void> send(Map<String, dynamic> message) async {}

  @override
  Future<void> close() async {}
}

final class _StalledTransport implements McpTransport {
  @override
  Stream<Map<String, dynamic>> get incoming =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Stream<String> get diagnostics => const Stream<String>.empty();

  @override
  Future<void> get done => Completer<void>().future;

  @override
  Future<void> start() async {}

  @override
  Future<void> send(Map<String, dynamic> message) async {}

  @override
  Future<void> close() async {}
}
