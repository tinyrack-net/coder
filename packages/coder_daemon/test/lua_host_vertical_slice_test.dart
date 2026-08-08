@Tags(<String>[
  'feature_test__lua_tool_orchestration__verticalSlice',
  'feature_test__lua_tool_orchestration__platformSmoke',
])
library;

import 'dart:async';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/lua_code_mode_service.dart';
import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;
import 'package:test/test.dart';

void main() {
  test(
    'official Lua host resumes parallel nested reads in its sandbox',
    () async {
      final root = _repositoryRoot();
      final staging = await Directory.systemTemp.createTemp(
        'coder-lua-tool-runtime-',
      );
      addTearDown(() => staging.delete(recursive: true));
      await lua.stageLuaToolRuntime(
        destination: staging.path,
        buildMode: lua.LuaBuildMode.debug,
      );
      final service = LuaCodeModeService(
        lua.LuaToolRuntime<ConversationAttachment>(
          host: lua.LuaHostCommand.fromDirectory(staging.path),
          processLauncher: const lua.IoLuaHostProcessLauncher(),
          clock: const lua.SystemLuaClock(),
          ids: _Ids(),
        ),
      );
      addTearDown(service.close);
      final invoker = _ParallelEchoInvoker();
      final context = ToolExecutionContext(
        workspaceRoot: root.path,
        cancellation: CancellationToken(),
        callId: 'exec-parent',
        nestedTools: invoker,
      );
      const request = LuaExecuteRequest(
        source: '''
local first = spawn(function() return tools.echo({value="a"}) end)
local second = spawn(function() return tools.echo({value="b"}) end)
local values = await_all({first, second})
text(values[1][1].output .. values[2][1].output)
text(tostring(io) .. ":" .. tostring(os) .. ":" .. tostring(package))
store("null-value", NULL)
local cyclic = {}; cyclic.self = cyclic
text(tostring(pcall(function() store("cyclic", cyclic) end)))
''',
        yieldTime: Duration(seconds: 5),
        maxOutputTokens: 1000,
        tools: <LuaNestedToolDefinition>[
          LuaNestedToolDefinition(
            name: 'echo',
            description: 'Echoes one value.',
            inputSchema: <String, dynamic>{'type': 'object'},
          ),
        ],
      );

      var chunk = await service.execute(
        owner: 'session',
        workingDirectory: root.path,
        request: request,
        context: context,
      );
      final output = StringBuffer()..write(chunk.output);
      while (chunk.running) {
        chunk = await service.wait(
          owner: 'session',
          request: LuaWaitRequest(
            cellId: chunk.cellId,
            yieldTime: const Duration(seconds: 5),
            maxOutputTokens: 1000,
            terminate: false,
          ),
          context: context,
        );
        if (chunk.output.isNotEmpty) output.write('\n${chunk.output}');
      }

      expect(output.toString(), contains('ab'));
      expect(output.toString(), contains('nil:nil:nil'));
      expect(output.toString(), contains('false'));
      expect(invoker.maximumActive, 2);

      final stored = await service.execute(
        owner: 'session',
        workingDirectory: root.path,
        request: const LuaExecuteRequest(
          source: 'text(tostring(load("null-value")))',
          yieldTime: Duration(seconds: 5),
          maxOutputTokens: 1000,
          tools: <LuaNestedToolDefinition>[],
        ),
        context: context,
      );
      expect(stored.output, contains('null'));
    },
  );
}

Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !Directory('${directory.path}/packages/coder_daemon').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Repository root not found.');
    }
    directory = parent;
  }
  return directory;
}

final class _ParallelEchoInvoker implements NestedToolInvoker {
  int _active = 0;
  int maximumActive = 0;

  @override
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    _active += 1;
    if (_active > maximumActive) maximumActive = _active;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    _active -= 1;
    return ToolResult(output: arguments['value']! as String);
  }
}

final class _Ids implements lua.LuaIdGenerator {
  @override
  String generate() => 'vertical';
}
