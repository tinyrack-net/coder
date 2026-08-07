import 'package:coder_protocol/src/common/rpc_values.dart';
import 'package:coder_protocol/src/models.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';
import 'package:coder_protocol/src/rpc_models.dart';

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

/// Feature-owned descriptor catalog.
final sessionsProcedures = <RpcProcedureDescriptor>[
  sessionsListProcedure,
  sessionsListSubagentsProcedure,
  sessionsCreateProcedure,
  sessionsUpdateSettingsProcedure,
  sessionsStartTurnProcedure,
  sessionsCancelTurnProcedure,
  sessionsCompactProcedure,
  sessionsResolveApprovalProcedure,
  sessionsAnswerQuestionProcedure,
  sessionsNotePendingInputProcedure,
  sessionsSubscribeTimelineProcedure,
];

/// Feature-owned descriptor catalog.
final sessionsNotifications = <RpcNotificationDescriptor>[
  sessionsTimelineEventNotification,
  sessionsUpdatedNotification,
  sessionsApprovalRequestedNotification,
  sessionsQuestionRequestedNotification,
];
