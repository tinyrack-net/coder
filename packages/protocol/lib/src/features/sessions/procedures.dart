import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/models.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final sessionsListProcedure =
    RpcProcedure<SessionListParamsDto, SessionListResultDto>(
      name: 'sessions.list',
      decodeParams: SessionListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SessionListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsListSubagentsProcedure =
    RpcProcedure<SessionSubagentListParamsDto, SessionListResultDto>(
      name: 'sessions.listSubagents',
      decodeParams: SessionSubagentListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SessionListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsCreateProcedure =
    RpcProcedure<SessionCreateParamsDto, SessionResultDto>(
      name: 'sessions.create',
      decodeParams: SessionCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SessionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsUpdateSettingsProcedure =
    RpcProcedure<SessionSettingsUpdateParamsDto, SessionResultDto>(
      name: 'sessions.updateSettings',
      decodeParams: SessionSettingsUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SessionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Reads the goal attached to one session.
final sessionsGetGoalProcedure =
    RpcProcedure<SessionIdParamsDto, GoalGetResultDto>(
      name: 'sessions.getGoal',
      decodeParams: SessionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: GoalGetResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Replaces any existing goal with a fresh active goal.
final sessionsReplaceGoalProcedure =
    RpcProcedure<GoalReplaceParamsDto, GoalResultDto>(
      name: 'sessions.replaceGoal',
      decodeParams: GoalReplaceParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: GoalResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Atomically updates an existing goal.
final sessionsUpdateGoalProcedure =
    RpcProcedure<GoalUpdateParamsDto, GoalResultDto>(
      name: 'sessions.updateGoal',
      decodeParams: GoalUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: GoalResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Clears the goal attached to one session.
final sessionsClearGoalProcedure =
    RpcProcedure<SessionIdParamsDto, GoalClearResultDto>(
      name: 'sessions.clearGoal',
      decodeParams: SessionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: GoalClearResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsStartTurnProcedure =
    RpcProcedure<TurnStartParamsDto, TurnStartResultDto>(
      name: 'sessions.startTurn',
      decodeParams: TurnStartParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TurnStartResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsCancelTurnProcedure =
    RpcProcedure<SessionIdParamsDto, EmptyResultDto>(
      name: 'sessions.cancelTurn',
      decodeParams: SessionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsCompactProcedure =
    RpcProcedure<SessionIdParamsDto, EmptyResultDto>(
      name: 'sessions.compact',
      decodeParams: SessionIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsResolveApprovalProcedure =
    RpcProcedure<ApprovalResolveParamsDto, ApprovalResultDto>(
      name: 'sessions.resolveApproval',
      decodeParams: ApprovalResolveParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ApprovalResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsAnswerQuestionProcedure =
    RpcProcedure<UserQuestionAnswerParamsDto, UserQuestionResultDto>(
      name: 'sessions.answerQuestion',
      decodeParams: UserQuestionAnswerParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: UserQuestionResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsNotePendingInputProcedure =
    RpcProcedure<SessionPendingInputParamsDto, EmptyResultDto>(
      name: 'sessions.notePendingInput',
      decodeParams: SessionPendingInputParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsSubscribeTimelineProcedure =
    RpcProcedure<TimelineSubscribeParamsDto, TimelineResultDto>(
      name: 'sessions.subscribeTimeline',
      decodeParams: TimelineSubscribeParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TimelineResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
///
/// Read-only: unlike `sessions.subscribeTimeline` this never moves the live
/// delivery cursor, so paging backwards through history cannot swallow events
/// arriving in the same moment.
final sessionsTimelineHistoryProcedure =
    RpcProcedure<TimelineHistoryParamsDto, TimelineResultDto>(
      name: 'sessions.timelineHistory',
      decodeParams: TimelineHistoryParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: TimelineResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsTimelineEventNotification = RpcNotification<TimelineEventDto>(
  name: 'sessions.timelineEvent',
  decode: TimelineEventDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final sessionsUpdatedNotification = RpcNotification<SessionDto>(
  name: 'sessions.updated',
  decode: SessionDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final sessionsApprovalRequestedNotification =
    RpcNotification<ApprovalRequestDto>(
      name: 'sessions.approvalRequested',
      decode: ApprovalRequestDto.fromJson,
      encode: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final sessionsQuestionRequestedNotification =
    RpcNotification<UserQuestionRequestDto>(
      name: 'sessions.questionRequested',
      decode: UserQuestionRequestDto.fromJson,
      encode: (value) => value.toJson(),
    );

/// Emitted whenever a session goal changes.
final sessionsGoalUpdatedNotification = RpcNotification<GoalDto>(
  name: 'sessions.goalUpdated',
  decode: GoalDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Emitted whenever a session goal is cleared.
final sessionsGoalClearedNotification = RpcNotification<GoalClearedDto>(
  name: 'sessions.goalCleared',
  decode: GoalClearedDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final sessionsProcedures = <RpcProcedureDescriptor>[
  sessionsListProcedure,
  sessionsListSubagentsProcedure,
  sessionsCreateProcedure,
  sessionsUpdateSettingsProcedure,
  sessionsGetGoalProcedure,
  sessionsReplaceGoalProcedure,
  sessionsUpdateGoalProcedure,
  sessionsClearGoalProcedure,
  sessionsStartTurnProcedure,
  sessionsCancelTurnProcedure,
  sessionsCompactProcedure,
  sessionsResolveApprovalProcedure,
  sessionsAnswerQuestionProcedure,
  sessionsNotePendingInputProcedure,
  sessionsSubscribeTimelineProcedure,
  sessionsTimelineHistoryProcedure,
];

/// Feature-owned descriptor catalog.
final sessionsNotifications = <RpcNotificationDescriptor>[
  sessionsTimelineEventNotification,
  sessionsUpdatedNotification,
  sessionsApprovalRequestedNotification,
  sessionsQuestionRequestedNotification,
  sessionsGoalUpdatedNotification,
  sessionsGoalClearedNotification,
];
