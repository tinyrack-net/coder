import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/remote_bootstrap.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile bootstrap remains remote-only', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await tester.pumpWidget(CoderApp(bootstrap: RemoteBootstrap()));
    await tester.pumpAndSettle();

    expect(find.text('모바일은 원격 daemon에만 연결합니다.'), findsOneWidget);
    expect(find.text('Daemon WebSocket 주소'), findsOneWidget);
  });
}
