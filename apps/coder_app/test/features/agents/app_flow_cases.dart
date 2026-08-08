part of '../../app/app_flows_test.dart';

void _registerAgentsAppFlows() {
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
      final prompt = _textInput('시스템 프롬프트 (Markdown)');
      await tester.enterText(prompt, 'Always run focused tests.');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await api.agents.getAgentDefinition('coder')).systemPrompt,
        'Always run focused tests.',
      );
      await tester.scrollUntilVisible(
        find.text('내장 도구'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('내장 도구'), findsOneWidget);

      // An always-on tool is shown checked and locked, sorted above the
      // tools the user can actually turn off.
      final alwaysOn = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-tile-read_file')),
      );
      expect(alwaysOn.value, isTrue);
      expect(alwaysOn.onChanged, isNull);
      expect(
        find.byKey(const ValueKey<String>('agent-tool-lock-read_file')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('agent-tool-tile-exec_command')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      final toggleable = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-tile-exec_command')),
      );
      expect(toggleable.onChanged, isNotNull);

      await tester.tap(find.byKey(const ValueKey('agent-add-button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('ID (파일명)'),
        'reviewer',
      );
      await tester.enterText(
        _textInput('이름').last,
        'Reviewer',
      );
      await tester.tap(
        find.byType(TRSelectFormField<AgentMode>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('subagent').last);
      tester.testTextInput.hide();
      final createButton = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createButton);
      await tester.pumpAndSettle();
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      expect(find.text('Reviewer'), findsWidgets);
      expect(
        (await api.agents.getAgentDefinition('reviewer')).mode,
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

      await tester.tap(find.byKey(const ValueKey('agent-add-button')));
      await tester.pumpAndSettle();
      var create = tester.widget<TRButton>(
        find.widgetWithText(TRButton, '생성'),
      );
      expect(create.onPressed, isNull);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'Invalid ID',
      );
      await tester.enterText(
        _textInput('이름').last,
        'Reviewer',
      );
      await tester.pumpAndSettle();
      expect(find.text('영문 소문자, 숫자, -, _만 사용할 수 있습니다.'), findsOneWidget);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'coder',
      );
      await tester.pumpAndSettle();
      expect(find.text('이미 존재하는 Agent ID입니다.'), findsOneWidget);

      await tester.enterText(
        _textInput('ID (파일명)'),
        'reviewer',
      );
      await tester.pumpAndSettle();
      create = tester.widget<TRButton>(
        find.widgetWithText(TRButton, '생성'),
      );
      expect(create.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(TRButton, '생성'));
      await tester.pumpAndSettle();
      expect(find.textContaining('agent_create_failed'), findsOneWidget);
      expect(find.text('Agent 추가'), findsOneWidget);

      await tester.tap(find.widgetWithText(TRButton, '생성'));
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
    expect(_textField('시스템 프롬프트 (Markdown)'), findsNothing);
    await tester.tap(find.text('Coder').first);
    await tester.pumpAndSettle();
    expect(_textField('시스템 프롬프트 (Markdown)'), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-list-button')), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-back-button')),
    );
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
          source: AgentModelSource.session,
        ),
        modelControls: <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.stringValue(value: 'medium'),
        },
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
          source: AgentModelSource.session,
        ),
        modelControls: <String, ModelControlValueDto>{
          'reasoning_effort': ModelControlValueDto.stringValue(value: 'medium'),
        },
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
      await tester.tap(find.byKey(const ValueKey('agent-copy-path-button')));
      await tester.tap(find.text('Custom system prompt 사용'));
      final editorList = find.byType(ListView).last;
      await tester.drag(editorList, const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('고정 provider/model'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _textInput('Provider 연결 ID'),
        'openai',
      );
      await tester.enterText(
        _textInput('Model ID'),
        'gpt-test',
      );
      await tester.drag(editorList, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('read_file').last);
      await tester.tap(find.text('Reviewer').last);
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 저장 실패'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, 'Overwrite'));
      await tester.pumpAndSettle();

      final updated = await api.agents.getAgentDefinition('coder');
      expect(updated.promptEnabled, isFalse);
      expect(updated.model.providerConnectionId, 'openai');
      expect(updated.model.modelId, 'gpt-test');
      expect(updated.toolIds, isEmpty);
      expect(updated.callableAgentIds, <String>['reviewer']);

      await tester.tap(find.byKey(const ValueKey('agent-reset-button')));
      await tester.pumpAndSettle();
      expect(
        (await api.agents.getAgentDefinition('coder')).systemPrompt,
        'Code carefully.',
      );
      await tester.tap(find.text('Reviewer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agent-archive-button')));
      await tester.pumpAndSettle();
      expect(
        (await api.agents.listAgentDefinitions()).map(
          (definition) => definition.id,
        ),
        isNot(contains('reviewer')),
      );
    },
    tags: const <String>['feature_test__agent_collaboration__widget'],
  );

  testWidgets('remote agent settings stays editable and exposes load errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const remoteInfo = ServerInfoDto(
      serverId: 'server',
      version: 'test',
      protocolVersion: coderProtocolMajor,
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
          .widget<TRIconButton>(
            find.widgetWithIcon(TRIconButton, CoderIcons.add),
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
    await tester.tap(find.widgetWithText(TRButton, '다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('definition load failed'), findsOneWidget);
  });
}
