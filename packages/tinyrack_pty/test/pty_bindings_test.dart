import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tinyrack_pty/src/pty_bindings.dart';
import 'package:tinyrack_pty/tinyrack_pty.dart';

/// Drives [PtyProcess] through operating-system failures that a healthy
/// pseudo-terminal never produces.
///
/// The handle is a placeholder address that is never dereferenced, so this
/// class must also stub the finalizer: attaching the real one would free a
/// fabricated pointer during a later collection and crash the isolate.
final class _FakeBindings extends PtyBindings {
  _FakeBindings();

  int Function(Pointer<Uint8> buffer, int capacity) onRead = (_, _) => 0;
  int Function(Pointer<Uint8> buffer, int length) onWrite = (_, length) =>
      length;
  int Function(Pointer<Int32> exitCode) onTryWait = (_) => 0;
  int Function(int force) onSignal = (_) => 0;
  int onResize = 0;
  int onLastError = 5;

  final List<Uint8List> writes = <Uint8List>[];
  final List<int> signals = <int>[];
  bool finalizerAttached = false;
  bool freed = false;

  /// Makes the next poll observe a clean exit with [code].
  void reportExit(int code) => onTryWait = (exitCode) {
    exitCode.value = code;
    return 1;
  };

  @override
  int read(Pointer<Void> pty, Pointer<Uint8> buffer, int capacity) =>
      onRead(buffer, capacity);

  @override
  int write(Pointer<Void> pty, Pointer<Uint8> buffer, int length) {
    writes.add(Uint8List.fromList(buffer.asTypedList(length)));
    return onWrite(buffer, length);
  }

  @override
  int resize(Pointer<Void> pty, int columns, int rows) => onResize;

  @override
  int tryWait(Pointer<Void> pty, Pointer<Int32> exitCode) =>
      onTryWait(exitCode);

  @override
  int signal(Pointer<Void> pty, int force) {
    signals.add(force);
    return onSignal(force);
  }

  @override
  int lastError(Pointer<Void> pty) => onLastError;

  @override
  void free(Pointer<Void> pty) => freed = true;

  @override
  void attachFinalizer(Finalizable owner, Pointer<Void> pty) =>
      finalizerAttached = true;

  @override
  void detachFinalizer(Finalizable owner) => finalizerAttached = false;
}

Matcher _ptyFailure(String operation) => isA<PtyException>().having(
  (exception) => exception.operation,
  'operation',
  operation,
);

void main() {
  late _FakeBindings bindings;

  setUp(() => bindings = _FakeBindings());

  test('surfaces a failed read on the output stream and exits', () async {
    bindings.onRead = (_, _) => -1;
    final process = PtyProcess.withBindings(bindings);

    await expectLater(process.output, emitsError(_ptyFailure('read')));

    expect(await process.exitCode, -1);
    expect(process.status, PtyStatus.exited);
    expect(bindings.freed, isTrue);
    expect(bindings.finalizerAttached, isFalse);
  });

  test('surfaces a failed exit poll on the output stream', () async {
    bindings.onTryWait = (_) => -1;
    final process = PtyProcess.withBindings(bindings);

    await expectLater(process.output, emitsError(_ptyFailure('wait')));

    expect(await process.exitCode, -1);
    expect(process.status, PtyStatus.exited);
  });

  test('fails the queued write when the native write fails', () async {
    bindings.onWrite = (_, _) => -1;
    final process = PtyProcess.withBindings(bindings);

    await expectLater(
      process.write(<int>[1, 2, 3]),
      throwsA(_ptyFailure('write')),
    );

    expect(await process.exitCode, -1);
    expect(process.status, PtyStatus.exited);
    // The write failure is reported to its caller, not duplicated onto output.
    expect(await process.output.isEmpty, isTrue);
  });

  test('throws a typed error when the native resize fails', () async {
    bindings.onResize = -1;
    final process = PtyProcess.withBindings(bindings);

    expect(
      () => process.resize(columns: 100, rows: 40),
      throwsA(_ptyFailure('resize')),
    );

    bindings.reportExit(0);
    expect(await process.exitCode, 0);
  });

  test('polls for exit when the graceful signal fails', () async {
    bindings
      ..reportExit(7)
      ..onSignal = (_) => -1;
    final process = PtyProcess.withBindings(bindings);

    await process.terminate(gracePeriod: const Duration(seconds: 5));

    expect(await process.exitCode, 7);
    expect(bindings.signals, <int>[0]);
  });

  test('throws when the forced signal fails and no exit is observed', () async {
    bindings.onSignal = (force) => force == 0 ? 0 : -1;
    final process = PtyProcess.withBindings(bindings);

    await expectLater(
      process.terminate(gracePeriod: const Duration(milliseconds: 50)),
      throwsA(_ptyFailure('terminate')),
    );

    expect(bindings.signals, <int>[0, 1]);
    expect(process.status, PtyStatus.terminating);

    bindings.reportExit(0);
    expect(await process.exitCode, 0);
  });

  test(
    'completes when the forced signal fails but the child had exited',
    () async {
      bindings.onSignal = (force) {
        if (force == 1) bindings.reportExit(3);
        return force == 0 ? 0 : -1;
      };
      final process = PtyProcess.withBindings(bindings);

      await process.terminate(gracePeriod: const Duration(milliseconds: 50));

      expect(await process.exitCode, 3);
      expect(bindings.signals, <int>[0, 1]);
    },
  );

  test('resumes a partial write and preserves queue order', () async {
    var call = 0;
    bindings.onWrite = (_, length) => (call++ < 2) ? 0 : length;
    final process = PtyProcess.withBindings(bindings);

    final first = process.write(<int>[1, 2, 3, 4]);
    final second = process.write(<int>[5, 6]);
    await Future.wait<void>(<Future<void>>[first, second]);

    expect(
      bindings.writes.map<List<int>>((chunk) => chunk.toList()).toList(),
      <List<int>>[
        <int>[1, 2, 3, 4],
        <int>[1, 2, 3, 4],
        <int>[1, 2, 3, 4],
        <int>[5, 6],
      ],
    );

    bindings.reportExit(0);
    expect(await process.exitCode, 0);
  });
}
