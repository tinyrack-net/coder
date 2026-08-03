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
      final coder = await setupClient.getAgentDefinition('coder');
      final reviewer = await setupClient.createAgentDefinition(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          description: 'Read-only E2E reviewer',
          mode: AgentMode.subagent,
          systemPrompt: 'Review the current change.',
          permissionMode: PermissionMode.readOnly,
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      await setupClient.updateAgentDefinition(
        coder.copyWith(callableAgentIds: const <String>['reviewer']),
        expectedContentHash: coder.contentHash,
      );
      final reviewerFile = File(reviewer.sourcePath);
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
      final remoteSetupClient = await CoderClient.connect(
        endpoint: HostEndpoint(websocketUri: remoteHandle.boundEndpoint),
        credentials: const DaemonCredentials(
          bearerToken: 'remote-token-0123456789abcdef0123456789',
        ),
        clientId: 'remote-e2e-setup',
        clientKind: 'integration-test',
      );
      await remoteSetupClient.registerWorkspace(
        workspaceId: 'remote-workspace-e2e',
        checkoutId: 'remote-checkout-e2e',
        rootPath: remoteWorkspace.path,
        name: 'Remote Workspace',
      );
      await remoteSetupClient.close();

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
      await _pumpUntil(tester, find.text('Remote Workspace'));
      await tester.tap(find.text('E2E Workspace').last);
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        find.text(workspace.path),
      );
      await tester.tap(find.text('E2E Workspace').last);
      await _pumpUntil(tester, find.text('새 session 시작'));
      await tester.tap(find.text('새 session 시작'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('생성'));
      await _pumpUntil(tester, find.text('코딩 요청을 입력하세요.'));

      await tester.enterText(find.byType(TextField).last, 'Delegate review');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
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
      await tester.testTextInput.receiveAction(TextInputAction.done);
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
    },
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
