import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:app/src/features/conversation/presentation/chat_approval_card.dart';
import 'package:app/src/features/conversation/presentation/chat_tool_card.dart';
import 'package:app/src/features/conversation/presentation/widgets/session_composer.dart';
import 'package:app/src/features/desktop/domain/tray_menu_model.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/shared/presentation/coder_icons.dart';
import 'package:app/src/shared/presentation/coder_selection_row.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/pump_until.dart';
import 'support/temporary_directory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app switches hosts, streams, approves a patch, and restores timeline',
    (tester) async {
      // GitHub's Linux runner can expose platform accessibility even when
      // testWidgets does not create its own semantics handle. Force it off for
      // this visual interaction test to avoid flutter/flutter#189902.
      tester.platformDispatcher.semanticsEnabledTestValue = false;
      addTearDown(
        tester.platformDispatcher.clearSemanticsEnabledTestValue,
      );
      expect(tester.binding.semanticsEnabled, isFalse);
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final home = await Directory.systemTemp.createTemp('coder-e2e-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-e2e-workspace-',
      );
      final directoryWorkspace = await Directory.systemTemp.createTemp(
        'coder-e2e-directory-',
      );
      // Stands in for the machine home the daemon turns into the implicit home
      // workspace, so the run never touches the home of whoever runs it.
      final userHome = Directory(
        await (await Directory.systemTemp.createTemp(
          'coder-e2e-user-home-',
        )).resolveSymbolicLinks(),
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
      await _writeProjectCommand(workspace.path);
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
      final attachmentCapture = File(
        '${home.path}/provider-attachment-capture.json',
      );
      final imageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
        'A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final documentBytes = utf8.encode('attachment document\n');
      final agentProvider = _AgentE2eProvider(attachmentCapture.path);
      final handle = await EmbeddedDaemonHandle.start(
        DaemonConfig(
          homeDirectory: home.path,
          userHomeDirectory: userHome.path,
          port: 0,
          bearerToken: 'e2e-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: agentProvider,
      );
      final embeddedLauncher = _RestartableLauncher(
        initialHandle: handle,
        homeDirectory: home.path,
        userHomeDirectory: userHome.path,
        bearerToken: 'e2e-token-0123456789abcdef0123456789',
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
        modelDiscovery: const _E2eModelDiscovery(),
      );
      addTearDown(() async {
        await embeddedLauncher.stopCurrent();
        await remoteHandle.stop();
        await Future.wait(<Future<void>>[
          deleteTemporaryDirectory(home),
          deleteTemporaryDirectory(userHome),
          deleteTemporaryDirectory(remoteHome),
          deleteTemporaryDirectory(workspace),
          deleteTemporaryDirectory(directoryWorkspace),
          deleteTemporaryDirectory(remoteWorkspace),
        ]);
        await modelServer.close(force: true);
      });
      final endpoint = HostEndpoint(
        websocketUri: handle.boundEndpoint,
      );
      var setupClient = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
        ),
        clientId: 'e2e-setup',
        clientKind: 'integration-test',
      );
      addTearDown(() => setupClient.close());
      final remoteClient = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: remoteHandle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'remote-token-0123456789abcdef0123456789',
        ),
        clientId: 'e2e-remote-setup',
        clientKind: 'integration-test',
      );
      addTearDown(remoteClient.close);
      await setupClient.workspaces.registerWorkspace(
        workspaceId: 'workspace-e2e',
        checkoutId: 'checkout-e2e',
        rootPath: workspace.path,
        name: 'E2E Workspace',
      );
      await setupClient.workspaces.registerWorkspace(
        workspaceId: 'directory-workspace-e2e',
        checkoutId: 'directory-checkout-e2e',
        rootPath: directoryWorkspace.path,
        name: 'E2E Directory',
      );
      final remoteWorkspaceName = remoteWorkspace.path
          .split(Platform.pathSeparator)
          .last;
      await remoteClient.workspaces.registerWorkspace(
        workspaceId: 'remote-workspace-e2e',
        checkoutId: 'remote-checkout-e2e',
        rootPath: remoteWorkspace.path,
        name: remoteWorkspaceName,
      );
      final terminal = await setupClient.terminals.createTerminal(
        id: 'terminal-e2e',
        worktreeId: 'checkout-e2e',
        title: 'E2E Terminal',
        columns: 80,
        rows: 24,
      );
      await setupClient.terminals.attachTerminal(
        terminal.id,
        mode: TerminalRestoreMode.snapshot,
      );
      const terminalMarker = 'terminal-e2e-ready';
      final terminalOutput = setupClient.terminals.output
          .where((output) => output.terminalId == terminal.id)
          .map((output) => output.data)
          .firstWhere((data) => data.contains(terminalMarker))
          .timeout(const Duration(seconds: 30));
      await setupClient.terminals.writeTerminal(
        terminal.id,
        "printf '$terminalMarker\\n'\r",
      );
      expect(await terminalOutput, contains(terminalMarker));
      await setupClient.terminals.terminateTerminal(terminal.id);

      final now = DateTime.utc(2026, 8, 3);
      final appStore = MemoryAppStore(
        settings: AppSettings(
          embeddedDaemonPort: handle.boundEndpoint.port,
        ),
        profiles: <RemoteDaemonProfile>[
          RemoteDaemonProfile(
            id: 'remote',
            label: 'Remote daemon',
            connections: directHostConnections(remoteHandle.boundEndpoint),
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
          attachmentInput: _E2eAttachmentInput(
            imageBytes: imageBytes,
            documentBytes: documentBytes,
          ),
        ),
      );
      // Unmount before the daemons stop so no provider request outlives its
      // client; tear-downs registered earlier run after this one.
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      // The sidebar has no daemon level; each daemon names the workspace rows
      // it serves, so a subtitle is the evidence that it connected.
      await pumpUntil(tester, find.text('E2E Workspace'));
      await pumpUntil(tester, find.text(remoteWorkspaceName));
      await pumpUntil(tester, find.textContaining('내장 daemon · '));

      // The View menu must keep following the persisted sidebar state after
      // each selection, rather than reusing the first title-bar snapshot.
      expect(find.text('보기'), findsOneWidget);
      await tester.tap(find.text('보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('사이드바 접기'));
      await tester.pumpAndSettle();
      expect(appStore.settings.sidebarCollapsed, isTrue);

      await tester.tap(find.text('보기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('사이드바 열기'));
      await tester.pumpAndSettle();
      expect(appStore.settings.sidebarCollapsed, isFalse);

      // The global desktop menu reaches the same typed new-workspace route.
      expect(find.text('파일'), findsOneWidget);
      await tester.tap(find.text('파일'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New workspace').last);
      await tester.pumpAndSettle();
      final projectChip = find.byKey(
        const ValueKey('new-workspace-project'),
      );
      // The hover-dismiss contract has focused widget coverage. Repeating a
      // Tooltip OverlayPortal lifecycle in this long-lived desktop test also
      // triggers Flutter 3.44's stale semantics-child bug
      // (flutter/flutter#189902) before the required context-meter hover.
      await tester.tap(projectChip);
      await tester.pumpAndSettle();
      final addProject = find.byKey(
        const ValueKey('new-workspace-project-add'),
      );
      expect(addProject, findsOneWidget);
      await tester.tap(projectChip);
      await tester.pumpAndSettle();
      expect(addProject, findsNothing);

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daemons').last);
      final exposureToggle = find.byKey(
        const ValueKey<String>('embedded-daemon-exposure'),
      );
      await pumpUntil(tester, exposureToggle);
      await tester.tap(exposureToggle);
      await pumpUntilCondition(
        tester,
        () => embeddedLauncher.exposures.length == 2,
        'embedded daemon to restart on all interfaces',
      );
      await pumpUntilCondition(
        tester,
        () => tester.widget<CoderSwitchRow>(exposureToggle).onChanged != null,
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
      await pumpUntilCondition(
        tester,
        () => embeddedLauncher.exposures.length == 3,
        'embedded daemon to return to loopback',
      );
      await pumpUntilCondition(
        tester,
        () => tester.widget<CoderSwitchRow>(exposureToggle).onChanged != null,
        'loopback daemon to reconnect',
      );
      expect(
        embeddedLauncher.exposures.last,
        EmbeddedDaemonExposure.loopback,
      );
      setupClient = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
        ),
        clientId: 'e2e-setup-reconnected',
        clientKind: 'integration-test',
      );
      await tester.tap(find.text('Agent'));
      await pumpUntil(tester, find.text('Agents'));
      await _selectDaemon(tester, 'Remote daemon');
      final addAgent = find.byKey(const ValueKey('agent-add-button'));
      await pumpUntil(tester, addAgent);
      await tester.tap(addAgent);
      await tester.pumpAndSettle();
      await tester.enterText(
        _trTextInput('ID (파일명)'),
        'remote-agent',
      );
      await tester.enterText(
        _trTextInput('이름').last,
        'Remote Agent',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createRemoteAgent = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createRemoteAgent);
      await tester.pumpAndSettle();
      await tester.tap(createRemoteAgent);
      await pumpUntilGone(tester, find.text('Agent 추가'));
      final remoteAgent = await _waitForAgentDefinition(
        remoteClient,
        'remote-agent',
      );
      expect(remoteAgent.sourcePath, startsWith(remoteHome.path));
      await _selectDaemon(tester, '내장 daemon');
      await pumpUntil(tester, addAgent);
      await tester.tap(addAgent);
      await tester.pumpAndSettle();
      await tester.enterText(
        _trTextInput('ID (파일명)'),
        'reviewer',
      );
      await tester.enterText(
        _trTextInput('이름').last,
        'Reviewer',
      );
      await tester.tap(
        find.widgetWithText(TRSelectFormField<AgentMode>, '유형'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('subagent').last);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      final createAgent = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createAgent);
      await tester.pumpAndSettle();
      await tester.tap(createAgent);
      await pumpUntilGone(tester, find.text('Agent 추가'));
      final reviewer = await _waitForAgentDefinition(setupClient, 'reviewer');
      final reviewerFile = File(reviewer.sourcePath);
      expect(reviewerFile.existsSync(), isTrue);

      final promptField = _trTextInput('시스템 프롬프트 (Markdown)');
      await tester.enterText(promptField, 'Review the current change.');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
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
      final validReviewerSource = await reviewerFile.readAsString();
      await expectLater(
        setupClient.agents.validateAgentDefinition(
          'reviewer',
          'this document has no frontmatter',
        ),
        throwsA(isA<CoderClientException>()),
      );
      expect(await reviewerFile.readAsString(), validReviewerSource);

      await pumpUntil(tester, addAgent);
      await tester.tap(addAgent);
      await tester.pumpAndSettle();
      await tester.enterText(
        _trTextInput('ID (파일명)'),
        'temporary',
      );
      await tester.enterText(
        _trTextInput('이름').last,
        'Temporary',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createTemporary = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createTemporary);
      await tester.pumpAndSettle();
      await tester.tap(createTemporary);
      await pumpUntilGone(tester, find.text('Agent 추가'));
      await _waitForAgentDefinition(setupClient, 'temporary');
      await tester.tap(find.byKey(const ValueKey('agent-archive-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-archive-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        (await setupClient.agents.listAgentDefinitions()).map(
          (item) => item.id,
        ),
        isNot(contains('temporary')),
      );

      await tester.tap(find.text('Coder').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agent-reset-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('agent-reset-confirm')),
      );
      await tester.pumpAndSettle();
      final editorList = find.byType(ListView).last;
      final editorScrollable = find
          .descendant(of: editorList, matching: find.byType(Scrollable))
          .first;
      // Two steps, and both are needed. scrollUntilVisible builds the section
      // the row lives in, but stops as soon as the row exists rather than when
      // it is on screen; ensureVisible then brings it fully into view. The row
      // is addressed by key because a section builds as a unit, so a text match
      // can resolve to an occurrence far below the fold. The group header is
      // the waypoint rather than the tool: a group starts closed, so its tools
      // are not in the tree until someone opens it.
      final collaborationGroup = find.byKey(
        const ValueKey<String>('agent-tool-group-collaboration'),
      );
      await tester.scrollUntilVisible(
        collaborationGroup,
        400,
        scrollable: editorScrollable,
      );
      await tester.ensureVisible(collaborationGroup);
      await tester.pumpAndSettle();
      // Opening it proves the group really does carry the tool the reset
      // default turned on, which the assertion below reads back off disk.
      await tester.tap(collaborationGroup);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CoderCheckboxRow>(
              find.byKey(
                const ValueKey<String>('agent-tool-tile-collaboration'),
              ),
            )
            .value,
        isTrue,
      );

      await tester.scrollUntilVisible(
        find.text('호출 가능한 Subagent'),
        400,
        scrollable: editorScrollable,
      );
      final reviewerSubagent = find.text('Reviewer').last;
      await tester.ensureVisible(reviewerSubagent);
      await tester.pumpAndSettle();
      await tester.tap(reviewerSubagent);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      final collaboratingCoder = await setupClient.agents.getAgentDefinition(
        'coder',
      );
      expect(collaboratingCoder.callableAgentIds, <String>['reviewer']);
      expect(collaboratingCoder.toolIds, contains('collaboration'));

      await tester.tap(find.text('Agent'));
      await pumpUntil(tester, find.text('Agents'));
      await tester.tap(find.text('스킬'));
      final skillAddButton = find.byKey(
        const ValueKey<String>('skill-add-button'),
      );
      await pumpUntil(tester, skillAddButton);
      await tester.tap(skillAddButton);
      await tester.pumpAndSettle();
      await tester.enterText(
        _trTextInput('ID (디렉터리 이름)'),
        'e2e-skill',
      );
      await tester.enterText(
        _trTextInput('이름').last,
        'e2e-skill',
      );
      await tester.enterText(
        _trTextInput('설명').last,
        'Explains the end-to-end flow.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final createSkill = find.widgetWithText(TRButton, '생성');
      await tester.ensureVisible(createSkill);
      await tester.pumpAndSettle();
      await tester.tap(createSkill);
      await pumpUntilGone(tester, find.text('스킬 추가'));
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.prompts.listSkills()).any(
          (skill) => skill.id == 'e2e-skill',
        ),
        'the new skill to reach the daemon',
      );
      expect(
        (await setupClient.prompts.getSkill('e2e-skill')).sourcePath,
        startsWith(home.path),
      );

      // A toggleable built-in can be turned off, and the daemon remembers it.
      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      final commitSwitch = find.byKey(
        const ValueKey<String>('skill-enabled-commit'),
      );
      await tester.ensureVisible(commitSwitch);
      await tester.pumpAndSettle();
      await tester.tap(commitSwitch);
      await pumpUntilCondition(
        tester,
        () async => !(await setupClient.prompts.getSkill('commit')).isEnabled,
        'the built-in skill to turn off',
      );

      await tester.tap(find.text('e2e-skill').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('skill-delete-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제'));
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.prompts.listSkills()).every(
          (skill) => skill.id != 'e2e-skill',
        ),
        'the skill to be archived',
      );
      final invokedSkill = await setupClient.prompts.createSkill(
        id: 'invoke-e2e',
        source: SkillSource.config,
        name: 'invoke-e2e',
        description: 'Loaded during an end-to-end turn.',
        body: 'Use the deterministic E2E instructions.',
      );
      final invokedSkillFile = File(invokedSkill.sourcePath);
      final validSkillSource = await invokedSkillFile.readAsString();
      await expectLater(
        setupClient.prompts.updateSkill(
          invokedSkill.copyWith(body: 'must not overwrite'),
          expectedContentHash: 'stale-content-hash',
        ),
        throwsA(isA<CoderClientException>()),
      );
      expect(await invokedSkillFile.readAsString(), validSkillSource);

      await tester.tap(find.text('Agent'));
      await pumpUntil(tester, find.text('Agents'));
      await tester.pumpAndSettle();
      // MCP: expose a real child-process failure, repair its command and
      // secret through the UI, test discovery, then remove it again.
      // Scoped to the sidebar: the agent editor behind it also has a row
      // labelled MCP, the group its resource tools are toggled in.
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey<String>('settings-sidebar-surface')),
          matching: find.text('MCP'),
        ),
      );
      await pumpUntil(tester, find.text('MCP 서버'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TRSelect<String>>(
              find
                  .byKey(
                    const ValueKey<String>('settings-daemon-select'),
                  )
                  .last,
            )
            .value,
        embeddedHostId,
      );
      await tester.tap(find.byKey(const ValueKey('mcp-server-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('mcp-field-id')),
        'e2e',
      );
      await tester.enterText(
        find.byKey(const ValueKey('mcp-field-command')),
        '/nonexistent/mcp-server',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      final saveServer = find.byKey(const ValueKey('mcp-server-save'));
      await tester.ensureVisible(saveServer);
      await tester.pumpAndSettle();
      final testServer = find.byKey(
        const ValueKey<String>('mcp-server-test'),
      );
      await tester.ensureVisible(testServer);
      await tester.tap(testServer);
      await pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('mcp-editor-error')),
      );
      await pumpUntilCondition(
        tester,
        () => tester.widget<TRButton>(testServer).onPressed != null,
        'the failed MCP probe to release the editor',
      );
      await _replaceMcpFieldText(
        tester,
        'mcp-field-command',
        _dartExecutable(),
      );
      await _replaceMcpFieldText(
        tester,
        'mcp-field-args',
        _fakeMcpServerPath(),
      );
      await _replaceMcpFieldText(
        tester,
        'mcp-field-env',
        r'MCP_ECHO_PREFIX=${secret:e2e.prefix}',
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('mcp-field-command')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        _dartExecutable(),
      );
      final setSecret = find.byKey(const ValueKey<String>('mcp-secret-set'));
      await tester.ensureVisible(setSecret);
      await pumpUntil(tester, setSecret.hitTestable());
      await tester.tap(setSecret.hitTestable());
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey<String>('mcp-secret-key')),
        'e2e.prefix',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('mcp-secret-value')),
        'secret-',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('mcp-secret-save')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(testServer);
      await tester.tap(testServer);
      await tester.pump();
      final mcpTestNotice = find.byKey(
        const ValueKey<String>('mcp-editor-notice'),
      );
      final mcpTestError = find.byKey(
        const ValueKey<String>('mcp-editor-error'),
      );
      expect(mcpTestError, findsNothing);
      await pumpUntilCondition(
        tester,
        () =>
            mcpTestNotice.evaluate().isNotEmpty ||
            mcpTestError.evaluate().isNotEmpty,
        'the repaired unsaved MCP test to finish',
      );
      if (mcpTestError.evaluate().isNotEmpty) {
        throw TestFailure(
          'Repaired unsaved MCP test failed: '
          '${tester.widget<Text>(mcpTestError).data}',
        );
      }
      await tester.ensureVisible(saveServer);
      await tester.tap(saveServer);
      await pumpUntilCondition(
        tester,
        () async {
          final servers = await setupClient.mcp.listMcpServers();
          if (servers.isEmpty) return false;
          final server = servers.single;
          if (server.status == McpServerStatus.failed &&
              server.config.command == _dartExecutable()) {
            throw TestFailure(
              'Repaired MCP server failed: ${server.error}; '
              'args=${server.config.args}; env=${server.config.env}',
            );
          }
          return server.status == McpServerStatus.ready;
        },
        'the repaired MCP server to become ready',
      );
      await tester.pumpAndSettle();
      expect(
        (await setupClient.mcp.listMcpServers()).single.tools.single.toolId,
        'mcp__e2e__echo',
      );
      final deleteServer = find.byKey(const ValueKey('mcp-server-delete'));
      await tester.ensureVisible(deleteServer);
      await tester.pumpAndSettle();
      // The save reported itself over the bottom-trailing corner, which is
      // where this button sits. Waiting the report out is what a user does
      // before reaching underneath it, and it doubles as proof that a toast
      // gives the surface back on its own.
      await pumpUntilGone(tester, find.text('저장했습니다.'));
      await tester.tap(deleteServer);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mcp-delete-confirm')));
      await pumpUntilGone(
        tester,
        find.byKey(const ValueKey('mcp-server-tile-e2e')),
      );
      expect(await setupClient.mcp.listMcpServers(), isEmpty);

      // Reinstall the proven local server for the turn-execution scenarios.
      await setupClient.mcp.addMcpServer(
        McpServerConfigDto(
          id: 'e2e',
          transport: McpTransportKind.stdio,
          command: _dartExecutable(),
          args: <String>[_fakeMcpServerPath()],
          env: const <String, String>{
            'MCP_ECHO_PREFIX': r'${secret:e2e.prefix}',
          },
        ),
      );
      await pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.mcp.listMcpServers()).single.status ==
            McpServerStatus.ready,
        'the MCP turn server to reconnect',
      );
      final coderDefinition = await setupClient.agents.getAgentDefinition(
        'coder',
      );
      // The remaining turn fixtures invoke individual tools directly, so they
      // need the MCP echo capability on top of the shipped set. The Lua
      // surface stays out of them because these models declare the direct
      // tool surface, not because of anything listed here.
      await setupClient.agents.updateAgentDefinition(
        coderDefinition.copyWith(
          toolIds: <String>[...coderDefinition.toolIds, 'mcp__e2e__echo'],
        ),
        expectedContentHash: coderDefinition.contentHash,
      );

      await tester.tap(find.byIcon(CoderIcons.back).first);
      await pumpUntil(tester, find.text('E2E Workspace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E2E Workspace').last);
      await tester.pumpAndSettle();
      // Worktrees are created by the new-workspace composer, not the tree.
      expect(find.byTooltip('새 worktree'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('workspace-new-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('E2E Workspace ·').last);
      await tester.pumpAndSettle();
      final worktreeModelSelector = find.byKey(
        const ValueKey('session-composer-model'),
      );
      await tester.ensureVisible(worktreeModelSelector);
      await tester.pumpAndSettle();
      await tester.tap(worktreeModelSelector);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('model-search-field')),
        'gpt-5.2',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.2')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Feature e2e',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.workspaces.getWorkspaceCatalog()).worktrees.any(
              (worktree) => worktree.branch == 'feature-e2e',
            ),
        'the composer to create a worktree',
      );
      // The session route keeps the sidebar, so the new worktree is listed.
      await pumpUntil(tester, find.text('feature-e2e'));
      await tester.pumpAndSettle();
      final managedWorktree =
          (await setupClient.workspaces.getWorkspaceCatalog()).worktrees
              .singleWhere((worktree) => worktree.branch == 'feature-e2e');
      final managedMenu = find.byKey(
        ValueKey<String>('worktree-menu-${managedWorktree.id}'),
      );
      // Three workspace groups are present, so no group auto-expands while
      // the new-workspace route is still handing off to the session route.
      if (managedMenu.evaluate().isEmpty) {
        await tester.tap(find.text('E2E Workspace').last);
        await tester.pumpAndSettle();
      }
      await pumpUntil(tester, managedMenu);
      await tester.ensureVisible(managedMenu);
      await tester.pumpAndSettle();
      await tester.tap(managedMenu);
      await tester.pumpAndSettle();
      // The catalog is still streaming the new checkout in, so the sidebar can
      // rebuild under the menu and the panel needs another frame to settle.
      await pumpUntil(tester, find.text('Archive'));
      await tester.tap(find.text('Archive'));
      final archiveConfirm = find.byKey(
        const ValueKey<String>('worktree-archive-confirm'),
      );
      await pumpUntil(tester, archiveConfirm);
      await tester.tap(archiveConfirm);
      await pumpUntil(tester, find.text('E2E Workspace'));
      await tester.pumpAndSettle();
      if (find.text('main').evaluate().isEmpty) {
        await tester.tap(find.text('E2E Workspace').last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('main'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('main'));
      const composer = ValueKey<String>('session-composer-input');
      const send = ValueKey<String>('session-composer-send');
      await pumpUntil(tester, find.byKey(composer));
      await tester.pumpAndSettle();
      final sessionModelSelector = find.byKey(
        const ValueKey('session-composer-model'),
      );
      expect(sessionModelSelector, findsOne);
      await tester.ensureVisible(sessionModelSelector);
      await tester.pumpAndSettle();
      await tester.tap(sessionModelSelector);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('model-search-field')),
        'gpt-5.2',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.2')),
      );
      await tester.pumpAndSettle();

      // An @ token completes into a worktree-relative path rather than
      // sending, and the completed prompt is what reaches the daemon.
      await _typeComposerPrompt(tester, composer, 'read @READ');
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.text('README.md'));
      // Picked with the pointer rather than Enter: the catalog is still
      // streaming here, and a rebuild that takes focus sends the keystroke
      // nowhere. This step is about the daemon's search reaching the composer,
      // and `composer_input_test.dart` owns the keyboard contract.
      // The row names the file and its worktree-relative path, which are the
      // same string at the repository root, so both land in the same row.
      await tester.tap(find.text('README.md').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TRTextField>(find.byKey(composer)).controller?.text,
        'read @README.md ',
      );

      // A query that matches nothing says so. Dismiss it from the stable tab
      // strip; composer_input_test.dart owns the keyboard dismissal contract.
      await _typeComposerPrompt(tester, composer, 'read @zzzzzz');
      await tester.pumpAndSettle();
      // The E2E app is pinned to Korean, so the empty row reads in Korean.
      await pumpUntil(tester, find.text('파일 없음'));
      await tester.tap(
        find.byKey(const ValueKey<String>('session-tab-strip')).hitTestable(),
      );
      await pumpUntilGone(tester, find.text('파일 없음'));

      await _submitComposerPrompt(tester, composer, send, 'Delegate review');
      // The parent turn completes without waiting for the spawned child.
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('Parent completed.', findRichText: true),
        setupClient,
      );
      final contextMeter = find.byKey(
        const ValueKey<String>('session-composer-context-meter'),
      );
      await pumpUntil(tester, contextMeter);
      final contextMouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await contextMouse.addPointer(location: Offset.zero);
      await contextMouse.moveTo(tester.getCenter(contextMeter));
      await pumpUntil(tester, find.text('컨텍스트 사용량'));
      await contextMouse.moveTo(Offset.zero);
      await pumpUntilGone(tester, find.text('컨텍스트 사용량'));
      // Do not leave a live hover pointer at the origin while this long-lived
      // test replaces routes. A later control can move underneath it and
      // create the second OverlayPortal show/hide cycle that triggers
      // flutter/flutter#189902 on Flutter 3.44.
      await contextMouse.removePointer();
      // The child works asynchronously; wait for its FINAL_ANSWER so the
      // track rows below render settled icons instead of live spinners.
      late SessionDto spawnedChild;
      await pumpUntilCondition(
        tester,
        () async {
          final sessions = await setupClient.sessions.listSessions(
            worktreeId: 'checkout-e2e',
          );
          final child = sessions
              .where(
                (session) =>
                    session.origin == SessionOrigin.delegated &&
                    session.lifecycle == AgentLifecycle.completed,
              )
              .firstOrNull;
          if (child == null) return false;
          spawnedChild = child;
          return true;
        },
        'the spawned subagent to complete',
        budget: e2eTurnBudget,
      );
      expect(spawnedChild.taskName, 'review_task');
      expect(spawnedChild.agentPath, '/root/review_task');
      expect(
        (await setupClient.sessions.listSubagents(spawnedChild.id)).map(
          (session) => session.id,
        ),
        contains(spawnedChild.id),
      );

      // The collapsed track summarizes; expanding it reveals the child row,
      // and opening the row shows a live read-only transcript.
      final trackHeader = find.text('서브 에이전트 1개');
      await pumpUntil(tester, trackHeader);
      await tester.tap(trackHeader);
      final childRow = find.byKey(
        ValueKey<String>('subagent-row-${spawnedChild.id}'),
      );
      await pumpUntil(tester, childRow);
      await tester.tap(childRow);
      await pumpUntil(tester, find.textContaining('읽기 전용'));
      await pumpUntil(
        tester,
        find.text('Review completed.', findRichText: true),
      );
      expect(find.byKey(composer), findsNothing);
      // Subagents never surface in the all-sessions menu.
      await tester.tap(
        find
            .byKey(const ValueKey<String>('workspace-all-sessions-menu'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TRMenuItem, 'review_task'), findsNothing);
      await tester.tap(find.text('Delegate review').last);
      await pumpUntil(tester, find.text('coder · manual'));
      await pumpUntil(tester, find.byKey(composer));

      final goalSessionId = (await setupClient.sessions.listSessions(
        worktreeId: 'checkout-e2e',
      )).singleWhere((session) => session.origin == SessionOrigin.manual).id;
      await _waitForComposerReady(tester, send);
      await _typeComposerPrompt(tester, composer, '/goal');
      // The catalog merges agent commands and skills that the daemon sends over
      // the wire, so the row arrives a round trip after the keystroke and
      // `pumpAndSettle` returns long before it. Enter pressed into a closed
      // overlay sends `/goal` as an ordinary prompt and the editor never opens.
      await pumpUntil(tester, find.text('goal'));
      // First Enter accepts the highlighted command completion; the second
      // dispatches `/goal` and opens the editor. The overlay closing is the
      // evidence that the first one landed as an acceptance.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpUntilGone(tester, find.text('goal'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpUntil(tester, find.text('세션 Goal'));
      final goalDialog = find.byType(TRAlertDialog);
      final goalObjective = find
          .descendant(of: goalDialog, matching: find.byType(EditableText))
          .first;
      await tester.enterText(goalObjective, 'Complete persistent goal e2e');
      await tester.tap(find.text('Goal 시작'));
      await tester.pump();
      late GoalDto completedGoal;
      var observedGoalState = 'no goal state observed';
      try {
        await pumpUntilCondition(
          tester,
          () async {
            final session = (await setupClient.sessions.listSessions())
                .singleWhere((session) => session.id == goalSessionId);
            final goal = await setupClient.sessions.getGoal(goalSessionId);
            observedGoalState =
                '${session.status.name}:${session.mode.name}:'
                '${goal?.status.name}:${goal?.objective}';
            if (goal?.objective == 'Complete persistent goal e2e' &&
                goal?.status == GoalStatus.complete) {
              completedGoal = goal!;
              return true;
            }
            return false;
          },
          'the persistent goal to complete after continuation turns',
          budget: e2eTurnBudget,
        );
      } on TestFailure catch (error) {
        throw TestFailure(
          '$error Provider goal rounds: ${agentProvider._goalRounds}. '
          'Observed: $observedGoalState',
        );
      }
      await pumpUntil(tester, find.text('완료'));
      final reconnectClient = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(bearerToken: handle.bearerToken),
        clientId: 'goal-reconnect',
        clientKind: 'integration-test',
      );
      expect(
        await reconnectClient.sessions.getGoal(completedGoal.sessionId),
        completedGoal,
      );
      await reconnectClient.close();

      // An app-owned command runs in the app: the draft clears and no turn
      // starts for it. This needs the live session, which is where the app
      // wires a handler; a draft composer has none and submits the text.
      final composerInput = find.descendant(
        of: find.byKey(composer),
        matching: find.byType(EditableText),
      );
      // Enter is ignored until a model resolves, so typing before that leaves
      // the draft sitting in the field.
      await _waitForComposerReady(tester, send);
      await tester.tap(composerInput);
      await pumpUntilCondition(
        tester,
        () => tester.widget<EditableText>(composerInput).focusNode.hasFocus,
        'the composer to take focus',
      );
      final sessionsBefore = (await setupClient.sessions.listSessions(
        worktreeId: 'checkout-e2e',
      )).length;
      tester.testTextInput.enterText('/clear');
      await pumpUntil(tester, find.text('clear'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TRTextField>(find.byKey(composer)).controller?.text,
        isEmpty,
      );
      expect(
        (await setupClient.sessions.listSessions(
          worktreeId: 'checkout-e2e',
        )).length,
        sessionsBefore,
      );

      // A project command on disk expands its template into the prompt the
      // daemon records for the turn.
      await _submitComposerPrompt(
        tester,
        composer,
        send,
        '/e2e-review lib/app.dart',
      );
      await pumpUntilCondition(
        tester,
        () async {
          for (final session in await setupClient.sessions.listSessions(
            worktreeId: 'checkout-e2e',
          )) {
            final timeline = await setupClient.sessions.subscribeTimeline(
              session.id,
            );
            final expanded = timeline
                .where((event) => event.type == 'user.message')
                .any(
                  (event) =>
                      '${event.data['text']}' ==
                      'Review lib/app.dart for the E2E fixture.',
                );
            if (expanded) return true;
          }
          return false;
        },
        'the expanded agent command prompt to reach the daemon',
      );
      await _waitForComposerReady(tester, send);
      // Sending moved focus to the send button; the flow below types straight
      // into the field, so hand it back.
      await tester.tap(composerInput);
      await pumpUntilCondition(
        tester,
        () => tester.widget<EditableText>(composerInput).focusNode.hasFocus,
        'the composer to take focus',
      );

      await tester.enterText(
        find.byKey(composer),
        'Disallowed delegation',
      );
      await tester.pump();
      expect(
        tester.widget<TRTextField>(find.byKey(composer)).controller?.text,
        'Disallowed delegation',
      );
      expect(
        tester.widget<TRIconButton>(find.byKey(send)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(send));
      await tester.pump();
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text(
          '실패',
          findRichText: true,
        ),
        setupClient,
      );
      final failedToolCard = find.byWidgetPredicate(
        (widget) =>
            widget is ChatToolCard &&
            widget.activity.callId == 'disallowed-delegate-call',
      );
      expect(failedToolCard, findsOneWidget);
      // Expansion and the structured error body are owned by the focused
      // chat-view widget test. This real-daemon slice pins the failed card and
      // the exact tool event below without depending on virtual-list details.
      await pumpUntilCondition(
        tester,
        () => tester.widget<TRIconButton>(find.byKey(send)).onPressed != null,
        'the failed delegation turn to release the composer',
      );

      await _submitComposerPrompt(tester, composer, send, 'Create result.txt');
      final patchApproval = _approvalForCall('patch-call');
      await pumpUntil(tester, patchApproval);
      await tester.tap(
        find.descendant(
          of: patchApproval,
          matching: find.widgetWithText(TRButton, '승인'),
        ),
      );
      await pumpUntil(
        tester,
        find.text('Created result.txt', findRichText: true),
      );
      // That reply is the scripted provider's catch-all, so an earlier turn
      // already put it in this transcript and the finder above matches on the
      // first poll. Only a settled session proves this turn's tool ran, and
      // the file it wrote is what the next line reads.
      await pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.sessions.listSessions(
                  worktreeId: 'checkout-e2e',
                ))
                .singleWhere(
                  (session) => session.origin == SessionOrigin.manual,
                )
                .status ==
            SessionStatus.idle,
        'the patch turn to finish',
      );
      expect(
        await File('${workspace.path}/result.txt').readAsString(),
        'done\n',
      );
      // Collapsed tool activity renders only its localized action and status;
      // no request or result payload reaches the UI until it is expanded.
      expect(find.text('파일 편집', findRichText: true), findsWidgets);
      expect(find.textContaining('Edit('), findsNothing);
      expect(find.textContaining('changedFiles'), findsNothing);
      expect(find.textContaining('"isError"'), findsNothing);
      expect(tester.takeException(), isNull);

      // Attachments use the authenticated HTTP transport even though the turn
      // and timeline continue to use the WebSocket API.
      await File('${workspace.path}/agent-output.txt').writeAsString(
        'agent attachment\n',
      );
      final attachmentSession = (await setupClient.sessions.listSessions(
        worktreeId: 'checkout-e2e',
      )).singleWhere((session) => session.origin == SessionOrigin.manual);
      final attachButton = find
          .byKey(const ValueKey('session-composer-attach'))
          .hitTestable();
      expect(tester.widget<TRIconButton>(attachButton).onPressed, isNotNull);
      await tester.tap(attachButton);
      await tester.pump();
      expect(find.textContaining('fixture.png'), findsNothing);
      expect(tester.widget<TRIconButton>(attachButton).onPressed, isNotNull);
      await tester.tap(attachButton);
      await pumpUntil(tester, find.textContaining('fixture.png'));
      expect(find.textContaining('fixture.txt'), findsOneWidget);
      await tester.tap(find.byKey(send));
      await pumpUntilCondition(
        tester,
        attachmentCapture.exists,
        'the provider to receive hydrated attachments',
      );
      final providerAttachments =
          (jsonDecode(
                    await attachmentCapture.readAsString(),
                  )
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(
        providerAttachments.map((attachment) => attachment['fileName']),
        orderedEquals(<String>['fixture.png', 'fixture.txt']),
      );
      expect(
        base64Decode(providerAttachments[0]['bytes']! as String),
        orderedEquals(imageBytes),
      );
      expect(
        base64Decode(providerAttachments[1]['bytes']! as String),
        orderedEquals(documentBytes),
      );
      final attachmentTimeline = await setupClient.sessions.subscribeTimeline(
        attachmentSession.id,
      );
      final uploadedSnapshots =
          attachmentTimeline
                  .lastWhere(
                    (event) =>
                        event.type == 'user.message' &&
                        (event.data['attachments'] as List? ??
                                const <dynamic>[])
                            .isNotEmpty,
                  )
                  .data['attachments']!
              as List<dynamic>;
      final imageAttachmentId =
          (uploadedSnapshots.first! as Map<String, dynamic>)['id']! as String;
      await pumpUntil(
        tester,
        find.byKey(ValueKey('chat-attachment-$imageAttachmentId')),
      );
      await tester.tap(
        find.byKey(ValueKey('chat-attachment-$imageAttachmentId')),
      );
      await pumpUntil(tester, find.byType(InteractiveViewer));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      Navigator.of(tester.element(find.byType(InteractiveViewer))).pop();
      await pumpUntilGone(tester, find.byType(InteractiveViewer));
      await pumpUntil(
        tester,
        find.text('Attached fixtures.', findRichText: true),
      );

      await _submitComposerPrompt(
        tester,
        composer,
        send,
        'Publish outbound attachment',
      );
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.sessions.subscribeTimeline(
          attachmentSession.id,
        )).any((event) => event.type == 'assistant.attachment'),
        'the agent to publish its outbound attachment',
      );
      await pumpUntil(
        tester,
        find.textContaining('agent-output.txt'),
      );
      final outboundTimeline = await setupClient.sessions.subscribeTimeline(
        attachmentSession.id,
      );
      final outboundEvent = outboundTimeline.singleWhere(
        (event) => event.type == 'assistant.attachment',
      );
      final outboundId = outboundEvent.data['id']! as String;
      final outboundDownload = await setupClient.attachments.downloadAttachment(
        outboundId,
      );
      expect(
        await outboundDownload.bytes.expand((chunk) => chunk).toList(),
        utf8.encode('agent attachment\n'),
      );
      await pumpUntil(
        tester,
        find.text('Published outbound attachment.', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Reject result.txt');
      final rejectedPatchApproval = _approvalForCall('reject-patch-call');
      await pumpUntil(tester, rejectedPatchApproval);
      await tester.tap(
        find.descendant(
          of: rejectedPatchApproval,
          matching: find.widgetWithText(TRButton, '거부'),
        ),
      );
      await pumpUntil(
        tester,
        find.text('Rejected safely', findRichText: true),
      );
      expect(File('${workspace.path}/rejected.txt').existsSync(), isFalse);

      final liveMcpServer = (await setupClient.mcp.listMcpServers()).single;
      expect(liveMcpServer.status, McpServerStatus.ready);
      expect(
        liveMcpServer.tools.map((tool) => tool.toolId),
        contains('mcp__e2e__echo'),
      );
      expect(
        (await setupClient.agents.listAgentTools()).map((tool) => tool.id),
        contains('mcp__e2e__echo'),
      );
      await _submitComposerPrompt(tester, composer, send, 'MCP echo');
      final mcpApproval = _approvalForCall('mcp-call');
      await _pumpUntilWithSessionDiagnostics(
        tester,
        mcpApproval,
        setupClient,
      );
      await tester.tap(
        find.descendant(
          of: mcpApproval,
          matching: find.widgetWithText(TRButton, '승인'),
        ),
      );
      await pumpUntil(
        tester,
        find.text('MCP completed', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Reject MCP');
      final rejectedMcpApproval = _approvalForCall('reject-mcp-call');
      await _pumpUntilWithSessionDiagnostics(
        tester,
        rejectedMcpApproval,
        setupClient,
      );
      await tester.tap(
        find.descendant(
          of: rejectedMcpApproval,
          matching: find.widgetWithText(TRButton, '거부'),
        ),
      );
      await pumpUntil(tester, find.text('MCP rejected', findRichText: true));

      await setupClient.mcp.removeMcpServer('e2e');
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.agents.listAgentTools()).every(
          (tool) => tool.id != 'mcp__e2e__echo',
        ),
        'the offline MCP tool to leave the agent catalog',
      );
      await _submitComposerPrompt(tester, composer, send, 'Offline MCP');
      await pumpUntil(
        tester,
        find.text('MCP unavailable safely', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Use E2E skill');
      await pumpUntil(
        tester,
        find.text('Skill loaded', findRichText: true),
      );
      await setupClient.prompts.setSkillEnabled('invoke-e2e', enabled: false);
      await _submitComposerPrompt(tester, composer, send, 'Disabled E2E skill');
      await pumpUntil(
        tester,
        find.text('Disabled skill excluded', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Cancel streaming');
      await pumpUntil(
        tester,
        find.text('Streaming before cancel', findRichText: true),
      );
      final stop = find.byWidgetPredicate(
        (widget) => widget is TRIconButton && widget.label == '중지',
        description: 'stop active turn button',
      );
      await tester.tap(stop);
      await pumpUntil(tester, find.text('중지됨'));

      await _submitComposerPrompt(tester, composer, send, 'Recover provider');
      await pumpUntil(tester, find.textContaining('planned provider outage'));
      await _submitComposerPrompt(tester, composer, send, 'Recover provider');
      await pumpUntil(
        tester,
        find.text('Provider recovered', findRichText: true),
      );

      final turnBranches = await setupClient.sessions.subscribeTimeline(
        (await setupClient.sessions.listSessions(
          worktreeId: 'checkout-e2e',
        )).singleWhere((session) => session.origin == SessionOrigin.manual).id,
      );
      expect(
        turnBranches.map((event) => event.type),
        containsAll(<String>[
          'turn.cancelled',
          'turn.failed',
          'approval.resolved',
          'tool.denied',
        ]),
      );
      expect(
        turnBranches
            .where((event) => event.type == 'turn.failed')
            .map((event) => event.data['error']),
        contains(contains('planned provider outage')),
      );
      // A rejected spawn surfaces as an error tool result, not a failed turn.
      expect(
        turnBranches
            .where(
              (event) =>
                  event.type == 'tool.completed' &&
                  event.data['isError'] == true,
            )
            .map((event) => event.data['output']),
        contains(contains('Agent type is not allowed: not-allowed')),
      );
      expect(
        turnBranches
            .where((event) => event.type == 'approval.resolved')
            .map((event) => event.data['status']),
        contains('denied'),
      );
      expect(
        turnBranches
            .where(
              (event) =>
                  event.type == 'tool.completed' &&
                  event.data['name'] == 'mcp__e2e__echo',
            )
            .map((event) => event.data['output']),
        contains('secret-through MCP'),
      );
      expect(
        turnBranches
            .where(
              (event) =>
                  event.type == 'tool.completed' &&
                  event.data['name'] == 'skill',
            )
            .map((event) => event.data['output'])
            .join('\n'),
        contains('Use the deterministic E2E instructions.'),
      );

      // Plan mode proposes work and hands it back for approval.
      await tester.tap(
        find.byKey(const ValueKey('session-composer-mode')).hitTestable(),
      );
      await pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.sessions.listSessions(
                  worktreeId: 'checkout-e2e',
                ))
                .singleWhere((session) => session.id == attachmentSession.id)
                .mode ==
            SessionMode.plan,
        'the attachment session to enter plan mode',
      );
      await tester.pumpAndSettle();
      await _submitComposerPrompt(tester, composer, send, 'Plan the change');
      await pumpUntil(
        tester,
        find.text('Plan ready: Create result.txt', findRichText: true),
      );
      // update_plan records execution progress and is unavailable in Plan
      // Mode. The user explicitly returns to Default mode after reading the
      // prose proposal.
      await tester.tap(
        find.byKey(const ValueKey('session-composer-mode')).hitTestable(),
      );
      await tester.pump();
      // The chip returning to 실행 proves the session left plan mode.
      await pumpUntil(tester, find.text('실행'));
      // The chip only reflects what the app asked for, so confirm the daemon
      // agrees before sending a prompt that must not be planned again.
      await pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.sessions.listSessions(
                  worktreeId: 'checkout-e2e',
                ))
                .singleWhere((session) => session.id == attachmentSession.id)
                .mode ==
            SessionMode.normal,
        'the attachment session to leave plan mode',
      );

      // A blocking agent question stops the turn until the user answers it,
      // and the chosen answer reaches the model.
      await _submitComposerPrompt(
        tester,
        composer,
        send,
        'Ask me about storage',
      );
      // The prompt has to leave the composer. Failing here separates "never
      // left the client" from "the daemon never answered", which the 120s
      // wait below cannot tell apart.
      await pumpUntilCondition(
        tester,
        () =>
            find.text('Ask me about storage').evaluate().isNotEmpty ||
            tester
                .widgetList<SessionComposer>(find.byType(SessionComposer))
                .any((item) => item.queued.isNotEmpty),
        'the storage prompt to leave the composer',
      );
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('Storage'),
        setupClient,
      );
      expect(find.text('Which store should the cache use?'), findsOneWidget);
      final questionSubmit = find.byKey(
        const ValueKey<String>('chat-question-submit'),
      );
      // The turn stays blocked: nothing was chosen yet.
      expect(tester.widget<TRButton>(questionSubmit).onPressed, isNull);
      await tester.tap(find.text('SQLite'));
      await pumpUntil(tester, find.text('Which theme should the editor use?'));
      expect(find.text('Which store should the cache use?'), findsNothing);

      await tester.tap(find.text('직접 입력'));
      final themeAnswer = find.byKey(
        const ValueKey<String>('chat-question-other-theme'),
      );
      await pumpUntil(tester, themeAnswer);
      await tester.enterText(themeAnswer, 'High contrast');
      await pumpUntilCondition(
        tester,
        () => tester.widget<TRButton>(questionSubmit).onPressed != null,
        'the next button to accept the typed answer',
      );
      expect(find.widgetWithText(TRButton, '다음'), findsOneWidget);
      await tester.ensureVisible(questionSubmit);
      await tester.pump();
      await tester.tap(questionSubmit);
      await pumpUntil(tester, find.text('How should changes be reviewed?'));

      expect(find.widgetWithText(TRButton, '답변'), findsOneWidget);
      expect(tester.widget<TRButton>(questionSubmit).onPressed, isNull);
      await tester.tap(find.text('Pull request'));
      await pumpUntilCondition(
        tester,
        () => tester.widget<TRButton>(questionSubmit).onPressed != null,
        'the answer button to accept all three answers',
      );
      await tester.ensureVisible(questionSubmit);
      await tester.pump();
      await tester.tap(questionSubmit);
      await pumpUntil(
        tester,
        find.textContaining('Chose SQLite, High contrast, and Pull request'),
      );
      await pumpUntilGone(tester, questionSubmit);

      final reconnected = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
        ),
        clientId: 'e2e-reconnect',
        clientKind: 'integration-test',
      );
      final agents = await reconnected.sessions.listSessions(
        worktreeId: 'checkout-e2e',
      );
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
      final timeline = await reconnected.sessions.subscribeTimeline(parent.id);
      expect(timeline.map((event) => event.type), contains('turn.completed'));
      final restoredAttachmentTimeline = await reconnected.sessions
          .subscribeTimeline(
            parent.id,
          );
      expect(
        restoredAttachmentTimeline.map((event) => event.type),
        contains('assistant.attachment'),
      );
      final restoredUserAttachment = restoredAttachmentTimeline.singleWhere(
        (event) =>
            event.type == 'user.message' &&
            (event.data['attachments'] as List? ?? const <dynamic>[])
                .isNotEmpty,
      );
      expect(
        (restoredUserAttachment.data['attachments']! as List<dynamic>).map(
          (item) => (item! as Map<String, dynamic>)['fileName'],
        ),
        orderedEquals(<String>['fixture.png', 'fixture.txt']),
      );
      expect(
        timeline.map((event) => event.sequence),
        orderedEquals(
          List<int>.generate(timeline.length, (index) => index + 1),
        ),
      );
      await reconnected.close();

      // Session tabs are device-local: closing one must preserve daemon
      // history, and the all-sessions picker must restore it.
      await tester.tap(
        find.byKey(ValueKey<String>('tr-tabs-close-${parent.id}')),
      );
      await pumpUntilGone(
        tester,
        find.byKey(ValueKey<String>('tr-tabs-close-${parent.id}')),
      );
      expect(
        (await setupClient.sessions.listSessions(
          worktreeId: 'checkout-e2e',
        )).map((session) => session.id),
        contains(parent.id),
      );
      // Closing the last tab returns to the checkout, and the tab strip shows
      // a spinner in place of its menus until the tab state loads again.
      final allSessionsMenu = find.byKey(
        const ValueKey<String>('workspace-all-sessions-menu'),
      );
      await pumpUntil(tester, allSessionsMenu);
      await tester.tap(allSessionsMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delegate review').last);
      await pumpUntil(
        tester,
        find.byKey(ValueKey<String>('tr-tabs-close-${parent.id}')),
      );
      // The desktop workspace persists a binary layout, streams divider
      // changes, and collapses a source pane when its last tab moves away.
      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-split-right')),
      );
      await pumpUntil(tester, find.byType(TRSplitView));
      expect(
        find.byKey(const ValueKey<String>('workspace-pane')),
        findsNWidgets(2),
      );
      await tester.drag(
        find.byKey(const ValueKey<String>('tr-split-view-separator')),
        const Offset(TRSpacing.threeExtraLarge, 0),
      );
      await tester.pumpAndSettle();
      final sourceTab = find.byKey(
        ValueKey<String>('tr-tabs-tab-${parent.id}'),
      );
      final targetPane = find
          .byKey(const ValueKey<String>('workspace-pane'))
          .last;
      final targetTab = find.descendant(
        of: targetPane,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'tr-tabs-tab-',
              ),
        ),
      );
      await tester.timedDragFrom(
        tester.getCenter(sourceTab),
        tester.getCenter(targetTab) - tester.getCenter(sourceTab),
        const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      await pumpUntil(
        tester,
        find.descendant(
          of: targetPane,
          matching: find.byKey(
            ValueKey<String>('tr-tabs-tab-${parent.id}'),
          ),
        ),
      );
      for (var moved = 0; moved < 10; moved++) {
        if (find.byType(TRSplitView).evaluate().isEmpty) break;
        final sourceRemainingTab = find.descendant(
          of: find.byKey(const ValueKey<String>('workspace-pane')).first,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'tr-tabs-tab-',
                ),
          ),
        );
        if (sourceRemainingTab.evaluate().isEmpty) break;
        await tester.timedDragFrom(
          tester.getCenter(sourceRemainingTab.first),
          tester.getCenter(targetTab.last) -
              tester.getCenter(sourceRemainingTab.first),
          const Duration(seconds: 1),
        );
        await tester.pumpAndSettle();
      }
      await pumpUntilGone(tester, find.byType(TRSplitView));
      expect(
        find.byKey(ValueKey<String>('tr-tabs-close-${parent.id}')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await _selectDaemon(
        tester,
        'Remote daemon',
        settleAfterSelection: false,
      );
      await pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('OpenAI'), findsWidgets);
      expect(find.text('DeepSeek'), findsWidgets);
      final addCustom = find.byKey(const ValueKey('provider-add-custom'));
      await tester.ensureVisible(addCustom);
      await tester.pumpAndSettle();
      await tester.tap(addCustom);
      await tester.pumpAndSettle();
      await tester.enterText(_trTextInput('이름'), '');
      await tester.enterText(_trTextInput('Base URL'), '');
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-custom-save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('이름과 Base URL을 입력하세요.'), findsOneWidget);
      await tester.enterText(
        _trTextInput('이름'),
        'E2E Provider',
      );
      await tester.enterText(
        _trTextInput('Base URL'),
        'http://127.0.0.1:${modelServer.port}/unavailable/v1',
      );
      await tester.enterText(_trTextInput('API 키'), 'valid-key');
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-custom-save')),
      );
      ProviderConnectionDto? degradedProvider;
      await pumpUntilCondition(
        tester,
        () async {
          final matches =
              (await remoteClient.providers.listProviderConnections()).where(
                (item) =>
                    item.displayName == 'E2E Provider' &&
                    item.status == ProviderConnectionStatus.degraded,
              );
          if (matches.length != 1) return false;
          degradedProvider = matches.single;
          return true;
        },
        'the custom provider to be persisted',
      );
      expect(degradedProvider!.status, ProviderConnectionStatus.degraded);
      await pumpUntil(
        tester,
        find.byKey(
          ValueKey<String>('provider-detail-${degradedProvider!.id}'),
        ),
      );

      await tester.enterText(_trTextInput('이름'), 'E2E Provider Edited');
      await tester.enterText(
        _trTextInput('Base URL'),
        'http://127.0.0.1:${modelServer.port}/v1',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-custom-save')),
      );
      await pumpUntilCondition(
        tester,
        () async => (await remoteClient.providers.listProviderConnections())
            .any((item) => item.displayName == 'E2E Provider Edited'),
        'the custom provider edit to be persisted',
      );
      final providerConnection = await _waitForProviderModels(
        remoteClient,
        'E2E Provider Edited',
      );
      expect(
        (await remoteClient.providers.listProviderModels(
          providerConnection.id,
        )).map((model) => model.id),
        containsAll(<String>[
          '${providerConnection.modelPrefix}/e2e-model',
          '${providerConnection.modelPrefix}/$selectedModelId',
        ]),
      );
      expect(find.text('E2E Provider Edited'), findsWidgets);
      const customDelete = ValueKey<String>('provider-custom-delete');
      await pumpUntilCondition(
        tester,
        () =>
            tester.widget<TRButton>(find.byKey(customDelete)).onPressed != null,
        'the custom provider delete action to become enabled',
      );
      await tester.tap(find.byKey(customDelete));
      await pumpUntil(tester, find.byType(TRAlertDialog));
      await tester.tap(
        find.descendant(
          of: find.byType(TRAlertDialog),
          matching: find.widgetWithText(TRButton, '취소'),
        ),
      );
      await pumpUntil(tester, find.byKey(customDelete));
      expect(
        (await remoteClient.providers.listProviderConnections()).where(
          (item) => item.id == providerConnection.id,
        ),
        hasLength(1),
      );
      await tester.tap(find.byKey(customDelete));
      await pumpUntil(tester, find.byType(TRAlertDialog));
      await tester.tap(
        find.descendant(
          of: find.byType(TRAlertDialog),
          matching: find.widgetWithText(TRButton, '삭제'),
        ),
      );
      await pumpUntilCondition(
        tester,
        () async =>
            (await remoteClient.providers.listProviderConnections()).every(
              (item) => item.id != providerConnection.id,
            ),
        'custom provider to be deleted',
      );
      await pumpUntilGone(
        tester,
        find.byKey(
          ValueKey<String>('provider-detail-${providerConnection.id}'),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.pumpAndSettle();
      final addDeepSeek = find.byKey(const ValueKey('provider-add-deepseek'));
      await pumpUntil(tester, addDeepSeek);
      await tester.ensureVisible(addDeepSeek);
      await tester.tap(addDeepSeek);
      await tester.pumpAndSettle();
      await tester.enterText(_trTextInput('API 키'), 'valid-key');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-connect-submit')),
      );
      ProviderConnectionDto? connectedDeepSeek;
      await pumpUntilCondition(
        tester,
        () async {
          final matches =
              (await remoteClient.providers.listProviderConnections())
                  .where(
                    (item) =>
                        item.definitionId == 'deepseek' &&
                        item.status == ProviderConnectionStatus.connected,
                  )
                  .toList();
          if (matches.length != 1) return false;
          connectedDeepSeek = matches.single;
          return true;
        },
        'provider credential to connect',
      );
      await pumpUntil(
        tester,
        find.byKey(
          ValueKey<String>('provider-detail-${connectedDeepSeek!.id}'),
        ),
      );
      await _disconnectProviderConnection(tester, connectedDeepSeek!.id);

      await tester.tap(
        find.byKey(const ValueKey<String>('provider-add-button')),
      );
      await tester.pumpAndSettle();
      final addOllama = find.byKey(const ValueKey('provider-add-ollama'));
      await pumpUntil(tester, addOllama);
      await tester.ensureVisible(addOllama);
      await tester.tap(addOllama);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('provider-connect-submit')),
      );
      ProviderConnectionDto? connectedOllama;
      await pumpUntilCondition(
        tester,
        () async {
          final matches =
              (await remoteClient.providers.listProviderConnections())
                  .where(
                    (item) =>
                        item.definitionId == 'ollama' &&
                        item.status == ProviderConnectionStatus.connected,
                  )
                  .toList();
          if (matches.length != 1 ||
              matches.single.credentialOrigin !=
                  ProviderCredentialOrigin.none) {
            return false;
          }
          connectedOllama = matches.single;
          return true;
        },
        'no-auth provider to connect',
      );
      await _disconnectProviderConnection(tester, connectedOllama!.id);
      await pumpUntilCondition(
        tester,
        () async => (await remoteClient.providers.listProviderConnections())
            .where(
              (item) =>
                  (item.definitionId == 'deepseek' ||
                      item.definitionId == 'ollama') &&
                  item.status == ProviderConnectionStatus.connected,
            )
            .isEmpty,
        'connected providers to finish disconnecting',
      );
      final remainingConnections = await remoteClient.providers
          .listProviderConnections();
      expect(
        remainingConnections.where(
          (item) =>
              (item.definitionId == 'deepseek' ||
                  item.definitionId == 'ollama') &&
              item.status == ProviderConnectionStatus.connected,
        ),
        isEmpty,
      );
      expect(
        remainingConnections
            .singleWhere((item) => item.definitionId == 'openai')
            .status,
        ProviderConnectionStatus.connected,
      );

      // A plain directory reuses its sole checkout without exposing or
      // validating Git-only worktree and base-branch targets.
      await tester.tap(find.text('파일'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New workspace').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('E2E Directory ·').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('new-workspace-worktree')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('new-workspace-branch')),
        findsNothing,
      );
      // The send button is disabled until a model resolves, so tapping before
      // that does nothing and no session is ever created.
      await _waitForComposerReady(
        tester,
        const ValueKey<String>('session-composer-send'),
      );
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Directory e2e',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.sessions.listSessions(
          worktreeId: 'directory-checkout-e2e',
        )).any((session) => session.title == 'Directory e2e'),
        'the directory checkout session to start',
      );
      final directoryWorktrees =
          (await setupClient.workspaces.getWorkspaceCatalog()).worktrees.where(
            (item) => item.workspaceId == 'directory-workspace-e2e',
          );
      expect(directoryWorktrees.single.id, 'directory-checkout-e2e');

      // A session can start without any project: the daemon provisioned the
      // user home as an implicit workspace that no project list offers, and
      // the sidebar lists the session outside every project.
      final homeCatalog = await setupClient.workspaces.getWorkspaceCatalog();
      final homeWorkspace = homeCatalog.workspaces.singleWhere(
        (item) => item.kind == WorkspaceKind.home,
      );
      expect(homeWorkspace.rootPath, userHome.path);
      final homeCheckout = homeCatalog.worktrees.singleWhere(
        (item) => item.workspaceId == homeWorkspace.id,
      );
      final newWorkspaceButton = find
          .byKey(const ValueKey('workspace-new-button'))
          .hitTestable();
      await pumpUntil(tester, newWorkspaceButton);
      await tester.tap(newWorkspaceButton.first);
      await pumpUntil(
        tester,
        find.byKey(const ValueKey('new-workspace-project')),
      );
      await tester.tap(find.byKey(const ValueKey('new-workspace-project')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('new-workspace-project-none')),
      );
      await tester.pumpAndSettle();
      // Without a project there is no branch to pick and no checkout to make.
      expect(
        find.byKey(const ValueKey('new-workspace-worktree')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('new-workspace-branch')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Home e2e',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await pumpUntilCondition(
        tester,
        () async => (await setupClient.sessions.listSessions(
          worktreeId: homeCheckout.id,
        )).any((session) => session.title == 'Home e2e'),
        'the project-less session to start in the home folder',
      );
      // The home workspace backs the session but is never shown as a project.
      await tester.tap(find.text('Workspaces').last);
      await pumpUntil(tester, find.text('Home e2e'));
      expect(find.text(homeWorkspace.name), findsNothing);
    },
    // This test validates visible desktop interactions, not accessibility.
    // Flutter 3.44's testWidgets semantics handle exposes the open
    // OverlayPortal corruption tracked by flutter/flutter#189902, making the
    // otherwise successful run fail nondeterministically during a later frame.
    // Focused widget tests retain semantics coverage for these controls.
    semanticsEnabled: false,
    tags: const <String>[
      'feature_test__daemon_management__e2e',
      'feature_test__daemon_exposure__e2e',
      'feature_test__daemon_authentication__e2e',
      'feature_test__workspace_catalog__e2e',
      'feature_test__workspace_registration__e2e',
      'feature_test__worktree_lifecycle__e2e',
      'feature_test__session_lifecycle__e2e',
      'feature_test__session_tabs__e2e',
      'feature_test__session_goal__e2e',
      'feature_scenario__session_goal__multi_turn_completion_reconnect__e2e',
      'feature_test__terminal_lifecycle__e2e',
      'feature_test__terminal_lifecycle__platformSmoke',
      'feature_scenario__terminal_lifecycle__create_write_terminate__e2e',
      'feature_test__turn_execution__e2e',
      'feature_test__turn_question__e2e',
      'feature_scenario__turn_question__ask_and_answer__e2e',
      'feature_test__agent_definition_management__e2e',
      'feature_test__mcp_server_management__e2e',
      'feature_test__skill_management__e2e',
      'feature_test__agent_collaboration__e2e',
      'feature_test__provider_catalog__e2e',
      'feature_test__provider_usage__e2e',
      'feature_scenario__provider_usage__context_usage_hover__e2e',
      'feature_test__provider_connection_management__e2e',
      'feature_test__provider_custom__e2e',
      'feature_test__desktop_window_chrome__e2e',
      'feature_test__conversation_attachments__e2e',
      'feature_scenario__conversation_attachments__picker_cancel_retry__e2e',
      'feature_scenario__conversation_attachments__upload_preview_restore__e2e',
      'feature_scenario__conversation_attachments__agent_publish_download__e2e',
      'feature_scenario__daemon_authentication__valid_token_reconnect__e2e',
      'feature_scenario__daemon_exposure__loopback_lan_restart__e2e',
      'feature_scenario__workspace_catalog__multi_host_merge_refresh__e2e',
      'feature_scenario__worktree_lifecycle__create_and_archive__e2e',
      'feature_scenario__session_lifecycle__create_with_configuration__e2e',
      'feature_scenario__session_lifecycle__update_model_and_mode__e2e',
      'feature_scenario__session_lifecycle__reconnect_persistence__e2e',
      'feature_test__session_home__e2e',
      'feature_scenario__session_home__create_without_project__e2e',
      'feature_scenario__session_tabs__open_switch_close_restore__e2e',
      'feature_scenario__turn_execution__stream_and_restore__e2e',
      'feature_scenario__turn_execution__cancel_stream__e2e',
      'feature_scenario__turn_execution__approve_and_reject__e2e',
      'feature_scenario__turn_execution__provider_failure_recovery__e2e',
      // The verifier requires one literal tag so it can reject stale evidence.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__agent_definition_management__create_validate_edit_reload__e2e',
      // The scenario tag mirrors its typed manifest ID exactly.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__agent_definition_management__invalid_definition_rejected__e2e',
      'feature_scenario__agent_definition_management__archive_and_reset__e2e',
      'feature_scenario__mcp_server_management__add_edit_test_remove__e2e',
      // The scenario tag mirrors its typed manifest ID exactly.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__mcp_server_management__offline_and_secret_recovery__e2e',
      'feature_scenario__mcp_tool_execution__approve_execute_result__e2e',
      'feature_scenario__mcp_tool_execution__reject_and_offline__e2e',
      'feature_scenario__skill_management__source_crud_toggle__e2e',
      'feature_scenario__skill_management__invalid_edit_preserves_file__e2e',
      'feature_test__composer_file_mention__e2e',
      'feature_test__composer_slash_command__e2e',
      'feature_scenario__composer_file_mention__mention_insert_path__e2e',
      'feature_scenario__composer_file_mention__no_match_dismiss__e2e',
      'feature_scenario__composer_slash_command__client_command_dispatch__e2e',
      'feature_scenario__composer_slash_command__agent_command_prompt__e2e',
      'feature_scenario__skill_invocation__enabled_injection_and_load__e2e',
      'feature_scenario__skill_invocation__disabled_skill_excluded__e2e',
      'feature_scenario__agent_collaboration__spawn_child_final_answer__e2e',
      // The scenario tag mirrors its typed manifest ID exactly.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__agent_collaboration__unauthorized_agent_type_rejected__e2e',
      'feature_scenario__provider_catalog__presets_models_refresh__e2e',
      // The scenario tag mirrors its typed manifest ID exactly.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__provider_connection_management__api_key_none_disconnect__e2e',
      // The second connection scenario has the same typed tag constraint.
      // ignore: lines_longer_than_80_chars
      'feature_scenario__provider_connection_management__invalid_credential_recovery__e2e',
      'feature_scenario__provider_custom__create_edit_delete__e2e',
      'feature_scenario__provider_custom__validation_and_model_failure__e2e',
      'feature_scenario__desktop_window_chrome__localized_menu_navigation__e2e',
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
      await tray.install(menu: menu, onSelected: (_) {}, onActivated: () {});
      await tray.update(menu);
      expect(const NativeAttachmentInput(), isA<AttachmentInputPort>());
      expect(const NativeAttachmentExport(), isA<AttachmentExportPort>());

      // Hiding must leave the process alive, which is the whole point of
      // closing to the tray.
      await window.hide();
      await _waitForWindowVisibility(window, visible: false);
      // The tray reads this rather than the plugin query, because a hidden
      // window stops the embedder from producing the frame a rebuild needs.
      expect(window.visible.value, isFalse);
      await window.show();
      await _waitForWindowVisibility(window, visible: true);
      expect(window.visible.value, isTrue);
      expect(closes, 0);
    },
    tags: const <String>[
      'feature_test__desktop_residency__platformSmoke',
      'feature_test__desktop_window_chrome__platformSmoke',
      'feature_test__conversation_attachments__platformSmoke',
      'feature_scenario__desktop_residency__close_hide_restore__e2e',
      'feature_scenario__desktop_window_chrome__native_window_controls__e2e',
    ],
  );
}

