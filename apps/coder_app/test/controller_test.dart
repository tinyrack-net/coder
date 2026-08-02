import 'dart:async';

import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/ports.dart';
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
    createdAt: now,
  );
  final agent = AgentDto(
    id: 'agent',
    workspaceId: workspace.id,
    title: 'Agent',
    providerId: 'openai',
    model: 'gpt-5.6-sol',
    status: AgentStatus.idle,
    permissionMode: PermissionMode.ask,
    createdAt: now,
    updatedAt: now,
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
  final approvalEvent = TimelineEventDto(
    agentId: agent.id,
    sequence: 1,
    turnId: 'turn',
    type: 'approval.requested',
    data: <String, dynamic>{'approval': approval.toJson()},
    createdAt: now,
  );
  const model = ProviderModelDto(
    providerId: 'openai',
    id: 'gpt-5.6-sol',
    label: 'GPT',
    source: ProviderModelSource.preset,
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
        agents: <AgentDto>[agent],
      );
      final container = _container(api);
      addTearDown(container.dispose);

      final connection = await container.read(
        connectionControllerProvider.future,
      );
      expect(connection, isNotNull);
      expect(connection!.connected, isTrue);
      expect(connection.connecting, isFalse);
      expect(connection.label, '127.0.0.1:7337');
      expect(connection.serverInfo.serverId, 'server');
      expect(
        container
            .read(connectionControllerProvider.notifier)
            .canRegisterLocalWorkspace,
        isTrue,
      );

      api.emitState(ClientConnectionState.reconnecting);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(connectionControllerProvider).value!.connecting,
        isTrue,
      );
      api.emitState(ClientConnectionState.connected);

      expect(
        await container.read(workspacesControllerProvider.future),
        <WorkspaceDto>[
          workspace,
        ],
      );
      final registered = await container
          .read(workspacesControllerProvider.notifier)
          .register('/workspace/new');
      expect(registered.id, 'generated-id');
      expect(registered.name, 'new');
      expect(container.read(workspacesControllerProvider).value, hasLength(2));

      final agentsProvider = agentsControllerProvider(workspace.id);
      expect(await container.read(agentsProvider.future), <AgentDto>[agent]);
      final created = await container
          .read(agentsProvider.notifier)
          .create(
            title: 'Created',
            providerId: 'openai',
            model: 'gpt-5.6-sol',
            reasoningEffort: 'high',
            permissionMode: PermissionMode.workspaceWrite,
          );
      expect(created.id, 'generated-id');
      expect(container.read(agentsProvider).value!.first, created);
      final updated = await container
          .read(agentsProvider.notifier)
          .updateConfiguration(
            agentId: agent.id,
            providerId: 'openai',
            model: 'gpt-5.6-terra',
            reasoningEffort: 'low',
          );
      expect(updated.model, 'gpt-5.6-terra');
      api.emit(
        AgentUpdatedClientEvent(updated.copyWith(status: AgentStatus.running)),
      );
      expect(
        container.read(agentsProvider).value!.last.status,
        AgentStatus.running,
      );

      expect(
        await container.read(agentsControllerProvider(null).future),
        isEmpty,
      );
    },
  );

  test(
    'conversation notifier deduplicates timeline and resolves approvals',
    () async {
      final api = FakeCoderApi(
        agents: <AgentDto>[agent],
        timelines: <String, List<TimelineEventDto>>{
          agent.id: <TimelineEventDto>[approvalEvent],
        },
      );
      final container = _container(api);
      addTearDown(container.dispose);
      final provider = conversationControllerProvider(agent.id);
      final initial = await container.read(provider.future);
      expect(initial.timeline, <TimelineEventDto>[approvalEvent]);
      expect(initial.approvals[approval.id], approval);

      api
        ..emit(TimelineClientEvent(approvalEvent))
        ..emit(
          TimelineClientEvent(
            TimelineEventDto(
              agentId: agent.id,
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
            agentId: agent.id,
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
        await container.read(conversationControllerProvider(null).future),
        const ConversationState(),
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
      final notifier = container.read(
        providerSettingsControllerProvider.notifier,
      );
      final initial = await container.read(
        providerSettingsControllerProvider.future,
      );
      expect(initial!.catalog.defaultProviderId, 'openai');
      expect(notifier.canManage, isTrue);

      await notifier.loadModels('openai');
      expect(
        container
            .read(providerSettingsControllerProvider)
            .value!
            .models['openai'],
        <ProviderModelDto>[model],
      );
      await notifier.refreshModels('openai');
      final provider = initial.catalog.providers.single.copyWith(
        credentialSource: CredentialSource.stored,
      );
      await notifier.saveProvider(
        provider,
        apiKey: 'secret',
        makeDefault: true,
      );
      expect(api.credentials['openai'], 'secret');
      await notifier.saveProvider(provider, apiKey: '');

      final manual = model.copyWith(
        id: 'manual',
        label: 'Manual',
        source: ProviderModelSource.manual,
      );
      expect(await notifier.saveManualModel(manual), manual);
      await notifier.diagnose('openai', 'manual');
      await notifier.deleteModel('openai', 'manual');
      await notifier.deleteProvider('openai');
      expect(
        container
            .read(providerSettingsControllerProvider)
            .value!
            .catalog
            .providers,
        isEmpty,
      );
    },
  );

  test(
    'feature state value objects and production ports are deterministic',
    () {
      final api = FakeCoderApi();
      final endpoint = HostEndpoint.parse('ws://localhost/ws', token: 'token');
      final snapshot = ConnectionSnapshot(
        api: api,
        endpoint: endpoint,
        connectionState: ClientConnectionState.disconnected,
      );
      expect(snapshot.connected, isFalse);
      expect(snapshot.connecting, isFalse);
      expect(
        snapshot
            .copyWith(connectionState: ClientConnectionState.connecting)
            .connecting,
        isTrue,
      );
      const conversation = ConversationState();
      expect(
        conversation.copyWith(timeline: <TimelineEventDto>[]).timeline,
        isEmpty,
      );
      const catalog = ProviderCatalogDto(
        providers: <ApiProviderDto>[],
        presets: <ProviderPresetDto>[],
      );
      const settings = ProviderSettingsState(catalog: catalog);
      expect(
        settings
            .copyWith(models: const <String, List<ProviderModelDto>>{})
            .catalog,
        catalog,
      );
      expect(const SystemAppClock().nowUtc().isUtc, isTrue);
      expect(const UuidAppIdGenerator().generate(), isNotEmpty);
      unawaited(api.close());
    },
  );
}

ProviderContainer _container(FakeCoderApi api) => ProviderContainer(
  overrides: [
    bootstrapProvider.overrideWithValue(FakeAppBootstrap(api: api)),
    appIdGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
  ],
);

final class _FixedIdGenerator implements AppIdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => 'generated-id';
}
