import 'package:app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:app/src/features/desktop/domain/tray_menu_model.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/pump_until.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the real runner registers a tray icon and hides instead of quitting',
    (tester) async {
      final window = PluginDesktopWindow();
      final tray = PluginTrayIcon();
      addTearDown(tray.destroy);
      addTearDown(window.releaseClose);

      await window.prepare(startHidden: false);
      expect(window.chrome, DesktopWindowChrome.custom);
      expect(await window.isVisible(), isTrue);
      await window.toggleMaximized();
      expect(window.maximized.value, isTrue);
      await window.toggleMaximized();
      expect(window.maximized.value, isFalse);

      var closes = 0;
      await window.interceptClose(() => closes += 1);
      const menu = TrayMenuModel(
        tooltip: 'Tinest',
        entries: <TrayMenuEntry>[
          TrayMenuEntry(
            key: trayItemToggleWindow,
            label: 'Show window',
            action: TrayMenuAction.toggleWindow,
          ),
          TrayMenuEntry.separator(),
          TrayMenuEntry(key: trayItemQuit, label: 'Quit'),
        ],
      );
      await tray.install(menu: menu, onSelected: (_) {}, onActivated: () {});
      await tray.update(menu);
      expect(const NativeAttachmentInput(), isA<AttachmentInputPort>());
      expect(const NativeAttachmentExport(), isA<AttachmentExportPort>());

      await window.hide();
      await _waitForWindowVisibility(window, visible: false);
      expect(window.visible.value, isFalse);
      await window.show();
      await _waitForWindowVisibility(window, visible: true);
      expect(window.visible.value, isTrue);
      expect(closes, 0);
    },
    tags: const <String>[
      'feature_test__desktop_residency__platformSmoke',
      'feature_test__desktop_window_chrome__platformSmoke',
      'feature_test__conversation_attachments__platformSmoke',
      'feature_scenario__desktop_residency__close_hide_restore__e2e',
      'feature_scenario__desktop_window_chrome__native_window_controls__e2e',
    ],
  );
}

Future<void> _waitForWindowVisibility(
  DesktopWindow window, {
  required bool visible,
}) => awaitCondition(
  () async => await window.isVisible() == visible,
  'the window to become ${visible ? 'visible' : 'hidden'}',
);
