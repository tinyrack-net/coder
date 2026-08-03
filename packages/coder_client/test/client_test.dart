import 'dart:async';

import 'package:async/async.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Workspace',
    rootPath: '/workspace',
    kind: WorkspaceKind.directory,
    createdAt: now,
  );
  final worktree = WorktreeDto(
    id: 'worktree',
    workspaceId: workspace.id,
    name: workspace.name,
    path: workspace.rootPath,
    kind: WorktreeKind.directory,
    isCoderOwned: false,
    createdAt: now,
  );
  final agent = SessionDto(
    id: 'agent',
    worktreeId: worktree.id,
    title: 'Agent',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  const agentDefinition = AgentDefinitionDto(
    id: 'coder',
    name: 'Coder',
    description: 'Coding agent',
    mode: AgentMode.primary,
    promptEnabled: true,
    systemPrompt: 'Code carefully.',
    model: AgentModelSelectionDto(
      source: AgentModelSource.daemonDefault,
    ),
    reasoningEffort: 'medium',
    permissionMode: PermissionMode.ask,
    toolIds: <String>['read_file'],
    callableAgentIds: <String>[],
    contentHash: 'hash',
    sourcePath: '/config/agents/coder.md',
    isBuiltIn: true,
  );
  const agentTool = AgentToolDefinitionDto(
    id: 'read_file',
    name: 'read_file',
    description: 'Read a file.',
    risk: ToolRisk.read,
  );
  const definition = ProviderDefinitionDto(
    id: 'provider',
    name: 'Provider',
    description: 'Hosted provider',
    authMethods: <ProviderAuthMethodDto>[
      ProviderAuthMethodDto(
        id: 'api-key',
        label: 'API key',
        kind: ProviderAuthKind.apiKey,
        flow: ProviderAuthFlow.apiKey,
      ),
    ],
  );
  final connection = ProviderConnectionDto(
    id: 'provider',
    definitionId: 'provider',
    displayName: 'Provider',
    status: ProviderConnectionStatus.connected,
    authKind: ProviderAuthKind.apiKey,
    credentialOrigin: ProviderCredentialOrigin.stored,
    isDefault: true,
    defaultModelId: 'retired/model-not-in-current-catalog',
    createdAt: now,
    updatedAt: now,
  );
  const model = ProviderModelDto(
    connectionId: 'provider',
    id: 'vendor/model-with-an-extremely-long-identifier',
    label: 'Model with an extremely long display label',
    source: ProviderModelSource.manual,
    capabilities: ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
    ),
  );
  final approval = ApprovalRequestDto(
    id: 'approval',
    sessionId: agent.id,
    turnId: 'turn',
    toolCallId: 'call',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': 'diff'},
    status: ApprovalStatus.pending,
    createdAt: now,
  );
  final timeline = TimelineEventDto(
    sessionId: agent.id,
    sequence: 2,
    turnId: 'turn',
    type: 'assistant.delta',
    data: const <String, dynamic>{'text': 'hello'},
    createdAt: now,
  );

  test(
    'typed client covers the complete RPC surface and notifications',
    () async {
      final connector = _TestConnector(
        onConfigure: (peer, requests) {
          _registerFixtureMethods(
            peer,
            requests,
            workspace: workspace,
            worktree: worktree,
            agent: agent,
            agentDefinition: agentDefinition,
            agentTool: agentTool,
            definition: definition,
            connection: connection,
            model: model,
            approval: approval,
            timeline: timeline,
          );
        },
      );
      final states = <ClientConnectionState>[];
      final clientFuture = CoderClient.connect(
        endpoint: HostEndpoint.parse('127.0.0.1:7337'),
        credentials: const DaemonCredentials(bearerToken: 'secret-token'),
        clientId: 'client',
        clientKind: 'test',
        connector: connector,
      );
      await Future<void>.delayed(Duration.zero);
      final client = await clientFuture;
      final subscription = client.states.listen(states.add);
      addTearDown(subscription.cancel);
      addTearDown(client.close);

      expect(client.serverInfo.protocolVersion, coderProtocolVersion);
      expect(connector.lastUri, Uri.parse('ws://127.0.0.1:7337/ws'));
      expect(
        connector.lastHeaders,
        const <String, String>{
          'Authorization': 'Bearer secret-token',
        },
      );
      expect(
        await client.getWorkspaceCatalog(),
        WorkspaceCatalogDto(
          workspaces: <WorkspaceDto>[workspace],
          worktrees: <WorktreeDto>[worktree],
        ),
      );
      expect(
        await client.registerWorkspace(
          workspaceId: workspace.id,
          checkoutId: worktree.id,
          rootPath: workspace.rootPath,
          name: workspace.name,
        ),
        WorkspaceRegisterResultDto(
          workspace: workspace,
          worktrees: <WorktreeDto>[worktree],
        ),
      );
      expect(
        await client.refreshWorkspace(workspace.id),
        isA<WorkspaceCatalogDto>(),
      );
      await client.unregisterWorkspace(workspace.id);
      expect(await client.suggestDirectories('work'), isNotEmpty);
      expect(await client.listGitBranches(workspace.id), isNotEmpty);
      expect(
        await client.createWorktree(
          id: worktree.id,
          workspaceId: workspace.id,
          mode: WorktreeCreateMode.newBranch,
          branchName: 'topic',
        ),
        WorktreeResultDto(worktree: worktree),
      );
      expect(
        await client.previewWorktreeArchive(worktree.id),
        isA<WorktreeArchivePreviewDto>(),
      );
      expect(
        await client.archiveWorktree(worktree.id),
        WorktreeResultDto(
          worktree: worktree,
          hookRuns: const <WorktreeHookRunDto>[
            WorktreeHookRunDto(
              phase: WorktreeHookPhase.teardown,
              command: 'docker compose down',
              exitCode: 0,
              stdout: '',
              stderr: '',
            ),
          ],
        ),
      );
      expect(
        await client.getProjectSettings(workspace.id),
        const ProjectSettingsResultDto(
          settings: ProjectSettingsDto(setup: <String>['npm ci']),
          sourcePath: '/workspace/coder.json',
        ),
      );
      expect(
        await client.saveProjectSettings(
          workspace.id,
          const ProjectSettingsDto(setup: <String>['npm ci']),
        ),
        isA<ProjectSettingsResultDto>(),
      );
      expect(await client.listSessions(worktreeId: worktree.id), <SessionDto>[
        agent,
      ]);
      expect(
        await client.createSession(
          id: agent.id,
          worktreeId: worktree.id,
          title: agent.title,
          agentDefinitionId: agent.agentDefinitionId,
          mode: SessionMode.plan,
          model: const SessionModelSelectionDto(
            providerConnectionId: 'provider',
            modelId: 'model',
          ),
        ),
        agent,
      );
      expect(
        await client.updateSessionModel(
          agent.id,
          const SessionModelSelectionDto(
            providerConnectionId: 'provider',
            modelId: 'model',
          ),
        ),
        agent,
      );
      expect(await client.updateSessionModel(agent.id, null), agent);
      expect(
        await client.updateSessionMode(agent.id, SessionMode.plan),
        agent,
      );
      expect(await client.listAgentDefinitions(), <AgentDefinitionDto>[
        agentDefinition,
      ]);
      expect(await client.getAgentDefinition('coder'), agentDefinition);
      expect(
        await client.createAgentDefinition('coder', agentDefinition),
        agentDefinition,
      );
      expect(
        await client.updateAgentDefinition(
          agentDefinition,
          expectedContentHash: agentDefinition.contentHash,
        ),
        agentDefinition,
      );
      await client.archiveAgentDefinition('custom');
      expect(await client.resetAgentDefinition('coder'), agentDefinition);
      expect(
        await client.validateAgentDefinition('coder', 'markdown'),
        agentDefinition,
      );
      expect(await client.listAgentTools(), <AgentToolDefinitionDto>[
        agentTool,
      ]);
      final catalog = await client.listProviderCatalog();
      expect(catalog.definitions, <ProviderDefinitionDto>[definition]);
      expect(await client.listProviderConnections(), <ProviderConnectionDto>[
        connection,
      ]);
      expect(
        await client.connectProviderApiKey(
          definition.id,
          'api-key',
          makeDefault: true,
        ),
        connection,
      );
      expect(await client.connectProviderNone('ollama'), connection);
      final attempt = await client.startProviderAuth(
        definition.id,
        'chatgpt-device',
      );
      expect(await client.providerAuthStatus(attempt.id), attempt);
      await client.cancelProviderAuth(attempt.id);
      await client.disconnectProvider(connection.id);
      await client.setDefaultProvider(connection.id);
      await client.setDefaultProviderModel(connection.id, model.id);
      expect(
        (await client.refreshProviderCatalog()).definitions,
        <ProviderDefinitionDto>[definition],
      );
      expect(
        await client.listProviderModels(connection.id),
        <ProviderModelDto>[model],
      );
      expect(connection.defaultModelId, isNot(model.id));
      const customConfig = CustomProviderConfigDto(
        name: 'Custom',
        baseUrl: 'http://localhost/v1',
        apiFormat: ProviderApiFormat.chatCompletions,
        authenticationRequired: false,
      );
      expect(
        await client.createCustomProvider(
          'custom',
          customConfig,
        ),
        connection,
      );
      expect(
        await client.updateCustomProvider('custom', customConfig),
        connection,
      );
      await client.deleteCustomProvider('custom');
      await client.startTurn(
        sessionId: agent.id,
        turnId: 'turn',
        prompt: 'hello',
      );
      await client.cancelTurn(agent.id);
      await client.resolveApproval(approvalId: approval.id, approved: true);
      expect(await client.subscribeTimeline(agent.id), <TimelineEventDto>[
        timeline,
      ]);

      final events = <ClientEvent>[];
      final eventSubscription = client.events.listen(events.add);
      addTearDown(eventSubscription.cancel);
      connector.connections.single.peer
        ..sendNotification(RpcNotification.timelineEvent, timeline.toJson())
        ..sendNotification(
          RpcNotification.timelineEvent,
          timeline.copyWith(sequence: 3).toJson(),
        )
        ..sendNotification(RpcNotification.sessionUpdated, agent.toJson())
        ..sendNotification(
          RpcNotification.agentDefinitionsChanged,
          const <String, dynamic>{},
        )
        ..sendNotification(
          RpcNotification.approvalRequested,
          approval.toJson(),
        )
        ..sendNotification(
          RpcNotification.providerAuthUpdated,
          attempt.toJson(),
        );
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<TimelineClientEvent>(), hasLength(1));
      expect(
        events.whereType<SessionUpdatedClientEvent>().single.session,
        agent,
      );
      expect(
        events.whereType<AgentDefinitionsChangedClientEvent>(),
        hasLength(1),
      );
      expect(
        events.whereType<ApprovalRequestedClientEvent>().single.approval,
        approval,
      );
      expect(
        events.whereType<ProviderAuthUpdatedClientEvent>().single.attempt,
        attempt,
      );
      expect(
        connector.requests.map((request) => request.method),
        containsAll(<String>[
          RpcMethod.workspaceCatalog,
          RpcMethod.workspaceRegister,
          RpcMethod.workspaceRefresh,
          RpcMethod.workspaceUnregister,
          RpcMethod.directorySuggest,
          RpcMethod.gitBranchesList,
          RpcMethod.worktreeCreate,
          RpcMethod.worktreeArchivePreview,
          RpcMethod.worktreeArchive,
          RpcMethod.projectSettingsGet,
          RpcMethod.projectSettingsSave,
          RpcMethod.sessionList,
          RpcMethod.sessionCreate,
          RpcMethod.sessionModelSet,
          RpcMethod.sessionModeSet,
          RpcMethod.agentDefinitionList,
          RpcMethod.agentDefinitionGet,
          RpcMethod.agentDefinitionCreate,
          RpcMethod.agentDefinitionUpdate,
          RpcMethod.agentDefinitionArchive,
          RpcMethod.agentDefinitionReset,
          RpcMethod.agentDefinitionValidate,
          RpcMethod.agentToolCatalog,
          RpcMethod.providerCatalog,
          RpcMethod.providerConnectionsList,
          RpcMethod.providerConnectApiKey,
          RpcMethod.providerConnectNone,
          RpcMethod.providerAuthStart,
          RpcMethod.providerAuthStatus,
          RpcMethod.providerAuthCancel,
          RpcMethod.providerDisconnect,
          RpcMethod.providerDefaultSet,
          RpcMethod.providerDefaultModelSet,
          RpcMethod.providerCatalogRefresh,
          RpcMethod.providerModelsList,
          RpcMethod.providerCustomCreate,
          RpcMethod.providerCustomUpdate,
          RpcMethod.providerCustomDelete,
          RpcMethod.turnStart,
          RpcMethod.turnCancel,
          RpcMethod.approvalResolve,
          RpcMethod.timelineSubscribe,
        ]),
      );
      expect(states, isNot(contains(ClientConnectionState.disconnected)));
    },
    tags: const <String>[
      'feature_test__daemon_management__contract',
      'feature_test__daemon_authentication__contract',
      'feature_test__workspace_catalog__contract',
      'feature_test__workspace_registration__contract',
      'feature_test__worktree_lifecycle__contract',
      'feature_test__project_settings__contract',
      'feature_test__session_lifecycle__contract',
      'feature_test__turn_execution__contract',
      'feature_test__agent_definition_management__contract',
      'feature_test__provider_catalog__contract',
      'feature_test__provider_connection_management__contract',
      'feature_test__provider_oauth__contract',
      'feature_test__provider_custom__contract',
    ],
  );

  test('requests in flight when the peer closes fail as retryable', () async {
    final connector = _TestConnector(onConfigure: _registerHello);
    final clientFuture = CoderClient.connect(
      endpoint: HostEndpoint.parse('127.0.0.1:7337'),
      credentials: const DaemonCredentials(bearerToken: 'secret-token'),
      clientId: 'client',
      clientKind: 'test',
      connector: connector,
    );
    await Future<void>.delayed(Duration.zero);
    final client = await clientFuture;
    await client.close();

    await expectLater(
      client.getWorkspaceCatalog(),
      throwsA(
        isA<CoderClientException>().having(
          (error) => error.retryable,
          'retryable',
          isTrue,
        ),
      ),
    );
  });

  test('RPC errors preserve daemon code and retryability', () async {
    final connector = _TestConnector(
      onConfigure: (peer, requests) {
        _registerHello(peer, requests);
        peer.registerMethod(RpcMethod.workspaceCatalog, (_) {
          throw json_rpc.RpcException(
            -32000,
            'Workspace unavailable',
            data: const <String, dynamic>{
              'code': 'workspace_unavailable',
              'retryable': true,
            },
          );
        });
      },
    );
    final client = await CoderClient.connect(
      endpoint: HostEndpoint.parse('ws://localhost/ws'),
      credentials: const DaemonCredentials(bearerToken: 'token'),
      clientId: 'client',
      clientKind: 'test',
      connector: connector,
    );
    addTearDown(client.close);

    await expectLater(
      client.getWorkspaceCatalog(),
      throwsA(
        isA<CoderClientException>()
            .having((error) => error.code, 'code', 'workspace_unavailable')
            .having((error) => error.retryable, 'retryable', isTrue)
            .having(
              (error) => error.toString(),
              'toString',
              contains('Workspace unavailable'),
            ),
      ),
    );
  });

  test('request timeout and idempotent close clean up resources', () async {
    final connector = _TestConnector(
      onConfigure: (peer, requests) {
        _registerHello(peer, requests);
        peer.registerMethod(
          RpcMethod.workspaceCatalog,
          (_) => Completer<Map<String, dynamic>>().future,
        );
      },
    );
    final client = await CoderClient.connect(
      endpoint: HostEndpoint.parse('ws://localhost/ws'),
      credentials: const DaemonCredentials(bearerToken: 'token'),
      clientId: 'client',
      clientKind: 'test',
      connector: connector,
      requestTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      client.getWorkspaceCatalog(),
      throwsA(isA<TimeoutException>()),
    );
    await client.close();
    await client.close();
  });

  test(
    'socket close reconnects and catches up from the last sequence',
    () async {
      final connector = _TestConnector(
        onConfigure: (peer, requests) {
          _registerHello(peer, requests);
          peer.registerMethod(RpcMethod.timelineSubscribe, (
            json_rpc.Parameters parameters,
          ) {
            final request = TimelineSubscribeParamsDto.fromJson(
              Map<String, dynamic>.from(parameters.asMap),
            );
            requests.add((
              method: RpcMethod.timelineSubscribe,
              payload: request.toJson(),
            ));
            return const TimelineResultDto(
              events: <TimelineEventDto>[],
            ).toJson();
          });
        },
      );
      final client = await CoderClient.connect(
        endpoint: HostEndpoint.parse('ws://localhost/ws'),
        credentials: const DaemonCredentials(bearerToken: 'token'),
        clientId: 'client',
        clientKind: 'test',
        connector: connector,
        reconnectDelay: (_) => Duration.zero,
      );
      addTearDown(client.close);
      await client.subscribeTimeline('agent', afterSequence: 7);
      final connectedAgain = client.states.firstWhere(
        (state) =>
            state == ClientConnectionState.connected &&
            connector.connections.length == 2,
      );
      await connector.connections.first.peer.close();
      await connectedAgain.timeout(const Duration(seconds: 2));

      expect(connector.connections, hasLength(2));
      final subscriptions = connector.requests
          .where((request) => request.method == RpcMethod.timelineSubscribe)
          .toList(growable: false);
      expect(subscriptions, hasLength(2));
      expect(subscriptions.last.payload['afterSequence'], 7);
    },
  );
}

