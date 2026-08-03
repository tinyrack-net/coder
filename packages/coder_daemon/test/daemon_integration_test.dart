import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_daemon/src/provider_auth.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  test(
    'standalone application serves authenticated workspace and agent RPCs',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-daemon-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-workspace-',
      );
      final modelServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      modelServer.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'object': 'list',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'test-model', 'owned_by': 'test'},
              <String, dynamic>{'id': 'discovered-model', 'owned_by': 'test'},
            ],
          }),
        );
        await request.response.close();
      });
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'test-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
        await modelServer.close(force: true);
      });

      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'test-token-0123456789abcdef0123456789',
        ),
        clientId: 'integration-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      expect(client.serverInfo.serverId, handle.serverId);
      expect(client.serverInfo.features, isNot(contains('providerAdmin')));
      expect(client.serverInfo.features['jsonRpc2'], isTrue);
      final initialCatalog = await client.listProviderCatalog();
      expect(
        initialCatalog.definitions.map((item) => item.id),
        containsAll(<String>['openai', 'deepseek', 'ollama']),
      );
      expect(
        initialCatalog.toJson().toString(),
        isNot(anyOf(contains('baseUrl'), contains('transport'))),
      );
      final custom = await client.createCustomProvider(
        'local-test',
        CustomProviderConfigDto(
          name: 'Local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
        makeDefault: true,
      );
      expect(custom.status, ProviderConnectionStatus.connected);
      expect(custom.authKind, ProviderAuthKind.none);
      expect(
        (await client.listProviderConnections())
            .singleWhere((connection) => connection.id == 'local-test')
            .id,
        'local-test',
      );
      expect(
        (await client.listProviderModels('local-test')).map((item) => item.id),
        containsAll(<String>['test-model', 'discovered-model']),
      );
      final updatedCustom = await client.updateCustomProvider(
        'local-test',
        CustomProviderConfigDto(
          name: 'Updated local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
      );
      expect(updatedCustom.displayName, 'Updated local test');
      await client.setDefaultProviderModel('local-test', 'discovered-model');
      expect(
        (await client.listProviderConnections())
            .singleWhere((connection) => connection.id == 'local-test')
            .defaultModelId,
        'discovered-model',
      );
      await client.setDefaultProviderModel('local-test', 'test-model');
      await client.setDefaultProvider('local-test');
      final temporary = await client.createCustomProvider(
        'temporary',
        CustomProviderConfigDto(
          name: 'Temporary',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          apiFormat: ProviderApiFormat.responses,
          authenticationRequired: false,
          manualModelIds: const <String>['test-model'],
        ),
      );
      expect(temporary.id, 'temporary');
      await client.deleteCustomProvider(temporary.id);
      expect(
        (await client.listProviderConnections()).map((item) => item.id),
        isNot(contains('temporary')),
      );
      final registered = await client.registerWorkspace(
        workspaceId: 'workspace-1',
        checkoutId: 'checkout-1',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      expect(
        registered.workspace.rootPath,
        workspace.resolveSymbolicLinksSync(),
      );
      expect((await client.getWorkspaceCatalog()).workspaces, hasLength(1));
      final checkout = registered.worktrees.single;

      final agent = await client.createSession(
        id: 'agent-1',
        worktreeId: checkout.id,
        title: 'Session',
        agentDefinitionId: 'coder',
      );
      expect(agent.status, SessionStatus.idle);
      final coder = (await client.listAgentDefinitions()).single;
      final configuredDefinition = await client.updateAgentDefinition(
        coder.copyWith(reasoningEffort: 'high'),
        expectedContentHash: coder.contentHash,
      );
      expect(configuredDefinition.reasoningEffort, 'high');
      expect(await client.listSessions(worktreeId: checkout.id), hasLength(1));
      expect(await client.subscribeTimeline(agent.id), isEmpty);

      final approvalFuture = client.events
          .where((event) => event is ApprovalRequestedClientEvent)
          .cast<ApprovalRequestedClientEvent>()
          .map((event) => event.approval)
          .first
          .timeout(const Duration(seconds: 5));
      final completedFuture = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere((event) => event.type == 'turn.completed')
          .timeout(const Duration(seconds: 5));
      await client.startTurn(
        sessionId: agent.id,
        turnId: 'turn-1',
        prompt: 'Create result.txt',
      );
      final approval = await approvalFuture;
      expect(approval.toolName, 'apply_patch');
      expect(approval.preview, contains('result.txt'));
      await client.resolveApproval(approvalId: approval.id, approved: true);
      await completedFuture;
      final afterTurn = await client.updateAgentDefinition(
        configuredDefinition.copyWith(reasoningEffort: 'medium'),
        expectedContentHash: configuredDefinition.contentHash,
      );
      expect(afterTurn.reasoningEffort, 'medium');

      expect(
        await File('${workspace.path}/result.txt').readAsString(),
        'done\n',
      );
      final timeline = await client.subscribeTimeline(agent.id);
      expect(
        timeline.map((event) => event.sequence),
        orderedEquals(
          List<int>.generate(timeline.length, (index) => index + 1),
        ),
      );
      expect(timeline.map((event) => event.type), contains('tool.completed'));
      expect(timeline.map((event) => event.type), contains('turn.completed'));
      await client.disconnectProvider('local-test');
      await expectLater(
        client.startTurn(
          sessionId: agent.id,
          turnId: 'turn-stale-provider',
          prompt: 'This must not run.',
        ),
        throwsA(
          isA<CoderClientException>().having(
            (error) => error.code,
            'code',
            'provider_not_connected',
          ),
        ),
      );
      expect(
        (await client.listSessions(worktreeId: checkout.id)).single.status,
        SessionStatus.idle,
      );
    },
    tags: const <String>[
      'feature_test__workspace_catalog__verticalSlice',
      'feature_test__workspace_registration__verticalSlice',
      'feature_test__session_lifecycle__verticalSlice',
      'feature_test__turn_execution__verticalSlice',
      'feature_test__provider_catalog__verticalSlice',
      'feature_test__provider_connection_management__verticalSlice',
      'feature_test__provider_custom__verticalSlice',
    ],
  );

  test(
    'primary agents delegate to allowlisted Markdown subagents at depth one',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-delegate-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-delegate-workspace-',
      );
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'delegate-token-0123456789abcdef012345',
          useEnvironmentCredentials: false,
        ),
        provider: _DelegatingProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'delegate-token-0123456789abcdef012345',
        ),
        clientId: 'delegate-test',
        clientKind: 'test',
      );
      addTearDown(client.close);
      final coder = (await client.listAgentDefinitions()).single;
      final reviewer = await client.createAgentDefinition(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          mode: AgentMode.subagent,
          permissionMode: PermissionMode.readOnly,
          toolIds: const <String>['apply_patch'],
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      await client.updateAgentDefinition(
        coder.copyWith(
          permissionMode: PermissionMode.workspaceWrite,
          callableAgentIds: <String>[reviewer.id],
        ),
        expectedContentHash: coder.contentHash,
      );
      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final parent = await client.createSession(
        id: 'parent',
        worktreeId: registered.worktrees.single.id,
        title: 'Parent',
        agentDefinitionId: 'coder',
      );
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere(
            (event) =>
                event.sessionId == parent.id && event.type == 'turn.completed',
          )
          .timeout(const Duration(seconds: 5));
      await client.subscribeTimeline(parent.id);
      await client.startTurn(
        sessionId: parent.id,
        turnId: 'parent-turn',
        prompt: 'Review this workspace.',
      );
      await completed;

      final sessions = await client.listSessions(
        worktreeId: registered.worktrees.single.id,
      );
      final child = sessions.singleWhere(
        (session) => session.origin == SessionOrigin.delegated,
      );
      expect(child.parentSessionId, parent.id);
      expect(child.agentDefinitionId, reviewer.id);
      final childTimeline = await client.subscribeTimeline(child.id);
      expect(childTimeline.map((event) => event.type), contains('tool.denied'));
      expect(
        childTimeline
            .where((event) => event.type == 'tool.requested')
            .single
            .data['name'],
        'apply_patch',
      );
    },
    tags: const <String>['feature_test__agent_delegation__verticalSlice'],
  );

  test(
    'agent create survives watcher reload and daemon restart',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-agent-create-home-',
      );
      const bearerToken = 'agent-create-token-0123456789abcdef012345';
      final config = DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        bearerToken: bearerToken,
        useEnvironmentCredentials: false,
      );
      addTearDown(() async {
        if (home.existsSync()) await home.delete(recursive: true);
      });

      final firstHandle = await DaemonApplication.start(config);
      final firstClient = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: firstHandle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'agent-create-first',
        clientKind: 'test',
      );
      final coder = (await firstClient.listAgentDefinitions()).single;
      await firstClient.createAgentDefinition(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          description: '',
          mode: AgentMode.subagent,
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      expect(
        (await firstClient.listAgentDefinitions()).map((item) => item.id),
        contains('reviewer'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        (await firstClient.listAgentDefinitions()).map((item) => item.id),
        contains('reviewer'),
      );
      expect(File('${home.path}/agents/reviewer.md').existsSync(), isTrue);
      await firstClient.close();
      await firstHandle.stop();

      final secondHandle = await DaemonApplication.start(config);
      final secondClient = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: secondHandle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'agent-create-second',
        clientKind: 'test',
      );
      expect(
        (await secondClient.listAgentDefinitions()).map((item) => item.id),
        contains('reviewer'),
      );
      await secondClient.close();
      await secondHandle.stop();
    },
    tags: const <String>[
      'feature_test__agent_definition_management__verticalSlice',
    ],
  );

  test(
    'bearer-only clients can mutate provider and Agent settings',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-remote-home-');
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'remote-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
      });
      for (final headers in <Map<String, dynamic>>[
        const <String, dynamic>{},
        const <String, dynamic>{'Authorization': 'Bearer incorrect'},
      ]) {
        await expectLater(
          WebSocket.connect(
            handle.boundEndpoint.toString(),
            headers: headers,
          ),
          throwsA(isA<WebSocketException>()),
        );
      }
      final obsoleteChannel = IOWebSocketChannel.connect(
        handle.boundEndpoint,
        headers: const <String, dynamic>{
          'Authorization': 'Bearer remote-token-0123456789abcdef0123456789',
        },
      );
      await obsoleteChannel.ready;
      final obsoletePeer = json_rpc.Peer(obsoleteChannel.cast<String>());
      unawaited(obsoletePeer.listen());
      await expectLater(
        obsoletePeer.sendRequest(
          RpcMethod.hello,
          const HelloParamsDto(
            clientId: 'obsolete-client',
            clientKind: 'test',
            protocolVersion: 6,
            capabilities: <String, bool>{},
          ).toJson(),
        ),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (error) => error.code,
            'code',
            1001,
          ),
        ),
      );
      await obsoletePeer.close();
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'remote-token-0123456789abcdef0123456789',
        ),
        clientId: 'remote-test',
        clientKind: 'mobile',
      );
      addTearDown(client.close);
      expect(client.serverInfo.features, isNot(contains('providerAdmin')));
      final connection = await client.createCustomProvider(
        'denied',
        const CustomProviderConfigDto(
          name: 'Bearer managed',
          baseUrl: 'http://127.0.0.1:9999/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
        ),
      );
      expect(connection.id, 'denied');
      final coder = (await client.listAgentDefinitions()).single;
      final updated = await client.updateAgentDefinition(
        coder.copyWith(name: 'Bearer managed Coder'),
        expectedContentHash: coder.contentHash,
      );
      expect(updated.name, 'Bearer managed Coder');
    },
    tags: const <String>[
      'feature_test__daemon_authentication__verticalSlice',
    ],
  );

  test(
    'real daemon creates and archives a Git worktree over WebSocket',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-git-home-');
      final repository = await Directory.systemTemp.createTemp(
        'coder-git-repository-',
      );
      await _runGit(repository.path, <String>['init', '-b', 'main']);
      await File('${repository.path}/README.md').writeAsString('# fixture\n');
      await _runGit(repository.path, <String>['add', 'README.md']);
      await _runGit(repository.path, <String>[
        '-c',
        'user.name=Coder Test',
        '-c',
        'user.email=coder@example.invalid',
        'commit',
        '-m',
        'Initial fixture',
      ]);
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'git-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await repository.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: DaemonCredentials(bearerToken: handle.bearerToken),
        clientId: 'git-vertical-slice',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'git-workspace',
        checkoutId: 'main-checkout',
        rootPath: repository.path,
        name: 'Git fixture',
      );
      expect(registered.workspace.kind, WorkspaceKind.git);
      expect(await client.listGitBranches('git-workspace'), hasLength(1));
      final managed = await client.createWorktree(
        id: 'managed-worktree',
        workspaceId: 'git-workspace',
        mode: WorktreeCreateMode.newBranch,
        branchName: 'feature/vertical-slice',
        baseBranch: 'main',
      );
      expect(Directory(managed.path).existsSync(), isTrue);
      expect(
        (await client.refreshWorkspace('git-workspace')).worktrees,
        isNotEmpty,
      );
      final preview = await client.previewWorktreeArchive(managed.id);
      expect(preview.removesDirectory, isTrue);
      await client.archiveWorktree(managed.id);
      expect(Directory(managed.path).existsSync(), isFalse);
      await client.unregisterWorkspace('git-workspace');
      expect((await client.getWorkspaceCatalog()).workspaces, isEmpty);
    },
    tags: const <String>['feature_test__worktree_lifecycle__verticalSlice'],
  );

  test(
    'real daemon completes and cancels OAuth attempts over WebSocket',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-oauth-home-');
      final gateway = _IntegrationOAuthGateway();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'oauth-token-0123456789abcdef01234567',
          useEnvironmentCredentials: false,
        ),
        oauthGateway: gateway,
        modelDiscovery: const _StaticDiscovery(<String>['gpt-test']),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: DaemonCredentials(bearerToken: handle.bearerToken),
        clientId: 'oauth-vertical-slice',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final completed = await client.startProviderAuth(
        'openai',
        'chatgpt-device',
      );
      gateway.sessions.single.completer.complete(
        OAuthCredential(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );
      await _waitForAuthStatus(
        client,
        completed.id,
        ProviderAuthAttemptStatus.succeeded,
      );
      expect(
        (await client.listProviderConnections()).single.credentialOrigin,
        ProviderCredentialOrigin.oauth,
      );

      final cancelled = await client.startProviderAuth(
        'openai',
        'chatgpt-browser',
      );
      await client.cancelProviderAuth(cancelled.id);
      expect(
        (await client.providerAuthStatus(cancelled.id)).status,
        ProviderAuthAttemptStatus.cancelled,
      );
      expect(gateway.sessions.last.cancelled, isTrue);
    },
    tags: const <String>['feature_test__provider_oauth__verticalSlice'],
  );

  test('secrets are not persisted in daemon files', () async {
    final home = await Directory.systemTemp.createTemp('coder-secret-home-');
    final config = await Directory.systemTemp.createTemp(
      'coder-secret-config-',
    );
    const token = 'plaintext-token-that-must-not-be-stored';
    const apiKey = 'plaintext-api-key-that-must-not-be-stored';
    final handle = await DaemonApplication.start(
      DaemonConfig(
        homeDirectory: home.path,
        configDirectory: config.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
        apiKey: apiKey,
      ),
      modelDiscovery: const _StaticDiscovery(<String>['gpt-5.6-sol']),
    );
    await handle.stop();
    final persisted = StringBuffer();
    await for (final entity in home.list()) {
      if (entity is File) {
        persisted.write(String.fromCharCodes(await entity.readAsBytes()));
      }
    }
    expect(persisted.toString(), isNot(contains(token)));
    expect(persisted.toString(), isNot(contains(apiKey)));
    final credentials = await File(
      '${config.path}/credentials.json',
    ).readAsString();
    expect(credentials, contains(token));
    expect(credentials, contains(apiKey));
    expect(File('${config.path}/auth.json').existsSync(), isFalse);
    if (!Platform.isWindows) {
      expect(
        File('${config.path}/credentials.json').statSync().mode & 0x1ff,
        0x180,
      );
    }
    await home.delete(recursive: true);
    await config.delete(recursive: true);
  });

  test('embedded daemon starts in an isolate and shuts down cleanly', () async {
    final home = await Directory.systemTemp.createTemp('coder-embedded-home-');
    final handle = await EmbeddedDaemonHandle.start(
      DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        bearerToken: 'embedded-token-0123456789abcdef012345',
        useEnvironmentCredentials: false,
      ),
    );
    expect(handle.boundEndpoint.port, greaterThan(0));
    await handle.stop();
    await home.delete(recursive: true);
  });
}

