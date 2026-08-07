import 'package:coder_app/main.dart' as platform_entry;
import 'package:coder_app/main_desktop.dart' as desktop_entry;
import 'package:coder_app/main_mobile.dart' as mobile_entry;
import 'package:coder_app/main_web.dart' as web_entry;
import 'package:coder_app/src/app/coder_app.dart';
import 'package:coder_app/src/features/conversation/infrastructure/attachment_export_web.dart';
import 'package:coder_app/src/features/conversation/infrastructure/attachment_web.dart';
import 'package:coder_app/src/features/desktop/application/desktop_startup.dart';
import 'package:coder_app/src/features/hosts/domain/host_models.dart';
import 'package:coder_app/src/features/hosts/domain/host_ports.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_coder_api.dart';
import '../support/fake_desktop_ports.dart';

void main() {
  test('platform dispatcher selects exactly one entry point', () async {
    var desktopCalls = 0;
    var mobileCalls = 0;
    Future<void> desktop() async => desktopCalls += 1;
    Future<void> mobile() async => mobileCalls += 1;

    await platform_entry.runPlatformApp(
      isMobile: false,
      runDesktop: desktop,
      runMobile: mobile,
    );
    await platform_entry.runPlatformApp(
      isMobile: true,
      runDesktop: desktop,
      runMobile: mobile,
    );

    expect(desktopCalls, 1);
    expect(mobileCalls, 1);
  });

  testWidgets('desktop and mobile runners accept test services', (
    tester,
  ) async {
    final desktopApi = FakeCoderApi(
      workspaces: <WorkspaceDto>[
        WorkspaceDto(
          id: 'workspace',
          name: 'Coder',
          rootPath: '/repos/coder',
          kind: WorkspaceKind.git,
          createdAt: DateTime.utc(2026, 8, 3),
        ),
      ],
    );
    final window = FakeDesktopWindow();
    final tray = FakeTrayIcon();
    await desktop_entry.runDesktopApp(
      services: fakeAppServices(desktopApi),
      window: window,
      tray: tray,
      autostart: FakeAutostartRegistration(),
    );
    await tester.pumpAndSettle();
    // The injected daemon names the workspace row it serves.
    expect(find.text('Test daemon · /repos/coder'), findsOneWidget);
    // The desktop runner is resident: it owns a tray and swallows the close.
    expect(window.preparedHidden, isFalse);
    expect(window.preventingClose, isTrue);
    expect(tray.installs, 1);

    final mobileApi = FakeCoderApi();
    await mobile_entry.runMobileApp(
      services: fakeAppServices(mobileApi),
    );
    // The gate paints its splash first, so the app arrives a frame after the
    // bootstrap future resolves rather than in the first pump.
    await tester.pumpAndSettle();
    expect(find.byType(CoderApp), findsOneWidget);
  });

  testWidgets('the web runner starts remote-only', (tester) async {
    await web_entry.runWebApp(services: fakeAppServices(FakeCoderApi()));
    await tester.pumpAndSettle();

    expect(find.byType(CoderApp), findsOneWidget);
  });

  test('the web attachment adapters replace their native counterparts', () {
    // A browser has no filesystem, so both ports need a web implementation or
    // the composer silently loses file support.
    expect(createAttachmentExport(), isA<WebAttachmentExport>());
    // Drop support is dropwell's answer, not this adapter's: repeating the
    // claim here is how the two would drift apart. What the adapter owes is
    // to report whatever the running platform says.
    expect(
      const WebAttachmentInput().supportsDrop,
      DropwellPlatform.instance.supportsDrop,
    );
  });

  testWidgets(
    'the login-item argument starts the desktop runner hidden',
    (tester) async {
      final store = MemoryAppStore(
        settings: const AppSettings(embeddedDaemonEnabled: false),
      );
      final window = FakeDesktopWindow();
      await desktop_entry.runDesktopApp(
        services: fakeAppServices(FakeCoderApi(), store: store),
        arguments: const <String>[startMinimizedFlag],
        window: window,
        tray: FakeTrayIcon(),
        autostart: FakeAutostartRegistration(),
      );
      await tester.pumpAndSettle();

      expect(window.preparedHidden, isTrue);
      expect(window.visible, isFalse);
      expect(window.shows, 0);
    },
    tags: const <String>['feature_test__settings_startup__widget'],
  );
}