typedef _Request = ({String method, Map<String, dynamic> payload});

final class _TestConnector implements WebSocketConnector {
  _TestConnector({required this.onConfigure});

  final void Function(json_rpc.Peer peer, List<_Request> requests) onConfigure;
  final List<_TestConnection> connections = <_TestConnection>[];
  final List<_Request> requests = <_Request>[];
  Uri? lastUri;
  Map<String, String>? lastHeaders;

  @override
  Future<WebSocketChannel> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    lastUri = uri;
    lastHeaders = headers;
    final controller = StreamChannelController<Object?>(sync: true);
    final peer = json_rpc.Peer(controller.local.cast<String>());
    onConfigure(peer, requests);
    unawaited(peer.listen());
    connections.add(_TestConnection(peer));
    return _TestWebSocketChannel(controller.foreign);
  }
}

final class _TestConnection {
  const _TestConnection(this.peer);

  final json_rpc.Peer peer;
}

final class _TestWebSocketChannel extends StreamChannelMixin<Object?>
    implements WebSocketChannel {
  _TestWebSocketChannel(this._channel);

  final StreamChannel<Object?> _channel;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Stream<Object?> get stream => _channel.stream;

  @override
  late final WebSocketSink sink = _TestWebSocketSink(_channel.sink);
}