Future<void> _runGit(String workingDirectory, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    throw TestFailure('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Future<void> _waitForAuthStatus(
  CoderApi client,
  String attemptId,
  ProviderAuthAttemptStatus status,
) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
    final current = await client.providerAuthStatus(attemptId);
    if (current.status == status) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TestFailure('Timed out waiting for OAuth status ${status.name}.');
}

final class _IntegrationOAuthGateway implements ProviderOAuthGateway {
  final List<_IntegrationOAuthSession> sessions = <_IntegrationOAuthSession>[];

  @override
  Future<OAuthCredential> refresh(OAuthCredential credential) async =>
      credential;

  @override
  Future<ProviderOAuthSession> start(ProviderAuthFlow flow) async {
    final session = _IntegrationOAuthSession(flow);
    sessions.add(session);
    return session;
  }
}

final class _IntegrationOAuthSession implements ProviderOAuthSession {
  _IntegrationOAuthSession(this.flow);

  final ProviderAuthFlow flow;
  final Completer<OAuthCredential> completer = Completer<OAuthCredential>();
  bool cancelled = false;

  @override
  String get authorizationUrl => 'https://auth.example/${flow.name}';

  @override
  Future<OAuthCredential> get completion => completer.future;

  @override
  DateTime get expiresAt =>
      DateTime.now().toUtc().add(const Duration(minutes: 15));