Future<void> _waitForWindowVisibility(
  DesktopWindow window, {
  required bool visible,
}) => awaitCondition(
  () async => await window.isVisible() == visible,
  'the window to become ${visible ? 'visible' : 'hidden'}',
);

final class _E2eAttachmentInput implements AttachmentInputPort {
  _E2eAttachmentInput({
    required this.imageBytes,
    required this.documentBytes,
  });

  final Uint8List imageBytes;
  final List<int> documentBytes;
  bool _cancelNextPick = true;

  @override
  bool get supportsDrop => false;

  @override
  Future<List<PendingAttachment>> pickFiles() async {
    if (_cancelNextPick) {
      _cancelNextPick = false;
      return const <PendingAttachment>[];
    }
    return <PendingAttachment>[
      PendingAttachment.fromBytes(
        fileName: 'fixture.png',
        mimeType: 'image/png',
        bytes: imageBytes,
      ),
      PendingAttachment.fromBytes(
        fileName: 'fixture.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(documentBytes),
      ),
    ];
  }

  @override
  Future<List<PendingAttachment>> pasteFiles() async =>
      const <PendingAttachment>[];

  @override
  Future<List<PendingAttachment>> droppedFiles(
    List<DropwellFile> files,
  ) async => const <PendingAttachment>[];
}

