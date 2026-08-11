@Tags(<String>['feature_test__lua_tool_orchestration__unit'])
library;

import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test('the surface exposes only exec and wait and documents nested tools', () {
    const provider = LuaCodeModeToolProvider();
    final nested = <AgentTool>[_NestedEchoTool()];
    final surface = provider.buildSurface(_scope(_FakeLuaHost()), nested);

    expect(surface.tools.map((tool) => tool.name), <String>['exec', 'wait']);
    expect(surface.nestedTools, nested);
    expect(surface.promptFragment, contains('tools.echo'));
    expect(surface.promptFragment, contains('await_all'));
    expect(surface.promptFragment, contains('ALL_TOOLS'));
  });

  test(
    'exec validates source and forwards bounded options to the host',
    () async {
      final host = _FakeLuaHost();
      final tool = LuaExecTool(
        host: host,
        nestedTools: <AgentTool>[_NestedEchoTool()],
      );
      final context = ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
        callId: 'outer',
        nestedTools: _EchoInvoker(),
      );

      final result = await tool.executeFreeform(
        '-- @exec: {"yield_time_ms": 999999, "max_output_tokens": 1}\n'
        'text("done")',
        context,
      );

      expect(host.request!.source, contains('text("done")'));
      expect(host.request!.yieldTime, const Duration(seconds: 60));
      expect(host.request!.maxOutputTokens, 256);
      final definition = host.request!.tools.single;
      expect(definition.kind, 'function');
      expect(definition.exposure, 'advertised');
      expect(definition.namespace, isNull);
      expect(definition.inputSchema, _NestedEchoTool().strictJsonSchema);
      expect(result.output, contains('Script completed'));
      expect(result.output, contains('done'));
    },
  );

  test('wait resumes or terminates a cell through the session host', () async {
    final host = _FakeLuaHost();
    final tool = LuaWaitTool(host: host);
    final result = await tool.execute(
      <String, dynamic>{
        'cell_id': 'lua-7',
        'yield_time_ms': null,
        'max_tokens': null,
        'terminate': true,
      },
      ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
      ),
    );

    expect(host.waitCellId, 'lua-7');
    expect(host.terminated, isTrue);
    expect(result.output, contains('Script terminated'));
  });

  test('notify values remain separate from textual Lua output', () async {
    final host = _FakeLuaHost(
      result: const LuaCellChunk(
        cellId: 'lua-1',
        output: 'visible',
        notifications: <Object?>[
          <String, Object?>{'progress': 1},
        ],
      ),
    );
    final result =
        await LuaExecTool(
          host: host,
          nestedTools: const <AgentTool>[],
        ).executeFreeform(
          'notify({progress=1}); text("visible")',
          ToolExecutionContext(
            workspaceRoot: '/workspace',
            cancellation: CancellationToken(),
          ),
        );

    expect(result.output, contains('visible'));
    expect(result.output, isNot(contains('progress')));
    expect(result.notifications, <Object?>[
      <String, Object?>{'progress': 1},
    ]);
  });
}

AgentToolScope _scope(LuaCodeModeHost host) => AgentToolScope(
  session: const AgentSessionContext(id: 'session'),
  definition: const AgentDefinitionContext(id: 'tinest'),
  selectedToolIds: const <String>{},
  workspaceRoot: '/workspace',
  turnId: 'turn',
  attachmentPublisher: const _UnusedPorts(),
  attachmentReader: const _UnusedPorts(),
  clock: const _UnusedPorts(),
  questions: const _UnusedPorts(),
  execHost: const _UnusedPorts(),
  skills: const _UnusedSkills(),
  luaCodeModeHost: host,
  toolSurfaceMode: AgentToolSurfaceMode.luaCode,
);

final class _FakeLuaHost implements LuaCodeModeHost {
  _FakeLuaHost({
    this.result = const LuaCellChunk(cellId: 'lua-1', output: 'done'),
  });

  final LuaCellChunk result;
  LuaExecuteRequest? request;
  String? waitCellId;
  bool terminated = false;

  @override
  Future<LuaCellChunk> execute(
    LuaExecuteRequest request,
    ToolExecutionContext context,
  ) async {
    this.request = request;
    return result;
  }

  @override
  Future<LuaCellChunk> wait(
    LuaWaitRequest request,
    ToolExecutionContext context,
  ) async {
    waitCellId = request.cellId;
    terminated = request.terminate;
    return LuaCellChunk(
      cellId: request.cellId,
      output: '',
      terminated: request.terminate,
    );
  }
}

final class _EchoInvoker implements NestedToolInvoker {
  @override
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  ) async => ToolResult(value: arguments['value'] as String? ?? 'ok');
}

final class _NestedEchoTool extends AgentTool {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echo a value.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => const <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'value': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['value'],
    'additionalProperties': false,
  };

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async => const ToolResult(value: 'unused');
}

final class _UnusedPorts
    implements
        AttachmentPublisher,
        AttachmentReader,
        AgentClock,
        UserQuestionCoordinator,
        ExecSessionHost {
  const _UnusedPorts();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}

final class _UnusedSkills implements SkillCatalog {
  const _UnusedSkills();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('$invocation');
}
