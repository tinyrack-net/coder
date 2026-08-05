import 'dart:convert';

import 'package:coder_agent/src/exec_sessions.dart';
import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Name of the tool that starts a pseudo-terminal command.
const String execCommandToolName = 'exec_command';

/// Name of the tool that writes into a live pseudo-terminal.
const String writeStdinToolName = 'write_stdin';

/// How long a call waits for output before returning, unless overridden.
const Duration defaultExecYieldTime = Duration(seconds: 10);

/// Bounds on the wait a call may request.
const Duration minExecYieldTime = Duration(milliseconds: 100);

/// Longest wait a call may request.
const Duration maxExecYieldTime = Duration(seconds: 60);

/// Output budget one call returns, unless overridden.
const int defaultExecOutputTokens = 10000;

/// Smallest output budget a call may request.
const int minExecOutputTokens = 256;

/// Largest output budget a call may request.
const int maxExecOutputTokens = 100000;

/// Bytes of output assumed to fit in one token.
///
/// A rough average is enough: the budget only has to keep a runaway command
/// from flooding the context, and [truncateToolOutput] is the hard ceiling.
const int bytesPerToken = 4;

/// Truncates [output] to roughly [maxTokens], keeping its tail.
///
/// Terminal output matters most at the end — the prompt, the error, the exit
/// line — so the head is dropped and replaced with a note saying how much.
String truncateToTokenBudget(String output, int maxTokens) {
  final limit = maxTokens * bytesPerToken;
  final bytes = utf8.encode(output);
  if (bytes.length <= limit) return output;
  var start = bytes.length - limit;
  while (start < bytes.length && (bytes[start] & 0xC0) == 0x80) {
    start += 1;
  }
  final elided = start;
  return '[… $elided bytes elided …]\n${utf8.decode(bytes.sublist(start))}';
}

Map<String, dynamic> _yieldTimeSchema() => <String, dynamic>{
  'type': <String>['integer', 'null'],
  'description':
      'How long to wait for output, in milliseconds. Null uses '
      '${defaultExecYieldTime.inMilliseconds}; values are clamped to '
      '${minExecYieldTime.inMilliseconds}…${maxExecYieldTime.inMilliseconds}.',
};

Map<String, dynamic> _outputTokensSchema() => <String, dynamic>{
  'type': <String>['integer', 'null'],
  'description':
      'Approximate output budget in tokens. Null uses '
      '$defaultExecOutputTokens; values are clamped to '
      '$minExecOutputTokens…$maxExecOutputTokens. The tail is kept.',
};

Duration _yieldTime(Object? raw) {
  if (raw is! int) return defaultExecYieldTime;
  return Duration(
    milliseconds: raw.clamp(
      minExecYieldTime.inMilliseconds,
      maxExecYieldTime.inMilliseconds,
    ),
  );
}

int _outputTokens(Object? raw) => raw is int
    ? raw.clamp(minExecOutputTokens, maxExecOutputTokens)
    : defaultExecOutputTokens;

String _encodeChunk(
  ExecSessionChunk chunk,
  int maxTokens, {
  String? sessionId,
}) {
  final truncated = truncateToTokenBudget(chunk.output, maxTokens);
  return truncateToolOutput(
    jsonEncode(<String, dynamic>{
      // A session id only appears while there is something left to drive.
      if (sessionId != null && chunk.isRunning) 'sessionId': sessionId,
      'output': truncated,
      'isRunning': chunk.isRunning,
      if (chunk.exitCode != null) 'exitCode': chunk.exitCode,
      'truncated': truncated.length != chunk.output.length,
    }),
  );
}

/// Runs a command in a pseudo-terminal that outlives the call.
///
/// Subsumes one-shot execution: a command that finishes inside the wait
/// returns its output and exit code with no session to clean up.
class ExecCommandTool extends AgentTool {
  /// Creates an [ExecCommandTool].
  factory ExecCommandTool({required ExecSessionHost host}) =>
      ExecCommandTool._(host);

  ExecCommandTool._(this._host);

  final ExecSessionHost _host;

  @override
  String get name => execCommandToolName;

