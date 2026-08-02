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
    createdAt: now,
  );
  final agent = AgentDto(
    id: 'agent',
    workspaceId: workspace.id,
    title: 'Agent',
    providerId: 'provider',
    model: 'model',
    status: AgentStatus.idle,
    permissionMode: PermissionMode.ask,
    createdAt: now,
    updatedAt: now,
  );
  final provider = ApiProviderDto(
    id: 'provider',
    name: 'Provider',
    presetId: 'custom',
    baseUrl: 'http://localhost/v1',
    transport: ApiTransport.chatCompletions,
    credentialSource: CredentialSource.none,
    credentialConfigured: true,
    enabled: true,
    strictToolSchema: false,
    defaultModelId: 'model',
    createdAt: now,
    updatedAt: now,
  );
  const model = ProviderModelDto(
    providerId: 'provider',
    id: 'model',
    label: 'Model',
    source: ProviderModelSource.manual,
    capabilities: ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
    ),
  );
  final approval = ApprovalRequestDto(
    id: 'approval',
    agentId: agent.id,
    turnId: 'turn',
    toolCallId: 'call',
    toolName: 'apply_patch',
    risk: ToolRisk.write,
    arguments: const <String, dynamic>{'patch': 'diff'},
    status: ApprovalStatus.pending,
    createdAt: now,
  );
  final timeline = TimelineEventDto(
    agentId: agent.id,
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
            agent: agent,
            provider: provider,
            model: model,
            approval: approval,
            timeline: timeline,
          );
        },
      );
      final states = <ClientConnectionState>[];
      final clientFuture = CoderClient.connect(
        endpoint: HostEndpoint.parse(
          '127.0.0.1:7337',
          token: 'secret-token',
        ),
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
        const <String, String>{'Authorization': 'Bearer secret-token'},
      );
      expect(await client.listWorkspaces(), <WorkspaceDto>[workspace]);
      expect(
        await client.registerWorkspace(
          id: workspace.id,
          rootPath: workspace.rootPath,
          name: workspace.name,
        ),
        workspace,
      );
      expect(await client.listAgents(workspaceId: workspace.id), <AgentDto>[
        agent,
      ]);
      expect(
        await client.createAgent(
          id: agent.id,
          workspaceId: workspace.id,
          title: agent.title,
          providerId: agent.providerId,
          model: agent.model,
          permissionMode: agent.permissionMode,
        ),
        agent,
      );
      expect(
        await client.updateAgentConfiguration(
          agentId: agent.id,
          providerId: provider.id,
          model: model.id,
        ),
        agent,
      );
      final catalog = await client.listProviderCatalog();
      expect(catalog.providers, <ApiProviderDto>[provider]);
      expect(
        await client.upsertProvider(provider, makeDefault: true),
        provider,
      );
      await client.deleteProvider(provider.id);
      expect(await client.listProviderModels(provider.id), <ProviderModelDto>[
        model,
      ]);
      expect(
        await client.refreshProviderModels(provider.id),
        <ProviderModelDto>[
          model,
        ],
      );
      expect(await client.upsertProviderModel(model), model);
      await client.deleteProviderModel(provider.id, model.id);
      expect(
        (await client.diagnoseProviderModel(provider.id, model.id)).status,
        DiagnosticStatus.verified,
      );
      await client.setProviderCredential(provider.id, 'api-key');
      await client.clearProviderCredential(provider.id);
      await client.startTurn(
        agentId: agent.id,
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
        ..sendNotification(RpcNotification.agentUpdated, agent.toJson())
        ..sendNotification(
          RpcNotification.approvalRequested,
          approval.toJson(),
        );
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<TimelineClientEvent>(), hasLength(1));
      expect(events.whereType<AgentUpdatedClientEvent>().single.agent, agent);
      expect(
        events.whereType<ApprovalRequestedClientEvent>().single.approval,
        approval,
      );
      expect(
        connector.requests.map((request) => request.method),
        containsAll(<String>[
          RpcMethod.workspaceList,
          RpcMethod.workspaceRegister,
          RpcMethod.agentList,
          RpcMethod.agentCreate,
          RpcMethod.agentConfigurationUpdate,
          RpcMethod.providerList,
          RpcMethod.providerUpsert,
          RpcMethod.providerDelete,
          RpcMethod.providerModelsList,
          RpcMethod.providerModelsRefresh,
          RpcMethod.providerModelUpsert,
          RpcMethod.providerModelDelete,
          RpcMethod.providerModelDiagnose,
          RpcMethod.providerCredentialSet,
          RpcMethod.providerCredentialClear,
          RpcMethod.turnStart,
          RpcMethod.turnCancel,
          RpcMethod.approvalResolve,
          RpcMethod.timelineSubscribe,
        ]),
      );
      expect(states, isNot(contains(ClientConnectionState.disconnected)));
    },
  );

  test('RPC errors preserve daemon code and retryability', () async {
    final connector = _TestConnector(
      onConfigure: (peer, requests) {
        _registerHello(peer, requests);
        peer.registerMethod(RpcMethod.workspaceList, (_) {
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
      endpoint: HostEndpoint.parse('ws://localhost/ws', token: 'token'),
      clientId: 'client',
      clientKind: 'test',
      connector: connector,
    );
    addTearDown(client.close);

    await expectLater(
      client.listWorkspaces(),
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
          RpcMethod.workspaceList,
          (_) => Completer<Map<String, dynamic>>().future,
        );
      },
    );
    final client = await CoderClient.connect(
      endpoint: HostEndpoint.parse('ws://localhost/ws', token: 'token'),
      clientId: 'client',
      clientKind: 'test',
      connector: connector,
      requestTimeout: const Duration(milliseconds: 10),
    );
    await expectLater(
      client.listWorkspaces(),
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
        endpoint: HostEndpoint.parse('ws://localhost/ws', token: 'token'),
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
      features: <String, bool>{'providerAdmin': true},
    ).toJson();
  });
}

