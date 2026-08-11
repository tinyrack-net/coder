@Tags(<String>['feature_test__mcp_tool_execution__unit'])
library;

import 'dart:async';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:daemon/src/features/agents/infrastructure/built_in_tools.dart';
import 'package:daemon/src/shared/ports/agent_protocol_mapping.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  // A registry standing in for the daemon's, with the runtime-backed
  // capabilities stubbed: nothing here needs a live MCP pool or supervisor.
  final registry = builtInAgentToolRegistry(
    gitignoreEnvironment: const GitignoreEnvironment.none(),
    mcpResourceHostFor: (_) => throw UnimplementedError(),
    multiAgent: () => null,
  );

  const readFile = AgentToolDefinitionDto(
    id: 'read_file',
    name: 'read_file',
    description: 'Read files.',
    risk: ToolRisk.read,
    group: ToolGroup.filesystem,
    alwaysOn: true,
  );
  const runCommand = AgentToolDefinitionDto(
    id: 'run_command',
    name: 'run_command',
    description: 'Run a command.',
    risk: ToolRisk.command,
    group: ToolGroup.execution,
  );
  const projectTool = AgentToolDefinitionDto(
    id: 'mcp__repo__lint',
    name: 'mcp__repo__lint',
    description: 'Lint the repository.',
    risk: ToolRisk.dangerous,
    group: ToolGroup.mcp,
  );

  test('read-only built-in tools are always on', () {
    expect(registry.alwaysOnIds, <String>{
      'list_directory',
      'read_file',
      'search_text',
      'glob',
      'update_plan',
      'attach_file',
      'clock__curr_time',
      'clock__sleep',
      'view_image',
      'request_user_input',
      'read_attachment',
    });
  });

  test('every tool group has a built-in capability in it', () {
    // A group nothing belongs to would be a heading a client can never draw,
    // so a group is added with the capability that needs it and not before.
    expect(
      registry.catalog.map((entry) => entry.group).toSet(),
      AgentToolGroup.values.toSet(),
    );
  });

  test('capabilities are grouped by what they do', () {
    Set<String> idsIn(AgentToolGroup group) => <String>{
      for (final entry in registry.catalog)
        if (entry.group == group) entry.id,
    };
    expect(idsIn(AgentToolGroup.filesystem), <String>{
      'list_directory',
      'read_file',
      'search_text',
      'glob',
      'view_image',
    });
    expect(idsIn(AgentToolGroup.editing), <String>{'apply_patch'});
    expect(idsIn(AgentToolGroup.execution), <String>{'exec_command'});
    expect(idsIn(AgentToolGroup.attachments), <String>{
      'attach_file',
      'read_attachment',
    });
    expect(idsIn(AgentToolGroup.mcp), <String>{
      'list_mcp_resources',
      'list_mcp_resource_templates',
      'read_mcp_resource',
    });
    expect(idsIn(AgentToolGroup.collaboration), <String>{'collaboration'});
    expect(idsIn(AgentToolGroup.session), <String>{
      'update_plan',
      'request_user_input',
      'clock__curr_time',
      'clock__sleep',
    });
  });

  test('the protocol catalog carries each capability group', () {
    expect(
      registry.catalog
          .map(protocolToolDefinition)
          .where((entry) => entry.id == 'exec_command')
          .single
          .group,
      ToolGroup.execution,
    );
    // The twin enums are mapped by name, so a case added to one and not the
    // other has to fail here rather than at runtime on a user's machine.
    expect(
      AgentToolGroup.values.map((value) => value.name),
      ToolGroup.values.map((value) => value.name),
    );
  });

  test('resolution forces the always-on tools ahead of the chosen ones', () {
    expect(
      registry.resolveIds(const <String>['exec_command']),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'glob',
        'update_plan',
        'attach_file',
        'clock__curr_time',
        'clock__sleep',
        'view_image',
        'request_user_input',
        'read_attachment',
        'exec_command',
      ],
    );
    // An agent that still lists a read tool gets it once, not twice.
    expect(
      registry.resolveIds(const <String>['read_file', 'mcp__repo__lint']),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'glob',
        'update_plan',
        'attach_file',
        'clock__curr_time',
        'clock__sleep',
        'view_image',
        'request_user_input',
        'read_attachment',
        'mcp__repo__lint',
      ],
    );
    expect(
      registry.resolveIds(const <String>[]),
      <String>[
        'list_directory',
        'read_file',
        'search_text',
        'glob',
        'update_plan',
        'attach_file',
        'clock__curr_time',
        'clock__sleep',
        'view_image',
        'request_user_input',
        'read_attachment',
      ],
    );
  });

  test('the built-in catalog advertises every compiled-in tool', () {
    final definitions = registry.catalog;

    // Pins the public catalog so moving a definition next to its tool cannot
    // silently drop an entry, change a risk, or make an opt-in tool always-on.
    expect(
      definitions.map(
        (tool) =>
            '${tool.id} ${tool.risk.name} '
            '${tool.alwaysOn ? 'always-on' : 'opt-in'}',
      ),
      <String>[
        'list_directory read always-on',
        'read_file read always-on',
        'search_text read always-on',
        'glob read always-on',
        'update_plan read always-on',
        'apply_patch write opt-in',
        'attach_file read always-on',
        'clock__curr_time read always-on',
        'clock__sleep read always-on',
        'list_mcp_resources read opt-in',
        'list_mcp_resource_templates read opt-in',
        'read_mcp_resource read opt-in',
        'exec_command command opt-in',
        'view_image read always-on',
        'request_user_input read always-on',
        'read_attachment read always-on',
        'collaboration read opt-in',
      ],
    );
    // The name is what the model calls; nothing may advertise an id it cannot
    // be invoked by.
    for (final tool in definitions) {
      expect(tool.name, tool.id);
      expect(tool.description, isNotEmpty);
    }
  });

  test('every always-on tool id is one the catalog actually advertises', () {
    final advertised = registry.catalog.map((tool) => tool.id).toSet();

    expect(registry.alwaysOnIds.difference(advertised), isEmpty);
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
      directory = await Directory.systemTemp.createTemp('tinest-mcp-catalog-');
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
        alwaysOnToolIds: registry.alwaysOnIds,
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
      final tinest = await service.get('tinest');
      final reviewer = await service.create(
        'reviewer',
        tinest.copyWith(
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
        alwaysOnToolIds: registry.alwaysOnIds,
      );
      addTearDown(bare.close);
      await bare.initialize();

      final tinest = await bare.get('tinest');
      final legacy = await bare.create(
        'legacy',
        tinest.copyWith(
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
      'the built-in agent enables every selectable built-in tool',
      () async {
        final tinest = await service.get('tinest');

        expect(tinest.toolIds, <String>[
          'apply_patch',
          'list_mcp_resources',
          'list_mcp_resource_templates',
          'read_mcp_resource',
          'exec_command',
          'collaboration',
        ]);
        expect(
          registry.resolveIds(tinest.toolIds),
          <String>[
            'list_directory',
            'read_file',
            'search_text',
            'glob',
            'update_plan',
            'attach_file',
            'clock__curr_time',
            'clock__sleep',
            'view_image',
            'request_user_input',
            'read_attachment',
            'apply_patch',
            'list_mcp_resources',
            'list_mcp_resource_templates',
            'read_mcp_resource',
            'exec_command',
            'collaboration',
          ],
        );
      },
      tags: const <String>['feature_test__agent_definition_management__unit'],
    );

    test(
      'the built-in agent lists nothing this daemon cannot supply',
      () async {
        // The shipped definition names capabilities by id, and nothing keeps
        // that list in step with the registry. Wire the service to the real
        // built-in catalog the way the daemon does so a retired or renamed id
        // fails here instead of showing every user an unavailable_tool
        // warning on the one agent they cannot delete.
        final real = AgentDefinitionService(
          store: FileAgentDefinitionStore(directory.path),
          tools: StaticAgentToolCatalog(
            registry.catalog.map(protocolToolDefinition).toList(),
          ),
          alwaysOnToolIds: registry.alwaysOnIds,
        );
        addTearDown(real.close);
        await real.initialize();

        expect((await real.get('tinest')).diagnostics, isEmpty);
      },
      tags: const <String>['feature_test__agent_definition_management__unit'],
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
