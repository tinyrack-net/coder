import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/openai/openai.dart';
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
    'daemon permission default survives a restart',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-permission-home-',
      );
      const token = 'permission-token-0123456789abcdef012345';
      final config = DaemonConfig(
        homeDirectory: home.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
      );
      try {
        final firstHandle = await DaemonApplication.start(config);
        final firstClient = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: firstHandle.boundEndpoint),
          credentials: const DaemonCredentials(bearerToken: token),
          clientId: 'permission-first',
          clientKind: 'test',
        );
        expect(
          (await firstClient.getDefaultPermissionMode()).defaultMode,
          PermissionMode.ask,
        );
        await firstClient.setDefaultPermissionMode(PermissionMode.fullAccess);
        await firstClient.close();
        await firstHandle.stop();

        final secondHandle = await DaemonApplication.start(config);
        final secondClient = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: secondHandle.boundEndpoint),
          credentials: const DaemonCredentials(bearerToken: token),
          clientId: 'permission-second',
          clientKind: 'test',
        );
        expect(
          (await secondClient.getDefaultPermissionMode()).defaultMode,
          PermissionMode.fullAccess,
        );
        await secondClient.close();
        await secondHandle.stop();
      } finally {
        await home.delete(recursive: true);
      }
    },
    tags: const <String>['feature_test__permission_settings__verticalSlice'],
  );

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
          // A temporary directory stands in for the machine home so the test
          // never depends on the home of whoever runs it.
          osHomeDirectory: workspace.path,
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
      // The handshake carries the browsing home so the app can open a picker
      // there instead of at the drive root.
      expect(client.serverInfo.homeDirectory, workspace.path);
      expect(
        (await client.getDefaultPermissionMode()).defaultMode,
        PermissionMode.ask,
      );
      await client.setDefaultPermissionMode(PermissionMode.fullAccess);
      expect(
        (await client.getDefaultPermissionMode()).defaultMode,
        PermissionMode.fullAccess,
      );
      await client.setDefaultPermissionMode(PermissionMode.ask);
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
          wireFormatId: openAIChatCompletionsWireId,
          authenticationRequired: false,
          models: const <ManualProviderModelDto>[
            ManualProviderModelDto(id: 'test-model', label: 'test-model'),
          ],
        ),
      );
      expect(custom.status, ProviderConnectionStatus.connected);
      expect(custom.authKind, ProviderAuthKind.none);
      expect(
        (await client.listProviderConnections())
            .singleWhere((connection) => connection.id == custom.id)
            .id,
        custom.id,
      );
      expect(
        (await client.listProviderModels(custom.id)).map((item) => item.id),
        containsAll(<String>[
          'local-test/test-model',
          'local-test/discovered-model',
        ]),
      );
      final updatedCustom = await client.updateCustomProvider(
        custom.id,
        CustomProviderConfigDto(
          name: 'Updated local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          wireFormatId: openAIChatCompletionsWireId,
          authenticationRequired: false,
          models: const <ManualProviderModelDto>[
            ManualProviderModelDto(id: 'test-model', label: 'test-model'),
          ],
        ),
      );
      expect(updatedCustom.displayName, 'Updated local test');
      final temporary = await client.createCustomProvider(
        'temporary',
        CustomProviderConfigDto(
          name: 'Temporary',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          wireFormatId: openAIResponsesWireId,
          authenticationRequired: false,
          models: const <ManualProviderModelDto>[
            ManualProviderModelDto(id: 'test-model', label: 'test-model'),
          ],
        ),
      );
      expect(temporary.id, isNot('temporary'));
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

      final projectShell = ShellSpecDto(
        executable: Platform.isWindows ? 'cmd.exe' : '/bin/sh',
      );
      await client.setTerminalShell(
        const ShellSpecDto(executable: '/definitely/missing-shell'),
      );
      expect(
        await client.getTerminalShell(),
        const ShellSpecDto(executable: '/definitely/missing-shell'),
      );
      await client.saveProjectSettings(
        registered.workspace.id,
        ProjectSettingsDto(shell: projectShell),
      );
      final terminal = await client.createTerminal(
        id: 'terminal-1',
        worktreeId: checkout.id,
        title: 'Terminal 1',
        columns: 80,
        rows: 24,
      );
      expect(terminal.shell, projectShell);
      expect(
        (await client.listTerminals(checkout.id)).map((item) => item.id),
        contains(terminal.id),
      );
      final attached = await client.attachTerminal(terminal.id);
      expect(attached.terminal.id, terminal.id);
      const marker = 'coder-terminal-ready';
      final output = client.terminals.output
          .where((output) => output.terminalId == terminal.id)
          .map((output) => output.data)
          .firstWhere((data) => data.contains(marker))
          .timeout(_eventTimeout);
      await client.resizeTerminal(terminal.id, columns: 100, rows: 30);
      await client.writeTerminal(
        terminal.id,
        Platform.isWindows ? 'echo $marker\r' : "printf '$marker\\n'\r",
      );
      expect(await output, contains(marker));
      await client.terminateTerminal(terminal.id);

      // The built-in agent picks no model of its own, so creation now falls
      // back to the daemon default and leaves the session without an override.
      expect(await client.getDefaultModel(), isNull);
      const wireDefault = SessionModelSelectionDto(
        modelId: 'local-test/test-model',
      );
      await client.setDefaultModel(wireDefault);
      expect(await client.getDefaultModel(), wireDefault);
      final inherited = await client.createSession(
        id: 'model-inherited',
        worktreeId: checkout.id,
        title: 'Model inherited',
        agentDefinitionId: 'coder',
      );
      expect(inherited.model, isNull);
      await client.setDefaultModel(null);
      expect(await client.getDefaultModel(), isNull);
      await expectLater(
        client.createSession(
          id: 'agent-rejected',
          worktreeId: checkout.id,
          title: 'Rejected',
          agentDefinitionId: 'coder',
          model: const SessionModelSelectionDto(
            modelId: 'missing-connection/test-model',
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
          modelId: 'local-test/test-model',
        ),
      );
      expect(agent.status, SessionStatus.idle);
      expect(
        agent.model,
        const SessionModelSelectionDto(
          modelId: 'local-test/test-model',
        ),
      );
      expect(
        (await client.sessions.listSessions(
          worktreeId: checkout.id,
        )).singleWhere((session) => session.id == agent.id).model,
        agent.model,
      );
      expect(agent.mode, SessionMode.plan);
      final normalFuture = client.sessions.sessionUpdates
          .firstWhere((session) => session.mode == SessionMode.normal)
          .timeout(_eventTimeout);
      expect(
        (await client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(mode: SessionMode.normal),
        )).mode,
        SessionMode.normal,
      );
      expect((await normalFuture).id, agent.id);
      expect(
        (await client.sessions.listSessions(
          worktreeId: checkout.id,
        )).singleWhere((session) => session.id == agent.id).mode,
        SessionMode.normal,
      );
      final coder = (await client.listAgentDefinitions()).single;
      final configuredDefinition = await client.updateAgentDefinition(
        coder.copyWith(
          model: const AgentModelSelectionDto(
            source: AgentModelSource.fixed,
            modelId: 'local-test/test-model',
          ),
          modelControls: const <String, ModelControlValueDto>{},
        ),
        expectedContentHash: coder.contentHash,
      );
      expect(configuredDefinition.model.source, AgentModelSource.fixed);
      expect(
        await client.sessions.listSessions(worktreeId: checkout.id),
        hasLength(2),
      );
      expect(await client.subscribeTimeline(agent.id), isEmpty);

      final approvalFuture = client.sessions.approvalRequests.first.timeout(
        _eventTimeout,
      );
      final completedFuture = client.sessions.timelineEvents
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
        configuredDefinition.copyWith(
          modelControls: const <String, ModelControlValueDto>{},
        ),
        expectedContentHash: configuredDefinition.contentHash,
      );
      expect(afterTurn.modelControls, isEmpty);

      expect(
        (await client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(
            hasModel: true,
            model: SessionModelSelectionDto(
              modelId: 'local-test/test-model',
            ),
          ),
        )).model,
        const SessionModelSelectionDto(
          modelId: 'local-test/test-model',
        ),
      );
      // Clearing the override is always legal now: the model resolves through
      // the fallback chain when the turn starts.
      expect(
        (await client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(hasModel: true),
        )).model,
        isNull,
      );
      expect(
        (await client.sessions.updateSettings(
          agent.id,
          SessionSettingsPatchDto(hasModel: true, model: agent.model),
        )).model,
        agent.model,
      );
      expect(
        (await client.sessions.listSessions(
          worktreeId: checkout.id,
        )).singleWhere((session) => session.id == agent.id).model,
        agent.model,
      );
      await expectLater(
        client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(
            hasModel: true,
            model: SessionModelSelectionDto(
              modelId: 'local-test/missing-model',
            ),
          ),
        ),
        throwsA(isA<CoderClientException>()),
      );

      // Model controls are persisted atomically with other session settings.
      expect(
        (await client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(
            hasPermissionMode: true,
            permissionMode: PermissionMode.workspaceWrite,
          ),
        )).permissionMode,
        PermissionMode.workspaceWrite,
      );
      final withControls = await client.sessions.updateSettings(
        agent.id,
        const SessionSettingsPatchDto(
          hasModelControls: true,
        ),
      );
      expect(withControls.modelControls, isEmpty);
      final overridden = (await client.sessions.listSessions(
        worktreeId: checkout.id,
      )).singleWhere((session) => session.id == agent.id);
      expect(overridden.modelControls, isEmpty);
      expect(overridden.permissionMode, PermissionMode.workspaceWrite);
      expect(
        (await client.sessions.updateSettings(
          agent.id,
          const SessionSettingsPatchDto(hasPermissionMode: true),
        )).permissionMode,
        isNull,
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
      await client.disconnectProvider(custom.id);
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
        (await client.sessions.listSessions(
          worktreeId: checkout.id,
        )).singleWhere((session) => session.id == agent.id).status,
        SessionStatus.idle,
      );
    },
    tags: const <String>[
      'feature_test__workspace_catalog__verticalSlice',
      'feature_test__workspace_registration__verticalSlice',
      'feature_test__session_lifecycle__verticalSlice',
      'feature_test__terminal_lifecycle__verticalSlice',
      'feature_test__terminal_settings__verticalSlice',
      'feature_test__turn_execution__verticalSlice',
      'feature_test__provider_catalog__verticalSlice',
      'feature_test__provider_connection_management__verticalSlice',
      'feature_test__provider_custom__verticalSlice',
      'feature_test__provider_default_model__verticalSlice',
      'feature_test__permission_settings__verticalSlice',
    ],
  );

  test(
    'spawn_agent runs a subagent asynchronously and mails back a final answer',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-spawn-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-spawn-workspace-',
      );
      final provider = _CollaboratingProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'spawn-token-0123456789abcdef01234567',
          useEnvironmentCredentials: false,
        ),
        provider: provider,
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'spawn-token-0123456789abcdef01234567',
        ),
        clientId: 'spawn-test',
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
          toolIds: <String>[...coder.toolIds, 'collaboration'],
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
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      final timelineEvents = client.sessions.timelineEvents;
      final parentCompleted = timelineEvents
          .firstWhere(
            (event) =>
                event.sessionId == parent.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
      // The child session ID is unknown before the spawn, so completion is
      // detected through the parent's FINAL_ANSWER mail event.
      final finalAnswerMailed = timelineEvents
          .firstWhere(
            (event) =>
                event.sessionId == parent.id &&
                event.type == 'agent.mail' &&
                ((event.data['mail'] as Map<String, dynamic>?)?['type']
                        as String?) ==
                    'finalAnswer',
          )
          .timeout(_eventTimeout);
      await client.subscribeTimeline(parent.id);
      await client.startTurn(
        sessionId: parent.id,
        turnId: 'parent-turn',
        prompt: 'Review this workspace.',
      );
      // The parent turn completes without blocking on the child.
      await parentCompleted;
      await finalAnswerMailed;

      final tree = await client.listSubagents(parent.id);
      expect(tree.first.id, parent.id);
      final child = tree.singleWhere(
        (session) => session.origin == SessionOrigin.delegated,
      );
      expect(child.parentSessionId, parent.id);
      expect(child.rootSessionId, parent.id);
      expect(child.taskName, 'review_task');
      expect(child.agentPath, '/root/review_task');
      expect(child.lifecycle, AgentLifecycle.completed);
      expect(child.agentDefinitionId, reviewer.id);
      expect(child.model, parent.model);

      // The read-only clamp still denies the child's write attempt.
      final childTimeline = await client.subscribeTimeline(child.id);
      expect(childTimeline.map((event) => event.type), contains('agent.mail'));
      expect(childTimeline.map((event) => event.type), contains('tool.denied'));
      expect(
        childTimeline
            .where((event) => event.type == 'tool.requested')
            .single
            .data['name'],
        'apply_patch',
      );
      final parentTimeline = await client.subscribeTimeline(parent.id);
      expect(
        parentTimeline
            .where((event) => event.type == 'agent.spawned')
            .single
            .data['agentPath'],
        '/root/review_task',
      );

      // The parent's next turn folds the FINAL_ANSWER envelope into the
      // model request at its first message boundary.
      final secondCompleted = timelineEvents
          .firstWhere(
            (event) =>
                event.sessionId == parent.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);
      await client.startTurn(
        sessionId: parent.id,
        turnId: 'parent-turn-2',
        prompt: 'What did the reviewer say?',
      );
      await secondCompleted;
      expect(
        provider.requests.any(
          (request) => request.history.whereType<UserConversationItem>().any(
            (item) =>
                item.text.startsWith('Message Type: FINAL_ANSWER') &&
                item.text.contains('Review completed.'),
          ),
        ),
        isTrue,
      );

      // `turn.completed` is emitted before the runner reports the idle
      // status, so the tree has to be observed at rest before teardown
      // closes the database under a turn that is still writing.
      final worktreeId = registered.worktrees.single.id;
      await _waitForIdleSession(client, worktreeId, parent.id);
      await _waitForIdleSession(client, worktreeId, child.id);
    },
    tags: const <String>['feature_test__agent_collaboration__verticalSlice'],
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'spawn_agent rejects an agent_type outside the caller allowlist',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-reject-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-reject-workspace-',
      );
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'reject-token-0123456789abcdef0123456',
          useEnvironmentCredentials: false,
        ),
        provider: _CollaboratingProvider(agentType: 'stranger'),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'reject-token-0123456789abcdef0123456',
        ),
        clientId: 'reject-test',
        clientKind: 'test',
      );
      addTearDown(client.close);
      final coder = (await client.listAgentDefinitions()).single;
      await client.updateAgentDefinition(
        coder.copyWith(toolIds: <String>[...coder.toolIds, 'collaboration']),
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
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      final completed = client.sessions.timelineEvents
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

      expect(await client.listSubagents(parent.id), hasLength(1));
      final timeline = await client.subscribeTimeline(parent.id);
      final spawnResult = timeline
          .where((event) => event.type == 'tool.completed')
          .single;
      expect(spawnResult.data['isError'], isTrue);
      expect(spawnResult.data['output'], contains('not allowed'));

      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        parent.id,
      );
    },
    tags: const <String>['feature_test__agent_collaboration__verticalSlice'],
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
      expect(await client.mcp.listMcpServers(), isEmpty);

      final changed = client.mcp.serverChanges.first.timeout(_eventTimeout);
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
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      // A dangerous tool always asks, even under workspaceWrite.
      final approvalFuture = client.sessions.approvalRequests.first.timeout(
        _eventTimeout,
      );
      final completed = client.sessions.timelineEvents
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
      expect(await client.mcp.listMcpServers(), isEmpty);
    },
    tags: const <String>[
      'feature_test__mcp_server_management__verticalSlice',
      'feature_test__mcp_tool_execution__verticalSlice',
    ],
  );

  test(
    'a project .coder/config.json publishes tools only in its worktree',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'coder-mcp-project-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-mcp-project-',
      );
      const bearerToken = 'mcp-project-token-0123456789abcdef0123';
      final projectConfig = File(
        p.join(workspace.path, '.coder', 'config.json'),
      );
      await projectConfig.parent.create(recursive: true);
      await projectConfig.writeAsString(
        jsonEncode(<String, dynamic>{
          'schemaVersion': 4,
          'mcp': <String, dynamic>{
            'servers': <String, dynamic>{
              'repo': <String, dynamic>{
                'transport': 'stdio',
                'command': Platform.resolvedExecutable,
                'args': <String>[_fakeMcpServerPath()],
              },
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
      await client.mcp.listMcpServers(worktreeId: worktreeId);
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
        p.join(registered.worktrees.single.path, '.coder', 'config.json'),
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
      expect(await client.mcp.listMcpServers(), isEmpty);
    },
    tags: const <String>[
      'feature_test__mcp_server_management__verticalSlice',
      'feature_test__mcp_tool_execution__verticalSlice',
    ],
  );

  // Both transports are production paths — pipes for ordinary commands, a
  // pseudo-terminal for the interactive ones — so both are proved against a
  // real daemon and a real process rather than only the default.
  for (final tty in <bool>[false, true]) {
    final transport = tty ? 'pseudo-terminal' : 'pipes';
    test(
      'exec_command drives a real $transport across two tool calls',
      () async {
        final home = await Directory.systemTemp.createTemp('coder-exec-home-');
        final workspace = await Directory.systemTemp.createTemp(
          'coder-exec-workspace-',
        );
        const bearerToken = 'exec-command-token-0123456789abcdef012';
        final provider = _ExecProvider(tty: tty);
        final handle = await DaemonApplication.start(
          DaemonConfig(
            homeDirectory: home.path,
            port: 0,
            bearerToken: bearerToken,
            useEnvironmentCredentials: false,
          ),
          provider: provider,
        );
        addTearDown(() async {
          await handle.stop();
          await home.delete(recursive: true);
          await workspace.delete(recursive: true);
        });
        final client = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
          credentials: const DaemonCredentials(bearerToken: bearerToken),
          clientId: 'exec-command-test',
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
          id: 'exec-session',
          worktreeId: registered.worktrees.single.id,
          title: 'Exec',
          agentDefinitionId: 'coder',
          model: const SessionModelSelectionDto(
            modelId: 'openai/gpt-5.6-sol',
          ),
        );
        await client.subscribeTimeline(session.id);
        // Running a command always asks; approving the first one is what makes
        // every later write into that same session pass without another dialog.
        final approvals = <String>[];
        final approvalSubscription = client.sessions.approvalRequests.listen((
          approval,
        ) {
          approvals.add(approval.toolName);
          unawaited(
            client.resolveApproval(
              approvalId: approval.id,
              approved: true,
            ),
          );
        });
        addTearDown(approvalSubscription.cancel);
        await client.startTurn(
          sessionId: session.id,
          turnId: 'exec-turn',
          prompt: 'Run the shell',
        );

        // A command that outlives the first call hands back an id the second
        // call writes into, and the echoed text proves the same process
        // answered.
        final seen = await provider.echoed.future.timeout(_eventTimeout);
        expect(seen, contains('tinyrack-exec-probe'));
        expect(approvals, <String>['exec_command']);
        await _waitForIdleSession(
          client,
          registered.worktrees.single.id,
          session.id,
        );
      },
      tags: const <String>['feature_test__tool_exec_session__verticalSlice'],
      // Both transports run a POSIX shell; Windows uses PowerShell instead.
      testOn: '!windows',
    );
  }

  test(
    'view_image puts a hydrated workspace image into the model context',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-image-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-image-workspace-',
      );
      // A one-pixel PNG, valid down to its magic bytes.
      await File(p.join(workspace.path, 'shot.png')).writeAsBytes(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      ]);
      const bearerToken = 'view-image-token-0123456789abcdef01234';
      final provider = _ViewImageProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: provider,
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'view-image-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final session = await client.createSession(
        id: 'image-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Image',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'image-turn',
        prompt: 'Look at the screenshot',
      );

      final request = await provider.secondRequest.future.timeout(
        _eventTimeout,
      );
      final injected = request.history
          .whereType<UserConversationItem>()
          .last
          .attachments
          .single;
      expect(injected.mimeType, 'image/png');
      expect(injected.imageDetail, 'high');
      // The bytes are hydrated, so the provider can actually encode the image.
      expect(injected.bytes, isNotNull);
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );
    },
    tags: const <String>['feature_test__tool_image_context__verticalSlice'],
  );

  test(
    'a sleeping agent wakes early when the client queues input',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-sleep-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-sleep-workspace-',
      );
      const bearerToken = 'sleep-tool-token-0123456789abcdef01234';
      final provider = _SleepProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: provider,
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'sleep-tool-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final session = await client.createSession(
        id: 'sleep-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Sleep',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'sleep-turn',
        prompt: 'Wait for the build',
      );

      // The agent asked to wait five minutes; the queued prompt must cut it
      // short, so the turn finishing at all proves the signal arrived.
      await provider.sleeping.future.timeout(_eventTimeout);
      await client.notePendingInput(session.id);

      final outcome = await provider.outcome.future.timeout(_eventTimeout);
      expect(outcome, 'interrupted');
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );
    },
    tags: const <String>['feature_test__tool_clock__verticalSlice'],
  );

  test(
    'new_context discards the stored history but keeps the timeline',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-reset-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-reset-workspace-',
      );
      const bearerToken = 'reset-tool-token-0123456789abcdef01234';
      final provider = _ContextResetProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: provider,
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'reset-tool-test',
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
      final session = await client.createSession(
        id: 'reset-session',
        worktreeId: worktreeId,
        title: 'Reset',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'reset-turn-one',
        prompt: 'Remember the release date.',
      );
      await _waitForIdleSession(client, worktreeId, session.id);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'reset-turn-two',
        prompt: 'Start fresh.',
      );
      await _waitForIdleSession(client, worktreeId, session.id);

      // The request made after the reset is the whole point: it must carry the
      // assistant item that called new_context and that call's own output, and
      // nothing from the retired window.
      expect(provider.requests, hasLength(3));
      final afterReset = provider.requests[2];
      expect(
        afterReset.whereType<UserConversationItem>(),
        isEmpty,
        reason: 'the retired window must not be replayed',
      );
      final calls = afterReset
          .whereType<AssistantConversationItem>()
          .expand((item) => item.toolCalls)
          .map((call) => call.callId)
          .toList();
      final outputs = afterReset
          .whereType<ToolResultConversationItem>()
          .map((item) => item.callId)
          .toList();
      expect(calls, <String>['reset-call']);
      expect(
        outputs,
        calls,
        reason: 'both provider APIs reject an orphaned function_call_output',
      );

      // The user still sees everything; only the model forgot.
      final timeline = await client.subscribeTimeline(session.id);
      expect(
        timeline.map((event) => event.turnId).toSet(),
        containsAll(<String>['reset-turn-one', 'reset-turn-two']),
      );
      expect(timeline.map((event) => event.type), contains('context.reset'));

      // The meter is back to zero even though the first turn reported usage.
      final refreshed = await client.sessions.listSessions(
        worktreeId: worktreeId,
      );
      expect(
        refreshed.firstWhere((item) => item.id == session.id).contextTokens,
        0,
      );
    },
    tags: const <String>['feature_test__tool_context_budget__verticalSlice'],
  );

  test(
    'compacting a session replaces its window with a summary',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-compact-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-compact-workspace-',
      );
      const bearerToken = 'compact-token-0123456789abcdef0123456';
      final provider = _CompactingProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: provider,
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'compact-test',
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
      final session = await client.createSession(
        id: 'compact-session',
        worktreeId: worktreeId,
        title: 'Compact',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'compact-turn-one',
        prompt: 'Remember the release date.',
      );
      await _waitForIdleSession(client, worktreeId, session.id);

      await client.compactSession(session.id);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'compact-turn-two',
        prompt: 'What was it?',
      );
      await _waitForIdleSession(client, worktreeId, session.id);

      // Request 0 is the first turn, 1 is the summary request, 2 is the turn
      // that resumes on the compacted window.
      expect(provider.requests, hasLength(3));
      expect(
        provider.requests[1].last,
        isA<UserConversationItem>().having(
          (item) => item.text,
          'text',
          CompactionPolicy.summarizationPrompt,
        ),
      );

      final resumed = provider.requests[2];
      expect(
        resumed.map((item) => (item as UserConversationItem).text),
        <String>[
          'Remember the release date.',
          '${CompactionPolicy.summaryPrefix}\nThe release date is Tuesday.',
          'What was it?',
        ],
      );
      // The assistant turn it replaced is gone from the model's view.
      expect(resumed.whereType<AssistantConversationItem>(), isEmpty);

      // The user still sees the original exchange.
      final timeline = await client.subscribeTimeline(session.id);
      expect(
        timeline.map((event) => event.type),
        contains('context.compacted'),
      );
      expect(
        timeline.map((event) => event.turnId),
        contains('compact-turn-one'),
      );
    },
    tags: const <String>['feature_test__context_compaction__verticalSlice'],
  );

  test(
    'search_text and glob honour a real .gitignore in a real workspace',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-search-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-search-workspace-',
      );
      await Directory(p.join(workspace.path, 'generated')).create();
      await File(
        p.join(workspace.path, '.gitignore'),
      ).writeAsString('generated/\n*.log\n');
      await File(
        p.join(workspace.path, 'main.dart'),
      ).writeAsString('const marker = 1;\n');
      await File(
        p.join(workspace.path, 'generated', 'out.dart'),
      ).writeAsString('const marker = 2;\n');
      await File(
        p.join(workspace.path, 'notes.log'),
      ).writeAsString('marker\n');
      const bearerToken = 'search-tool-token-0123456789abcdef0123';
      final provider = _SearchProvider();
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: provider,
        // Without this the daemon would consult whatever global git excludes
        // the machine running the test happens to have.
        gitignoreEnvironment: const GitignoreEnvironment.none(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'search-tool-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final session = await client.createSession(
        id: 'search-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Search',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);
      await client.startTurn(
        sessionId: session.id,
        turnId: 'search-turn',
        prompt: 'Find the marker',
      );

      final results = await provider.results.future.timeout(_eventTimeout);
      final matches = results.search['matches']! as List;
      // The ignored copies of the marker are not reachable, so the model sees
      // exactly the file a developer would expect.
      expect(
        matches.map((match) => (match! as Map<String, dynamic>)['path']),
        <String>['main.dart'],
      );
      expect(results.search['truncated'], isFalse);
      expect(results.glob['paths'], <String>['main.dart']);
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );
    },
    tags: const <String>['feature_test__tool_search__verticalSlice'],
  );

  test(
    'an agent question blocks the turn until the user answers it',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-ask-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-ask-workspace-',
      );
      const bearerToken = 'ask-user-token-0123456789abcdef0123456';
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
        provider: _AskingProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'ask-user-test',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'workspace',
        checkoutId: 'checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final session = await client.createSession(
        id: 'ask-session',
        worktreeId: registered.worktrees.single.id,
        title: 'Ask',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      await client.subscribeTimeline(session.id);

      final questionFuture = client.sessions.questionRequests.first.timeout(
        _eventTimeout,
      );
      final waitingFuture = client.sessions.sessionUpdates
          .firstWhere(
            (updated) =>
                updated.id == session.id &&
                updated.status == SessionStatus.waitingForInput,
          )
          .timeout(_eventTimeout);
      final completedFuture = client.sessions.timelineEvents
          .firstWhere(
            (event) =>
                event.sessionId == session.id && event.type == 'turn.completed',
          )
          .timeout(_eventTimeout);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'ask-turn',
        prompt: 'Decide the store',
      );

      final question = await questionFuture;
      expect(question.toolCallId, 'ask-call');
      expect(question.status, UserQuestionStatus.pending);
      expect(question.questions.single.header, 'Storage');
      expect(question.questions.single.options, hasLength(2));
      await waitingFuture;

      // Every question must be answered before the turn may continue.
      await expectLater(
        client.answerUserQuestion(
          requestId: question.id,
          answers: const <UserQuestionAnswerDto>[],
        ),
        throwsA(isA<CoderClientException>()),
      );

      const answers = <UserQuestionAnswerDto>[
        UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'Postgres',
          isFreeForm: true,
        ),
      ];
      final answered = await client.answerUserQuestion(
        requestId: question.id,
        answers: answers,
      );
      expect(answered.status, UserQuestionStatus.answered);
      expect(answered.answers, answers);

      // The same question cannot be answered twice.
      await expectLater(
        client.answerUserQuestion(requestId: question.id, answers: answers),
        throwsA(isA<CoderClientException>()),
      );

      await completedFuture;
      await _waitForIdleSession(
        client,
        registered.worktrees.single.id,
        session.id,
      );

      final events = await client.subscribeTimeline(session.id);
      expect(
        events.map((event) => event.type),
        containsAll(<String>[
          'userQuestion.requested',
          'userQuestion.answered',
        ]),
      );
      final result = events.firstWhere(
        (event) =>
            event.type == 'tool.completed' && event.data['name'] == 'ask_user',
      );
      // The chosen answer reaches the model as the tool's output.
      expect(result.data['output'], contains('Postgres'));
    },
    tags: const <String>['feature_test__turn_question__verticalSlice'],
    timeout: const Timeout(Duration(minutes: 1)),
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
      await Directory(p.join(home.path, 'v4')).create();
      await File(p.join(home.path, 'v4', 'config.json')).writeAsString(
        jsonEncode(<String, dynamic>{
          'schemaVersion': 4,
          'mcp': <String, dynamic>{
            'servers': <String, dynamic>{
              'broken': <String, dynamic>{
                'transport': 'stdio',
                'command': '/nonexistent/mcp-server',
              },
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
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      final completed = client.sessions.timelineEvents
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
      final broken = (await client.mcp.listMcpServers()).single;
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
        File(
          p.join(home.path, 'v4', 'skills', 'release', 'SKILL.md'),
        ).existsSync(),
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
          modelId: 'openai/gpt-5.6-sol',
        ),
      );
      final completed = client.sessions.timelineEvents
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
          .firstWhere((event) => event.data['name'] == 'skill');
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
      expect(
        File('${home.path}/v4/agents/reviewer.md').existsSync(),
        isTrue,
      );
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
          systemHelloProcedure.name,
          const HelloParamsDto(
            clientId: 'obsolete-client',
            clientKind: 'test',
            protocolMajor: 2,
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
      final rawChannel = IOWebSocketChannel.connect(
        handle.boundEndpoint,
        headers: const <String, dynamic>{
          'Authorization': 'Bearer remote-token-0123456789abcdef0123456789',
        },
      );
      await rawChannel.ready;
      final rawPeer = json_rpc.Peer(rawChannel.cast<String>());
      unawaited(rawPeer.listen());
      await rawPeer.sendRequest(
        systemHelloProcedure.name,
        const HelloParamsDto(
          clientId: 'raw-client',
          clientKind: 'test',
          protocolMajor: coderProtocolMajor,
          capabilities: <String, bool>{},
        ).toJson(),
      );
      await expectLater(
        rawPeer.sendRequest('sessions.unknown', const <String, dynamic>{}),
        throwsA(
          isA<json_rpc.RpcException>().having(
            (error) => (error.data! as Map<String, dynamic>)['code'],
            'typed code',
            'unknown_method',
          ),
        ),
      );
      await rawPeer.close();
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
          wireFormatId: openAIChatCompletionsWireId,
          authenticationRequired: false,
        ),
      );
      expect(connection.id, isNot('denied'));
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
    'real daemon runs a session that belongs to no project in the user home',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-home-state-');
      // The daemon canonicalizes every workspace path, and macOS reaches its
      // temporary directory through a /var symlink, so the fixture starts from
      // the resolved path the daemon will report back.
      final userHome = Directory(
        await (await Directory.systemTemp.createTemp(
          'coder-user-home-',
        )).resolveSymbolicLinks(),
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
            ],
          }),
        );
        await request.response.close();
      });
      DaemonConfig config() => DaemonConfig(
        homeDirectory: home.path,
        userHomeDirectory: userHome.path,
        port: 0,
        bearerToken: 'home-token-0123456789abcdef0123456789',
        useEnvironmentCredentials: false,
      );
      var handle = await DaemonApplication.start(
        config(),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        await home.delete(recursive: true);
        await userHome.delete(recursive: true);
        await modelServer.close(force: true);
      });
      Future<CoderClient> connect() async {
        final client = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
          credentials: DaemonCredentials(bearerToken: handle.bearerToken),
          clientId: 'home-vertical-slice',
          clientKind: 'test',
        );
        addTearDown(client.close);
        return client;
      }

      var client = await connect();
      final catalog = await client.getWorkspaceCatalog();
      final homeWorkspace = catalog.workspaces.singleWhere(
        (item) => item.kind == WorkspaceKind.home,
      );
      expect(homeWorkspace.rootPath, userHome.path);
      final homeCheckout = catalog.worktrees.singleWhere(
        (item) => item.workspaceId == homeWorkspace.id,
      );
      expect(homeCheckout.kind, WorktreeKind.directory);
      expect(homeCheckout.path, userHome.path);
      expect(homeCheckout.isCoderOwned, isFalse);

      // The daemon owns this workspace, so clients must not be able to drop it
      // and orphan every session that belongs to no project.
      await expectLater(
        client.unregisterWorkspace(homeWorkspace.id),
        throwsA(isA<CoderClientException>()),
      );
      await expectLater(
        client.archiveWorktree(homeCheckout.id, force: true),
        throwsA(isA<CoderClientException>()),
      );
      await expectLater(
        client.registerWorkspace(
          workspaceId: 'shadow-home',
          checkoutId: 'shadow-home-checkout',
          rootPath: userHome.path,
          name: 'Home again',
        ),
        throwsA(isA<CoderClientException>()),
      );

      await client.createCustomProvider(
        'local-test',
        CustomProviderConfigDto(
          name: 'Local test',
          baseUrl: 'http://127.0.0.1:${modelServer.port}/v1',
          wireFormatId: openAIChatCompletionsWireId,
          authenticationRequired: false,
          models: const <ManualProviderModelDto>[
            ManualProviderModelDto(id: 'test-model', label: 'test-model'),
          ],
        ),
      );
      final session = await client.createSession(
        id: 'home-session',
        worktreeId: homeCheckout.id,
        title: 'No project',
        agentDefinitionId: 'coder',
        model: const SessionModelSelectionDto(
          modelId: 'local-test/test-model',
        ),
      );
      expect(session.worktreeId, homeCheckout.id);
      expect(
        (await client.sessions.listSessions(
          worktreeId: homeCheckout.id,
        )).single.id,
        'home-session',
      );

      // Re-provisioning happens on every boot, so a restart must reuse the same
      // workspace and checkout rather than forking a second home.
      await handle.stop();
      handle = await DaemonApplication.start(
        config(),
        provider: _PatchProvider(),
      );
      client = await connect();
      final restarted = await client.getWorkspaceCatalog();
      expect(
        restarted.workspaces.where((item) => item.kind == WorkspaceKind.home),
        hasLength(1),
      );
      expect(restarted.workspaces.single.id, homeWorkspace.id);
      expect(restarted.worktrees.single.id, homeCheckout.id);
      expect(
        (await client.sessions.listSessions(
          worktreeId: homeCheckout.id,
        )).single.id,
        'home-session',
      );
    },
    tags: const <String>['feature_test__session_home__verticalSlice'],
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
      expect(
        saved.sourcePath,
        p.join(repository.path, '.coder', 'config.json'),
      );
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
        modelDiscovery: const _CredentialAwareDiscovery(),
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

      final rejected = await client.connectProviderApiKey(
        'deepseek',
        'invalid-key',
      );
      expect(rejected.status, ProviderConnectionStatus.error);
      final corrected = await client.connectProviderApiKey(
        'deepseek',
        'valid-key',
        connectionId: rejected.id,
      );
      expect(corrected.id, rejected.id);
      expect(corrected.status, ProviderConnectionStatus.connected);
      await client.disconnectProvider(corrected.id);

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
      final connected = (await client.listProviderConnections()).singleWhere(
        (connection) => connection.definitionId == 'openai',
      );
      expect(connected.credentialOrigin, ProviderCredentialOrigin.oauth);
      // The Codex endpoint has no `/models` listing, so the connection must
      // settle on the bundled catalog instead of degrading on a discovery 400.
      expect(connected.status, ProviderConnectionStatus.connected);
      expect(connected.error, isNull);
      final oauthModels = (await client.listProviderModels(
        connected.id,
      )).map((model) => model.id);
      expect(oauthModels, contains('openai/gpt-5.6-sol'));
      expect(oauthModels, isNot(contains('gpt-test')));

      final createdAt = connected.createdAt;
      final reauth = await client.startProviderAuth(
        'openai',
        'chatgpt-device',
        connectionId: connected.id,
      );
      gateway.sessions.last.completer.complete(
        OAuthCredential(
          accessToken: 'replacement-access-token',
          refreshToken: 'replacement-refresh-token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
        ),
      );
      await _waitForAuthStatus(
        client,
        reauth.id,
        ProviderAuthAttemptStatus.succeeded,
      );
      final reauthenticated = await client.listProviderConnections();
      final reauthenticatedOpenAI = reauthenticated.singleWhere(
        (connection) => connection.definitionId == 'openai',
      );
      expect(reauthenticatedOpenAI.id, connected.id);
      expect(reauthenticatedOpenAI.createdAt, createdAt);

      final cancelled = await client.startProviderAuth(
        'openai',
        'chatgpt-browser',
      );
      await client.cancelProviderAuth(cancelled.id);
      expect(
        (await client.providers.providerAuthStatus(cancelled.id)).status,
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
          path: '/v4/attachments/missing',
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
      final runnableModel = models.firstWhere(
        (model) =>
            model.capabilities.streaming == CapabilitySupport.supported &&
            model.capabilities.toolCalling == CapabilitySupport.supported,
      );
      final session = await client.createSession(
        id: 'attachment-session',
        worktreeId: catalog.worktrees.single.id,
        title: 'Attachment session',
        agentDefinitionId: 'coder',
        model: SessionModelSelectionDto(
          modelId: runnableModel.id,
        ),
      );
      await client.subscribeTimeline(session.id);
      final completed = client.sessions.timelineEvents
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
    final handle = await DaemonApplication.start(
      DaemonConfig(
        homeDirectory: home.path,
        configDirectory: config.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
      ),
      modelDiscovery: const _StaticDiscovery(<String>['gpt-5.6-sol']),
    );
    await handle.stop();
    final persisted = StringBuffer();
    await for (final entity in home.list(recursive: true)) {
      if (entity is File) {
        persisted.write(String.fromCharCodes(await entity.readAsBytes()));
      }
    }
    expect(persisted.toString(), isNot(contains(token)));
    final credentials = await File(
      '${config.path}/v4/secrets.json',
    ).readAsString();
    expect(credentials, contains(token));
    expect(File('${config.path}/auth.json').existsSync(), isFalse);
    if (!Platform.isWindows) {
      expect(
        File('${config.path}/v4/secrets.json').statSync().mode & 0x1ff,
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

  test('embedded daemon reports a typed port conflict', () async {
    final occupied = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(occupied.close);
    final home = await Directory.systemTemp.createTemp(
      'coder-embedded-conflict-',
    );
    addTearDown(() => home.delete(recursive: true));

    final config = DaemonConfig(
      homeDirectory: home.path,
      port: occupied.port,
      bearerToken: 'embedded-token-0123456789abcdef012345',
      useEnvironmentCredentials: false,
    );
    await expectLater(
      EmbeddedDaemonHandle.start(
        config,
      ),
      throwsA(
        isA<EmbeddedDaemonStartupException>().having(
          (error) => error.reason,
          'reason',
          EmbeddedDaemonStartupFailureReason.portInUse,
        ),
      ),
    );

    await occupied.close();
    final recovered = await EmbeddedDaemonHandle.start(config);
    expect(recovered.boundEndpoint.port, config.port);
    await recovered.stop();
  });

  test(
    'a queued turn started on the idle session event is accepted',
    tags: const <String>[
      'feature_test__conversation_turn_queue__verticalSlice',
    ],
    () async {
      final home = await Directory.systemTemp.createTemp('coder-queue-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-queue-workspace-',
      );
      const token = 'queue-token-0123456789abcdef0123456789';
      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: token,
          useEnvironmentCredentials: false,
        ),
        provider: _TextProvider(),
      );
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: token),
        clientId: 'queue-integration',
        clientKind: 'test',
      );
      addTearDown(() async {
        await client.close();
        await handle.stop();
        await home.delete(recursive: true);
        await workspace.delete(recursive: true);
      });

      final catalog = await client.registerWorkspace(
        workspaceId: 'queue-workspace',
        checkoutId: 'queue-checkout',
        rootPath: workspace.path,
        name: 'Queue',
      );
      final models = await client.listProviderModels('openai');
      final session = await client.createSession(
        id: 'queue-session',
        worktreeId: catalog.worktrees.single.id,
        title: 'Queue session',
        agentDefinitionId: 'coder',
        model: SessionModelSelectionDto(
          modelId: models.first.id,
        ),
      );
      await client.subscribeTimeline(session.id);

      // The drain a queueing client performs: start the follow-up turn from the
      // idle session event itself, without waiting a further round trip. The
      // daemon must have released the session slot before broadcasting it.
      final drained = Completer<void>();
      final subscription = client.sessions.sessionUpdates.listen((updated) {
        if (updated.id != session.id) return;
        if (updated.status != SessionStatus.idle) return;
        if (drained.isCompleted) return;
        drained.complete(
          client.startTurn(
            sessionId: session.id,
            turnId: 'queued-turn',
            prompt: 'The queued follow-up.',
          ),
        );
      });
      addTearDown(subscription.cancel);

      await client.startTurn(
        sessionId: session.id,
        turnId: 'first-turn',
        prompt: 'The first prompt.',
      );
      await drained.future.timeout(_eventTimeout);

      await _waitForIdleSession(
        client,
        catalog.worktrees.single.id,
        session.id,
      );
      final timeline = await client.subscribeTimeline(session.id);
      expect(
        timeline
            .where((event) => event.type == 'user.message')
            .map((event) => event.data['text']),
        <String>['The first prompt.', 'The queued follow-up.'],
      );
    },
  );

  test(
    'composer file search honours gitignore over a real daemon',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-mention-home-');
      final repository = Directory(
        await (await Directory.systemTemp.createTemp(
          'coder-mention-repository-',
        )).resolveSymbolicLinks(),
      );
      await _runGit(repository.path, <String>['init', '-b', 'main']);
      await File(p.join(repository.path, '.gitignore')).writeAsString(
        'secrets.env\n',
      );
      await Directory(p.join(repository.path, 'lib')).create(recursive: true);
      await File(
        p.join(repository.path, 'lib', 'composer.dart'),
      ).writeAsString('// composer\n');
      await File(
        p.join(repository.path, 'secrets.env'),
      ).writeAsString('TOKEN=nope\n');

      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'mention-token-0123456789abcdef0123456789',
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
        clientId: 'mention-vertical-slice',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final registered = await client.registerWorkspace(
        workspaceId: 'mention-workspace',
        checkoutId: 'mention-checkout',
        rootPath: repository.path,
        name: 'Mention fixture',
      );
      final worktreeId = registered.worktrees.single.id;

      final matched = await client.searchFiles(
        worktreeId: worktreeId,
        query: 'composer',
      );
      expect(
        matched.matches.map((match) => match.relativePath),
        contains('lib/composer.dart'),
      );
      expect(matched.matches.single.absolutePath, startsWith(repository.path));

      final everything = await client.searchFiles(
        worktreeId: worktreeId,
        query: '',
      );
      expect(
        everything.matches.map((match) => match.relativePath),
        isNot(contains('secrets.env')),
      );
      expect(
        everything.matches.map((match) => match.relativePath),
        contains('.gitignore'),
      );

      await expectLater(
        client.searchFiles(worktreeId: 'missing', query: 'composer'),
        throwsA(isA<Exception>()),
      );
    },
    tags: const <String>['feature_test__composer_file_mention__verticalSlice'],
  );

  test(
    'agent commands merge across sources and follow disk changes',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-command-home-');
      final agentsHome = await Directory.systemTemp.createTemp(
        'coder-command-agents-home-',
      );
      final workspace = await Directory.systemTemp.createTemp(
        'coder-command-workspace-',
      );
      const bearerToken = 'command-token-0123456789abcdef0123456789';
      addTearDown(() async {
        await home.delete(recursive: true);
        await agentsHome.delete(recursive: true);
        await workspace.delete(recursive: true);
      });

      await _writeCommand(
        p.join(agentsHome.path, '.agents', 'commands'),
        name: 'review',
        description: 'From the user home.',
        body: 'Global review.',
      );
      await _writeCommand(
        p.join(workspace.path, '.agents', 'commands'),
        name: 'review',
        description: 'From the project.',
        body: r'Review $ARGUMENTS.',
        argumentHint: '<path>',
      );

      final handle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: home.path,
          userHomeDirectory: agentsHome.path,
          port: 0,
          bearerToken: bearerToken,
          useEnvironmentCredentials: false,
        ),
      );
      addTearDown(handle.stop);
      final client = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
        credentials: const DaemonCredentials(bearerToken: bearerToken),
        clientId: 'command-vertical-slice',
        clientKind: 'test',
      );
      addTearDown(client.close);

      final global = await client.listCommands();
      expect(global.single.name, 'review');
      expect(global.single.description, 'From the user home.');
      expect(global.single.source, AgentCommandSource.userHome);

      await client.registerWorkspace(
        workspaceId: 'command-workspace',
        checkoutId: 'command-checkout',
        rootPath: workspace.path,
        name: 'Workspace',
      );
      final scoped = await client.listCommands(
        workspaceId: 'command-workspace',
      );
      expect(scoped.single.source, AgentCommandSource.project);
      expect(scoped.single.description, 'From the project.');
      expect(scoped.single.argumentHint, '<path>');
      expect(scoped.single.body, r'Review $ARGUMENTS.');

      final changed = client.prompts.commandChanges.first;
      await _writeCommand(
        p.join(agentsHome.path, '.agents', 'commands'),
        name: 'ship',
        description: 'Ships the branch.',
        body: 'Ship it.',
      );
      await changed.timeout(const Duration(seconds: 10));

      expect(
        (await client.listCommands()).map((command) => command.name),
        containsAll(<String>['review', 'ship']),
      );
    },
    tags: const <String>['feature_test__composer_slash_command__verticalSlice'],
  );
}

