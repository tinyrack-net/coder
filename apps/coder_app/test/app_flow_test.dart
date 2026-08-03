import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/chat/chat_approval_card.dart';
import 'package:coder_app/src/chat/chat_timeline_model.dart';
import 'package:coder_app/src/chat/chat_timeline_view.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';

import 'support/localization.dart';

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
  SessionDto session(String id) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
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
        agents: <SessionDto>[first, second],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      expect(find.text('Test daemon'), findsOneWidget);
      // The composer's agent chip is also labelled 'Coder', so the repository
      // entry is matched through its tile.
      expect(find.widgetWithText(ListTile, 'Coder'), findsOneWidget);
      expect(find.text('main'), findsOneWidget);
      expect(find.text('Agents'), findsNothing);
      expect(find.text('Session one'), findsWidgets);

      await tester.tap(find.byTooltip('모든 session'));
      await tester.pumpAndSettle();
      expect(find.text('Session two'), findsOneWidget);
      await tester.tap(find.text('Session two'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, contains('two'));
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'session tabs close locally and reopen from the picker',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final first = session('one');
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[first],
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: first.id,
        ).location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.byTooltip('탭 닫기'));
      await tester.pumpAndSettle();
      expect(find.text('코딩 요청으로 새 session을 시작하세요.'), findsOneWidget);
      expect(await api.listSessions(worktreeId: checkout.id), <SessionDto>[
        first,
      ]);

      await tester.tap(find.byTooltip('모든 session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Session one'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('탭 닫기'), findsOneWidget);
    },
    tags: const <String>['feature_test__session_tabs__widget'],
  );

  testWidgets(
    'archives a managed worktree from the sidebar',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final managed = WorktreeDto(
        id: 'managed',
        workspaceId: workspace.id,
        name: 'feature/settings',
        path: '/worktrees/feature-settings',
        branch: 'feature/settings',
        kind: WorktreeKind.managed,
        isCoderOwned: true,
        createdAt: now,
      );
      final api =
          FakeCoderApi(
              workspaces: <WorkspaceDto>[workspace],
              worktrees: <WorktreeDto>[checkout, managed],
            )
            ..archiveWorktreeHookRuns = const <WorktreeHookRunDto>[
              WorktreeHookRunDto(
                phase: WorktreeHookPhase.teardown,
                command: 'docker compose down',
                exitCode: 1,
                stdout: '',
                stderr: 'no such service',
              ),
            ];
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: managed.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.byTooltip('새 worktree'), findsNothing);
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
      // Teardown never blocks the archive, so the failure is only reported.
      expect(
        find.text('Teardown 실패 (exit 1): docker compose down'),
        findsOneWidget,
      );
      await tester.tap(find.text('자세히'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no such service'), findsOneWidget);
    },
    tags: const <String>['feature_test__worktree_lifecycle__widget'],
  );

  testWidgets(
    'the project select registers a project through the daemon browser',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        directories: const <String, List<String>>{
          '/': <String>['/srv'],
          '/srv': <String>['/srv/repositories'],
          '/srv/repositories': <String>['/srv/repositories/project'],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('폴더 추가'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('new-workspace-project-add')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daemon의 폴더 선택'), findsOneWidget);
      await tester.tap(find.text('srv'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('repositories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('project'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '이 폴더 선택'));
      await tester.pumpAndSettle();

      expect(api.registeredPaths, <String>['/srv/repositories/project']);
      expect(find.text('project'), findsWidgets);
    },
    tags: const <String>['feature_test__workspace_registration__widget'],
  );

  testWidgets(
    'the sidebar collapses and restores from persisted settings',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
      );
      final store = MemoryAppStore();
      final router = await _pumpRoute(
        tester,
        api,
        const WorkspaceHomeRoute().location,
        store: store,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      // Toggling refreshes the host registry; the composer must keep its
      // loaded state instead of flashing an empty-state error.
      await tester.pump();
      expect(find.text('먼저 프로젝트를 추가하세요.'), findsNothing);
      expect(find.text('사용할 Provider와 모델을 먼저 선택하세요.'), findsNothing);
      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-button')), findsNothing);
      expect(store.settings.sidebarCollapsed, isTrue);

      await tester.tap(find.byKey(const ValueKey('workspace-sidebar-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
      expect(store.settings.sidebarCollapsed, isFalse);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

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

    expect(find.byKey(const ValueKey('workspace-new-button')), findsNothing);
    expect(find.text('코딩 요청으로 새 session을 시작하세요.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('workspace-new-button')), findsOne);
  });

  testWidgets(
    'creates a session and sends a coding request',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const planner = AgentDefinitionDto(
        id: 'planner',
        name: 'Planner',
        description: 'Plans changes',
        mode: AgentMode.primary,
        promptEnabled: true,
        systemPrompt: 'Plan first.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.daemonDefault,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.readOnly,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'planner-hash',
        sourcePath: '/config/agents/planner.md',
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agentDefinitions: const <AgentDefinitionDto>[planner],
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

      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-composer-agent')), findsOne);
      expect(find.text('Planner'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('GPT-5.6 Sol'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Run the tests',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.agentDefinitionId, 'planner');
      expect(created.title, 'Run the tests');
      expect(created.model, isNull);
      expect(api.startedPrompts, <String>['Run the tests']);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'composer pins a model at creation and clears it mid-session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const fast = ProviderModelDto(
        connectionId: 'openai',
        id: 'gpt-5.6-fast',
        label: 'GPT-5.6 Fast',
        source: ProviderModelSource.bundled,
        capabilities: ModelCapabilitiesDto(
          streaming: CapabilitySupport.supported,
          toolCalling: CapabilitySupport.supported,
        ),
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        models: <String, List<ProviderModelDto>>{
          'openai': <ProviderModelDto>[
            const ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-sol',
              label: 'GPT-5.6 Sol',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
            fast,
          ],
        },
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
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('session-composer-provider')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-provider-openai')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-fast')),
      );
      await tester.pumpAndSettle();
      expect(find.text('GPT-5.6 Fast'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Speed up the build',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();
      expect(
        api.createdSessions.single.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'openai',
          modelId: 'gpt-5.6-fast',
        ),
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('model-option-inherit')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModels.single.model, isNull);
      expect((await api.listSessions()).single.model, isNull);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'plan mode starts a planning session and implements the proposal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
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
      await tester.pumpAndSettle();

      expect(find.text('실행'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      expect(find.text('Plan'), findsOneWidget);
      expect(find.textContaining('Plan 모드'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Migrate the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.mode, SessionMode.plan);
      expect(find.textContaining('Plan 모드'), findsOneWidget);

      api
        ..emitTimeline(
          created.id,
          'assistant.delta',
          <String, dynamic>{
            'text':
                'Explored it.\n<proposed_plan>\n'
                '1. Move the parser\n</proposed_plan>',
          },
        )
        ..emitTimeline(
          created.id,
          'turn.completed',
          <String, dynamic>{'toolRounds': 0},
        );
      await tester.pumpAndSettle();

      expect(find.text('제안된 계획'), findsOneWidget);
      expect(
        find.textContaining('Move the parser', findRichText: true),
        findsWidgets,
      );
      expect(find.textContaining('proposed_plan'), findsNothing);
      expect(find.text('이 계획대로 진행할까요?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '계획대로 실행'));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
      expect(api.startedPrompts.last, '계획을 실행해줘.');
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'a plan can be handed to a fresh session or postponed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final planning = session('planning').copyWith(mode: SessionMode.plan);
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[planning],
        timelines: <String, List<TimelineEventDto>>{
          planning.id: <TimelineEventDto>[
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 1,
              turnId: 'turn-1',
              type: 'assistant.delta',
              data: const <String, dynamic>{
                'text': '<proposed_plan>\n1. Move the parser\n</proposed_plan>',
              },
              createdAt: now,
            ),
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 2,
              turnId: 'turn-1',
              type: 'turn.completed',
              data: const <String, dynamic>{'toolRounds': 0},
              createdAt: now,
            ),
          ],
        },
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: planning.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '계속 계획'));
      await tester.pumpAndSettle();
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
      expect(api.startedPrompts, isEmpty);

      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

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
        child: MaterialApp.router(
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.byTooltip('설정'), findsOneWidget);
  });

  testWidgets('settings combines Projects, Agent, Provider, and Daemon', (
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
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Provider'), findsOneWidget);
    expect(find.text('Daemon'), findsWidgets);
    expect(find.text('Test daemon'), findsOneWidget);
    await tester.tap(find.text('Daemon').first);
    await tester.pumpAndSettle();
    expect(find.text('원격 daemons'), findsOneWidget);
  });

  testWidgets(
    'agent settings edits Markdown definitions and creates subagents',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi();
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Coder'), findsWidgets);
      final prompt = find.widgetWithText(
        TextField,
        'System prompt (Markdown)',
      );
      await tester.enterText(prompt, 'Always run focused tests.');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await api.getAgentDefinition('coder')).systemPrompt,
        'Always run focused tests.',
      );
      await tester.scrollUntilVisible(
        find.text('내장 도구'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('내장 도구'), findsOneWidget);

      await tester.tap(find.byTooltip('Agent 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'reviewer',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '이름').last,
        'Reviewer',
      );
      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<AgentMode>, '유형'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('subagent').last);
      tester.testTextInput.hide();
      final createButton = find.widgetWithText(FilledButton, '생성');
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      expect(find.text('Reviewer'), findsWidgets);
      expect(
        (await api.getAgentDefinition('reviewer')).mode,
        AgentMode.subagent,
      );
    },
    tags: const <String>[
      'feature_test__agent_definition_management__widget',
    ],
  );

  testWidgets(
    'agent create validates input and keeps daemon failures in the dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(failNextAgentCreate: true);
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      await tester.tap(find.byTooltip('Agent 추가'));
      await tester.pumpAndSettle();
      var create = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '생성'),
      );
      expect(create.onPressed, isNull);

      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'Invalid ID',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '이름').last,
        'Reviewer',
      );
      await tester.pumpAndSettle();
      expect(find.text('영문 소문자, 숫자, -, _만 사용할 수 있습니다.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'coder',
      );
      await tester.pumpAndSettle();
      expect(find.text('이미 존재하는 Agent ID입니다.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'reviewer',
      );
      await tester.pumpAndSettle();
      create = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '생성'),
      );
      expect(create.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, '생성'));
      await tester.pumpAndSettle();
      expect(find.textContaining('agent_create_failed'), findsOneWidget);
      expect(find.text('Agent 추가'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '생성'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 추가'), findsNothing);
      expect(find.text('Reviewer'), findsWidgets);
    },
  );

  testWidgets('mobile agent settings navigates from list to Markdown detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = FakeCoderApi();
    final router = await _pumpRoute(
      tester,
      api,
      const AgentSettingsRoute(hostId: 'server').location,
    );
    addTearDown(router.dispose);

    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('System prompt (Markdown)'), findsNothing);
    await tester.tap(find.text('Coder').first);
    await tester.pumpAndSettle();
    expect(find.text('System prompt (Markdown)'), findsOneWidget);
    await tester.tap(find.byTooltip('Agent 목록'));
    await tester.pumpAndSettle();
    expect(find.text('Agents'), findsOneWidget);
  });

  testWidgets(
    'agent editor handles conflicts, policy controls, reset, and archive',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const coder = AgentDefinitionDto(
        id: 'coder',
        name: 'Coder',
        description: 'General coding',
        mode: AgentMode.primary,
        promptEnabled: true,
        systemPrompt: 'Code carefully.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.daemonDefault,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.ask,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'coder-hash',
        sourcePath: '/config/agents/coder.md',
        isBuiltIn: true,
        diagnostics: <AgentDefinitionDiagnosticDto>[
          AgentDefinitionDiagnosticDto(
            code: 'unavailable_tool',
            message: 'A future tool is unavailable.',
          ),
        ],
      );
      const reviewer = AgentDefinitionDto(
        id: 'reviewer',
        name: 'Reviewer',
        description: 'Reviews changes',
        mode: AgentMode.subagent,
        promptEnabled: true,
        systemPrompt: 'Review.',
        model: AgentModelSelectionDto(
          source: AgentModelSource.daemonDefault,
        ),
        reasoningEffort: 'medium',
        permissionMode: PermissionMode.readOnly,
        toolIds: <String>['read_file'],
        callableAgentIds: <String>[],
        contentHash: 'reviewer-hash',
        sourcePath: '/config/agents/reviewer.md',
      );
      final api = FakeCoderApi(
        agentDefinitions: const <AgentDefinitionDto>[coder, reviewer],
        failNextAgentUpdate: true,
      );
      final router = await _pumpRoute(
        tester,
        api,
        const AgentSettingsRoute(hostId: 'server').location,
      );
      addTearDown(router.dispose);

      expect(find.text('unavailable_tool'), findsOneWidget);
      await tester.tap(find.byTooltip('파일 위치 복사'));
      await tester.tap(find.text('Custom system prompt 사용'));
      final editorList = find.byType(ListView).last;
      await tester.drag(editorList, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('고정 provider/model'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Provider connection ID'),
        'openai',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Model ID'),
        'gpt-test',
      );
      await tester.drag(editorList, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('read_file').last);
      await tester.tap(find.text('Reviewer').last);
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 저장 실패'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Overwrite'));
      await tester.pumpAndSettle();

      final updated = await api.getAgentDefinition('coder');
      expect(updated.promptEnabled, isFalse);
      expect(updated.model.providerConnectionId, 'openai');
      expect(updated.model.modelId, 'gpt-test');
      expect(updated.toolIds, isEmpty);
      expect(updated.callableAgentIds, <String>['reviewer']);

      await tester.tap(find.byTooltip('기본값으로 초기화'));
      await tester.pumpAndSettle();
      expect(
        (await api.getAgentDefinition('coder')).systemPrompt,
        'Code carefully.',
      );
      await tester.tap(find.text('Reviewer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();
      expect(
        (await api.listAgentDefinitions()).map((definition) => definition.id),
        isNot(contains('reviewer')),
      );
    },
    tags: const <String>['feature_test__agent_delegation__widget'],
  );

  testWidgets('remote agent settings stays editable and exposes load errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const remoteInfo = ServerInfoDto(
      serverId: 'server',
      version: 'test',
      protocolVersion: coderProtocolVersion,
      features: <String, bool>{},
    );
    final remoteRouter = await _pumpRoute(
      tester,
      FakeCoderApi(serverInfo: remoteInfo),
      const AgentSettingsRoute(hostId: 'server').location,
    );
    expect(find.textContaining('읽기만'), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add),
          )
          .onPressed,
      isNotNull,
    );
    remoteRouter.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final errorRouter = await _pumpRoute(
      tester,
      FakeCoderApi(agentListError: Exception('definition load failed')),
      const AgentSettingsRoute(hostId: 'server').location,
    );
    addTearDown(errorRouter.dispose);
    expect(find.textContaining('definition load failed'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('definition load failed'), findsOneWidget);
  });

  testWidgets(
    'timeline and approval cards render typed event content',
    (
      tester,
    ) async {
      final agent = session('approval');
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
      final event = TimelineEventDto(
        sessionId: agent.id,
        sequence: 1,
        type: 'user.message',
        data: const <String, dynamic>{'text': 'Inspect this'},
        createdAt: now,
      );
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
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
                  ChatItemView(
                    item: projectChatTimeline(
                      <TimelineEventDto>[event],
                    ).single,
                  ),
                  ApprovalCard(hostId: 'server', approval: approval),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(find.text('>'), findsOneWidget);
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
    },
    tags: const <String>['feature_test__turn_execution__widget'],
  );
}

Future<GoRouter> _pumpRoute(
  WidgetTester tester,
  FakeCoderApi api,
  String location, {
  MemoryAppStore? store,
}) async {
  final router = GoRouter(initialLocation: location, routes: $appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, store: store),
        ),
      ],
      child: MaterialApp.router(
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
