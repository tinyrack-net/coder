import 'package:app/testing/features/conversation/infrastructure/attachment_io.dart';
import 'package:app/testing/features/desktop/domain/tray_menu_model.dart';
import 'package:app/testing/features/desktop/infrastructure/desktop_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/pump_until.dart';

// DIAGNOSTIC BUILD — NOT FOR MERGE.
//
// `hides instead of quitting` fails on roughly one in ten Linux CI runs with
// the native window still reporting visible 60s after `hide()` returned, even
// though `PluginDesktopWindow.hide()` already re-issues hide ten times. This
// build answers three questions the failure message cannot:
//
//   1. Does the app-level notifier also flip back, which would mean the
//      plugin delivered a native `show` event that undid our hide, rather
//      than the hide never reaching GTK?
//   2. Does hide work before `tray.install`, which is the only step between
//      the passing visibility wait and the failing one?
//   3. Does hide fail once and stay failed, or fail on a random iteration?
//
// The hide/show cycle repeats so a per-attempt race reproduces inside a single
// job instead of once every ten pipeline runs.
//
// The first diagnostic run answered one question already: a healthy process
// hides in about 7ms and did so 23 times in a row, before and after the tray,
// finishing inside 700ms. A burst that short only samples the first instant of
// the process, so the cycles are now spaced to cover the first ~40s instead,
// which is where a hazard that needs the app to reach some later state — a
// delayed first frame, a tray fallback timer, a lifecycle transition — would
// actually live.
const int _hideCycles = 80;
const Duration _cycleGap = Duration(milliseconds: 500);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the real runner registers a tray icon and hides instead of quitting',
    (tester) async {
      final window = PluginDesktopWindow();
      final tray = PluginTrayIcon();
      addTearDown(tray.destroy);
      addTearDown(window.releaseClose);

      final log = <String>[];
      final clock = Stopwatch()..start();
      void record(String entry) =>
          log.add('+${clock.elapsedMilliseconds}ms $entry');

      await window.prepare(startHidden: false);
      await window.show();
      await _waitForWindowVisibility(window, visible: true);
      expect(window.chrome, DesktopWindowChrome.custom);
      expect(await window.isVisible(), isTrue);

      var closes = 0;
      await window.interceptClose(() => closes += 1);
      // Registered only after interceptClose, because the relay that publishes
      // native show/hide events into the notifier is installed there.
      window.visible.addListener(
        () => record('notifier visible=${window.visible.value}'),
      );

      // Question 2: the same cycle before the tray exists.
      await _diagnoseHideCycle(
        window,
        log,
        record,
        label: 'pre-tray',
        cycles: 3,
      );

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
      record('tray installed');
      expect(const NativeAttachmentInput(), isA<AttachmentInputPort>());
      expect(const NativeAttachmentExport(), isA<AttachmentExportPort>());

      await _diagnoseHideCycle(
        window,
        log,
        record,
        label: 'post-tray',
        cycles: _hideCycles,
      );

      // The original single-shot assertions, kept so a green diagnostic run
      // still proves the contract this test owns.
      await window.hide();
      await _waitForWindowVisibility(window, visible: false);
      expect(window.visible.value, isFalse);
      await window.show();
      await _waitForWindowVisibility(window, visible: true);
      expect(window.visible.value, isTrue);
      expect(closes, 0);

      // ignore: avoid_print, the diagnostic payload this build exists to emit.
      print('HIDE DIAGNOSTICS (passed)\n${log.join('\n')}');

      await window.toggleMaximized();
      expect(window.maximized.value, isTrue);
      await window.toggleMaximized();
      expect(window.maximized.value, isFalse);
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

/// Hides and shows [window] repeatedly, failing with the whole event log the
/// first time the native window refuses to report itself hidden.
Future<void> _diagnoseHideCycle(
  DesktopWindow window,
  List<String> log,
  void Function(String) record, {
  required String label,
  required int cycles,
}) async {
  for (var cycle = 0; cycle < cycles; cycle += 1) {
    await window.hide();
    final hiddenImmediately = !await window.isVisible();
    record(
      '$label #$cycle hide() returned '
      'native=${hiddenImmediately ? 'hidden' : 'VISIBLE'} '
      'notifier=${window.visible.value}',
    );
    if (!hiddenImmediately) {
      // Give the compositor the budget the original wait allowed, then report
      // what one more explicit hide does, which separates "the request was
      // dropped" from "something keeps showing the window again".
      final recovered = await _settles(window, visible: false);
      record(
        '$label #$cycle after wait native=${recovered ? 'hidden' : 'VISIBLE'}',
      );
      if (!recovered) {
        await window.hide();
        final afterRetry = !await window.isVisible();
        record(
          '$label #$cycle extra hide '
          'native=${afterRetry ? 'hidden' : 'VISIBLE'} '
          'notifier=${window.visible.value}',
        );
        fail('HIDE DIAGNOSTICS (failed)\n${log.join('\n')}');
      }
    }
    await window.show();
    await _waitForWindowVisibility(window, visible: true);
    await Future<void>.delayed(_cycleGap);
  }
  record('$label cycles complete');
}

Future<bool> _settles(DesktopWindow window, {required bool visible}) async {
  for (var waited = 0; waited < 100; waited += 1) {
    if (await window.isVisible() == visible) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return false;
}

Future<void> _waitForWindowVisibility(
  DesktopWindow window, {
  required bool visible,
}) => awaitCondition(
  () async => await window.isVisible() == visible,
  'the window to become ${visible ? 'visible' : 'hidden'}',
);
