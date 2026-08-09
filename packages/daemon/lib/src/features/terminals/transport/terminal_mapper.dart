import 'package:daemon/src/features/terminals/domain/terminal.dart';
import 'package:protocol/protocol.dart';

/// Maps a terminal domain snapshot to its v4 wire DTO.
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

/// Maps terminal output to its v4 wire DTO.
TerminalOutputDto terminalOutputToDto(TerminalOutput output) =>
    TerminalOutputDto(
      terminalId: output.terminalId,
      sequence: output.sequence,
      data: output.data,
    );

/// Maps an attach result to its v4 wire DTO.
TerminalAttachResultDto terminalAttachmentToDto(
  TerminalAttachment attachment,
) => TerminalAttachResultDto(
  terminal: terminalToDto(attachment.terminal),
  replay: attachment.replay.map(terminalOutputToDto).toList(growable: false),
);