void _registerFixtureMethods(
  json_rpc.Peer peer,
  List<_Request> requests, {
  required WorkspaceDto workspace,
  required AgentDto agent,
  required ApiProviderDto provider,
  required ProviderModelDto model,
  required ApprovalRequestDto approval,
  required TimelineEventDto timeline,
}) {
  _registerHello(peer, requests);
  final diagnostic = ProviderDiagnosticDto(
    providerId: provider.id,
    model: model.id,
    status: DiagnosticStatus.verified,
    endpointReachable: true,
    streaming: true,
    toolCalling: true,
    checkedAt: workspace.createdAt,
  );
  final responses = <String, Map<String, dynamic>>{
    RpcMethod.workspaceList: WorkspaceListResultDto(
      workspaces: <WorkspaceDto>[workspace],
    ).toJson(),
    RpcMethod.workspaceRegister: WorkspaceResultDto(
      workspace: workspace,
    ).toJson(),
    RpcMethod.agentList: AgentListResultDto(agents: <AgentDto>[agent]).toJson(),
    RpcMethod.agentCreate: AgentResultDto(agent: agent).toJson(),
    RpcMethod.agentConfigurationUpdate: AgentResultDto(agent: agent).toJson(),
    RpcMethod.providerList: ProviderCatalogResultDto(
      catalog: ProviderCatalogDto(
        providers: <ApiProviderDto>[provider],
        presets: const <ProviderPresetDto>[],
        defaultProviderId: provider.id,
      ),
    ).toJson(),
    RpcMethod.providerUpsert: ProviderResultDto(provider: provider).toJson(),
    RpcMethod.providerDelete: const <String, dynamic>{},
    RpcMethod.providerModelsList: ProviderModelsResultDto(
      models: <ProviderModelDto>[model],
    ).toJson(),
    RpcMethod.providerModelsRefresh: ProviderModelsResultDto(
      models: <ProviderModelDto>[model],
    ).toJson(),
    RpcMethod.providerModelUpsert: ProviderModelResultDto(
      model: model,
    ).toJson(),
    RpcMethod.providerModelDelete: const <String, dynamic>{},
    RpcMethod.providerModelDiagnose: ProviderDiagnosticResultDto(
      diagnostic: diagnostic,
    ).toJson(),
    RpcMethod.providerCredentialSet: const <String, dynamic>{},
    RpcMethod.providerCredentialClear: const <String, dynamic>{},
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
