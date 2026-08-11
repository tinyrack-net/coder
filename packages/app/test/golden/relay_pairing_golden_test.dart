import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:relay_protocol/relay_protocol.dart';

import '../support/fake_coder_api.dart';
import '../support/localization.dart';

void main() {
  final offerUrl = RelayPairingOffer(
    serverId: 'daemon-4d2a713c9e18',
    relayUri: Uri.parse('wss://relay.coder.tinyrack.net/v1/ws'),
    daemonPublicKey: List<int>.filled(32, 1),
    offerId: 'golden-offer',
    secret: List<int>.filled(32, 2),
    // Keep the rendered local clock stable across developer and CI time zones.
    expiresAt: DateTime(2100),
  ).toUrl(Uri.parse('https://coder.tinyrack.net/pair'));
  final routes = <({String name, String location})>[
    (name: 'connect', location: const ConnectDaemonRoute().location),
    (name: 'offer', location: offerUrl.toString()),
    (
      name: 'connections',
      location: const DaemonConnectionsRoute(hostId: 'server').location,
    ),
  ];

  for (final route in routes) {
    for (final locale in const <Locale>[
      Locale('en'),
      Locale('ko'),
      Locale('ja'),
    ]) {
      for (final viewport in _viewports) {
        for (final brightness in Brightness.values) {
          unawaited(
            goldenTest(
              '${route.name} ${locale.languageCode} ${viewport.name} '
              '${brightness.name}',
              fileName:
                  'relay_${route.name}_${locale.languageCode}_'
                  '${viewport.name}_${brightness.name}',
              constraints: BoxConstraints.tight(viewport.size),
              builder: () => _PairingGoldenHost(
                location: route.location,
                locale: locale,
                brightness: brightness,
                size: viewport.size,
              ),
            ),
          );
        }
      }
    }
  }

  unawaited(
    goldenTest(
      'connections relay pairing dialog',
      fileName: 'relay_connections_pair_dialog_ko_desktop_dark',
      constraints: const BoxConstraints.tightFor(width: 1200, height: 900),
      whilePerforming: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('relay-pair-device')),
        );
        await tester.pumpAndSettle();
        return null;
      },
      builder: () => const _PairingGoldenHost(
        location: '/settings/daemons/server/connections',
        locale: Locale('ko'),
        brightness: Brightness.dark,
        size: Size(1200, 900),
      ),
    ),
  );

  for (final variant in <({String name, Size size})>[
    (name: 'desktop_dialog', size: const Size(1200, 900)),
    (name: 'mobile_sheet', size: const Size(390, 760)),
  ]) {
    unawaited(
      goldenTest(
        'relay endpoint editor ${variant.name}',
        fileName: 'relay_endpoint_editor_ko_${variant.name}_light',
        constraints: BoxConstraints.tight(variant.size),
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey<String>('relay-advanced-endpoint')),
          );
          await tester.pumpAndSettle();
          return null;
        },
        builder: () => _PairingGoldenHost(
          location: const DaemonConnectionsRoute(
            hostId: 'server',
          ).location,
          locale: const Locale('ko'),
          brightness: Brightness.light,
          size: variant.size,
        ),
      ),
    );
  }
}

const _viewports = <({String name, Size size})>[
  (name: 'desktop', size: Size(1200, 900)),
  (name: 'mobile', size: Size(390, 760)),
];

class _PairingGoldenHost extends StatefulWidget {
  const _PairingGoldenHost({
    required this.location,
    required this.locale,
    required this.brightness,
    required this.size,
  });

  final String location;
  final Locale locale;
  final Brightness brightness;
  final Size size;

  @override
  State<_PairingGoldenHost> createState() => _PairingGoldenHostState();
}

class _PairingGoldenHostState extends State<_PairingGoldenHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.location,
    routes: $appRoutes,
  );

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
        appServicesProvider.overrideWithValue(
          fakeAppServices(
            FakeCoderApi(
              relayPairingOffer: RelayPairingOfferDto(
                url: 'https://coder.tinyrack.net/pair#offer=golden-offer',
                expiresAt: DateTime(2100),
              ),
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: testLightTheme,
        darkTheme: testDarkTheme,
        themeMode: widget.brightness == Brightness.light
            ? ThemeMode.light
            : ThemeMode.dark,
        locale: widget.locale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        routerConfig: _router,
      ),
    ),
  );
}
