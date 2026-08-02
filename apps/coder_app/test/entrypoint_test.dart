import 'package:coder_app/main.dart' as platform_entry;
import 'package:coder_app/main_desktop.dart' as desktop_entry;
import 'package:coder_app/main_mobile.dart' as mobile_entry;
import 'package:coder_app/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';

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
    final desktopApi = FakeCoderApi();
    await desktop_entry.runDesktopApp(
      services: fakeAppServices(desktopApi),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test daemon'), findsOneWidget);

    final mobileApi = FakeCoderApi();
    await mobile_entry.runMobileApp(
      services: fakeAppServices(mobileApi),
    );
    await tester.pump();
    expect(find.byType(CoderApp), findsOneWidget);
  });
}
