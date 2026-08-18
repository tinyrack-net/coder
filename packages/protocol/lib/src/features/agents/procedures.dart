import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v5 transport descriptor.
final agentsListProcedure =
    RpcProcedure<EmptyParamsDto, AgentDefinitionListResultDto>(
      name: 'agents.list',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsGetProcedure =
    RpcProcedure<AgentDefinitionIdParamsDto, AgentDefinitionResultDto>(
      name: 'agents.get',
      decodeParams: AgentDefinitionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsCreateProcedure =
    RpcProcedure<AgentDefinitionCreateParamsDto, AgentDefinitionResultDto>(
      name: 'agents.create',
      decodeParams: AgentDefinitionCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsUpdateProcedure =
    RpcProcedure<AgentDefinitionUpdateParamsDto, AgentDefinitionResultDto>(
      name: 'agents.update',
      decodeParams: AgentDefinitionUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsArchiveProcedure =
    RpcProcedure<AgentDefinitionIdParamsDto, EmptyResultDto>(
      name: 'agents.archive',
      decodeParams: AgentDefinitionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsResetProcedure =
    RpcProcedure<AgentDefinitionIdParamsDto, AgentDefinitionResultDto>(
      name: 'agents.reset',
      decodeParams: AgentDefinitionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsValidateProcedure =
    RpcProcedure<AgentDefinitionValidateParamsDto, AgentDefinitionResultDto>(
      name: 'agents.validate',
      decodeParams: AgentDefinitionValidateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentDefinitionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsListToolsProcedure =
    RpcProcedure<AgentToolCatalogParamsDto, AgentToolCatalogResultDto>(
      name: 'agents.listTools',
      decodeParams: AgentToolCatalogParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: AgentToolCatalogResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsGetDefaultPermissionModeProcedure =
    RpcProcedure<EmptyParamsDto, PermissionSettingsDto>(
      name: 'agents.getDefaultPermissionMode',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PermissionSettingsDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsSetDefaultPermissionModeProcedure =
    RpcProcedure<PermissionSettingsDto, PermissionSettingsDto>(
      name: 'agents.setDefaultPermissionMode',
      decodeParams: PermissionSettingsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PermissionSettingsDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final agentsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'agents.changed',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final agentsProcedures = <RpcProcedureDescriptor>[
  agentsListProcedure,
  agentsGetProcedure,
  agentsCreateProcedure,
  agentsUpdateProcedure,
  agentsArchiveProcedure,
  agentsResetProcedure,
  agentsValidateProcedure,
  agentsListToolsProcedure,
  agentsGetDefaultPermissionModeProcedure,
  agentsSetDefaultPermissionModeProcedure,
];

/// Feature-owned descriptor catalog.
final agentsNotifications = <RpcNotificationDescriptor>[
  agentsChangedNotification,
];
