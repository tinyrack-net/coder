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
