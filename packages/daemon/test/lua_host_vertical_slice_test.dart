@Tags(<String>[
  'feature_test__lua_tool_orchestration__verticalSlice',
  'feature_test__lua_tool_orchestration__platformSmoke',
])
library;

import 'dart:async';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/lua_code_mode_service.dart';
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
      final buildDirectory = await Directory.systemTemp.createTemp(
        'coder-lua-tool-runtime-build-',
      );
      addTearDown(() => staging.delete(recursive: true));
      addTearDown(() => buildDirectory.delete(recursive: true));
      await lua.stageLuaToolRuntime(
        destination: staging.path,
        buildMode: lua.LuaBuildMode.debug,
        buildDirectory: buildDirectory.path,
        cmakeExecutable: await _cmakeExecutable(),
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
text(values[1][1] .. values[2][1])
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
            kind: 'function',
            exposure: 'nested',
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

Future<String> _cmakeExecutable() async {
  if (!Platform.isWindows) return 'cmake';
  final onPath = await Process.run('where.exe', <String>['cmake']);
  if (onPath.exitCode == 0) {
    final candidates = (onPath.stdout as String)
        .split(RegExp(r'[\r\n]+'))
        .where((line) => line.isNotEmpty);
    if (candidates.isNotEmpty) return candidates.first;
  }
  final programFilesX86 = Platform.environment['ProgramFiles(x86)'];
  if (programFilesX86 != null) {
    final vswhere = File(
      '$programFilesX86/Microsoft Visual Studio/Installer/vswhere.exe',
    );
    if (vswhere.existsSync()) {
      final result = await Process.run(vswhere.path, const <String>[
        '-latest',
        '-products',
        '*',
        '-requires',
        'Microsoft.VisualStudio.Component.VC.CMake.Project',
        '-find',
        r'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe',
      ]);
      final candidate = (result.stdout as String).trim();
      if (result.exitCode == 0 && candidate.isNotEmpty) return candidate;
    }
  }
  return 'cmake';
}

Directory _repositoryRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !Directory('${directory.path}/packages/daemon').existsSync()) {
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
    return ToolResult(value: arguments['value']! as String);
  }
}

final class _Ids implements lua.LuaIdGenerator {
  @override
  String generate() => 'vertical';
}
