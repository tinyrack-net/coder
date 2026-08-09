/// Shell command used to start a terminal.
final class TerminalShell {
  /// Creates a shell command.
  const TerminalShell({required this.executable, this.arguments = const []});

  /// Executable path or command name.
  final String executable;

  /// Arguments passed to [executable].
  final List<String> arguments;
}

/// Lifecycle state of a daemon-owned terminal.
enum TerminalLifecycle {
  /// Process is accepting input.
  running,

  /// Process exited normally.
  exited,

  /// Process or PTY stream failed.
  failed,
}

/// Domain snapshot of a daemon-owned terminal.
final class Terminal {
  /// Creates a terminal snapshot.
  const Terminal({
    required this.id,
    required this.worktreeId,
    required this.title,
    required this.shell,
    required this.status,
    required this.columns,
    required this.rows,
    required this.lastSequence,
    this.exitCode,
    this.error,
  });

  /// Stable terminal identifier.
  final String id;

  /// Worktree containing the process.
  final String worktreeId;

  /// User-facing title.
  final String title;

  /// Shell command used by the process.
  final TerminalShell shell;

  /// Current lifecycle state.
  final TerminalLifecycle status;

  /// PTY columns.
  final int columns;

  /// PTY rows.
  final int rows;

  /// Last emitted output sequence.
  final int lastSequence;

  /// Process exit code after a normal exit.
  final int? exitCode;

  /// Failure description after an abnormal exit.
  final String? error;

  /// Returns a copy with selected fields replaced.
  Terminal copyWith({
    TerminalLifecycle? status,
    int? columns,
    int? rows,
    int? lastSequence,
    int? exitCode,
    String? error,
  }) => Terminal(
    id: id,
    worktreeId: worktreeId,
    title: title,
    shell: shell,
    status: status ?? this.status,
    columns: columns ?? this.columns,
    rows: rows ?? this.rows,
    lastSequence: lastSequence ?? this.lastSequence,
    exitCode: exitCode ?? this.exitCode,
    error: error ?? this.error,
  );
}

/// One ordered terminal output chunk.
final class TerminalOutput {
  /// Creates an output chunk.
  const TerminalOutput({
    required this.terminalId,
    required this.sequence,
    required this.data,
  });

  /// Owning terminal identifier.
  final String terminalId;

  /// Monotonic per-terminal sequence.
  final int sequence;

  /// UTF-8 text emitted by the PTY.
  final String data;

  /// Returns a copy with replaced text.
  TerminalOutput copyWith({String? data}) => TerminalOutput(
    terminalId: terminalId,
    sequence: sequence,
    data: data ?? this.data,
  );
}

/// Terminal metadata plus replay output.
final class TerminalAttachment {
  /// Creates an attachment snapshot.
  const TerminalAttachment({required this.terminal, required this.replay});

  /// Current terminal metadata.
  final Terminal terminal;

  /// Output newer than the requested sequence.
  final List<TerminalOutput> replay;
}
