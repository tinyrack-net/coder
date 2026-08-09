import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools.dart';
import 'package:agent/src/tools/exec_sessions.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/local.dart';
import 'package:platform/platform.dart';

/// Name of the tool that starts a command session.
const String execCommandToolName = 'exec_command';

/// Name of the tool that writes into a live command session.
const String writeStdinToolName = 'write_stdin';

/// How long a call waits for output before returning, unless overridden.
const Duration defaultExecYieldTime = Duration(seconds: 10);

/// Bounds on the wait a call may request.
const Duration minExecYieldTime = Duration(milliseconds: 100);

/// Longest wait a call may request.
const Duration maxExecYieldTime = Duration(seconds: 60);

/// How long a write waits for the program to answer, unless overridden.
///
/// A write is a turn in a conversation with a program that is already warm, so
/// it usually answers immediately. Waiting the full [defaultExecYieldTime] for
/// a shell that already printed its prompt only burns wall-clock time.
const Duration defaultWriteYieldTime = Duration(milliseconds: 250);

/// Shortest wait an output-only poll may request.
///
/// Polling with no input to send produces nothing new until the program does,
/// so a sub-second poll is a busy loop that spends a tool call per round trip.
const Duration minPollYieldTime = Duration(seconds: 5);

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

Map<String, dynamic> _yieldTimeSchema({
  required Duration fallback,
  required String clamping,
}) => <String, dynamic>{
  'type': <String>['integer', 'null'],
  'description':
      'How long to wait for output, in milliseconds. Null uses '
      '${fallback.inMilliseconds}. $clamping',
};

Map<String, dynamic> _outputTokensSchema() => <String, dynamic>{
  'type': <String>['integer', 'null'],
  'description':
      'Approximate output budget in tokens. Null uses '
      '$defaultExecOutputTokens; values are clamped to '
      '$minExecOutputTokens…$maxExecOutputTokens. The tail is kept.',
};

Duration _yieldTime(
  Object? raw, {
  required Duration fallback,
  required Duration floor,
}) {
  if (raw is! int) return fallback;
  return Duration(
    milliseconds: raw.clamp(
      floor.inMilliseconds,
      maxExecYieldTime.inMilliseconds,
    ),
  );
}

int _outputTokens(Object? raw) => raw is int
    ? raw.clamp(minExecOutputTokens, maxExecOutputTokens)
    : defaultExecOutputTokens;

/// Estimated token count of [output] before any budget was applied.
int estimateTokenCount(String output) =>
    (utf8.encode(output).length / bytesPerToken).ceil();

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
      // Both are what let the model reason about what it did not get: how much
      // output was dropped, and whether the wait was actually consumed.
      'originalTokenCount': estimateTokenCount(chunk.output),
      'wallTimeSeconds': chunk.wallTime.inMilliseconds / 1000,
    }),
  );
}

/// Runs a command in a session that outlives the call.
///
/// Subsumes one-shot execution: a command that finishes inside the wait
/// returns its output and exit code with no session to clean up.
class ExecCommandTool extends AgentTool {
  /// Creates an [ExecCommandTool].
  ExecCommandTool({
    required this._host,
    this._fileSystem = const LocalFileSystem(),
    this._platform = const LocalPlatform(),
  });

  final ExecSessionHost _host;
  final file_api.FileSystem _fileSystem;
  final Platform _platform;

  @override
  String get name => execCommandToolName;

  @override
  String get description =>
      'Run a shell command. If it finishes in time you get its output and exit '
      'code; if it is still running you get a sessionId to drive with '
      '$writeStdinToolName. Use it for one-off commands as well as for REPLs '
      'and servers you want to keep alive.';

