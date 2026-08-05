import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:coder_daemon/src/terminal_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:portable_pty/portable_pty.dart';

/// Production cross-platform PTY adapter.
final class PortableTerminalGateway implements TerminalGateway {
  /// Creates the production PTY adapter.
  const PortableTerminalGateway();

  @override
  Future<TerminalProcess> start({
    required ShellSpecDto shell,
    required String workingDirectory,
    required int columns,
    required int rows,
  }) async {
    final pty = PortablePty.open(rows: rows, cols: columns);
    if (Platform.isWindows) {
      pty.spawn(
        'powershell.exe',
        args: <String>[
          '-NoLogo',
          '-NoExit',
          '-Command',
          <String>[
            r'Set-Location -LiteralPath $args[0];',
            r'if ($args.Count -gt 2) {',
            r'& $args[1] @($args[2..($args.Count-1)])',
            r'} else { & $args[1] }',
          ].join(' '),
          workingDirectory,
          shell.executable,
          ...shell.arguments,
        ],
      );
    } else {
      pty.spawn(
        '/bin/sh',
        args: <String>[
          '-c',
          r'cd -- "$1" && shift && exec "$@"',
          'coder-terminal',
          workingDirectory,
          shell.executable,
          ...shell.arguments,
        ],
      );
      _setNonBlocking(pty.masterFd);
    }
    return _PortableTerminalProcess(pty);
  }
}

final class _PortableTerminalProcess implements TerminalProcess {
  _PortableTerminalProcess(this._pty) {
    _decodedOutput = _encodedOutput.stream
        .transform(utf8.decoder)
        .listen(
          _outputs.add,
          onError: _outputs.addError,
        );
    _poller = Timer.periodic(const Duration(milliseconds: 10), (_) => _poll());
  }

  final PortablePty _pty;
  final StreamController<String> _outputs =
      StreamController<String>.broadcast();
  final StreamController<List<int>> _encodedOutput =
      StreamController<List<int>>();
  final Completer<int> _exitCode = Completer<int>();
  late final StreamSubscription<String> _decodedOutput;
  late final Timer _poller;
  bool _closed = false;
  bool _terminating = false;

  @override
  Stream<String> get outputs => _outputs.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  void _poll() {
    if (_closed || _terminating) return;
    try {
      final bytes = _readAvailable();
      if (bytes.isNotEmpty) {
        _encodedOutput.add(bytes);
      }
      final code = _pty.tryWait();
      if (code != null) _finish(code);
    } on Object catch (error, stackTrace) {
      _outputs.addError(error, stackTrace);
      _finish(-1);
    }
  }

  List<int> _readAvailable() {
    try {
      return _pty.readSync(64 * 1024);
    } on Object catch (error, stackTrace) {
      if (!Platform.isWindows && error is StateError) return const <int>[];
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> write(String data) async {
    if (_closed) return;
    _pty.writeString(data);
  }

  @override
  Future<void> resize(int columns, int rows) async {
    if (_closed) return;
    _pty.resize(rows: rows, cols: columns);
  }

  @override
  Future<void> terminate() async {
    if (_closed) return;
    _terminating = true;
    _poller.cancel();
    try {
      _signalProcessTree(ProcessSignal.sigterm);
      for (var attempt = 0; attempt < 10; attempt += 1) {
        final code = _pty.tryWait();
        if (code != null) {
          _finish(code);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      _signalProcessTree(ProcessSignal.sigkill);
      _finish(_pty.wait());
    } finally {
      if (!_closed) _finish(_pty.tryWait() ?? -1);
    }
  }

  void _signalProcessTree(ProcessSignal signal) {
    final processGroup = _pty.processGroup;
    final childPid = _pty.childPid;
    if (!Platform.isWindows && processGroup > 0 && processGroup == childPid) {
      Process.killPid(-processGroup, signal);
      return;
    }
    _pty.kill(signal.signalNumber);
  }

  void _finish(int code) {
    if (_closed) return;
    _closed = true;
    _poller.cancel();
    _pty.close();
    if (!_exitCode.isCompleted) _exitCode.complete(code);
    unawaited(_closeOutputs());
  }

  Future<void> _closeOutputs() async {
    await _encodedOutput.close();
    await _decodedOutput.cancel();
    await _outputs.close();
  }
}

void _setNonBlocking(int fileDescriptor) {
  final fcntl = DynamicLibrary.process()
      .lookupFunction<
        Int32 Function(Int32, Int32, Int32),
        int Function(int, int, int)
      >('fcntl');
  const getFlags = 3;
  const setFlags = 4;
  final nonBlocking = Platform.isMacOS ? 0x4 : 0x800;
  final flags = fcntl(fileDescriptor, getFlags, 0);
  if (flags < 0 || fcntl(fileDescriptor, setFlags, flags | nonBlocking) < 0) {
    throw StateError('Unable to configure non-blocking PTY output.');
  }
}
