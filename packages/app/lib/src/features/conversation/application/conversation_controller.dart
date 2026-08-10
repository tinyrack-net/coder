import 'dart:async';

import 'package:app/src/app/composition/app_providers.dart';
import 'package:app/src/features/conversation/application/attachment_ports.dart';
import 'package:app/src/features/conversation/application/composer_controller.dart';
import 'package:app/src/features/hosts/application/host_controller.dart';
import 'package:client/client.dart';
import 'package:protocol/protocol.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_controller.g.dart';

/// One prompt typed while a turn was still running.
///
/// The daemon runs a single turn per session, so a follow-up waits here until
/// the active turn settles instead of being rejected or silently dropped.
final class QueuedTurn {
  /// Creates a [QueuedTurn].
  const QueuedTurn({
    required this.id,
    required this.text,
    required this.attachments,
    this.attempts = 0,
    this.error,
  });

  /// Identity used to edit or promote one entry.
  final String id;

  /// Trimmed prompt text.
  final String text;

  /// Files that go up with the prompt.
  final List<PendingAttachment> attachments;

  /// Releases already charged against this prompt's retry budget.
  ///
  /// Charged when a retry is armed rather than when a send fails, so every
  /// path that can arm one shares a single budget and none can chain past it.
  final int attempts;

  /// Why the last release failed, once the budget is spent.
  ///
  /// Null while the prompt is merely waiting its turn, which is the state a
  /// reader has to be able to tell apart from one that has stopped trying.
  final String? error;

  /// Returns a copy carrying a new retry budget or failure reason.
  QueuedTurn copyWith({int? attempts, String? error}) => QueuedTurn(
    id: id,
    text: text,
    attachments: attachments,
    attempts: attempts ?? this.attempts,
    error: error ?? this.error,
  );
}

/// ConversationState defines a public contract.
final class ConversationState {
  /// Creates a [ConversationState].
  const ConversationState({
    this.timeline = const <TimelineEventDto>[],
    this.approvals = const <String, ApprovalRequestDto>{},
    this.queued = const <QueuedTurn>[],
    this.questions = const <String, UserQuestionRequestDto>{},
    this.goal,
  });

  /// The timeline public API member.
  final List<TimelineEventDto> timeline;

  /// The approvals public API member.
  final Map<String, ApprovalRequestDto> approvals;

  /// Prompts waiting for the active turn to finish, oldest first.
  final List<QueuedTurn> queued;

  /// Questions the agent is blocked on, keyed by request id.
  final Map<String, UserQuestionRequestDto> questions;

  /// Persistent execution goal for this root session.
  final GoalDto? goal;

  /// The copyWith public API member.
  ConversationState copyWith({
    List<TimelineEventDto>? timeline,
    Map<String, ApprovalRequestDto>? approvals,
    List<QueuedTurn>? queued,
    Map<String, UserQuestionRequestDto>? questions,
    GoalDto? goal,
    bool clearGoal = false,
  }) => ConversationState(
    timeline: timeline ?? this.timeline,
    approvals: approvals ?? this.approvals,
    queued: queued ?? this.queued,
    questions: questions ?? this.questions,
    goal: clearGoal ? null : goal ?? this.goal,
  );
}

@riverpod
/// ConversationController defines a public contract.
class ConversationController extends _$ConversationController {
  StreamSubscription<TimelineEventDto>? _timelineEvents;
  StreamSubscription<ApprovalRequestDto>? _approvalEvents;
  StreamSubscription<SessionDto>? _sessionEvents;
  StreamSubscription<UserQuestionRequestDto>? _questionEvents;
  StreamSubscription<GoalDto>? _goalEvents;
  StreamSubscription<GoalClearedDto>? _goalClearEvents;
  late String? _sessionId;
  // Both the idle session event and an explicit promotion can ask for a drain,
  // so one send is in flight at a time.
  bool _draining = false;
  // A drain asked for while one runs, held rather than dropped: the request
  // refused here is often the only signal that prompt was ever going to get.
  bool _drainAgain = false;
  Timer? _drainRetry;