Future<void> _writeCommand(
  String directory, {
  required String name,
  required String description,
  required String body,
  String? argumentHint,
}) async {
  await Directory(directory).create(recursive: true);
  await File(p.join(directory, '$name.md')).writeAsString(
    '---\n'
    'description: $description\n'
    '${argumentHint == null ? '' : 'argument-hint: $argumentHint\n'}'
    '---\n\n'
    '$body\n',
  );
}

/// Provider that answers every turn with one assistant message.
final class _TextProvider implements ModelProvider {
  @override
  String get id => 'text-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    yield const ModelTextDelta('Done.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Done.'),
    );
  }
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
    final session = (await client.sessions.listSessions(
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
    final current = await client.providers.providerAuthStatus(attemptId);
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
  Future<ProviderOAuthSession> start(AgentProviderAuthFlow flow) async {
    final session = _IntegrationOAuthSession(flow);
    sessions.add(session);
    return session;
  }
}

final class _IntegrationOAuthSession implements ProviderOAuthSession {
  _IntegrationOAuthSession(this.flow);

  final AgentProviderAuthFlow flow;
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
      flow == AgentProviderAuthFlow.oauthDevice ? 'TEST-CODE' : null;

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
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async => modelIds;
}

final class _CredentialAwareDiscovery implements ProviderModelDiscovery {
  const _CredentialAwareDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async {
    if (credential case ApiKeyCredential(:final key) when key != 'valid-key') {
      throw const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.invalidCredential,
        'credential rejected by deterministic provider',
      );
    }
    return const <String>['gpt-test'];
  }
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
    final servers = await client.mcp.listMcpServers(worktreeId: worktreeId);
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

class _SleepProvider implements ModelProvider {
  /// Completes once the sleep call has been issued.
  final Completer<void> sleeping = Completer<void>();

  /// Completes with the outcome the sleep tool reported.
  final Completer<String> outcome = Completer<String>();

  var _round = 0;

  @override
  String get id => 'sleep-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_round++ == 0) {
      const arguments = <String, dynamic>{
        'duration_ms': 300000,
        'reason': 'the build',
      };
      yield const ModelFunctionCall(
        callId: 'sleep-call',
        name: 'sleep',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'sleep-call',
              name: 'sleep',
              arguments: arguments,
            ),
          ],
        ),
      );
      if (!sleeping.isCompleted) sleeping.complete();
      return;
    }
    if (!outcome.isCompleted) {
      final result = jsonDecode(
        request.history
            .whereType<ToolResultConversationItem>()
            .firstWhere((item) => item.callId == 'sleep-call')
            .output,
      );
      outcome.complete((result as Map<String, dynamic>)['outcome'] as String);
    }
    yield const ModelTextDelta('Done.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Done.'),
    );
  }
}

