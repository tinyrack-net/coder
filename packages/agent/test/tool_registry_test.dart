@Tags(<String>['feature_test__turn_execution__unit'])
library;

import 'package:agent/agent.dart';
import 'package:test/test.dart';

import 'support/conformance.dart';

void main() {
  final registry = AgentToolRegistry(_providers());

  for (final provider in _providers()) {
    agentToolProviderConformanceTests(provider.id, () => provider);
  }

  test('the catalog is derived from the providers, in their order', () {
    expect(registry.catalog.map((entry) => entry.id), <String>[
      'list_directory',
      'read_file',
      'search_text',
      'glob',
      'update_plan',
      'apply_patch',
      'attach_file',
      'read_attachment',
      'view_image',
      'request_user_input',
      'clock__curr_time',
      'clock__sleep',
      'exec_command',
    ]);
    // Hidden capabilities are built, never advertised.
    expect(
      registry.providers.map((provider) => provider.id),
      containsAll(<String>['context_window', 'skills']),
    );
    expect(registry.alwaysOnIds, isNot(contains('apply_patch')));
    expect(registry.alwaysOnIds, isNot(contains('exec_command')));
    expect(registry.alwaysOnIds, contains('read_file'));
  });

  test('resolution forces the always-on capabilities ahead and once', () {
    final resolved = registry.resolveIds(const <String>[
      'read_file',
      'exec_command',
    ]);
    expect(resolved.where((id) => id == 'read_file'), hasLength(1));
    expect(resolved.last, 'exec_command');
  });

  test('the registry rejects a duplicate and a mislabelled provider', () {
    expect(
      () => AgentToolRegistry(<AgentToolProvider>[
        const ReadFileToolProvider(),
        const ReadFileToolProvider(),
      ]),
      throwsStateError,
    );
    expect(
      () => AgentToolRegistry(<AgentToolProvider>[_Mislabelled()]),
      throwsStateError,
    );
  });

  test('a turn builds selected capabilities, hidden ones, and externals', () {
    final scope = _scope(
      selected: registry.resolveIds(const <String>[
        'apply_patch',
        'exec_command',
        'mcp__repo__lint',
      ]).toSet(),
      skills: const <SkillSummary>[
        SkillSummary(name: 'commit', description: 'Writes commits.'),
      ],
    );

    final turn = registry.build(
      scope,
      external: (id) => id == 'mcp__repo__lint' ? _ExternalTool(id) : null,
    );
    final names = turn.tools.map((tool) => tool.name).toList();

    // One capability, two tools: nobody may write to a shell they cannot
    // start.
    expect(
      names,
      containsAll(<String>[execCommandToolName, writeStdinToolName]),
    );
    expect(names, containsAll(<String>['read_file', 'apply_patch']));
    // Hidden capabilities join without being selected.
    expect(
      names,
      containsAll(<String>[
        'get_context_remaining',
        'new_context',
        listSkillsToolName,
        skillToolName,
      ]),
    );
    // Unknown ids resolve through the external source — how MCP tools
    // published at runtime join a turn without being compiled in.
    expect(names, contains('mcp__repo__lint'));
    expect(names.toSet(), hasLength(names.length));
    // Only the capabilities that wrote a prompt contribute one.
    expect(
      turn.promptFragments,
      containsAll(<Matcher>[
        contains('## Available skills'),
        contains('`apply_patch`'),
      ]),
    );
  });

  test('a selected surface replaces direct tools and retains nested tools', () {
    final surfaceRegistry = AgentToolRegistry(<AgentToolProvider>[
      const ReadFileToolProvider(),
      const _TestSurfaceProvider(),
    ]);
    final turn = surfaceRegistry.build(
      _scope(
        selected: surfaceRegistry.resolveIds(const <String>['surface']).toSet(),
      ),
    );

    expect(turn.tools.map((tool) => tool.name), <String>['orchestrate']);
    expect(turn.nestedTools.map((tool) => tool.name), <String>['read_file']);
    expect(turn.promptFragments.single, contains('Nested tool surface'));
  });

  test('the Lua surface follows the model, not the selected capabilities', () {
    // The shipped agent definitions name no Lua capability, because there is
    // none to name: the surface is hidden from the catalog and switched on by
    // the model's declared tool surface. Selecting nothing must still yield
    // exec/wait over the direct tools as nested ones.
    final luaRegistry = AgentToolRegistry(<AgentToolProvider>[
      const ReadFileToolProvider(),
      const LuaCodeModeToolProvider(),
    ]);

    final turn = luaRegistry.build(
      _scope(
        selected: luaRegistry.resolveIds(const <String>[]).toSet(),
        luaCodeModeHost: _UnusedLuaHost(),
        toolSurfaceMode: AgentToolSurfaceMode.luaCode,
      ),
    );

    expect(turn.tools.map((tool) => tool.name), <String>['exec', 'wait']);
    expect(turn.nestedTools.map((tool) => tool.name), <String>['read_file']);

    // And the same registry under the direct surface leaves the tools alone,
    // so nothing an agent lists can turn the surface on or off.
    final direct = luaRegistry.build(
      _scope(
        selected: luaRegistry.resolveIds(const <String>[]).toSet(),
        luaCodeModeHost: _UnusedLuaHost(),
      ),
    );
    expect(direct.tools.map((tool) => tool.name), <String>['read_file']);
    expect(direct.nestedTools, isEmpty);
  }, tags: const <String>['feature_test__lua_tool_orchestration__unit']);

  test('an unselected capability builds nothing and shapes nothing', () {
    final scope = _scope(
      selected: registry.resolveIds(const <String>[]).toSet(),
    );

    final turn = registry.build(scope);
    final names = turn.tools.map((tool) => tool.name).toList();

    expect(names, isNot(contains(execCommandToolName)));
    expect(names, isNot(contains('apply_patch')));
    expect(names, isNot(contains(listSkillsToolName)));
    expect(turn.promptFragments, isEmpty);
    // No exec capability in the turn, so its policy never joins the chain.
    const inner = DefaultApprovalPolicy(AgentPermissionMode.ask);
    expect(identical(turn.decoratePolicy(inner), inner), isTrue);
  });

  test('the exec capability approves its own shell, once allowed', () {
    final host = _ApprovedHost();
    final scope = _scope(
      selected: registry.resolveIds(const <String>['exec_command']).toSet(),
      execHost: host,
    );

    final policy = registry
        .build(scope)
        .decoratePolicy(const DefaultApprovalPolicy(AgentPermissionMode.ask));

    expect(
      policy.evaluate(
        const ToolInvocation(
          callId: 'call-1',
          workspaceRoot: '/workspace',
          name: writeStdinToolName,
          arguments: <String, dynamic>{'session_id': 1},
          risk: AgentToolRisk.command,
        ),
      ),
      ApprovalEvaluation.allow,
    );
    expect(
      policy.evaluate(
        const ToolInvocation(
          callId: 'call-2',
          workspaceRoot: '/workspace',
          name: execCommandToolName,
          arguments: <String, dynamic>{'cmd': 'ls'},
          risk: AgentToolRisk.command,
        ),
      ),
      ApprovalEvaluation.ask,
    );
  });

  test('the production clock reports UTC now', () {
    const clock = SystemClock();
    final now = clock.nowUtc();
    expect(now.isUtc, isTrue);
    expect(
      DateTime.now().toUtc().difference(now).inSeconds.abs(),
      lessThan(5),
    );
  });
}

