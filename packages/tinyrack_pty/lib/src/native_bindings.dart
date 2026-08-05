import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Returns the Dart/native ABI version.
String nativePtyBindingsVersion() => '0.1.0';

@Native<
  Pointer<Void> Function(
    Pointer<Utf8>,
    Pointer<Pointer<Utf8>>,
    Pointer<Utf8>,
    Pointer<Pointer<Utf8>>,
    Int32,
    Int32,
    Pointer<Int32>,
  )
>(symbol: 'tr_pty_spawn')
/// Creates a native PTY handle.
external Pointer<Void> trPtySpawn(
  Pointer<Utf8> executable,
  Pointer<Pointer<Utf8>> arguments,
  Pointer<Utf8> workingDirectory,
  Pointer<Pointer<Utf8>> environment,
  int columns,
  int rows,
  Pointer<Int32> errorCode,
);

@Native<Int32 Function(Pointer<Void>)>(symbol: 'tr_pty_pid')
/// Returns the child process identifier.
external int trPtyPid(Pointer<Void> pty);

@Native<Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32)>(
  symbol: 'tr_pty_read',
)
/// Reads a currently available output chunk.
external int trPtyRead(Pointer<Void> pty, Pointer<Uint8> buffer, int capacity);

@Native<Int32 Function(Pointer<Void>, Pointer<Uint8>, Int32)>(
  symbol: 'tr_pty_write',
)
/// Writes a terminal input chunk.
external int trPtyWrite(Pointer<Void> pty, Pointer<Uint8> buffer, int length);

@Native<Int32 Function(Pointer<Void>, Int32, Int32)>(
  symbol: 'tr_pty_resize',
)
/// Updates terminal dimensions.
external int trPtyResize(Pointer<Void> pty, int columns, int rows);

@Native<Int32 Function(Pointer<Void>, Pointer<Int32>)>(
  symbol: 'tr_pty_try_wait',
)
/// Polls for process exit.
external int trPtyTryWait(Pointer<Void> pty, Pointer<Int32> exitCode);

@Native<Int32 Function(Pointer<Void>, Int32)>(symbol: 'tr_pty_signal')
/// Sends a graceful or forced termination signal.
external int trPtySignal(Pointer<Void> pty, int force);

@Native<Int32 Function(Pointer<Void>)>(symbol: 'tr_pty_last_error')
/// Returns the most recent operating-system error for this handle.
external int trPtyLastError(Pointer<Void> pty);

@Native<Void Function(Int32, Pointer<Char>, Int32)>(
  symbol: 'tr_pty_error_message',
)
/// Formats an operating-system error.
external void trPtyErrorMessage(
  int errorCode,
  Pointer<Char> buffer,
  int capacity,
);

@Native<Void Function(Pointer<Void>)>(symbol: 'tr_pty_free')
/// Releases a native PTY handle.
external void trPtyFree(Pointer<Void> pty);
