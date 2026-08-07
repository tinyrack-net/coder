part of '../../app/app_flows_test.dart';

void _registerSessionsAppFlows() {
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
    'the draft composer stays quiet while agent discovery is still loading',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final gate = Completer<void>();
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agentDefinitions: const <AgentDefinitionDto>[],
        agentDefinitionsGate: gate.future,
      );
      final router = await _pumpRoute(
        tester,
        api,
        WorktreeRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
        ).location,
        settle: false,
      );
      addTearDown(router.dispose);
      await tester.pump();
      await tester.pump();

      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('사용 가능한 primary Agent가 없습니다.'), findsOneWidget);
    },
    tags: const <String>['feature_test__workspace_catalog__widget'],
  );

  testWidgets(
    'session tab strip is a TRTabs bar whose commands stay square',
    (tester) async {
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

      // The strip is the design system's tab bar, so its inset, its height,
      // and the tone of the rule below it are upstream contracts covered by
      // upstream tests. What Coder owns is that the open session reaches it as
      // a closable tab.
      final strip = find.byKey(const ValueKey('session-tab-strip'));
      expect(strip, findsOneWidget);
      expect(tester.widget<TRTabs>(strip).value, first.id);
      expect(
        find.descendant(
          of: strip,
          matching: find.byKey(const ValueKey<String>('tr-tabs-close-one')),
        ),
        findsOneWidget,
      );

      // The two menu commands sit beside the square close buttons on each tab,
      // so a wide trigger would read as a stray pill in that row.
      final square = Size.square(TRControlMetrics.heightOf(TRUiSize.md));
      for (final key in const <String>[
        'workspace-new-tab-menu',
        'workspace-all-sessions-menu',
      ]) {
        expect(
          tester.getSize(find.byKey(ValueKey<String>(key))),
          square,
          reason: key,
        );
      }
    },
    tags: const <String>['feature_test__session_tabs__widget'],
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

      await tester.tap(
        find.byKey(const ValueKey('tr-tabs-close-one')),
      );
      await tester.pumpAndSettle();
      expect(find.text('코딩 요청으로 새 session을 시작하세요.'), findsOneWidget);
      expect(
        await api.sessions.listSessions(worktreeId: checkout.id),
        <SessionDto>[
          first,
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey('workspace-all-sessions-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Session one'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tr-tabs-close-one')),
        findsOneWidget,
      );
    },
    tags: const <String>['feature_test__session_tabs__widget'],
  );

  testWidgets(
    'new-tab menu creates a terminal and confirms termination on close',
    (tester) async {
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

      await tester.tap(find.byKey(const ValueKey('workspace-new-tab-menu')));
      await tester.pumpAndSettle();
      expect(find.text('새 session'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('workspace-new-terminal')));
      await tester.pumpAndSettle();

      expect(find.byType(TerminalView), findsOneWidget);
      expect(find.text('Terminal 1'), findsOneWidget);
      final terminal = (await api.terminals.listTerminals(checkout.id)).single;
      await tester.tap(
        find.byKey(ValueKey<String>('tr-tabs-close-${terminal.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('터미널을 종료할까요?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pumpAndSettle();
      expect(find.byType(TerminalView), findsOneWidget);
      await tester.tap(
        find.byKey(ValueKey<String>('tr-tabs-close-${terminal.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('terminal-close-confirm')));
      await tester.pumpAndSettle();
      expect(
        (await api.terminals.listTerminals(checkout.id)).single.status,
        TerminalStatus.exited,
      );
      expect(find.byType(TerminalView), findsNothing);
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets('terminal tab shows attach failures and closes exited shells', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const terminal = TerminalDto(
      id: 'terminal-failed-attach',
      worktreeId: 'checkout',
      title: 'Exited terminal',
      shell: ShellSpecDto(executable: '/bin/sh'),
      status: TerminalStatus.exited,
      columns: 80,
      rows: 24,
      lastSequence: 0,
      exitCode: 0,
    );
    final router = await _pumpRoute(
      tester,
      FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[terminal],
        terminalAttachError: Exception('host disconnected'),
      ),
      TerminalRoute(
        hostId: 'server',
        workspaceId: workspace.id,
        worktreeId: checkout.id,
        terminalId: terminal.id,
      ).location,
    );
    addTearDown(router.dispose);

    expect(find.text('터미널 연결에 실패했어요'), findsOneWidget);
    expect(find.textContaining('host disconnected'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey<String>('tr-tabs-close-${terminal.id}')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('terminal-close-dialog')), findsNothing);
  });

  testWidgets(
    'terminal deep link restores the requested live terminal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const terminal = TerminalDto(
        id: 'terminal-deep-link',
        worktreeId: 'checkout',
        title: 'Remote terminal',
        shell: ShellSpecDto(executable: '/bin/sh'),
        status: TerminalStatus.running,
        columns: 80,
        rows: 24,
        lastSequence: 0,
      );
      final router = await _pumpRoute(
        tester,
        FakeCoderApi(
          workspaces: <WorkspaceDto>[workspace],
          worktrees: <WorktreeDto>[checkout],
          terminals: const <TerminalDto>[terminal],
          terminalReplay: const <TerminalOutputDto>[
            TerminalOutputDto(
              terminalId: 'terminal-deep-link',
              sequence: 1,
              data: 'ready\r\n',
            ),
            TerminalOutputDto(
              terminalId: 'terminal-deep-link',
              sequence: 1,
              data: 'duplicate',
            ),
          ],
        ),
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: terminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      expect(find.byType(TerminalView), findsOneWidget);
      expect(find.text('Remote terminal'), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__terminal_lifecycle__widget',
      'route_test__terminal_route__widget',
    ],
  );

  testWidgets(
    'terminal sends a Hangul word the input method composes exactly once',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      // A Hangul input method keeps its committed text in the platform editing
      // buffer for the whole composition session instead of letting the
      // terminal reset it between syllables.
      for (final value in const <TextEditingValue>[
        TextEditingValue(
          text: 'ㅂ',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '반',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '반',
          selection: TextSelection.collapsed(offset: 1),
        ),
        TextEditingValue(
          text: '반갑',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        TextEditingValue(
          text: '반갑',
          selection: TextSelection.collapsed(offset: 2),
        ),
        TextEditingValue(
          text: '반갑다',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 2, end: 3),
        ),
        TextEditingValue(
          text: '반갑다',
          selection: TextSelection.collapsed(offset: 3),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
      }

      expect(
        api.terminalWrites.map((write) => write.data).join(),
        '반갑다',
      );
      expect(
        api.terminalWrites.map((write) => write.terminalId).toSet(),
        <String>{liveTerminal.id},
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal ignores the duplicate commit a sticky input method repeats',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      // A sticky input method ends its composition session by reporting the
      // unchanged committed buffer one more time, without a new character.
      for (final value in const <TextEditingValue>[
        TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        TextEditingValue(
          text: '한',
          selection: TextSelection.collapsed(offset: 1),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 1, end: 2),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
        ),
        TextEditingValue(
          text: '한솔',
          selection: TextSelection.collapsed(offset: 2),
        ),
      ]) {
        tester.testTextInput.updateEditingValue(value);
        await tester.pump();
      }

      expect(
        api.terminalWrites.map((write) => write.data).join(),
        '한솔',
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal context menu closes on a terminal click and on Escape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      final copy = find.byKey(const ValueKey<String>('terminal-menu-copy'));
      final surface = find.byKey(const ValueKey<String>('tr-terminal-surface'));

      Future<void> openMenu() async {
        final gesture = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(24, 24),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(copy, findsOneWidget);

      // The terminal anchors its own menu, so a click on the terminal is not
      // an outside tap for the menu's tap region and must still close it.
      await tester.tapAt(tester.getBottomRight(surface) - const Offset(48, 48));
      await tester.pumpAndSettle();
      expect(copy, findsNothing);
      // Let the terminal's double-tap recognition window expire.
      await tester.pump(const Duration(milliseconds: 350));

      await openMenu();
      expect(copy, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(copy, findsNothing);

      // Closing the menu consumed Escape instead of sending it to the shell.
      expect(
        api.terminalWrites.map((write) => write.data).join(),
        isNot(contains('\x1b')),
      );
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

  testWidgets(
    'terminal context menu copies the selection and pastes the clipboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          switch (call.method) {
            case 'Clipboard.setData':
              final arguments = call.arguments as Map<Object?, Object?>;
              clipboard = arguments['text'] as String?;
              return null;
            case 'Clipboard.getData':
              return <String, Object?>{'text': clipboard};
            default:
              return null;
          }
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        terminals: const <TerminalDto>[liveTerminal],
        terminalReplay: const <TerminalOutputDto>[
          TerminalOutputDto(
            terminalId: 'terminal-deep-link',
            sequence: 1,
            data: 'selectable output',
          ),
        ],
      );
      final router = await _pumpRoute(
        tester,
        api,
        TerminalRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          terminalId: liveTerminal.id,
        ).location,
      );
      addTearDown(router.dispose);

      final copy = find.byKey(const ValueKey<String>('terminal-menu-copy'));
      expect(copy, findsNothing);

      Future<void> openMenu() async {
        final surface = find.byKey(
          const ValueKey<String>('tr-terminal-surface'),
        );
        final gesture = await tester.startGesture(
          tester.getTopLeft(surface) + const Offset(24, 24),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryButton,
        );
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
      }

      await openMenu();
      expect(copy, findsOneWidget);
      expect(find.text('붙여넣기'), findsOneWidget);

      // Copy stays unavailable until something is selected.
      expect(tester.widget<TRMenuItem>(copy).onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-select-all')),
      );
      await tester.pumpAndSettle();

      await openMenu();
      await tester.tap(copy);
      await tester.pumpAndSettle();
      expect(clipboard, contains('selectable output'));

      await openMenu();
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-paste')),
      );
      await tester.pumpAndSettle();
      expect(
        api.terminalWrites.map((write) => write.data).join(),
        contains('selectable output'),
      );

      await openMenu();
      await tester.tap(
        find.byKey(const ValueKey<String>('terminal-menu-clear-screen')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TerminalView), findsOneWidget);
    },
    tags: const <String>['feature_test__terminal_lifecycle__widget'],
  );

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
          source: AgentModelSource.session,
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
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
          ProviderConnectionDto(
            id: 'deepseek',
            definitionId: 'deepseek',
            displayName: 'DeepSeek',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        models: const <String, List<ProviderModelDto>>{
          'deepseek': <ProviderModelDto>[
            ProviderModelDto(
              connectionId: 'deepseek',
              id: 'gpt-5.6-sol',
              label: 'Shared Model',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
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
      expect(find.byKey(const ValueKey('session-composer-agent')), findsOne);
      expect(find.text('Planner'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('session-composer-provider')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      expect(find.textContaining('OpenAI · gpt-5.6-sol'), findsOneWidget);
      expect(find.text('DeepSeek · gpt-5.6-sol'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('model-search-field')),
        'DeepSeek',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('OpenAI · gpt-5.6-sol'), findsNothing);
      expect(find.text('DeepSeek · gpt-5.6-sol'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('model-option-deepseek-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Run the tests',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.agentDefinitionId, 'planner');
      expect(created.title, 'Run the tests');
      expect(
        created.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'gpt-5.6-sol',
        ),
      );
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
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
          ProviderConnectionDto(
            id: 'deepseek',
            definitionId: 'deepseek',
            displayName: 'DeepSeek',
            status: ProviderConnectionStatus.degraded,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        agentDefinitions: const <AgentDefinitionDto>[
          AgentDefinitionDto(
            id: 'coder',
            name: 'Coder',
            description: 'Coding agent',
            mode: AgentMode.primary,
            promptEnabled: true,
            systemPrompt: 'Code carefully.',
            model: AgentModelSelectionDto(
              source: AgentModelSource.fixed,
              providerConnectionId: 'openai',
              modelId: 'gpt-5.6-sol',
            ),
            reasoningEffort: 'medium',
            permissionMode: PermissionMode.ask,
            toolIds: <String>['read_file'],
            callableAgentIds: <String>[],
            contentHash: 'coder-hash',
            sourcePath: '/config/agents/coder.md',
            isBuiltIn: true,
          ),
        ],
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
          'deepseek': <ProviderModelDto>[
            const ProviderModelDto(
              connectionId: 'deepseek',
              id: 'deepseek-v4',
              label: 'DeepSeek V4',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
              ),
            ),
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
      await tester.tap(
        find.byKey(const ValueKey('model-option-deepseek-deepseek-v4')),
      );
      await tester.pumpAndSettle();
      expect(
        api.updatedSessionModels.single.model,
        const SessionModelSelectionDto(
          providerConnectionId: 'deepseek',
          modelId: 'deepseek-v4',
        ),
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('model-option-inherit')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionModels.last.model, isNull);
      expect((await api.sessions.listSessions()).single.model, isNull);
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'composer turn settings follow model capabilities and return to inherit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        connections: <ProviderConnectionDto>[
          ProviderConnectionDto(
            id: 'openai',
            definitionId: 'openai',
            displayName: 'OpenAI',
            status: ProviderConnectionStatus.connected,
            authKind: ProviderAuthKind.apiKey,
            credentialOrigin: ProviderCredentialOrigin.stored,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        models: const <String, List<ProviderModelDto>>{
          'openai': <ProviderModelDto>[
            ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-sol',
              label: 'GPT-5.6 Sol',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
                reasoningEffort: CapabilitySupport.supported,
                serviceTier: CapabilitySupport.supported,
                supportedReasoningEfforts: <String>['low', 'high'],
                supportedServiceTiers: <String>['default', 'priority'],
              ),
            ),
            // A model the catalog says cannot honour either setting.
            ProviderModelDto(
              connectionId: 'openai',
              id: 'gpt-5.6-plain',
              label: 'GPT-5.6 Plain',
              source: ProviderModelSource.bundled,
              capabilities: ModelCapabilitiesDto(
                streaming: CapabilitySupport.supported,
                toolCalling: CapabilitySupport.supported,
                reasoningEffort: CapabilitySupport.unsupported,
                serviceTier: CapabilitySupport.unsupported,
              ),
            ),
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

      // Permissions never depend on the model, so the chip is always offered.
      expect(
        find.byKey(const ValueKey('session-composer-permission')),
        findsOne,
      );

      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-composer-effort')), findsOne);
      expect(find.byKey(const ValueKey('session-composer-fast')), findsOne);

      await tester.tap(find.byKey(const ValueKey('session-composer-effort')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-effort-high')),
      );
      await tester.pumpAndSettle();
      expect(find.text('high'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('permission-option-readOnly')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('session-composer-fast')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Audit the parser',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      final created = api.createdSessions.single;
      expect(created.reasoningEffort, 'high');
      expect(created.permissionMode, PermissionMode.readOnly);
      expect(created.serviceTier, 'priority');

      // Toggling fast mode off restores the provider default tier.
      await tester.tap(find.byKey(const ValueKey('session-composer-fast')));
      await tester.pumpAndSettle();
      expect(api.updatedSessionServiceTiers.single.serviceTier, isNull);

      await tester.tap(find.byKey(const ValueKey('session-composer-effort')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-effort-inherit')),
      );
      await tester.pumpAndSettle();
      expect(api.updatedSessionReasoningEfforts.single.reasoningEffort, isNull);

      await tester.tap(
        find.byKey(const ValueKey('session-composer-permission')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('permission-option-inherit')),
      );
      await tester.pumpAndSettle();
      expect(api.updatedSessionPermissionModes.single.permissionMode, isNull);

      // A model without the capability hides both controls again.
      await tester.tap(find.byKey(const ValueKey('session-composer-model')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-plain')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('session-composer-effort')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('session-composer-fast')), findsNothing);
      expect(
        find.byKey(const ValueKey('session-composer-permission')),
        findsOne,
      );
    },
    tags: const <String>['feature_test__session_lifecycle__widget'],
  );

  testWidgets(
    'the draft composer runs a client command instead of sending it',
    (tester) async {
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

      // The draft pane creates its session from the first prompt, so `/new`
      // has no session to be new relative to.
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/',
      );
      await tester.pumpAndSettle();
      expect(find.text('mode'), findsOneWidget);
      expect(find.text('new'), findsNothing);

      expect(find.text('Plan'), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        '/mode',
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await tester.pumpAndSettle();

      expect(find.text('Plan'), findsOneWidget);
      expect(api.createdSessions, isEmpty);
      expect(api.startedPrompts, isEmpty);
    },
    tags: const <String>['feature_test__composer_slash_command__widget'],
  );
}
