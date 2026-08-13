import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protocol/protocol.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../../support/fake_tinest_api.dart';
import '../../support/localization.dart';

void main() {
  testWidgets(
    'describes every mode and persists full access without confirmation',
    (tester) async {
      final api = FakeTinestApi();
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
            builder: (context, child) =>
                TinestToastScope(child: child ?? const SizedBox.shrink()),
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
      expect(find.text('전체 접근'), findsWidgets);
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
      // The closed trigger and the retained overlay route can both contain the
      // selected label during the route's final frame.
      expect(find.text('전체 접근'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );

  testWidgets(
    'restores the prior default and shows an error when persistence fails',
    (tester) async {
      final api = FakeTinestApi(
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
            builder: (context, child) =>
                TinestToastScope(child: child ?? const SizedBox.shrink()),
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
      expect(find.text('변경 전 확인'), findsWidgets);
      expect(find.text('기본 권한을 변경하지 못했습니다'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );

  testWidgets(
    'permission Select uses a desktop menu and a mobile sheet',
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
              fakeAppServices(FakeTinestApi()),
            ),
          ],
          child: MaterialApp.router(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            routerConfig: router,
            builder: (context, child) =>
                TinestToastScope(child: child ?? const SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('permission-settings-change')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TRDrawer), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(390, 760);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('permission-settings-change')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TRDrawer), findsOneWidget);
      expect(find.byType(TRTextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    tags: const <String>['feature_test__permission_settings__widget'],
  );
}
