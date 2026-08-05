@Tags(<String>['feature_test__mcp_tool_execution__unit'])
library;

import 'dart:async';
import 'dart:io';

import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  const readFile = AgentToolDefinitionDto(
    id: 'read_file',
    name: 'read_file',
    description: 'Read files.',
    risk: ToolRisk.read,
    alwaysOn: true,
  );
  const runCommand = AgentToolDefinitionDto(
    id: 'run_command',
    name: 'run_command',
    description: 'Run a command.',
    risk: ToolRisk.command,
  );
  const projectTool = AgentToolDefinitionDto(
    id: 'mcp__repo__lint',
    name: 'mcp__repo__lint',
    description: 'Lint the repository.',
    risk: ToolRisk.dangerous,
  );

  test('read-only built-in tools are always on', () {
    expect(alwaysOnBuiltInToolIds, <String>{
      'list_directory',
      'read_file',
      'search_text',
      'attach_file',
      'read_attachment',
    });
  });

  test('resolution forces the always-on tools ahead of the chosen ones', () {
    expect(
      resolveAgentToolIds(const <String>['run_command']),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'attach_file',
        'read_attachment',
        'run_command',
      ],
    );
    // An agent that still lists a read tool gets it once, not twice.
    expect(
      resolveAgentToolIds(const <String>['read_file', 'mcp__repo__lint']),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'attach_file',
        'read_attachment',
        'mcp__repo__lint',
      ],
    );
    expect(
      resolveAgentToolIds(const <String>[]),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'attach_file',
        'read_attachment',
      ],
    );
  });

  test('a static catalog reports its tools and never changes', () async {
    const catalog = StaticAgentToolCatalog(<AgentToolDefinitionDto>[
      readFile,
      runCommand,
    ]);

    expect(catalog.tools().map((tool) => tool.id), <String>[
      'read_file',
      'run_command',
    ]);
    expect(
      catalog.tools(workspaceRoot: '/repo').map((tool) => tool.id),
      <String>['read_file', 'run_command'],
    );
    expect(await catalog.changes.isEmpty, isTrue);
  });

  test('a composite catalog merges its sources and their changes', () async {
    final dynamicCatalog = _FakeCatalog();
    final catalog = CompositeAgentToolCatalog(<AgentToolCatalog>[
      const StaticAgentToolCatalog(<AgentToolDefinitionDto>[readFile]),
      dynamicCatalog,
    ]);
    addTearDown(dynamicCatalog.close);

    expect(catalog.tools().map((tool) => tool.id), <String>['read_file']);

    final changes = <void>[];
    final subscription = catalog.changes.listen(changes.add);
    addTearDown(subscription.cancel);

    dynamicCatalog
      ..scoped['/repo'] = <AgentToolDefinitionDto>[projectTool]
      ..announce();
    await pumpEventQueue();

    expect(changes, hasLength(1));
    expect(catalog.tools().map((tool) => tool.id), <String>['read_file']);
    expect(
      catalog.tools(workspaceRoot: '/repo').map((tool) => tool.id),
      <String>['read_file', 'mcp__repo__lint'],
    );
  });

  group('with a service', () {
    late Directory directory;
    late _FakeCatalog dynamicCatalog;
    late AgentDefinitionService service;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('coder-mcp-catalog-');
      dynamicCatalog = _FakeCatalog();
      service = AgentDefinitionService(
        store: FileAgentDefinitionStore(directory.path),
        tools: CompositeAgentToolCatalog(<AgentToolCatalog>[
          const StaticAgentToolCatalog(<AgentToolDefinitionDto>[
            readFile,
            runCommand,
          ]),
          dynamicCatalog,
        ]),
      );
      await service.initialize();
    });

    tearDown(() async {
      await service.close();
      await dynamicCatalog.close();
      await directory.delete(recursive: true);
    });

    test('the catalog is sorted and scoped to a workspace', () {
      expect(service.toolCatalog().map((tool) => tool.id), <String>[
        'read_file',
        'run_command',
      ]);

      dynamicCatalog.scoped['/repo'] = <AgentToolDefinitionDto>[projectTool];

      expect(
        service.toolCatalog(workspaceRoot: '/repo').map((tool) => tool.id),
        <String>['mcp__repo__lint', 'read_file', 'run_command'],
      );
      expect(service.toolCatalog().map((tool) => tool.id), <String>[
        'read_file',
        'run_command',
      ]);
    });

    test('a tool that appears later is no longer unavailable', () async {
      final coder = await service.get('coder');
      final reviewer = await service.create(
        'reviewer',
        coder.copyWith(
          id: 'reviewer',
          name: 'Reviewer',
          mode: AgentMode.subagent,
          toolIds: const <String>['mcp__repo__lint'],
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );
      expect(
        reviewer.diagnostics.map((diagnostic) => diagnostic.code),
        contains('unavailable_tool'),
      );

      dynamicCatalog.unscoped.add(projectTool);

      expect(
        (await service.get('reviewer')).diagnostics,
        isEmpty,
      );
    });

    test('an always-on id is never reported as unavailable', () async {
      // A daemon may drop a built-in from its catalog, but an agent that
      // still lists a read tool is not misconfigured: it gets it regardless.
      final bare = AgentDefinitionService(
        store: FileAgentDefinitionStore(directory.path),
        tools: const StaticAgentToolCatalog(<AgentToolDefinitionDto>[
          runCommand,
        ]),
      );
      addTearDown(bare.close);
      await bare.initialize();

      final coder = await bare.get('coder');
      final legacy = await bare.create(
        'legacy',
        coder.copyWith(
          id: 'legacy',
          name: 'Legacy',
          mode: AgentMode.subagent,
          toolIds: const <String>['read_file', 'search_text'],
          callableAgentIds: const <String>[],
          contentHash: '',
          sourcePath: '',
          isBuiltIn: false,
        ),
      );

      expect(legacy.diagnostics, isEmpty);
    });

    test(
      'the built-in agent only opts into the write and command tools',
      () async {
        final coder = await service.get('coder');

        expect(coder.toolIds, <String>['apply_patch', 'run_command']);
        expect(
          resolveAgentToolIds(coder.toolIds),
          <String>[
            'list_directory',
            'read_file',
            'search_text',
            'attach_file',
            'read_attachment',
            'apply_patch',
            'run_command',
          ],
        );
      },
    );

    test('service changes fire for source and catalog updates', () async {
      final changes = <void>[];
      final subscription = service.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      dynamicCatalog.announce();
      await pumpEventQueue();

      expect(changes, hasLength(1));
    });
  });
}

final class _FakeCatalog implements AgentToolCatalog {
  final List<AgentToolDefinitionDto> unscoped = <AgentToolDefinitionDto>[];
  final Map<String, List<AgentToolDefinitionDto>> scoped =
      <String, List<AgentToolDefinitionDto>>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  void announce() => _changes.add(null);

  Future<void> close() => _changes.close();

  @override
  List<AgentToolDefinitionDto> tools({String? workspaceRoot}) =>
      <AgentToolDefinitionDto>[
        ...unscoped,
        if (workspaceRoot != null) ...?scoped[workspaceRoot],
      ];
}
