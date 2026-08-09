import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';

/// Stable capability identifier for Lua orchestration.
const String luaCodeModeCapabilityId = 'lua_code_mode';

/// Model-facing tool that starts a Lua cell.
const String luaExecToolName = 'exec';

/// Model-facing tool that resumes or terminates a Lua cell.
const String luaWaitToolName = 'wait';

/// Largest accepted Lua source body.
const int maxLuaSourceBytes = 256 * 1024;

/// Default time an exec or wait call observes a live cell.
const Duration defaultLuaYieldTime = Duration(seconds: 10);

/// Longest time one model call waits before yielding a live cell.
const Duration maxLuaYieldTime = Duration(seconds: 60);

/// Default output budget for one Lua tool response.
const int defaultLuaOutputTokens = 10000;

/// One request to start a fresh Lua VM.
final class LuaExecuteRequest {
  /// Creates a Lua execution request.
  const LuaExecuteRequest({
    required this.source,
    required this.yieldTime,
    required this.maxOutputTokens,
    required this.tools,
  });

  /// User-authored Lua source.
  final String source;

  /// Time to observe the cell before returning it as running.
  final Duration yieldTime;

  /// Output budget for this response.
  final int maxOutputTokens;

  /// Metadata for every callable nested tool.
  final List<LuaNestedToolDefinition> tools;
}

/// One request for a cell that already exists.
final class LuaWaitRequest {
  /// Creates a wait request.
  const LuaWaitRequest({
    required this.cellId,
    required this.yieldTime,
    required this.maxOutputTokens,
    required this.terminate,
  });

  /// Session-scoped cell identifier.
  final String cellId;

  /// Time to observe the cell before yielding again.
  final Duration yieldTime;

  /// Output budget for this response.
  final int maxOutputTokens;

  /// Whether to terminate rather than resume the cell.
  final bool terminate;
}

/// Nested tool metadata injected into the Lua runtime.
final class LuaNestedToolDefinition {
  /// Creates nested tool metadata.
  const LuaNestedToolDefinition({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Exact dispatcher name.
  final String name;

  /// Human-readable behavior.
  final String description;

  /// JSON schema for the argument table.
  final Map<String, dynamic> inputSchema;
}

/// Output drained from one Lua cell.
final class LuaCellChunk {
  /// Creates one cell result.
  const LuaCellChunk({
    required this.cellId,
    required this.output,
    this.running = false,
    this.terminated = false,
    this.error,
    this.attachments = const <ConversationAttachment>[],
    this.contextImages = const <ConversationAttachment>[],
  });

  /// Cell identifier used by [LuaWaitTool].
  final String cellId;

  /// Output produced since the previous drain.
  final String output;

  /// Whether the cell remains alive.
  final bool running;

  /// Whether this response was produced by explicit termination.
  final bool terminated;

  /// Script or host failure.
  final String? error;

  /// User-visible files published by the script.
  final List<ConversationAttachment> attachments;

  /// Images forwarded into model context.
  final List<ConversationAttachment> contextImages;
}

/// Session-scoped host for Lua cells.
abstract interface class LuaCodeModeHost {
  /// Starts a new cell and returns its first observable chunk.
  Future<LuaCellChunk> execute(
    LuaExecuteRequest request,
    ToolExecutionContext context,
  );

  /// Observes or terminates an existing cell.
  Future<LuaCellChunk> wait(
    LuaWaitRequest request,
    ToolExecutionContext context,
  );
}

/// Replaces direct tools with Lua exec/wait while retaining nested dispatch.
final class LuaCodeModeToolProvider extends AgentToolSurfaceProvider {
  /// Creates the Lua tool-surface provider.
  const LuaCodeModeToolProvider();

  @override
  String get id => luaCodeModeCapabilityId;

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: luaCodeModeCapabilityId,
    name: luaCodeModeCapabilityId,
    description: 'Orchestrate selected tools from sandboxed Lua code.',
    risk: AgentToolRisk.read,
  );

  @override
  AgentToolSurface buildSurface(
    AgentToolScope scope,
    List<AgentTool> nestedTools,
  ) {
    final host = scope.luaCodeModeHost;
    if (host == null) {
      throw StateError('Lua Code Mode is unavailable on this runtime.');
    }
    return AgentToolSurface(
      tools: <AgentTool>[
        LuaExecTool(host: host, nestedTools: nestedTools),
        LuaWaitTool(host: host),
      ],
      nestedTools: nestedTools,
      promptFragment: renderLuaCodeModePrompt(nestedTools),
    );
  }
}

/// Starts a sandboxed Lua orchestration cell.
final class LuaExecTool extends AgentTool {
  /// Creates an exec tool over a [LuaCodeModeHost].
  LuaExecTool({
    required this._host,
    required List<AgentTool> nestedTools,
  }) : _nestedTools = List<AgentTool>.unmodifiable(nestedTools);

  final LuaCodeModeHost _host;
  final List<AgentTool> _nestedTools;

  @override
  String get name => luaExecToolName;

