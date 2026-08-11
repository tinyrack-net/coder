import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/hosts/domain/host_models.dart';
import 'package:app/src/features/hosts/domain/host_ports.dart';
import 'package:app/src/shared/presentation/tinest_ui_density.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_desktop_ports.dart';
import '../support/fake_tinest_api.dart';
import '../support/localization.dart';

void main() {
  for (final viewport in _viewports) {
    for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      unawaited(
        goldenTest(
          'disabled start minimized ${viewport.name} ${mode.name}',
          fileName: 'startup_settings_disabled_${viewport.name}_${mode.name}',
          constraints: BoxConstraints.tight(viewport.size),
          builder: () => _StartupSettingsGoldenHost(
            mode: mode,
            size: viewport.size,
          ),
        ),
      );
    }
  }
}

const _viewports = <({String name, Size size})>[
  (name: 'desktop', size: Size(1200, 900)),
  (name: 'mobile', size: Size(390, 760)),
];

class _StartupSettingsGoldenHost extends StatefulWidget {
  const _StartupSettingsGoldenHost({required this.mode, required this.size});

  final ThemeMode mode;
  final Size size;

  @override
  State<_StartupSettingsGoldenHost> createState() =>
      _StartupSettingsGoldenHostState();
}

class _StartupSettingsGoldenHostState
    extends State<_StartupSettingsGoldenHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: const GeneralSettingsRoute().location,
    routes: $appRoutes,
  );
  late final MemoryAppStore _store = MemoryAppStore(
    settings: const AppSettings(
      embeddedDaemonEnabled: false,
      startAtBoot: false,
    ),
  );
  late final AppServices _services = fakeAppServices(
    FakeTinestApi(),
    store: _store,
  );
  late final _autostart = FakeAutostartRegistration();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: widget.size,
    child: ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(_services),
        autostartProvider.overrideWithValue(_autostart),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        themeMode: widget.mode,
        locale: testLocale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: _router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: widget.size),
          child: TinestUiDensity(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}
