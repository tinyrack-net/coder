import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/attachment_io.dart';
import 'package:coder_app/src/coder_icons.dart';
import 'package:coder_app/src/coder_selection_row.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/tray_menu_model.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app switches hosts, streams, approves a patch, and restores timeline',
    (tester) async {
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
        modelDiscovery: const _E2eModelDiscovery(),
      );
      addTearDown(() async {
        await embeddedLauncher.stopCurrent();
        await remoteHandle.stop();
        if (home.existsSync()) home.deleteSync(recursive: true);
        if (remoteHome.existsSync()) remoteHome.deleteSync(recursive: true);
        if (workspace.existsSync()) workspace.deleteSync(recursive: true);
        if (directoryWorkspace.existsSync()) {
          directoryWorkspace.deleteSync(recursive: true);
        }
        if (remoteWorkspace.existsSync()) {
          remoteWorkspace.deleteSync(recursive: true);
        }
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
      await setupClient.registerWorkspace(
        workspaceId: 'workspace-e2e',
        checkoutId: 'checkout-e2e',
        rootPath: workspace.path,
        name: 'E2E Workspace',
      );
      await setupClient.registerWorkspace(
        workspaceId: 'directory-workspace-e2e',
        checkoutId: 'directory-checkout-e2e',
        rootPath: directoryWorkspace.path,
        name: 'E2E Directory',
      );
      final remoteWorkspaceName = remoteWorkspace.path
          .split(Platform.pathSeparator)
          .last;
      await remoteClient.registerWorkspace(
        workspaceId: 'remote-workspace-e2e',
        checkoutId: 'remote-checkout-e2e',
        rootPath: remoteWorkspace.path,
        name: remoteWorkspaceName,
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
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await _pumpUntil(tester, find.text(remoteWorkspaceName));
      await _pumpUntil(tester, find.textContaining('내장 daemon · '));

      // The global desktop menu reaches the same typed new-workspace route.
      expect(find.text('파일'), findsOneWidget);
      await tester.tap(find.text('파일'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New workspace').last);
      await tester.pumpAndSettle();
      final projectChip = find.byKey(
        const ValueKey('new-workspace-project'),
      );
      final pointer = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getCenter(projectChip));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(find.text('프로젝트 선택'), findsOneWidget);

      final projectChipCenter = tester.getCenter(projectChip);
      await pointer.down(projectChipCenter);
      await pointer.up();
      await tester.pumpAndSettle();
      final addProject = find.byKey(
        const ValueKey('new-workspace-project-add'),
      );
      expect(addProject, findsOneWidget);
      expect(find.text('프로젝트 선택'), findsNothing);
      await pointer.down(projectChipCenter);
      await pointer.up();
      await tester.pumpAndSettle();
      expect(addProject, findsNothing);
      await pointer.removePointer();

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daemon').last);
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
      await _pumpUntilCondition(
        tester,
        () => embeddedLauncher.exposures.length == 3,
        'embedded daemon to return to loopback',
      );
      await _pumpUntilCondition(
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
      await _pumpUntil(tester, find.text('Agents'));
      await _selectDaemon(tester, 'Remote daemon');
      final addAgent = find.byKey(const ValueKey('agent-add-button'));
      await _pumpUntil(tester, addAgent);
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
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      final remoteAgent = await _waitForAgentDefinition(
        remoteClient,
        'remote-agent',
      );
      expect(remoteAgent.sourcePath, startsWith(remoteHome.path));
      await _selectDaemon(tester, '내장 daemon');
      await _pumpUntil(tester, addAgent);
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
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      final reviewer = await _waitForAgentDefinition(setupClient, 'reviewer');
      final reviewerFile = File(reviewer.sourcePath);
      expect(reviewerFile.existsSync(), isTrue);

      final promptField = _trTextInput('System prompt (Markdown)');
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
        setupClient.validateAgentDefinition(
          'reviewer',
          'this document has no frontmatter',
        ),
        throwsA(isA<CoderClientException>()),
      );
      expect(await reviewerFile.readAsString(), validReviewerSource);

      await _pumpUntil(tester, addAgent);
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
      await _pumpUntilGone(tester, find.text('Agent 추가'));
      await _waitForAgentDefinition(setupClient, 'temporary');
      await tester.tap(find.byKey(const ValueKey('agent-archive-button')));
      await tester.pumpAndSettle();
      expect(
        (await setupClient.listAgentDefinitions()).map((item) => item.id),
        isNot(contains('temporary')),
      );

      await tester.tap(find.text('Coder').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('agent-reset-button')));
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
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(
        (await setupClient.getAgentDefinition('coder')).callableAgentIds,
        <String>['reviewer'],
      );

      await tester.tap(find.text('Agent'));
      await _pumpUntil(tester, find.text('Agents'));
      await tester.tap(find.text('스킬'));
      final skillAddButton = find.byKey(
        const ValueKey<String>('skill-add-button'),
      );
      await _pumpUntil(tester, skillAddButton);
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
      await tester.tap(find.text('commit').first);
      await tester.pumpAndSettle();
      final commitSwitch = find.byKey(
        const ValueKey<String>('skill-enabled-commit'),
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
      await tester.tap(
        find.byKey(const ValueKey<String>('skill-delete-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제'));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.listSkills()).every(
          (skill) => skill.id != 'e2e-skill',
        ),
        'the skill to be archived',
      );
      final invokedSkill = await setupClient.createSkill(
        id: 'invoke-e2e',
        source: SkillSource.config,
        name: 'invoke-e2e',
        description: 'Loaded during an end-to-end turn.',
        body: 'Use the deterministic E2E instructions.',
      );
      final invokedSkillFile = File(invokedSkill.sourcePath);
      final validSkillSource = await invokedSkillFile.readAsString();
      await expectLater(
        setupClient.updateSkill(
          invokedSkill.copyWith(body: 'must not overwrite'),
          expectedContentHash: 'stale-content-hash',
        ),
        throwsA(isA<CoderClientException>()),
      );
      expect(await invokedSkillFile.readAsString(), validSkillSource);

      await tester.tap(find.text('Agent'));
      await _pumpUntil(tester, find.text('Agents'));
      await tester.pumpAndSettle();
      // MCP: expose a real child-process failure, repair its command and
      // secret through the UI, test discovery, then remove it again.
      await tester.tap(find.text('MCP').last);
      await _pumpUntil(tester, find.text('MCP 서버'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TRSelectFormField<String>>(
              find
                  .byKey(
                    const ValueKey<String>('settings-daemon-select'),
                  )
                  .last,
            )
            .initialValue,
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
      await _pumpUntil(
        tester,
        find.byKey(const ValueKey<String>('mcp-editor-error')),
      );
      await _pumpUntilCondition(
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
      await tester.tap(setSecret);
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
      await _pumpUntilCondition(
        tester,
        () =>
            mcpTestNotice.evaluate().isNotEmpty ||
            mcpTestError.evaluate().isNotEmpty,
        'the repaired unsaved MCP test to finish',
        attempts: 200,
      );
      if (mcpTestError.evaluate().isNotEmpty) {
        throw TestFailure(
          'Repaired unsaved MCP test failed: '
          '${tester.widget<Text>(mcpTestError).data}',
        );
      }
      await tester.ensureVisible(saveServer);
      await tester.tap(saveServer);
      await _pumpUntilCondition(
        tester,
        () async {
          final servers = await setupClient.listMcpServers();
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
        (await setupClient.listMcpServers()).single.tools.single.toolId,
        'mcp__e2e__echo',
      );
      final deleteServer = find.byKey(const ValueKey('mcp-server-delete'));
      await tester.ensureVisible(deleteServer);
      await tester.pumpAndSettle();
      await tester.tap(deleteServer);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mcp-delete-confirm')));
      await _pumpUntilGone(
        tester,
        find.byKey(const ValueKey('mcp-server-tile-e2e')),
      );
      expect(await setupClient.listMcpServers(), isEmpty);

      // Reinstall the proven local server for the turn-execution scenarios.
      await setupClient.addMcpServer(
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
      await _pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.listMcpServers()).single.status ==
            McpServerStatus.ready,
        'the MCP turn server to reconnect',
      );
      final coderDefinition = await setupClient.getAgentDefinition('coder');
      await setupClient.updateAgentDefinition(
        coderDefinition.copyWith(
          toolIds: <String>[
            ...coderDefinition.toolIds,
            'mcp__e2e__echo',
          ],
        ),
        expectedContentHash: coderDefinition.contentHash,
      );

      await tester.tap(find.byIcon(CoderIcons.back).first);
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
      await tester.tap(find.textContaining('E2E Workspace ·').last);
      await tester.pumpAndSettle();
      final worktreeModelSelector = find.byKey(
        const ValueKey('session-composer-model'),
      );
      await tester.ensureVisible(worktreeModelSelector);
      await tester.pumpAndSettle();
      await tester.tap(worktreeModelSelector);
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
      final managedWorktree = (await setupClient.getWorkspaceCatalog())
          .worktrees
          .singleWhere((worktree) => worktree.branch == 'feature-e2e');
      final managedMenu = find.byKey(
        ValueKey<String>('worktree-menu-${managedWorktree.id}'),
      );
      await tester.ensureVisible(managedMenu);
      await tester.pumpAndSettle();
      await tester.tap(managedMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      final archiveConfirm = find.byKey(
        const ValueKey<String>('worktree-archive-confirm'),
      );
      await _pumpUntil(tester, archiveConfirm);
      await tester.tap(archiveConfirm);
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
      final sessionModelSelector = find.byKey(
        const ValueKey('session-composer-model'),
      );
      expect(sessionModelSelector, findsOne);
      await tester.ensureVisible(sessionModelSelector);
      await tester.pumpAndSettle();
      await tester.tap(sessionModelSelector);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('model-option-openai-gpt-5.6-sol')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(composer), 'Delegate review');
      await tester.pump();
      expect(
        tester.widget<TRTextField>(find.byKey(composer)).controller?.text,
        isNotEmpty,
      );
      expect(
        tester.widget<TRIconButton>(find.byKey(send)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(send));
      await tester.pump();
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('Parent completed.', findRichText: true),
        setupClient,
      );
      await tester.tap(
        find
            .byKey(const ValueKey<String>('workspace-all-sessions-menu'))
            .hitTestable(),
      );
      await _pumpUntil(tester, find.text('Reviewer'));
      // The popup is still animating when its label first appears.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reviewer').last);
      await _pumpUntil(tester, find.text('reviewer · delegated'));
      await tester.tap(find.text('Delegate review').first);
      await _pumpUntil(tester, find.text('coder · manual'));
      await _pumpUntil(tester, find.byKey(composer));

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
        find.textContaining(
          'Agent delegation is not allowed: not-allowed',
          findRichText: true,
        ),
        setupClient,
      );
      await _pumpUntilCondition(
        tester,
        () => tester.widget<TRIconButton>(find.byKey(send)).onPressed != null,
        'the failed delegation turn to release the composer',
      );

      await _submitComposerPrompt(tester, composer, send, 'Create result.txt');
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
      await _pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.listSessions(worktreeId: 'checkout-e2e'))
                .singleWhere(
                  (session) => session.origin == SessionOrigin.manual,
                )
                .status ==
            SessionStatus.idle,
        'the current session to become idle',
      );
      expect(tester.takeException(), isNull);

      // Attachments use the authenticated HTTP transport even though the turn
      // and timeline continue to use the WebSocket API.
      await File('${workspace.path}/agent-output.txt').writeAsString(
        'agent attachment\n',
      );
      final attachmentSession = (await setupClient.listSessions(
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
      await _pumpUntil(tester, find.textContaining('fixture.png'));
      expect(find.textContaining('fixture.txt'), findsOneWidget);
      await tester.tap(find.byKey(send));
      await _pumpUntilCondition(
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
      final attachmentTimeline = await setupClient.subscribeTimeline(
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
      await _pumpUntil(
        tester,
        find.byKey(ValueKey('chat-attachment-$imageAttachmentId')),
        attempts: 300,
      );
      await tester.tap(
        find.byKey(ValueKey('chat-attachment-$imageAttachmentId')),
      );
      await _pumpUntil(tester, find.byType(InteractiveViewer));
      expect(find.byType(InteractiveViewer), findsOneWidget);
      Navigator.of(tester.element(find.byType(InteractiveViewer))).pop();
      await _pumpUntilGone(tester, find.byType(InteractiveViewer));
      await _pumpUntil(
        tester,
        find.text('Attached fixtures.', findRichText: true),
        attempts: 300,
      );

      await tester.enterText(
        find.byKey(composer),
        'Publish outbound attachment',
      );
      await tester.tap(find.byKey(send));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.subscribeTimeline(
          attachmentSession.id,
        )).any((event) => event.type == 'assistant.attachment'),
        'the agent to publish its outbound attachment',
        attempts: 300,
      );
      await _pumpUntil(
        tester,
        find.textContaining('agent-output.txt'),
        attempts: 300,
      );
      final outboundTimeline = await setupClient.subscribeTimeline(
        attachmentSession.id,
      );
      final outboundEvent = outboundTimeline.singleWhere(
        (event) => event.type == 'assistant.attachment',
      );
      final outboundId = outboundEvent.data['id']! as String;
      final outboundDownload = await setupClient.downloadAttachment(outboundId);
      expect(
        await outboundDownload.bytes.expand((chunk) => chunk).toList(),
        utf8.encode('agent attachment\n'),
      );
      await _pumpUntil(
        tester,
        find.text('Published outbound attachment.', findRichText: true),
        attempts: 300,
      );

      await _submitComposerPrompt(tester, composer, send, 'Reject result.txt');
      await _pumpUntil(tester, find.text('승인 필요 · apply_patch'));
      await tester.tap(find.widgetWithText(TRButton, '거부'));
      await _pumpUntil(
        tester,
        find.text('Rejected safely', findRichText: true),
      );
      expect(File('${workspace.path}/rejected.txt').existsSync(), isFalse);

      final liveMcpServer = (await setupClient.listMcpServers()).single;
      expect(liveMcpServer.status, McpServerStatus.ready);
      expect(
        liveMcpServer.tools.map((tool) => tool.toolId),
        contains('mcp__e2e__echo'),
      );
      expect(
        (await setupClient.listAgentTools()).map((tool) => tool.id),
        contains('mcp__e2e__echo'),
      );
      await _submitComposerPrompt(tester, composer, send, 'MCP echo');
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('승인 필요 · mcp__e2e__echo'),
        setupClient,
      );
      await tester.tap(find.widgetWithText(TRButton, '승인'));
      await _pumpUntil(
        tester,
        find.text('MCP completed', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Reject MCP');
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('승인 필요 · mcp__e2e__echo'),
        setupClient,
      );
      await tester.tap(find.widgetWithText(TRButton, '거부'));
      await _pumpUntil(tester, find.text('MCP rejected', findRichText: true));

      await setupClient.removeMcpServer('e2e');
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.listAgentTools()).every(
          (tool) => tool.id != 'mcp__e2e__echo',
        ),
        'the offline MCP tool to leave the agent catalog',
      );
      await _submitComposerPrompt(tester, composer, send, 'Offline MCP');
      await _pumpUntil(
        tester,
        find.text('MCP unavailable safely', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Use E2E skill');
      await _pumpUntil(
        tester,
        find.text('Skill loaded', findRichText: true),
      );
      await setupClient.setSkillEnabled('invoke-e2e', enabled: false);
      await _submitComposerPrompt(tester, composer, send, 'Disabled E2E skill');
      await _pumpUntil(
        tester,
        find.text('Disabled skill excluded', findRichText: true),
      );

      await _submitComposerPrompt(tester, composer, send, 'Cancel streaming');
      await _pumpUntil(
        tester,
        find.text('Streaming before cancel', findRichText: true),
      );
      final stop = find.byWidgetPredicate(
        (widget) => widget is TRIconButton && widget.label == '중지',
        description: 'stop active turn button',
      );
      await tester.tap(stop);
      await _pumpUntil(tester, find.text('중지됨'));

      await _submitComposerPrompt(tester, composer, send, 'Recover provider');
      await _pumpUntil(tester, find.textContaining('planned provider outage'));
      await _submitComposerPrompt(tester, composer, send, 'Recover provider');
      await _pumpUntil(
        tester,
        find.text('Provider recovered', findRichText: true),
      );

      final turnBranches = await setupClient.subscribeTimeline(
        (await setupClient.listSessions(
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
        contains(
          contains('Agent delegation is not allowed: not-allowed'),
        ),
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
      await _pumpUntilCondition(
        tester,
        () async =>
            (await setupClient.listSessions(
                  worktreeId: 'checkout-e2e',
                ))
                .singleWhere((session) => session.id == attachmentSession.id)
                .mode ==
            SessionMode.plan,
        'the attachment session to enter plan mode',
      );
      await tester.pumpAndSettle();
      await _waitForComposerReady(tester, send);
      await tester.enterText(find.byKey(composer), 'Plan the change');
      await tester.pump();
      expect(
        tester.widget<TRIconButton>(find.byKey(send)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(send));
      await _pumpUntil(tester, find.text('제안된 계획'), attempts: 600);
      await _pumpUntil(
        tester,
        find.text('이 계획대로 진행할까요?'),
        attempts: 600,
      );
      expect(find.textContaining('proposed_plan'), findsNothing);
      final implement = find.widgetWithText(TRButton, '계획대로 실행');
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
      final restoredAttachmentTimeline = await reconnected.subscribeTimeline(
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
        find.byKey(ValueKey<String>('session-tab-close-${parent.id}')),
      );
      await _pumpUntilGone(
        tester,
        find.byKey(ValueKey<String>('session-tab-close-${parent.id}')),
      );
      expect(
        (await setupClient.listSessions(
          worktreeId: 'checkout-e2e',
        )).map((session) => session.id),
        contains(parent.id),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-all-sessions-menu')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delegate review').last);
      await _pumpUntil(
        tester,
        find.byKey(ValueKey<String>('session-tab-close-${parent.id}')),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('workspace-settings-button')),
      );
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
      await tester.enterText(_trTextInput('이름'), '');
      await tester.enterText(_trTextInput('Base URL'), '');
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await tester.pumpAndSettle();
      expect(find.text('Custom Provider 고급 설정'), findsOneWidget);
      await tester.enterText(
        _trTextInput('이름'),
        'E2E Provider',
      );
      await tester.enterText(
        _trTextInput('Base URL'),
        'http://127.0.0.1:${modelServer.port}/unavailable/v1',
      );
      await tester.tap(find.text('API key 필요'));
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await _pumpUntil(tester, find.text('Model 자동 조회 실패'));
      await tester.tap(find.widgetWithText(TRButton, '나중에'));
      await _pumpUntil(tester, find.text('E2E Provider'));
      final degradedProvider = (await remoteClient.listProviderConnections())
          .singleWhere((item) => item.displayName == 'E2E Provider');
      expect(degradedProvider.status, ProviderConnectionStatus.degraded);

      var providerCard = find.ancestor(
        of: find.text('E2E Provider'),
        matching: find.byType(TRCard),
      );
      var providerMenu = find.descendant(
        of: providerCard.first,
        matching: find.byType(TRMenu),
      );
      await tester.tap(providerMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('고급 설정 편집'));
      await tester.pumpAndSettle();
      await tester.enterText(_trTextInput('이름'), 'E2E Provider Edited');
      await tester.enterText(
        _trTextInput('Base URL'),
        'http://127.0.0.1:${modelServer.port}/v1',
      );
      await tester.tap(find.widgetWithText(TRButton, '저장'));
      await _pumpUntil(tester, find.text('E2E Provider Edited'));
      final providerConnection = await _waitForProviderModels(
        remoteClient,
        'E2E Provider Edited',
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
      providerCard = find.ancestor(
        of: find.text('E2E Provider Edited'),
        matching: find.byType(TRCard),
      );
      providerMenu = find.descendant(
        of: providerCard.first,
        matching: find.byType(TRMenu),
      );
      await Scrollable.ensureVisible(
        tester.element(providerMenu),
        alignment: 0.3,
      );
      await tester.pumpAndSettle();
      await tester.tap(providerMenu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '취소'));
      expect(
        (await remoteClient.listProviderConnections()).where(
          (item) => item.id == providerConnection.id,
        ),
        hasLength(1),
      );
      await Scrollable.ensureVisible(
        tester.element(providerMenu),
        alignment: 0.3,
      );
      await tester.pumpAndSettle();
      await tester.tap(providerMenu.hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TRButton, '삭제'));
      await _pumpUntilCondition(
        tester,
        () async => (await remoteClient.listProviderConnections()).every(
          (item) => item.id != providerConnection.id,
        ),
        'custom provider to be deleted',
      );

      final addDeepSeek = find.byKey(const ValueKey('provider-add-deepseek'));
      await tester.ensureVisible(addDeepSeek);
      await tester.tap(addDeepSeek);
      await tester.pumpAndSettle();
      await tester.enterText(_trTextInput('API key'), 'invalid-key');
      await tester.tap(find.widgetWithText(TRButton, '연결'));
      await _pumpUntilCondition(
        tester,
        () async {
          final matches = (await remoteClient.listProviderConnections())
              .where((item) => item.id == 'deepseek')
              .toList();
          return matches.isNotEmpty &&
              matches.single.status == ProviderConnectionStatus.error;
        },
        'invalid provider credential to be rejected',
      );
      expect(find.textContaining('credential rejected'), findsOneWidget);
      await _disconnectProviderCard(tester, 'DeepSeek');
      await _pumpUntilCondition(
        tester,
        () async =>
            (await remoteClient.listProviderConnections())
                .singleWhere((item) => item.id == 'deepseek')
                .status ==
            ProviderConnectionStatus.disconnected,
        'failed provider to disconnect',
      );

      await tester.ensureVisible(addDeepSeek);
      await tester.tap(addDeepSeek);
      await tester.pumpAndSettle();
      await tester.enterText(_trTextInput('API key'), 'valid-key');
      await tester.tap(find.widgetWithText(TRButton, '연결'));
      await _pumpUntilCondition(
        tester,
        () async {
          final matches = (await remoteClient.listProviderConnections())
              .where((item) => item.id == 'deepseek')
              .toList();
          return matches.isNotEmpty &&
              matches.single.status == ProviderConnectionStatus.connected;
        },
        'corrected provider credential to connect',
      );
      await _disconnectProviderCard(tester, 'DeepSeek');

      final addOllama = find.byKey(const ValueKey('provider-add-ollama'));
      await tester.ensureVisible(addOllama);
      await tester.tap(addOllama);
      await _pumpUntilCondition(
        tester,
        () async {
          final matches = (await remoteClient.listProviderConnections())
              .where((item) => item.id == 'ollama')
              .toList();
          return matches.isNotEmpty &&
              matches.single.status == ProviderConnectionStatus.connected &&
              matches.single.credentialOrigin == ProviderCredentialOrigin.none;
        },
        'no-auth provider to connect',
      );
      await _disconnectProviderCard(tester, 'Ollama');
      await _pumpUntilCondition(
        tester,
        () async => (await remoteClient.listProviderConnections())
            .where(
              (item) =>
                  (item.id == 'deepseek' || item.id == 'ollama') &&
                  item.status == ProviderConnectionStatus.connected,
            )
            .isEmpty,
        'connected providers to finish disconnecting',
      );
      final remainingConnections = await remoteClient.listProviderConnections();
      expect(
        remainingConnections.where(
          (item) =>
              (item.id == 'deepseek' || item.id == 'ollama') &&
              item.status == ProviderConnectionStatus.connected,
        ),
        isEmpty,
      );
      expect(
        remainingConnections.singleWhere((item) => item.id == 'openai').status,
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
      await tester.enterText(
        find.byKey(const ValueKey('session-composer-input')),
        'Directory e2e',
      );
      await tester.tap(find.byKey(const ValueKey('session-composer-send')));
      await _pumpUntilCondition(
        tester,
        () async => (await setupClient.listSessions(
          worktreeId: 'directory-checkout-e2e',
        )).any((session) => session.title == 'Directory e2e'),
        'the directory checkout session to start',
      );
      final directoryWorktrees = (await setupClient.getWorkspaceCatalog())
          .worktrees
          .where((item) => item.workspaceId == 'directory-workspace-e2e');
      expect(directoryWorktrees.single.id, 'directory-checkout-e2e');
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
      'feature_test__mcp_server_management__e2e',
      'feature_test__skill_management__e2e',
      'feature_test__agent_delegation__e2e',
      'feature_test__provider_catalog__e2e',
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
      'feature_scenario__skill_invocation__enabled_injection_and_load__e2e',
      'feature_scenario__skill_invocation__disabled_skill_excluded__e2e',
      'feature_scenario__agent_delegation__allowlisted_child_navigation__e2e',
      'feature_scenario__agent_delegation__disallowed_delegation_rejected__e2e',
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
      await tray.install(menu: menu, onSelected: (_) {});
      await tray.update(menu);
      expect(const NativeAttachmentInput(), isA<AttachmentInputPort>());
      expect(const NativeAttachmentExport(), isA<AttachmentExportPort>());

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
      'feature_test__conversation_attachments__platformSmoke',
      'feature_scenario__desktop_residency__close_hide_restore__e2e',
      'feature_scenario__desktop_window_chrome__native_window_controls__e2e',
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
  Future<List<PendingAttachment>> droppedFiles(PerformDropEvent event) async =>
      const <PendingAttachment>[];
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
  final dropdown = find.byKey(
    const ValueKey<String>('settings-daemon-select'),
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

Future<void> _disconnectProviderCard(
  WidgetTester tester,
  String displayName,
) async {
  final card = find.ancestor(
    of: find.text(displayName),
    matching: find.byType(TRCard),
  );
  final menu = find.descendant(of: card.first, matching: find.byType(TRMenu));
  await _pumpUntil(tester, menu);
  await Scrollable.ensureVisible(tester.element(menu), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text('연결 해제'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TRButton, '연결 해제'));
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilTextFieldValue(
  WidgetTester tester,
  Finder finder,
  String value, {
  int attempts = 100,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    final fields = tester.widgetList<EditableText>(finder);
    if (fields.any((field) => field.controller.text == value)) return;
  }
  throw TestFailure('Timed out waiting for text field value "$value".');
}

Finder _trTextInput(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is TRTextField && widget.label == label,
    description: 'TRTextField labelled "$label"',
  ),
  matching: find.byType(EditableText),
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

Future<void> _runGit(String path, List<String> arguments) async {
  final result = await Process.run('git', arguments, workingDirectory: path);
  if (result.exitCode != 0) {
    throw TestFailure('git ${arguments.join(' ')} failed: ${result.stderr}');
  }
}

String _fakeMcpServerPath() {
  final suffix = <String>[
    'packages',
    'coder_daemon',
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

Future<void> _waitForComposerReady(
  WidgetTester tester,
  ValueKey<String> sendKey,
) => _pumpUntilCondition(
  tester,
  () => tester.widget<TRIconButton>(find.byKey(sendKey)).onPressed != null,
  'the composer to accept another turn',
);

Future<void> _submitComposerPrompt(
  WidgetTester tester,
  ValueKey<String> composerKey,
  ValueKey<String> sendKey,
  String prompt,
) async {
  await _waitForComposerReady(tester, sendKey);
  final composer = find.byKey(composerKey);
  final input = find.descendant(
    of: composer,
    matching: find.byType(EditableText),
  );
  await tester.tap(input);
  await tester.pump();
  tester.testTextInput.enterText(prompt);
  await tester.pump();
  expect(tester.widget<TRTextField>(composer).controller?.text, prompt);
  await tester.tap(find.byKey(sendKey));
  await tester.pump();
}

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

final class _E2eModelDiscovery implements ProviderModelDiscovery {
  const _E2eModelDiscovery();

  @override
  Future<List<String>> fetchModelIds(
    ProviderRuntimeConfig config,
    ProviderCredential? credential,
  ) async {
    if (config.baseUrl.contains('/unavailable/')) {
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

  @override
  String get id => 'agent-e2e-fake';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) async* {
    cancellation.throwIfCancelled();
    final latestUser = request.history.whereType<UserConversationItem>().last;
    final latestPrompt = latestUser.text;
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
              ConversationToolCall(
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
    final hasDisallowedDelegationResult = request.history
        .whereType<ToolResultConversationItem>()
        .any((item) => item.callId == 'disallowed-delegate-call');

    if (latestPrompt == 'Disallowed delegation' &&
        !hasDisallowedDelegationResult) {
      const arguments = <String, dynamic>{
        'agentDefinitionId': 'not-allowed',
        'prompt': 'This delegation must not start.',
      };
      yield const ModelFunctionCall(
        callId: 'disallowed-delegate-call',
        name: 'delegate_agent',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'disallowed-delegate-call',
              name: 'delegate_agent',
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

    if (latestPrompt == 'Use E2E skill' && !hasSkillResult) {
      if (!request.instructions.contains(
            '- invoke-e2e: Loaded during an end-to-end turn.',
          ) ||
          request.instructions.contains('- commit:')) {
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
            ConversationToolCall(
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
      if (request.instructions.contains('- invoke-e2e:') ||
          request.instructions.contains('- commit:')) {
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
            ConversationToolCall(
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
            ConversationToolCall(
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
    if (latestPrompt == 'Reject result.txt' && !hasRejectedPatchResult) {
      const arguments = <String, dynamic>{
        'patch': '--- /dev/null\n+++ b/rejected.txt\n@@ -0,0 +1,1 @@\n+nope\n',
      };
      yield const ModelFunctionCall(
        callId: 'reject-patch-call',
        name: 'apply_patch',
        arguments: arguments,
      );
      yield const ModelResponseCompleted(
        assistant: AssistantConversationItem(
          text: '',
          toolCalls: <ConversationToolCall>[
            ConversationToolCall(
              callId: 'reject-patch-call',
              name: 'apply_patch',
              arguments: arguments,
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
