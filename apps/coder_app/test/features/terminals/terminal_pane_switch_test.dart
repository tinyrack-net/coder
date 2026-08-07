@Tags(<String>['feature_test__terminal_lifecycle__widget'])
library;

import 'package:coder_app/src/app/composition/app_providers.dart';
import 'package:coder_app/src/app/router/app_router.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_coder_api.dart';
import '../../support/localization.dart';

final _now = DateTime.utc(2026, 8, 3);
final _workspace = WorkspaceDto(
  id: 'workspace',
  name: 'Coder',
  rootPath: '/repos/coder',
  kind: WorkspaceKind.git,
  createdAt: _now,
);
final _worktree = WorktreeDto(
  id: 'checkout',
  workspaceId: 'workspace',
  name: 'main',
  path: '/repos/coder',
  branch: 'main',
  head: 'abc',
  kind: WorktreeKind.checkout,
  isCoderOwned: false,
  createdAt: _now,
);

TerminalDto _terminal(String id) => TerminalDto(
  id: id,
  worktreeId: 'checkout',
  title: id,
  shell: const ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

String _location(String terminalId) => TerminalRoute(
  hostId: 'server',
  workspaceId: _workspace.id,
  worktreeId: _worktree.id,
  terminalId: terminalId,
).location;

void main() {
  testWidgets('switching terminal tabs attaches the terminal switched to', (
    tester,
  ) async {
    final api = FakeCoderApi(
      workspaces: <WorkspaceDto>[_workspace],
      worktrees: <WorktreeDto>[_worktree],
      terminals: <TerminalDto>[
        _terminal('terminal-a'),
        _terminal('terminal-b'),
      ],
      terminalReplay: const <TerminalOutputDto>[
        TerminalOutputDto(
          terminalId: 'terminal-a',
          sequence: 1,
          data: 'output',
        ),
      ],
    );
    final router = GoRouter(
      initialLocation: _location('terminal-a'),
      routes: $appRoutes,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appServicesProvider.overrideWithValue(fakeAppServices(api)),
        ],
        child: MaterialApp.router(
          theme: testLightTheme,
          locale: testLocale,
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.attachedTerminalIds, <String>['terminal-a']);

    router.go(_location('terminal-b'));
    await tester.pumpAndSettle();

    // The pane's state owns the attachment, so an unkeyed pane would be reused
    // here and the second terminal would never be attached to at all.
    expect(api.attachedTerminalIds, <String>['terminal-a', 'terminal-b']);
  });
}
