import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
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
      final handle = await EmbeddedDaemonHandle.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'e2e-token-0123456789abcdef0123456789',
          useEnvironmentCredentials: false,
        ),
        provider: _AgentE2eProvider(),
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
        await handle.stop();
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
          adminToken: handle.adminToken,
        ),
        clientId: 'e2e-setup',
        clientKind: 'integration-test',
      );
      addTearDown(setupClient.close);
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

      await tester.pumpWidget(
        CoderApp(
          services: AppServices(
            settings: appStore,
            profiles: appStore,
            credentials: appStore,
            clients: const WebSocketHostClientFactory(),
            clientKind: 'desktop-integration-test',
            embeddedLauncher: _ExistingLauncher(handle),
          ),
        ),
      );
      await _pumpUntil(tester, find.text('내장 daemon'));
      await _pumpUntil(tester, find.text('Remote daemon'));
      await _pumpUntil(tester, find.text('E2E Workspace'));

      await tester.tap(find.byTooltip('폴더 추가').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('Remote daemon'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Daemon 경로'),
        remoteWorkspace.path,
      );
      await tester.tap(find.widgetWithText(FilledButton, '등록'));
      await tester.pumpAndSettle();
      await _pumpUntilGone(tester, find.text('Daemon의 폴더 선택'));
      final remoteWorkspaceName = remoteWorkspace.path
          .split(Platform.pathSeparator)
          .last;
      await _pumpUntil(tester, find.text(remoteWorkspaceName));

      await tester.tap(find.byTooltip('설정'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agent'));
      await _pumpUntil(tester, find.text('Agents'));
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

      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E2E Workspace').last);
      await tester.pumpAndSettle();
      final newWorktree = find.byTooltip('새 worktree');
      await tester.ensureVisible(newWorktree);
      await tester.tap(newWorktree);
      final branchField = find.widgetWithText(TextField, '새 branch 이름');
      await _pumpUntil(tester, branchField);
      await tester.enterText(branchField, 'feature/e2e');
      await tester.tap(find.widgetWithText(FilledButton, '생성'));
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
      await _pumpUntil(tester, find.text('새 session 시작'));
      await tester.tap(find.text('새 session 시작'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('생성'));
      await _pumpUntil(tester, find.text('코딩 요청을 입력하세요.'));

      await tester.enterText(find.byType(TextField).last, 'Delegate review');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await _pumpUntilWithSessionDiagnostics(
        tester,
        find.text('Parent completed.', findRichText: true),
        setupClient,
      );
      await tester.tap(find.byTooltip('모든 session'));
      await _pumpUntil(tester, find.text('Reviewer'));
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<String>),
          matching: find.text('Reviewer'),
        ),
      );
      await _pumpUntil(tester, find.text('reviewer · delegated'));
      await tester.tap(find.text('Coding session').first);
      await _pumpUntil(tester, find.text('coder · manual'));

      await tester.enterText(find.byType(TextField).last, 'Create result.txt');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_upward));
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

      final reconnected = await CoderClient.connect(
        endpoint: endpoint,
        credentials: DaemonCredentials(
          bearerToken: handle.bearerToken,
          adminToken: handle.adminToken,
        ),
        clientId: 'e2e-reconnect',
        clientKind: 'integration-test',
      );
      final agents = await reconnected.listSessions(worktreeId: 'checkout-e2e');
      expect(agents, hasLength(2));
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
      final providerConnection = (await setupClient.listProviderConnections())
          .singleWhere((item) => item.displayName == 'E2E Provider');
      expect(providerConnection.defaultModelId, 'e2e-model');
      final connectedSection = find.byKey(
        const ValueKey('provider-settings-connected'),
      );
      final addSection = find.byKey(
        const ValueKey('provider-settings-add'),
      );
      expect(
        tester.getBottomRight(connectedSection).dy,
        lessThanOrEqualTo(tester.getTopLeft(addSection).dy),
      );
      final modelSelector = find.byKey(
        ValueKey('model-selector-${providerConnection.id}'),
      );
      await _pumpUntil(tester, modelSelector);
      await tester.ensureVisible(modelSelector);
      await tester.pumpAndSettle();
      await tester.tap(modelSelector);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('model-search-field')),
        'extremely-long',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          ValueKey(
            'model-option-${providerConnection.id}-$selectedModelId',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        (await setupClient.listProviderConnections())
            .singleWhere((item) => item.id == providerConnection.id)
            .defaultModelId,
        selectedModelId,
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
      expect(
        (await setupClient.listProviderConnections())
            .singleWhere((item) => item.id == providerConnection.id)
            .status,
        ProviderConnectionStatus.disconnected,
      );
    },
    tags: const <String>[
      'feature_test__daemon_management__e2e',
      'feature_test__workspace_catalog__e2e',
      'feature_test__workspace_registration__e2e',
      'feature_test__worktree_lifecycle__e2e',
      'feature_test__session_lifecycle__e2e',
      'feature_test__session_tabs__e2e',
      'feature_test__turn_execution__e2e',
      'feature_test__agent_definition_management__e2e',
      'feature_test__agent_delegation__e2e',
      'feature_test__provider_catalog__e2e',
      'feature_test__provider_connection_management__e2e',
      'feature_test__provider_custom__e2e',
    ],
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

Future<void> _selectDaemon(WidgetTester tester, String label) async {
  final dropdown = find.widgetWithText(
    DropdownButtonFormField<String>,
    'Daemon',
  );
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
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

final class _ExistingLauncher implements EmbeddedDaemonLauncher {
  const _ExistingLauncher(this.handle);

  final EmbeddedDaemonHandle handle;

  @override
  Future<EmbeddedDaemonSession> start() async => _ExistingSession(handle);
}

final class _ExistingSession implements EmbeddedDaemonSession {
  const _ExistingSession(this.handle);

  final EmbeddedDaemonHandle handle;

  @override
  DaemonCredentials get credentials => DaemonCredentials(
    bearerToken: handle.bearerToken,
    adminToken: handle.adminToken,
  );

  @override
  HostEndpoint get endpoint => HostEndpoint(
    websocketUri: handle.boundEndpoint,
  );

  @override
  String get serverId => handle.serverId;

  @override
  Future<void> stop() => handle.stop();
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