/// Calls `new_context` in the first turn, then reports what survived.
///
/// Round 1 answers the first prompt plainly, round 2 resets, and round 3 (the
/// second turn) records the history the provider was actually given.
class _ContextResetProvider implements ModelProvider {
  /// History of every request, so the test can assert on the one after a reset.
  final List<List<ConversationItem>> requests = <List<ConversationItem>>[];

  var _round = 0;

  @override
  String get id => 'context-reset-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    requests.add(request.history);
    switch (_round++) {
      case 0:
        yield const ModelTextDelta('Noted.');
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(text: 'Noted.'),
          usage: ModelUsage(
            inputTokens: 900,
            outputTokens: 100,
            totalTokens: 1000,
          ),
        );
      case 1:
        const arguments = <String, dynamic>{};
        yield const ModelFunctionCall(
          callId: 'reset-call',
          name: 'new_context',
          arguments: arguments,
        );
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: 'Starting over.',
            toolCalls: <ConversationToolCall>[
              ConversationToolCall(
                callId: 'reset-call',
                name: 'new_context',
                arguments: arguments,
              ),
            ],
          ),
        );
      default:
        yield const ModelTextDelta('Fresh.');
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(text: 'Fresh.'),
        );
    }
  }
}

/// Answers a turn, then writes a summary when the compaction request arrives.
class _CompactingProvider implements ModelProvider {
  final List<List<ConversationItem>> requests = <List<ConversationItem>>[];

