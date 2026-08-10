import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/shared/presentation/toast_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import 'fake_coder_api.dart';
import 'localization.dart';

/// Pumps the routed app at [initialLocation] and returns its router.
///
/// Tests that assert navigation behaviour need the router itself, so this
/// builds one explicitly rather than going through [CoderApp].
Future<GoRouter> pumpRoutedApp(
  WidgetTester tester,
  FakeCoderApi api, {
  required String initialLocation,
  MemoryAppStore? store,
  List<Override> overrides = const <Override>[],
  // A screen with a perpetual animation (a running subagent spinner, for
  // instance) never settles; such tests pump fixed frames instead.
  bool settle = true,
}) async {
  final router = GoRouter(initialLocation: initialLocation, routes: $appRoutes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          fakeAppServices(api, store: store),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: router,
        // Mirrors what CoderApp wraps every route in, so a screen under test
        // can report a result the same way it does when the app runs.
        builder: (context, child) =>
            CoderToastScope(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var frame = 0; frame < 8; frame += 1) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  return router;
}

/// Location of the top-most page of [router], including query parameters.
///
/// [GoRouter.routeInformationProvider] reports the base configuration, which
/// does not move when a route is pushed, so it cannot see a pushed task.
String currentLocation(GoRouter router) => router.state.uri.toString();
