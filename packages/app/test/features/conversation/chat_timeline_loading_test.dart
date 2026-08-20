import 'dart:async';

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/chat_message_views.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:client/client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/router_harness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 2);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Workspace',
    rootPath: '/workspace',
    kind: WorkspaceKind.directory,
    createdAt: now,
  );
  final checkout = WorktreeDto(
    id: 'checkout',
    workspaceId: workspace.id,
    name: workspace.name,
    path: workspace.rootPath,
    kind: WorktreeKind.directory,
    isTinestOwned: false,
    createdAt: now,
  );
  final agent = SessionDto(
    id: 'agent',
    worktreeId: checkout.id,
    title: 'Agent',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );
  final location = SessionRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: checkout.id,
    sessionId: agent.id,
  ).location;

  testWidgets(
    'an existing session shows a timeline skeleton, never a false empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
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
      )..subscribeTimelineGate = Completer<void>();
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: location,
        // The skeleton shimmer animates until the gate opens.
        settle: false,
      );
      addTearDown(router.dispose);

      expect(find.byType(ChatTimelineSkeleton), findsOneWidget);
      expect(find.bySemanticsLabel('대화 불러오는 중'), findsOneWidget);
      expect(find.byType(ChatEmptyState), findsNothing);

      api.subscribeTimelineGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ChatTimelineSkeleton), findsNothing);
      expect(find.text('Earlier request', findRichText: true), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__workspace_async_loading__widget',
      'ui_state__conversation_timeline__loading__widget',
    ],
  );

  testWidgets(
    'a session with no history still resolves to the real empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[agent],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: location,
      );
      addTearDown(router.dispose);

      expect(find.byType(ChatTimelineSkeleton), findsNothing);
      expect(find.byType(ChatEmptyState), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__workspace_async_loading__widget',
      'ui_state__conversation_timeline__empty__widget',
    ],
  );

  testWidgets(
    'a reconnect currently shows the transcript as an empty conversation',
    (tester) async {
      // Characterization, not an aspiration. A transport blip is not "this
      // session has no messages", but it renders as one: the controller
      // settles empty the moment the API goes away, which
      // `conversation_offline_test.dart` records as a deliberate choice with
      // the note that anything wanting the last timeline has to keep it
      // itself. Nothing does. Pinned here so the day that changes, this test
      // is what says so.
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
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
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: location,
      );
      addTearDown(router.dispose);
      expect(find.text('Earlier request', findRichText: true), findsOneWidget);

      api.emitState(ClientConnectionState.reconnecting);
      await tester.pumpAndSettle();
      expect(
        find.byType(ChatEmptyState),
        findsOneWidget,
        reason: 'the blip is indistinguishable from a session with no history',
      );

      // It comes back whole, which is what makes the gap purely visual.
      api.emitState(ClientConnectionState.connected);
      await tester.pumpAndSettle();
      expect(find.byType(ChatEmptyState), findsNothing);
      expect(find.text('Earlier request', findRichText: true), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__workspace_async_loading__widget',
      'ui_state__conversation_timeline__loading__widget',
    ],
  );
}
