import 'package:coder_protocol/src/common/rpc_values.dart';
import 'package:coder_protocol/src/models.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';
import 'package:coder_protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final providersCatalogProcedure =
    RpcProcedure<EmptyParamsDto, ProviderCatalogResultDto>(
      name: 'providers.catalog',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderCatalogResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersListConnectionsProcedure =
    RpcProcedure<EmptyParamsDto, ProviderConnectionsResultDto>(
      name: 'providers.listConnections',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionsResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Reads subscription quota for all configured provider connections.
final providersListUsageProcedure =
    RpcProcedure<EmptyParamsDto, ProviderUsageResultDto>(
      name: 'providers.listUsage',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderUsageResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersConnectApiKeyProcedure =
    RpcProcedure<ProviderConnectApiKeyParamsDto, ProviderConnectionResultDto>(
      name: 'providers.connectApiKey',
      decodeParams: ProviderConnectApiKeyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersConnectNoneProcedure =
    RpcProcedure<ProviderConnectNoneParamsDto, ProviderConnectionResultDto>(
      name: 'providers.connectNone',
      decodeParams: ProviderConnectNoneParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersStartAuthProcedure =
    RpcProcedure<ProviderAuthStartParamsDto, ProviderAuthAttemptResultDto>(
      name: 'providers.startAuth',
      decodeParams: ProviderAuthStartParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderAuthAttemptResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersGetAuthProcedure =
    RpcProcedure<ProviderAuthAttemptParamsDto, ProviderAuthAttemptResultDto>(
      name: 'providers.getAuth',
      decodeParams: ProviderAuthAttemptParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderAuthAttemptResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersCancelAuthProcedure =
    RpcProcedure<ProviderAuthAttemptParamsDto, EmptyResultDto>(
      name: 'providers.cancelAuth',
      decodeParams: ProviderAuthAttemptParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersDisconnectProcedure =
    RpcProcedure<ProviderConnectionIdParamsDto, EmptyResultDto>(
      name: 'providers.disconnect',
      decodeParams: ProviderConnectionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Changes the globally unique model prefix of one connection.
final providersUpdateModelPrefixProcedure =
    RpcProcedure<ProviderPrefixUpdateParamsDto, ProviderConnectionResultDto>(
      name: 'providers.updateModelPrefix',
      decodeParams: ProviderPrefixUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersRefreshCatalogProcedure =
    RpcProcedure<EmptyParamsDto, ProviderCatalogResultDto>(
      name: 'providers.refreshCatalog',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderCatalogResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersListModelsProcedure =
    RpcProcedure<ProviderConnectionIdParamsDto, ProviderModelsResultDto>(
      name: 'providers.listModels',
      decodeParams: ProviderConnectionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderModelsResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersGetDefaultModelProcedure =
    RpcProcedure<EmptyParamsDto, DefaultModelDto>(
      name: 'providers.getDefaultModel',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: DefaultModelDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersSetDefaultModelProcedure =
    RpcProcedure<DefaultModelDto, EmptyResultDto>(
      name: 'providers.setDefaultModel',
      decodeParams: DefaultModelDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersCreateCustomProcedure =
    RpcProcedure<ProviderCustomCreateParamsDto, ProviderConnectionResultDto>(
      name: 'providers.createCustom',
      decodeParams: ProviderCustomCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersUpdateCustomProcedure =
    RpcProcedure<ProviderCustomUpdateParamsDto, ProviderConnectionResultDto>(
      name: 'providers.updateCustom',
      decodeParams: ProviderCustomUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProviderConnectionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersDeleteCustomProcedure =
    RpcProcedure<ProviderConnectionIdParamsDto, EmptyResultDto>(
      name: 'providers.deleteCustom',
      decodeParams: ProviderConnectionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final providersAuthUpdatedNotification =
    RpcNotification<ProviderAuthAttemptDto>(
      name: 'providers.authUpdated',
      decode: ProviderAuthAttemptDto.fromJson,
      encode: (value) => value.toJson(),
    );

/// Background provider-catalog refresh result.
final providersCatalogUpdatedNotification = RpcNotification<ProviderCatalogDto>(
  name: 'providers.catalogUpdated',
  decode: ProviderCatalogDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final providersProcedures = <RpcProcedureDescriptor>[
  providersCatalogProcedure,
  providersListConnectionsProcedure,
  providersListUsageProcedure,
  providersConnectApiKeyProcedure,
  providersConnectNoneProcedure,
  providersStartAuthProcedure,
  providersGetAuthProcedure,
  providersCancelAuthProcedure,
  providersDisconnectProcedure,
  providersUpdateModelPrefixProcedure,
  providersRefreshCatalogProcedure,
  providersListModelsProcedure,
  providersGetDefaultModelProcedure,
  providersSetDefaultModelProcedure,
  providersCreateCustomProcedure,
  providersUpdateCustomProcedure,
  providersDeleteCustomProcedure,
];

/// Feature-owned descriptor catalog.
final providersNotifications = <RpcNotificationDescriptor>[
  providersAuthUpdatedNotification,
  providersCatalogUpdatedNotification,
];