List<AgentToolProvider> _providers() => <AgentToolProvider>[
  const ListDirectoryToolProvider(),
  const ReadFileToolProvider(),
  const SearchTextToolProvider(
    gitignoreEnvironment: GitignoreEnvironment.none(),
  ),
  const GlobToolProvider(gitignoreEnvironment: GitignoreEnvironment.none()),
  const UpdatePlanToolProvider(),
  const ApplyPatchToolProvider(),
  const AttachFileToolProvider(),
  const ReadAttachmentToolProvider(),
  const ViewImageToolProvider(),
  const RequestUserInputToolProvider(),
  const CurrentTimeToolProvider(),
  const SleepToolProvider(),
  const ExecCommandToolProvider(),
  const ContextWindowToolProvider(),
  const SkillToolProvider(),
];

final class _Mislabelled extends SelectableToolProvider {
  @override
  String get id => 'someone_else';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'read_file',
    name: 'read_file',
    description: 'Claims an id it does not answer to.',
    risk: AgentToolRisk.read,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => const <AgentTool>[];
}

final class _TestSurfaceProvider extends AgentToolSurfaceProvider {
  const _TestSurfaceProvider();

  @override
  String get id => 'surface';

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: 'surface',
    name: 'Surface',
    description: 'Replaces direct tools for a test.',
    risk: AgentToolRisk.read,
  );

  @override
  AgentToolSurface buildSurface(
    AgentToolScope scope,
    List<AgentTool> nestedTools,
  ) => AgentToolSurface(
    tools: <AgentTool>[_ExternalTool('orchestrate')],
    nestedTools: nestedTools,
    promptFragment: 'Nested tool surface.',
  );
}

AgentToolScope _scope({
  required Set<String> selected,
  List<SkillSummary> skills = const <SkillSummary>[],
  ExecSessionHost? execHost,
  LuaCodeModeHost? luaCodeModeHost,
  AgentToolSurfaceMode toolSurfaceMode = AgentToolSurfaceMode.direct,
}) => AgentToolScope(
  session: const AgentSessionContext(id: 'session-1'),
  definition: const AgentDefinitionContext(id: 'coder'),
  selectedToolIds: selected,
  workspaceRoot: '/workspace',
  turnId: 'turn-1',
  attachmentPublisher: const _UnusedPorts(),
  attachmentReader: const _UnusedPorts(),
  clock: const _UnusedPorts(),
  questions: const _UnusedPorts(),
  execHost: execHost ?? const _UnusedPorts(),
  skills: _StaticSkills(skills),
  luaCodeModeHost: luaCodeModeHost,
  toolSurfaceMode: toolSurfaceMode,
);

/// Satisfies the surface's host requirement without running a cell.
final class _UnusedLuaHost implements LuaCodeModeHost {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of this test: building a turn '
    'assembles the surface without executing it.',
  );
}

final class _StaticSkills implements SkillCatalog {
  const _StaticSkills(this._summaries);

  final List<SkillSummary> _summaries;

  @override
  List<SkillSummary> summaries() => _summaries;

  @override
  Future<SkillContent> read(String name) => throw UnimplementedError();

  @override
  Future<String> readResource(String name, String relativePath) =>
      throw UnimplementedError();
}

/// Stands in for every port constructing a tool never touches.
final class _UnusedPorts
    implements
        AttachmentPublisher,
        AttachmentReader,
        AgentClock,
        UserQuestionCoordinator,
        ExecSessionHost {
  const _UnusedPorts();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not part of this test: building a turn '
    'constructs tools without running one.',
  );
}

final class _ApprovedHost implements ExecSessionHost {
  @override
  bool isApproved(int sessionId) => sessionId == 1;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}

final class _ExternalTool extends AgentTool {
  _ExternalTool(this.name);

  @override
  final String name;

  @override
  String get description => 'External tool $name.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(const <String, Map<String, dynamic>>{});

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => const ToolResult(value: 'ok');
}
