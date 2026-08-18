import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;

/// Resolves the immutable native Lua host distribution on first use.
typedef LuaHostCommandResolver = Future<lua.LuaHostCommand> Function();

/// Defers native Lua host staging until a runtime starts its first worker.
///
/// Daemon transports and non-Lua RPCs do not need the native helper. Keeping
/// resolution behind the process-launch boundary prevents an unused helper
/// build from delaying daemon readiness. Concurrent first workers share one
/// resolution, while a failed resolution remains retryable.
final class DeferredLuaHostProcessLauncher
    implements lua.LuaHostProcessLauncher {
  /// Creates a launcher over a lazily resolved host and concrete process port.
  DeferredLuaHostProcessLauncher(this._resolver, this._delegate);

  final LuaHostCommandResolver _resolver;
  final lua.LuaHostProcessLauncher _delegate;
  Future<lua.LuaHostCommand>? _resolution;

  @override
  Future<lua.LuaHostProcess> start(
    lua.LuaHostCommand command, {
    required String workingDirectory,
  }) async {
    final resolved = await _resolve();
    return _delegate.start(
      resolved.withEnvironment(command.environment),
      workingDirectory: workingDirectory,
    );
  }

  Future<lua.LuaHostCommand> _resolve() {
    final existing = _resolution;
    if (existing != null) return existing;

    final shared = Future<lua.LuaHostCommand>.sync(_resolver).then(
      (command) => command,
      onError: (Object error, StackTrace stackTrace) {
        _resolution = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _resolution = shared;
    return shared;
  }
}

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
