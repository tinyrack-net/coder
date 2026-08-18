@Tags(<String>[
  'feature_test__plugin_runtime__unit',
  'feature_test__lua_tool_orchestration__unit',
])
library;

import 'dart:async';

import 'package:daemon/src/shared/infrastructure/serialized_lua_host_process.dart';
import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;
import 'package:test/test.dart';

void main() {
  test('host resolution is deferred and shared by concurrent starts', () async {
    final delegate = _RecordingLauncher();
    final resolution = Completer<lua.LuaHostCommand>();
    var resolverCalls = 0;
    final launcher = DeferredLuaHostProcessLauncher(
      () {
        resolverCalls += 1;
        return resolution.future;
      },
      delegate,
    );

    expect(resolverCalls, 0);
    expect(delegate.commands, isEmpty);

    final first = launcher.start(
      const lua.LuaHostCommand(
        executable: 'unresolved-host-must-not-run',
        environment: <String, String>{'first-limit': '1'},
      ),
      workingDirectory: 'first-workspace',
    );
    final second = launcher.start(
      const lua.LuaHostCommand(
        executable: 'unresolved-host-must-not-run',
        environment: <String, String>{'second-limit': '2'},
      ),
      workingDirectory: 'second-workspace',
    );
    await pumpEventQueue();

    expect(resolverCalls, 1);
    expect(delegate.commands, isEmpty);

    resolution.complete(
      const lua.LuaHostCommand(
        executable: 'resolved-host',
        arguments: <String>['bootstrap.lua'],
        environment: <String, String>{'base': 'true'},
      ),
    );
    await Future.wait(<Future<lua.LuaHostProcess>>[first, second]);

    expect(
      delegate.commands.map((command) => command.executable),
      everyElement('resolved-host'),
    );
    expect(
      delegate.commands.map((command) => command.arguments),
      everyElement(<String>['bootstrap.lua']),
    );
    expect(delegate.commands[0].environment, <String, String>{
      'base': 'true',
      'first-limit': '1',
    });
    expect(delegate.commands[1].environment, <String, String>{
      'base': 'true',
      'second-limit': '2',
    });
    expect(delegate.workingDirectories, <String>[
      'first-workspace',
      'second-workspace',
    ]);
  });

  test('a failed deferred resolution is retried by the next start', () async {
    final delegate = _RecordingLauncher();
    var resolverCalls = 0;
    final launcher = DeferredLuaHostProcessLauncher(
      () async {
        resolverCalls += 1;
        if (resolverCalls == 1) throw StateError('staging failed');
        return const lua.LuaHostCommand(executable: 'resolved-host');
      },
      delegate,
    );

    await expectLater(
      launcher.start(
        const lua.LuaHostCommand(executable: 'unresolved-host-must-not-run'),
        workingDirectory: 'workspace',
      ),
      throwsStateError,
    );
    expect(delegate.commands, isEmpty);

    await launcher.start(
      const lua.LuaHostCommand(executable: 'unresolved-host-must-not-run'),
      workingDirectory: 'workspace',
    );

    expect(resolverCalls, 2);
    expect(delegate.commands.single.executable, 'resolved-host');
  });

  test('termination waits for an accepted protocol write to finish', () async {
    final delegate = _RecordingLauncher();
    final launcher = SerializedLuaHostProcessLauncher(delegate);
    final process = await launcher.start(
      const lua.LuaHostCommand(executable: 'lua-host'),
      workingDirectory: 'workspace',
    );

    final write = process.write('invoke\n');
    await delegate.process.writeStarted.future;
    final termination = process.terminate();
    await pumpEventQueue();

    expect(delegate.commands.single.executable, 'lua-host');
    expect(delegate.workingDirectories, <String>['workspace']);
    expect(delegate.process.terminateCalls, 0);

    delegate.process.releaseWrite.complete();
    await write;
    await termination;
    expect(delegate.process.terminateCalls, 1);

    await process.terminate();
    expect(delegate.process.terminateCalls, 1);
    await expectLater(process.write('late\n'), throwsStateError);
  });

  test('a failed write does not strand queued termination', () async {
    final delegate = _RecordingLauncher(failWrite: true);
    final process = await SerializedLuaHostProcessLauncher(delegate).start(
      const lua.LuaHostCommand(executable: 'lua-host'),
      workingDirectory: 'workspace',
    );

    await expectLater(process.write('invoke\n'), throwsStateError);
    await process.terminate();

    expect(delegate.process.terminateCalls, 1);
    expect(await process.exitCode, 0);
    expect(await process.outputs.toList(), isEmpty);
  });
}

final class _RecordingLauncher implements lua.LuaHostProcessLauncher {
  _RecordingLauncher({bool failWrite = false})
    : process = _RecordingProcess(failWrite: failWrite);

  final _RecordingProcess process;
  final List<lua.LuaHostCommand> commands = <lua.LuaHostCommand>[];
  final List<String> workingDirectories = <String>[];

  @override
  Future<lua.LuaHostProcess> start(
    lua.LuaHostCommand command, {
    required String workingDirectory,
  }) async {
    commands.add(command);
    workingDirectories.add(workingDirectory);
    return process;
  }
}

final class _RecordingProcess implements lua.LuaHostProcess {
  _RecordingProcess({required this.failWrite});

  final bool failWrite;
  final Completer<void> writeStarted = Completer<void>();
  final Completer<void> releaseWrite = Completer<void>();
  int terminateCalls = 0;

  @override
  Future<int> get exitCode => Future<int>.value(0);

  @override
  Stream<String> get outputs => const Stream<String>.empty();

  @override
  Future<void> terminate() async {
    terminateCalls += 1;
    if (writeStarted.isCompleted && !releaseWrite.isCompleted) {
      throw StateError('StreamSink is bound to a stream');
    }
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('write failed');
    writeStarted.complete();
    await releaseWrite.future;
  }
}
