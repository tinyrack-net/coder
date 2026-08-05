import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

/// Budget for one broadcast event to arrive.
///
/// These drive a real daemon over a real WebSocket with SQLite behind an
/// isolate, and a cold Windows runner is comfortably slower than the five
/// seconds this used to allow. A generous budget costs wall-clock only when
/// something is genuinely broken.
const Duration _eventTimeout = Duration(seconds: 30);

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

      await expectLater(
        client.createSession(
          id: 'model-required',
          worktreeId: checkout.id,
          title: 'Model required',
          agentDefinitionId: 'coder',
        ),
        throwsA(isA<CoderClientException>()),
      );
      await expectLater(
        client.createSession(
          id: 'agent-rejected',
          worktreeId: checkout.id,
          title: 'Rejected',
          agentDefinitionId: 'coder',
          model: const SessionModelSelectionDto(
            providerConnectionId: 'missing-connection',
            modelId: 'test-model',
          ),
        ),
        throwsA(
          isA<CoderClientException>().having(
            (error) => error.code,
            'code',
            'provider_not_connected',
          ),
        ),
      );
      final agent = await client.createSession(
        id: 'agent-1',
        worktreeId: checkout.id,
        title: 'Session',
        agentDefinitionId: 'coder',
        mode: SessionMode.plan,
        model: const SessionModelSelectionDto(
          providerConnectionId: 'local-test',
          modelId: 'test-model',
        ),
      );
      expect(agent.status, SessionStatus.idle);
      expect(
        agent.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'local-test',
          modelId: 'test-model',
        ),
      );
      expect(
        (await client.listSessions(worktreeId: checkout.id)).single.model,
        agent.model,
      );
      expect(agent.mode, SessionMode.plan);
      final normalFuture = client.events
          .where((event) => event is SessionUpdatedClientEvent)
          .cast<SessionUpdatedClientEvent>()
          .map((event) => event.session)
          .firstWhere((session) => session.mode == SessionMode.normal)
          .timeout(_eventTimeout);
      expect(
        (await client.updateSessionMode(agent.id, SessionMode.normal)).mode,
        SessionMode.normal,
      );
      expect((await normalFuture).id, agent.id);
      expect(
        (await client.listSessions(worktreeId: checkout.id)).single.mode,
        SessionMode.normal,
      );
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
          .timeout(_eventTimeout);
      final completedFuture = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere((event) => event.type == 'turn.completed')
          .timeout(_eventTimeout);
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
      await _waitForIdleSession(client, checkout.id, agent.id);
      final afterTurn = await client.updateAgentDefinition(
        configuredDefinition.copyWith(reasoningEffort: 'medium'),
        expectedContentHash: configuredDefinition.contentHash,
      );
      expect(afterTurn.reasoningEffort, 'medium');

      expect(
        (await client.updateSessionModel(
          agent.id,
          const SessionModelSelectionDto(
            providerConnectionId: 'local-test',
            modelId: 'test-model',
          ),
        )).model,
        const SessionModelSelectionDto(
          providerConnectionId: 'local-test',
          modelId: 'test-model',
        ),
      );
      await expectLater(
        client.updateSessionModel(agent.id, null),
        throwsA(isA<CoderClientException>()),
      );
      expect(
        (await client.listSessions(worktreeId: checkout.id)).single.model,
        agent.model,
      );
      await expectLater(
        client.updateSessionModel(
          agent.id,
          const SessionModelSelectionDto(
            providerConnectionId: 'local-test',
            modelId: 'missing-model',
          ),
        ),
        throwsA(isA<CoderClientException>()),
      );

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
        model: const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-sol',
        ),
      );
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere(
            (event) =>
                event.sessionId == parent.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
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
      expect(child.model, parent.model);
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
    'MCP servers publish tools a real turn can call',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-mcp-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-mcp-workspace-',
      );
      const bearerToken = 'mcp-token-0123456789abcdef0123456789';
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: _EchoingMcpProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'mcp-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      expect(client.serverInfo.features['mcp'], isTrue);
      expect(await client.listMcpServers(), isEmpty);

      final changed = client.events
          .where((event) => event is McpServersChangedClientEvent)
          .first
          .timeout(_eventTimeout);
      await client.setMcpSecret('fake.prefix', 'secret-');
      final added = await client.addMcpServer(
        McpServerConfigDto(
          id: 'fake',
          transport: McpTransportKind.stdio,
          command: Platform.resolvedExecutable,
          // Run the script directly rather than through `dart run`: it
          // imports nothing but dart:*, and the pub layer would otherwise
          // contend with the suite for this package's .dart_tool.
          args: <String>[_fakeMcpServerPath()],
          env: const <String, String>{
            'MCP_ECHO_PREFIX': r'${secret:fake.prefix}',
          },
        ),
      );
      await changed;
      expect(added.config.id, 'fake');

      // The server connects in the background, so wait for it to come up.
      final ready = await _awaitReadyMcpServer(client, 'fake');
      expect(ready.serverName, 'fake');
      expect(ready.protocolVersion, '2025-06-18');
      expect(ready.tools.single.toolId, 'mcp__fake__echo');

      final catalog = await client.listAgentTools();
      final published = catalog.singleWhere(
        (tool) => tool.id == 'mcp__fake__echo',
      );
      expect(published.risk, ToolRisk.dangerous);
      // Read tools are supplied by the daemon, not opted into.
      expect(
        catalog.where((tool) => tool.alwaysOn).map((tool) => tool.id),
        containsAll(<String>['list_directory', 'read_file', 'search_text']),
      );

      final coder = (await client.listAgentDefinitions()).single;
      await client.updateAgentDefinition(
        coder.copyWith(
          permissionMode: PermissionMode.workspaceWrite,
          toolIds: <String>[...coder.toolIds, 'mcp__fake__echo'],
        ),
        expectedContentHash: coder.contentHash,
      );

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final session = await client.createSession(
        id: 'mcp-session',
        worktreeId: registered.worktrees.single.id,
        title: 'MCP',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-sol',
        ),
      );
      // A dangerous tool always asks, even under workspaceWrite.
      final approvalFuture = client.events
          .where((event) => event is ApprovalRequestedClientEvent)
          .cast<ApprovalRequestedClientEvent>()
          .map((event) => event.approval)
          .first
          .timeout(_eventTimeout);
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere(
            (event) =>
                event.sessionId == session.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'mcp-turn',
        prompt: 'Echo something through MCP.',
      );
      final approval = await approvalFuture;
      expect(approval.toolName, 'mcp__fake__echo');
      expect(approval.risk, ToolRisk.dangerous);
      expect(approval.preview, 'fake.echo');
      await client.resolveApproval(approvalId: approval.id, approved: true);
      await completed;
      // turn.completed precedes the daemon's own final writes, so let the
      // session settle before the teardown closes its database.
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );

      final timeline = await client.subscribeTimeline(session.id);
      final requested = timeline
          .where((event) => event.type == 'tool.requested')
          .single;
      expect(requested.data['name'], 'mcp__fake__echo');
      // Dangerous tools need approval, and workspaceWrite does not grant it.
      expect(
        timeline.map((event) => event.type),
        contains('approval.resolved'),
      );
      final completedTool = timeline
          .where((event) => event.type == 'tool.completed')
          .single;
      // The configured secret reached the child process.
      expect(completedTool.data['output'], 'secret-through MCP');

      await client.removeMcpServer('fake');
      expect(
        (await client.listAgentTools()).map((tool) => tool.id),
        isNot(contains('mcp__fake__echo')),
      );
      expect(await client.listMcpServers(), isEmpty);
    },
    tags: const <String>[
      'feature_test__mcp_server_management__verticalSlice',
      'feature_test__mcp_tool_execution__verticalSlice',
    ],
  );

  test(
    'a project .mcp.json publishes tools only inside its own worktree',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-mcp-project-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-mcp-project-',
      );
      const bearerToken = 'mcp-project-token-0123456789abcdef0123';
      await File(p.join(workspace.path, '.mcp.json')).writeAsString(
        jsonEncode(<String, dynamic>{
          'version': 1,
          'servers': <String, dynamic>{
            'repo': <String, dynamic>{
              'transport': 'stdio',
              'command': Platform.resolvedExecutable,
              'args': <String>[_fakeMcpServerPath()],
            },
          },
        }),
      );
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'mcp-project-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final worktreeId = registered.worktrees.single.id;

      // Listing with the worktree in hand is what puts it into use.
      await client.listMcpServers(worktreeId: worktreeId);
      final ready = await _awaitReadyMcpServer(
        client,
        'repo',
        worktreeId: worktreeId,
      );
      expect(ready.scope, McpConfigScope.project);
      // The daemon canonicalizes checkout paths, and macOS resolves the
      // temporary directory through /private, so compare against what the
      // registration actually recorded.
      expect(
        ready.sourcePath,
        p.join(registered.worktrees.single.path, '.mcp.json'),
      );
      expect(ready.shadowed, isFalse);

      expect(
        (await client.listAgentTools(
          worktreeId: worktreeId,
        )).map((tool) => tool.id),
        contains('mcp__repo__echo'),
      );
      // The daemon-wide catalog never sees a repository's servers.
      expect(
        (await client.listAgentTools()).map((tool) => tool.id),
        isNot(contains('mcp__repo__echo')),
      );
      expect(await client.listMcpServers(), isEmpty);
    },
    tags: const <String>[
      'feature_test__mcp_server_management__verticalSlice',
      'feature_test__mcp_tool_execution__verticalSlice',
    ],
  );

  test(
    'a server that cannot start leaves the daemon and its turns working',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-mcp-broken-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-mcp-broken-workspace-',
      );
      const bearerToken = 'mcp-broken-token-0123456789abcdef01234';
      await File(p.join(home.path, 'mcp.json')).writeAsString(
        jsonEncode(<String, dynamic>{
          'version': 1,
          'servers': <String, dynamic>{
            'broken': <String, dynamic>{
              'transport': 'stdio',
              'command': '/nonexistent/mcp-server',
            },
          },
        }),
      );
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'mcp-broken-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final coder = (await client.listAgentDefinitions()).single;
      await client.updateAgentDefinition(
        coder.copyWith(permissionMode: PermissionMode.workspaceWrite),
        expectedContentHash: coder.contentHash,
      );
      final session = await client.createSession(
        id: 'broken-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Broken',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-sol',
        ),
      );
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere(
            (event) =>
                event.sessionId == session.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'broken-turn',
        prompt: 'Write a file.',
      );
      await completed;
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );

      // The turn succeeded on built-in tools alone.
      expect(
        File(p.join(workspace.path, 'result.txt')).existsSync(),
        isTrue,
      );
      final broken = (await client.listMcpServers()).single;
      expect(broken.status, McpServerStatus.failed);
      expect(broken.error, isNotNull);
      expect(broken.tools, isEmpty);
    },
    tags: const <String>[
      'feature_test__mcp_server_management__verticalSlice',
      'feature_test__mcp_tool_execution__verticalSlice',
    ],
  );

  test(
    'skills merge across sources, drive a turn, and stay editable over RPC',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-skill-home-');
      final agentsHome = await Directory.systemTemp.createTemp(
        'coder-skill-agents-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-skill-workspace-',
      );
      const bearerToken = 'skill-token-0123456789abcdef0123456789';
      addTearDown(() async {
        await home.delete(recursive: true);
        await agentsHome.delete(recursive: true);
        await workspace.delete(recursive: true);
      });

      // A global skill in the shared `~/.agents` tree, shadowed by a project
      // skill with the same ID.
      await _writeSkill(
        p.join(agentsHome.path, '.agents', 'skills', 'shared'),
        description: 'From the user home.',
        body: 'Global instructions.',
      );
      await _writeSkill(
        p.join(workspace.path, '.agents', 'skills', 'shared'),
        description: 'From the project.',
        body: 'Project instructions.',
      );

      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          userHomeDirectory: agentsHome.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: _SkillProvider(),
      );
      addTearDown(handle.stop);
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'skill-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      expect(client.serverInfo.features['skills'], isTrue);

      final global = await client.listSkills();
      expect(
        global.map((skill) => skill.id),
        containsAll(<String>['coding-conventions', 'commit', 'shared']),
      );
      expect(
        global.singleWhere((skill) => skill.id == 'shared').description,
        'From the user home.',
      );

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final scoped = await client.listSkills(workspaceId: 'workspace');
      final projectSkill = scoped.singleWhere(
        (skill) => skill.id == 'shared' && !skill.isShadowed,
      );
      expect(projectSkill.source, SkillSource.project);
      expect(projectSkill.description, 'From the project.');
      expect(
        scoped
            .where((skill) => skill.id == 'shared' && skill.isShadowed)
            .single
            .source,
        SkillSource.userHome,
      );

      // Creating, editing, and deleting reach the daemon's own directory.
      final created = await client.createSkill(
        id: 'release',
        source: SkillSource.config,
        name: 'release',
        description: 'Ships a release.',
        body: 'Tag, build, publish.',
      );
      expect(
        File(p.join(home.path, 'skills', 'release', 'SKILL.md')).existsSync(),
        isTrue,
      );
      final updated = await client.updateSkill(
        created.copyWith(description: 'Ships a signed release.'),
        expectedContentHash: created.contentHash,
      );
      expect(updated.description, 'Ships a signed release.');
      await client.deleteSkill('release');
      expect(
        (await client.listSkills()).map((skill) => skill.id),
        isNot(contains('release')),
      );

      // The disabled skill must disappear from the catalog handed to a turn.
      await client.setSkillEnabled('commit', enabled: false);
      expect((await client.getSkill('commit')).isEnabled, isFalse);

      final session = await client.createSession(
        id: 'skill-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Skills',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-sol',
        ),
      );
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere(
            (event) =>
                event.sessionId == session.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'skill-turn',
        prompt: 'Use the shared skill.',
      );
      await completed;

      final timeline = await client.subscribeTimeline(session.id);
      final loaded = timeline
          .where((event) => event.type == 'tool.completed')
          .single;
      expect(loaded.data['name'], 'skill');
      expect(loaded.data['isError'], isFalse);
      // The worktree is the checkout itself, so the project skill wins.
      final output = loaded.data['output']! as String;
      expect(output, contains('Project instructions.'));
      expect(output, isNot(contains('Global instructions.')));
    },
    tags: const <String>[
      'feature_test__skill_management__verticalSlice',
      'feature_test__skill_invocation__verticalSlice',
    ],
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
      // The daemon canonicalizes every workspace path, and macOS reaches its
      // temporary directory through a /var symlink to /private/var, so the
      // fixture starts from the resolved path the daemon will report back.
      final repository = Directory(
        await (await Directory.systemTemp.createTemp(
          'coder-git-repository-',
        )).resolveSymbolicLinks(),
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

      expect(
        (await client.getProjectSettings('git-workspace')).settings,
        const ProjectSettingsDto(),
      );
      final teardownMarker = p.join(repository.path, 'teardown-ran');
      // Hooks run in the platform shell, so the fixture has to speak the one
      // it will actually get.
      final saved = await client.saveProjectSettings(
        'git-workspace',
        ProjectSettingsDto(
          setup: <String>[
            if (Platform.isWindows)
              'echo %CODER_BRANCH% > setup-ran'
            else
              r'printf "%s" "$CODER_BRANCH" > setup-ran',
          ],
          teardown: <String>[
            if (Platform.isWindows)
              'echo ran > $teardownMarker'
            else
              'printf ran > $teardownMarker',
          ],
        ),
      );
      expect(saved.sourcePath, p.join(repository.path, 'coder.json'));
      expect(File(saved.sourcePath).existsSync(), isTrue);

      final managed = await client.createWorktree(
        id: 'managed-worktree',
        workspaceId: 'git-workspace',
        mode: WorktreeCreateMode.newBranch,
        branchName: 'feature/vertical-slice',
        baseBranch: 'main',
      );
      expect(Directory(managed.worktree.path).existsSync(), isTrue);
      expect(managed.hookRuns.single.exitCode, 0);
      expect(managed.hookRuns.single.phase, WorktreeHookPhase.setup);
      expect(
        // cmd's echo appends a line break, so compare the written value.
        (await File(
          p.join(managed.worktree.path, 'setup-ran'),
        ).readAsString()).trim(),
        'feature-vertical-slice',
      );
      expect(
        (await client.refreshWorkspace('git-workspace')).worktrees,
        isNotEmpty,
      );
      final preview = await client.previewWorktreeArchive(
        managed.worktree.id,
      );
      expect(preview.removesDirectory, isTrue);
      final archived = await client.archiveWorktree(
        managed.worktree.id,
        force: true,
      );
      expect(archived.hookRuns.single.phase, WorktreeHookPhase.teardown);
      expect(archived.hookRuns.single.exitCode, 0);
      expect(File(teardownMarker).existsSync(), isTrue);
      expect(Directory(managed.worktree.path).existsSync(), isFalse);
      await client.unregisterWorkspace('git-workspace');
      expect((await client.getWorkspaceCatalog()).workspaces, isEmpty);
    },
    tags: const <String>[
      'feature_test__worktree_lifecycle__verticalSlice',
      'feature_test__project_settings__verticalSlice',
    ],
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

  test(
    'attachments stream through a remote client and survive daemon restart',
    tags: const <String>[
      'feature_test__conversation_attachments__verticalSlice',
    ],
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-attachment-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-attachment-workspace-',
      );
      await File(p.join(workspace.path, 'agent-result.txt')).writeAsString(
        'agent bytes',
      );
      const token = 'attachment-token-0123456789abcdef0123456789';
      final provider = _AttachmentProvider();
      final config = DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
        apiKey: 'test-api-key',
      );
      var handle = await DaemonApplication.start(config, provider: provider);
      var client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: token),
        clientId: 'attachment-integration',
        clientKind: 'test',
      );
      addTearDown(() async {
        await client.close();
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });

      final unauthorizedClient = HttpClient();
      final unauthorized = await unauthorizedClient.getUrl(
        handle.boundEndpoint.replace(
          scheme: 'http',
          path: '/attachments/missing',
        ),
      );
      expect(
        (await unauthorized.close()).statusCode,
        HttpStatus.unauthorized,
      );
      unauthorizedClient.close(force: true);

      final imageBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        1,
        2,
        3,
      ];
      final uploaded = await client.uploadAttachment(
        fileName: 'fixture.png',
        mimeType: 'image/png',
        byteSize: imageBytes.length,
        bytes: Stream<List<int>>.value(imageBytes),
      );
      expect(uploaded.kind, AttachmentKind.image);

      final catalog = await client.registerWorkspace(
        workspaceId: 'attachment-workspace',
        checkoutId: 'attachment-checkout',
        rootPath: workspace.path,
        name: 'Attachments',
      );
      final models = await client.listProviderModels('openai');
      final session = await client.createSession(
        id: 'attachment-session',
        worktreeId: catalog.worktrees.single.id,
        title: 'Attachment session',
        agentDefinitionId: 'coder',
        model: SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: models.first.id,
        ),
      );
      await client.subscribeTimeline(session.id);
      final completed = client.events
          .where((event) => event is TimelineClientEvent)
          .cast<TimelineClientEvent>()
          .map((event) => event.event)
          .firstWhere((event) => event.type == 'turn.completed')
          .timeout(_eventTimeout);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'attachment-turn',
        prompt: '',
        attachmentIds: <String>[uploaded.id],
      );
      await completed;

      final request = await provider.firstRequest.future;
      final input = request.history.whereType<UserConversationItem>().last;
      expect(input.text, isEmpty);
      expect(input.attachments.single.bytes, imageBytes);
      final timeline = await client.subscribeTimeline(session.id);
      final userMessage = timeline.singleWhere(
        (event) => event.type == 'user.message',
      );
      expect(userMessage.data['attachments'], hasLength(1));
      final userAttachment =
          (userMessage.data['attachments']! as List<Object?>).single!
              as Map<String, dynamic>;
      expect(userAttachment, isNot(contains('path')));
      expect(userAttachment, isNot(contains('bytes')));
      final outbound = timeline.singleWhere(
        (event) => event.type == 'assistant.attachment',
      );
      expect(outbound.data, isNot(contains('path')));
      expect(outbound.data, isNot(contains('bytes')));
      final outboundId = outbound.data['id']! as String;

      final imageDownload = await client.downloadAttachment(uploaded.id);
      expect(
        await imageDownload.bytes.expand((chunk) => chunk).toList(),
        imageBytes,
      );
      final outboundDownload = await client.downloadAttachment(outboundId);
      expect(
        utf8.decode(
          await outboundDownload.bytes.expand((chunk) => chunk).toList(),
        ),
        'agent bytes',
      );

      await client.close();
      await handle.stop();
      handle = await DaemonApplication.start(
        config,
        provider: _AttachmentProvider(),
      );
      client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: token),
        clientId: 'attachment-reconnect',
        clientKind: 'test',
      );
      final restored = await client.downloadAttachment(uploaded.id);
      expect(
        await restored.bytes.expand((chunk) => chunk).toList(),
        imageBytes,
      );
      expect(
        await client.subscribeTimeline(session.id),
        contains(
          predicate<TimelineEventDto>(
            (event) =>
                event.type == 'assistant.attachment' &&
                event.data['id'] == outboundId,
          ),
        ),
      );
    },
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