final class _TestWebSocketSink extends DelegatingStreamSink<Object?>
    implements WebSocketSink {
  _TestWebSocketSink(super.sink);

  @override
  Future<void> close([int? closeCode, String? closeReason]) => super.close();
}

void _registerHello(json_rpc.Peer peer, List<_Request> requests) {
  peer.registerMethod(RpcMethod.hello, (json_rpc.Parameters parameters) {
    requests.add((
      method: RpcMethod.hello,
      payload: Map<String, dynamic>.from(parameters.asMap),
    ));
    return const ServerInfoDto(
      serverId: 'server',
      version: 'test',
      protocolVersion: coderProtocolVersion,
      features: <String, bool>{},
    ).toJson();
  });
}

void _registerFixtureMethods(
  json_rpc.Peer peer,
  List<_Request> requests, {
  required WorkspaceDto workspace,
  required WorktreeDto worktree,
  required SessionDto agent,
  required AgentDefinitionDto agentDefinition,
  required AgentToolDefinitionDto agentTool,
  required ProviderDefinitionDto definition,
  required ProviderConnectionDto connection,
  required ProviderModelDto model,
  required ApprovalRequestDto approval,
  required TimelineEventDto timeline,
}) {
  _registerHello(peer, requests);
  final attempt = ProviderAuthAttemptDto(
    id: 'attempt',
    definitionId: definition.id,
    methodId: 'chatgpt-device',
    status: ProviderAuthAttemptStatus.awaitingUser,
    userCode: 'CODE-1234',
  );
  final workspaceCatalog = WorkspaceCatalogDto(
    workspaces: <WorkspaceDto>[workspace],
    worktrees: <WorktreeDto>[worktree],
  );
  const archivePreview = WorktreeArchivePreviewDto(
    worktreeId: 'worktree',
    dirty: false,
    unpushedCommitCount: 0,
    runningSessionCount: 0,
    removesDirectory: false,
  );
  final responses = <String, Map<String, dynamic>>{
    RpcMethod.workspaceCatalog: WorkspaceCatalogResultDto(
      catalog: workspaceCatalog,
    ).toJson(),
    RpcMethod.workspaceRegister: WorkspaceRegisterResultDto(
      workspace: workspace,
      worktrees: <WorktreeDto>[worktree],
    ).toJson(),
    RpcMethod.workspaceRefresh: WorkspaceCatalogResultDto(
      catalog: workspaceCatalog,
    ).toJson(),
    RpcMethod.workspaceUnregister: const WorkspaceUnregisterResultDto(
      unregistered: true,
    ).toJson(),
    RpcMethod.directorySuggest: const DirectorySuggestResultDto(
      suggestions: <DirectorySuggestionDto>[
        DirectorySuggestionDto(path: '/workspace', name: 'Workspace'),
      ],
    ).toJson(),
    RpcMethod.gitBranchesList: const GitBranchesListResultDto(
      branches: <GitBranchDto>[
        GitBranchDto(name: 'main', current: true, checkedOut: true),
      ],
    ).toJson(),
    RpcMethod.worktreeCreate: WorktreeResultDto(worktree: worktree).toJson(),
    RpcMethod.worktreeArchivePreview: const WorktreeArchivePreviewResultDto(
      preview: archivePreview,
    ).toJson(),
    RpcMethod.worktreeArchive: WorktreeResultDto(
      worktree: worktree,
      hookRuns: const <WorktreeHookRunDto>[
        WorktreeHookRunDto(
          phase: WorktreeHookPhase.teardown,
          command: 'docker compose down',
          exitCode: 0,
          stdout: '',
          stderr: '',
        ),
      ],
    ).toJson(),
    RpcMethod.projectSettingsGet: const ProjectSettingsResultDto(
      settings: ProjectSettingsDto(setup: <String>['npm ci']),
      sourcePath: '/workspace/coder.json',
    ).toJson(),
    RpcMethod.projectSettingsSave: const ProjectSettingsResultDto(
      settings: ProjectSettingsDto(setup: <String>['npm ci']),
      sourcePath: '/workspace/coder.json',
    ).toJson(),
    RpcMethod.sessionList: SessionListResultDto(
      sessions: <SessionDto>[agent],
    ).toJson(),
    RpcMethod.sessionCreate: SessionResultDto(session: agent).toJson(),
    RpcMethod.sessionModelSet: SessionResultDto(session: agent).toJson(),
    RpcMethod.sessionModeSet: SessionResultDto(session: agent).toJson(),
    RpcMethod.agentDefinitionList: AgentDefinitionListResultDto(
      definitions: <AgentDefinitionDto>[agentDefinition],
    ).toJson(),
    RpcMethod.agentDefinitionGet: AgentDefinitionResultDto(
      definition: agentDefinition,
    ).toJson(),
    RpcMethod.agentDefinitionCreate: AgentDefinitionResultDto(
      definition: agentDefinition,
    ).toJson(),
    RpcMethod.agentDefinitionUpdate: AgentDefinitionResultDto(
      definition: agentDefinition,
    ).toJson(),
    RpcMethod.agentDefinitionArchive: const <String, dynamic>{},
    RpcMethod.agentDefinitionReset: AgentDefinitionResultDto(
      definition: agentDefinition,
    ).toJson(),
    RpcMethod.agentDefinitionValidate: AgentDefinitionResultDto(
      definition: agentDefinition,
    ).toJson(),
    RpcMethod.agentToolCatalog: AgentToolCatalogResultDto(
      tools: <AgentToolDefinitionDto>[agentTool],
    ).toJson(),
    RpcMethod.providerCatalog: ProviderCatalogResultDto(
      catalog: ProviderCatalogDto(
        definitions: <ProviderDefinitionDto>[definition],
        source: ProviderCatalogSource.bundled,
        updatedAt: workspace.createdAt,
      ),
    ).toJson(),
    RpcMethod.providerConnectionsList: ProviderConnectionsResultDto(
      connections: <ProviderConnectionDto>[connection],
    ).toJson(),
    RpcMethod.providerConnectApiKey: ProviderConnectionResultDto(
      connection: connection,
    ).toJson(),
    RpcMethod.providerConnectNone: ProviderConnectionResultDto(
      connection: connection,
    ).toJson(),
    RpcMethod.providerAuthStart: ProviderAuthAttemptResultDto(
      attempt: attempt,
    ).toJson(),
    RpcMethod.providerAuthStatus: ProviderAuthAttemptResultDto(
      attempt: attempt,
    ).toJson(),
    RpcMethod.providerAuthCancel: const <String, dynamic>{},
    RpcMethod.providerDisconnect: const <String, dynamic>{},
    RpcMethod.providerDefaultSet: const <String, dynamic>{},
    RpcMethod.providerDefaultModelSet: const <String, dynamic>{},
    RpcMethod.providerCatalogRefresh: ProviderCatalogResultDto(
      catalog: ProviderCatalogDto(
        definitions: <ProviderDefinitionDto>[definition],
        source: ProviderCatalogSource.refreshed,
        updatedAt: workspace.createdAt,
      ),
    ).toJson(),
    RpcMethod.providerModelsList: ProviderModelsResultDto(
      models: <ProviderModelDto>[model],
    ).toJson(),
    RpcMethod.providerCustomCreate: ProviderConnectionResultDto(
      connection: connection,
    ).toJson(),
    RpcMethod.providerCustomUpdate: ProviderConnectionResultDto(
      connection: connection,
    ).toJson(),
    RpcMethod.providerCustomDelete: const <String, dynamic>{},
    RpcMethod.turnStart: const TurnStartResultDto(created: true).toJson(),
    RpcMethod.turnCancel: const <String, dynamic>{},
    RpcMethod.approvalResolve: ApprovalResultDto(approval: approval).toJson(),
    RpcMethod.timelineSubscribe: TimelineResultDto(
      events: <TimelineEventDto>[timeline],
    ).toJson(),
  };
  for (final entry in responses.entries) {
    peer.registerMethod(entry.key, (json_rpc.Parameters parameters) {
      requests.add((
        method: entry.key,
        payload: Map<String, dynamic>.from(parameters.asMap),
      ));
      return entry.value;
    });
  }
}