  @override
  String get description =>
      'Run sandboxed Lua to orchestrate the selected nested tools.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject(
    <String, Map<String, dynamic>>{
      'source': <String, dynamic>{
        'type': 'string',
        'description': 'Raw Lua source code.',
      },
      'yield_time_ms': <String, dynamic>{
        'type': <String>['integer', 'null'],
        'description': 'Milliseconds to wait before yielding a live cell.',
      },
      'max_output_tokens': <String, dynamic>{
        'type': <String>['integer', 'null'],
        'description': 'Approximate output token budget.',
      },
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final source = arguments['source'];
    if (source is! String || source.trim().isEmpty) {
      return const ToolResult(
        output: 'Lua source must be non-empty.',
        isError: true,
      );
    }
    if (utf8.encode(source).length > maxLuaSourceBytes) {
      return const ToolResult(
        output: 'Lua source exceeds 256 KiB.',
        isError: true,
      );
    }
    final chunk = await _host.execute(
      LuaExecuteRequest(
        source: source,
        yieldTime: _yieldTime(arguments['yield_time_ms']),
        maxOutputTokens: _outputTokens(arguments['max_output_tokens']),
        tools: <LuaNestedToolDefinition>[
          for (final tool in _nestedTools)
            LuaNestedToolDefinition(
              name: tool.name,
              description: tool.description,
              inputSchema: tool.strictJsonSchema,
            ),
        ],
      ),
      context,
    );
    return _chunkResult(chunk);
  }
}

/// Observes or terminates a live Lua cell.
final class LuaWaitTool extends AgentTool {
  /// Creates a wait tool over a [LuaCodeModeHost].
  LuaWaitTool({required this._host});

  final LuaCodeModeHost _host;

  @override
  String get name => luaWaitToolName;

  @override
  String get description => 'Wait for or terminate a running Lua cell.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => strictToolObject(
    <String, Map<String, dynamic>>{
      'cell_id': <String, dynamic>{'type': 'string'},
      'yield_time_ms': <String, dynamic>{
        'type': <String>['integer', 'null'],
      },
      'max_tokens': <String, dynamic>{
        'type': <String>['integer', 'null'],
      },
      'terminate': <String, dynamic>{'type': 'boolean'},
    },
  );

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final cellId = arguments['cell_id'];
    if (cellId is! String || cellId.isEmpty) {
      return const ToolResult(
        output: 'cell_id must be non-empty.',
        isError: true,
      );
    }
    final chunk = await _host.wait(
      LuaWaitRequest(
        cellId: cellId,
        yieldTime: _yieldTime(arguments['yield_time_ms']),
        maxOutputTokens: _outputTokens(arguments['max_tokens']),
        terminate: arguments['terminate'] == true,
      ),
      context,
    );
    return _chunkResult(chunk);
  }
}

Duration _yieldTime(Object? raw) => Duration(
  milliseconds: raw is int
      ? raw.clamp(100, maxLuaYieldTime.inMilliseconds)
      : defaultLuaYieldTime.inMilliseconds,
);

int _outputTokens(Object? raw) =>
    raw is int ? raw.clamp(256, 100000) : defaultLuaOutputTokens;

ToolResult _chunkResult(LuaCellChunk chunk) {
  final status = chunk.terminated
      ? 'Script terminated'
      : chunk.running
      ? 'Script running with cell ID ${chunk.cellId}'
      : chunk.error == null
      ? 'Script completed'
      : 'Script failed';
  final output = <String>[
    status,
    if (chunk.output.isNotEmpty) chunk.output,
    if (chunk.error case final error?) 'Script error:\n$error',
  ].join('\n');
  return ToolResult(
    output: truncateToolOutput(output),
    isError: chunk.error != null,
    attachments: chunk.attachments,
    contextImages: chunk.contextImages,
  );
}

/// Renders the Lua globals and nested tool schemas into the turn prompt.
String renderLuaCodeModePrompt(List<AgentTool> nestedTools) {
  final buffer = StringBuffer('''
## Lua Code Mode

Use `exec` to run Lua. Only the safe standard libraries and these globals are
available: `tools`, `spawn`, `await`, `await_all`, `text`, `image`, `audio`,
`generated_image`, `store`, `load`, `notify`, `set_timeout`, `clear_timeout`,
`yield_control`, `exit`, `NULL`, and `ALL_TOOLS`. `NULL` is the JSON null value.
Tool calls suspend the current Lua
coroutine and retain their normal host approval policy.
''');
  for (final tool in nestedTools) {
    final identifier = _luaIdentifier(tool.name);
    buffer
      ..writeln('\n### tools.$identifier')
      ..writeln(tool.description)
      ..writeln('```json')
      ..writeln(jsonEncode(tool.strictJsonSchema))
      ..writeln('```');
  }
  return buffer.toString().trim();
}

String _luaIdentifier(String name) {
  final normalized = name.replaceAll(RegExp('[^A-Za-z0-9_]'), '_');
  if (normalized.isEmpty || RegExp('^[0-9]').hasMatch(normalized)) {
    return '_$normalized';
  }
  return normalized;
}