/// Waits until a session reports idle.
///
/// The `turn.completed` timeline event is broadcast before the session row
/// leaves the running state, so a mutation issued immediately after it can
/// still be rejected.
Future<void> _waitForIdleSession(
  CoderApi client,
  String worktreeId,
  String sessionId, {
  int attempts = 50,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    final session = (await client.listSessions(
      worktreeId: worktreeId,
    )).singleWhere((item) => item.id == sessionId);
    if (session.status != SessionStatus.running) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Timed out waiting for $sessionId to leave running.');
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
  // 50 attempts at 10ms allowed half a second for an entire OAuth round trip.
  for (var attempt = 0; attempt < 100; attempt += 1) {
    final current = await client.providerAuthStatus(attemptId);
    if (current.status == status) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
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

/// Locates the fake stdio MCP server, whichever directory the suite runs from.
///
/// melos runs the vertical slice from the workspace root while a package-level
/// `dart test` runs from the package, so neither path can be assumed.
String _fakeMcpServerPath() {
  const relative = <String>['test', 'support', 'fake_mcp_server_main.dart'];
  for (final root in <String>[
    Directory.current.path,
    p.join(Directory.current.path, 'packages', 'coder_daemon'),
  ]) {
    final candidate = p.join(root, p.joinAll(relative));
    if (File(candidate).existsSync()) return candidate;
  }
  fail('Could not locate fake_mcp_server_main.dart from ${Directory.current}.');
}

/// Polls until [serverId] reports itself ready, or the event budget expires.
Future<McpServerStateDto> _awaitReadyMcpServer(
  CoderApi client,
  String serverId, {
  String? worktreeId,
}) async {
  final deadline = DateTime.now().add(_eventTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final servers = await client.listMcpServers(worktreeId: worktreeId);
    for (final server in servers) {
      if (server.config.id != serverId) continue;
      if (server.status == McpServerStatus.ready) return server;
      if (server.status == McpServerStatus.failed) {
        // The server's own output is what explains a platform-specific
        // launch failure, so report it rather than just the summary.
        fail(
          'MCP server "$serverId" failed: ${server.error}\n'
          'diagnostics: ${server.diagnostics.join('\n')}',
        );
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  fail('MCP server "$serverId" never became ready.');
}

class _EchoingMcpProvider implements ModelProvider {
  var _round = 0;

  @override
  String get id => 'fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_round++ == 0) {
      const arguments = <String, dynamic>{'value': 'through MCP'};
      yield const ModelFunctionCall(
        callId: 'echo-call',
        name: 'mcp__fake__echo',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'echo-call',
              name: 'mcp__fake__echo',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Echoed.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Echoed.'),
    );
  }
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

final class _AttachmentProvider implements ModelProvider {
  final Completer<ModelRequest> firstRequest = Completer<ModelRequest>();

  @override
  String get id => 'attachment-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (!firstRequest.isCompleted) firstRequest.complete(request);
    final hasToolResult = request.history.any(
      (item) => item is ToolResultConversationItem,
    );
    if (!hasToolResult) {
      const arguments = <String, dynamic>{'path': 'agent-result.txt'};
      yield const ModelFunctionCall(
        callId: 'attach-call',
        name: 'attach_file',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'attach-call',
              name: 'attach_file',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Attached.'),
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

Future<void> _writeSkill(
  String directory, {
  required String description,
  required String body,
}) async {
  await Directory(directory).create(recursive: true);
  await File(p.join(directory, 'SKILL.md')).writeAsString(
    '---\n'
    'name: ${p.basename(directory)}\n'
    'description: $description\n'
    '---\n\n'
    '$body\n',
  );
}

/// Loads one skill through the `skill` tool, then finishes the turn.
final class _SkillProvider implements ModelProvider {
  @override
  String get id => 'skill-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final hasToolResult = request.history.any(
      (item) => item is ToolResultConversationItem,
    );
    if (!hasToolResult) {
      // The catalog is advertised in the instructions, and a disabled skill
      // must not appear there.
      expect(request.instructions, contains('- shared: From the project.'));
      expect(request.instructions, isNot(contains('- commit:')));
      const arguments = <String, dynamic>{'name': 'shared', 'resource': null};
      yield const ModelFunctionCall(
        callId: 'skill-call',
        name: 'skill',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'skill-call',
              name: 'skill',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Loaded the skill.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Loaded the skill.'),
    );
  }
}
