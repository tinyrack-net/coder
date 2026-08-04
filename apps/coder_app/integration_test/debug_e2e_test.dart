import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/tray_menu_model.dart';
import 'package:coder_app/src/workspace/directory_browser.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app switches hosts, streams, approves a patch, and restores timeline',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final home = await Directory.systemTemp.createTemp('coder-e2e-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-e2e-workspace-',
      );
      final remoteHome = await Directory.systemTemp.createTemp(
        'coder-e2e-remote-home-',
      );
      final remoteWorkspace = await Directory.systemTemp.createTemp(
        'coder-e2e-remote-workspace-',
      );
      const selectedModelId =
          'vendor/reasoning-model-with-an-extremely-long-identifier';
      await _initializeGitRepository(workspace.path);
      final modelServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      modelServer.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, dynamic>{
            'object': 'list',
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'e2e-model', 'owned_by': 'test'},
              <String, dynamic>{
                'id': selectedModelId,
                'owned_by': 'test',
              },
            ],
          }),
        );
        await request.response.close();
      });
      final agentProvider = _AgentE2eProvider();
      final handle = await EmbeddedDaemonHandle.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'e2e-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: agentProvider,
      );
      final embeddedLauncher = _RestartableLauncher(
        initialHandle: handle,
        homeDirectory: home.path,
        bearerToken: 'e2e-token-0123456789abcdef0123456789',
        port: handle.boundEndpoint.port,
        provider: agentProvider,
      );
      final remoteHandle = await DaemonApplication.start(
        DaemonConfig(
          homeDirectory: remoteHome.path,
          port: 0,
          bearerToken: 'remote-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await embeddedLauncher.stopCurrent();
        await remoteHandle.stop();
        if (home.existsSync()) home.deleteSync(recursive: true);
        if (remoteHome.existsSync()) remoteHome.deleteSync(recursive: true);
        if (workspace.existsSync()) workspace.deleteSync(recursive: true);
        if (remoteWorkspace.existsSync()) {
          remoteWorkspace.deleteSync(recursive: true);
        }
        await modelServer.close(force: true);
      });
      final endpoint = HostEndpoint(
        websocketUri: handle.boundEndpoint,
      );
      final setupClient = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
        ),
        clientId: 'e2e-setup',
        clientKind: 'integration-test',
      );
      addTearDown(setupClient.close);
      final remoteClient = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: remoteHandle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'remote-token-0123456789abcdef0123456789',
        ),
        clientId: 'e2e-remote-setup',
        clientKind: 'integration-test',
      );
      addTearDown(remoteClient.close);
      await setupClient.registerWorkspace(
        workspaceId: 'workspace-e2e',
        checkoutId: 'checkout-e2e',
        rootPath: workspace.path,
        name: 'E2E Workspace',
      );

      final now = DateTime.utc(2026, 8, 3);
      final appStore = MemoryAppStore(
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'remote',
            label: 'Remote daemon',
            websocketUri: remoteHandle.boundEndpoint,
            autoConnect: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tokens: const <String, String>{
          'remote': 'remote-token-0123456789abcdef0123456789',
        },
      );
      final desktopWindow = PluginDesktopWindow();
      await desktopWindow.prepare(startHidden: false);
      addTearDown(desktopWindow.releaseClose);

      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: appStore,
            profiles: appStore,
            credentials: appStore,
            clients: const WebSocketHostClientFactory(),
            clientKind: 'desktop-integration-test',
            embeddedLauncher: embeddedLauncher,
          ),
          desktopWindow: desktopWindow,
        ),
      );
      // Unmount before the daemons stop so no provider request outlives its
      // client; tear-downs registered earlier run after this one.
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      // The sidebar has no daemon level; each daemon names the workspace rows
      // it serves, so a subtitle is the evidence that it connected.
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await _pumpUntil(tester, find.textContaining('내장 daemon · '));

      // The global desktop menu reaches the same typed new-workspace route.
      expect(find.text('파일'), findsOneWidget);
      await tester.tap(find.text('파일'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New workspace').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-workspace-project-add')));
      await tester.pumpAndSettle();
      final remoteOption = find.descendant(
        of: find.byType(SimpleDialog),
        matching: find.text('Remote daemon'),
      );
      // The remote daemon is only offered once its connection is online.
      await _pumpUntil(tester, remoteOption);
      await tester.tap(remoteOption);
      await _pumpUntil(tester, find.text('Daemon의 폴더 선택'));
      await tester.enterText(
        find.byKey(const ValueKey('directory-browser-path')),
        remoteWorkspace.path,
      );
      await tester.pump(directoryBrowserDebounce);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '이 폴더 선택'));
      await tester.pumpAndSettle();
      await _pumpUntilGone(tester, find.text('Daemon의 폴더 선택'));
      final remoteWorkspaceName = remoteWorkspace.path
          .split(Platform.pathSeparator)
          .last;
      await _pumpUntil(tester, find.text(remoteWorkspaceName));

      await tester.tap(find.byTooltip('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Daemon'));
      final exposureToggle = find.byKey(
        const ValueKey<String>('embedded-daemon-exposure'),
      );
      await _pumpUntil(tester, exposureToggle);
      await tester.tap(exposureToggle);
      await _pumpUntilCondition(
        tester,
        () => embeddedLauncher.exposures.length == 2,
        'embedded daemon to restart on all interfaces',
      );
      await _pumpUntilCondition(
        tester,
        () => tester.widget<SwitchListTile>(exposureToggle).onChanged != null,
        'all-interface daemon to reconnect',
      );
      expect(
        embeddedLauncher.exposures,
        <EmbeddedDaemonExposure>[
          EmbeddedDaemonExposure.loopback,
          EmbeddedDaemonExposure.allInterfaces,
        ],
      );
      await tester.tap(exposureToggle);
      await _pumpUntilCondition(
        tester,
        () => embeddedLauncher.exposures.length == 3,
        'embedded daemon to return to loopback',
      );
      await _pumpUntilCondition(
        tester,
        () => tester.widget<SwitchListTile>(exposureToggle).onChanged != null,
        'loopback daemon to reconnect',
      );
      expect(
        embeddedLauncher.exposures.last,
        EmbeddedDaemonExposure.loopback,
      );
      await tester.tap(find.text('Agent'));
      await _pumpUntil(tester, find.text('Agents'));
      await _selectDaemon(tester, 'Remote daemon');
      await tester.tap(find.byTooltip('Agent 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'remote-agent',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '이름').last,
        'Remote Agent',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createRemoteAgent = find.widgetWithText(FilledButton, '생성');
      await tester.ensureVisible(createRemoteAgent);
      await tester.pumpAndSettle();
      await tester.tap(createRemoteAgent);
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      final remoteAgent = await _waitForAgentDefinition(
        remoteClient,
        'remote-agent',
      );
      expect(remoteAgent.sourcePath, startsWith(remoteHome.path));
      await _selectDaemon(tester, '내장 daemon');
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
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      final createAgent = find.widgetWithText(FilledButton, '생성');
      await tester.ensureVisible(createAgent);
      await tester.pumpAndSettle();
      await tester.tap(createAgent);
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      final reviewer = await _waitForAgentDefinition(setupClient, 'reviewer');
      final reviewerFile = File(reviewer.sourcePath);
      expect(reviewerFile.existsSync(), isTrue);

      final promptField = find.widgetWithText(
        TextField,
        'System prompt (Markdown)',
      );
      await tester.enterText(promptField, 'Review the current change.');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await _waitForAgentPrompt(
        setupClient,
        'reviewer',
        'Review the current change.',
      );
      await reviewerFile.writeAsString(
        (await reviewerFile.readAsString()).replaceFirst(
          'Review the current change.',
          'Review the current change after external reload.',
        ),
        flush: true,
      );
      await _waitForAgentPrompt(
        setupClient,
        'reviewer',
        'Review the current change after external reload.',
      );
      await _pumpUntilTextFieldValue(
        tester,
        promptField,
        'Review the current change after external reload.',
      );

      await tester.tap(find.byTooltip('Agent 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ID (파일명)'),
        'temporary',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '이름').last,
        'Temporary',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createTemporary = find.widgetWithText(FilledButton, '생성');
      await tester.ensureVisible(createTemporary);
      await tester.pumpAndSettle();
      await tester.tap(createTemporary);
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      await _waitForAgentDefinition(setupClient, 'temporary');
      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();
      expect(
        (await setupClient.listAgentDefinitions()).map((item) => item.id),
        isNot(contains('temporary')),
      );

      await tester.tap(find.text('Coder').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('기본값으로 초기화'));
      await tester.pumpAndSettle();
      final editorList = find.byType(ListView).last;
      final editorScrollable = find
          .descendant(of: editorList, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(
        find.text('호출 가능한 Subagent'),
        400,
        scrollable: editorScrollable,
      );
      await tester.tap(find.text('Reviewer').last);
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await setupClient.getAgentDefinition('coder')).callableAgentIds,
        <String>['reviewer'],
      );

      await tester.tap(find.text('스킬'));
      await _pumpUntil(tester, find.byTooltip('스킬 추가'));
      await tester.tap(find.byTooltip('스킬 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'ID (디렉터리 이름)'),
        'e2e-skill',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '이름').last,
        'e2e-skill',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '설명').last,
        'Explains the end-to-end flow.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createSkill = find.widgetWithText(FilledButton, '생성');
      await tester.ensureVisible(createSkill);
      await tester.pumpAndSettle();
      await tester.tap(createSkill);
      await _pumpUntilGone(tester, find.text('스킬 추가'));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.listSkills()).any(
          (skill) => skill.id == 'e2e-skill',
        ),
        'the new skill to reach the daemon',
      );
      expect(
        (await setupClient.getSkill('e2e-skill')).sourcePath,
        startsWith(home.path),
      );

      // A toggleable built-in can be turned off, and the daemon remembers it.
      final commitSwitch = find.descendant(
        of: find.widgetWithText(ListTile, 'commit').first,
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(commitSwitch);
      await tester.pumpAndSettle();
      await tester.tap(commitSwitch);
      await _pumpUntilCondition(
        tester,
        () async => !(await setupClient.getSkill('commit')).isEnabled,
        'the built-in skill to turn off',
      );

      await tester.tap(find.text('e2e-skill').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('스킬 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.listSkills()).every(
          (skill) => skill.id != 'e2e-skill',
        ),
        'the skill to be archived',
      );

      await tester.tap(find.text('Agent'));
      await _pumpUntil(tester, find.text('Agents'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E2E Workspace').last);
      await tester.pumpAndSettle();
      // Worktrees are created by the new-workspace composer, not the tree.
      expect(find.byTooltip('새 worktree'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('workspace-new-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(PopupMenuItem<String>),
              matching: find.text('E2E Workspace'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-provider')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-provider-openai')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Feature e2e',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.getWorkspaceCatalog()).worktrees.any(
          (worktree) => worktree.branch == 'feature-e2e',
        ),
        'the composer to create a worktree',
        attempts: 300,
      );
      // The session route keeps the sidebar, so the new worktree is listed.
      await _pumpUntil(tester, find.text('feature-e2e'));
      await tester.pumpAndSettle();
      final managedTile = find.ancestor(
        of: find.text('feature-e2e'),
        matching: find.byType(ListTile),
      );
      final managedMenu = find.descendant(
        of: managedTile.last,
        matching: find.byTooltip('Worktree 메뉴'),
      );
      await tester.ensureVisible(managedMenu);
      await tester.pumpAndSettle();
      await tester.tap(managedMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await tester.pumpAndSettle();
      if (find.text('main').evaluate().isEmpty) {
        await tester.tap(find.text('E2E Workspace').last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('main'));
      const composer = ValueKey<String>('session-composer-input');
      const send = ValueKey<String>('session-composer-send');
      await _pumpUntil(tester, find.byKey(composer));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('session-composer-model')), findsOne);
      await tester.tap(
        find.byKey(const ValueKey('session-composer-provider')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('session-composer-provider-openai')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(composer), 'Delegate review');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(composer)).controller?.text,
        isNotEmpty,
      );
      expect(tester.widget<IconButton>(find.byKey(send)).onPressed, isNotNull);
      await tester.tap(find.byKey(send));
      await tester.pump();
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('Parent completed.', findRichText: true),
        setupClient,
      );
      await tester.tap(find.byTooltip('모든 session').hitTestable());
      await _pumpUntil(tester, find.text('Reviewer'));
      // The popup is still animating when its label first appears.
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<String>),
          matching: find.text('Reviewer'),
        ),
      );
      await _pumpUntil(tester, find.text('reviewer · delegated'));
      await tester.tap(find.text('Delegate review').first);
      await _pumpUntil(tester, find.text('coder · manual'));

      await tester.enterText(find.byKey(composer), 'Create result.txt');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(composer)).controller?.text,
        isNotEmpty,
      );
      expect(tester.widget<IconButton>(find.byKey(send)).onPressed, isNotNull);
      await tester.tap(find.byKey(send));
      await tester.pump();
      await _pumpUntil(tester, find.text('승인 필요 · apply_patch'));
      await tester.tap(find.text('승인'));
      await _pumpUntil(
        tester,
        find.text('Created result.txt', findRichText: true),
      );
      expect(
        await File('${workspace.path}/result.txt').readAsString(),
        'done\n',
      );
      // Tool activity renders as a CLI summary; no raw payload reaches the UI.
      expect(find.textContaining('Edit('), findsWidgets);
      expect(find.textContaining('changedFiles'), findsNothing);
      expect(find.textContaining('"isError"'), findsNothing);

      // Plan mode proposes work and hands it back for approval.
      await tester.tap(
        find.byKey(const ValueKey('session-composer-mode')).hitTestable(),
      );
      await _pumpUntil(tester, find.textContaining('Plan 모드'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(composer), 'Plan the change');
      await tester.pump();
      expect(tester.widget<IconButton>(find.byKey(send)).onPressed, isNotNull);
      await tester.tap(find.byKey(send));
      await _pumpUntil(tester, find.text('제안된 계획'), attempts: 600);
      await _pumpUntil(
        tester,
        find.text('이 계획대로 진행할까요?'),
        attempts: 600,
      );
      expect(find.textContaining('proposed_plan'), findsNothing);
      final implement = find.widgetWithText(FilledButton, '계획대로 실행');
      await tester.ensureVisible(implement);
      await tester.pumpAndSettle();
      await tester.tap(implement);
      await tester.pump();
      // The chip returning to 실행 proves the session left plan mode.
      await _pumpUntil(tester, find.text('실행'));
      await _pumpUntilGone(tester, find.textContaining('Plan 모드'));

      final reconnected = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
        ),
        clientId: 'e2e-reconnect',
        clientKind: 'integration-test',
      );
      final agents = await reconnected.listSessions(worktreeId: 'checkout-e2e');
      expect(agents, hasLength(2));
      expect(
        agents.every((session) => session.mode == SessionMode.normal),
        isTrue,
      );
      final parent = agents.singleWhere(
        (session) => session.origin == SessionOrigin.manual,
      );
      final child = agents.singleWhere(
        (session) => session.origin == SessionOrigin.delegated,
      );
      expect(child.parentSessionId, parent.id);
      final timeline = await reconnected.subscribeTimeline(parent.id);
      expect(timeline.map((event) => event.type), contains('turn.completed'));
      expect(
        timeline.map((event) => event.sequence),
        orderedEquals(
          List<int>.generate(timeline.length, (index) => index + 1),
        ),
      );
      await reconnected.close();

      await tester.tap(find.byTooltip('설정'));
      await _pumpUntil(tester, find.text('Provider 추가'));
      await _selectDaemon(
        tester,
        'Remote daemon',
        settleAfterSelection: false,
      );
      await _pumpUntil(tester, find.text('Provider 추가'));
      expect(find.text('OpenAI'), findsWidgets);
      expect(find.text('DeepSeek'), findsWidgets);
      final addCustom = find.byKey(const ValueKey('provider-add-custom'));
      await tester.ensureVisible(addCustom);
      await tester.pumpAndSettle();
      await tester.tap(addCustom);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '이름'),
        'E2E Provider',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Base URL'),
        'http://127.0.0.1:${modelServer.port}/v1',
      );
      await tester.tap(find.text('API key 필요'));
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await _pumpUntil(tester, find.text('E2E Provider'));
      // The connection is stored before its model catalog is fetched.
      final providerConnection = await _waitForProviderModels(
        remoteClient,
        'E2E Provider',
      );
      expect(
        (await remoteClient.listProviderModels(
          providerConnection.id,
        )).map((model) => model.id),
        containsAll(<String>['e2e-model', selectedModelId]),
      );
      final connectedSection = find.byKey(
        const ValueKey('provider-settings-connected'),
      );
      final addSection = find.byKey(
        const ValueKey('provider-settings-add'),
      );
      // The save dialog carries the same label, so wait for the settings list
      // itself before measuring section order.
      await _pumpUntil(tester, connectedSection);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(connectedSection).dy,
        lessThanOrEqualTo(tester.getTopLeft(addSection).dy),
      );
      final providerCard = find.ancestor(
        of: find.text('E2E Provider'),
        matching: find.byType(Card),
      );
      final providerMenu = find.descendant(
        of: providerCard.first,
        matching: find.byType(PopupMenuButton<String>),
      );
      await Scrollable.ensureVisible(
        tester.element(providerMenu),
        alignment: 0.3,
      );
      await tester.pumpAndSettle();
      await tester.tap(providerMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('연결 해제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '연결 해제'));
      await tester.pumpAndSettle();
      // The daemon call outlives the frame, so poll instead of asserting once.
      await _pumpUntilCondition(
        tester,
        () async =>
            (await remoteClient.listProviderConnections())
                .singleWhere((item) => item.id == providerConnection.id)
                .status ==
            ProviderConnectionStatus.disconnected,
        'remote provider to disconnect',
      );
      expect(
        (await remoteClient.listProviderConnections())
            .singleWhere((item) => item.id == providerConnection.id)
            .status,
        ProviderConnectionStatus.disconnected,
      );
    },
    tags: const <String>[
      'feature_test__daemon_management__e2e',
      'feature_test__daemon_exposure__e2e',
      'feature_test__daemon_authentication__e2e',
      'feature_test__workspace_catalog__e2e',
      'feature_test__workspace_registration__e2e',
      'feature_test__worktree_lifecycle__e2e',
      'feature_test__session_lifecycle__e2e',
      'feature_test__session_tabs__e2e',
      'feature_test__turn_execution__e2e',
      'feature_test__agent_definition_management__e2e',
      'feature_test__skill_management__e2e',
      'feature_test__agent_delegation__e2e',
      'feature_test__provider_catalog__e2e',
      'feature_test__provider_connection_management__e2e',
      'feature_test__provider_custom__e2e',
      'feature_test__desktop_window_chrome__e2e',
    ],
  );

  testWidgets(
    'the real runner registers a tray icon and hides instead of quitting',
    (tester) async {
      // This runs against the real Linux runner, so it proves the tray and
      // window plugins are linked and answer their channels. It deliberately
      // asserts nothing about the icon being visible: a headless CI display
      // has no StatusNotifier host to show it.
      final window = PluginDesktopWindow();
      final tray = PluginTrayIcon();
      addTearDown(tray.destroy);
      addTearDown(window.releaseClose);

      await window.prepare(startHidden: false);
      expect(window.supportsCustomTitleBar, isTrue);
      expect(await window.isVisible(), isTrue);

      await window.toggleMaximized();
      expect(window.maximized.value, isTrue);
      await window.toggleMaximized();
      expect(window.maximized.value, isFalse);

      var closes = 0;
      await window.interceptClose(() => closes += 1);

      const menu = TrayMenuModel(
        tooltip: 'Tinyrack Coder',
        entries: <TrayMenuEntry>[
          TrayMenuEntry(
            key: trayItemToggleWindow,
            label: 'Show window',
            action: TrayMenuAction.toggleWindow,
          ),
          TrayMenuEntry.separator(),
          TrayMenuEntry(key: trayItemQuit, label: 'Quit'),
        ],
      );
      await tray.install(menu: menu, onSelected: (_) {});
      await tray.update(menu);

      // Hiding must leave the process alive, which is the whole point of
      // closing to the tray.
      await window.hide();
      await _waitForWindowVisibility(window, visible: false);
      await window.show();
      await _waitForWindowVisibility(window, visible: true);
      expect(closes, 0);
    },
    tags: const <String>[
      'feature_test__desktop_residency__platformSmoke',
      'feature_test__desktop_window_chrome__platformSmoke',
    ],
  );
}

