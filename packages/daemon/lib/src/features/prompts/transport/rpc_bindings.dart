import 'package:daemon/src/features/prompts/infrastructure/commands.dart';
import 'package:daemon/src/features/prompts/infrastructure/skills.dart';
import 'package:daemon/src/features/workspaces/infrastructure/workspace_service.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Builds the prompt catalog feature's complete v4 RPC surface.
List<RpcBindingDescriptor> promptRpcBindings({
  required SkillCatalogService skills,
  required CommandService commands,
  required WorkspaceCatalogPort workspaces,
}) {
  Future<SkillScope> skillScope(String? workspaceId) async =>
      workspaceId == null
      ? SkillScope.global
      : SkillScope(
          workspaceId: workspaceId,
          projectRoot: await workspaces.workspaceRoot(workspaceId),
        );
  Future<CommandScope> commandScope(String? workspaceId) async =>
      workspaceId == null
      ? CommandScope.global
      : CommandScope(
          workspaceId: workspaceId,
          projectRoot: await workspaces.workspaceRoot(workspaceId),
        );

  return <RpcBindingDescriptor>[
    RpcBinding(promptsListCommandsProcedure, (request, _) async {
      return CommandListResultDto(
        commands: await commands.list(
          scope: await commandScope(request.workspaceId),
        ),
      );
    }),
    RpcBinding(promptsListSkillsProcedure, (request, _) async {
      return SkillListResultDto(
        skills: await skills.list(scope: await skillScope(request.workspaceId)),
      );
    }),
    RpcBinding(promptsGetSkillProcedure, (request, _) async {
      return SkillResultDto(
        skill: await skills.get(
          request.id,
          scope: await skillScope(request.workspaceId),
        ),
      );
    }),
    RpcBinding(promptsCreateSkillProcedure, (request, _) async {
      return SkillResultDto(
        skill: await skills.create(
          id: request.id,
          source: request.source,
          name: request.name,
          description: request.description,
          body: request.body,
          scope: await skillScope(request.workspaceId),
        ),
      );
    }),
    RpcBinding(promptsUpdateSkillProcedure, (request, _) async {
      try {
        return SkillResultDto(
          skill: await skills.update(
            request.skill,
            expectedContentHash: request.expectedContentHash,
            force: request.force,
            scope: await skillScope(request.workspaceId),
          ),
        );
      } on SkillFileConflict catch (error) {
        throw RpcFailureException(
          code: 'skill_file_conflict',
          message: 'Skill file changed outside Coder.',
          details: <String, dynamic>{
            'currentContentHash': error.currentContentHash,
          },
        );
      }
    }),
    RpcBinding(promptsDeleteSkillProcedure, (request, _) async {
      await skills.delete(
        request.id,
        scope: await skillScope(request.workspaceId),
      );
      return const EmptyResultDto();
    }),
    RpcBinding(promptsSetSkillEnabledProcedure, (request, _) async {
      return SkillResultDto(
        skill: await skills.setEnabled(
          request.id,
          enabled: request.enabled,
          scope: await skillScope(request.workspaceId),
        ),
      );
    }),
  ];
}
