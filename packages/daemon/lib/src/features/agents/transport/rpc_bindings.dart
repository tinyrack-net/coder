import 'package:daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Builds the agent-definition feature's complete v5 RPC surface.
List<RpcBindingDescriptor> agentRpcBindings({
  required AgentDefinitionService definitions,
  required SettingsRepository settings,
}) => <RpcBindingDescriptor>[
  RpcBinding(agentsListProcedure, (_, _) async {
    return AgentDefinitionListResultDto(definitions: await definitions.list());
  }),
  RpcBinding(agentsGetProcedure, (request, _) async {
    return AgentDefinitionResultDto(
      definition: await definitions.get(request.id),
    );
  }),
  RpcBinding(agentsCreateProcedure, (request, _) async {
    return AgentDefinitionResultDto(
      definition: await definitions.create(request.id, request.definition),
    );
  }),
  RpcBinding(agentsUpdateProcedure, (request, _) async {
    try {
      return AgentDefinitionResultDto(
        definition: await definitions.update(
          request.definition,
          expectedContentHash: request.expectedContentHash,
          force: request.force,
        ),
      );
    } on AgentFileConflict catch (error) {
      throw RpcFailureException(
        code: 'agent_file_conflict',
        message: 'Agent file changed outside Tinest.',
        details: <String, dynamic>{
          'currentContentHash': error.currentContentHash,
        },
      );
    }
  }),
  RpcBinding(agentsArchiveProcedure, (request, _) async {
    await definitions.archive(request.id);
    return const EmptyResultDto();
  }),
  RpcBinding(agentsResetProcedure, (request, _) async {
    return AgentDefinitionResultDto(
      definition: await definitions.reset(request.id),
    );
  }),
  RpcBinding(agentsValidateProcedure, (request, _) async {
    return AgentDefinitionResultDto(
      definition: await definitions.validate(request.id, request.markdown),
    );
  }),
  RpcBinding(agentsListToolsProcedure, (_, _) async {
    return AgentToolCatalogResultDto(
      tools: await definitions.toolCatalog(),
    );
  }),
  RpcBinding(agentsGetDefaultPermissionModeProcedure, (_, _) async {
    final stored = await settings.getValue('permission.defaultMode');
    return PermissionSettingsDto(
      defaultMode: stored == null || stored.isEmpty
          ? PermissionMode.ask
          : PermissionMode.values.byName(stored),
    );
  }),
  RpcBinding(agentsSetDefaultPermissionModeProcedure, (request, _) async {
    await settings.setValue('permission.defaultMode', request.defaultMode.name);
    return request;
  }),
];
