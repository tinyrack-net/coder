import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/router_harness.dart';

/// What a streamed delta is allowed to rebuild.
///
/// The conversation pane reads one narrow slice of the conversation controller
/// but watches the whole thing, so every assistant delta rebuilds the composer,
/// its selector bar, the plugin slots, and the subagent track along with the
/// transcript. Counting builds is the only honest assertion available here: a
/// timing assertion would be flaky, and the repo forbids buying a green run
/// with tolerance.
void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Tinest',
    rootPath: '/repos/tinest',
    kind: WorkspaceKind.git,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: 'main',
    path: workspace.rootPath,
    branch: 'main',
    head: 'abc',
    kind: WorktreeKind.checkout,
    isTinestOwned: false,
    createdAt: now,
  );
  final session = SessionDto(
    id: 'session',
    worktreeId: checkout.id,
    title: 'Session',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'a streamed delta rebuilds the transcript without the composer bar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[session],
        timelines: <String, List<TimelineEventDto>>{
          session.id: <TimelineEventDto>[
            TimelineEventDto(
              sessionId: session.id,
              sequence: 1,
              turnId: 'turn-0',
              type: 'user.message',
              data: const <String, dynamic>{'text': 'Earlier prompt'},
              createdAt: now,
            ),
          ],
        },
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: session.id,
        ).location,
      );
      addTearDown(router.dispose);

      // A parent that did not rebuild hands its child the same widget object.
      // Rebuilding it constructs a new one, so identity is a direct read of
      // whether the delta reached this subtree at all.
      SessionComposerBar barWidget() =>
          tester.widget<SessionComposerBar>(find.byType(SessionComposerBar));
      final before = barWidget();

      for (var index = 0; index < 8; index += 1) {
        api.emitTimeline(session.id, 'assistant.delta', <String, dynamic>{
          'text': 'chunk $index',
        });
        await tester.pump();
      }

      expect(
        barWidget(),
        same(before),
        reason: 'a delta changes the transcript, not the composer selectors',
      );
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );
}