  var _round = 0;

  @override
  String get id => 'compacting-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    requests.add(request.history);
    switch (_round++) {
      case 0:
        yield const ModelTextDelta('Noted.');
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(text: 'Noted.'),
          usage: ModelUsage(
            inputTokens: 900,
            outputTokens: 100,
            totalTokens: 1000,
          ),
        );
      case 1:
        yield const ModelTextDelta('The release date is Tuesday.');
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: 'The release date is Tuesday.',
          ),
        );
      default:
        yield const ModelTextDelta('Tuesday.');
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(text: 'Tuesday.'),
        );
    }
  }
}

class _AskingProvider implements ModelProvider {
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
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'store',
            'header': 'Storage',
            'question': 'Which store should the cache use?',
            'options': <Map<String, dynamic>>[
              <String, dynamic>{
                'label': 'SQLite',
                'description': 'Durable and already a dependency.',
              },
              <String, dynamic>{
                'label': 'In memory',
                'description': 'Fastest, lost on restart.',
              },
            ],
          },
        ],
      };
      yield const ModelFunctionCall(
        callId: 'ask-call',
        name: 'ask_user',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'ask-call',
              name: 'ask_user',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    final answer = request.history
        .whereType<ToolResultConversationItem>()
        .firstWhere((item) => item.callId == 'ask-call')
        .output;
    yield ModelTextDelta('Using $answer');
    yield ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Using $answer'),
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

class _ExecProvider implements ModelProvider {
  _ExecProvider({required this.tty});

  /// Whether the command is asked for a pseudo-terminal or plain pipes.
  final bool tty;

  /// Completes with the shell's output once stdin has been echoed back.
  final Completer<String> echoed = Completer<String>();

  var _round = 0;
  String? _sessionId;

  @override
  String get id => 'exec-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    Map<String, dynamic> resultFor(String callId) => Map<String, dynamic>.from(
      jsonDecode(
            request.history
                .whereType<ToolResultConversationItem>()
                .firstWhere((item) => item.callId == callId)
                .output,
          )
          as Map,
    );

    if (_round++ == 0) {
      // `cat` keeps running with no arguments, so the session survives the
      // call and the next one can write into it.
      final arguments = <String, dynamic>{
        'command': 'cat',
        'workdir': null,
        'tty': tty,
        'yield_time_ms': 300,
        'max_output_tokens': null,
      };
      yield ModelFunctionCall(
        callId: 'exec-call',
        name: 'exec_command',
        arguments: arguments,
      );
      yield ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'exec-call',
              name: 'exec_command',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (_round == 2) {
      _sessionId = resultFor('exec-call')['sessionId'] as String?;
      final arguments = <String, dynamic>{
        'session_id': _sessionId,
        'chars': 'tinyrack-exec-probe\n',
        'yield_time_ms': 1000,
        'max_output_tokens': null,
      };
      yield ModelFunctionCall(
        callId: 'stdin-call',
        name: 'write_stdin',
        arguments: arguments,
      );
      yield ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'stdin-call',
              name: 'write_stdin',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (!echoed.isCompleted) {
      echoed.complete(resultFor('stdin-call')['output'] as String);
    }
    yield const ModelTextDelta('Done.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Done.'),
    );
  }
}

