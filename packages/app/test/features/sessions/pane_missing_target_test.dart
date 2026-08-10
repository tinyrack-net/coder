import 'package:app/src/app/router/app_router.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_coder_api.dart';
import '../../support/router_harness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 10);
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
  final agent = SessionDto(
    id: 'one',
    worktreeId: checkout.id,
    title: 'Session one',
    agentDefinitionId: 'coder',
    origin: SessionOrigin.manual,
    status: SessionStatus.idle,
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'a daemon that drops mid-session keeps its tab instead of throwing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[workspace],
        worktrees: <WorktreeDto>[checkout],
        agents: <SessionDto>[agent],
      );
      final router = await pumpRoutedApp(
        tester,
        api,
        initialLocation: SessionRoute(
          hostId: 'server',
          workspaceId: workspace.id,
          worktreeId: checkout.id,
          sessionId: agent.id,
        ).location,
      );
      addTearDown(router.dispose);
      expect(find.text('Session one'), findsWidgets);

      // The daemon drops. Its catalogs stop answering, but the tab the user
      // opened is still on screen and must not take the pane down with it.
      api.emitState(ClientConnectionState.disconnected);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
      // The tab keeps naming the session it was opened on, so reconnecting
      // lands the user back where they were instead of on a blank pane.
      expect(find.text('Session one'), findsWidgets);
    },
    tags: const <String>['feature_test__session_tabs__widget'],
  );
}