  @override
  Future<ConversationState> build(String hostId, String? sessionId) async {
    _sessionId = sessionId;
    final api = await watchConnectedHostApi(ref, hostId);
    if (api == null || sessionId == null) {
      return const ConversationState();
    }
    final timeline = await api.sessions.subscribeTimeline(sessionId);
    _timelineEvents = api.sessions.timelineEvents.listen(_handleTimeline);
    _approvalEvents = api.sessions.approvalRequests.listen(_handleApproval);
    _sessionEvents = api.sessions.sessionUpdates.listen(_handleSession);
    _questionEvents = api.sessions.questionRequests.listen(_handleQuestion);
    _goalEvents = api.sessions.goalUpdates.listen(_handleGoal);
    _goalClearEvents = api.sessions.goalClears.listen(_handleGoalCleared);
    // Install notification listeners before the snapshot read so an update
    // cannot land in the reconnect gap between those two operations.
    final goal = await api.sessions.getGoal(sessionId);
    ref
      ..onDispose(() => unawaited(_timelineEvents?.cancel()))
      ..onDispose(() => unawaited(_approvalEvents?.cancel()))
      ..onDispose(() => unawaited(_sessionEvents?.cancel()))
      ..onDispose(() => unawaited(_questionEvents?.cancel()))
      ..onDispose(() => unawaited(_goalEvents?.cancel()))
      ..onDispose(() => unawaited(_goalClearEvents?.cancel()))
      ..onDispose(() => _drainRetry?.cancel());
    return ConversationState(
      timeline: timeline,
      approvals: _pendingApprovals(timeline),
      questions: _pendingQuestions(timeline),
      goal: goal,
    );
  }