Future<void> _waitForWindowVisibility(
  DesktopWindow window, {
  required bool visible,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (await window.isVisible() != visible) {
    if (DateTime.now().isAfter(deadline)) {
      fail('window visibility did not become $visible');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<ProviderConnectionDto> _waitForProviderModels(
  CoderApi api,
  String displayName, {
  int attempts = 50,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    final connection = (await api.listProviderConnections())
        .where((item) => item.displayName == displayName)
        .singleOrNull;
    if (connection != null &&
        (await api.listProviderModels(connection.id)).isNotEmpty) {
      return connection;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw TestFailure(
    'Timed out waiting for $displayName to discover models.',
  );
}

Future<void> _waitForAgentPrompt(
  CoderApi api,
  String id,
  String prompt, {
  int attempts = 50,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    final definition = await api.getAgentDefinition(id);
    if (definition.systemPrompt == prompt) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out waiting for external agent file reload.');
}

Future<AgentDefinitionDto> _waitForAgentDefinition(
  CoderApi api,
  String id, {
  int attempts = 50,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    try {
      return await api.getAgentDefinition(id);
    } on CoderClientException catch (error) {
      if (error.code != 'request_failed') rethrow;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw TestFailure('Timed out waiting for Agent definition $id.');
}

Future<void> _selectDaemon(
  WidgetTester tester,
  String label, {
  bool settleAfterSelection = true,
}) async {
  final dropdown = find.widgetWithText(
    DropdownButtonFormField<String>,
    'Daemon',
  );
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  if (settleAfterSelection) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _pumpUntilTextFieldValue(
  WidgetTester tester,
  Finder finder,
  String value, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    final fields = tester.widgetList<TextField>(finder);
    if (fields.any((field) => field.controller?.text == value)) return;
  }
  throw TestFailure('Timed out waiting for text field value "$value".');
}

Future<void> _initializeGitRepository(String path) async {
  await _runGit(path, <String>['init', '-b', 'main']);
  await File('$path/README.md').writeAsString('# E2E fixture\n');
  await _runGit(path, <String>['add', 'README.md']);
  await _runGit(path, <String>[
    '-c',
    'user.name=Coder E2E',
    '-c',
    'user.email=coder-e2e@example.invalid',
    'commit',
    '-m',
    'Initial fixture',
  ]);
}

Future<void> _runGit(String path, List<String> arguments) async {
  final result = await Process.run('git', arguments, workingDirectory: path);
  if (result.exitCode != 0) {
    throw TestFailure('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder.');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder to disappear.');
}

Future<void> _pumpUntilCondition(
  WidgetTester tester,
  FutureOr<bool> Function() condition,
  String description, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (await condition()) return;
  }
  throw TestFailure('Timed out waiting for $description.');
}

Future<void> _pumpUntilWithSessionDiagnostics(
  WidgetTester tester,
  Finder finder,
  CoderApi api,
) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final sessions = await api.listSessions(worktreeId: 'checkout-e2e');
  final diagnostics = <String, Object?>{};
  for (final session in sessions) {
    diagnostics[session.id] = <String, Object?>{
      'status': session.status.name,
      'definition': session.agentDefinitionId,
      'events': (await api.subscribeTimeline(
        session.id,
      )).map((event) => event.type).toList(growable: false),
    };
  }
  throw TestFailure('Timed out waiting for $finder: $diagnostics');
}

final class _RestartableLauncher implements EmbeddedDaemonLauncher {
  _RestartableLauncher({
    required EmbeddedDaemonHandle initialHandle,
    required this.homeDirectory,
    required this.bearerToken,
    required this.port,
    required this.provider,
  }) : _current = initialHandle;

  final String homeDirectory;
  final String bearerToken;
  final int port;
  final ModelProvider provider;
  final List<EmbeddedDaemonExposure> exposures = <EmbeddedDaemonExposure>[];
  EmbeddedDaemonHandle? _current;
  bool _initial = true;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
  }) async {
    exposures.add(exposure);
    final handle = _initial
        ? _current!
        : await EmbeddedDaemonHandle.start(
            DaemonConfig(
              homeDirectory: homeDirectory,
              host: exposure.bindHost,
              port: port,
              bearerToken: bearerToken,
              useEnvironmentCredentials: false,
            ),
            provider: provider,
          );
    _initial = false;
    _current = handle;
    return _ExistingSession(
      handle,
      onStopped: () {
        if (identical(_current, handle)) _current = null;
      },
    );
  }

  Future<void> stopCurrent() async {
    final handle = _current;
    _current = null;
    await handle?.stop();
  }
}

final class _ExistingSession implements EmbeddedDaemonSession {
  const _ExistingSession(this.handle, {required this.onStopped});

  final EmbeddedDaemonHandle handle;
  final void Function() onStopped;

  @override
  DaemonCredentials get credentials => DaemonCredentials(
    bearerToken: handle.bearerToken,
  );

  @override
  HostEndpoint get endpoint => HostEndpoint(
    websocketUri: handle.boundEndpoint,
  );

  @override
  String get serverId => handle.serverId;

  @override
  Future<void> stop() async {
    await handle.stop();
    onStopped();
  }
}

final class _PatchProvider implements ModelProvider {
  int _round = 0;

  @override
  String get id => 'e2e-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    if (_round == 0) {
      _round += 1;
      const arguments = <String, dynamic>{
        'patch': '--- /dev/null\n+++ b/result.txt\n@@ -0,0 +1,1 @@\n+done\n',
      };
      yield const ModelFunctionCall(
        callId: 'patch-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'patch-call',
              name: 'apply_patch',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Created result.txt');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Created result.txt'),
    );
  }
}

final class _AgentE2eProvider implements ModelProvider {
  @override
  String get id => 'agent-e2e-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final latestPrompt = request.history
        .whereType<UserConversationItem>()
        .last
        .text;
    if (request.instructions.contains('You are in Plan Mode')) {
      const plan =
          'Explored the workspace.\n'
          '<proposed_plan>\n'
          '1. Create result.txt\n'
          '</proposed_plan>';
      yield const ModelTextDelta(plan);
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: plan),
      );
      return;
    }
    final delegateEnabled = request.tools.any(
      (tool) => tool.name == 'delegate_agent',
    );
    final hasDelegateResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'delegate-call');
    final hasPatchResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'patch-call');

    if (latestPrompt == 'Delegate review' &&
        delegateEnabled &&
        !hasDelegateResult) {
      const arguments = <String, dynamic>{
        'agentDefinitionId': 'reviewer',
        'prompt': 'Review without changing files.',
      };
      yield const ModelFunctionCall(
        callId: 'delegate-call',
        name: 'delegate_agent',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'delegate-call',
              name: 'delegate_agent',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (!delegateEnabled) {
      yield const ModelTextDelta('Review completed.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Review completed.'),
      );
      return;
    }
    if (latestPrompt == 'Delegate review') {
      yield const ModelTextDelta('Parent completed.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Parent completed.'),
      );
      return;
    }
    if (latestPrompt == 'Create result.txt' && !hasPatchResult) {
      const arguments = <String, dynamic>{
        'patch': '--- /dev/null\n+++ b/result.txt\n@@ -0,0 +1,1 @@\n+done\n',
      };
      yield const ModelFunctionCall(
        callId: 'patch-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'patch-call',
              name: 'apply_patch',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    yield const ModelTextDelta('Created result.txt');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Created result.txt'),
    );
  }
}
