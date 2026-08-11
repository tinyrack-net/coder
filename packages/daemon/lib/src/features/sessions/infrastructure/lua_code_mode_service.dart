import 'dart:convert';
import 'dart:io';

import 'package:agent/agent.dart';
import 'package:lua_tool_runtime/lua_tool_runtime.dart' as lua;
import 'package:path/path.dart' as p;

/// Resolves a packaged host, with the dependency source as a development
/// fallback. Production bundles always take the first branch.
lua.LuaHostCommand discoverLuaHostCommand({
  required String sourceRoot,
  String? resolvedExecutable,
  bool? isMacOS,
}) {
  final executableDirectory = p.dirname(
    resolvedExecutable ?? Platform.resolvedExecutable,
  );
  final packaged = lua.LuaHostCommand.fromDirectory(executableDirectory);
  if (File(packaged.executable).existsSync() &&
      File(packaged.arguments.single).existsSync()) {
    return packaged;
  }
  if (isMacOS ?? Platform.isMacOS) {
    final resourceBootstrap = p.normalize(
      p.join(
        executableDirectory,
        '..',
        'Resources',
        'lua_tool_runtime',
        'bootstrap.lua',
      ),
    );
    if (File(packaged.executable).existsSync() &&
        File(resourceBootstrap).existsSync()) {
      return lua.LuaHostCommand(
        executable: packaged.executable,
        arguments: <String>[resourceBootstrap],
      );
    }
  }

  var directory = Directory(p.normalize(p.absolute(sourceRoot)));
  while (true) {
    final packageConfig = File(
      p.join(directory.path, '.dart_tool', 'package_config.json'),
    );
    if (packageConfig.existsSync()) {
      final decoded = jsonDecode(packageConfig.readAsStringSync());
      if (decoded case {'packages': final List<dynamic> packages}) {
        for (final rawPackage in packages) {
          if (rawPackage case <String, dynamic>{
            'name': 'lua_tool_runtime',
            'rootUri': final String rootUri,
          }) {
            final root = packageConfig.parent.uri.resolve(rootUri).toFilePath();
            final bootstrap = p.join(root, 'native', 'bootstrap.lua');
            if (File(bootstrap).existsSync()) {
              return lua.LuaHostCommand(
                executable: Platform.isWindows ? 'lua.exe' : 'lua',
                arguments: <String>[bootstrap],
              );
            }
          }
        }
      }
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'lua-tool-runtime-host and its bootstrap could not be located next to '
    '${resolvedExecutable ?? Platform.resolvedExecutable}.',
  );
}

/// Adapts Tinest's tool and attachment contracts to the shared Lua runtime.
final class LuaCodeModeService {
  /// Creates a service over the process runtime supplied by the composition
  /// root.
  LuaCodeModeService(this._runtime);

  final lua.LuaToolRuntime<ConversationAttachment> _runtime;
  final Map<String, lua.LuaRuntimeSession<ConversationAttachment>> _sessions =
      <String, lua.LuaRuntimeSession<ConversationAttachment>>{};

  lua.LuaRuntimeSession<ConversationAttachment> _session(String owner) =>
      _sessions.putIfAbsent(owner, _runtime.createSession);

  /// Starts one fresh VM and returns its first output delta.
  Future<LuaCellChunk> execute({
    required String owner,
    required String workingDirectory,
    required LuaExecuteRequest request,
    required ToolExecutionContext context,
  }) async => _mapDelta(
    await _session(owner).execute(
      lua.LuaExecuteRequest(
        source: request.source,
        yieldTime: request.yieldTime,
        maxOutputTokens: request.maxOutputTokens,
        tools: <lua.LuaToolDefinition>[
          for (final tool in request.tools)
            lua.LuaToolDefinition(
              name: tool.name,
              description: tool.description,
              kind: tool.kind,
              namespace: tool.namespace,
              exposure: tool.exposure,
              inputSchema: tool.inputSchema,
              outputSchema: tool.outputSchema,
            ),
        ],
      ),
      _executionContext(context),
      workingDirectory: workingDirectory,
    ),
  );

  /// Resumes, observes, or terminates a session-owned cell.
  Future<LuaCellChunk> wait({
    required String owner,
    required LuaWaitRequest request,
    required ToolExecutionContext context,
  }) async {
    final session = _sessions[owner];
    if (session == null) {
      return LuaCellChunk(
        cellId: request.cellId,
        output: '',
        error: 'Lua cell not found.',
      );
    }
    return _mapDelta(
      await session.wait(
        lua.LuaWaitRequest(
          cellId: request.cellId,
          yieldTime: request.yieldTime,
          maxOutputTokens: request.maxOutputTokens,
          terminate: request.terminate,
        ),
        _executionContext(context),
      ),
    );
  }

  lua.LuaExecutionContext<ConversationAttachment> _executionContext(
    ToolExecutionContext context,
  ) => lua.LuaExecutionContext<ConversationAttachment>(
    dispatcher: _TinestLuaToolDispatcher(context),
    cancellation: _TinestLuaCancellation(context.cancellation),
  );

  LuaCellChunk _mapDelta(
    lua.LuaCellDelta<ConversationAttachment> delta,
  ) {
    var error = delta.error?.message;
    final contextImages = <ConversationAttachment>[];
    for (final resource in delta.emittedResources) {
      if (resource.mimeType.startsWith('image/')) {
        contextImages.add(resource.value);
      } else {
        error ??= resource.mimeType.startsWith('audio/')
            ? 'Audio output is not supported by the current provider bridge.'
            : 'Media handle ${resource.fileName} is not an image.';
      }
    }
    return LuaCellChunk(
      cellId: delta.cellId,
      output: delta.output,
      running: delta.running,
      terminated: delta.terminated,
      error: error,
      attachments: <ConversationAttachment>[
        for (final resource in delta.resources) resource.value,
      ],
      contextImages: contextImages,
      notifications: delta.notifications,
    );
  }

  /// Reclaims expired and over-time cells.
  void sweep() => _runtime.sweep();

  /// Terminates all cells owned by one Tinest session.
  Future<void> closeOwner(String owner) async {
    final session = _sessions.remove(owner);
    if (session != null) await session.close();
  }

  /// Terminates every helper process.
  Future<void> close() async {
    _sessions.clear();
    await _runtime.close();
  }
}

/// Session-scoped view that prevents cross-session cell access.
final class SessionLuaCodeModeHost implements LuaCodeModeHost {
  /// Creates the scoped host.
  const SessionLuaCodeModeHost(
    this._service,
    this._sessionId,
    this._workingDirectory,
  );

  final LuaCodeModeService _service;
  final String _sessionId;
  final String _workingDirectory;

  @override
  Future<LuaCellChunk> execute(
    LuaExecuteRequest request,
    ToolExecutionContext context,
  ) => _service.execute(
    owner: _sessionId,
    workingDirectory: _workingDirectory,
    request: request,
    context: context,
  );

  @override
  Future<LuaCellChunk> wait(
    LuaWaitRequest request,
    ToolExecutionContext context,
  ) => _service.wait(owner: _sessionId, request: request, context: context);
}

final class _TinestLuaToolDispatcher
    implements lua.LuaToolDispatcher<ConversationAttachment> {
  const _TinestLuaToolDispatcher(this._context);

  final ToolExecutionContext _context;

  @override
  Future<lua.LuaToolResult<ConversationAttachment>> invoke(
    lua.LuaToolInvocation invocation,
  ) async {
    final result = await _context.invokeNestedTool(
      invocation.name,
      Map<String, dynamic>.from(invocation.arguments),
    );
    final attachments = <ConversationAttachment>[
      ...result.attachments,
      ...result.contextImages,
    ];
    return lua.LuaToolResult<ConversationAttachment>(
      value: result.value,
      isError: result.isError,
      resources: <lua.LuaOpaqueResource<ConversationAttachment>>[
        for (final attachment in attachments)
          lua.LuaOpaqueResource<ConversationAttachment>(
            value: attachment,
            fileName: attachment.fileName,
            mimeType: attachment.mimeType,
            byteSize: attachment.byteSize,
          ),
      ],
      content: <Map<String, Object?>>[
        for (final block in result.content) block.toJson(),
      ],
      structuredContent: result.structuredContent,
      meta: result.meta,
    );
  }
}

final class _TinestLuaCancellation implements lua.LuaCancellationSignal {
  const _TinestLuaCancellation(this._token);

  final CancellationToken _token;

  @override
  void onCancel(void Function() callback) => _token.onCancel(callback);
}
