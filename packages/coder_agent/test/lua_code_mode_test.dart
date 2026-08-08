@Tags(<String>['feature_test__lua_tool_orchestration__unit'])
library;

import 'package:coder_agent/coder_agent.dart';
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

      final result = await tool.execute(<String, dynamic>{
        'source': 'text("done")',
        'yield_time_ms': 999999,
        'max_output_tokens': 1,
      }, context);

      expect(host.request!.source, 'text("done")');
      expect(host.request!.yieldTime, const Duration(seconds: 60));
      expect(host.request!.maxOutputTokens, 256);
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
}

AgentToolScope _scope(LuaCodeModeHost host) => AgentToolScope(
  session: const AgentSessionContext(id: 'session'),
  definition: const AgentDefinitionContext(id: 'coder'),
  selectedToolIds: const <String>{'lua_code_mode'},
  workspaceRoot: '/workspace',
  turnId: 'turn',
  attachmentPublisher: const _UnusedPorts(),
  attachmentReader: const _UnusedPorts(),
  clock: const _UnusedPorts(),
  questions: const _UnusedPorts(),
  execHost: const _UnusedPorts(),
  skills: const _UnusedSkills(),
  luaCodeModeHost: host,
);

final class _FakeLuaHost implements LuaCodeModeHost {
  LuaExecuteRequest? request;
  String? waitCellId;
  bool terminated = false;

  @override
  Future<LuaCellChunk> execute(
    LuaExecuteRequest request,
    ToolExecutionContext context,
  ) async {
    this.request = request;
    return const LuaCellChunk(cellId: 'lua-1', output: 'done');
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
  ) async => ToolResult(output: arguments['value'] as String? ?? 'ok');
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
  ) async => const ToolResult(output: 'unused');
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
