import 'dart:io';

import 'package:coder_workspace/src/feature_verifier.dart';
import 'package:test/test.dart';

void main() {
  test('feature verifier accepts complete API, route, and layer evidence', () {
    const markerPrefix =
        'feature_'
        'test__';
    const routeMarkerPrefix =
        'route_'
        'test__';
    final fixture = _fixture(
      api:
          'abstract interface class CoderApi {'
          ' Future<void> createThing(); }',
      routes: '@TypedGoRoute<HomeRoute>(path: "/")',
      tests: <String>[
        "test('works', () {}, tags: <String>[",
        "'${markerPrefix}thing_create__contract', ",
        "'${markerPrefix}thing_create__e2e', ",
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
        ),
      ],
      apiPath: 'lib/api.dart',
      routePath: 'lib/app.dart',
    ).verify();

    expect(violations, isEmpty);
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
          'abstract interface class CoderApi {'
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
