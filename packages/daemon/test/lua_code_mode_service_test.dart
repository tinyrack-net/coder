@Tags(<String>[
  'feature_test__lua_tool_orchestration__contract',
  'feature_test__lua_tool_orchestration__unit',
])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/lua_code_mode_service.dart';
import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late _PipeGateway pipes;
  late LuaCodeModeService service;

  setUp(() {
    pipes = _PipeGateway();
    service = LuaCodeModeService(
      lua.LuaToolRuntime<ConversationAttachment>(
        host: const lua.LuaHostCommand(
          executable: 'lua-tool-runtime-host',
          arguments: <String>['bootstrap.lua'],
        ),
        processLauncher: pipes,
        clock: const lua.SystemLuaClock(),
        ids: _Ids(),
      ),
    );
  });

  tearDown(() => service.close());

  test('development discovery walks up from a package directory', () {
    final command = discoverLuaHostCommand(
      sourceRoot: '${Directory.current.path}/test',
    );

    expect(
      command.arguments.single,
      endsWith(
        <String>['native', 'bootstrap.lua'].join(Platform.pathSeparator),
      ),
    );
  });

  test('macOS discovery reads bootstrap from app resources', () {
    final bundle = Directory.systemTemp.createTempSync('coder-lua-bundle-');
    addTearDown(() => bundle.deleteSync(recursive: true));
    final executableDirectory = Directory(
      p.join(bundle.path, 'Coder.app', 'Contents', 'MacOS'),
    )..createSync(recursive: true);
    final helper = File(
      p.join(
        executableDirectory.path,
        Platform.isWindows
            ? 'lua-tool-runtime-host.exe'
            : 'lua-tool-runtime-host',
      ),
    )..createSync();
    final bootstrap = File(
      p.join(
        bundle.path,
        'Coder.app',
        'Contents',
        'Resources',
        'lua_tool_runtime',
        'bootstrap.lua',
      ),
    )..createSync(recursive: true);

    final command = discoverLuaHostCommand(
      sourceRoot: bundle.path,
      resolvedExecutable: p.join(executableDirectory.path, 'Coder'),
      isMacOS: true,
    );

    expect(command.executable, helper.path);
    expect(command.arguments, <String>[bootstrap.path]);
  });

  test('a nested tool batch resumes the cell and preserves output', () async {
    final invoker = _Invoker();
    final future = service.execute(
      owner: 'session-1',
      workingDirectory: '/workspace',
      request: const LuaExecuteRequest(
        source: 'text(tools.echo({value="hi"}))',
        yieldTime: Duration(seconds: 1),
        maxOutputTokens: 1000,
        tools: <LuaNestedToolDefinition>[
          LuaNestedToolDefinition(
            name: 'echo',
            description: 'Echo a value.',
            kind: 'function',
            namespace: 'sample',
            exposure: 'advertised',
            inputSchema: <String, dynamic>{'type': 'object'},
            outputSchema: <String, dynamic>{'type': 'string'},
          ),
        ],
      ),
      context: _context(invoker),
    );
    await pumpEventQueue();
    final process = pipes.process;
    final init = process.writtenFrame(0);
    final cellId = init['cell_id']! as String;
    final initPayload = Map<String, dynamic>.from(init['payload']! as Map);
    expect(initPayload['tools'], <Object?>[
      <String, Object?>{
        'name': 'echo',
        'description': 'Echo a value.',
        'kind': 'function',
        'namespace': 'sample',
        'exposure': 'advertised',
        'input_schema': <String, Object?>{'type': 'object'},
        'output_schema': <String, Object?>{'type': 'string'},
      },
    ]);

    process.emitFrame(cellId, 1, 'tool_batch', <String, dynamic>{
      'calls': <Map<String, dynamic>>[
        <String, dynamic>{
          'request_id': '1:1',
          'name': 'echo',
          'arguments': <String, dynamic>{'value': 'hi'},
        },
      ],
    });
    await pumpEventQueue();

    expect(invoker.calls, <String>['echo:hi']);
    final response = process.writtenFrame(1);
    expect(response['type'], 'tool_results');
    final responsePayload = Map<String, dynamic>.from(
      response['payload']! as Map,
    );
    final results = responsePayload['results']! as List;
    expect((results.single as Map)['value'], 'echoed hi');
    process
      ..emitFrame(cellId, 2, 'output', <String, dynamic>{
        'kind': 'notify',
        'value': <String, dynamic>{'progress': 1},
      })
      ..emitFrame(cellId, 3, 'output', <String, dynamic>{
        'kind': 'text',
        'value': 'echoed hi',
      })
      ..emitFrame(cellId, 4, 'completed', const <String, dynamic>{
        'store': <String, dynamic>{},
      });

    var chunk = await future;
    final output = StringBuffer(chunk.output);
    final notifications = <Object?>[...chunk.notifications];
    while (chunk.running) {
      chunk = await service.wait(
        owner: 'session-1',
        request: LuaWaitRequest(
          cellId: cellId,
          yieldTime: const Duration(seconds: 1),
          maxOutputTokens: 1000,
          terminate: false,
        ),
        context: _context(invoker),
      );
      output.write(chunk.output);
      notifications.addAll(chunk.notifications);
    }
    expect(chunk.running, isFalse);
    expect(output.toString(), 'echoed hi');
    expect(notifications, <Object?>[
      <String, Object?>{'progress': 1},
    ]);
  });

  test('yielded cells resume through wait and can be terminated', () async {
    final execute = service.execute(
      owner: 'session-1',
      workingDirectory: '/workspace',
      request: const LuaExecuteRequest(
        source: 'yield_control(); text("later")',
        yieldTime: Duration(seconds: 1),
        maxOutputTokens: 1000,
        tools: <LuaNestedToolDefinition>[],
      ),
      context: _context(_Invoker()),
    );
    await pumpEventQueue();
    final cellId = pipes.process.writtenFrame(0)['cell_id']! as String;
    pipes.process.emitFrame(cellId, 1, 'yielded', const <String, dynamic>{
      'store': <String, dynamic>{},
    });

    final first = await execute;
    expect(first.running, isTrue);

    final resumed = service.wait(
      owner: 'session-1',
      request: LuaWaitRequest(
        cellId: cellId,
        yieldTime: const Duration(seconds: 1),
        maxOutputTokens: 1000,
        terminate: false,
      ),
      context: _context(_Invoker()),
    );
    await pumpEventQueue();
    expect(pipes.process.writtenFrame(1)['type'], 'continue');
    pipes.process
      ..emitFrame(cellId, 2, 'output', <String, dynamic>{
        'kind': 'text',
        'value': 'later',
      })
      ..emitFrame(cellId, 3, 'completed', const <String, dynamic>{
        'store': <String, dynamic>{},
      });
    final resumedChunk = await resumed;
    expect(resumedChunk.output, 'later');

    final missing = await service.wait(
      owner: 'session-1',
      request: LuaWaitRequest(
        cellId: cellId,
        yieldTime: const Duration(milliseconds: 10),
        maxOutputTokens: 1000,
        terminate: true,
      ),
      context: _context(_Invoker()),
    );
    if (resumedChunk.running) {
      expect(missing.terminated, isTrue);
    } else {
      expect(missing.error, 'Lua cell not found.');
    }
  });

  test('forwards Coder cancellation to the shared runtime process', () async {
    final cancellation = CancellationToken();
    final execute = service.execute(
      owner: 'session-1',
      workingDirectory: '/workspace',
      request: const LuaExecuteRequest(
        source: 'yield_control()',
        yieldTime: Duration(seconds: 1),
        maxOutputTokens: 1000,
        tools: <LuaNestedToolDefinition>[],
      ),
      context: ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: cancellation,
        callId: 'exec-parent',
        nestedTools: _Invoker(),
      ),
    );
    await pumpEventQueue();
    final cellId = pipes.process.writtenFrame(0)['cell_id']! as String;
    pipes.process.emitFrame(cellId, 1, 'yielded', const <String, dynamic>{
      'store': <String, dynamic>{},
    });
    expect((await execute).running, isTrue);

    cancellation.cancel();
    await pumpEventQueue();

    expect(pipes.process.terminated, isTrue);
  });

  test(
    'maps opaque tool resources into attachments and image context',
    () async {
      const attachment = ConversationAttachment(
        id: 'image-1',
        fileName: 'preview.png',
        mimeType: 'image/png',
        byteSize: 42,
        path: '/attachments/preview.png',
      );
      final execute = service.execute(
        owner: 'session-1',
        workingDirectory: '/workspace',
        request: const LuaExecuteRequest(
          source: 'image(tools.picture({}).attachments[1].handle)',
          yieldTime: Duration(seconds: 1),
          maxOutputTokens: 1000,
          tools: <LuaNestedToolDefinition>[],
        ),
        context: _context(const _AttachmentInvoker(attachment)),
      );
      await pumpEventQueue();
      final cellId = pipes.process.writtenFrame(0)['cell_id']! as String;
      pipes.process.emitFrame(cellId, 1, 'tool_batch', <String, dynamic>{
        'calls': <Map<String, dynamic>>[
          <String, dynamic>{
            'request_id': '1:1',
            'name': 'picture',
            'arguments': <String, dynamic>{},
          },
        ],
      });
      await pumpEventQueue();
      pipes.process
        ..emitFrame(cellId, 2, 'output', <String, dynamic>{
          'kind': 'image',
          'value': 'resource-1',
        })
        ..emitFrame(cellId, 3, 'completed', const <String, dynamic>{
          'store': <String, dynamic>{},
        });

      final chunk = await execute;
      expect(chunk.attachments, <ConversationAttachment>[attachment]);
      expect(chunk.contextImages, <ConversationAttachment>[attachment]);
    },
  );
}

