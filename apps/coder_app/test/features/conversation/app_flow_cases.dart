part of '../../app/app_flows_test.dart';

void _registerConversationAppFlows() {
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
    'a running chat restores permission and reports a daemon save failure',
    (tester) async {
      final running = session('running').copyWith(
        status: SessionStatus.running,
        permissionMode: PermissionMode.ask,
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[running],
        sessionPermissionSetError: Exception('daemon rejected update'),
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

      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission')),
      );
      await tester.pumpAndSettle();
      final fullAccess = find.byKey(
        const ValueKey('permission-option-fullAccess'),
      );
      await tester.ensureVisible(fullAccess);
      await tester.tap(fullAccess);
      await tester.pumpAndSettle();

      expect(find.text('변경 전 확인'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-composer-permission-error')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
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
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      // The chip label is the whole mode indicator, so the run label is gone.
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('실행'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Migrate the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.mode, SessionMode.plan);
      // Sending a prompt keeps the session in plan mode.
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('실행'), findsNothing);

      api
        ..emitTimeline(
          created.id,
          'assistant.delta',
          <String, dynamic>{'text': 'Explored it.'},
        )
        ..emitTimeline(created.id, 'tool.requested', <String, dynamic>{
          'callId': 'call-plan',
          'name': 'update_plan',
          'arguments': _planArguments,
        })
        ..emitTimeline(created.id, 'tool.completed', <String, dynamic>{
          'callId': 'call-plan',
          'name': 'update_plan',
          'output': '{}',
        })
        ..emitTimeline(
          created.id,
          'turn.completed',
          <String, dynamic>{'toolRounds': 1},
        );
      await tester.pumpAndSettle();

      expect(find.text('계획'), findsOneWidget);
      expect(
        find.textContaining('Move the parser', findRichText: true),
        findsWidgets,
      );
      expect(find.text('이 계획대로 진행할까요?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TRButton, '계획대로 실행'));
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
              type: 'tool.requested',
              data: <String, dynamic>{
                'callId': 'call-plan',
                'name': 'update_plan',
                'arguments': _planArguments,
              },
              createdAt: now,
            ),
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 2,
              turnId: 'turn-1',
              type: 'tool.completed',
              data: const <String, dynamic>{
                'callId': 'call-plan',
                'name': 'update_plan',
                'output': '{}',
              },
              createdAt: now,
            ),
            TimelineEventDto(
              sessionId: planning.id,
              sequence: 3,
              turnId: 'turn-1',
              type: 'turn.completed',
              data: const <String, dynamic>{'toolRounds': 1},
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
      await tester.tap(find.widgetWithText(TRButton, '계속 계획'));
      await tester.pumpAndSettle();
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
      expect(api.startedPrompts, isEmpty);

      await tester.tap(find.byKey(const ValueKey('session-composer-mode')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

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
            theme: testLightTheme,
            darkTheme: testDarkTheme,
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
      await tester.tap(find.widgetWithText(TRButton, '거부'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '승인'));
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

  testWidgets(
    'a question card answers with an option or with free-form text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final agent = session('asking');
      final request = UserQuestionRequestDto(
        id: 'question',
        sessionId: agent.id,
        turnId: 'turn',
        toolCallId: 'ask-call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'store',
            header: 'Storage',
            question: 'Which store should the cache use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'SQLite',
                description: 'Durable and already a dependency.',
              ),
              UserQuestionOptionDto(
                label: 'In memory',
                description: 'Fastest, lost on restart.',
              ),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );
      final api = FakeCoderApi(agents: <SessionDto>[agent]);
      Future<void> pump() => tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
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
                  ChatQuestionCard(hostId: 'server', request: request),
                ],
              ),
            ),
          ),
        ),
      );

      await pump();
      await tester.pumpAndSettle();
      expect(find.text('ready'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('Which store should the cache use?'), findsOneWidget);
      expect(find.text('Durable and already a dependency.'), findsOneWidget);
      // The client offers the free-form choice; the agent never authors it.
      expect(find.text('직접 입력'), findsOneWidget);

      final submit = find.byKey(const ValueKey<String>('chat-question-submit'));
      expect(tester.widget<TRButton>(submit).onPressed, isNull);

      await tester.tap(find.text('SQLite'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.questionAnswers.single.id, 'question');
      expect(api.questionAnswers.single.answers, <UserQuestionAnswerDto>[
        const UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'SQLite',
          isFreeForm: false,
        ),
      ]);

      await pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      final field = find.byKey(
        const ValueKey<String>('chat-question-other-store'),
      );
      expect(field, findsOneWidget);
      // Blank free-form text is not an answer.
      expect(tester.widget<TRButton>(submit).onPressed, isNull);
      await tester.enterText(field, '  Postgres  ');
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.questionAnswers.last.answers, <UserQuestionAnswerDto>[
        const UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'Postgres',
          isFreeForm: true,
        ),
      ]);
    },
    tags: const <String>['feature_test__turn_question__widget'],
  );

  testWidgets(
    'session goal controls edit and dispatch every slash command lifecycle',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final agent = session('goal-session');
      final activeGoal = GoalDto(
        sessionId: agent.id,
        goalId: 'goal-1',
        objective: 'Ship the persistent goal flow',
        status: GoalStatus.active,
        tokenBudget: 12000,
        tokensUsed: 4200,
        timeUsedSeconds: 30,
        createdAt: now,
        updatedAt: now,
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[agent],
        goals: <String, GoalDto>{agent.id: activeGoal},
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: agent.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      expect(find.text('Ship the persistent goal flow'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(testL10n.goalEdit));
      await tester.pumpAndSettle();
      final dialog = find.byType(TRAlertDialog);
      final objective = find
          .descendant(
            of: dialog,
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(objective, 'Ship the edited goal flow');
      await tester.tap(find.widgetWithText(TRButton, testL10n.commonSave));
      await tester.pumpAndSettle();
      expect(
        (await api.getGoal(agent.id))?.objective,
        'Ship the edited goal flow',
      );

      Future<void> submitGoalCommand(String command) async {
        await tester.enterText(
          find.byKey(const ValueKey('session-composer-input')),
          command,
        );
        await tester.tap(find.byKey(const ValueKey('session-composer-send')));
        await tester.pumpAndSettle();
      }

      await submitGoalCommand('/goal pause');
      expect((await api.getGoal(agent.id))?.status, GoalStatus.paused);
      await submitGoalCommand('/goal resume');
      expect((await api.getGoal(agent.id))?.status, GoalStatus.active);
      await submitGoalCommand('/goal clear');
      expect(await api.getGoal(agent.id), isNull);

      await submitGoalCommand('/goal Ship a replacement');
      expect(
        (await api.getGoal(agent.id))?.objective,
        'Ship a replacement',
      );
      await submitGoalCommand('/goal Replace it again');
      expect(find.text(testL10n.goalReplaceTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TRButton, testL10n.goalReplaceAction),
      );
      await tester.pumpAndSettle();
      expect((await api.getGoal(agent.id))?.objective, 'Replace it again');
    },
    tags: const <String>['feature_test__session_goal__widget'],
  );
}
