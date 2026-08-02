import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:coder_client/coder_client.dart';
import 'package:coder_daemon/coder_daemon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'embedded daemon streams, approves a patch, and restores timeline',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final home = await Directory.systemTemp.createTemp('coder-e2e-home-');
      final workspace = await Directory.systemTemp.createTemp(
        'coder-e2e-workspace-',
      );
      final handle = await EmbeddedDaemonHandle.start(
        DaemonConfig(
          homeDirectory: home.path,
          port: 0,
          bearerToken: 'e2e-token-0123456789abcdef0123456789',
        ),
        provider: _PatchProvider(),
      );
      addTearDown(() async {
        await handle.stop();
        if (home.existsSync()) home.deleteSync(recursive: true);
        if (workspace.existsSync()) workspace.deleteSync(recursive: true);
      });
      final endpoint = HostEndpoint(
        websocketUri: handle.boundEndpoint,
        token: handle.bearerToken,
      );
      final setupClient = await CoderClient.connect(
        endpoint: endpoint,
        clientId: 'e2e-setup',
        clientKind: 'integration-test',
      );
      await setupClient.registerWorkspace(
        id: 'workspace-e2e',
        rootPath: workspace.path,
        name: 'E2E Workspace',
      );
      await setupClient.close();

      await tester.pumpWidget(
        CoderApp(
          bootstrap: DesktopBootstrap(
            launcher: _ExistingLauncher(handle),
          ),
        ),
      );
      await _pumpUntil(tester, find.text('E2E Workspace'));
      await tester.tap(find.text('E2E Workspace'));
      await _pumpUntil(tester, find.text('새 agent를 만들어 시작하세요.'));
      await tester.tap(find.byTooltip('Agent 생성'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('생성'));
      await _pumpUntil(
        tester,
        find.text('요청을 입력해 coding agent를 시작하세요.'),
      );

      await tester.enterText(find.byType(TextField).last, 'Create result.txt');
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
        clientId: 'e2e-reconnect',
        clientKind: 'integration-test',
      );
      final agents = await reconnected.listAgents(workspaceId: 'workspace-e2e');
      expect(agents, hasLength(1));
      final timeline = await reconnected.subscribeTimeline(agents.single.id);
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
  String get bearerToken => handle.bearerToken;

  @override
  Uri get boundEndpoint => handle.boundEndpoint;

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
