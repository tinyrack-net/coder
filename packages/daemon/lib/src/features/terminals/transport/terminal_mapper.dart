import 'package:daemon/src/features/terminals/domain/terminal.dart';
import 'package:protocol/protocol.dart';

/// Maps a terminal domain snapshot to its v5 wire DTO.
TerminalDto terminalToDto(Terminal terminal) => TerminalDto(
  id: terminal.id,
  worktreeId: terminal.worktreeId,
  title: terminal.title,
  shell: ShellSpecDto(
    executable: terminal.shell.executable,
    arguments: terminal.shell.arguments,
  ),
  status: TerminalStatus.values.byName(terminal.status.name),
  columns: terminal.columns,
  rows: terminal.rows,
  lastSequence: terminal.lastSequence,
  exitCode: terminal.exitCode,
  error: terminal.error,
);

/// Maps terminal output to its v5 wire DTO.
TerminalOutputDto terminalOutputToDto(TerminalOutput output) =>
    TerminalOutputDto(
      terminalId: output.terminalId,
      sequence: output.sequence,
      data: output.data,
    );

/// Maps a restore request from its v5 wire DTO.
TerminalRestoreRequest terminalRestoreRequestFromDto(
  TerminalAttachParamsDto params,
) => TerminalRestoreRequest(
  strategy: switch (params.mode) {
    TerminalRestoreMode.resume => TerminalRestoreStrategy.resume,
    TerminalRestoreMode.snapshot => TerminalRestoreStrategy.snapshot,
  },
  afterSequence: params.afterSequence,
  scrollbackLines: params.scrollbackLines,
  viewport: switch (params.viewport) {
    null => null,
    final viewport => TerminalViewport(
      columns: viewport.columns,
      rows: viewport.rows,
    ),
  },
);

/// Maps an attach result to its v5 wire DTO.
TerminalAttachResultDto terminalRestoreToDto(TerminalRestore restore) =>
    TerminalAttachResultDto(
      terminal: terminalToDto(restore.terminal),
      restore: switch (restore) {
        TerminalDeltaRestore(:final afterSequence, :final chunks) =>
          TerminalRestoreDto.delta(
            afterSequence: afterSequence,
            chunks: chunks.map(terminalOutputToDto).toList(growable: false),
          ),
        TerminalSnapshotRestore(:final throughSequence, :final ansi) =>
          TerminalRestoreDto.snapshot(
            throughSequence: throughSequence,
            ansi: ansi,
          ),
      },
    );
