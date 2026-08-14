import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/conversation/application/conversation_controller.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:client/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';

void main() {
  final now = DateTime.utc(2026, 8, 10);
  final worktree = WorktreeDto(
    id: 'worktree',
    workspaceId: 'workspace',
    name: 'main',
    path: '/repos/tinest',
    kind: WorktreeKind.checkout,
    isTinestOwned: false,
    createdAt: now,
  );
  final agent = SessionDto(
    id: 'one',
    worktreeId: worktree.id,
    title: 'Session one',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );

  test(
    'a daemon that drops settles the conversation empty rather than reloading',
    () async {
      final api = FakeTinestApi(
        worktrees: <WorktreeDto>[worktree],
        agents: <SessionDto>[agent],
        timelines: <String, List<TimelineEventDto>>{
          agent.id: <TimelineEventDto>[
            TimelineEventDto(
              sessionId: agent.id,
              sequence: 1,
              turnId: 'turn-1',
              type: 'user.message',
              data: const <String, dynamic>{
                'text': 'Earlier request',
                'attachments': <Map<String, dynamic>>[],
              },
              createdAt: now,
            ),
          ],
        },
      );
      final container = ProviderContainer(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(hostRegistryControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      final provider = conversationControllerProvider('server', agent.id);
      container.listen(provider, (_, _) {});
      expect((await container.read(provider.future)).timeline, hasLength(1));

      api.emitState(ClientConnectionState.disconnected);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Losing the daemon takes the API away before any replacement arrives, so
      // this provider settles on an empty conversation instead of holding the
      // previous one through a reload. Anything downstream that wants the last
      // timeline has to keep it itself; reading `value` over `asData` here
      // would not preserve it.
      final offline = container.read(provider);
      expect(offline.isLoading, isFalse);
      expect(offline.value?.timeline, isEmpty);
    },
    tags: const <String>['feature_test__session_tabs__unit'],
  );
}
