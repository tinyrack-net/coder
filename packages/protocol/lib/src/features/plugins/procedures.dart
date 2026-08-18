import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Lists installed built-in and app-data plugins.
final pluginsListProcedure = RpcProcedure<EmptyParamsDto, PluginListResultDto>(
  name: 'plugins.list',
  decodeParams: EmptyParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: PluginListResultDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Reads one installed plugin descriptor.
final pluginsGetProcedure = RpcProcedure<PluginIdParamsDto, PluginResultDto>(
  name: 'plugins.get',
  decodeParams: PluginIdParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: PluginResultDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Validates one plugin source without activating the candidate revision.
final pluginsValidateProcedure =
    RpcProcedure<PluginIdParamsDto, PluginResultDto>(
      name: 'plugins.validate',
      decodeParams: PluginIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Reloads one plugin using the referenced Agent's grants.
final pluginsReloadProcedure =
    RpcProcedure<PluginReloadParamsDto, PluginResultDto>(
      name: 'plugins.reload',
      decodeParams: PluginReloadParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Scaffolds one app-data user plugin package.
final pluginsScaffoldProcedure =
    RpcProcedure<PluginScaffoldParamsDto, PluginResultDto>(
      name: 'plugins.scaffold',
      decodeParams: PluginScaffoldParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Forks one installed validated revision into an app-data user plugin.
final pluginsForkProcedure = RpcProcedure<PluginForkParamsDto, PluginResultDto>(
  name: 'plugins.fork',
  decodeParams: PluginForkParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: PluginResultDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Describes the exact SDK ABI and LuaLS sidecar for one user plugin.
final pluginsGetPluginAuthoringEnvironmentProcedure =
    RpcProcedure<PluginIdParamsDto, PluginAuthoringEnvironmentResultDto>(
      name: 'plugins.getPluginAuthoringEnvironment',
      decodeParams: PluginIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginAuthoringEnvironmentResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Atomically synchronizes the exact SDK ABI and LuaLS sidecar.
final pluginsSyncPluginAuthoringEnvironmentProcedure =
    RpcProcedure<PluginIdParamsDto, PluginAuthoringEnvironmentResultDto>(
      name: 'plugins.syncPluginAuthoringEnvironment',
      decodeParams: PluginIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginAuthoringEnvironmentResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Lists capability grants owned by one Agent.
final pluginsListGrantsProcedure =
    RpcProcedure<AgentPluginGrantsParamsDto, PluginGrantListResultDto>(
      name: 'plugins.listGrants',
      decodeParams: AgentPluginGrantsParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginGrantListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Grants one exact Agent/plugin/capability tuple.
final pluginsGrantProcedure =
    RpcProcedure<PluginGrantParamsDto, PluginGrantListResultDto>(
      name: 'plugins.grant',
      decodeParams: PluginGrantParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginGrantListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Revokes one exact Agent/plugin/capability tuple.
final pluginsRevokeProcedure =
    RpcProcedure<PluginGrantParamsDto, PluginGrantListResultDto>(
      name: 'plugins.revoke',
      decodeParams: PluginGrantParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginGrantListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Stores one Agent/plugin-isolated secret without returning its value.
final pluginsSetSecretProcedure =
    RpcProcedure<PluginSecretSetParamsDto, EmptyResultDto>(
      name: 'plugins.setSecret',
      decodeParams: PluginSecretSetParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Removes one Agent/plugin-isolated secret without probing other scopes.
final pluginsRemoveSecretProcedure =
    RpcProcedure<PluginSecretRemoveParamsDto, EmptyResultDto>(
      name: 'plugins.removeSecret',
      decodeParams: PluginSecretRemoveParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Reads one durable Agent-active plugin session-control value.
final pluginsGetSessionControlProcedure =
    RpcProcedure<PluginSessionControlParamsDto, PluginSessionControlResultDto>(
      name: 'plugins.getSessionControl',
      decodeParams: PluginSessionControlParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginSessionControlResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Normalizes and replaces one durable plugin session-control value.
final pluginsSetSessionControlProcedure =
    RpcProcedure<
      PluginSessionControlSetParamsDto,
      PluginSessionControlResultDto
    >(
      name: 'plugins.setSessionControl',
      decodeParams: PluginSessionControlSetParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginSessionControlResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Renders one host-owned declarative UI slot.
final pluginsRenderUiProcedure =
    RpcProcedure<PluginUiRenderParamsDto, PluginUiDocumentResultDto>(
      name: 'plugins.renderUi',
      decodeParams: PluginUiRenderParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginUiDocumentResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Dispatches one action from a host-rendered plugin UI document.
final pluginsDispatchUiActionProcedure =
    RpcProcedure<PluginUiActionParamsDto, PluginUiDocumentResultDto>(
      name: 'plugins.dispatchUiAction',
      decodeParams: PluginUiActionParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: PluginUiDocumentResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// App-data plugin source files changed and should be revalidated by clients.
final pluginsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'plugins.changed',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Complete v5 plugin-management RPC catalog.
final pluginsProcedures = <RpcProcedureDescriptor>[
  pluginsListProcedure,
  pluginsGetProcedure,
  pluginsValidateProcedure,
  pluginsReloadProcedure,
  pluginsScaffoldProcedure,
  pluginsForkProcedure,
  pluginsGetPluginAuthoringEnvironmentProcedure,
  pluginsSyncPluginAuthoringEnvironmentProcedure,
  pluginsListGrantsProcedure,
  pluginsGrantProcedure,
  pluginsRevokeProcedure,
  pluginsSetSecretProcedure,
  pluginsRemoveSecretProcedure,
  pluginsGetSessionControlProcedure,
  pluginsSetSessionControlProcedure,
  pluginsRenderUiProcedure,
  pluginsDispatchUiActionProcedure,
];

/// Complete v5 plugin notification catalog.
final pluginsNotifications = <RpcNotificationDescriptor>[
  pluginsChangedNotification,
];
