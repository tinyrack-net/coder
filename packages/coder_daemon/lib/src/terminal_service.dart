import 'dart:async';
import 'dart:convert';

import 'package:coder_daemon/src/ports.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Running pseudo-terminal process boundary.
abstract interface class TerminalProcess implements ExecProcess {
  /// Changes the PTY character-cell dimensions.
  Future<void> resize(int columns, int rows);
}

/// Starts interactive terminal processes.
abstract interface class TerminalGateway {
  /// Starts a shell in a working directory.
  Future<TerminalProcess> start({
    required ShellSpecDto shell,
    required String workingDirectory,
    required int columns,
    required int rows,
  });
}

/// Resolves an active worktree to its checkout path.
typedef WorktreePathResolver = Future<String> Function(String worktreeId);

/// Resolves the effective project, host, or OS shell.
typedef ShellResolver = Future<ShellSpecDto> Function(String worktreeId);

/// Owns live terminals and bounded replay while the daemon is running.
final class TerminalService {
  /// Creates a terminal service around injected host boundaries.
  TerminalService({
    required this.gateway,
    required this.worktreePath,
    required this.shellFor,
    this.maxReplayBytes = 1024 * 1024,
  });

  /// Host PTY boundary.
  final TerminalGateway gateway;

  /// Active worktree path resolver.
  final WorktreePathResolver worktreePath;

  /// Effective shell resolver.
  final ShellResolver shellFor;

  /// Maximum UTF-8 bytes retained per terminal.
  final int maxReplayBytes;
  final Map<String, _LiveTerminal> _terminals = <String, _LiveTerminal>{};
  final StreamController<Object> _events = StreamController<Object>.broadcast(
    sync: true,
  );

  /// Emits [TerminalDto] and [TerminalOutputDto] changes.
  Stream<Object> get events => _events.stream;

  /// Lists live and exited terminals for one worktree.
  List<TerminalDto> list(String worktreeId) => _terminals.values
      .where((item) => item.dto.worktreeId == worktreeId)
      .map((item) => item.dto)
      .toList(growable: false);

  /// Starts a new interactive terminal.
  Future<TerminalDto> create({
    required String id,
    required String worktreeId,
    required String title,
    required int columns,
    required int rows,
  }) async {
    if (_terminals.containsKey(id)) {
      throw const FormatException('Terminal ID already exists.');
    }
    if (columns <= 0 || rows <= 0) {
      throw const FormatException('Terminal dimensions must be positive.');
    }
    final shell = await shellFor(worktreeId);
    if (shell.executable.trim().isEmpty) {
      throw const FormatException('Shell executable must not be empty.');
    }
    final process = await gateway.start(
      shell: shell,
      workingDirectory: await worktreePath(worktreeId),
      columns: columns,
      rows: rows,
    );
    final terminal = _LiveTerminal(
      process: process,
      dto: TerminalDto(
        id: id,
        worktreeId: worktreeId,
        title: title,
        shell: shell,
        status: TerminalStatus.running,
        columns: columns,
        rows: rows,
        lastSequence: 0,
      ),
    );
    _terminals[id] = terminal;
    process.outputs.listen(
      (data) => _record(terminal, data),
      onError: (Object error, StackTrace _) => _fail(terminal, error),
    );
    unawaited(
      process.exitCode.then((code) {
        terminal.dto = terminal.dto.copyWith(
          status: TerminalStatus.exited,
          exitCode: code,
        );
        _events.add(terminal.dto);
      }),
    );
    _events.add(terminal.dto);
    return terminal.dto;
  }

  /// Returns metadata and output newer than [afterSequence].
  TerminalAttachResultDto attach(String id, {required int afterSequence}) {
    final terminal = _require(id);
    return TerminalAttachResultDto(
      terminal: terminal.dto,
      replay: terminal.replay
          .where((item) => item.sequence > afterSequence)
          .toList(growable: false),
    );
  }

  /// Writes input to one terminal.
  Future<void> write(String id, String data) =>
      _require(id).process.write(data);

  /// Resizes one terminal.
  Future<TerminalDto> resize(
    String id, {
    required int columns,
    required int rows,
  }) async {
    if (columns <= 0 || rows <= 0) {
      throw const FormatException('Terminal dimensions must be positive.');
    }
    final terminal = _require(id);
    await terminal.process.resize(columns, rows);
    terminal.dto = terminal.dto.copyWith(columns: columns, rows: rows);
    _events.add(terminal.dto);
    return terminal.dto;
  }

  /// Terminates one terminal.
  Future<void> terminate(String id) => _require(id).process.terminate();

  /// Terminates every owned PTY and closes the event stream.
  Future<void> close() async {
    await Future.wait(
      _terminals.values.map((terminal) => terminal.process.terminate()),
    );
    await _events.close();
  }

  void _record(_LiveTerminal terminal, String data) {
    final sequence = terminal.dto.lastSequence + 1;
    terminal.dto = terminal.dto.copyWith(lastSequence: sequence);
    terminal.replay.add(
      TerminalOutputDto(
        terminalId: terminal.dto.id,
        sequence: sequence,
        data: data,
      ),
    );
    // Carried across chunks rather than recomputed. Re-measuring the whole
    // buffer here costs a full megabyte of encoding per chunk once the budget
    // is reached, which blocks this isolate for hundreds of milliseconds on a
    // single burst of PTY reads and stalls every other request with it.
    terminal.replayBytes += utf8.encode(data).length;
    while (terminal.replayBytes > maxReplayBytes &&
        terminal.replay.isNotEmpty) {
      final first = terminal.replay.first;
      final bytes = utf8.encode(first.data);
      final excess = terminal.replayBytes - maxReplayBytes;
      if (bytes.length <= excess) {
        terminal.replay.removeAt(0);
        terminal.replayBytes -= bytes.length;
      } else {
        var start = excess;
        while (start < bytes.length && (bytes[start] & 0xC0) == 0x80) {
          start += 1;
        }
        terminal.replay[0] = first.copyWith(
          data: utf8.decode(bytes.sublist(start)),
        );
        terminal.replayBytes -= start;
      }
    }
    _events.add(terminal.replay.last);
  }

  void _fail(_LiveTerminal terminal, Object error) {
    terminal.dto = terminal.dto.copyWith(
      status: TerminalStatus.failed,
      error: error.toString(),
    );
    _events.add(terminal.dto);
  }

  _LiveTerminal _require(String id) {
    final terminal = _terminals[id];
    if (terminal == null) throw const FormatException('Terminal not found.');
    return terminal;
  }
}

final class _LiveTerminal {
  _LiveTerminal({required this.process, required this.dto});
  final TerminalProcess process;
  TerminalDto dto;
  final List<TerminalOutputDto> replay = <TerminalOutputDto>[];

  /// UTF-8 bytes currently held in [replay].
  int replayBytes = 0;
}
