import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tinest_quality/src/architecture_verifier.dart';

import 'support/repo_root.dart';

void main() {
  useRepositoryRoot();
  const verifier = ArchitectureVerifier('/workspace');

  test('the checked-in workspace satisfies every architecture contract', () {
    expect(const ArchitectureVerifier('.').verify(), isEmpty);
  });

  test('agent domain cannot import the wire protocol', () {
    final violations = verifier.verifySource(
      package: 'agent',
      path: 'packages/agent/lib/src/runtime.dart',
      source: "import 'package:protocol/protocol.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('source_dependency_direction'),
    );
  });

  test('daemon application code rejects protocol and infrastructure', () {
    final violations = verifier.verifySource(
      package: 'daemon',
      path:
          'packages/daemon/lib/src/features/sessions/application/'
          'session_service.dart',
      source:
          "import 'package:protocol/protocol.dart';\n"
          "import 'package:drift/drift.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_protocol_dependency',
        'application_infrastructure_import',
      ]),
    );
  });

  test('an incomplete workspace reports its package topology', () {
    final root = Directory.systemTemp.createTempSync('tinest-quality-dag-');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(p.join(root.path, 'packages')).createSync();

    final violations = ArchitectureVerifier(root.path).verify();

    expect(
      violations.map((violation) => violation.rule),
      contains('internal_package_set'),
    );
    expect(violations.first.toString(), contains('[internal_package_set]'));
  });

  test('workspace pubspecs enforce the package dependency DAG', () {
    final root = Directory.systemTemp.createTempSync('tinest-quality-dag-');
    addTearDown(() => root.deleteSync(recursive: true));
    for (final package in <String>{
      'agent',
      'app',
      'cli',
      'client',
      'daemon',
      'protocol',
      'relay',
      'relay_protocol',
      'tinest_quality',
    }) {
      final directory = Directory(p.join(root.path, 'packages', package))
        ..createSync(recursive: true);
      File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
        'name: $package\n'
        '${package == 'agent' ? 'dependencies:\n  protocol: any\n' : ''}',
      );
    }

    final violations = ArchitectureVerifier(root.path).verify();

    expect(
      violations.map((violation) => violation.rule),
      contains('package_dependency_direction'),
    );
  });

  test('valid application fixture depends only on an injected API', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source:
          "import 'package:client/client.dart';\n"
          'final TinestApi api = throw UnimplementedError();',
    );
    expect(violations, isEmpty);
  });

  test('Windows-style paths resolve the same exemptions as POSIX paths', () {
    // On Windows the filesystem walk hands in backslash-separated relative
    // paths; every rule matches forward-slash layouts, so without one
    // canonical form an exempted vendor file is falsely flagged.
    final violations = verifier.verifySource(
      package: 'daemon',
      path:
          r'packages\daemon\lib\src\features\providers\infrastructure'
          r'\anthropic\anthropic_provider.dart',
      source: "const vendor = 'anthropic';",
    );
    expect(violations, isEmpty);
  });

  test('invalid application fixture reports imports and concrete calls', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source:
          "import 'dart:io';\n"
          "import 'package:uuid/uuid.dart';\n"
          'final now = DateTime.now();\n'
          'final id = Uuid();',
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('feature application directories enforce application rules', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/sessions/application/'
          'sessions_controller.dart',
      source: "import 'dart:io';\nfinal process = Process.start;",
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('feature presentation cannot import another feature presentation', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/sessions/presentation/'
          'session_page.dart',
      source: <String>[
        "import 'package:app/src/features/settings/presentation/pages/",
        "settings_page.dart';",
      ].join(),
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('feature_presentation_dependency'),
    );
  });

  test('shared code cannot depend on a feature', () {
    final violations = verifier.verifySource(
      package: 'app',
      path: 'packages/app/lib/src/shared/presentation/list_row.dart',
      source: <String>[
        "import 'package:app/src/features/workspace/domain/",
        "workspace_selection.dart';",
      ].join(),
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('shared_feature_dependency'),
    );
  });

  test('feature domain stays independent of framework layers', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/workspace/domain/'
          'workspace_selection.dart',
      source: "import 'package:flutter/widgets.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('domain_framework_dependency'),
    );
  });

  test('a vendor name in shared code is a violation', () {
    for (final package in const <String>[
      'agent',
      'daemon',
      'client',
      'cli',
      'app',
      'protocol',
    ]) {
      final violations = verifier.verifySource(
        package: package,
        path: '$package/lib/src/service.dart',
        source: "if (definition.id == 'openai') connectChatGpt();",
      );
      expect(
        violations.map((violation) => violation.rule),
        contains('vendor_literal'),
        reason: package,
      );
    }
  });

  test('app presentation cannot draw a local focus ring', () {
    for (final source in const <String>[
      'final width = TRControlMetrics.focusWidth;',
      'final color = context.tinyrackTheme.focus;',
      'final color = colors.focus;',
    ]) {
      final violations = verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/shared/presentation/control.dart',
        source: source,
      );
      expect(
        violations.map((violation) => violation.rule),
        contains('local_focus_style'),
        reason: source,
      );
    }
  });

  test('terminal adapter may inject the design-system focus caret color', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/terminals/presentation/'
            'tinest_terminal_view.dart',
        source: 'cursor: colors.focus,',
      ),
      isEmpty,
    );
  });

  // A rule that never fires is indistinguishable from no rule, so each of the
  // two below is pinned by a case that must fire and a case that must not.
  test('an unlisted keepAlive provider must name who ends its lifetime', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/terminals/application/'
          'terminal_session_controller.dart',
      source:
          '@Riverpod(keepAlive: true)\n'
          '/// Doc comments sit between the annotation and the class here.\n'
          'class TerminalSessionController '
          r'extends _$TerminalSessionController {}',
    );
    expect(violations, hasLength(1));
    expect(violations.single.rule, 'keepalive_provider_owner');
    expect(violations.single.message, contains('TerminalSessionController'));
  });

  test('a keepAlive provider function is caught the same as a class', () {
    // `activeHostId` is a plain annotated function rather than a notifier, and
    // it is listed, so the shape must resolve to its name rather than to null.
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/hosts/application/'
            'host_controller.dart',
        source:
            '@Riverpod(keepAlive: true)\n'
            '/// The daemon that host-scoped screens read and write.\n'
            'String? activeHostId(Ref ref) => null;',
      ),
      isEmpty,
    );
  });

  test('an auto-disposed provider needs no ownership entry', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/terminals/application/'
            'terminal_session_leases.dart',
        source:
            '@riverpod\n'
            r'class TerminalSessionLeases extends _$TerminalSessionLeases {}',
      ),
      isEmpty,
    );
  });

  test('application code cannot borrow a widget lifetime', () {
    final violations = verifier.verifySource(
      package: 'app',
      path:
          'packages/app/lib/src/features/providers/application/'
          'model_picker_options.dart',
      source: 'Future<void> load(WidgetRef ref) async {}',
    );
    expect(violations, hasLength(1));
    expect(violations.single.rule, 'application_widget_ref');
  });

  test('application code may still hold a provider Ref', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/providers/application/'
            'model_picker_options.dart',
        source:
            "import 'package:riverpod_annotation/riverpod_annotation.dart';\n"
            'Future<void> load(Ref ref) async {}',
      ),
      isEmpty,
    );
  });

  // The four negatives below are the real shapes this tree uses. Each one sits
  // inside a lifecycle method and each one is correct, which is exactly why the
  // rule cannot be a line match.
  test('invalidating through a private helper of a lifecycle method fires', () {
    final violations = verifier.verifySource(
      package: 'app',
      path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
      source: '''
class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  @override
  void didUpdateWidget(WorkspacePage oldWidget) {
    _releaseTerminals(oldWidget.selection);
  }

  void _releaseTerminals(WorkspaceSelection? selection) {
    ref.invalidate(terminalSessionControllerProvider('a', 'b'));
  }
}
''',
    );
    expect(violations, hasLength(1));
    expect(violations.single.rule, 'lifecycle_provider_invalidation');
    expect(violations.single.message, contains('didUpdateWidget'));
  });

  test('invalidating from a gesture closure inside build is allowed', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/skills/presentation/'
            'skill_settings_page.dart',
        source: '''
class _Page extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ErrorView(
    onRetry: () => ref.invalidate(skillsControllerProvider('host')),
  );
}
''',
      ),
      isEmpty,
    );
  });

  test('invalidating after the frame is allowed', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
        source: '''
class _State extends ConsumerState<Page> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(someProvider);
    });
    return const SizedBox.shrink();
  }
}
''',
      ),
      isEmpty,
    );
  });

  test('a tear-off handed to ref.listen is not a call', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
        source: '''
class _State extends ConsumerState<Page> {
  @override
  Widget build(BuildContext context) {
    ref.listen(provider, _release);
    return const SizedBox.shrink();
  }

  void _release(Object? previous, Object? next) => ref.invalidate(provider);
}
''',
      ),
      isEmpty,
    );
  });

  test('invalidating past an await in a lifecycle method is allowed', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
        source: '''
class _State extends ConsumerState<Page> {
  @override
  void didChangeDependencies() {
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    await ref.read(controller.notifier).refreshHost('host');
    ref.invalidate(provider);
  }
}
''',
      ),
      isEmpty,
    );
  });

  test('invalidating from an ordinary method is not a lifecycle call', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            'packages/app/lib/src/features/relay/presentation/'
            'relay_pairing_pages.dart',
        source: '''
class _State extends ConsumerState<Page> {
  void retryPairing() => ref.invalidate(pairingProvider);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''',
      ),
      isEmpty,
    );
  });

  test('navigating straight from build is a violation', () {
    final violations = verifier.verifySource(
      package: 'app',
      path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
      source: '''
class _State extends ConsumerState<Page> {
  @override
  Widget build(BuildContext context) {
    const WorkspaceHomeRoute().replace(context);
    return const SizedBox.shrink();
  }
}
''',
    );
    expect(violations, hasLength(1));
    expect(violations.single.rule, 'lifecycle_navigation');
  });

  test('the post-frame restore WorkspacePage uses stays allowed', () {
    expect(
      verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/app/presentation/workspace_page.dart',
        source: '''
class _State extends ConsumerState<Page> {
  @override
  Widget build(BuildContext context) {
    _restoreSelection();
    return const SizedBox.shrink();
  }

  void _restoreSelection() {
    if (_restoreScheduled) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      const WorktreeRoute(hostId: 'h').replace(context);
    });
  }
}
''',
      ),
      isEmpty,
    );
  });

  test('provider infrastructure and the composition root may name vendors', () {
    expect(
      verifier.verifySource(
        package: 'daemon',
        path:
            'packages/daemon/lib/src/features/providers/'
            'infrastructure/openai/plugins.dart',
        source: "const id = 'openai'; // ChatGPT subscription backend",
      ),
      isEmpty,
    );
    expect(
      verifier.verifySource(
        package: 'daemon',
        path: 'packages/daemon/lib/src/bootstrap/application.dart',
        source: 'final plugins = openAIFamilyPlugins(clock: clock);',
      ),
      isEmpty,
    );
  });

  test('Windows source paths use the same architecture boundaries', () {
    expect(
      verifier.verifySource(
        package: 'daemon',
        path:
            r'packages\daemon\lib\src\features\providers\infrastructure\'
            r'openai\plugins.dart',
        source: "const id = 'openai';",
      ),
      isEmpty,
    );
    expect(
      verifier.verifySource(
        package: 'app',
        path:
            r'packages\app\lib\src\features\conversation\presentation\'
            r'tools\apply_patch.dart',
        source: "const name = 'apply_patch';",
      ),
      isEmpty,
    );
  });

  test(
    'a tool name literal in the app outside its presenter is a violation',
    () {
      final violations = verifier.verifySource(
        package: 'app',
        path: 'packages/app/lib/src/chat/chat_approval_card.dart',
        source: "if (approval.toolName == 'apply_patch') showDiff();",
      );
      expect(violations.single.rule, 'tool_name_literal');

      for (final toolName in const <String>[
        'request_user_input',
        'clock__curr_time',
        'clock__sleep',
        'skills__list',
        'skills__read',
      ]) {
        final modernNameViolations = verifier.verifySource(
          package: 'app',
          path: 'packages/app/lib/src/chat/chat_tool_card.dart',
          source: "const toolName = '$toolName';",
        );
        expect(
          modernNameViolations.map((violation) => violation.rule),
          contains('tool_name_literal'),
          reason: toolName,
        );
      }

      // The presenter tree owns the names, the timeline builds the dedicated
      // cards, and other packages define the tools themselves.
      for (final (package, path) in const <(String, String)>[
        (
          'app',
          'packages/app/lib/src/features/conversation/presentation/tools/'
              'apply_patch.dart',
        ),
        (
          'app',
          'packages/app/lib/src/features/conversation/application/'
              'chat_timeline_model.dart',
        ),
        ('agent', 'packages/agent/lib/src/tools/apply_patch.dart'),
        ('daemon', 'packages/daemon/lib/src/built_in_tools.dart'),
      ]) {
        expect(
          verifier.verifySource(
            package: package,
            path: path,
            source: "const name = 'apply_patch';",
          ),
          isEmpty,
          reason: path,
        );
      }
    },
  );

  test('Windows paths preserve architecture boundary exceptions', () {
    for (final (package, path, source) in const <(String, String, String)>[
      (
        'daemon',
        r'packages\daemon\lib\src\features\providers\infrastructure\openai\wire.dart',
        "const vendor = 'openai';",
      ),
      (
        'app',
        r'packages\app\lib\src\features\conversation\presentation\tools\apply_patch.dart',
        "const tool = 'apply_patch';",
      ),
      (
        'app',
        r'packages\app\lib\src\features\conversation\application\chat_timeline_model.dart',
        "const tool = 'apply_patch';",
      ),
      (
        'app',
        r'packages\app\lib\src\features\terminals\presentation\tinest_terminal_view.dart',
        'cursor: colors.focus,',
      ),
    ]) {
      expect(
        verifier.verifySource(package: package, path: path, source: source),
        isEmpty,
        reason: path,
      );
    }
  });

  test('invalid package fixture reports a reversed dependency', () {
    final violations = verifier.verifySource(
      package: 'protocol',
      path: 'packages/protocol/lib/src/bad.dart',
      source: "import 'package:daemon/daemon.dart';",
    );
    expect(violations.single.rule, 'source_dependency_direction');
  });

  test('the daemon cannot depend on the client transport package', () {
    final violations = verifier.verifySource(
      package: 'daemon',
      path: 'packages/daemon/lib/src/bootstrap/config.dart',
      source: "import 'package:client/local_daemon.dart';",
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('source_dependency_direction'),
    );
  });

  test('the daemon server cannot own feature dispatch', () {
    final violations = verifier.verifySource(
      package: 'daemon',
      path: 'packages/daemon/lib/src/transport/rpc/server.dart',
      source: <String>[
        "import 'package:daemon/src/features/sessions/",
        "infrastructure/service.dart';\n",
        'switch (method) { case "sessions.list": break; }',
      ].join(),
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>['rpc_server_feature_import', 'central_rpc_switch']),
    );
  });

  test('the client public API cannot expose a heterogeneous event stream', () {
    final violations = verifier.verifySource(
      package: 'client',
      path: 'packages/client/lib/src/api.dart',
      source: 'sealed class ClientEvent {}',
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('raw_client_event'),
    );
  });

  test('the daemon barrel cannot export concrete host adapters', () {
    final violations = verifier.verifySource(
      package: 'daemon',
      path: 'packages/daemon/lib/daemon.dart',
      source: 'show SystemClock, UuidIdGenerator, FileProjectSettingsStore;',
    );
    expect(
      violations.map((violation) => violation.rule),
      contains('daemon_concrete_public_export'),
    );
  });

  test('the agent package stays independent of every internal package', () {
    for (final forbidden in const <String>[
      'protocol',
      'client',
      'daemon',
      'cli',
    ]) {
      final violations = verifier.verifySource(
        package: 'agent',
        path: 'packages/agent/lib/src/runtime.dart',
        source: "import 'package:$forbidden/$forbidden.dart';",
      );
      expect(violations.single.rule, 'source_dependency_direction');
    }
    expect(
      verifier.verifySource(
        package: 'daemon',
        path:
            'packages/daemon/lib/src/features/mcp/'
            'infrastructure/mcp_service.dart',
        source:
            "import 'package:daemon/src/features/mcp/infrastructure/mcp.dart';",
      ),
      isEmpty,
    );
  });

  test('the PTY package is reachable only from the daemon', () {
    for (final package in const <String>[
      'agent',
      'protocol',
      'app',
      'cli',
      'client',
    ]) {
      final violations = verifier.verifySource(
        package: package,
        path: 'packages/$package/lib/src/bad.dart',
        source: "import 'package:ptyworld/ptyworld.dart';",
      );
      expect(violations.single.rule, 'source_dependency_direction');
    }
    expect(
      verifier.verifySource(
        package: 'daemon',
        path: 'packages/daemon/lib/src/portable_terminal.dart',
        source: "import 'package:ptyworld/ptyworld.dart';",
      ),
      isEmpty,
    );
  });

  test('an unrestricted external package stays reachable everywhere', () {
    // The PTY restriction must not accidentally generalise: only packages
    // named in the external map are confined, so ordinary third-party
    // dependencies stay unrestricted.
    for (final package in const <String>['agent', 'protocol']) {
      expect(
        verifier.verifySource(
          package: package,
          path: 'packages/$package/lib/src/fine.dart',
          source: "import 'package:path/path.dart';",
        ),
        isEmpty,
      );
    }
  });

  test('the MCP service is held to the application-layer rules', () {
    final violations = verifier.verifySource(
      package: 'daemon',
      path: 'packages/daemon/lib/src/mcp_service.dart',
      source:
          "import 'dart:io';\n"
          'final started = Process.start;\n'
          'final now = DateTime.now();',
    );
    expect(
      violations.map((violation) => violation.rule),
      containsAll(<String>[
        'application_infrastructure_import',
        'application_concrete_dependency',
      ]),
    );
  });

  test('every daemon application boundary rejects concrete infrastructure', () {
    for (final file in const <String>[
      'session_interactions.dart',
      'session_settings.dart',
      'mcp_server_service.dart',
      'workspace_service.dart',
    ]) {
      final violations = verifier.verifySource(
        package: 'daemon',
        path: 'packages/daemon/lib/src/$file',
        source: "import 'dart:io';\nfinal process = Process.start;",
      );
      expect(
        violations.map((violation) => violation.rule),
        containsAll(<String>[
          'application_infrastructure_import',
          'application_concrete_dependency',
        ]),
        reason: file,
      );
    }
  });
}
