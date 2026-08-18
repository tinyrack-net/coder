import 'package:protocol/src/models.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v5 transport descriptor.
final systemHelloProcedure = RpcProcedure<HelloParamsDto, ServerInfoDto>(
  name: 'system.hello',
  decodeParams: HelloParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: ServerInfoDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final systemProcedures = <RpcProcedureDescriptor>[systemHelloProcedure];
