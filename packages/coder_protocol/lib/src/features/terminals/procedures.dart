import 'package:coder_protocol/src/common/rpc_values.dart';
import 'package:coder_protocol/src/models.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';
import 'package:coder_protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final terminalsListProcedure =
    RpcProcedure<TerminalListParamsDto, TerminalListResultDto>(
      name: 'terminals.list',
      decodeParams: TerminalListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TerminalListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsCreateProcedure =
    RpcProcedure<TerminalCreateParamsDto, TerminalResultDto>(
      name: 'terminals.create',
      decodeParams: TerminalCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TerminalResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsAttachProcedure =
    RpcProcedure<TerminalAttachParamsDto, TerminalAttachResultDto>(
      name: 'terminals.attach',
      decodeParams: TerminalAttachParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TerminalAttachResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsWriteProcedure =
    RpcProcedure<TerminalWriteParamsDto, EmptyResultDto>(
      name: 'terminals.write',
      decodeParams: TerminalWriteParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsResizeProcedure =
    RpcProcedure<TerminalResizeParamsDto, TerminalResultDto>(
      name: 'terminals.resize',
      decodeParams: TerminalResizeParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TerminalResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsTerminateProcedure =
    RpcProcedure<TerminalIdParamsDto, EmptyResultDto>(
      name: 'terminals.terminate',
      decodeParams: TerminalIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsGetDefaultShellProcedure =
    RpcProcedure<EmptyParamsDto, TerminalShellDto>(
      name: 'terminals.getDefaultShell',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TerminalShellDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsSetDefaultShellProcedure =
    RpcProcedure<TerminalShellDto, EmptyResultDto>(
      name: 'terminals.setDefaultShell',
      decodeParams: TerminalShellDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final terminalsOutputNotification = RpcNotification<TerminalOutputDto>(
  name: 'terminals.output',
  decode: TerminalOutputDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final terminalsUpdatedNotification = RpcNotification<TerminalDto>(
  name: 'terminals.updated',
  decode: TerminalDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final terminalsProcedures = <RpcProcedureDescriptor>[
  terminalsListProcedure,
  terminalsCreateProcedure,
  terminalsAttachProcedure,
  terminalsWriteProcedure,
  terminalsResizeProcedure,
  terminalsTerminateProcedure,
  terminalsGetDefaultShellProcedure,
  terminalsSetDefaultShellProcedure,
];

/// Feature-owned descriptor catalog.
final terminalsNotifications = <RpcNotificationDescriptor>[
  terminalsOutputNotification,
  terminalsUpdatedNotification,
];
