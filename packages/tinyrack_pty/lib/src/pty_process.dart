import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:tinyrack_pty/src/native_bindings.dart';
import 'package:tinyrack_pty/src/pty_exception.dart';

/// Lifecycle state of a pseudo-terminal process.
enum PtyStatus {
  /// The child process is running.
  running,

  /// Graceful or forced termination is in progress.
  terminating,

  /// The child process has exited and resources were released.
  exited,
}

/// A child process connected to a platform pseudo-terminal.
final class PtyProcess implements Finalizable {
  PtyProcess._(this._handle, this.pid) {
    _finalizer.attach(this, _handle, detach: this);
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) => _poll());
  }

  /// Starts [executable] inside a new pseudo-terminal.
  static Future<PtyProcess> start(
    String executable, {
    List<String> arguments = const <String>[],
    String? workingDirectory,
    Map<String, String> environment = const <String, String>{},
    int columns = 80,
    int rows = 24,
  }) async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      throw UnsupportedError('Local PTYs require Linux, macOS, or Windows.');
    }
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('Terminal columns and rows must be positive.');
    }
    final cwd = workingDirectory ?? Directory.current.path;
    if (!Directory(cwd).existsSync()) {
      throw const PtyException(
        operation: 'start',
        errorCode: 2,
        message: 'Working directory does not exist.',
      );
    }
    final resolvedExecutable = _resolveExecutable(executable);
    if (!Platform.isWindows && !File(resolvedExecutable).existsSync()) {
      throw const PtyException(
        operation: 'start',
        errorCode: 2,
        message: 'Executable does not exist.',
      );
    }

    return using((arena) {
      final nativeExecutable = resolvedExecutable.toNativeUtf8(
        allocator: arena,
      );
      final nativeCwd = cwd.toNativeUtf8(allocator: arena);
      final nativeArguments = _nativeStrings(
        <String>[resolvedExecutable, ...arguments],
        arena,
      );
      final effectiveEnvironment = <String, String>{
        ...Platform.environment,
        'TERM': Platform.environment['TERM'] ?? 'xterm-256color',
        ...environment,
      };
      final nativeEnvironment = _nativeStrings(
        effectiveEnvironment.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .toList(),
        arena,
      );
      final errorCode = arena<Int32>();
      final handle = trPtySpawn(
        nativeExecutable,
        nativeArguments,
        nativeCwd,
        nativeEnvironment,
        columns,
        rows,
        errorCode,
      );
      if (handle == nullptr) {
        throw _nativeException('start', errorCode.value);
      }
      return PtyProcess._(handle, trPtyPid(handle));
    });
  }

  static final NativeFinalizer _finalizer = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(trPtyFree),
  );

  final Pointer<Void> _handle;
  final StreamController<List<int>> _output = StreamController<List<int>>();
  final Completer<int> _exitCode = Completer<int>();
  final ListQueue<_PendingWrite> _writes = ListQueue<_PendingWrite>();
  late final Timer _timer;
  int? _observedExitCode;
  bool _outputEnded = false;

  /// Operating-system process identifier of the terminal child.
  final int pid;

  PtyStatus _status = PtyStatus.running;

  /// Current process state.
  PtyStatus get status => _status;

  /// Raw bytes read from the terminal output.
  Stream<List<int>> get output => _output.stream;

  /// Completes with the exact child exit code.
  Future<int> get exitCode => _exitCode.future;

  void _poll() {
    if (_status == PtyStatus.exited) return;
    try {
      _flushWrites();
      _readAvailable();
      _checkExit();
      if (_observedExitCode != null && _outputEnded) {
        _finish(_observedExitCode!);
      }
    } on PtyException catch (error, stackTrace) {
      _output.addError(error, stackTrace);
      _finish(-1, error: error, stackTrace: stackTrace);
    }
  }

  void _readAvailable() {
    if (_outputEnded) return;
    const capacity = 64 * 1024;
    final buffer = calloc<Uint8>(capacity);
    try {
      while (true) {
        final length = trPtyRead(_handle, buffer, capacity);
        if (length > 0) {
          _output.add(Uint8List.fromList(buffer.asTypedList(length)));
        } else if (length == 0) {
          return;
        } else if (length == -2) {
          _outputEnded = true;
          return;
        } else {
          throw _nativeException('read', trPtyLastError(_handle));
        }
      }
    } finally {
      calloc.free(buffer);
    }
  }

  void _checkExit() {
    if (_observedExitCode != null) return;
    final result = calloc<Int32>();
    try {
      final state = trPtyTryWait(_handle, result);
      if (state < 0) {
        throw _nativeException('wait', trPtyLastError(_handle));
      }
      if (state == 1) _observedExitCode = result.value;
    } finally {
      calloc.free(result);
    }
  }

  /// Queues [data] for an ordered, non-blocking write.
  Future<void> write(List<int> data) {
    if (_status != PtyStatus.running) {
      return Future<void>.error(StateError('The PTY is not running.'));
    }
    if (data.isEmpty) return Future<void>.value();
    final pending = _PendingWrite(Uint8List.fromList(data));
    _writes.add(pending);
    _flushWrites();
    return pending.done.future;
  }

  void _flushWrites() {
    while (_writes.isNotEmpty) {
      final pending = _writes.first;
      final remaining = pending.data.length - pending.offset;
      final buffer = calloc<Uint8>(remaining);
      try {
        buffer
            .asTypedList(remaining)
            .setRange(
              0,
              remaining,
              pending.data,
              pending.offset,
            );
        final written = trPtyWrite(_handle, buffer, remaining);
        if (written < 0) {
          throw _nativeException('write', trPtyLastError(_handle));
        }
        if (written == 0) return;
        pending.offset += written;
        if (pending.offset == pending.data.length) {
          _writes.removeFirst();
          pending.done.complete();
        }
      } finally {
        calloc.free(buffer);
      }
    }
  }

  /// Changes the terminal window dimensions.
  void resize({required int columns, required int rows}) {
    if (_status != PtyStatus.running) {
      throw StateError('The PTY is not running.');
    }
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('Terminal columns and rows must be positive.');
    }
    if (trPtyResize(_handle, columns, rows) != 0) {
      throw _nativeException('resize', trPtyLastError(_handle));
    }
  }

  /// Requests graceful process-tree termination, then forces it after timeout.
  Future<void> terminate({
    Duration gracePeriod = const Duration(seconds: 1),
  }) async {
    if (_status == PtyStatus.exited) return;
    if (_status == PtyStatus.running) {
      _status = PtyStatus.terminating;
      final result = trPtySignal(_handle, 0);
      if (result != 0 && _observedExitCode == null) {
        _checkExit();
      }
    }
    try {
      await exitCode.timeout(gracePeriod);
    } on TimeoutException {
      if (trPtySignal(_handle, 1) != 0) {
        _checkExit();
        if (_observedExitCode == null) {
          throw _nativeException('terminate', trPtyLastError(_handle));
        }
      }
      await exitCode;
    }
  }

  void _finish(
    int code, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_status == PtyStatus.exited) return;
    _status = PtyStatus.exited;
    _timer.cancel();
    while (_writes.isNotEmpty) {
      final pending = _writes.removeFirst();
      pending.done.completeError(
        error ?? StateError('The PTY exited before the write completed.'),
        stackTrace,
      );
    }
    if (!_exitCode.isCompleted) _exitCode.complete(code);
    unawaited(_output.close());
    _finalizer.detach(this);
    trPtyFree(_handle);
  }
}

