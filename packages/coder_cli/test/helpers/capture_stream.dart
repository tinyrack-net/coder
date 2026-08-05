import 'package:cliweave/cliweave.dart';

/// A [WriteStream] that records everything written to it.
///
/// cliweave ships no test package; this is the idiom its own suite uses, and
/// it is the seam that lets a test drive the real router without a terminal.
/// [isTTY] is false so the logger and spinner degrade to plain lines.
final class CaptureStream implements WriteStream {
  final StringBuffer _buffer = StringBuffer();

  /// Everything written so far.
  String get text => _buffer.toString();

  @override
  bool get isTTY => false;

  @override
  void write(String chunk) => _buffer.write(chunk);

  @override
  void clearLine(int dir) {}

  @override
  void cursorTo(int column) {}
}
