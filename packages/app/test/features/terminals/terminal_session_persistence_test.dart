@Tags(<String>['feature_test__terminal_lifecycle__widget'])
library;

import 'dart:async';

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/terminals/presentation/coder_terminal_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_coder_api.dart';
import '../../support/router_harness.dart';

final _now = DateTime.utc(2026, 8, 10);
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

FakeCoderApi _api() => FakeCoderApi(
  workspaces: <WorkspaceDto>[_workspace],
  worktrees: <WorktreeDto>[_worktree],
  terminals: <TerminalDto>[_terminal('terminal-a'), _terminal('terminal-b')],
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
  testWidgets('terminal content survives a round trip to another tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api();
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _location('terminal-a'),
    );
    addTearDown(router.dispose);

    api.emitTerminalOutput('terminal-a', 'hello-before');
    await _flush(tester);
    expect(_screen(tester), contains('hello-before'));

    router.go(_location('terminal-b'));
    await tester.pumpAndSettle();
    router.go(_location('terminal-a'));
    await _flush(tester);

    // The emulator outlives the pane, so the scrollback is still the one the
    // user was looking at rather than whatever the daemon can still replay.
    expect(_screen(tester), contains('hello-before'));
    expect(api.attachedTerminalIds, <String>['terminal-a', 'terminal-b']);
  });

  testWidgets('output produced while the tab is hidden is not lost', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api();
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _location('terminal-a'),
    );
    addTearDown(router.dispose);

    router.go(_location('terminal-b'));
    await tester.pumpAndSettle();
    api.emitTerminalOutput('terminal-a', 'while-hidden');
    await tester.pumpAndSettle();
    router.go(_location('terminal-a'));
    await _flush(tester);

    expect(_screen(tester), contains('while-hidden'));
    expect(api.attachedTerminalIds, <String>['terminal-a', 'terminal-b']);
  });

  testWidgets('output published during the attach round trip arrives once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api()..terminalAttachGate = Completer<void>();
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _location('terminal-a'),
      // The connecting spinner animates until the gate opens.
      settle: false,
    );
    addTearDown(router.dispose);

    // The chunk is broadcast while the attach RPC is still in flight, so it is
    // in neither the server snapshot nor a subscription created afterwards.
    api.emitTerminalOutput('terminal-a', 'mid-attach');
    api.terminalAttachGate!.complete();
    await _flush(tester);

    expect('mid-attach'.allMatches(_screen(tester)), hasLength(1));
  });
}