  @override
  AgentToolRisk get risk => AgentToolRisk.command;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'command': <String, dynamic>{
          'type': 'string',
          'description': 'The shell command to run.',
        },
        'workdir': <String, dynamic>{
          'type': <String>['string', 'null'],
          'description':
              'Directory to run in, relative to the workspace root. Null runs '
              'at the root. Must stay inside the workspace.',
        },
        'tty': <String, dynamic>{
          'type': <String>['boolean', 'null'],
          'description':
              'Whether to allocate a pseudo-terminal. Null and false use plain '
              'pipes, which is what you want for ordinary commands: no escape '
              'sequences and no echoed input. Pass true only for programs that '
              'need a terminal, such as REPLs and full-screen tools.',
        },
        'yield_time_ms': _yieldTimeSchema(
          fallback: defaultExecYieldTime,
          clamping:
              'Values are clamped to ${minExecYieldTime.inMilliseconds}…'
              '${maxExecYieldTime.inMilliseconds}.',
        ),
        'max_output_tokens': _outputTokensSchema(),
      });

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final command = arguments['command'];
    if (command is! String) return null;
    final workdir = arguments['workdir'];
    // The directory is part of what the user is approving, so it belongs in
    // the preview whenever it is not simply the workspace root.
    return workdir is String && workdir.trim().isNotEmpty
        ? '$command  (in $workdir)'
        : command;
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
    final String workingDirectory;
    try {
      workingDirectory = _resolveWorkdir(
        arguments['workdir'],
        context.workspaceRoot,
      );
    } on FileSystemException catch (error) {
      // A bad directory is something the model can fix on the next call, so it
      // is reported as tool output rather than failing the turn.
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'workdir is not a usable directory inside the workspace.',
          'detail': error.message,
        }),
        isError: true,
      );
    }
    context.cancellation.throwIfCancelled();
    final session = await _host.start(
      command: command,
      workingDirectory: workingDirectory,
      tty: arguments['tty'] == true,
    );
    // Reaching this line means the approval gate already passed, which is how
    // a session the user allowed becomes writable without re-asking.
    _host.markApproved(session.id);
    final chunk = await _readWithCancellation(
      session,
      _yieldTime(
        arguments['yield_time_ms'],
        fallback: defaultExecYieldTime,
        floor: minExecYieldTime,
      ),
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

  String _resolveWorkdir(Object? raw, String workspaceRoot) {
    if (raw is! String || raw.trim().isEmpty) return workspaceRoot;
    final resolved = WorkspacePathGuard(
      workspaceRoot,
      fileSystem: _fileSystem,
      platform: _platform,
    ).resolveExisting(raw);
    if (!_fileSystem.directory(resolved).existsSync()) {
      throw FileSystemException('Not a directory.', resolved);
    }
    return resolved;
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
  AgentToolRisk get risk => AgentToolRisk.command;

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
        'yield_time_ms': _yieldTimeSchema(
          fallback: defaultWriteYieldTime,
          clamping:
              'An empty poll waits at least '
              '${minPollYieldTime.inMilliseconds} and defaults to '
              '${defaultExecYieldTime.inMilliseconds}; a write waits at least '
              '${minExecYieldTime.inMilliseconds}. Both cap at '
              '${maxExecYieldTime.inMilliseconds}.',
        ),
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
      // A write and a poll are different questions: a write asks a warm program
      // to answer now, a poll waits for one that has nothing to say yet.
      chars.isEmpty
          ? _yieldTime(
              arguments['yield_time_ms'],
              fallback: defaultExecYieldTime,
              floor: minPollYieldTime,
            )
          : _yieldTime(
              arguments['yield_time_ms'],
              fallback: defaultWriteYieldTime,
              floor: minExecYieldTime,
            ),
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

/// Registers running shell commands, and writing to the ones still running.
final class ExecCommandToolProvider extends SelectableToolProvider {
  /// Creates a [ExecCommandToolProvider].
  const ExecCommandToolProvider();

  @override
  String get id => 'exec_command';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description:
        'Run shell commands, on pipes or in a pseudo-terminal, '
        'including REPLs and servers driven across several calls.',
    risk: AgentToolRisk.command,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    ExecCommandTool(host: scope.execHost),
    WriteStdinTool(host: scope.execHost),
  ];

  @override
  ApprovalPolicy decoratePolicy(ApprovalPolicy inner, AgentToolScope scope) =>
      ExecSessionApprovalPolicy(
        inner,
        scope.execHost,
        toolName: writeStdinToolName,
      );
}
