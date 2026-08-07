import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

void main() {
  testWidgets(
    'describes every mode and persists full access without confirmation',
    (tester) async {
      final api = FakeCoderApi();
      final router = GoRouter(
        initialLocation: const PermissionSettingsRoute(
          hostId: 'server',
        ).location,
        routes: $appRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp.router(
            theme: testLightTheme,
            darkTheme: testDarkTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('permission-settings-change')),
      );
      await tester.pumpAndSettle();

      expect(find.text('읽기 전용'), findsOneWidget);
      expect(find.text('변경 전 확인'), findsWidgets);
      expect(find.text('작업 공간 접근'), findsOneWidget);
      expect(find.text('전체 접근'), findsOneWidget);
      expect(
        find.textContaining('신뢰할 수 있는 작업에서만 사용하세요'),
        findsOneWidget,
      );

      final fullAccess = find.byKey(
        const ValueKey<String>('permission-option-fullAccess'),
      );
      await tester.ensureVisible(fullAccess);
      await tester.tap(fullAccess);
      await tester.pumpAndSettle();

      expect(api.defaultPermissionMode, PermissionMode.fullAccess);
      expect(find.text('전체 접근'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );

  testWidgets(
    'restores the prior default and shows an error when persistence fails',
    (tester) async {
      final api = FakeCoderApi(
        defaultPermissionSetError: Exception('daemon rejected update'),
      );
      final router = GoRouter(
        initialLocation: const PermissionSettingsRoute(
          hostId: 'server',
        ).location,
        routes: $appRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(fakeAppServices(api)),
          ],
          child: MaterialApp.router(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('permission-settings-change')),
      );
      await tester.pumpAndSettle();
      final fullAccess = find.byKey(
        const ValueKey<String>('permission-option-fullAccess'),
      );
      await tester.ensureVisible(fullAccess);
      await tester.tap(fullAccess);
      await tester.pumpAndSettle();

      expect(api.defaultPermissionMode, PermissionMode.ask);
      expect(find.text('변경 전 확인'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('permission-settings-error')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );

  testWidgets(
    'permission picker stays content-sized as the window grows',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: const PermissionSettingsRoute(
          hostId: 'server',
        ).location,
        routes: $appRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(
              fakeAppServices(FakeCoderApi()),
            ),
          ],
          child: MaterialApp.router(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('permission-settings-change')),
      );
      await tester.pumpAndSettle();

      final mediumHeight = tester.getSize(find.byType(TRDrawer)).height;
      tester.view.physicalSize = const Size(1000, 1100);
      await tester.pumpAndSettle();
      final tallHeight = tester.getSize(find.byType(TRDrawer)).height;

      expect(tallHeight, mediumHeight);
      expect(tallHeight, lessThan(550));
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );
}
