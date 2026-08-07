import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools/exec_tools.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// One drain of a live [ExecSession]'s output.
class ExecSessionChunk {
  /// Creates an [ExecSessionChunk].
  const ExecSessionChunk({
    required this.output,
    required this.isRunning,
    this.exitCode,
    this.wallTime = Duration.zero,
  });

  /// Output produced since the previous read, decoded leniently.
  final String output;

  /// Whether the command is still running.
  final bool isRunning;

  /// Exit status once the command finished; null while it runs.
  final int? exitCode;

  /// How long this read actually waited.
  ///
  /// Reported back to the model so it can tell a command that finished
  /// instantly from one that consumed the whole yield window, which is what
  /// decides whether polling again is worthwhile.
  final Duration wallTime;
}

/// A live pseudo-terminal the agent can drive across several tool calls.
abstract interface class ExecSession {
  /// Host-assigned identifier the model refers to the session by.
  String get id;

  /// Writes [chars] to the session's standard input.
  Future<void> write(String chars);

  /// Drains buffered output, waiting at most [yieldTime] for more.
  ///
  /// Returns early once the command exits. The wait lives in the host, which
  /// keeps the tools deterministic under a scripted fake.
  Future<ExecSessionChunk> read(Duration yieldTime);

  /// Interrupts the foreground command without ending the session.
  Future<void> interrupt();
}

/// Owns the terminals and pipes one coder session may drive.
abstract interface class ExecSessionHost {
  /// Starts [command] in a new session rooted at [workingDirectory].
  ///
  /// [workingDirectory] is already resolved and verified to sit inside the
  /// workspace by the caller, so a host never has to re-check containment.
  /// When [tty] is false the command runs on plain pipes instead of a
  /// pseudo-terminal: no escape sequences, no echo, and no interactive
  /// prompts.
  Future<ExecSession> start({
    required String command,
    required String workingDirectory,
    required bool tty,
  });

  /// Returns a live session, or null when it never existed or already ended.
  ExecSession? lookup(String sessionId);

  /// Whether the user already approved commands for [sessionId].
  bool isApproved(String sessionId);

  /// Records that the user approved the command that started [sessionId].
  void markApproved(String sessionId);
}

/// Approves later writes into a pseudo-terminal the user already allowed.
///
/// Without this, `ask` mode raises a dialog for every write into a session,
/// which makes an interactive shell unusable. It only ever upgrades an ask to
/// an allow: a denial from the inner policy — every non-read tool under
/// [PermissionMode.readOnly] — is never overturned.
class ExecSessionApprovalPolicy implements ApprovalPolicy {
  /// Creates an [ExecSessionApprovalPolicy].
  const ExecSessionApprovalPolicy(this._inner, this._host);

  final ApprovalPolicy _inner;
  final ExecSessionHost _host;

  @override
  ApprovalEvaluation evaluate(ToolInvocation invocation) {
    final decision = _inner.evaluate(invocation);
    if (decision != ApprovalEvaluation.ask) return decision;
    if (invocation.name != writeStdinToolName) return decision;
    final sessionId = invocation.arguments['session_id'];
    return sessionId is String && _host.isApproved(sessionId)
        ? ApprovalEvaluation.allow
        : decision;
  }
}
