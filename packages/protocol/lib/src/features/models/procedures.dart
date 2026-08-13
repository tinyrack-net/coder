import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Reads daemon-owned model settings.
final modelsGetSettingsProcedure =
    RpcProcedure<EmptyParamsDto, DaemonModelSettingsDto>(
      name: 'models.getSettings',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: DaemonModelSettingsDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Replaces the daemon default with one concrete runnable model.
final modelsSetDefaultModelProcedure =
    RpcProcedure<SetDaemonDefaultModelParamsDto, DaemonModelSettingsDto>(
      name: 'models.setDefaultModel',
      decodeParams: SetDaemonDefaultModelParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: DaemonModelSettingsDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Feature-owned descriptor catalog.
final modelsProcedures = <RpcProcedureDescriptor>[
  modelsGetSettingsProcedure,
  modelsSetDefaultModelProcedure,
];