  @override
  String get description =>
      'Run a shell command in a pseudo-terminal. If it finishes in time you '
      'get its output and exit code; if it is still running you get a '
      'sessionId to drive with $writeStdinToolName. Use it for one-off '
      'commands as well as for REPLs and servers you want to keep alive.';

  @override
  ToolRisk get risk => ToolRisk.command;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'command': <String, dynamic>{
          'type': 'string',
          'description': 'The shell command to run.',
        },
        'yield_time_ms': _yieldTimeSchema(),
        'max_output_tokens': _outputTokensSchema(),
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final command = arguments['command'];
    return command is String ? command : null;
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final command = arguments['command'];
    if (command is! String || command.trim().isEmpty) {
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'command must be a non-empty string.',
        }),
        isError: true,
      );
    }
    context.cancellation.throwIfCancelled();
    final session = await _host.start(command, context.workspaceRoot);
    // Reaching this line means the approval gate already passed, which is how
    // a session the user allowed becomes writable without re-asking.
    _host.markApproved(session.id);
    final chunk = await _readWithCancellation(
      session,
      _yieldTime(arguments['yield_time_ms']),
      context.cancellation,
    );
    return ToolResult(
      output: _encodeChunk(
        chunk,
        _outputTokens(arguments['max_output_tokens']),
        sessionId: session.id,
      ),
      isError: chunk.exitCode != null && chunk.exitCode != 0,
    );
  }
}

/// Writes into a live [ExecCommandTool] session and returns new output.
class WriteStdinTool extends AgentTool {
  /// Creates a [WriteStdinTool].
  factory WriteStdinTool({required ExecSessionHost host}) =>
      WriteStdinTool._(host);

  WriteStdinTool._(this._host);

  final ExecSessionHost _host;

  @override
  String get name => writeStdinToolName;

  @override
  String get description =>
      'Write to the standard input of a running $execCommandToolName session '
      'and read what it produces. Send an empty string to poll without '
      'writing. Include a trailing newline when the program expects a line.';

  @override
  ToolRisk get risk => ToolRisk.command;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'session_id': <String, dynamic>{
          'type': 'string',
          'description': 'A sessionId returned by $execCommandToolName.',
        },
        'chars': <String, dynamic>{
          'type': 'string',
          'description': 'Characters to write; empty polls for output.',
        },
        'yield_time_ms': _yieldTimeSchema(),
        'max_output_tokens': _outputTokensSchema(),
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final sessionId = arguments['session_id'];
    final chars = arguments['chars'];
    return sessionId is String && chars is String
        ? '$sessionId ← ${chars.trimRight()}'
        : null;
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final sessionId = arguments['session_id'];
    final chars = arguments['chars'];
    if (sessionId is! String || chars is! String) {
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'session_id and chars must both be strings.',
        }),
        isError: true,
      );
    }
    final session = _host.lookup(sessionId);
    if (session == null) {
      // A daemon restart kills every PTY while the id survives in history, so
      // this has to be recoverable rather than a failed turn.
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'exec session not found',
          'hint': 'Start a new $execCommandToolName.',
        }),
        isError: true,
      );
    }
    context.cancellation.throwIfCancelled();
    if (chars.isNotEmpty) await session.write(chars);
    final chunk = await _readWithCancellation(
      session,
      _yieldTime(arguments['yield_time_ms']),
      context.cancellation,
    );
    return ToolResult(
      output: _encodeChunk(
        chunk,
        _outputTokens(arguments['max_output_tokens']),
        sessionId: sessionId,
      ),
      isError: chunk.exitCode != null && chunk.exitCode != 0,
    );
  }
}

/// Reads one chunk, interrupting the command if the turn is cancelled.
///
/// The session itself survives: cancelling a turn should stop the command the
/// user asked to stop, not destroy a REPL they are still working in.
Future<ExecSessionChunk> _readWithCancellation(
  ExecSession session,
  Duration yieldTime,
  CancellationToken cancellation,
) async {
  var interrupted = false;
  void onCancel() {
    interrupted = true;
    session.interrupt().ignore();
  }

  cancellation.onCancel(onCancel);
  final chunk = await session.read(yieldTime);
  if (interrupted || cancellation.isCancelled) {
    throw const AgentCancelledException();
  }
  return chunk;
}
