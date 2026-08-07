import 'dart:convert';

import 'package:coder_daemon/src/features/terminals/application/terminal_service.dart';
import 'package:coder_daemon/src/features/terminals/transport/terminal_mapper.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Builds the terminal feature's complete v4 RPC surface.
List<RpcBindingDescriptor> terminalRpcBindings({
  required TerminalService terminals,
  required SettingsRepository settings,
}) => <RpcBindingDescriptor>[
  RpcBinding(terminalsListProcedure, (request, _) async {
    return TerminalListResultDto(
      terminals: terminals
          .list(request.worktreeId)
          .map(terminalToDto)
          .toList(growable: false),
    );
  }),
  RpcBinding(terminalsCreateProcedure, (request, _) async {
    return TerminalResultDto(
      terminal: terminalToDto(
        await terminals.create(
          id: request.id,
          worktreeId: request.worktreeId,
          title: request.title,
          columns: request.columns,
          rows: request.rows,
        ),
      ),
    );
  }),
  RpcBinding(terminalsAttachProcedure, (request, _) async {
    return terminalAttachmentToDto(
      terminals.attach(
        request.terminalId,
        afterSequence: request.afterSequence,
      ),
    );
  }),
  RpcBinding(terminalsWriteProcedure, (request, _) async {
    await terminals.write(request.terminalId, request.data);
    return const EmptyResultDto();
  }),
  RpcBinding(terminalsResizeProcedure, (request, _) async {
    return TerminalResultDto(
      terminal: terminalToDto(
        await terminals.resize(
          request.terminalId,
          columns: request.columns,
          rows: request.rows,
        ),
      ),
    );
  }),
  RpcBinding(terminalsTerminateProcedure, (request, _) async {
    await terminals.terminate(request.terminalId);
    return const EmptyResultDto();
  }),
  RpcBinding(terminalsGetDefaultShellProcedure, (_, _) async {
    final stored = await settings.getValue('terminal.shell');
    return TerminalShellDto(
      shell: stored == null || stored.isEmpty
          ? null
          : ShellSpecDto.fromJson(
              Map<String, dynamic>.from(jsonDecode(stored) as Map),
            ),
    );
  }),
  RpcBinding(terminalsSetDefaultShellProcedure, (request, _) async {
    if (request.shell case final shell? when shell.executable.trim().isEmpty) {
      throw const FormatException('Shell executable must not be empty.');
    }
    await settings.setValue(
      'terminal.shell',
      request.shell == null ? '' : jsonEncode(request.shell!.toJson()),
    );
    return const EmptyResultDto();
  }),
];
