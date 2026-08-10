// Throwaway IME probe: renders a bare termworld TerminalView and records
// every message crossing the `flutter/textinput` channel (both directions)
// plus every byte the terminal would send to the PTY, as timestamped JSONL.
//
// Outputs (in the working directory, or set IME_TRACE_DIR):
//   ime-trace.jsonl  — one JSON object per event:
//     {"t_us": <int>, "dir": "rx"|"tx"|"pty", "method": <string>, "args": ...}
//     rx  = platform -> framework (updateEditingStateWithDeltas, ...)
//     tx  = framework -> platform (TextInput.setEditingState, setClient, ...)
//     pty = string termworld emitted toward the PTY (terminal.onData)
//   pty-input.bin    — the raw PTY bytes, byte-exact (same shape as the
//                      repo E2E's capture file).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:termworld/termworld.dart';

final Stopwatch _clock = Stopwatch()..start();

final Directory _outDir = Directory(
  Platform.environment['IME_TRACE_DIR'] ?? Directory.current.path,
);
final File _traceFile = File('${_outDir.path}/ime-trace.jsonl');
final File _ptyFile = File('${_outDir.path}/pty-input.bin');

void _trace(String dir, String method, Object? args) {
  final line = jsonEncode(<String, Object?>{
    't_us': _clock.elapsedMicroseconds,
    'dir': dir,
    'method': method,
    'args': args,
  });
  // Synchronous append so a crash or SIGKILL never loses the tail.
  _traceFile.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
}

void _traceMessage(String dir, ByteData message) {
  try {
    final call = SystemChannels.textInput.codec.decodeMethodCall(message);
    _trace(dir, call.method, call.arguments);
  } on Object catch (error) {
    // The probe must record rather than crash on any undecodable message, so
    // it deliberately catches everything the codec can throw.
    _trace(dir, '<undecodable>', error.toString());
  }
}

/// Wraps the default messenger and taps `flutter/textinput` in both
/// directions, below termworld's interpretation of the deltas.
class _LoggingMessenger implements BinaryMessenger {
  _LoggingMessenger(this._inner);

  static const String _channel = 'flutter/textinput';
  final BinaryMessenger _inner;

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    if (channel == _channel && message != null) _traceMessage('tx', message);
    return _inner.send(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    if (channel == _channel && handler != null) {
      _inner.setMessageHandler(channel, (message) {
        if (message != null) _traceMessage('rx', message);
        return handler(message);
      });
      return;
    }
    _inner.setMessageHandler(channel, handler);
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) =>
      // Deprecated entry point; incoming traffic is logged by the wrapped
      // handler above, so only forward here to avoid double records.
      // ignore: deprecated_member_use
      _inner.handlePlatformMessage(channel, data, callback);
}

/// Binding whose messenger taps the text-input channel for the trace log.
class ProbeBinding extends WidgetsFlutterBinding {
  /// Initializes the binding with the logging messenger installed.
  static WidgetsBinding ensureInitialized() {
    ProbeBinding();
    return WidgetsBinding.instance;
  }

  @override
  BinaryMessenger createBinaryMessenger() =>
      _LoggingMessenger(super.createBinaryMessenger());
}

void main() {
  if (_traceFile.existsSync()) _traceFile.deleteSync();
  if (_ptyFile.existsSync()) _ptyFile.deleteSync();
  ProbeBinding.ensureInitialized();

  final terminal = Terminal();
  terminal.onData.listen((data) {
    _ptyFile.writeAsBytesSync(
      utf8.encode(data),
      mode: FileMode.append,
      flush: true,
    );
    _trace('pty', 'onData', data);
    // Local echo so typing is visible without a real shell. DEL (0x7f) is
    // what termworld emits when the IME retracts committed text; render it
    // as a destructive backspace, and CR as a new line.
    terminal.write(
      data.replaceAll('\u007f', '\b \b').replaceAll('\r', '\r\n'),
    );
  });
  terminal.write(
    'IME delta probe. Type: 안녕하세요. '
    'then Enter, then close the window.\r\n',
  );

  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: TerminalView(terminal: terminal, autofocus: true),
      ),
    ),
  );
}
