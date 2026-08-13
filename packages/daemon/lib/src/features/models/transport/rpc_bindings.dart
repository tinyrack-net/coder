import 'package:daemon/src/features/models/infrastructure/model_settings_service.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Builds the daemon model-settings RPC surface.
List<RpcBindingDescriptor> modelRpcBindings(
  DaemonModelSettingsService models,
) => <RpcBindingDescriptor>[
  RpcBinding(modelsGetSettingsProcedure, (_, _) => models.getSettings()),
  RpcBinding(modelsSetDefaultModelProcedure, (request, _) async {
    try {
      return await models.setDefaultModel(request.model);
    } on ModelSettingsFailure catch (error) {
      throw RpcFailureException(code: error.code, message: error.message);
    }
  }),
];
