import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final mcpListServersProcedure =
    RpcProcedure<McpServersParamsDto, McpServersResultDto>(
      name: 'mcp.listServers',
      decodeParams: McpServersParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: McpServersResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final mcpAddServerProcedure =
    RpcProcedure<McpServerParamsDto, McpServerStateResultDto>(
      name: 'mcp.addServer',
      decodeParams: McpServerParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: McpServerStateResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final mcpUpdateServerProcedure =
    RpcProcedure<McpServerParamsDto, McpServerStateResultDto>(
      name: 'mcp.updateServer',
      decodeParams: McpServerParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: McpServerStateResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final mcpRemoveServerProcedure =
    RpcProcedure<McpServerIdParamsDto, EmptyResultDto>(
      name: 'mcp.removeServer',
      decodeParams: McpServerIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final mcpTestServerProcedure =
    RpcProcedure<McpServerParamsDto, McpServerStateResultDto>(
      name: 'mcp.testServer',
      decodeParams: McpServerParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: McpServerStateResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final mcpSetSecretProcedure = RpcProcedure<McpSecretParamsDto, EmptyResultDto>(
  name: 'mcp.setSecret',
  decodeParams: McpSecretParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: EmptyResultDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final mcpChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'mcp.changed',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final mcpProcedures = <RpcProcedureDescriptor>[
  mcpListServersProcedure,
  mcpAddServerProcedure,
  mcpUpdateServerProcedure,
  mcpRemoveServerProcedure,
  mcpTestServerProcedure,
  mcpSetSecretProcedure,
];

/// Feature-owned descriptor catalog.
final mcpNotifications = <RpcNotificationDescriptor>[mcpChangedNotification];
