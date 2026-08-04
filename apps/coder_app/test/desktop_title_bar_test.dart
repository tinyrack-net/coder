import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/desktop_title_bar.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';
import 'support/fake_desktop_ports.dart';

void main() {
  ({
    Widget app,
    FakeDesktopWindow window,
    FakeTrayIcon tray,
    MemoryAppStore store,
  })
  build() {
    final window = FakeDesktopWindow(supportsCustomTitleBar: true);
    final tray = FakeTrayIcon()..calls = window.calls;
    final store = MemoryAppStore(
      settings: const AppSettings(
        embeddedDaemonEnabled: false,
        localeTag: 'en',
      ),
    );
    return (
      app: CoderApp(
        services: fakeAppServices(
          FakeCoderApi(),
          connected: false,
          store: store,
        ),
        desktopWindow: window,
        trayIcon: tray,
        autostart: FakeAutostartRegistration(),
      ),
      window: window,
      tray: tray,
      store: store,
    );
  }

  testWidgets(
    'custom title bar drives drag, window controls, and close-to-tray',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      expect(find.byType(DesktopTitleBar), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey<String>('desktop-title-bar-drag-area')),
        const Offset(30, 0),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-title-bar-minimize')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-title-bar-maximize')),
      );
      await tester.pump();

      expect(harness.window.drags, 1);
      expect(harness.window.minimizes, 1);
      expect(harness.window.maximizeToggles, 1);
      expect(
        find.byKey(const ValueKey<String>('desktop-title-bar-restore')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-title-bar-close')),
      );
      await tester.pumpAndSettle();
      expect(harness.window.hides, 1);
      expect(harness.window.destroys, 0);
      expect(harness.window.visible, isFalse);
    },
    tags: const <String>['feature_test__desktop_window_chrome__widget'],
  );

  testWidgets(
    'localized menus navigate, toggle the sidebar, show about, and quit',
    (tester) async {
      final harness = build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('New workspace'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Quit'), findsWidgets);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('Display language'), findsOneWidget);

      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About Tinyrack Coder'));
      await tester.pumpAndSettle();
      expect(find.text('Tinyrack Coder'), findsWidgets);
      expect(find.text('0.1.0'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      const shortcut = SingleActivator(LogicalKeyboardKey.keyB, control: true);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(shortcut.trigger);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(harness.store.settings.sidebarCollapsed, isTrue);

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quit'));
      await tester.pumpAndSettle();
      for (
        var attempt = 0;
        attempt < 20 && harness.window.destroys == 0;
        attempt += 1
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(
        harness.window.calls,
        containsAllInOrder(<String>[
          'destroyTray',
          'releaseClose',
          'destroyWindow',
        ]),
      );
    },
    tags: const <String>['feature_test__desktop_window_chrome__widget'],
  );
}
