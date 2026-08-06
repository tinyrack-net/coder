@Tags(<String>['feature_test__terminal_lifecycle__widget'])
library;

import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

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
const _terminal = TerminalDto(
  id: 'terminal-shortcuts',
  worktreeId: 'checkout',
  title: 'Remote terminal',
  shell: ShellSpecDto(executable: '/bin/sh'),
  status: TerminalStatus.running,
  columns: 80,
  rows: 24,
  lastSequence: 0,
);

/// Sends one chord to whatever holds focus.
Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  required bool shift,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyDownEvent(key);
  await tester.sendKeyUpEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  testWidgets(
    'a focused terminal keeps control chords and yields the shifted ones',
    (tester) async {
      final fired = <String>[];
      final api = FakeCoderApi(
        workspaces: <WorkspaceDto>[_workspace],
        worktrees: <WorktreeDto>[_worktree],
        terminals: const <TerminalDto>[_terminal],
        terminalReplay: const <TerminalOutputDto>[
          TerminalOutputDto(
            terminalId: 'terminal-shortcuts',
            sequence: 1,
            data: 'output',
          ),
        ],
      );
      final router = GoRouter(
        initialLocation: TerminalRoute(
          hostId: 'server',
          workspaceId: _workspace.id,
          worktreeId: _worktree.id,
          terminalId: _terminal.id,
        ).location,
        routes: $appRoutes,
      );
      addTearDown(router.dispose);

      // Stands in for the application bindings that DesktopShellScope installs
      // above the router, which is the position that makes them lose to a
      // focused terminal.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(
                  LogicalKeyboardKey.keyB,
                  control: true,
                  shift: true,
                ): () =>
                    fired.add('toggle-sidebar'),
                const SingleActivator(
                  LogicalKeyboardKey.keyN,
                  control: true,
                  shift: true,
                ): () =>
                    fired.add('new-workspace'),
              },
              child: Router<Object>.withConfig(config: router),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.keyB, shift: true);
      await _press(tester, LogicalKeyboardKey.keyN, shift: true);

      expect(fired, <String>['toggle-sidebar', 'new-workspace']);
      expect(
        api.terminalWrites,
        isEmpty,
        reason: 'a reserved application chord must not reach the program',
      );

      await _press(tester, LogicalKeyboardKey.keyB, shift: false);
      await _press(tester, LogicalKeyboardKey.keyN, shift: false);

      // Control with a letter stays with the program: Control+B is the default
      // tmux prefix and Control+Q is flow control, so the shell needs them.
      expect(fired, <String>['toggle-sidebar', 'new-workspace']);
      expect(
        api.terminalWrites.map((write) => write.data).join().codeUnits,
        <int>[0x02, 0x0E],
      );
    },
  );
}
