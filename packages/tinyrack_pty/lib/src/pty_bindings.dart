import 'dart:ffi';

import 'package:tinyrack_pty/src/native_bindings.dart';

/// Indirection over the native entry points that take a live PTY handle.
///
/// A healthy pseudo-terminal never fails these calls, so the error branches
/// they guard are unreachable from a real child process. Tests substitute an
/// implementation that reports failures instead.
///
/// `tr_pty_spawn`, `tr_pty_pid`, and `tr_pty_error_message` are deliberately
/// absent: the first two run only while constructing a real process, and the
/// third formats a plain error code without touching a handle.
class PtyBindings {
  /// Creates bindings that forward to the linked native library.
  const PtyBindings();

  /// Reads a currently available output chunk into [buffer].
  int read(Pointer<Void> pty, Pointer<Uint8> buffer, int capacity) =>
      trPtyRead(pty, buffer, capacity);

  /// Writes at most [length] bytes of terminal input from [buffer].
  int write(Pointer<Void> pty, Pointer<Uint8> buffer, int length) =>
      trPtyWrite(pty, buffer, length);

  /// Updates the terminal window dimensions.
  int resize(Pointer<Void> pty, int columns, int rows) =>
      trPtyResize(pty, columns, rows);

  /// Polls for process exit, storing the code in [exitCode] when it returns 1.
  int tryWait(Pointer<Void> pty, Pointer<Int32> exitCode) =>
      trPtyTryWait(pty, exitCode);

  /// Sends a graceful ([force] 0) or forced ([force] 1) termination signal.
  int signal(Pointer<Void> pty, int force) => trPtySignal(pty, force);

  /// Returns the most recent operating-system error for this handle.
  int lastError(Pointer<Void> pty) => trPtyLastError(pty);

  /// Releases the native handle.
  void free(Pointer<Void> pty) => trPtyFree(pty);

  /// Registers [pty] for release if [owner] is collected without finishing.
  ///
  /// Overridden alongside [detachFinalizer] so a fake handle is never handed
  /// to the real finalizer, which would free a fabricated pointer during a
  /// later garbage collection and crash the isolate.
  void attachFinalizer(Finalizable owner, Pointer<Void> pty) =>
      _finalizer.attach(owner, pty, detach: owner);

  /// Cancels the registration made by [attachFinalizer].
  void detachFinalizer(Finalizable owner) => _finalizer.detach(owner);

  static final NativeFinalizer _finalizer = NativeFinalizer(
    Native.addressOf<NativeFunction<Void Function(Pointer<Void>)>>(trPtyFree),
  );
}
