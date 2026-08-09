import 'dart:async';

import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/desktop/domain/tray_menu_model.dart';
import 'package:app/src/features/desktop/presentation/desktop_shell_scope.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:client/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_desktop_ports.dart';
import '../../support/localization.dart';

void main() {
  ({
    Widget app,
    FakeDesktopWindow window,
    FakeTrayIcon tray,
    FakeAppTerminator terminator,
    MemoryAppStore store,
  })
  build({
    String? localeTag,
    bool startHidden = false,
    Completer<void>? installGate,
    EmbeddedDaemonLauncher? embeddedLauncher,
  }) {
    final store = MemoryAppStore(
      settings: AppSettings(
        embeddedDaemonEnabled: embeddedLauncher != null,
        localeTag: localeTag,
      ),
    );
    final window = FakeDesktopWindow();
    final tray = FakeTrayIcon(installGate: installGate)..calls = window.calls;
    final terminator = FakeAppTerminator(calls: window.calls);
    return (
      app: CoderApp(
        services: AppServices(
          settings: store,
          profiles: store,
          credentials: store,
          clients: const _OfflineClients(),
          clientKind: 'test',
          embeddedLauncher: embeddedLauncher,
        ),
        desktopWindow: window,
        trayIcon: tray,
        terminator: terminator,
        autostart: FakeAutostartRegistration(),
        startHidden: startHidden,
      ),
      window: window,
      tray: tray,
      terminator: terminator,
      store: store,
    );
  }

  testWidgets(
    'closing the window hides it and leaves the process running',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(harness.window.preventingClose, isTrue);
      expect(harness.tray.installs, 1);
      expect(
        harness.tray.menu.entries
            .firstWhere((entry) => entry.key == trayItemToggleWindow)
            .label,
        testL10n.trayHideWindow,
      );

      harness.window.requestClose();
      await tester.pumpAndSettle();

      expect(harness.window.hides, 1);
      expect(harness.terminator.terminations, 0);
      expect(harness.window.visible, isFalse);
      // The tray now offers to bring the window back.
      expect(
        harness.tray.menu.entries
            .firstWhere((entry) => entry.key == trayItemToggleWindow)
            .label,
        testL10n.trayShowWindow,
      );
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'the tray toggles the window and never quits by accident',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.tray.select(trayItemToggleWindow);
      await tester.pumpAndSettle();
      expect(harness.window.visible, isFalse);
      expect(harness.window.hides, 1);

      harness.tray.select(trayItemToggleWindow);
      await tester.pumpAndSettle();
      expect(harness.window.visible, isTrue);
      expect(harness.window.shows, 1);

      // Selecting the informational daemon row must do nothing at all.
      harness.tray.select(trayItemDaemonStatus);
      await tester.pumpAndSettle();
      expect(harness.window.hides, 1);
      expect(harness.window.shows, 1);
      expect(harness.terminator.terminations, 0);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'clicking the tray icon reveals the window and repeating it keeps it up',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.window.requestClose();
      await tester.pumpAndSettle();
      expect(harness.window.visible, isFalse);

      harness.tray.activate();
      await tester.pumpAndSettle();
      expect(harness.window.visible, isTrue);
      expect(harness.window.shows, 1);
      expect(
        harness.tray.menu.entries
            .firstWhere((entry) => entry.key == trayItemToggleWindow)
            .label,
        testL10n.trayHideWindow,
      );

      // Windows reports a double click as two icon clicks. Showing has to be
      // idempotent, or the second click would hide what the first revealed.
      harness.tray.activate();
      await tester.pumpAndSettle();
      expect(harness.window.visible, isTrue);
      expect(harness.window.hides, 1);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'the tray settings row reveals the window on the general settings page',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.window.requestClose();
      await tester.pumpAndSettle();
      expect(harness.window.visible, isFalse);

      harness.tray.select(trayItemOpenSettings);
      await tester.pumpAndSettle();

      expect(harness.window.visible, isTrue);
      expect(find.text(testL10n.generalLanguageLabel), findsOneWidget);
      expect(find.text(testL10n.generalStartupAtBootLabel), findsOneWidget);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'quitting hides the window, stops the daemon, and ends the process',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.tray.select(trayItemQuit);
      await tester.pumpAndSettle();

      expect(harness.tray.destroys, 1);
      expect(harness.terminator.terminations, 1);
      expect(harness.window.visible, isFalse);
      expect(harness.window.preventingClose, isFalse);
      // The window leaves the screen first so quit feels immediate, and the
      // process only ends once the teardown that needs it has run.
      expect(
        harness.window.calls,
        containsAllInOrder(<String>[
          'hide',
          'destroyTray',
          'releaseClose',
          'terminate',
        ]),
      );

      // A second selection must not tear anything down twice.
      harness.tray.select(trayItemQuit);
      await tester.pumpAndSettle();
      expect(harness.terminator.terminations, 1);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'quitting ends the process even when stopping the daemon fails',
    (tester) async {
      final harness = build(
        embeddedLauncher: const _StubLauncher(_StubSession.failing()),
      );
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.tray.select(trayItemQuit);
      await tester.pumpAndSettle();

      expect(harness.terminator.terminations, 1);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'quitting ends the process when the daemon never stops',
    (tester) async {
      final harness = build(
        embeddedLauncher: const _StubLauncher(_StubSession.hanging()),
      );
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      harness.tray.select(trayItemQuit);
      await tester.pump();
      // A daemon that will not stop must not hold the app on screen forever.
      expect(harness.terminator.terminations, 0);

      await tester.pump(quitBudget);
      expect(harness.terminator.terminations, 1);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'the tray menu follows the language and ignores idle rebuilds',
    (tester) async {
      final english = build(localeTag: 'en');
      await tester.pumpWidget(english.app);
      await tester.pumpAndSettle();

      String quitLabel(FakeTrayIcon tray) => tray.menu.entries
          .firstWhere((entry) => entry.key == trayItemQuit)
          .label;

      // The stored language wins over the platform locale the harness pins.
      expect(quitLabel(english.tray), 'Quit');

      // A rebuild that changes nothing visible must not churn the native menu.
      final settled = english.tray.menus.length;
      await tester.pump();
      await tester.pumpAndSettle();
      expect(english.tray.menus, hasLength(settled));

      // A fresh tree, so the second app installs its own tray rather than
      // reusing the element the first one already attached to.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final korean = build(localeTag: 'ko');
      await tester.pumpWidget(korean.app);
      await tester.pumpAndSettle();
      expect(quitLabel(korean.tray), '종료');
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'a menu change during installation waits for the icon to exist',
    (tester) async {
      // The native tray rejects a menu before its icon exists, so a second
      // frame must not overtake an install that is still running.
      final gate = Completer<void>();
      final harness = build(localeTag: 'en', installGate: gate);
      await tester.pumpWidget(harness.app);
      await tester.pump();
      await tester.pump();

      expect(harness.tray.operations, <String>['install']);

      gate.complete();
      await tester.pumpAndSettle();

      expect(harness.tray.operations.first, 'install');
      expect(harness.tray.operations.sublist(1), everyElement('update'));
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );

  testWidgets(
    'a login launch starts hidden and offers to show the window',
    (tester) async {
      final harness = build(startHidden: true);
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(
        harness.tray.menu.entries
            .firstWhere((entry) => entry.key == trayItemToggleWindow)
            .label,
        testL10n.trayShowWindow,
      );
      expect(harness.window.shows, 0);
    },
    tags: const <String>['feature_test__desktop_residency__widget'],
  );
}

final class _OfflineClients implements HostClientFactory {
  const _OfflineClients();

  @override
  Future<CoderApi> connect({
    required HostEndpoint endpoint,
    required DaemonCredentials credentials,
    required String clientId,
    required String clientKind,
  }) => Future<CoderApi>.error(const HostConnectionFailure.network('offline'));
}

final class _StubLauncher implements EmbeddedDaemonLauncher {
  const _StubLauncher(this.session);

  final EmbeddedDaemonSession session;

  @override
  Future<EmbeddedDaemonSession> start({
    required EmbeddedDaemonExposure exposure,
    required int port,
  }) async => session;
}

/// An embedded session whose stop misbehaves the way a wedged daemon does.
final class _StubSession implements EmbeddedDaemonSession {
  const _StubSession.failing() : _hangs = false;

  const _StubSession.hanging() : _hangs = true;

  final bool _hangs;

  @override
  HostEndpoint get endpoint => HostEndpoint.parse('ws://embedded.test/ws');

  @override
  DaemonCredentials get credentials => const DaemonCredentials(
    bearerToken: 'embedded-bearer',
  );

  @override
  String get serverId => 'embedded-server';

  @override
  Future<void> stop() => _hangs
      ? Completer<void>().future
      : Future<void>.error(StateError('The daemon refused to stop.'));
}
