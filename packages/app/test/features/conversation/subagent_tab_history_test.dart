@Tags(<String>['feature_test__agent_collaboration__widget'])
library;

import 'dart:async';

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/chat_timeline_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/router_harness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 20);
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

  SessionDto root({required SessionStatus status}) => SessionDto(
    id: 'main-session',
    worktreeId: checkout.id,
    title: 'Session main',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: status,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );

  final child = SessionDto(
    id: 'child-a',
    worktreeId: checkout.id,
    title: 'explore_auth',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.delegated,
    status: SessionStatus.idle,
    parentSessionId: 'main-session',
    taskName: 'explore_auth',
    agentPath: '/root/explore_auth',
    rootSessionId: 'main-session',
    lifecycle: AgentLifecycle.completed,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
    createdAt: now,
    updatedAt: now,
  );

  String sessionLocation(String sessionId) => SessionRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: checkout.id,
    sessionId: sessionId,
  ).location;

  /// A session stored the way the daemon stores one: a row per streamed delta.
  List<TimelineEventDto> history(String sessionId, {required int turns}) {
    final events = <TimelineEventDto>[];
    void append(String type, String turnId, Map<String, dynamic> data) {
      final sequence = events.length + 1;
      events.add(
        TimelineEventDto(
          sessionId: sessionId,
          sequence: sequence,
          turnId: turnId,
          type: type,
          data: data,
          createdAt: now.add(Duration(seconds: sequence)),
        ),
      );
    }

    for (var turn = 1; turn <= turns; turn += 1) {
      append('user.message', 'turn-$turn', <String, dynamic>{
        'text': 'question $turn',
        'attachments': const <Map<String, dynamic>>[],
      });
      for (var delta = 0; delta < 8; delta += 1) {
        append('assistant.delta', 'turn-$turn', <String, dynamic>{
          'text': 'answer $turn part $delta. ',
          'blockId': 'block-$turn',
        });
      }
      append('turn.completed', 'turn-$turn', const <String, dynamic>{});
    }
    return events;
  }

  Finder scrollableOf() => find
      .descendant(
        of: find.byType(ChatTimelineView),
        matching: find.byType(Scrollable),
      )
      .first;

  ScrollPosition scrollPosition(WidgetTester tester) =>
      tester.state<ScrollableState>(scrollableOf()).position;

  /// Pumps fixed frames: a workspace holding a running turn never settles.
  Future<void> pumpFrames(WidgetTester tester, {int frames = 12}) async {
    for (var frame = 0; frame < frames; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'a settled agent keeps its transcript across a trip to a subagent tab',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[
          root(status: SessionStatus.idle),
          child,
        ],
        timelines: <String, List<TimelineEventDto>>{
          'main-session': history('main-session', turns: 12),
          'child-a': history('child-a', turns: 2),
        },
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
        settle: false,
      );
      addTearDown(router.dispose);
      await pumpFrames(tester);
      expect(scrollPosition(tester).maxScrollExtent, greaterThan(0));

      router.go(sessionLocation('child-a'));
      await pumpFrames(tester);
      router.go(sessionLocation('main-session'));
      await pumpFrames(tester);

      expect(
        find.textContaining('question 12', findRichText: true),
        findsOneWidget,
        reason: 'the conversation reopens on its newest message',
      );
      expect(
        scrollPosition(tester).maxScrollExtent,
        greaterThan(0),
        reason: 'with the history above it still there to scroll through',
      );
    },
  );

  testWidgets(
    'rejoining a working agent keeps the transcript when the next delta lands',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      // The reason to open a subagent at all is that the agent that spawned it
      // is working, so the tab is left and rejoined mid-turn.
      final seeded = history('main-session', turns: 20);
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[
          root(status: SessionStatus.running),
          child,
        ],
        timelines: <String, List<TimelineEventDto>>{
          'main-session': seeded,
          'child-a': history('child-a', turns: 2),
        },
      );

      /// One live delta of the running turn, numbered past the stored window.
      TimelineEventDto delta(int sequence, String text) => TimelineEventDto(
        sessionId: 'main-session',
        sequence: sequence,
        turnId: 'turn-live',
        type: 'assistant.delta',
        data: <String, dynamic>{'text': text, 'blockId': 'block-live'},
        createdAt: now.add(Duration(seconds: sequence)),
      );

      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
        settle: false,
      );
      addTearDown(router.dispose);
      await pumpFrames(tester);
      expect(scrollPosition(tester).maxScrollExtent, greaterThan(0));

      // Look in on the subagent, then come back.
      router.go(sessionLocation('child-a'));
      await pumpFrames(tester);

      // Rejoining re-subscribes, and the daemon answers over a link that takes
      // time. The snapshot it sends is what it held when it was asked.
      final roundTrip = Completer<void>();
      api.subscribeTimelineGate = roundTrip;
      router.go(sessionLocation('main-session'));
      await pumpFrames(tester);

      // The turn never stopped, so these deltas are delivered while the
      // subscription is still in flight — after the daemon answered with what
      // it held, and before the conversation has anything to apply them to.
      api
        ..emit(TimelineClientEvent(delta(seeded.length + 1, 'in flight one ')))
        ..emit(TimelineClientEvent(delta(seeded.length + 2, 'in flight two ')));
      roundTrip.complete();
      api.subscribeTimelineGate = null;
      await pumpFrames(tester);
      expect(
        scrollPosition(tester).maxScrollExtent,
        greaterThan(0),
        reason: 'the restored snapshot is a whole transcript',
      );
      final pagesBefore = api.readTimelineHistoryCount;

      // Then the next delta of the same turn arrives. It is numbered as though
      // the two before it had landed, because from the daemon's side they did.
      api.emit(TimelineClientEvent(delta(seeded.length + 3, 'and the next ')));
      await tester.pump();

      expect(
        find.textContaining('question 20', findRichText: true),
        findsOneWidget,
        reason:
            'one delta of the running turn must not take the conversation '
            'with it: the reader was reading it',
      );
      expect(
        scrollPosition(tester).maxScrollExtent,
        greaterThan(0),
        reason: 'the history above the reader must still be scrollable',
      );
      expect(
        api.readTimelineHistoryCount,
        pagesBefore,
        reason:
            'and history the app already holds must not be re-fetched to put '
            'the transcript back',
      );
    },
  );
}
