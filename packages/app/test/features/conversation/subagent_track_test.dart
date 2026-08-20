@Tags(<String>['feature_test__agent_collaboration__widget'])
library;

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/shared/presentation/tinest_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/router_harness.dart';

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

  SessionDto root(String id) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
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
    SessionStatus status = SessionStatus.running,
  }) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: taskName,
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.delegated,
    status: status,
    parentSessionId: parentId,
    taskName: taskName,
    agentPath: agentPath,
    rootSessionId: rootId,
    lifecycle: lifecycle,
    model: const ModelSelectionDto(modelId: 'openai/gpt-5.6-sol'),
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
      final api = FakeTinestApi(
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
      final api = FakeTinestApi(
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

      // Read-only chrome: the tab names the task and carries the status icon,
      // and the pane offers no composer and no subagent track.
      expect(find.text('explore_auth'), findsWidgets);
      expect(find.byType(SessionComposer), findsNothing);
      expect(find.byKey(const ValueKey('subagent-track')), findsNothing);
      expect(find.byType(TRSpinner), findsWidgets);

      // Read-only means the user cannot talk to the subagent, not that the
      // subagent is unreachable. Its approvals are the one thing only a human
      // can answer, and hiding them parks the child's turn forever.
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
      expect(find.byType(ApprovalCard), findsOneWidget);
      expect(find.byType(SessionComposer), findsNothing);
      await tester.tap(find.widgetWithText(TRButton, '승인'));
      await tester.pump(const Duration(seconds: 1));
      expect(
        api.approvalDecisions,
        <({String id, bool approved})>[(id: 'approval', approved: true)],
      );

      // The transcript streams live timeline events.
      api.emitTimeline('child-a', 'assistant.delta', <String, dynamic>{
        'text': 'Reading auth module…',
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Reading auth module…'), findsOneWidget);

      // A lifecycle change flips the tab's spinner into a settled icon.
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
      expect(find.byIcon(TinestIcons.success), findsWidgets);
    },
  );

  testWidgets(
    'a subagent waiting for approval is distinguishable from a working one',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final child = subagent(
        'child-a',
        parentId: 'main-session',
        taskName: 'explore_auth',
        agentPath: '/root/explore_auth',
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[root('main-session'), child],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
        settle: false,
      );
      addTearDown(router.dispose);

      await tester.tap(find.text('서브 에이전트 1개'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final row = find.byKey(const ValueKey('subagent-row-child-a'));
      expect(
        find.descendant(of: row, matching: find.byType(TRSpinner)),
        findsOneWidget,
      );

      // A child blocked on an approval is not making progress; rendering it
      // as a plain spinner hides the one row the user has to act on.
      api.emit(
        SessionUpdatedClientEvent(
          child.copyWith(status: SessionStatus.waitingForApproval),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(of: row, matching: find.byType(TRSpinner)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(TinestIcons.approvalPending),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the collapsed track flags descendants that need the user',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final child = subagent(
        'child-a',
        parentId: 'main-session',
        taskName: 'explore_auth',
        agentPath: '/root/explore_auth',
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[root('main-session'), child],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
        settle: false,
      );
      addTearDown(router.dispose);

      // A working child is summarized as running and nothing else.
      expect(find.text('1개 실행 중'), findsOneWidget);
      expect(find.text('1개 승인 필요'), findsNothing);

      // Once it parks on an approval the collapsed header has to say so: the
      // rows are hidden by default, so the badge is the only thing between a
      // stuck tree and a user who never looks.
      api.emit(
        SessionUpdatedClientEvent(
          child.copyWith(status: SessionStatus.waitingForApproval),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1개 승인 필요'), findsOneWidget);
      expect(find.text('1개 실행 중'), findsNothing);
    },
  );

  testWidgets(
    'a blocked subagent approval is answerable from the parent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final child = subagent(
        'child-a',
        parentId: 'main-session',
        taskName: 'explore_auth',
        agentPath: '/root/explore_auth',
        status: SessionStatus.waitingForApproval,
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[root('main-session'), child],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: sessionLocation('main-session'),
        settle: false,
      );
      addTearDown(router.dispose);

      // The request belongs to the child's session, and only the human can
      // answer it. Surfacing it on the parent is what keeps the tree from
      // parking on a card nobody is looking at.
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
      expect(find.byType(ApprovalCard), findsOneWidget);
      // Named, because the parent runs its own tools and the user has to know
      // which agent is asking.
      expect(find.text('/root/explore_auth'), findsWidgets);

      // The banner is bounded so it cannot squeeze the composer out, so a
      // long request scrolls; the button still has to be reachable from here.
      final approve = find.widgetWithText(TRButton, '승인');
      await tester.ensureVisible(approve);
      await tester.pump();
      await tester.tap(approve);
      await tester.pump(const Duration(seconds: 1));
      expect(
        api.approvalDecisions,
        <({String id, bool approved})>[(id: 'approval', approved: true)],
      );
      // Answering it never navigated away from the parent.
      expect(currentLocation(router), sessionLocation('main-session'));
    },
    tags: const <String>[
      'ui_state__conversation_timeline__subagent_approval_pending__widget',
    ],
  );

  testWidgets('a session tab flags a descendant waiting on the user', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final child = subagent(
      'child-a',
      parentId: 'main-session',
      taskName: 'explore_auth',
      agentPath: '/root/explore_auth',
    );
    final api = FakeTinestApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
      agents: <SessionDto>[root('main-session'), child],
    );
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: sessionLocation('main-session'),
      settle: false,
    );
    addTearDown(router.dispose);

    final tabFlag = find.byKey(
      const ValueKey('session-tab-approval-main-session'),
    );
    expect(tabFlag, findsNothing);

    // The tab is the only part of the parent that stays visible from another
    // session, so a tree blocked behind it has to show there too.
    api.emit(
      SessionUpdatedClientEvent(
        child.copyWith(status: SessionStatus.waitingForApproval),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tabFlag, findsOneWidget);
  });

  testWidgets('a session without subagents shows no track', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeTinestApi(
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
