import 'dart:async';

import 'package:coder_daemon/src/terminal_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'terminal keeps bounded ordered output and survives client detach',
    () async {
      final process = _FakeTerminalProcess();
      final service = TerminalService(
        gateway: _FakeTerminalGateway(process),
        worktreePath: (id) async => '/worktrees/$id',
        shellFor: (id) async => const ShellSpecDto(executable: '/bin/zsh'),
        maxReplayBytes: 8,
      );

      final created = await service.create(
        id: 'terminal-1',
        worktreeId: 'worktree-1',
        title: 'Terminal 1',
        columns: 80,
        rows: 24,
      );
      expect(created.status, TerminalStatus.running);
      expect(process.workingDirectory, '/worktrees/worktree-1');

      process.output.add('12345');
      process.output.add('67890');
      await pumpEventQueue();
      final attached = service.attach('terminal-1', afterSequence: 0);
      expect(attached.replay.map((item) => item.data).join(), '34567890');
      expect(attached.terminal.lastSequence, 2);

      process.output.add('가나다');
      await pumpEventQueue();
      final unicodeReplay = service.attach(
        'terminal-1',
        afterSequence: 2,
      );
      expect(unicodeReplay.replay.single.data, '나다');

      await service.write('terminal-1', 'echo hi\r');
      await service.resize('terminal-1', columns: 120, rows: 40);
      expect(process.input, <String>['echo hi\r']);
      expect(process.sizes, <(int, int)>[(120, 40)]);

      await service.terminate('terminal-1');
      expect(process.terminated, isTrue);
    },
    tags: const <String>['feature_test__terminal_lifecycle__unit'],
  );
}

final class _FakeTerminalGateway implements TerminalGateway {
  _FakeTerminalGateway(this.process);
  final _FakeTerminalProcess process;

  @override
  Future<TerminalProcess> start({
    required ShellSpecDto shell,
    required String workingDirectory,
    required int columns,
    required int rows,
  }) async {
    process.workingDirectory = workingDirectory;
    return process;
  }
}

final class _FakeTerminalProcess implements TerminalProcess {
  final output = StreamController<String>();
  final input = <String>[];
  final sizes = <(int, int)>[];
  final exit = Completer<int>();
  String? workingDirectory;
  bool terminated = false;

  @override
  Stream<String> get outputs => output.stream;
  @override
  Future<int> get exitCode => exit.future;
  @override
  Future<void> write(String data) async => input.add(data);
  @override
  Future<void> interrupt() async => input.add(String.fromCharCode(0x03));
  @override
  Future<void> resize(int columns, int rows) async =>
      sizes.add((columns, rows));
  @override
  Future<void> terminate() async {
    if (terminated) return;
    terminated = true;
    if (!exit.isCompleted) exit.complete(0);
    await output.close();
  }
}
