import 'dart:io';

import 'package:agent/agent.dart';
import 'package:client/client.dart';
import 'package:daemon/daemon.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'real daemon persists goal RPC state and notifications across restart',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-goal-home-');
      final userHome = await Directory.systemTemp.createTemp(
        'coder-goal-user-',
      );
      const token = 'goal-token-0123456789abcdef0123456789';
      final config = DaemonConfig(
        homeDirectory: home.path,
        userHomeDirectory: userHome.path,
        port: 0,
        bearerToken: token,
        useEnvironmentCredentials: false,
      );
      DaemonHandle? handle;
      CoderClient? client;
      try {
        handle = await DaemonApplication.start(config, provider: _NoModel());
        client = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
          credentials: const DaemonCredentials(bearerToken: token),
          clientId: 'goal-first',
          clientKind: 'test',
        );
        final catalog = await client.workspaces.getWorkspaceCatalog();
        final homeWorkspace = catalog.workspaces.singleWhere(
          (workspace) => workspace.kind == WorkspaceKind.home,
        );
        final checkout = catalog.worktrees.singleWhere(
          (worktree) => worktree.workspaceId == homeWorkspace.id,
        );
        final session = await client.sessions.createSession(
          id: 'goal-session',
          worktreeId: checkout.id,
          title: 'Goal session',
          agentDefinitionId: 'coder',
          mode: SessionMode.plan,
        );
        final update = client.sessions.goalUpdates.first;
        final goal = await client.sessions.replaceGoal(
          sessionId: session.id,
          objective: 'Persist and reconnect',
          tokenBudget: 1000,
        );
        expect(await update, goal);
        expect(
          (await client.sessions.getGoal(session.id))?.goalId,
          goal.goalId,
        );
        await client.close();
        client = null;
        await handle.stop();
        handle = null;

        handle = await DaemonApplication.start(config, provider: _NoModel());
        client = await CoderClient.connect(
          endpoint: HostEndpoint(websocketUri: handle.boundEndpoint),
          credentials: const DaemonCredentials(bearerToken: token),
          clientId: 'goal-second',
          clientKind: 'test',
        );
        expect(await client.sessions.getGoal(session.id), goal);
        expect(await client.sessions.clearGoal(session.id), isTrue);
        expect(await client.sessions.getGoal(session.id), isNull);
      } finally {
        await client?.close();
        await handle?.stop();
        await home.delete(recursive: true);
        await userHome.delete(recursive: true);
      }
    },
    tags: const <String>['feature_test__session_goal__verticalSlice'],
  );
}

final class _NoModel implements ModelProvider {
  @override
  String get id => 'goal-test';

  @override
  Stream<ModelEvent> stream(
    ModelRequest request,
    CancellationToken cancellation,
  ) => const Stream<ModelEvent>.empty();
}