final class _ViewImageProvider implements ModelProvider {
  /// The request that carried the image back into the model's context.
  final Completer<ModelRequest> secondRequest = Completer<ModelRequest>();

  @override
  String get id => 'view-image-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    final viewed = request.history.whereType<ToolResultConversationItem>().any(
      (item) => item.callId == 'view-call',
    );
    if (!viewed) {
      const arguments = <String, dynamic>{
        'path': 'shot.png',
        'detail': 'high',
      };
      yield const ModelFunctionCall(
        callId: 'view-call',
        name: 'view_image',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'view-call',
              name: 'view_image',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (!secondRequest.isCompleted) secondRequest.complete(request);
    yield const ModelTextDelta('I can see it.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'I can see it.'),
    );
  }
}

/// The two tool results the search vertical slice inspects.
final class _SearchResults {
  const _SearchResults({required this.search, required this.glob});

  final Map<String, dynamic> search;
  final Map<String, dynamic> glob;
}

final class _SearchProvider implements ModelProvider {
  /// Completes once both tools have answered.
  final Completer<_SearchResults> results = Completer<_SearchResults>();

  @override
  String get id => 'search-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    Map<String, dynamic>? resultFor(String callId) {
      for (final item
          in request.history.whereType<ToolResultConversationItem>()) {
        if (item.callId == callId) {
          return jsonDecode(item.output) as Map<String, dynamic>;
        }
      }
      return null;
    }

    final search = resultFor('search-call');
    if (search == null) {
      const arguments = <String, dynamic>{
        'query': 'marker',
        'path': null,
        'regex': null,
        'case_sensitive': null,
        'context_lines': null,
        'include_ignored': null,
        'max_results': null,
      };
      yield const ModelFunctionCall(
        callId: 'search-call',
        name: 'search_text',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'search-call',
              name: 'search_text',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    final glob = resultFor('glob-call');
    if (glob == null) {
      const arguments = <String, dynamic>{
        'pattern': '**/*.dart',
        'path': null,
        'include_ignored': null,
        'max_results': null,
      };
      yield const ModelFunctionCall(
        callId: 'glob-call',
        name: 'glob',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'glob-call',
              name: 'glob',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (!results.isCompleted) {
      results.complete(_SearchResults(search: search, glob: glob));
    }
    yield const ModelTextDelta('Found it.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Found it.'),
    );
  }
}

final class _CollaboratingProvider implements ModelProvider {
  _CollaboratingProvider({this.agentType = 'reviewer'});

  /// The `agent_type` the scripted root passes to `spawn_agent`.
  final String agentType;

  /// Every request the daemon sent, for envelope assertions.
  final List<ModelRequest> requests = <ModelRequest>[];

  static List<ModelEvent> _toolCall(
    String callId,
    String name,
    Map<String, dynamic> arguments,
  ) => <ModelEvent>[
    ModelFunctionCall(callId: callId, name: name, arguments: arguments),
    ModelResponseCompleted(
      assistant: AssistantConversationItem(
        text: '',
        toolCalls: <ConversationToolCall>[
          ConversationToolCall(
            callId: callId,
            name: name,
            arguments: arguments,
          ),
        ],
      ),
    ),
  ];

  @override
  String get id => 'collab-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    requests.add(request);
    final userTexts = request.history
        .whereType<UserConversationItem>()
        .map((item) => item.text)
        .toList(growable: false);
    final isSubagent = userTexts.any(
      (text) => text.startsWith('Message Type: NEW_TASK'),
    );
    final hasToolResult = request.history.any(
      (item) => item is ToolResultConversationItem,
    );
    if (isSubagent) {
      if (!hasToolResult) {
        yield* Stream<ModelEvent>.fromIterable(
          _toolCall('write-call', 'apply_patch', const <String, dynamic>{
            'patch':
                '--- /dev/null\n+++ b/forbidden.txt\n'
                '@@ -0,0 +1,1 @@\n+forbidden\n',
          }),
        );
        return;
      }
      yield const ModelTextDelta('Review completed.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Review completed.'),
      );
      return;
    }
    if (!hasToolResult &&
        request.tools.any((tool) => tool.name == 'spawn_agent')) {
      yield* Stream<ModelEvent>.fromIterable(
        _toolCall('spawn-call', 'spawn_agent', <String, dynamic>{
          'task_name': 'review_task',
          'message': 'Review without changing files.',
          'agent_type': agentType,
          'fork_turns': null,
          'model': null,
          'reasoning_effort': null,
        }),
      );
      return;
    }
    yield const ModelTextDelta('Parent completed.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Parent completed.'),
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
    String? outputFor(String callId) {
      for (final item
          in request.history.whereType<ToolResultConversationItem>()) {
        if (item.callId == callId) return item.output;
      }
      return null;
    }

    Stream<ModelEvent> call(
      String callId,
      String name,
      Map<String, dynamic> arguments,
    ) async* {
      yield ModelFunctionCall(
        callId: callId,
        name: name,
        arguments: arguments,
      );
      yield ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: callId,
              name: name,
              arguments: arguments,
            ),
          ],
        ),
      );
    }

    final listed = outputFor('list-call');
    if (listed == null) {
      // The prompt no longer names the skills, only how many there are and
      // which tool finds them.
      yield* call('list-call', 'list_skills', <String, dynamic>{
        'cursor': null,
      });
      return;
    }
    if (outputFor('skill-call') == null) {
      // A disabled skill must not reach the model through the listing either,
      // which is where the catalog now lives.
      final page = jsonDecode(listed) as Map<String, dynamic>;
      final names = (page['skills']! as List)
          .map((skill) => (skill! as Map<String, dynamic>)['name'])
          .toList();
      expect(names, contains('shared'));
      expect(names, isNot(contains('commit')));
      expect(page['total'], names.length);
      yield* call('skill-call', 'skill', <String, dynamic>{
        'name': 'shared',
        'resource': null,
      });
      return;
    }
    yield const ModelTextDelta('Loaded the skill.');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Loaded the skill.'),
    );
  }
}
