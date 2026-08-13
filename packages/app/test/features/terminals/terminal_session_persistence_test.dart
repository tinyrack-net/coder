@Tags(<String>['feature_test__terminal_lifecycle__widget'])
library;

import 'dart:async';

import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/terminals/presentation/tinest_terminal_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/router_harness.dart';

final _now = DateTime.utc(2026, 8, 10);
final _workspace = WorkspaceDto(
  id: 'workspace',
  name: 'Tinest',
  rootPath: '/repos/tinest',
  kind: WorkspaceKind.git,
  createdAt: _now,
);
final _worktree = WorktreeDto(
  id: 'checkout',
  workspaceId: 'workspace',
  name: 'main',
  path: '/repos/tinest',
  branch: 'main',
  head: 'abc',
  kind: WorktreeKind.checkout,
  isTinestOwned: false,
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

FakeTinestApi _api() => FakeTinestApi(
  workspaces: <WorkspaceDto>[_workspace],
  worktrees: <WorktreeDto>[_worktree],
  terminals: <TerminalDto>[_terminal('terminal-a'), _terminal('terminal-b')],
);

/// Everything the on-screen emulator currently holds, scrollback included.
String _screen(WidgetTester tester) {
  final view = tester.widget<TinestTerminalView>(
    find.byType(TinestTerminalView),
  );
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

  // Characterization. `WorkspacePage` justifies keeping terminal sessions alive
  // with "a trip to settings tears this page down, and coming back must not
  // find every terminal wiped". Whether the page really is torn down decides
  // where a session's lifetime may be rooted, so it is pinned rather than
  // trusted: the pushed settings route is opaque, and the workspace page below
  // it stays mounted.
  testWidgets('the workspace page stays mounted behind pushed settings', (
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

    await tester.tap(
      find.byKey(const ValueKey<String>('workspace-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TinestTerminalView), findsNothing);
    expect(
      find.byType(TinestTerminalView, skipOffstage: false),
      findsOneWidget,
    );

    router.pop();
    await _flush(tester);

    expect(_screen(tester), contains('hello-before'));
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

  // Input being dropped *during* the paint is asserted in the controller's
  // own tests, where the barrier is observable. What matters here is the
  // frame the user ends up looking at: the screen is back and the terminal is
  // live again rather than left read-only.
  testWidgets('a restored terminal shows the screen and is live again', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _api()..terminalAttachGate = Completer<void>();
    api.terminalSnapshotAnsi['terminal-a'] = 'restored-screen';
    api.emitTerminalOutput('terminal-a', 'seed');
    final router = await pumpRoutedApp(
      tester,
      api,
      initialLocation: _location('terminal-a'),
      // The connecting overlay animates until the gate opens.
      settle: false,
    );
    addTearDown(router.dispose);

    api.terminalAttachGate!.complete();
    await _flush(tester);

    expect(_screen(tester), contains('restored-screen'));
    // The barrier has lifted by the time the paint finished, so the terminal
    // is live again and the user is not left with a dead prompt.
    expect(
      tester
          .widget<TinestTerminalView>(find.byType(TinestTerminalView))
          .readOnly,
      isFalse,
    );
  });
}
