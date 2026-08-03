import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

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
  final approvalEvent = TimelineEventDto(
    sessionId: agent.id,
    sequence: 1,
    turnId: 'turn',
    type: 'approval.requested',
    data: <String, dynamic>{'approval': approval.toJson()},
    createdAt: now,
  );
  const model = ProviderModelDto(
    connectionId: 'openai',
    id: 'gpt-5.6-sol',
    label: 'GPT',
    source: ProviderModelSource.bundled,
    capabilities: ModelCapabilitiesDto(
      streaming: CapabilitySupport.supported,
      toolCalling: CapabilitySupport.supported,
    ),
  );

  test(
    'connection, workspace, and agent notifiers own their feature state',
    () async {
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[worktree],
        agents: <SessionDto>[agent],
      );
      final container = _container(api);
      addTearDown(container.dispose);

      await container.read(
        hostRegistryControllerProvider.future,
      );
      await Future<void>.delayed(Duration.zero);
      final runtime = container
          .read(hostRegistryControllerProvider)
          .value!
          .runtimes['server']!;
      expect(runtime.connected, isTrue);
      expect(runtime.serverInfo!.serverId, 'server');

      api.emitState(ClientConnectionState.reconnecting);
      await Future<void>.delayed(Duration.zero);
      expect(
        container
            .read(hostRegistryControllerProvider)
            .value!
            .runtimes['server']!
            .status,
        HostRuntimeStatus.reconnecting,
      );
      api.emitState(ClientConnectionState.connected);

      final catalog = await container.read(
        workspaceCatalogControllerProvider.future,
      );
      expect(catalog.catalogs['server']?.workspaces, <WorkspaceDto>[workspace]);
      final registered = await container
          .read(workspaceCatalogControllerProvider.notifier)
          .register('server', '/workspace/new');
      expect(registered.workspace.id, 'generated-id');
      expect(registered.workspace.name, 'new');
      expect(
        container
            .read(workspaceCatalogControllerProvider)
            .value
            ?.catalogs['server']
            ?.workspaces,
        hasLength(2),
      );

      final agentsProvider = sessionsControllerProvider('server', worktree.id);
      expect(await container.read(agentsProvider.future), <SessionDto>[agent]);
      final created = await container
          .read(agentsProvider.notifier)
          .create(
            title: 'Created',
            agentDefinitionId: 'coder',
          );
      expect(created.id, 'generated-id');
      expect(container.read(agentsProvider).value!.first, created);
      api.emit(
        SessionUpdatedClientEvent(
          agent.copyWith(status: SessionStatus.running),
        ),
      );
      expect(
        container.read(agentsProvider).value!.last.status,
        SessionStatus.running,
      );
      final delegated = agent.copyWith(
        id: 'delegated',
        title: 'Reviewer',
        parentSessionId: agent.id,
        origin: SessionOrigin.delegated,
      );
      api.emit(SessionUpdatedClientEvent(delegated));
      expect(
        container.read(agentsProvider).value!.map((item) => item.id),
        contains(delegated.id),
      );

      expect(
        await container.read(sessionsControllerProvider('server', null).future),
        isEmpty,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
  );

  test('feature families never mix state between connected hosts', () async {
    WorkspaceDto hostWorkspace(String host) => WorkspaceDto(
      id: 'workspace',
      name: '$host workspace',
      rootPath: '/$host',
      kind: WorkspaceKind.directory,
      createdAt: now,
    );
    SessionDto hostAgent(String host) => agent.copyWith(title: '$host agent');
    TimelineEventDto hostEvent(String host) => TimelineEventDto(
      sessionId: agent.id,
      sequence: 1,
      turnId: 'turn',
      type: 'assistant.delta',
      data: <String, dynamic>{'text': host},
      createdAt: now,
    );
    ProviderCatalogDto hostCatalog(String host) => ProviderCatalogDto(
      definitions: <ProviderDefinitionDto>[
        ProviderDefinitionDto(
          id: host,
          name: host,
          description: host,
          authMethods: const <ProviderAuthMethodDto>[],
        ),
      ],
      source: ProviderCatalogSource.bundled,
      updatedAt: now,
    );
    final firstApi = FakeCoderApi(
      serverInfo: _serverInfo('first-server'),
      workspaces: <WorkspaceDto>[hostWorkspace('first')],
      worktrees: <WorktreeDto>[worktree],
      agents: <SessionDto>[hostAgent('first')],
      timelines: <String, List<TimelineEventDto>>{
        agent.id: <TimelineEventDto>[hostEvent('first')],
      },
      catalog: hostCatalog('first'),
    );
    final secondApi = FakeCoderApi(
      serverInfo: _serverInfo('second-server'),
      workspaces: <WorkspaceDto>[hostWorkspace('second')],
      worktrees: <WorktreeDto>[worktree],
      agents: <SessionDto>[hostAgent('second')],
      timelines: <String, List<TimelineEventDto>>{
        agent.id: <TimelineEventDto>[hostEvent('second')],
      },
      catalog: hostCatalog('second'),
    );
    final store = MemoryAppStore(
      settings: const AppSettings(embeddedDaemonEnabled: false),
      profiles: <RemoteDaemonProfile>[
        _profile('first', now),
        _profile('second', now),
      ],
      tokens: const <String, String>{'first': 'one', 'second': 'two'},
    );
    final container = ProviderContainer(
      overrides: [
        appServicesProvider.overrideWithValue(
          AppServices(
            settings: store,
            profiles: store,
            credentials: store,
            clients: _HostClients(<String, CoderApi>{
              'first.test': firstApi,
              'second.test': secondApi,
            }),
            clientKind: 'test',
          ),
        ),
        appIdGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(hostRegistryControllerProvider.future);
    await Future<void>.delayed(Duration.zero);

    final catalogs = await container.read(
      workspaceCatalogControllerProvider.future,
    );
    expect(
      catalogs.catalogs['first']?.workspaces.single.name,
      'first workspace',
    );
    expect(
      catalogs.catalogs['second']?.workspaces.single.name,
      'second workspace',
    );
    expect(
      (await container.read(
        sessionsControllerProvider('first', 'worktree').future,
      )).single.title,
      'first agent',
    );
    expect(
      (await container.read(
        sessionsControllerProvider('second', 'worktree').future,
      )).single.title,
      'second agent',
    );
    expect(
      (await container.read(
        conversationControllerProvider('first', agent.id).future,
      )).timeline.single.data['text'],
      'first',
    );
    expect(
      (await container.read(
        conversationControllerProvider('second', agent.id).future,
      )).timeline.single.data['text'],
      'second',
    );
    expect(
      (await container.read(
        providerSettingsControllerProvider('first').future,
      ))!.catalog.definitions.single.id,
      'first',
    );
    expect(
      (await container.read(
        providerSettingsControllerProvider('second').future,
      ))!.catalog.definitions.single.id,
      'second',
    );
  });

  test(
    'session tabs close locally and persist independently per worktree',
    () async {
      final second = agent.copyWith(id: 'agent-2', title: 'Second');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[worktree],
        agents: <SessionDto>[agent, second],
      );
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
        profiles: <RemoteDaemonProfile>[_profile('server', now)],
        tokens: const <String, String>{'server': 'token'},
      );
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(
            AppServices(
              settings: store,
              profiles: store,
              credentials: store,
              clients: _HostClients(<String, CoderApi>{
                'server.test': api,
              }),
              clientKind: 'test',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      const selection = WorkspaceSelection(
        hostId: 'server',
        workspaceId: 'workspace',
        worktreeId: 'worktree',
      );
      final provider = sessionTabsControllerProvider(selection);
      expect((await container.read(provider.future)).openAgentIds, <String>[
        'agent',
      ]);

      await container.read(provider.notifier).open(second.id);
      await container.read(provider.notifier).close(agent.id);

      expect(container.read(provider).requireValue.openAgentIds, <String>[
        second.id,
      ]);
      expect(
        store.settings.sessionTabs[selection.storageKey]?.selectedAgentId,
        second.id,
      );
      expect(await api.listSessions(worktreeId: worktree.id), hasLength(2));
    },
    tags: const <String>['feature_test__session_tabs__unit'],
  );

  test(
    'conversation notifier deduplicates timeline and resolves approvals',
    () async {
      final api = FakeCoderApi(
        agents: <SessionDto>[agent],
        timelines: <String, List<TimelineEventDto>>{
          agent.id: <TimelineEventDto>[approvalEvent],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      final initial = await container.read(provider.future);
      expect(initial.timeline, <TimelineEventDto>[approvalEvent]);
      expect(initial.approvals[approval.id], approval);

      api
        ..emit(TimelineClientEvent(approvalEvent))
        ..emit(
          TimelineClientEvent(
            TimelineEventDto(
              sessionId: agent.id,
              sequence: 2,
              turnId: 'turn',
              type: 'assistant.delta',
              data: const <String, dynamic>{'text': 'hello'},
              createdAt: now,
            ),
          ),
        )
        ..emit(
          ApprovalRequestedClientEvent(approval.copyWith(id: 'approval-2')),
        );
      expect(container.read(provider).value!.timeline, hasLength(2));
      expect(container.read(provider).value!.approvals, hasLength(2));

      await container.read(provider.notifier).startTurn('  prompt  ');
      await container.read(provider.notifier).startTurn('   ');
      expect(api.startedPrompts, <String>['prompt']);
      expect(api.startedTurnIds, <String>['generated-id']);
      await container.read(provider.notifier).cancelTurn();
      expect(api.cancelledAgents, <String>[agent.id]);
      await container
          .read(provider.notifier)
          .resolveApproval(approval.id, approved: false);
      expect(api.approvalDecisions.single.approved, isFalse);
      expect(
        container.read(provider).value!.approvals,
        isNot(contains(approval.id)),
      );

      api.emit(
        TimelineClientEvent(
          TimelineEventDto(
            sessionId: agent.id,
            sequence: 3,
            turnId: 'turn',
            type: 'approval.resolved',
            data: const <String, dynamic>{'approvalId': 'approval-2'},
            createdAt: now,
          ),
        ),
      );
      expect(container.read(provider).value!.approvals, isEmpty);
      expect(
        await container.read(
          conversationControllerProvider('server', null).future,
        ),
        const ConversationState(),
      );
    },
    tags: const <String>['feature_test__turn_execution__unit'],
  );

  test(
    'conversation ignores a transport event delivered after disposal',
    () async {
      final lateEvents = _LateClientEventStream();
      final api = FakeCoderApi(
        agents: <SessionDto>[agent],
        eventStream: lateEvents,
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      final listener = container.listen(provider, (_, _) {});
      await container.read(provider.future);

      listener.close();
      await Future<void>.delayed(Duration.zero);

      expect(
        () => lateEvents.emit(
          TimelineClientEvent(
            TimelineEventDto(
              sessionId: agent.id,
              sequence: 1,
              type: 'assistant.delta',
              data: const <String, dynamic>{'text': 'late'},
              createdAt: now,
            ),
          ),
        ),
        returnsNormally,
      );
    },
  );

  test(
    'provider settings notifier performs every administrative command',
    () async {
      final api = FakeCoderApi(
        models: const <String, List<ProviderModelDto>>{
          'openai': <ProviderModelDto>[model],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = providerSettingsControllerProvider('server');
      final notifier = container.read(provider.notifier);
      final initial = await container.read(
        provider.future,
      );
      expect(initial!.catalog.definitions.first.id, 'openai');
      expect(initial.connections.single.isDefault, isTrue);
      expect(notifier.canManage, isTrue);

      await notifier.loadModels('openai');
      expect(
        container.read(provider).value!.models['openai'],
        <ProviderModelDto>[model],
      );
      final connected = await notifier.connectApiKey(
        'deepseek',
        'secret',
        makeDefault: true,
      );
      expect(connected.definitionId, 'deepseek');
      expect(api.credentials['deepseek'], 'secret');
      await notifier.setDefaultModel('openai', 'gpt-5.6-sol');
      await notifier.setDefault('openai');
      final attempt = await notifier.startAuth(
        'openai',
        'chatgpt-browser',
      );
      expect(attempt.status, ProviderAuthAttemptStatus.awaitingUser);
      await notifier.cancelAuth(attempt.id);
      await notifier.refreshCatalog();
      expect(
        container.read(provider).value!.catalog.source,
        ProviderCatalogSource.refreshed,
      );
      final custom = await notifier.createCustom(
        'custom',
        const CustomProviderConfigDto(
          name: 'Custom',
          baseUrl: 'http://127.0.0.1:9000/v1',
          apiFormat: ProviderApiFormat.chatCompletions,
          authenticationRequired: false,
          manualModelIds: <String>['manual'],
        ),
      );
      expect(custom.displayName, 'Custom');
      await notifier.updateCustom(
        custom.id,
        custom.customConfig!.copyWith(name: 'Updated'),
      );
      await notifier.deleteCustom(custom.id);
      await notifier.disconnect('deepseek');
      expect(
        container
            .read(provider)
            .value!
            .connections
            .singleWhere((item) => item.id == 'deepseek')
            .status,
        ProviderConnectionStatus.disconnected,
      );
    },
  );

  test(
    'feature state value objects and production ports are deterministic',
    () {
      final api = FakeCoderApi();
      final endpoint = HostEndpoint.parse('ws://localhost/ws');
      final snapshot = HostRuntimeSnapshot(
        id: 'host',
        label: 'Host',
        kind: HostKind.remote,
        status: HostRuntimeStatus.offline,
        api: api,
        endpoint: endpoint,
      );
      expect(snapshot.connected, isFalse);
      expect(
        snapshot.copyWith(status: HostRuntimeStatus.connecting).status,
        HostRuntimeStatus.connecting,
      );
      const conversation = ConversationState();
      expect(
        conversation.copyWith(timeline: <TimelineEventDto>[]).timeline,
        isEmpty,
      );
      final catalog = ProviderCatalogDto(
        definitions: const <ProviderDefinitionDto>[],
        source: ProviderCatalogSource.bundled,
        updatedAt: now,
      );
      final settings = ProviderSettingsState(
        catalog: catalog,
        connections: const <ProviderConnectionDto>[],
      );
      expect(
        settings
            .copyWith(models: const <String, List<ProviderModelDto>>{})
            .catalog,
        catalog,
      );
      expect(const SystemAppClock().nowUtc().isUtc, isTrue);
      expect(const UuidAppIdGenerator().generate(), isNotEmpty);
      expect(
        const HostConnectionFailure.network('offline').toString(),
        'offline',
      );
      unawaited(api.close());
    },
  );
}

ProviderContainer _container(FakeCoderApi api) => ProviderContainer(
  overrides: [
    appServicesProvider.overrideWithValue(fakeAppServices(api)),
    appIdGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
  ],
);

RemoteDaemonProfile _profile(String id, DateTime now) => RemoteDaemonProfile(
  id: id,
  label: id,
  websocketUri: Uri.parse('ws://$id.test/ws'),
  autoConnect: true,
  createdAt: now,
  updatedAt: now,
);

ServerInfoDto _serverInfo(String id) => ServerInfoDto(
  serverId: id,
  version: 'test',
  protocolVersion: coderProtocolVersion,
  features: const <String, bool>{'providerAdmin': true},
);

final class _HostClients implements HostClientFactory {
  const _HostClients(this.apis);

  final Map<String, CoderApi> apis;

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) async => apis[endpoint.websocketUri.host]!;
}

final class _FixedIdGenerator implements AppIdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => 'generated-id';
}

final class _LateClientEventStream extends Stream<ClientEvent> {
  void Function(ClientEvent)? _onData;

  @override
  StreamSubscription<ClientEvent> listen(
    void Function(ClientEvent)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _onData = onData;
    return const Stream<ClientEvent>.empty().listen(
      null,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void emit(ClientEvent event) => _onData?.call(event);
}
