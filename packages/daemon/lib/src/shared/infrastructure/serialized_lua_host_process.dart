import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;

/// Serializes protocol writes with process termination for one Lua host.
///
/// A turn cancellation may arrive while the runtime is flushing an invocation
/// frame. Dart IO does not allow `stdin.close()` while that flush owns the
/// sink, so the safety-kernel composition queues termination behind every
/// accepted write.
final class SerializedLuaHostProcessLauncher
    implements lua.LuaHostProcessLauncher {
  /// Creates a serialization decorator over the native process launcher.
  const SerializedLuaHostProcessLauncher(this._delegate);

  final lua.LuaHostProcessLauncher _delegate;

  @override
  Future<lua.LuaHostProcess> start(
    lua.LuaHostCommand command, {
    required String workingDirectory,
  }) async => _SerializedLuaHostProcess(
    await _delegate.start(command, workingDirectory: workingDirectory),
  );
}

final class _SerializedLuaHostProcess implements lua.LuaHostProcess {
  _SerializedLuaHostProcess(this._delegate);

  final lua.LuaHostProcess _delegate;
  Future<void> _tail = Future<void>.value();
  Future<void>? _termination;

  @override
  Stream<String> get outputs => _delegate.outputs;

  @override
  Future<int> get exitCode => _delegate.exitCode;

  @override
  Future<void> write(String value) {
    if (_termination != null) {
      return Future<void>.error(
        StateError('The Lua host process is terminating.'),
      );
    }
    return _enqueue(() => _delegate.write(value));
  }

  @override
  Future<void> terminate() {
    final existing = _termination;
    if (existing != null) return existing;
    final queued = _enqueue(_delegate.terminate);
    _termination = queued;
    return queued;
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