ToolExecutionContext _context(NestedToolInvoker invoker) =>
    ToolExecutionContext(
      workspaceRoot: '/workspace',
      cancellation: CancellationToken(),
      callId: 'exec-parent',
      nestedTools: invoker,
    );

final class _Invoker implements NestedToolInvoker {
  final List<String> calls = <String>[];

  @override
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    calls.add('$name:${arguments['value']}');
    return ToolResult(value: 'echoed ${arguments['value']}');
  }
}

final class _AttachmentInvoker implements NestedToolInvoker {
  const _AttachmentInvoker(this.attachment);

  final ConversationAttachment attachment;

  @override
  Future<ToolResult> invoke(
    String name,
    Map<String, dynamic> arguments,
  ) async => ToolResult(
    value: 'image',
    attachments: <ConversationAttachment>[attachment],
  );
}

final class _Ids implements lua.LuaIdGenerator {
  int value = 0;

  @override
  String generate() => '${++value}';
}

final class _PipeGateway implements lua.LuaHostProcessLauncher {
  final _Process process = _Process();

  @override
  Future<lua.LuaHostProcess> start(
    lua.LuaHostCommand command, {
    required String workingDirectory,
  }) async {
    expect(command.executable, 'lua-tool-runtime-host');
    expect(workingDirectory, '/workspace');
    return process;
  }
}

final class _Process implements lua.LuaHostProcess {
  final StreamController<String> _outputs = StreamController<String>();
  final Completer<int> _exit = Completer<int>();
  final List<String> input = <String>[];
  bool terminated = false;

  Map<String, dynamic> writtenFrame(int index) =>
      Map<String, dynamic>.from(jsonDecode(input[index].trim()) as Map);

  void emit(String value) => _outputs.add(value);

  void emitFrame(
    String cellId,
    int sequence,
    String type,
    Map<String, dynamic> payload,
  ) => emit(
    '${jsonEncode(<String, dynamic>{
      'version': lua.luaHostProtocolVersion,
      'cell_id': cellId,
      'sequence_id': sequence,
      'type': type,
      'payload': payload,
    })}\n',
  );

  @override
  Future<int> get exitCode => _exit.future;

  @override
  Stream<String> get outputs => _outputs.stream;

  @override
  Future<void> terminate() async {
    terminated = true;
    if (!_exit.isCompleted) _exit.complete(0);
  }

  @override
  Future<void> write(String data) async => input.add(data);
}
