import 'dart:convert';

import 'package:coder_daemon/src/terminal_service.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:ptyworld/ptyworld.dart';

/// Production cross-platform PTY adapter.
final class PtyworldTerminalGateway implements TerminalGateway {
  /// Creates the production PTY adapter.
  const PtyworldTerminalGateway();

  @override
  Future<TerminalProcess> start({
    required ShellSpecDto shell,
    required String workingDirectory,
    required int columns,
    required int rows,
  }) async {
    final process = await PtyProcess.start(
      shell.executable,
      arguments: shell.arguments,
      workingDirectory: workingDirectory,
      columns: columns,
      rows: rows,
    );
    return _TinyrackTerminalProcess(process);
  }
}

final class _TinyrackTerminalProcess implements TerminalProcess {
  const _TinyrackTerminalProcess(this._process);

  final PtyProcess _process;

  @override
  Stream<String> get outputs => _process.output.transform(utf8.decoder);

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> write(String data) => _process.write(utf8.encode(data));

  @override
  Future<void> interrupt() =>
      // ETX is what Ctrl-C sends; the terminal's line discipline turns it into
      // SIGINT for the foreground command and leaves the shell running.
      _process.write(utf8.encode(String.fromCharCode(0x03)));

  @override
  Future<void> resize(int columns, int rows) async =>
      _process.resize(columns: columns, rows: rows);

  @override
  Future<void> terminate() => _process.terminate();
}
