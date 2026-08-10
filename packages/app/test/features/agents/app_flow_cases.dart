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

      // Tools are behind their group, so nothing is listed until one opens.
      expect(
        find.byKey(const ValueKey<String>('agent-tool-tile-read_file')),
        findsNothing,
      );
      // A group of nothing but always-on tools is checked and locked, and it
      // still opens: the lock is on the tools, not on the disclosure.
      final lockedGroup = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-group-filesystem')),
      );
      expect(lockedGroup.value, isTrue);
      expect(lockedGroup.onChanged, isNull);

      await tester.tap(
        find.byKey(const ValueKey<String>('agent-tool-group-filesystem')),
      );
      await tester.pumpAndSettle();
      // An always-on tool is shown checked and locked once its group is open.
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
        find.byKey(const ValueKey<String>('agent-tool-group-execution')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-tool-group-execution')),
      );
      await tester.pumpAndSettle();
      final toggleable = tester.widget<CoderCheckboxRow>(
        find.byKey(const ValueKey<String>('agent-tool-tile-exec_command')),
      );
      expect(toggleable.onChanged, isNotNull);

      await tester.tap(find.byKey(const ValueKey('agent-add-button')));
      await tester.pumpAndSettle();
      expect(find.byType(TRAlertDialog), findsNothing);
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
      final created = await api.agents.getAgentDefinition('reviewer');
      expect(created.mode, AgentMode.subagent);
      // A new agent starts with an empty prompt, so the override stays off
      // even though the Coder template it is cloned from has it enabled.
      expect(created.systemPrompt, isEmpty);
      expect(created.promptEnabled, isFalse);
    },
    tags: const <String>[
      'feature_test__agent_definition_management__widget',
    ],
  );

  testWidgets(
    'agent create validates input and keeps daemon failures in the pane',
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
      expect(find.text('Agent 추가'), findsWidgets);

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
      await tester.tap(find.widgetWithText(TRButton, '변경').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ModelPicker),
          matching: find.text('openai/gpt-5.6-sol'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(editorList, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reviewer').last);
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Agent 저장 실패'), findsOneWidget);
      await tester.tap(find.widgetWithText(TRButton, 'Overwrite'));
      await tester.pumpAndSettle();

      final updated = await api.agents.getAgentDefinition('coder');
      expect(updated.promptEnabled, isFalse);
      expect(updated.model.modelId, 'openai/gpt-5.6-sol');
      expect(updated.toolIds, isEmpty);
      expect(updated.callableAgentIds, <String>['reviewer']);

      await tester.tap(find.byKey(const ValueKey('agent-reset-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-reset-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        (await api.agents.getAgentDefinition('coder')).systemPrompt,
        'Code carefully.',
      );
      await tester.tap(find.text('Reviewer').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agent-archive-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-archive-confirm')),
      );
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

  testWidgets(
    'resetting a built-in agent asks first and reports what it did',
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

      // Edit first, so a reset that runs has something to undo.
      await tester.enterText(
        _textInput('시스템 프롬프트 (Markdown)'),
        'Always run focused tests.',
      );
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('agent-reset-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '취소'));
      await tester.pumpAndSettle();
      expect(
        (await api.agents.getAgentDefinition('coder')).systemPrompt,
        'Always run focused tests.',
        reason: 'declining the question must not discard the edit',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('agent-reset-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-reset-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('기본 Agent로 되돌렸습니다.'), findsOneWidget);
    },
    tags: const <String>[
      'feature_test__agent_definition_management__widget',
      'feature_test__app_toast__widget',
    ],
  );

  testWidgets(
    'a tool group header turns its whole group on and off at once',
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

      final scrollable = find.byType(Scrollable).last;
      // scrollUntilVisible stops as soon as the row is built, which a list
      // builds before it is on screen, so the row still has to be brought
      // fully into view before it can be tapped.
      Future<void> reveal(String key) async {
        final finder = find.byKey(ValueKey<String>(key));
        await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
      }

      CoderCheckboxRow rowFor(String key) =>
          tester.widget<CoderCheckboxRow>(find.byKey(ValueKey<String>(key)));

      await reveal('agent-tool-group-mcp');
      final initial = rowFor('agent-tool-group-mcp');
      expect(initial.value, isFalse);
      expect(initial.indeterminate, isFalse);

      // Checking the header takes every tool in the group, not just one.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('agent-tool-group-mcp')),
          matching: find.byType(TRCheckbox),
        ),
      );
      await tester.pumpAndSettle();
      expect(rowFor('agent-tool-group-mcp').value, isTrue);

      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await api.agents.getAgentDefinition('coder')).toolIds,
        <String>[
          'list_mcp_resource_templates',
          'list_mcp_resources',
          'read_mcp_resource',
        ],
        reason: 'a group is stored as the ids it contains, not as itself',
      );

      // Turning one member off leaves the header partially checked.
      await reveal('agent-tool-group-mcp');
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-tool-group-mcp')),
      );
      await tester.pumpAndSettle();
      await reveal('agent-tool-tile-read_mcp_resource');
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-tool-tile-read_mcp_resource')),
      );
      await tester.pumpAndSettle();
      await reveal('agent-tool-group-mcp');
      final partial = rowFor('agent-tool-group-mcp');
      expect(partial.value, isFalse);
      expect(partial.indeterminate, isTrue);
    },
    tags: const <String>[
      'feature_test__agent_definition_management__widget',
    ],
  );
}
