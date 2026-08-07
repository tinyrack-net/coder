import 'dart:io';

import 'package:coder_workspace/src/ci_impact_planner.dart';
import 'package:test/test.dart';

void main() {
  final graph = WorkspaceGraph.load(Directory.current.path);

  CiImpactPlan planFor(List<String> changedFiles) =>
      CiImpactPlanner(graph).plan(changedFiles: changedFiles);

  group('WorkspaceGraph', () {
    test('loads every workspace package including the tooling root', () {
      expect(graph.packageNames, <String>[
        'coder_agent',
        'coder_app',
        'coder_cli',
        'coder_client',
        'coder_daemon',
        'coder_mcp',
        'coder_protocol',
        'coder_provider_openai',
        'coder_workspace',
        'tinyrack_pty',
      ]);
    });

    test('reads intra-workspace dependencies from each pubspec', () {
      expect(graph.package('coder_daemon').dependencies, <String>{
        'coder_agent',
        'coder_client',
        'coder_mcp',
        'coder_protocol',
        'coder_provider_openai',
        'tinyrack_pty',
      });
      // `coder_agent` is a dev dependency of the app and still forces a rebuild
      // of its tests, so the graph keeps both dependency sections.
      expect(graph.package('coder_app').dependencies, <String>{
        'coder_agent',
        'coder_client',
        'coder_daemon',
        'coder_protocol',
      });
      expect(graph.package('coder_protocol').dependencies, isEmpty);
    });

    test('marks the app as the only Flutter package', () {
      expect(graph.package('coder_app').isFlutter, isTrue);
      for (final name in graph.packageNames.where((n) => n != 'coder_app')) {
        expect(graph.package(name).isFlutter, isFalse, reason: name);
      }
    });

    test('records which packages run build_runner', () {
      expect(
        graph.packageNames.where((n) => graph.package(n).usesBuildRunner),
        <String>['coder_app', 'coder_daemon', 'coder_protocol'],
      );
    });

    // `p.relative` yields `packages\coder_cli` on Windows, which never matched
    // the POSIX key a Git diff produces. Every path then looked unrecognised
    // and forced a full run, so the whole feature was a no-op there. The bug
    // is invisible on a POSIX host, hence the hand-built graph.
    test('a Windows-style package directory still matches a Git path', () {
      final windows = WorkspaceGraph(<String, WorkspacePackage>{
        'coder_cli': const WorkspacePackage(
          name: 'coder_cli',
          directory: r'packages\coder_cli',
          isFlutter: false,
          usesBuildRunner: false,
          dependencies: <String>{},
        ),
      });

      expect(windows.packageForDirectory('packages/coder_cli'), 'coder_cli');
      expect(
        CiImpactPlanner(windows)
            .plan(
              changedFiles: <String>[r'packages\coder_cli\lib\src\runner.dart'],
            )
            .affectedPackages,
        <String>{'coder_cli'},
      );
    });

    test('rejects a package it does not know', () {
      expect(
        () => graph.package('nope'),
        throwsA(isA<ArgumentError>()),
      );
      expect(graph.packageForDirectory('packages/nope'), isNull);
    });

    test('ignores a workspace group directory that does not exist', () {
      final empty = Directory.systemTemp.createTempSync('ci-impact-graph');
      addTearDown(() => empty.deleteSync(recursive: true));
      File(
        '${empty.path}/pubspec.yaml',
      ).writeAsStringSync('name: solo\ndependencies:\n  path: ^1.9.1\n');

      final solo = WorkspaceGraph.load(empty.path);
      expect(solo.packageNames, <String>['solo']);
      // `path` is not a workspace member, so it is not a graph edge.
      expect(solo.package('solo').dependencies, isEmpty);
      expect(solo.package('solo').directory, '.');
    });

    test('tolerates a manifest that is not a mapping', () {
      final broken = Directory.systemTemp.createTempSync('ci-impact-broken');
      addTearDown(() => broken.deleteSync(recursive: true));
      Directory('${broken.path}/packages/odd').createSync(recursive: true);
      File('${broken.path}/pubspec.yaml').writeAsStringSync('name: root\n');
      File(
        '${broken.path}/packages/odd/pubspec.yaml',
      ).writeAsStringSync('- not a map\n');

      expect(WorkspaceGraph.load(broken.path).packageNames, <String>[
        'null',
        'root',
      ]);
    });

    test('closes over dependents, not dependencies', () {
      expect(
        graph.dependentsClosure(<String>{'coder_protocol'}),
        <String>{
          'coder_agent',
          'coder_app',
          'coder_cli',
          'coder_client',
          'coder_daemon',
          'coder_mcp',
          'coder_protocol',
          'coder_provider_openai',
        }.difference(<String>{'coder_mcp'}),
      );
      expect(graph.dependentsClosure(<String>{'coder_app'}), <String>{
        'coder_app',
      });
      expect(graph.dependentsClosure(<String>{'tinyrack_pty'}), <String>{
        'coder_app',
        'coder_cli',
        'coder_daemon',
        'tinyrack_pty',
      });
    });
  });

  group('CiImpactPlanner', () {
    test('runs nothing for a documentation-only change', () {
      final plan = planFor(<String>['docs/testing.md', 'README.md']);

      expect(plan.full, isFalse);
      expect(plan.affectedPackages, isEmpty);
      expect(plan.dartScopes, isEmpty);
      expect(plan.runDartTests, isFalse);
      expect(plan.runFlutter, isFalse);
      expect(plan.runGenerated, isFalse);
      expect(plan.runCli, isFalse);
    });

    test('a leaf package change fans out to every dependent', () {
      final plan = planFor(<String>[
        'packages/coder_protocol/lib/src/session.dart',
      ]);

      expect(plan.full, isFalse);
      expect(plan.dartScopes, <String>[
        'coder_agent',
        'coder_cli',
        'coder_client',
        'coder_daemon',
        'coder_protocol',
        'coder_provider_openai',
      ]);
      expect(plan.runFlutter, isTrue);
      expect(plan.runCli, isTrue);
      expect(plan.runGenerated, isTrue);
    });

    test('a CLI change stays out of the Flutter jobs', () {
      final plan = planFor(<String>['packages/coder_cli/lib/src/runner.dart']);

      expect(plan.dartScopes, <String>['coder_cli']);
      expect(plan.runCli, isTrue);
      expect(plan.runDartTests, isTrue);
      expect(plan.runFlutter, isFalse);
      expect(plan.runE2e, isFalse);
      expect(plan.runGolden, isFalse);
      expect(plan.runWeb, isFalse);
      expect(plan.runDesktopBuild, isFalse);
      expect(plan.runGenerated, isFalse);
      expect(plan.dartCoverageScopes, isEmpty);
    });

    test('an app change runs the Flutter jobs and no Dart package job', () {
      final plan = planFor(<String>['apps/coder_app/lib/src/app.dart']);

      expect(plan.dartScopes, isEmpty);
      expect(plan.runDartTests, isFalse);
      expect(plan.runDartCoverage, isFalse);
      expect(plan.runFlutter, isTrue);
      expect(plan.runGolden, isTrue);
      expect(plan.runE2e, isTrue);
      expect(plan.runWeb, isTrue);
      expect(plan.runMobileBuild, isTrue);
      expect(plan.runDesktopBuild, isTrue);
      expect(plan.runCli, isFalse);
    });

    test('non-Dart platform sources map to their owning package', () {
      final native = planFor(<String>[
        'packages/tinyrack_pty/src/tinyrack_pty.c',
      ]);
      expect(native.affectedPackages, <String>{
        'coder_app',
        'coder_cli',
        'coder_daemon',
        'tinyrack_pty',
      });
      expect(native.runDesktopBuild, isTrue);

      final android = planFor(<String>[
        'apps/coder_app/android/build.gradle.kts',
      ]);
      expect(android.affectedPackages, <String>{'coder_app'});
      expect(android.runMobileBuild, isTrue);
    });

    test('only the packages CI gates today reach the coverage check', () {
      final plan = planFor(<String>[
        'packages/coder_protocol/lib/src/session.dart',
      ]);

      // `coder_cli`, `coder_mcp` and `tinyrack_pty` are deliberately absent:
      // the workflow has never gated their coverage and this change does not
      // widen the gate.
      expect(plan.dartCoverageScopes, <String>[
        'coder_agent',
        'coder_client',
        'coder_daemon',
        'coder_protocol',
        'coder_provider_openai',
      ]);
    });

    for (final path in <String>[
      'pubspec.yaml',
      'pubspec.lock',
      'analysis_options.yaml',
      'dart_test.yaml',
      'tool/plan_ci.dart',
      'lib/src/ci_impact_planner.dart',
      'test/ci_impact_planner_test.dart',
      '.github/workflows/pipeline.yml',
      '.github/actions/setup-flutter/action.yml',
    ]) {
      test('$path forces a full run', () {
        expect(planFor(<String>[path]).full, isTrue);
      });
    }

    test('an unrecognised path forces a full run rather than skipping', () {
      expect(planFor(<String>['Makefile']).full, isTrue);
      expect(planFor(<String>['apps/unknown_app/lib/main.dart']).full, isTrue);
    });

    test('a full plan enables every job and every scope', () {
      final plan = CiImpactPlanner(graph).fullPlan();

      expect(plan.full, isTrue);
      expect(plan.dartScopes, <String>[
        'coder_agent',
        'coder_cli',
        'coder_client',
        'coder_daemon',
        'coder_mcp',
        'coder_protocol',
        'coder_provider_openai',
        'coder_workspace',
        'tinyrack_pty',
      ]);
      expect(plan.runDartTests, isTrue);
      expect(plan.runFlutter, isTrue);
      expect(plan.runGenerated, isTrue);
      expect(plan.runGolden, isTrue);
      expect(plan.runE2e, isTrue);
      expect(plan.runWeb, isTrue);
      expect(plan.runMobileBuild, isTrue);
      expect(plan.runDesktopBuild, isTrue);
      expect(plan.runCli, isTrue);
    });

    test('the root tooling package only ever runs in a full plan', () {
      expect(
        planFor(<String>['packages/coder_daemon/lib/src/x.dart']).dartScopes,
        isNot(contains('coder_workspace')),
      );
      expect(
        CiImpactPlanner(graph).fullPlan().dartScopes,
        contains('coder_workspace'),
      );
    });
  });

  group('CiImpactPlan outputs', () {
    test('serialises booleans and scopes for GITHUB_OUTPUT', () {
      final outputs = planFor(<String>[
        'packages/coder_cli/lib/src/runner.dart',
      ]).outputs;

      expect(outputs['full'], 'false');
      expect(outputs['melos_packages'], 'coder_cli');
      expect(outputs['coverage_scope_flags'], '');
      expect(outputs['run_dart_tests'], 'true');
      expect(outputs['run_dart_coverage'], 'false');
      expect(outputs['run_flutter'], 'false');
      expect(outputs['run_cli'], 'true');
    });

    test('the Melos filter is the comma list `MELOS_PACKAGES` expects', () {
      final plan = planFor(<String>[
        'packages/coder_protocol/lib/src/session.dart',
      ]);

      expect(
        plan.melosPackages,
        'coder_agent,coder_cli,coder_client,coder_daemon,coder_protocol,'
        'coder_provider_openai',
      );
    });

    test('the coverage flags are what verify_coverage.dart parses', () {
      final plan = planFor(<String>[
        'packages/coder_provider_openai/lib/src/client.dart',
      ]);

      expect(
        plan.coverageScopeFlags,
        '--scope=coder_daemon --scope=coder_provider_openai',
      );
    });

    test('every output value is a single line of key=value text', () {
      final outputs = CiImpactPlanner(graph).fullPlan().outputs;

      expect(outputs.keys, containsAll(<String>['full', 'melos_packages']));
      for (final entry in outputs.entries) {
        expect(entry.key, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
        expect(entry.value, isNot(contains('\n')));
      }
    });

    test('the summary names the packages and the skipped jobs', () {
      final summary = planFor(<String>[
        'packages/coder_cli/lib/src/runner.dart',
      ]).summary;

      expect(summary, contains('coder_cli'));
      expect(summary, contains('run_flutter'));
    });
  });
}
