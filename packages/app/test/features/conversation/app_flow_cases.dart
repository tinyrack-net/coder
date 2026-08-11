part of '../../app/app_flows_test.dart';

void _registerConversationAppFlows() {
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
  SessionDto session(String id) => SessionDto(
    id: id,
    worktreeId: checkout.id,
    title: 'Session $id',
    agentDefinitionId: 'tinest',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );
  testWidgets(
    'conversation content is capped and centered while its header stays wide',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final root = session('layout');
      final child = session('layout-child').copyWith(
        parentSessionId: root.id,
        taskName: 'Layout child',
      );
      final goal = GoalDto(
        sessionId: root.id,
        goalId: 'layout-goal',
        objective: 'Keep the conversation column aligned',
        status: GoalStatus.active,
        tokensUsed: 0,
        timeUsedSeconds: 0,
        createdAt: now,
        updatedAt: now,
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[root, child],
        goals: <String, GoalDto>{root.id: goal},
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: root.id,
        ).location,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      final pane = find.byKey(
        ValueKey<String>('conversation-pane-session:${root.id}'),
      );
      final timeline = find.byType(ChatTimelineView);
      final composer = find.byType(SessionComposer);
      final goalBar = find.byType(GoalStatusBar);
      final subagents = find.byType(SubagentTrack);
      final header = find
          .ancestor(
            of: find.text(root.title).last,
            matching: find.byType(TinestListRow),
          )
          .first;

      final paneRect = tester.getRect(pane);
      for (final content in <Finder>[timeline, composer, goalBar]) {
        final rect = tester.getRect(content);
        expect(
          rect.width,
          TRMeasurements.measureXl * 2 + TRSpacing.extraLarge * 2,
        );
        expect(rect.center.dx, closeTo(paneRect.center.dx, 0.5));
      }
      final subagentRect = tester.getRect(subagents);
      expect(
        subagentRect.width,
        TinestLayoutMetrics.conversationContentMaxWidth - TRSpacing.medium * 2,
      );
      expect(subagentRect.center.dx, closeTo(paneRect.center.dx, 0.5));
      expect(tester.getRect(header).width, paneRect.width);
      expect(
        find.byKey(const ValueKey<String>('session-composer-model')),
        findsOneWidget,
      );

      await tester.binding.setSurfaceSize(const Size(700, 900));
      await tester.pumpAndSettle();
      final narrowPane = tester.getRect(pane);
      for (final content in <Finder>[timeline, composer, goalBar]) {
        final rect = tester.getRect(content);
        expect(rect.width, narrowPane.width);
        expect(rect.center.dx, closeTo(narrowPane.center.dx, 0.5));
      }
      final narrowSubagents = tester.getRect(subagents);
      expect(
        narrowSubagents.width,
        narrowPane.width - TRSpacing.medium * 2,
      );
      expect(narrowSubagents.center.dx, closeTo(narrowPane.center.dx, 0.5));
      expect(
        find.byKey(const ValueKey<String>('session-composer-settings')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'a running chat restores permission and reports a daemon save failure',
    (tester) async {
      final running = session('running').copyWith(
        status: SessionStatus.running,
        permissionMode: PermissionMode.ask,
      );
      final api = FakeTinestApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[running],
        sessionPermissionSetError: Exception('daemon rejected update'),
      );
      final router = await _pumpRoute(
        tester,
        api,
        SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: running.id,
        ).location,
        disableAnimations: true,
      );
      addTearDown(router.dispose);
      await tester.pumpAndSettle();

      await _openComposerSetting(tester, 'permission');
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
      await tester.binding.setSurfaceSize(const Size(1500, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeTinestApi(
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
      await _selectComposerMode(tester, SessionMode.plan);
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

      final timelineBefore = tester.getRect(find.byType(ChatTimelineView));

      await tester.tap(find.widgetWithText(TRButton, '계획대로 실행'));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModes.single.mode, SessionMode.normal);
      expect(api.startedPrompts.last, '계획을 실행해줘.');
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
      expect(tester.getRect(find.byType(ChatTimelineView)), timelineBefore);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'a mode refused during a turn is explained rather than dropped',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final planning = session('planning');
      // The composer keeps the mode reachable while a turn runs because it
      // applies to the next one, so the daemon's refusal is a normal answer.
      // It used to be fired and forgotten: the chip snapped back with nothing
      // said and the failure escaped as an unhandled asynchronous error.
      final api =
          FakeTinestApi(
              workspaces: <WorkspaceDto>[workspace],
              worktrees: <WorktreeDto>[checkout],
              agents: <SessionDto>[planning],
            )
            ..sessionUpdateError = const TinestClientException(
              'Cannot change the settings while a turn is running.',
              code: RpcErrorCodes.sessionTurnActive,
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

      await _selectComposerMode(tester, SessionMode.normal);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('turn을 실행 중입니다', findRichText: true),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'a plan can be handed to a fresh session or postponed',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final planning = session('planning').copyWith(mode: SessionMode.plan);
      final api = FakeTinestApi(
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

      expect(
        find.byKey(const ValueKey<String>('session-composer-settings')),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TRButton, '계속 계획'));
      await tester.pumpAndSettle();
      expect(find.text('이 계획대로 진행할까요?'), findsNothing);
      expect(api.startedPrompts, isEmpty);

      await _selectComposerMode(tester, SessionMode.normal);
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
      final api = FakeTinestApi(agents: <SessionDto>[agent]);
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
      expect(find.byType(TRChatUserBubble), findsOneWidget);
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
    tags: const <String>[
      'feature_test__turn_execution__widget',
      'ui_state__conversation_timeline__approval_pending__widget',
    ],
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
      final api = FakeTinestApi(agents: <SessionDto>[agent]);
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
    tags: const <String>[
      'feature_test__turn_question__widget',
      'ui_state__conversation_timeline__question_pending__widget',
    ],
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
      final api = FakeTinestApi(
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

  testWidgets(
    'a multi-question card pages through tabs and submits ordered answers',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final agent = session('asking-many');
      final request = UserQuestionRequestDto(
        id: 'questions',
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
          UserQuestionItemDto(
            id: 'theme',
            header: 'Theme',
            question: 'Which theme should the editor use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'System',
                description: 'Follow the operating system.',
              ),
              UserQuestionOptionDto(
                label: 'Dark',
                description: 'Always use the dark theme.',
              ),
            ],
          ),
          UserQuestionItemDto(
            id: 'review',
            header: 'Review',
            question: 'How should changes be reviewed?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(
                label: 'Pull request',
                description: 'Require a review before merging.',
              ),
              UserQuestionOptionDto(
                label: 'Direct',
                description: 'Merge directly after checks pass.',
              ),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );
      final api = FakeTinestApi(agents: <SessionDto>[agent]);
      await tester.pumpWidget(
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
      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
      expect(find.byType(TRTabs), findsOneWidget);
      expect(find.text('Which store should the cache use?'), findsOneWidget);
      expect(find.text('Which theme should the editor use?'), findsNothing);
      expect(find.text('How should changes be reviewed?'), findsNothing);
      expect(
        tester
            .widgetList<TRRadio>(find.byType(TRRadio))
            .every(
              (radio) =>
                  radio.labelAlignment == TRRadioLabelAlignment.firstLine,
            ),
        isTrue,
      );

      await tester.tap(find.text('SQLite'));
      await tester.pumpAndSettle();
      expect(find.text('Which store should the cache use?'), findsNothing);
      expect(find.text('Which theme should the editor use?'), findsOneWidget);
      expect(find.byIcon(TinestIcons.check), findsOneWidget);

      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      final other = find.byKey(
        const ValueKey<String>('chat-question-other-theme'),
      );
      expect(other, findsOneWidget);
      final primary = find.byKey(
        const ValueKey<String>('chat-question-submit'),
      );
      expect(find.widgetWithText(TRButton, '다음'), findsOneWidget);
      expect(tester.widget<TRButton>(primary).onPressed, isNull);
      await tester.enterText(other, '  High contrast  ');
      await tester.pumpAndSettle();
      expect(tester.widget<TRButton>(primary).onPressed, isNotNull);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(find.text('How should changes be reviewed?'), findsOneWidget);
      expect(find.byIcon(TinestIcons.check), findsNWidgets(2));
      expect(find.widgetWithText(TRButton, '답변'), findsOneWidget);
      expect(tester.widget<TRButton>(primary).onPressed, isNull);

      await tester.tap(find.text('Storage'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRRadioGroup>(find.byType(TRRadioGroup)).value, '0');
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TRTextField>(
              find.byKey(
                const ValueKey<String>('chat-question-other-theme'),
              ),
            )
            .controller
            ?.text,
        '  High contrast  ',
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pull request'));
      await tester.pumpAndSettle();
      expect(tester.widget<TRButton>(primary).onPressed, isNotNull);

      api.questionAnswerError = Exception('daemon rejected answers');
      await tester.tap(primary);
      await tester.pumpAndSettle();
      expect(find.text('Exception: daemon rejected answers'), findsOneWidget);
      expect(tester.widget<TRButton>(primary).loading, isFalse);
      expect(tester.widget<TRButton>(primary).onPressed, isNotNull);
      expect(
        tester.widget<TRTabs>(find.byType(TRTabs)).tabs,
        everyElement(
          isA<TRTabsTab>().having(
            (tab) => tab.disabled,
            'disabled',
            isFalse,
          ),
        ),
      );
      api
        ..questionAnswers.clear()
        ..questionAnswerError = null
        ..questionAnswerGate = Completer<void>();

      await tester.tap(primary);
      await tester.pump();

      expect(tester.widget<TRButton>(primary).loading, isTrue);
      expect(
        tester.widget<TRRadioGroup>(find.byType(TRRadioGroup)).disabled,
        isTrue,
      );
      expect(
        tester.widget<TRTabs>(find.byType(TRTabs)).tabs,
        everyElement(
          isA<TRTabsTab>().having((tab) => tab.disabled, 'disabled', isTrue),
        ),
      );
      api.questionAnswerGate!.complete();
      await tester.pumpAndSettle();

      expect(api.questionAnswers.single.id, 'questions');
      expect(api.questionAnswers.single.answers, const <UserQuestionAnswerDto>[
        UserQuestionAnswerDto(
          questionId: 'store',
          answer: 'SQLite',
          isFreeForm: false,
        ),
        UserQuestionAnswerDto(
          questionId: 'theme',
          answer: 'High contrast',
          isFreeForm: true,
        ),
        UserQuestionAnswerDto(
          questionId: 'review',
          answer: 'Pull request',
          isFreeForm: false,
        ),
      ]);
    },
    tags: const <String>[
      'feature_test__turn_question__widget',
      'ui_transition__conversation_timeline__answer_question__widget',
    ],
  );

  testWidgets(
    'question tabs remain accessible on a narrow large-text surface',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final request = UserQuestionRequestDto(
        id: 'compact-questions',
        sessionId: 'compact-session',
        turnId: 'turn',
        toolCallId: 'ask-call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'store',
            header: 'Storage',
            question: 'Which store should the cache use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(label: 'SQLite', description: 'Durable.'),
              UserQuestionOptionDto(label: 'Memory', description: 'Fast.'),
            ],
          ),
          UserQuestionItemDto(
            id: 'theme',
            header: 'Theme',
            question: 'Which theme should the editor use?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(label: 'System', description: 'Follow it.'),
              UserQuestionOptionDto(label: 'Dark', description: 'Always dark.'),
            ],
          ),
          UserQuestionItemDto(
            id: 'review',
            header: 'Review',
            question: 'How should changes be reviewed?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(label: 'PR', description: 'Review first.'),
              UserQuestionOptionDto(label: 'Direct', description: 'Merge now.'),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChatQuestionCard(hostId: 'server', request: request),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('질문'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Which theme should the editor use?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
    tags: const <String>[
      'feature_test__turn_question__widget',
      // Exact executable tag required by the typed UI manifest.
      // ignore: lines_longer_than_80_chars
      'ui_variant__conversation_timeline__mobile_light_korean_large_text_touch_online__widget',
    ],
  );
}
