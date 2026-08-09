@Tags(<String>['feature_test__agent_collaboration__widget'])
library;

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_coder_api.dart';
import '../../support/router_harness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);
  final workspace = WorkspaceDto(
    id: 'workspace',
    name: 'Coder',
    rootPath: '/repos/coder',
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
    isCoderOwned: false,
    createdAt: now,
  );

  SessionDto root(String id) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );

  SessionDto subagent(
    String id, {
    required String parentId,
    required String taskName,
    required String agentPath,
    String rootId = 'main-session',
    AgentLifecycle lifecycle = AgentLifecycle.running,
    DateTime? createdAt,
  }) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: taskName,
    agentDefinitionId: 'coder',
    origin: SessionOrigin.delegated,
    status: SessionStatus.running,
    parentSessionId: parentId,
    taskName: taskName,
    agentPath: agentPath,
    rootSessionId: rootId,
    lifecycle: lifecycle,
    createdAt: createdAt ?? now,
    updatedAt: createdAt ?? now,
  );

  String sessionLocation(String sessionId) => SessionRoute(
    hostId: 'server',
    workspaceId: workspace.id,
    worktreeId: checkout.id,
    sessionId: sessionId,
  ).location;

  testWidgets(
    'the track lists nested subagents and opens a read-only tab',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[
          root('main-session'),
          subagent(
            'child-a',
            parentId: 'main-session',
            taskName: 'explore_auth',
            agentPath: '/root/explore_auth',
          ),
          subagent(
            'grandchild',
            parentId: 'child-a',
            taskName: 'read_docs',
            agentPath: '/root/explore_auth/read_docs',
            lifecycle: AgentLifecycle.completed,
            createdAt: now.add(const Duration(seconds: 1)),
          ),
        ],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
      );
      addTearDown(router.dispose);

      // Collapsed by default: the header summarizes, rows stay hidden.
      final track = find.byKey(const ValueKey('subagent-track'));
      expect(track, findsOneWidget);
      expect(find.text('서브 에이전트 2개'), findsOneWidget);
      expect(find.text('1개 실행 중'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('subagent-row-child-a')),
        findsNothing,
      );

      // Expanding lists every descendant, nested ones included. A running
      // row keeps a spinner animating, so settle-style pumps would never
      // finish; fixed pumps are used from here on.
      await tester.tap(find.text('서브 에이전트 2개'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const ValueKey('subagent-row-child-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('subagent-row-grandchild')),
        findsOneWidget,
      );
      expect(find.text('explore_auth'), findsOneWidget);
      expect(find.text('/root/explore_auth/read_docs'), findsOneWidget);

      // Subagents never appear in the all-sessions menu.
      await tester.tap(
        find.byKey(const ValueKey('workspace-all-sessions-menu')),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Session main-session'), findsWidgets);
      // The expanded track behind the menu still shows the row text, so the
      // absence check is scoped to menu items.
      expect(
        find.widgetWithText(TRMenuItem, 'read_docs'),
        findsNothing,
      );
      expect(
        find.widgetWithText(TRMenuItem, 'explore_auth'),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('workspace-all-sessions-menu')),
      );
      await tester.pump(const Duration(seconds: 1));

      // Tapping a row opens the subagent as a tab on its session route.
      await tester.tap(find.byKey(const ValueKey('subagent-row-child-a')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(currentLocation(router), sessionLocation('child-a'));
      expect(
        find.byKey(const ValueKey('tr-tabs-close-child-a')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a subagent tab is a live read-only transcript without a composer',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final child = subagent(
        'child-a',
        parentId: 'main-session',
        taskName: 'explore_auth',
        agentPath: '/root/explore_auth',
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[root('main-session'), child],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('child-a'),
        settle: false,
      );
      addTearDown(router.dispose);

      // Read-only chrome: status header, no composer, no subagent track.
      expect(find.text('explore_auth'), findsWidgets);
      expect(
        find.textContaining('서브 에이전트 대화 · 읽기 전용'),
        findsOneWidget,
      );
      expect(find.byType(SessionComposer), findsNothing);
      expect(find.byKey(const ValueKey('subagent-track')), findsNothing);
      expect(find.byType(TRSpinner), findsWidgets);

      // A pending approval on the subagent never surfaces a card here.
      api.emit(
        ApprovalRequestedClientEvent(
          ApprovalRequestDto(
            id: 'approval',
            sessionId: 'child-a',
            turnId: 'turn-1',
            toolCallId: 'call',
            toolName: 'apply_patch',
            risk: ToolRisk.write,
            arguments: const <String, dynamic>{'patch': 'x'},
            status: ApprovalStatus.pending,
            createdAt: now,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ApprovalCard), findsNothing);

      // The transcript streams live timeline events.
      api.emitTimeline('child-a', 'assistant.delta', <String, dynamic>{
        'text': 'Reading auth module…',
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Reading auth module…'), findsOneWidget);

      // A lifecycle change flips the header spinner into a settled icon.
      api.emit(
        SessionUpdatedClientEvent(
          child.copyWith(
            status: SessionStatus.idle,
            lifecycle: AgentLifecycle.completed,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TRSpinner), findsNothing);
      expect(find.byIcon(CoderIcons.success), findsWidgets);
    },
  );

  testWidgets('a session without subagents shows no track', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
      agents: <SessionDto>[root('main-session')],
    );
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: sessionLocation('main-session'),
    );
    addTearDown(router.dispose);
    expect(find.byKey(const ValueKey('subagent-track')), findsNothing);
    expect(find.byType(SessionComposer), findsOneWidget);
  });
}