  /// Starts a fresh goal generation.
  Future<void> replaceGoal(String objective, {int? tokenBudget}) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final api = await requireHostApi(ref, hostId);
    final goal = await api.sessions.replaceGoal(
      sessionId: sessionId,
      objective: objective,
      tokenBudget: tokenBudget,
    );
    _handleGoal(goal);
  }

  /// Changes objective, status, or budget on the current generation.
  Future<void> updateGoal(GoalUpdateDto update) async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final api = await requireHostApi(ref, hostId);
    _handleGoal(await api.sessions.updateGoal(sessionId, update));
  }

  /// Clears the current goal.
  Future<void> clearGoal() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final api = await requireHostApi(ref, hostId);
    if (await api.sessions.clearGoal(sessionId)) {
      _handleGoalCleared(GoalClearedDto(sessionId: sessionId, goalId: ''));
    }
  }

  /// The startTurn public API member.
  Future<void> startTurn(
    String prompt, {
    List<PendingAttachment> attachments = const <PendingAttachment>[],
    bool queueWhenBusy = true,
  }) async {
    final sessionId = _sessionId;
    if (sessionId == null || (prompt.trim().isEmpty && attachments.isEmpty)) {
      return;
    }
    final api = await requireHostApi(ref, hostId);
    final uploaded = <AttachmentDto>[];
    for (final attachment in attachments) {
      uploaded.add(
        await api.attachments.uploadAttachment(
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          byteSize: attachment.byteSize,
          bytes: attachment.openRead(),
        ),
      );
    }
    try {
      await api.sessions.startTurn(
        sessionId: sessionId,
        turnId: ref.read(appIdGeneratorProvider).generate(),
        prompt: prompt.trim(),
        attachmentIds: uploaded.map((item) => item.id).toList(growable: false),
      );
    } on Exception {
      // The composer sends or queues from a rendered flag that trails the
      // daemon by one event, so it can send into a turn that is still running.
      // The daemon is the authority: when it says one is, hold the prompt the
      // way the composer would have, rather than handing back an error that
      // reads as "not sent" and drops it.
      if (!queueWhenBusy || !await _hasRunningTurn(api, sessionId)) rethrow;
      enqueueTurn(prompt, attachments: attachments);
    }
  }

  Future<bool> _hasRunningTurn(CoderApi api, String sessionId) async {
    try {
      final session = (await api.sessions.listSessions())
          .where((session) => session.id == sessionId)
          .firstOrNull;
      return session != null &&
          session.status != SessionStatus.idle &&
          session.status != SessionStatus.failed;
    } on Exception {
      return false;
    }
  }

  /// The cancelTurn public API member.
  Future<void> cancelTurn() async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      final api = await requireHostApi(ref, hostId);
      await api.sessions.cancelTurn(sessionId);
    }
  }

  /// Holds a prompt until the active turn settles.
  void enqueueTurn(
    String prompt, {
    List<PendingAttachment> attachments = const <PendingAttachment>[],
  }) {
    final text = prompt.trim();
    final current = state.asData?.value;
    if (current == null || (text.isEmpty && attachments.isEmpty)) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        queued: <QueuedTurn>[
          ...current.queued,
          QueuedTurn(
            id: ref.read(appIdGeneratorProvider).generate(),
            text: text,
            attachments: List<PendingAttachment>.unmodifiable(attachments),
          ),
        ],
      ),
    );
    // Best-effort: it only shortens a sleeping agent's wait, so a failure
    // costs a longer wait and nothing else.
    unawaited(_notePendingInput());
  }

  Future<void> _notePendingInput() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final CoderApi api;
    try {
      api = await requireHostApi(ref, hostId);
    } on Object {
      // Without a connection there is no queue to release: reconnecting
      // rebuilds this controller from scratch.
      return;
    }
    try {
      await api.sessions.notePendingInput(sessionId);
    } on Object {
      // Not state, so a lost notice is not worth surfacing. The settled check
      // below is liveness rather than a notice, so it still has to run.
    }
    try {
      await _drainIfAlreadySettled(api, sessionId);
    } on Object catch (error) {
      // For a prompt queued after the turn settled this check is the only
      // release it will ever get, so a failed check re-arms rather than
      // stranding the prompt. The reason travels with it: every way of
      // running out of budget has to end somewhere the reader can see.
      _scheduleDrainRetry(error: '$error');
    }
  }

  /// Arms one more release attempt, or stops and records why.
  ///
  /// The only place a retry timer is created. It charges the head's budget
  /// before arming, which is what makes the chain finite by construction.
  void _scheduleDrainRetry({required String error}) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    final head = current?.queued.firstOrNull;
    if (current == null || head == null) return;
    if (head.attempts >= conversationDrainMaxAttempts) {
      // Out of budget. The prompt stays, but it stops passing for one that is
      // simply waiting its turn, so the reader knows to send or edit it.
      if (head.error == null) {
        state = AsyncData<ConversationState>(
          current.copyWith(
            queued: <QueuedTurn>[
              head.copyWith(error: error),
              ...current.queued.skip(1),
            ],
          ),
        );
      }
      return;
    }
    state = AsyncData<ConversationState>(
      current.copyWith(
        queued: <QueuedTurn>[
          head.copyWith(attempts: head.attempts + 1),
          ...current.queued.skip(1),
        ],
      ),
    );
    _drainRetry?.cancel();
    _drainRetry = Timer(
      conversationDrainRetryDelay,
      () => unawaited(drainQueue()),
    );
  }

  /// Releases the queue when the turn it was waiting on has already finished.
  ///
  /// The composer chooses between sending and queueing from a rendered flag
  /// that trails the daemon by one event, so a prompt can land in the queue
  /// after the session settled. [drainQueue] otherwise runs only from a later
  /// session update, and no such update is coming, which strands the prompt.
  Future<void> _drainIfAlreadySettled(CoderApi api, String sessionId) async {
    if (state.asData?.value.queued.isEmpty ?? true) return;
    final session = (await api.sessions.listSessions())
        .where((session) => session.id == sessionId)
        .firstOrNull;
    if (session == null) return;
    if (session.status == SessionStatus.idle ||
        session.status == SessionStatus.failed) {
      await drainQueue();
    }
  }

  /// Removes one waiting prompt and returns it, so it can be edited again.
  QueuedTurn? takeQueuedTurn(String id) {
    final current = state.asData?.value;
    final item = current?.queued.where((entry) => entry.id == id).firstOrNull;
    if (current == null || item == null) return null;
    state = AsyncData<ConversationState>(
      current.copyWith(
        queued: current.queued
            .where((entry) => entry.id != id)
            .toList(growable: false),
      ),
    );
    return item;
  }

  /// Cancels the active turn and starts one waiting prompt immediately.
  Future<void> sendQueuedTurnNow(String id) async {
    final item = takeQueuedTurn(id);
    if (item == null) return;
    try {
      await cancelTurn();
      await startTurn(item.text, attachments: item.attachments);
    } on Exception {
      _restoreQueuedTurn(item);
      rethrow;
    }
  }

  /// Starts the oldest waiting prompt, if any.
  ///
  /// Exactly one prompt leaves the queue per call: each queued follow-up earns
  /// its own turn, and the next one waits for that turn to settle in turn.
  Future<void> drainQueue() async {
    if (_draining) {
      // Dropping the request drops the prompt when it was the last signal
      // coming, so the running drain picks it up on its way out.
      _drainAgain = true;
      return;
    }
    // Cleared on the way in: a request that arrives from here on is about this
    // run, and a stale flag would cost a pointless extra pass.
    _drainAgain = false;
    final current = state.asData?.value;
    final next = current?.queued.firstOrNull;
    if (current == null || next == null) return;
    _draining = true;
    state = AsyncData<ConversationState>(
      current.copyWith(queued: current.queued.sublist(1)),
    );
    try {
      // Already queued once: re-queueing here would only trade a restore for
      // a loop, so a busy daemon takes the same path as any other failure.
      await startTurn(
        next.text,
        attachments: next.attachments,
        queueWhenBusy: false,
      );
    } on Exception catch (error) {
      // The drain runs from a broadcast event with nobody to await it, so a
      // failed send puts the prompt back rather than disappearing. The event
      // that triggered this drain is often the last one coming, so putting it
      // back is only half the job: it has to be re-armed too.
      _restoreQueuedTurn(next);
      _scheduleDrainRetry(error: '$error');
    } finally {
      _draining = false;
    }
    // drainQueue clears the flag on entry, so this hands over rather than
    // racing: a request arriving during the next run is that run's to keep.
    if (_drainAgain) await drainQueue();
  }

  void _restoreQueuedTurn(QueuedTurn item) {
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(queued: <QueuedTurn>[item, ...current.queued]),
    );
  }

  /// The resolveApproval public API member.
  Future<void> resolveApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final api = await requireHostApi(ref, hostId);
    await api.sessions.resolveApproval(
      approvalId: approvalId,
      approved: approved,
    );
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        approvals: Map<String, ApprovalRequestDto>.of(current.approvals)
          ..remove(approvalId),
      ),
    );
  }

  /// Answers a pending agent question and lets its turn continue.
  Future<void> answerUserQuestion(
    String requestId,
    List<UserQuestionAnswerDto> answers,
  ) async {
    final api = await requireHostApi(ref, hostId);
    await api.sessions.answerUserQuestion(
      requestId: requestId,
      answers: answers,
    );
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        questions: Map<String, UserQuestionRequestDto>.of(current.questions)
          ..remove(requestId),
      ),
    );
  }

  ConversationState? get _currentEventState {
    if (!ref.mounted) return null;
    return state.asData?.value;
  }

  void _handleTimeline(TimelineEventDto event) {
    final current = _currentEventState;
    if (current == null) return;
    if (event.sessionId != _sessionId ||
        current.timeline.any((item) => item.sequence == event.sequence)) {
      return;
    }
    final approvals = Map<String, ApprovalRequestDto>.of(current.approvals);
    final approval = _approvalFromTimeline(event);
    if (approval != null) approvals[approval.id] = approval;
    if (event.type == 'approval.resolved') {
      approvals.remove(event.data['approvalId']);
    }
    final timeline = <TimelineEventDto>[...current.timeline, event];
    state = AsyncData<ConversationState>(
      current.copyWith(
        timeline: timeline,
        approvals: approvals,
        questions: _pendingQuestions(timeline),
      ),
    );
  }

  void _handleApproval(ApprovalRequestDto approval) {
    final current = _currentEventState;
    if (current == null || approval.sessionId != _sessionId) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        approvals: <String, ApprovalRequestDto>{
          ...current.approvals,
          approval.id: approval,
        },
      ),
    );
  }

  void _handleSession(SessionDto session) {
    final current = _currentEventState;
    if (current == null) return;
    if (session.id == _sessionId &&
        current.queued.isNotEmpty &&
        (session.status == SessionStatus.idle ||
            session.status == SessionStatus.failed)) {
      unawaited(drainQueue());
    }
  }

  void _handleQuestion(UserQuestionRequestDto request) {
    final current = _currentEventState;
    if (current == null || request.sessionId != _sessionId) return;
    state = AsyncData<ConversationState>(
      current.copyWith(
        questions: <String, UserQuestionRequestDto>{
          ...current.questions,
          request.id: request,
        },
      ),
    );
  }

  void _handleGoal(GoalDto goal) {
    final current = _currentEventState;
    if (current == null || goal.sessionId != _sessionId) return;
    state = AsyncData<ConversationState>(current.copyWith(goal: goal));
  }

  void _handleGoalCleared(GoalClearedDto cleared) {
    final current = _currentEventState;
    if (current == null || cleared.sessionId != _sessionId) return;
    state = AsyncData<ConversationState>(current.copyWith(clearGoal: true));
  }

  Map<String, ApprovalRequestDto> _pendingApprovals(
    List<TimelineEventDto> timeline,
  ) {
    final approvals = <String, ApprovalRequestDto>{};
    for (final event in timeline) {
      final approval = _approvalFromTimeline(event);
      if (approval != null && approval.status == ApprovalStatus.pending) {
        approvals[approval.id] = approval;
      }
      if (event.type == 'approval.resolved') {
        approvals.remove(event.data['approvalId']);
      }
    }
    return approvals;
  }

  /// Questions still awaiting an answer, derived from the timeline.
  ///
  /// A question whose turn already ended is dropped: the daemon cancels it on
  /// restart without writing an answer event, so leaving it would strand a card
  /// the user can never resolve.
  Map<String, UserQuestionRequestDto> _pendingQuestions(
    List<TimelineEventDto> timeline,
  ) {
    final questions = <String, UserQuestionRequestDto>{};
    final terminated = <String?>{
      for (final event in timeline)
        if (event.type == 'turn.completed' ||
            event.type == 'turn.failed' ||
            event.type == 'turn.cancelled')
          event.turnId,
    };
    for (final event in timeline) {
      final request = _questionFromTimeline(event);
      if (request != null && request.status == UserQuestionStatus.pending) {
        questions[request.id] = request;
      }
      if (event.type == 'userQuestion.answered') {
        questions.remove(event.data['requestId']);
      }
    }
    questions.removeWhere(
      (_, request) => terminated.contains(request.turnId),
    );
    return questions;
  }

  UserQuestionRequestDto? _questionFromTimeline(TimelineEventDto event) {
    if (event.type != 'userQuestion.requested') return null;
    final raw = event.data['request'];
    return raw is Map<dynamic, dynamic>
        ? UserQuestionRequestDto.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }

  ApprovalRequestDto? _approvalFromTimeline(TimelineEventDto event) {
    if (event.type != 'approval.requested') return null;
    final raw = event.data['approval'];
    return raw is Map<dynamic, dynamic>
        ? ApprovalRequestDto.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }
}
