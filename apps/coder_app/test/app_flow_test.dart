import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

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
  AgentDto session(String id) => AgentDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    providerConnectionId: 'openai',
    model: 'gpt-5.6-sol',
    status: AgentStatus.idle,
    permissionMode: PermissionMode.ask,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'desktop workspace uses host repository tree and session tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = session('one');
      final second = session('two');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <AgentDto>[first, second],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          agentId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.text('Test daemon'), findsOneWidget);
      expect(find.text('Coder'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
      expect(find.text('Agents'), findsNothing);
      expect(find.text('Session one'), findsWidgets);
      expect(find.byTooltip('새 worktree'), findsOneWidget);

      await tester.tap(find.byTooltip('모든 session'));
      await tester.pumpAndSettle();
      expect(find.text('Session two'), findsOneWidget);
      await tester.tap(find.text('Session two'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, contains('two'));
    },
  );

  testWidgets('session tabs close locally and reopen from the picker', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final first = session('one');
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
      agents: <AgentDto>[first],
    );
    final router = await _pumpRoute(
      tester,
      api,
      SessionRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
        agentId: first.id,
      ).location,
    );
    addTearDown(router.dispose);

    await tester.tap(find.byTooltip('탭 닫기'));
    await tester.pumpAndSettle();
    expect(find.text('새 session 시작'), findsOneWidget);
    expect(await api.listAgents(worktreeId: checkout.id), <AgentDto>[first]);

    await tester.tap(find.byTooltip('모든 session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Session one'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('탭 닫기'), findsOneWidget);
  });

  testWidgets('creates and archives a managed worktree from the repository', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
    );
    final router = await _pumpRoute(
      tester,
      api,
      WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
      ).location,
    );
    addTearDown(router.dispose);

    await tester.tap(find.byTooltip('새 worktree'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '새 branch 이름'),
      'feature/settings',
    );
    await tester.tap(find.widgetWithText(FilledButton, '생성'));
    await tester.pumpAndSettle();
    expect(find.text('feature/settings'), findsWidgets);

    final menus = find.byTooltip('Worktree 메뉴');
    await tester.tap(menus.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Archive할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();
    expect(find.text('feature/settings'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('folder add selects a daemon and remote path before register', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const WorkspaceHomeRoute().location,
    );
    addTearDown(router.dispose);

    await tester.tap(find.byTooltip('폴더 추가').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Test daemon'),
      ),
    );
    await tester.pumpAndSettle();
    final pathField = find.widgetWithText(TextField, 'Daemon 경로');
    await tester.enterText(pathField, '/srv/repositories/project');
    await tester.pumpAndSettle();
    expect(find.text('project'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '등록'));
    await tester.pumpAndSettle();

    expect(find.text('project'), findsWidgets);
    expect(
      router.routeInformationProvider.value.uri.path,
      startsWith('/workspaces/server/'),
    );
  });

  testWidgets('mobile opens selected worktree as a session-only detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
    );
    final router = await _pumpRoute(
      tester,
      api,
      WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
      ).location,
    );
    addTearDown(router.dispose);

    expect(find.text('Repositories'), findsNothing);
    expect(find.text('새 session 시작'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Repositories'), findsOneWidget);
  });

  testWidgets('creates a session and sends a coding request', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[workspace],
      worktrees: <WorktreeDto>[checkout],
    );
    final router = await _pumpRoute(
      tester,
      api,
      WorktreeRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
      ).location,
    );
    addTearDown(router.dispose);

    await tester.tap(find.text('새 session 시작'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '이름'),
      'Refactor API',
    );
    await tester.tap(find.widgetWithText(FilledButton, '생성'));
    await tester.pumpAndSettle();
    expect(find.text('Refactor API'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, '코딩 요청을 입력하세요…'),
      'Run the tests',
    );
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(api.startedPrompts, <String>['Run the tests']);
  });

  testWidgets('workspace shell is visible before any daemon exists', (
    tester,
  ) async {
    final api = FakeCoderApi();
    final router = GoRouter(
      initialLocation: const WorkspaceHomeRoute().location,
      routes: $appRoutes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(
            fakeAppServices(api, connected: false),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.byTooltip('설정'), findsOneWidget);
  });

  testWidgets('settings combines Provider and Daemon categories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const ProviderSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Daemon'), findsWidgets);
    expect(find.text('Test daemon'), findsOneWidget);
    await tester.tap(find.text('Daemon').first);
    await tester.pumpAndSettle();
    expect(find.text('원격 daemons'), findsOneWidget);
  });

  testWidgets('timeline and approval cards render typed event content', (
    tester,
  ) async {
    final agent = session('approval');
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
    final event = TimelineEventDto(
      agentId: agent.id,
      sequence: 1,
      type: 'user.message',
      data: const <String, dynamic>{'text': 'Inspect this'},
      createdAt: now,
    );
    final api = FakeCoderApi(agents: <AgentDto>[agent]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                Consumer(
                  builder: (context, ref, child) => Text(
                    ref
                                .watch(hostRegistryControllerProvider)
                                .asData
                                ?.value
                                .runtimes['server']
                                ?.connected ==
                            true
                        ? 'ready'
                        : 'waiting',
                  ),
                ),
                TimelineCard(event: event),
                ApprovalCard(hostId: 'server', approval: approval),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Inspect this', findRichText: true), findsOneWidget);
    expect(find.text('승인 필요 · apply_patch'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '거부'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '승인'));
    await tester.pumpAndSettle();
    expect(
      api.approvalDecisions,
      <({bool approved, String id})>[
        (id: 'approval', approved: false),
        (id: 'approval', approved: true),
      ],
    );
  });
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location,
) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(fakeAppServices(api)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
