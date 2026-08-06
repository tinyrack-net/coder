import 'dart:async';

import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/composer_commands.dart';
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
      const override = SessionModelSelectionDto(
        providerConnectionId: 'openai',
        modelId: 'gpt-5.6-sol',
      );
      final created = await container
          .read(agentsProvider.notifier)
          .create(
            title: 'Created',
            agentDefinitionId: 'coder',
            mode: SessionMode.plan,
            model: override,
          );
      expect(created.id, 'generated-id');
      expect(created.model, override);
      expect(created.mode, SessionMode.plan);
      expect(container.read(agentsProvider).value!.first, created);
      expect(
        (await container
                .read(agentsProvider.notifier)
                .setModel(created.id, null))
            .model,
        isNull,
      );
      expect(api.updatedSessionModels.single.sessionId, created.id);
      expect(
        (await container
                .read(agentsProvider.notifier)
                .setMode(created.id, SessionMode.plan))
            .mode,
        SessionMode.plan,
      );
      expect(api.updatedSessionModes.single.mode, SessionMode.plan);
      expect(
        container
            .read(agentsProvider)
            .value!
            .firstWhere((item) => item.id == created.id)
            .model,
        isNull,
      );
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

  test(
    'the home checkout resolves per host and is kept out of projects',
    () {
      final home = WorkspaceDto(
        id: 'home',
        name: 'user',
        rootPath: '/home/user',
        kind: WorkspaceKind.home,
        createdAt: now,
      );
      final homeCheckout = WorktreeDto(
        id: 'home-checkout',
        workspaceId: home.id,
        name: home.name,
        path: home.rootPath,
        kind: WorktreeKind.directory,
        isCoderOwned: false,
        createdAt: now,
      );
      final state = UnifiedWorkspaceCatalogState(
        hosts: const <String, HostRuntimeSnapshot>{},
        catalogs: <String, WorkspaceCatalogDto>{
          'with-home': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[workspace, home],
            worktrees: <WorktreeDto>[worktree, homeCheckout],
          ),
          'without-home': WorkspaceCatalogDto(
            workspaces: <WorkspaceDto>[workspace],
            worktrees: <WorktreeDto>[worktree],
          ),
        },
      );

      expect(
        state.homeSelection('with-home'),
        const WorkspaceSelection(
          hostId: 'with-home',
          workspaceId: 'home',
          worktreeId: 'home-checkout',
        ),
      );
      // A daemon configured without a user home offers no project-less start.
      expect(state.homeSelection('without-home'), isNull);
      expect(state.homeSelection('unknown'), isNull);
    },
    tags: const <String>['feature_test__session_home__unit'],
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
    'queued prompts start one per turn and survive a failed send',
    () async {
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
          appIdGeneratorProvider.overrideWithValue(_SequentialIdGenerator()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      final listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);
      await container.read(provider.future);
      // A prompt only queues because a turn is running.
      api.emit(
        SessionUpdatedClientEvent(
          agent.copyWith(status: SessionStatus.running),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      container.read(provider.notifier)
        ..enqueueTurn('  first  ')
        ..enqueueTurn('second')
        // Neither empty text nor empty attachments is worth a turn.
        ..enqueueTurn('   ');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(provider).value!.queued.map((item) => item.text),
        <String>['first', 'second'],
      );

      // A settled session releases exactly one prompt, so each queued
      // follow-up gets a turn of its own.
      api.emit(
        SessionUpdatedClientEvent(agent.copyWith(status: SessionStatus.idle)),
      );
      await Future<void>.delayed(Duration.zero);
      expect(api.startedPrompts, <String>['first']);
      expect(
        container.read(provider).value!.queued.map((item) => item.text),
        <String>['second'],
      );

      // A send that fails puts its prompt back at the head rather than
      // dropping it.
      api
        ..startTurnError = Exception('offline')
        ..emit(
          SessionUpdatedClientEvent(agent.copyWith(status: SessionStatus.idle)),
        );
      await Future<void>.delayed(Duration.zero);
      expect(api.startedPrompts, <String>['first']);
      expect(
        container.read(provider).value!.queued.map((item) => item.text),
        <String>['second'],
      );

      api
        ..startTurnError = null
        ..emit(
          SessionUpdatedClientEvent(
            agent.copyWith(status: SessionStatus.failed),
          ),
        );
      await Future<void>.delayed(Duration.zero);
      expect(api.startedPrompts, <String>['first', 'second']);
      expect(container.read(provider).value!.queued, isEmpty);
    },
    tags: const <String>['feature_test__conversation_turn_queue__unit'],
  );

  test(
    'a prompt queued after the turn already settled still starts',
    () async {
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
          appIdGeneratorProvider.overrideWithValue(_SequentialIdGenerator()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      final listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);
      await container.read(provider.future);

      // The composer reads a rendered flag that trails the daemon, so it can
      // queue one frame after the session went idle. No further session update
      // is coming, so nothing but the enqueue itself can release the prompt.
      container.read(provider.notifier).enqueueTurn('late');
      await Future<void>.delayed(Duration.zero);

      expect(api.startedPrompts, <String>['late']);
      expect(container.read(provider).value!.queued, isEmpty);
    },
    tags: const <String>['feature_test__conversation_turn_queue__unit'],
  );

  test(
    'a queued prompt can be taken back or promoted past the active turn',
    () async {
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
          appIdGeneratorProvider.overrideWithValue(_SequentialIdGenerator()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      final listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier)
        ..enqueueTurn('edit me')
        ..enqueueTurn('send me');
      final queued = container.read(provider).value!.queued;

      expect(notifier.takeQueuedTurn(queued.first.id)?.text, 'edit me');
      expect(notifier.takeQueuedTurn('missing'), isNull);
      expect(
        container.read(provider).value!.queued.map((item) => item.text),
        <String>['send me'],
      );

      await notifier.sendQueuedTurnNow(queued.last.id);
      expect(api.cancelledAgents, <String>[agent.id]);
      expect(api.startedPrompts, <String>['send me']);
      expect(container.read(provider).value!.queued, isEmpty);

      notifier.enqueueTurn('doomed');
      final doomed = container.read(provider).value!.queued.single;
      api.startTurnError = Exception('offline');
      await expectLater(
        notifier.sendQueuedTurnNow(doomed.id),
        throwsException,
      );
      expect(
        container.read(provider).value!.queued.map((item) => item.text),
        <String>['doomed'],
      );
    },
    tags: const <String>['feature_test__conversation_turn_queue__unit'],
  );

  test(
    'a turn setting shows before the daemon confirms it and rolls back',
    () async {
      final api = FakeCoderApi(
        worktrees: <WorktreeDto>[worktree],
        agents: <SessionDto>[agent],
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = sessionsControllerProvider('server', worktree.id);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);
      final gate = Completer<void>();
      api.sessionUpdateGate = gate;
      final pending = notifier.setMode(agent.id, SessionMode.plan);
      // The chip must not wait a round trip to flip.
      expect(container.read(provider).value!.single.mode, SessionMode.plan);
      gate.complete();
      expect((await pending).mode, SessionMode.plan);

      api
        ..sessionUpdateGate = null
        ..sessionUpdateError = Exception('offline');
      await expectLater(
        notifier.setMode(agent.id, SessionMode.normal),
        throwsException,
      );
      expect(container.read(provider).value!.single.mode, SessionMode.plan);
    },
    tags: const <String>['feature_test__session_lifecycle__unit'],
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
      expect(initial.connections.single.id, 'openai');

      await notifier.loadModels('openai');
      expect(
        container.read(provider).value!.models['openai'],
        <ProviderModelDto>[model],
      );
      final connected = await notifier.connectApiKey(
        'deepseek',
        'secret',
      );
      expect(connected.definitionId, 'deepseek');
      expect(api.credentials['deepseek'], 'secret');
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
    'provider settings retains every concurrent model catalog result',
    () async {
      const first = ProviderModelDto(
        connectionId: 'first',
        id: 'first/very-long-model-identifier',
        label: 'First very long model label',
        source: ProviderModelSource.discovered,
        capabilities: ModelCapabilitiesDto(),
      );
      const second = ProviderModelDto(
        connectionId: 'second',
        id: 'second/very-long-model-identifier',
        label: 'Second very long model label',
        source: ProviderModelSource.discovered,
        capabilities: ModelCapabilitiesDto(),
      );
      final api = FakeCoderApi(
        models: const <String, List<ProviderModelDto>>{
          'first': <ProviderModelDto>[first],
          'second': <ProviderModelDto>[second],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = providerSettingsControllerProvider('server');
      await container.read(provider.future);

      await Future.wait(<Future<void>>[
        container.read(provider.notifier).loadModels('first'),
        container.read(provider.notifier).loadModels('second'),
      ]);

      // The build already seeds the first usable connection, so assert that
      // neither concurrent load dropped the other rather than the exact map.
      expect(
        container.read(provider).value!.models,
        allOf(
          containsPair('first', const <ProviderModelDto>[first]),
          containsPair('second', const <ProviderModelDto>[second]),
        ),
      );
    },
    tags: const <String>['feature_test__provider_catalog__unit'],
  );

  test(
    'MCP reload ignores an older response that completes last',
    () async {
      const config = McpServerConfigDto(
        id: 'e2e',
        transport: McpTransportKind.stdio,
        command: '/missing',
      );
      const connecting = McpServerStateDto(
        config: config,
        scope: McpConfigScope.user,
        sourcePath: '/config/mcp.json',
        status: McpServerStatus.connecting,
      );
      const failed = McpServerStateDto(
        config: config,
        scope: McpConfigScope.user,
        sourcePath: '/config/mcp.json',
        status: McpServerStatus.failed,
        error: 'planned process failure',
      );
      final api = FakeCoderApi();
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = mcpServersControllerProvider('server', null);
      await container.read(provider.future);

      final older = Completer<List<McpServerStateDto>>();
      final newer = Completer<List<McpServerStateDto>>();
      api.mcpListResponses.addAll(<Future<List<McpServerStateDto>>>[
        older.future,
        newer.future,
      ]);
      final first = container.read(provider.notifier).refresh();
      final second = container.read(provider.notifier).refresh();
      newer.complete(const <McpServerStateDto>[failed]);
      await second;
      older.complete(const <McpServerStateDto>[connecting]);
      await first;

      expect(container.read(provider).value!.servers, <McpServerStateDto>[
        failed,
      ]);
    },
    tags: const <String>['feature_test__mcp_server_management__unit'],
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

  test(
    'agent commands load once and reload when the daemon reports a change',
    () async {
      final api = FakeCoderApi(
        commands: <AgentCommandDto>[_agentCommand('review')],
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);

      final provider = agentCommandsControllerProvider('server', null);
      final listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);

      expect(
        (await container.read(provider.future)).map((item) => item.name),
        <String>['review'],
      );

      api.commands.add(_agentCommand('ship'));
      api.emit(const CommandsChangedClientEvent());
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(provider).value!.map((item) => item.name),
        <String>['review', 'ship'],
      );
      unawaited(api.close());
    },
    tags: const <String>['feature_test__composer_slash_command__unit'],
  );

  test(
    'the composer catalog merges app, agent, and skill commands',
    () async {
      final api = FakeCoderApi(
        commands: <AgentCommandDto>[_agentCommand('review')],
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);

      final commands = await container.read(
        composerCommandsProvider('server', null).future,
      );

      expect(
        commands.map((command) => command.kind).toSet(),
        containsAll(<ComposerCommandKind>[
          ComposerCommandKind.client,
          ComposerCommandKind.agent,
          ComposerCommandKind.skill,
        ]),
      );
      expect(
        commands.singleWhere((command) => command.name == 'review').kind,
        ComposerCommandKind.agent,
      );
      unawaited(api.close());
    },
    tags: const <String>['feature_test__composer_slash_command__unit'],
  );

  test(
    'a file search waits out its debounce and re-ranks what it receives',
    () async {
      final api = FakeCoderApi(
        files: <String, List<String>>{
          'worktree': <String>['docs/composer.md', 'lib/composer.dart'],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);

      final provider = composerFileSearchProvider(
        'server',
        'worktree',
        'composer',
      );
      final listener = container.listen(provider, (_, _) {});
      addTearDown(listener.close);

      // Nothing reaches the daemon until the debounce elapses.
      await Future<void>.delayed(Duration.zero);
      expect(api.searchedQueries, isEmpty);

      final matches = await container.read(provider.future);

      expect(api.searchedQueries, <String>['composer']);
      // The basename match outranks the one that only matches through a
      // directory segment.
      expect(matches.first.relativePath, 'lib/composer.dart');
      unawaited(api.close());
    },
    tags: const <String>['feature_test__composer_file_mention__unit'],
  );

  test(
    'a file search abandoned inside its debounce never reaches the daemon',
    () async {
      final api = FakeCoderApi(
        files: <String, List<String>>{
          'worktree': <String>['lib/composer.dart'],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Each keystroke is its own provider, so an abandoned one disposes and
      // cancels its timer before the daemon is ever asked.
      for (final query in <String>['c', 'co', 'com']) {
        final listener = container.listen(
          composerFileSearchProvider('server', 'worktree', query),
          (_, _) {},
        );
        await Future<void>.delayed(Duration.zero);
        listener.close();
      }
      await Future<void>.delayed(composerFileSearchDebounce * 2);

      expect(api.searchedQueries, isEmpty);
      unawaited(api.close());
    },
    tags: const <String>['feature_test__composer_file_mention__unit'],
  );
}

AgentCommandDto _agentCommand(String name) => AgentCommandDto(
  id: name,
  name: name,
  description: 'Runs $name.',
  source: AgentCommandSource.project,
  sourcePath: '/workspace/.agents/commands/$name.md',
  body: 'Run $name.',
);

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
  features: const <String, bool>{},
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

final class _SequentialIdGenerator implements AppIdGenerator {
  var _next = 0;

  @override
  String generate() => 'generated-id-${_next++}';
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
