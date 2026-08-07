import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:coder_daemon/src/features/terminals/application/terminal_service.dart';
import 'package:coder_daemon/src/features/terminals/domain/terminal.dart';
import 'package:test/test.dart';

void main() {
  test(
    'terminal keeps bounded ordered output and survives client detach',
    () async {
      final process = _FakeTerminalProcess();
      final service = TerminalService(
        gateway: _FakeTerminalGateway(process),
        worktreePath: (id) async => '/worktrees/$id',
        shellFor: (id) async => const TerminalShell(executable: '/bin/zsh'),
        maxReplayBytes: 8,
      );

      final created = await service.create(
        id: 'terminal-1',
        worktreeId: 'worktree-1',
        title: 'Terminal 1',
        columns: 80,
        rows: 24,
      );
      expect(created.status, TerminalLifecycle.running);
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

  test(
    'replay stays a codepoint-aligned suffix of the stream at every step',
    () async {
      const maxReplayBytes = 512;
      final process = _FakeTerminalProcess();
      final service = TerminalService(
        gateway: _FakeTerminalGateway(process),
        worktreePath: (id) async => '/worktrees/$id',
        shellFor: (id) async => const TerminalShell(executable: '/bin/zsh'),
        maxReplayBytes: maxReplayBytes,
      );
      await service.create(
        id: 'terminal-1',
        worktreeId: 'worktree-1',
        title: 'Terminal 1',
        columns: 80,
        rows: 24,
      );

      // A fixed seed keeps the mix of chunk lengths and of one- and
      // three-byte codepoints reproducible across runs.
      final random = Random(20260806);
      final written = StringBuffer();
      for (var i = 0; i < 400; i++) {
        final chunk = String.fromCharCodes(<int>[
          for (var j = 0; j < 1 + random.nextInt(40); j++)
            random.nextBool() ? 0x61 + random.nextInt(26) : 0xAC00 + j,
        ]);
        written.write(chunk);
        process.output.add(chunk);
        await pumpEventQueue(times: 1);

        final retained = service
            .attach('terminal-1', afterSequence: 0)
            .replay
            .map((item) => item.data)
            .join();
        final retainedBytes = utf8.encode(retained);
        final streamBytes = utf8.encode(written.toString());

        // Trimming only ever drops from the front, so what is kept is a byte
        // suffix of everything the program has written.
        expect(
          retainedBytes,
          streamBytes.sublist(streamBytes.length - retainedBytes.length),
          reason: 'replay drifted from the stream after chunk $i',
        );
        expect(retainedBytes.length, lessThanOrEqualTo(maxReplayBytes));
        if (streamBytes.length > maxReplayBytes) {
          // Trimming stops as soon as the budget fits, and only the aligning
          // walk past continuation bytes can overshoot, by at most three.
          expect(
            retainedBytes.length,
            greaterThanOrEqualTo(maxReplayBytes - 3),
            reason: 'byte accounting drifted after chunk $i',
          );
        }
      }

      await service.terminate('terminal-1');
    },
    tags: const <String>['feature_test__terminal_lifecycle__unit'],
  );

  test(
    'recording output costs the same once the replay budget is full',
    () async {
      final process = _FakeTerminalProcess();
      final service = TerminalService(
        gateway: _FakeTerminalGateway(process),
        worktreePath: (id) async => '/worktrees/$id',
        shellFor: (id) async => const TerminalShell(executable: '/bin/zsh'),
      );
      await service.create(
        id: 'terminal-1',
        worktreeId: 'worktree-1',
        title: 'Terminal 1',
        columns: 80,
        rows: 24,
      );

      // A terminal that has produced its megabyte of scrollback must not cost
      // more per chunk than a fresh one. Accounting that rescans the buffer
      // makes this quadratic: it blocks the daemon isolate for hundreds of
      // milliseconds per PTY read burst, which stalls every other request.
      // The bound is deliberately far above the constant-time cost so that a
      // slow machine cannot fail it; only a return to rescanning can.
      // Wide enough that the default megabyte budget fills within the first
      // few thousand chunks, so most of the run measures the steady state.
      final chunk = '${'terminal output line' * 12}\r\n';
      final watch = Stopwatch()..start();
      for (var i = 0; i < 20000; i++) {
        process.output.add(chunk);
        await pumpEventQueue(times: 1);
      }
      watch.stop();

      expect(watch.elapsed, lessThan(const Duration(seconds: 15)));

      await service.terminate('terminal-1');
    },
    timeout: const Timeout(Duration(minutes: 3)),
    tags: const <String>['feature_test__terminal_lifecycle__unit'],
  );
}

final class _FakeTerminalGateway implements TerminalGateway {
  _FakeTerminalGateway(this.process);
  final _FakeTerminalProcess process;

  @override
  Future<TerminalProcess> start({
    required TerminalShell shell,
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