final class _PendingWrite {
  _PendingWrite(this.data);

  final Uint8List data;
  final Completer<void> done = Completer<void>();
  int offset = 0;
}

Pointer<Pointer<Utf8>> _nativeStrings(List<String> values, Arena arena) {
  final result = arena<Pointer<Utf8>>(values.length + 1);
  for (var index = 0; index < values.length; index += 1) {
    result[index] = values[index].toNativeUtf8(allocator: arena);
  }
  result[values.length] = nullptr;
  return result;
}

String _resolveExecutable(String executable) {
  if (Platform.isWindows || executable.contains('/')) return executable;
  for (final directory in (Platform.environment['PATH'] ?? '').split(':')) {
    if (directory.isEmpty) continue;
    final candidate = '$directory/$executable';
    if (File(candidate).existsSync()) return candidate;
  }
  return executable;
}

PtyException _nativeException(String operation, int errorCode) {
  const capacity = 512;
  final buffer = calloc<Char>(capacity);
  try {
    trPtyErrorMessage(errorCode, buffer, capacity);
    final message = buffer.cast<Utf8>().toDartString();
    return PtyException(
      operation: operation,
      errorCode: errorCode,
      message: message.isEmpty ? 'Unknown operating-system error.' : message,
    );
  } finally {
    calloc.free(buffer);
  }
}
