@Tags(<String>['feature_test__terminal_lifecycle__widget'])
library;

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/terminals/presentation/coder_terminal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../../support/build_phase_provider_guard.dart';
import '../../support/fake_coder_api.dart';
import '../../support/router_harness.dart';

final _now = DateTime.utc(2026, 8, 11);
final _workspace = WorkspaceDto(
  id: 'workspace',
  name: 'Coder',
  rootPath: '/repos/coder',
  kind: WorkspaceKind.git,
  createdAt: _now,
);

WorktreeDto _worktree(String id, String branch) => WorktreeDto(
  id: id,
  workspaceId: _workspace.id,
  name: branch,
  path: '/repos/coder-$id',
  branch: branch,
  head: 'abc',
  kind: WorktreeKind.checkout,
  isCoderOwned: false,
  createdAt: _now,
);

TerminalDto _terminal(String id, String worktreeId) => TerminalDto(
  id: id,
  worktreeId: worktreeId,
  title: id,
  shell: const ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

String _terminalLocation(String worktreeId, String terminalId) => TerminalRoute(
  hostId: 'server',
  workspaceId: _workspace.id,
  worktreeId: worktreeId,
  terminalId: terminalId,
).location;

String _worktreeLocation(String worktreeId) => WorktreeRoute(
  hostId: 'server',
  workspaceId: _workspace.id,
  worktreeId: worktreeId,
).location;

FakeCoderApi _api() => FakeCoderApi(
  workspaces: <WorkspaceDto>[_workspace],
  worktrees: <WorktreeDto>[
    _worktree('checkout-a', 'main'),
    _worktree('checkout-b', 'feature'),
  ],
  terminals: <TerminalDto>[
    _terminal('terminal-a', 'checkout-a'),
    _terminal('terminal-b', 'checkout-b'),
  ],
);

/// Everything the on-screen emulator currently holds, scrollback included.
String _screen(WidgetTester tester) {
  final view = tester.widget<CoderTerminalView>(find.byType(CoderTerminalView));
  final buffer = view.terminal.buffer.active;
  return <String>[
    for (var line = 0; line < buffer.length; line += 1)
      buffer.translateBufferLineToString(line, trimRight: true),
  ].join('\n');
}

/// Pumps until the emulator's asynchronous write buffer has been parsed.
Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('leaving a checkout with an open terminal raises nothing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api();
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _terminalLocation('checkout-a', 'terminal-a'),
    );
    addTearDown(router.dispose);

    api.emitTerminalOutput('terminal-a', 'hello-before');
    await _flush(tester);
    expect(_screen(tester), contains('hello-before'));

    // Every workspace location shares one Navigator page, so this is a widget
    // update rather than a push, and the departing checkout's clean-up runs
    // inside the build phase.
    router.go(_worktreeLocation('checkout-b'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // The framework error can only name `UncontrolledProviderScope`, so it never
  // says which provider was written. The observer does.
  testWidgets('leaving a checkout mutates no provider during the build', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api();
    final guard = BuildPhaseProviderGuard();
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _terminalLocation('checkout-a', 'terminal-a'),
      observers: <ProviderObserver>[guard],
    );
    addTearDown(router.dispose);
    await _flush(tester);

    guard.violations.clear();
    router.go(_worktreeLocation('checkout-b'));
    await tester.pumpAndSettle();
    // Drains the build-phase error so the guard's report is what fails.
    tester.takeException();

    expect(guard.violations, isEmpty);
  });
}