  @override
  String? get instructions => 'Complete the test authorization.';

  @override
  String? get userCode =>
      flow == ProviderAuthFlow.oauthDevice ? 'TEST-CODE' : null;

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

final class _StaticDiscovery implements ProviderModelDiscovery {
  const _StaticDiscovery(this.modelIds);

  final List<String> modelIds;

  @override
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  ) async => modelIds;
}

class _PatchProvider implements ModelProvider {
  var _round = 0;

  @override
  String get id => 'fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_round++ == 0) {
      const arguments = <String, dynamic>{
        'patch': '--- /dev/null\n+++ b/result.txt\n@@ -0,0 +1,1 @@\n+done\n',
      };
      yield const ModelFunctionCall(
        callId: 'patch-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'patch-call',
              name: 'apply_patch',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Created result.txt');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Created result.txt'),
    );
  }
}

final class _DelegatingProvider implements ModelProvider {
  @override
  String get id => 'delegate-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final delegateEnabled = request.tools.any(
      (tool) => tool.name == 'delegate_agent',
    );
    final hasToolResult = request.history.any(
      (item) => item is ToolResultConversationItem,
    );
    if (delegateEnabled && !hasToolResult) {
      const arguments = <String, dynamic>{
        'agentDefinitionId': 'reviewer',
        'prompt': 'Review without changing files.',
      };
      yield const ModelFunctionCall(
        callId: 'delegate-call',
        name: 'delegate_agent',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'delegate-call',
              name: 'delegate_agent',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (!delegateEnabled && !hasToolResult) {
      const arguments = <String, dynamic>{
        'patch':
            '--- /dev/null\n+++ b/forbidden.txt\n'
            '@@ -0,0 +1,1 @@\n+forbidden\n',
      };
      yield const ModelFunctionCall(
        callId: 'write-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'write-call',
              name: 'apply_patch',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    final text = delegateEnabled ? 'Parent completed.' : 'Review completed.';
    yield ModelTextDelta(text);
    yield ModelResponseCompleted(
      assistant: AssistantConversationItem(text: text),
    );
  }
}
