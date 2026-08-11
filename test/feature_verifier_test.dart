import 'dart:io';

import 'package:test/test.dart';
import 'package:tinest_workspace/src/feature_verifier.dart';

void main() {
  test('feature verifier accepts complete API, route, and layer evidence', () {
    const markerPrefix =
        'feature_'
        'test__';
    const routeMarkerPrefix =
        'route_'
        'test__';
    const scenarioMarkerPrefix =
        'feature_'
        'scenario__';
    final fixture = _fixture(
      api:
          'abstract interface class TinestApi {'
          ' Future<void> createThing(); }',
      routes: '@TypedGoRoute<HomeRoute>(path: "/")',
      tests: <String>[
        "testWidgets('works', (tester) async {",
        'await tester.pump();',
        'expect(true, isTrue);',
        '}, tags: <String>[',
        "'${markerPrefix}thing_create__contract', ",
        "'${markerPrefix}thing_create__e2e', ",
        "'${scenarioMarkerPrefix}thing_create__success__e2e', ",
        "'${routeMarkerPrefix}home_route__widget']);",
      ].join(),
    );
    addTearDown(() => fixture.delete(recursive: true));

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[
        FeatureContract(
          id: 'thing.create',
          description: 'Creates a thing.',
          apiMethods: <String>['createThing'],
          routes: <String>['HomeRoute'],
          requiredLayers: <FeatureVerificationLayer>{
            FeatureVerificationLayer.contract,
            FeatureVerificationLayer.e2e,
          },
          e2eScenarios: <FeatureScenario>[
            FeatureScenario(
              id: 'success',
              description: 'Creates a thing.',
              surfaces: <FeatureSurface>{FeatureSurface.desktop},
            ),
          ],
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();

    expect(violations, isEmpty);
  });

  test('feature verifier accepts executable typed E2E scenarios', () {
    const markerPrefix =
        'feature_'
        'scenario__';
    final fixture = _fixture(
      api: 'abstract interface class TinestApi {}',
      routes: '',
      tests: <String>[
        "testWidgets('creates a thing', (tester) async {",
        'await tester.pump();',
        "expect(find.text('created'), findsOneWidget);",
        "}, tags: <String>['${markerPrefix}thing_create__success__e2e']);",
      ].join(),
    );
    addTearDown(() => fixture.delete(recursive: true));

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[
        FeatureContract(
          id: 'thing.create',
          description: 'Creates a thing.',
          requiredLayers: <FeatureVerificationLayer>{
            FeatureVerificationLayer.e2e,
          },
          e2eScenarios: <FeatureScenario>[
            FeatureScenario(
              id: 'success',
              description: 'Creates and persists a valid thing.',
              surfaces: <FeatureSurface>{
                FeatureSurface.desktop,
                FeatureSurface.mobile,
              },
            ),
          ],
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();

    expect(violations, isEmpty);
  });

  test('feature verifier rejects incomplete E2E scenario contracts', () {
    const markerPrefix =
        'feature_'
        'scenario__';
    final fixture = _fixture(
      api: 'abstract interface class TinestApi {}',
      routes: '',
      tests: <String>[
        "test('marker only', () {}, tags: <String>[",
        "'${markerPrefix}thing_create__marker_only__e2e',",
        "'${markerPrefix}thing_create__unknown__e2e']);",
      ].join(),
    );
    addTearDown(() => fixture.delete(recursive: true));

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[
        FeatureContract(
          id: 'thing.create',
          description: 'Creates a thing.',
          requiredLayers: <FeatureVerificationLayer>{
            FeatureVerificationLayer.e2e,
          },
          e2eScenarios: <FeatureScenario>[
            FeatureScenario(
              id: 'marker_only',
              description: 'Exercises a real runner.',
              surfaces: <FeatureSurface>{FeatureSurface.desktop},
            ),
            FeatureScenario(
              id: 'marker_only',
              description: 'Duplicate scenario.',
              surfaces: <FeatureSurface>{FeatureSurface.desktop},
            ),
            FeatureScenario(
              id: 'no_surface',
              description: 'Has no supported surface.',
              surfaces: <FeatureSurface>{},
            ),
            FeatureScenario(
              id: 'missing',
              description: 'Has no executable evidence.',
              surfaces: <FeatureSurface>{FeatureSurface.mobile},
            ),
          ],
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();
    final messages = violations.map((item) => item.message).join('\n');

    expect(messages, contains('Duplicate E2E scenario marker_only'));
    expect(messages, contains('no_surface has no supported surface'));
    expect(
      messages,
      contains('Unknown E2E scenario tag: thing.create/unknown'),
    );
    expect(messages, contains('marker_only has no executable testWidgets'));
    expect(messages, contains('missing is missing E2E evidence'));
  });

  test('feature verifier requires scenarios for every E2E feature', () {
    const markerPrefix =
        'feature_'
        'test__';
    final fixture = _fixture(
      api: 'abstract interface class TinestApi {}',
      routes: '',
      tests:
          "test('layer', () {}, "
          "tags: <String>['${markerPrefix}thing_create__e2e']);",
    );
    addTearDown(() => fixture.delete(recursive: true));

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[
        FeatureContract(
          id: 'thing.create',
          description: 'Creates a thing.',
          requiredLayers: <FeatureVerificationLayer>{
            FeatureVerificationLayer.e2e,
          },
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();

    expect(
      violations.map((item) => item.message),
      contains(contains('Feature thing.create has no E2E scenarios')),
    );
  });

  test('feature verifier reports every missing or unsafe registration', () {
    const markerPrefix =
        'feature_'
        'test__';
    const routeMarkerPrefix =
        'route_'
        'test__';
    final fixture = _fixture(
      api:
          'abstract interface class TinestApi {'
          ' Future<void> createThing(); Future<void> deleteThing(); }',
      routes:
          '@TypedGoRoute<HomeRoute>(path: "/") '
          '@TypedGoRoute<SettingsRoute>(path: "/settings")',
      tests: <String>[
        "test('skipped', () {}, skip: true, tags: <String>[",
        "'${markerPrefix}thing_create__contract', ",
        "'${markerPrefix}unknown_feature__widget', ",
        "'${routeMarkerPrefix}home_route__widget', ",
        "'${routeMarkerPrefix}ghost_route__widget']);",
      ].join(),
    );
    addTearDown(() => fixture.delete(recursive: true));

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[
        FeatureContract(
          id: 'thing.create',
          description: 'Creates a thing.',
          apiMethods: <String>['createThing'],
          routes: <String>['HomeRoute'],
          requiredLayers: <FeatureVerificationLayer>{
            FeatureVerificationLayer.contract,
            FeatureVerificationLayer.verticalSlice,
          },
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();
    final messages = violations.map((item) => item.message).join('\n');

    expect(messages, contains('deleteThing'));
    expect(messages, contains('SettingsRoute'));
    expect(messages, contains('verticalSlice'));
    expect(messages, contains('unknown.feature'));
    expect(messages, contains('SettingsRoute'));
    expect(messages, contains('GhostRoute'));
    expect(messages, contains('skip'));
  });

  test('feature verifier rejects retired security terms in production', () {
    final fixture = _fixture(
      api: 'abstract interface class TinestApi {}',
      routes: '',
      tests: '',
    );
    addTearDown(() => fixture.delete(recursive: true));
    File('${fixture.path}/lib/security.dart').writeAsStringSync(
      "const retired = 'adminToken';",
    );

    final violations = FeatureVerifier(
      fixture.path,
      contracts: const <FeatureContract>[],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();

    expect(
      violations.map((item) => item.message),
      contains(contains('Forbidden production term adminToken')),
    );
  });
}

Directory _fixture({
  required String api,
  required String routes,
  required String tests,
}) {
  final root = Directory.systemTemp.createTempSync('feature-verifier-');
  Directory('${root.path}/lib').createSync();
  Directory('${root.path}/test').createSync();
  File('${root.path}/lib/api.dart').writeAsStringSync(api);
  File('${root.path}/lib/app.dart').writeAsStringSync(routes);
  File('${root.path}/test/features_test.dart').writeAsStringSync(tests);
  return root;
}
