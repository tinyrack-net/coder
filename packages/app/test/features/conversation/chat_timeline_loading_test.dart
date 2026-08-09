import 'dart:async';

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/chat_message_views.dart';
import 'package:app/src/shared/presentation/workspace_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_coder_api.dart';
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
    isCoderOwned: false,
    createdAt: now,
  );
  final agent = SessionDto(
    id: 'agent',
    worktreeId: checkout.id,
    title: 'Agent',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
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
      final api = FakeCoderApi(
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
    tags: const <String>['feature_test__workspace_async_loading__widget'],
  );

  testWidgets(
    'a session with no history still resolves to the real empty state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
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
    tags: const <String>['feature_test__workspace_async_loading__widget'],
  );
}
