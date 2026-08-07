import 'package:coder_daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Builds the agent-definition feature's complete v4 RPC surface.
List<RpcBindingDescriptor> agentRpcBindings({
  required AgentDefinitionService definitions,
  required WorktreeRepository worktrees,
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
        message: 'Agent file changed outside Coder.',
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
  RpcBinding(agentsListToolsProcedure, (request, _) async {
    final worktree = request.worktreeId == null
        ? null
        : await worktrees.getById(request.worktreeId!);
    return AgentToolCatalogResultDto(
      tools: definitions.toolCatalog(workspaceRoot: worktree?.path),
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