Future<ProviderConnectionDto> _waitForProviderModels(
  CoderApi api,
  String displayName,
) => awaitValue(() async {
  final connection = (await api.providers.listProviderConnections())
      .where((item) => item.displayName == displayName)
      .singleOrNull;
  if (connection == null) return null;
  final models = await api.providers.listProviderModels(connection.id);
  return models.isEmpty ? null : connection;
}, '$displayName to discover models');

Future<void> _waitForAgentPrompt(
  CoderApi api,
  String id,
  String prompt,
) => awaitCondition(
  () async => (await api.agents.getAgentDefinition(id)).systemPrompt == prompt,
  'the external agent file to reload',
);

Future<AgentDefinitionDto> _waitForAgentDefinition(
  CoderApi api,
  String id,
) => awaitValue(() async {
  try {
    return await api.agents.getAgentDefinition(id);
  } on CoderClientException catch (error) {
    if (error.code != 'request_failed') rethrow;
    return null;
  }
}, 'Agent definition $id');

Future<void> _selectDaemon(
  WidgetTester tester,
  String label, {
  bool settleAfterSelection = true,
}) async {
  // The picker now lives in the sidebar, so a settings route still animating
  // out carries its own copy. Settle it away where the caller allows it, and
  // target the incoming route otherwise.
  if (settleAfterSelection) {
    await tester.pumpAndSettle();
  }
  final dropdown = find.byKey(
    const ValueKey<String>('settings-daemon-select'),
  );
  await tester.tap(dropdown.last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  if (settleAfterSelection) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _disconnectProviderConnection(
  WidgetTester tester,
  String connectionId,
) async {
  final detail = find.byKey(
    ValueKey<String>('provider-detail-$connectionId'),
  );
  await pumpUntil(tester, detail);
  await tester.tap(find.widgetWithText(TRButton, '연결 해제'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(TRAlertDialog),
      matching: find.widgetWithText(TRButton, '연결 해제'),
    ),
  );
  await pumpUntilGone(tester, detail);
}

Future<void> _pumpUntilTextFieldValue(
  WidgetTester tester,
  Finder finder,
  String value,
) => pumpUntilCondition(
  tester,
  () => tester
      .widgetList<EditableText>(finder)
      .any((field) => field.controller.text == value),
  'the text field to hold "$value"',
);

Finder _trTextInput(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
    description: 'TRTextField labelled "$label"',
  ),
  matching: find.byType(EditableText),
);

Finder _approvalForCall(String toolCallId) => find.byWidgetPredicate(
  (widget) =>
      widget is ApprovalCard &&
      (widget.interaction?.approval ?? widget.approval)?.toolCallId ==
          toolCallId,
  description: 'approval card for tool call $toolCallId',
);

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

/// Seeds a project command so the composer has one to expand.
Future<void> _writeProjectCommand(String path) async {
  final directory = Directory('$path/.agents/commands');
  await directory.create(recursive: true);
  await File('${directory.path}/e2e-review.md').writeAsString(
    '---\n'
    'description: Reviews a path in the E2E fixture.\n'
    'argument-hint: <path>\n'
    '---\n\n'
    r'Review $ARGUMENTS for the E2E fixture.'
    '\n',
  );
}

Future<void> _runGit(String path, List<String> arguments) async {
  final result = await Process.run('git', arguments, workingDirectory: path);
  if (result.exitCode != 0) {
    throw TestFailure('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

String _fakeMcpServerPath() {
  final suffix = <String>[
    'packages',
    'daemon',
    'test',
    'support',
    'fake_mcp_server_main.dart',
  ].join(Platform.pathSeparator);
  final candidates = <File>[
    File('${Directory.current.path}${Platform.pathSeparator}$suffix'),
    File(
      '${Directory.current.path}${Platform.pathSeparator}..'
      '${Platform.pathSeparator}..${Platform.pathSeparator}$suffix',
    ),
  ];
  for (final candidate in candidates) {
    if (candidate.existsSync()) return candidate.absolute.path;
  }
  throw TestFailure(
    'Could not locate fake_mcp_server_main.dart from ${Directory.current}.',
  );
}

String _dartExecutable() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final executable = File(
      <String>[
        flutterRoot,
        'bin',
        'cache',
        'dart-sdk',
        'bin',
        if (Platform.isWindows) 'dart.exe' else 'dart',
      ].join(Platform.pathSeparator),
    );
    if (executable.existsSync()) return executable.absolute.path;
  }
  final lookup = Process.runSync(
    Platform.isWindows ? 'where' : 'which',
    <String>[
      'dart',
    ],
  );
  if (lookup.exitCode == 0) {
    return (lookup.stdout as String).split(RegExp(r'\r?\n')).first.trim();
  }
  throw TestFailure(
    'Could not locate the Dart executable for the MCP fixture.',
  );
}

/// Waits for the composer to have a model, which is all that gates sending.
///
/// A running turn never disables the button; the prompt queues instead. So
/// this is not a barrier on the previous turn, and a caller that needs one has
/// to wait on daemon state itself.
Future<void> _waitForComposerReady(
  WidgetTester tester,
  ValueKey<String> sendKey,
) => pumpUntilCondition(
  tester,
  () => tester.widget<TRIconButton>(find.byKey(sendKey)).onPressed != null,
  'the composer to have a model selected',
);

/// Types [prompt] into the composer and proves it arrived.
///
/// `tester.enterText` grants focus and pumps once, which is not enough: the
/// text goes to whichever field owns the input connection, so a rebuild racing
/// the keystroke leaves the field empty. An empty field then makes the send a
/// silent no-op, because the composer treats "nothing to send" as nothing to
/// do. Callers that only type, such as the `@` mention steps, use this
/// directly; everything else goes through [_submitComposerPrompt].
Future<void> _typeComposerPrompt(
  WidgetTester tester,
  ValueKey<String> composerKey,
  String prompt,
) async {
  final composer = find.byKey(composerKey);
  final input = find.descendant(
    of: composer,
    matching: find.byType(EditableText),
  );
  await tester.tap(input);
  // Focus is the evidence that the input connection is this composer's.
  await pumpUntilCondition(
    tester,
    () => tester.widget<EditableText>(input).focusNode.hasFocus,
    'the composer to take focus',
  );
  tester.testTextInput.enterText(prompt);
  await tester.pump();
  expect(tester.widget<TRTextField>(composer).controller?.text, prompt);
}

Future<void> _submitComposerPrompt(
  WidgetTester tester,
  ValueKey<String> composerKey,
  ValueKey<String> sendKey,
  String prompt,
) async {
  await _waitForComposerReady(tester, sendKey);
  await _typeComposerPrompt(tester, composerKey, prompt);
  // The send button and the toast stack share the bottom-trailing corner, so a
  // report still on screen from an earlier action takes the tap instead. A
  // reader waits it out or dismisses it; this waits.
  await _waitForToastsToClear(tester);
  await tester.tap(find.byKey(sendKey));
  await tester.pump();
}

/// Waits until nothing is left in the toast stack.
Future<void> _waitForToastsToClear(WidgetTester tester) => pumpUntilGone(
  tester,
  find.descendant(
    of: find.byType(TRToastRegion),
    matching: find.byType(Dismissible),
  ),
);

Future<void> _replaceMcpFieldText(
  WidgetTester tester,
  String key,
  String value,
) async {
  final field = find.byKey(ValueKey<String>(key));
  final input = find.descendant(of: field, matching: find.byType(EditableText));
  await tester.ensureVisible(field);
  await tester.tap(input);
  await tester.pump();
  tester.testTextInput.enterText(value);
  await tester.pump();
}

/// Waits for [finder], reporting both sides when it never comes.
///
/// The daemon dump alone reads as innocent when the prompt never left the
/// client, which is indistinguishable from a model that answered something
/// else. The composer state is what tells those apart.
Future<void> _pumpUntilWithSessionDiagnostics(
  WidgetTester tester,
  Finder finder,
  CoderApi api,
) async {
  try {
    await pumpUntil(tester, finder, budget: e2eTurnBudget);
  } on TestFailure catch (failure) {
    final sessions = await api.sessions.listSessions(
      worktreeId: 'checkout-e2e',
    );
    final diagnostics = <String, Object?>{};
    for (final session in sessions) {
      diagnostics[session.id] = <String, Object?>{
        'status': session.status.name,
        'definition': session.agentDefinitionId,
        'events': (await api.sessions.subscribeTimeline(
          session.id,
        )).map((event) => event.type).toList(growable: false),
      };
    }
    final composers = tester.widgetList<SessionComposer>(
      find.byType(SessionComposer),
    );
    final client = <String, Object?>{
      'busy': composers.map((item) => item.busy).toList(growable: false),
      'queued': composers
          .map(
            (item) => item.queued
                .map(
                  (turn) =>
                      '${turn.text} '
                      '(attempts ${turn.attempts}, error ${turn.error})',
                )
                .toList(growable: false),
          )
          .toList(growable: false),
      'composerText': tester
          .widgetList<TRTextField>(find.byType(TRTextField))
          .map((field) => field.controller?.text)
          .where((text) => text != null && text.isNotEmpty)
          .toList(growable: false),
    };
    throw TestFailure(
      '${failure.message} Client: $client Sessions: $diagnostics',
    );
  }
}

final class _RestartableLauncher implements EmbeddedDaemonLauncher {
  _RestartableLauncher({
    required EmbeddedDaemonHandle initialHandle,
    required this.homeDirectory,
    required this.userHomeDirectory,
    required this.bearerToken,
    required this.provider,
  }) : _current = initialHandle;

  final String homeDirectory;

  /// Stands in for the machine home so a restart keeps the home workspace.
  final String userHomeDirectory;
  final String bearerToken;
  final ModelProvider provider;
  final List<EmbeddedDaemonExposure> exposures = <EmbeddedDaemonExposure>[];
  EmbeddedDaemonHandle? _current;
  bool _initial = true;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) async {
    exposures.add(exposure);
    final handle = _initial
        ? _current!
        : await EmbeddedDaemonHandle.start(
            DaemonConfig(
              homeDirectory: homeDirectory,
              userHomeDirectory: userHomeDirectory,
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
      const patch =
          '*** Begin Patch\n'
          '*** Add File: result.txt\n'
          '+done\n'
          '*** End Patch';
      yield const ModelFreeformCall(
        callId: 'patch-call',
        name: 'apply_patch',
        rawInput: patch,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.freeform(
              callId: 'patch-call',
              name: 'apply_patch',
              input: patch,
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

final class _E2eModelDiscovery implements ProviderModelDiscovery {
  const _E2eModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderEndpoint endpoint,
    ProviderCredential? credential,
  ) async {
    if (endpoint.baseUrl.contains('/unavailable/')) {
      throw const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.unavailable,
        'planned model discovery outage',
      );
    }
    if (credential case ApiKeyCredential(:final key) when key != 'valid-key') {
      throw const ProviderDiscoveryFailure(
        ProviderDiscoveryFailureKind.invalidCredential,
        'credential rejected by deterministic provider',
      );
    }
    return const <String>[
      'e2e-model',
      'vendor/reasoning-model-with-an-extremely-long-identifier',
    ];
  }
}

final class _AgentE2eProvider implements ModelProvider {
  _AgentE2eProvider(this.attachmentCapturePath);

  final String attachmentCapturePath;
  int _providerFailures = 0;
  int _goalRounds = 0;

  @override
  String get id => 'agent-e2e-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final latestHistoryItem = request.history.lastOrNull;
    if (latestHistoryItem is ToolResultConversationItem &&
        latestHistoryItem.callId == 'goal-complete-call') {
      yield const ModelTextDelta('Persistent goal complete.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: 'Persistent goal complete.',
        ),
      );
      return;
    }
    // Matched on the objective inside its element rather than on one exact
    // line, so the goal prompt can be reworded without silently turning this
    // branch off and leaving the goal to time out.
    if (RegExp(
      r'<objective>\s*Complete persistent goal e2e\s*</objective>',
    ).hasMatch(request.instructions)) {
      _goalRounds += 1;
      if (_goalRounds < 3) {
        yield ModelTextDelta('Goal progress $_goalRounds.');
        yield ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: 'Goal progress $_goalRounds.',
          ),
        );
        return;
      }
      const arguments = <String, dynamic>{'status': 'complete'};
      yield const ModelFunctionCall(
        callId: 'goal-complete-call',
        name: 'update_goal',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'goal-complete-call',
              name: 'update_goal',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    final latestUser = request.history.whereType<UserConversationItem>().last;
    final latestPrompt = latestUser.text;
    if (request.instructions.contains('You are in Plan Mode')) {
      yield const ModelTextDelta('Plan ready: Create result.txt');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: 'Plan ready: Create result.txt',
        ),
      );
      return;
    }
    if (latestPrompt == 'Ask me about storage') {
      final answered = request.history
          .whereType<ToolResultConversationItem>()
          .where((item) => item.callId == 'ask-call')
          .firstOrNull;
      if (answered == null) {
        const arguments = <String, dynamic>{
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'store',
              'header': 'Storage',
              'question': 'Which store should the cache use?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{
                  'label': 'SQLite',
                  'description': 'Durable and already a dependency.',
                },
                <String, dynamic>{
                  'label': 'In memory',
                  'description': 'Fastest, lost on restart.',
                },
              ],
            },
            <String, dynamic>{
              'id': 'theme',
              'header': 'Theme',
              'question': 'Which theme should the editor use?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{
                  'label': 'System',
                  'description': 'Follow the operating system.',
                },
                <String, dynamic>{
                  'label': 'Dark',
                  'description': 'Always use the dark theme.',
                },
              ],
            },
            <String, dynamic>{
              'id': 'review',
              'header': 'Review',
              'question': 'How should changes be reviewed?',
              'options': <Map<String, dynamic>>[
                <String, dynamic>{
                  'label': 'Pull request',
                  'description': 'Require a review before merging.',
                },
                <String, dynamic>{
                  'label': 'Direct',
                  'description': 'Merge directly after checks pass.',
                },
              ],
            },
          ],
        };
        yield const ModelFunctionCall(
          callId: 'ask-call',
          name: 'request_user_input',
          arguments: arguments,
        );
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: '',
            toolCalls: <ConversationToolCall>[
              ConversationToolCall.function(
                callId: 'ask-call',
                name: 'request_user_input',
                arguments: arguments,
              ),
            ],
          ),
        );
        return;
      }
      final reply =
          answered.output.contains('SQLite') &&
              answered.output.contains('High contrast') &&
              answered.output.contains('Pull request')
          ? 'Chose SQLite, High contrast, and Pull request'
          : 'Chose something else';
      yield ModelTextDelta(reply);
      yield ModelResponseCompleted(
        assistant: AssistantConversationItem(text: reply),
      );
      return;
    }

    // A spawned subagent's turns always carry the NEW_TASK envelope the
    // daemon delivered at its first message boundary.
    final isSubagentTurn = request.history
        .whereType<UserConversationItem>()
        .any((item) => item.text.startsWith('Message Type: NEW_TASK'));
    if (isSubagentTurn) {
      yield const ModelTextDelta('Review completed.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Review completed.'),
      );
      return;
    }
    final hasSpawnResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'spawn-call');
    final hasPatchResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'patch-call');
    final hasAttachResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'attach-call');

    if (latestUser.attachments.isNotEmpty) {
      await File(attachmentCapturePath).writeAsString(
        jsonEncode(
          latestUser.attachments
              .map(
                (attachment) => <String, dynamic>{
                  'fileName': attachment.fileName,
                  'bytes': base64Encode(attachment.bytes!),
                },
              )
              .toList(growable: false),
        ),
      );
      yield const ModelTextDelta('Attached fixtures.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Attached fixtures.'),
      );
      return;
    }

    if (latestPrompt == 'Publish outbound attachment') {
      if (!hasAttachResult) {
        const arguments = <String, dynamic>{'path': 'agent-output.txt'};
        yield const ModelFunctionCall(
          callId: 'attach-call',
          name: 'attach_file',
          arguments: arguments,
        );
        yield const ModelResponseCompleted(
          assistant: AssistantConversationItem(
            text: '',
            toolCalls: <ConversationToolCall>[
              ConversationToolCall.function(
                callId: 'attach-call',
                name: 'attach_file',
                arguments: arguments,
              ),
            ],
          ),
        );
        return;
      }
      yield const ModelTextDelta('Published outbound attachment.');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: 'Published outbound attachment.',
        ),
      );
      return;
    }

    final hasRejectedPatchResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'reject-patch-call');
    final hasMcpResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'mcp-call');
    final hasRejectedMcpResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'reject-mcp-call');
    final hasSkillResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'skill-call');
    final skillListing = request.history
        .whereType<ToolResultConversationItem>()
        .where((item) => item.callId == 'skill-list-call')
        .map((item) => item.output)
        .firstOrNull;
    final hasDisallowedDelegationResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'disallowed-delegate-call');

    if (latestPrompt == 'Disallowed delegation' &&
        !hasDisallowedDelegationResult) {
      const arguments = <String, dynamic>{
        'task_name': 'forbidden_task',
        'message': 'This spawn must not start.',
        'agent_type': 'not-allowed',
        'fork_turns': 'none',
        'model': null,
        'reasoning_effort': null,
      };
      yield const ModelFunctionCall(
        callId: 'disallowed-delegate-call',
        name: 'spawn_agent',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'disallowed-delegate-call',
              name: 'spawn_agent',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Disallowed delegation') {
      yield const ModelTextDelta('Disallowed delegation rejected');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: 'Disallowed delegation rejected',
        ),
      );
      return;
    }

    if (latestPrompt == 'Use E2E skill' && skillListing == null) {
      // The prompt names no skill any more, only how many there are and which
      // tool finds them, so its size no longer tracks the catalog.
      if (!request.instructions.contains('list_skills') ||
          request.instructions.contains('Loaded during an end-to-end turn.')) {
        throw StateError('the skill prompt still carried the catalog');
      }
      const listArguments = <String, dynamic>{'cursor': null};
      yield const ModelFunctionCall(
        callId: 'skill-list-call',
        name: 'list_skills',
        arguments: listArguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'skill-list-call',
              name: 'list_skills',
              arguments: listArguments,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Use E2E skill' && !hasSkillResult) {
      // The catalog now lives in the listing, so that is where an enabled
      // skill must appear and a disabled one must not.
      if (!skillListing!.contains('invoke-e2e') ||
          skillListing.contains('"commit"')) {
        throw StateError('enabled and disabled skill catalog was incorrect');
      }
      const arguments = <String, dynamic>{
        'name': 'invoke-e2e',
        'resource': null,
      };
      yield const ModelFunctionCall(
        callId: 'skill-call',
        name: 'skill',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'skill-call',
              name: 'skill',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Use E2E skill') {
      yield const ModelTextDelta('Skill loaded');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Skill loaded'),
      );
      return;
    }
    if (latestPrompt == 'Disabled E2E skill') {
      // The prompt carries no skill text at all now, so this only guards
      // against a regression that puts the catalog back. That a disabled
      // skill leaves the catalog is pinned by the daemon vertical slice,
      // which asserts on the listing the tool actually returns.
      if (request.instructions.contains('Loaded during an end-to-end turn.')) {
        throw StateError('disabled skill remained in the turn catalog');
      }
      yield const ModelTextDelta('Disabled skill excluded');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Disabled skill excluded'),
      );
      return;
    }

    if (latestPrompt == 'Offline MCP') {
      final available = request.tools.any(
        (tool) => tool.name == 'mcp__e2e__echo',
      );
      if (available) throw StateError('offline MCP tool remained available');
      yield const ModelTextDelta('MCP unavailable safely');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: 'MCP unavailable safely',
        ),
      );
      return;
    }
    if (latestPrompt == 'MCP echo' && !hasMcpResult) {
      if (!request.tools.any((tool) => tool.name == 'mcp__e2e__echo')) {
        throw StateError('MCP echo tool was not injected');
      }
      const arguments = <String, dynamic>{'value': 'through MCP'};
      yield const ModelFunctionCall(
        callId: 'mcp-call',
        name: 'mcp__e2e__echo',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'mcp-call',
              name: 'mcp__e2e__echo',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'MCP echo') {
      yield const ModelTextDelta('MCP completed');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'MCP completed'),
      );
      return;
    }
    if (latestPrompt == 'Reject MCP' && !hasRejectedMcpResult) {
      const arguments = <String, dynamic>{'value': 'must not run'};
      yield const ModelFunctionCall(
        callId: 'reject-mcp-call',
        name: 'mcp__e2e__echo',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'reject-mcp-call',
              name: 'mcp__e2e__echo',
              arguments: arguments,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Reject MCP') {
      yield const ModelTextDelta('MCP rejected');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'MCP rejected'),
      );
      return;
    }

    if (latestPrompt == 'Cancel streaming') {
      yield const ModelTextDelta('Streaming before cancel');
      final cancelled = Completer<void>();
      cancellation.onCancel(cancelled.complete);
      await cancelled.future;
      cancellation.throwIfCancelled();
    }
    if (latestPrompt == 'Recover provider') {
      if (_providerFailures == 0) {
        _providerFailures += 1;
        throw StateError('planned provider outage');
      }
      yield const ModelTextDelta('Provider recovered');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Provider recovered'),
      );
      return;
    }

    if (latestPrompt == 'Delegate review' && !hasSpawnResult) {
      const arguments = <String, dynamic>{
        'task_name': 'review_task',
        'message': 'Review without changing files.',
        'agent_type': 'reviewer',
        'fork_turns': 'none',
        'model': null,
        'reasoning_effort': null,
      };
      yield const ModelFunctionCall(
        callId: 'spawn-call',
        name: 'spawn_agent',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.function(
              callId: 'spawn-call',
              name: 'spawn_agent',
              arguments: arguments,
            ),
          ],
        ),
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
      const patch =
          '*** Begin Patch\n'
          '*** Add File: result.txt\n'
          '+done\n'
          '*** End Patch';
      yield const ModelFreeformCall(
        callId: 'patch-call',
        name: 'apply_patch',
        rawInput: patch,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.freeform(
              callId: 'patch-call',
              name: 'apply_patch',
              input: patch,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Reject result.txt' && !hasRejectedPatchResult) {
      const patch =
          '*** Begin Patch\n'
          '*** Add File: rejected.txt\n'
          '+nope\n'
          '*** End Patch';
      yield const ModelFreeformCall(
        callId: 'reject-patch-call',
        name: 'apply_patch',
        rawInput: patch,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall.freeform(
              callId: 'reject-patch-call',
              name: 'apply_patch',
              input: patch,
            ),
          ],
        ),
      );
      return;
    }
    if (latestPrompt == 'Reject result.txt') {
      yield const ModelTextDelta('Rejected safely');
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(text: 'Rejected safely'),
      );
      return;
    }
    yield const ModelTextDelta('Created result.txt');
    yield const ModelResponseCompleted(
      assistant: AssistantConversationItem(text: 'Created result.txt'),
    );
  }
}
