import 'package:agent/agent.dart';
import 'package:daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:daemon/src/features/models/infrastructure/model_settings_service.dart';
import 'package:daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:daemon/src/features/sessions/infrastructure/agent_service.dart';
import 'package:daemon/src/features/sessions/infrastructure/goal_service.dart';
import 'package:daemon/src/features/sessions/infrastructure/session_interactions.dart';
import 'package:daemon/src/features/sessions/infrastructure/session_settings.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Builds the session feature's complete v4 RPC surface.
List<RpcBindingDescriptor> sessionRpcBindings({
  required SessionRepository sessions,
  required TimelineRepository timeline,
  required SessionTurnCoordinator turns,
  required SessionSettingsPort settings,
  required SessionInteractionPort interactions,
  required AgentDefinitionService agentDefinitions,
  required ProviderModelResolver models,
  required DaemonModelSettingsService modelSettings,
  required Clock clock,
  required SessionGoalService goals,
}) => <RpcBindingDescriptor>[
  RpcBinding(sessionsListProcedure, (request, _) async {
    return SessionListResultDto(
      sessions: await sessions.list(worktreeId: request.worktreeId),
    );
  }),
  RpcBinding(sessionsListSubagentsProcedure, (request, _) async {
    final session = await sessions.getById(request.sessionId);
    if (session == null) throw const FormatException('Session not found.');
    return SessionListResultDto(
      sessions: await sessions.listByRoot(session.rootSessionId ?? session.id),
    );
  }),
  RpcBinding(sessionsCreateProcedure, (request, _) async {
    try {
      final definition = await agentDefinitions.get(request.agentDefinitionId);
      if (definition.mode != AgentMode.primary ||
          definition.isArchived ||
          definition.isStale) {
        throw RpcFailureException(
          code: RpcErrorCodes.agentDefinitionUnusable,
          message:
              'New sessions require an active primary agent definition, and '
              '"${definition.name}" is not one.',
          details: <String, dynamic>{
            'agentDefinitionId': definition.id,
          },
        );
      }
      final ModelSelectionDto selected;
      final Map<String, ModelControlValueDto> controls;
      if (request.model case final chatModel?) {
        await modelSettings.requireRunnable(chatModel);
        selected = chatModel;
        controls = request.modelControls;
      } else if (definition.model case final agentModel?) {
        await modelSettings.requireRunnable(agentModel);
        selected = agentModel;
        controls = definition.modelControls;
      } else {
        selected = await modelSettings.requireDefaultModel();
        controls = const <String, ModelControlValueDto>{};
      }
      await models.validateQualifiedModelControls(
        selected.qualifiedModelId,
        controls,
      );
      final now = clock.nowUtc();
      return SessionResultDto(
        session: await sessions.create(
          SessionDto(
            id: request.id,
            worktreeId: request.worktreeId,
            title: request.title,
            agentDefinitionId: definition.id,
            origin: SessionOrigin.manual,
            status: SessionStatus.idle,
            mode: request.mode,
            model: selected,
            modelControls: controls,
            permissionMode: request.permissionMode,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    } on ProviderConnectionFailure catch (error) {
      throw RpcFailureException(code: error.code, message: error.message);
    } on ModelSettingsFailure catch (error) {
      throw RpcFailureException(code: error.code, message: error.message);
    } on AgentDefinitionLookupFailure catch (error) {
      throw RpcFailureException(
        code: error.isMissing
            ? RpcErrorCodes.agentDefinitionNotFound
            : RpcErrorCodes.agentDefinitionUnusable,
        message: error.message,
        details: <String, dynamic>{'agentDefinitionId': error.id},
      );
    }
  }),
  RpcBinding(sessionsUpdateSettingsProcedure, (request, _) async {
    try {
      final session = await settings.updateSettings(
        request.sessionId,
        request.patch,
      );
      await goals.reconsider(request.sessionId);
      return SessionResultDto(session: session);
    } on SessionTurnActiveFailure catch (error) {
      throw RpcFailureException(
        code: RpcErrorCodes.sessionTurnActive,
        message: error.message,
        details: <String, dynamic>{
          'sessionId': error.sessionId,
          'setting': error.setting,
        },
      );
    } on ProviderConnectionFailure catch (error) {
      throw RpcFailureException(code: error.code, message: error.message);
    }
  }),
  RpcBinding(sessionsGetGoalProcedure, (request, _) async {
    return GoalGetResultDto(goal: await goals.get(request.sessionId));
  }),
  RpcBinding(sessionsReplaceGoalProcedure, (request, _) async {
    return GoalResultDto(
      goal: await goals.replace(
        sessionId: request.sessionId,
        objective: request.objective,
        tokenBudget: request.tokenBudget,
      ),
    );
  }),
  RpcBinding(sessionsUpdateGoalProcedure, (request, _) async {
    return GoalResultDto(
      goal: await goals.update(request.sessionId, request.update),
    );
  }),
  RpcBinding(sessionsClearGoalProcedure, (request, _) async {
    return GoalClearResultDto(cleared: await goals.clear(request.sessionId));
  }),
  RpcBinding(sessionsStartTurnProcedure, (request, _) async {
    try {
      return TurnStartResultDto(
        created: await turns.startTurn(
          sessionId: request.sessionId,
          turnId: request.turnId,
          prompt: request.prompt,
          attachmentIds: request.attachmentIds,
        ),
      );
    } on ProviderConnectionFailure catch (error) {
      throw RpcFailureException(code: error.code, message: error.message);
    } on AgentDefinitionLookupFailure catch (error) {
      throw RpcFailureException(
        code: error.isMissing
            ? RpcErrorCodes.agentDefinitionNotFound
            : RpcErrorCodes.agentDefinitionUnusable,
        message: error.message,
        details: <String, dynamic>{'agentDefinitionId': error.id},
      );
    }
  }),
  RpcBinding(sessionsCancelTurnProcedure, (request, _) async {
    await turns.cancelTurn(request.sessionId);
    return const EmptyResultDto();
  }),
  RpcBinding(sessionsCompactProcedure, (request, _) async {
    await turns.compactSession(request.sessionId);
    return const EmptyResultDto();
  }),
  RpcBinding(sessionsResolveApprovalProcedure, (request, _) async {
    return ApprovalResultDto(
      approval: await interactions.resolveApproval(
        request.approvalId,
        approved: request.approved,
      ),
    );
  }),
  RpcBinding(sessionsNotePendingInputProcedure, (request, _) async {
    interactions.notePendingInput(request.sessionId);
    return const EmptyResultDto();
  }),
  RpcBinding(sessionsAnswerQuestionProcedure, (request, _) async {
    return UserQuestionResultDto(
      request: await interactions.answerUserQuestion(
        request.requestId,
        request.answers,
      ),
    );
  }),
  RpcBinding(sessionsSubscribeTimelineProcedure, (request, context) async {
    context.timelineSubscriptions.add(request.sessionId);
    final tailLimit = request.tailLimit;
    return TimelineResultDto(
      events: tailLimit == null
          ? await timeline.after(request.sessionId, request.afterSequence)
          : await timeline.tail(
              request.sessionId,
              request.afterSequence,
              limit: tailLimit,
            ),
    );
  }),
  // Deliberately does not touch `context.timelineSubscriptions`: that set is
  // also the live delivery cursor, and rewinding it to read history would
  // drop the events arriving during the round trip.
  RpcBinding(sessionsTimelineHistoryProcedure, (request, _) async {
    return TimelineResultDto(
      events: await timeline.before(
        request.sessionId,
        request.beforeSequence,
        limit: request.limit,
      ),
    );
  }),
];
