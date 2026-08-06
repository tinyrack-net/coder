import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_clock.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/attachment_service.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_daemon/src/skills.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by DaemonEventSink.
typedef DaemonEventSink = void Function(WireEnvelope event);

/// Signature used by AgentToolsFactory.
typedef AgentToolsFactory =
    Iterable<AgentTool> Function(
      Iterable<String> ids,
      String workspaceRoot,
      String sessionId,
      String turnId,
    );

/// Resolves the pseudo-terminals one coder session owns.
typedef ExecHostFactory = ExecSessionHost Function(String sessionId);

/// SessionService defines a public contract.
class SessionService {
  /// Creates a [SessionService].
  SessionService({
    required this._sessions,
    required this._definitions,
    required this._worktrees,
    required this._timeline,
    required this._providers,
    required this._events,
    required this._safetyIdentifier,
    required this._clock,
    required this._ids,
    required this._toolsFactory,
    required this._skills,
    required this._attachments,
    required this._execHostFor,
  });

  final ExecHostFactory _execHostFor;
  final SessionRepository _sessions;
  final AgentDefinitionService _definitions;
  final WorktreeRepository _worktrees;
  final TimelineRepository _timeline;
  final ProviderService _providers;
  final DaemonEventSink _events;
  final String _safetyIdentifier;
  final Clock _clock;
  final IdGenerator _ids;
  final AgentToolsFactory _toolsFactory;
  final SkillService _skills;
  final AttachmentService _attachments;
  final Map<String, CancellationToken> _activeTurns =
      <String, CancellationToken>{};
  final Map<String, Completer<ApprovalDecision>> _pendingApprovals =
      <String, Completer<ApprovalDecision>>{};
  final Map<String, Completer<List<UserAnswer>>> _pendingQuestions =
      <String, Completer<List<UserAnswer>>>{};
  final Map<String, Completer<void>> _pendingInput =
      <String, Completer<void>>{};
  final Set<String> _notedInput = <String>{};
  final Map<String, Completer<AgentRunResult>> _turnCompletions =
      <String, Completer<AgentRunResult>>{};

  /// The startTurn public API member.
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
    bool trackCompletion = false,
  }) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    final definition = await _definitions.resolve(session.agentDefinitionId);
    final sessionModel = session.model;
    // A session override wins over the model of its agent definition.
    final resolvedModel = sessionModel == null
        ? await _providers.resolveAgentModel(definition.model)
        : await _providers.resolveExplicitModel(
            sessionModel.providerConnectionId,
            sessionModel.modelId,
          );
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError('Agent already has a running turn.');
    }
    final worktree = await _worktrees.getById(session.worktreeId);
    if (worktree == null || worktree.archivedAt != null) {
      throw StateError('Worktree not found: ${session.worktreeId}');
    }
    final created = await _sessions.createTurn(
      id: turnId,
      sessionId: sessionId,
      prompt: prompt,
      attachmentIds: attachmentIds,
    );
    if (!created) return false;

    final cancellation = CancellationToken();
    // Starting a turn consumes whatever the client had queued, so a stale
    // notice cannot shorten a later wait.
    _notedInput.remove(sessionId);
    _activeTurns[sessionId] = cancellation;
    if (trackCompletion) {
      _turnCompletions[turnId] = Completer<AgentRunResult>();
    }
    await _sessions.updateStatus(
      sessionId,
      SessionStatus.running,
      activeTurnId: turnId,
    );
    // Cached on the row so the context meter reads the same window the turn
    // runs against, without a catalog lookup on every session read.
    _emitSession(
      await _sessions.recordContextWindow(
        sessionId,
        resolvedModel.limits?.context,
      ),
    );

    Future<void> reportStatus(SessionStatus status, {String? error}) async {
      final turnStatus = switch (status) {
        SessionStatus.waitingForApproval => TurnStatus.waitingForApproval,
        SessionStatus.waitingForInput => TurnStatus.waitingForInput,
        SessionStatus.running => TurnStatus.running,
        _ => null,
      };
      if (turnStatus != null) {
        await _sessions.updateTurn(turnId, turnStatus);
      }
      final terminal =
          status == SessionStatus.idle || status == SessionStatus.failed;
      final updated = await _sessions.updateStatus(
        sessionId,
        status,
        activeTurnId: terminal ? null : turnId,
        error: error,
      );
      // A client that queues follow-ups starts the next turn the moment it
      // sees the idle session, so the slot has to be free before the event
      // goes out. The `finally` below stays as the cancellation backstop.
      if (terminal && identical(_activeTurns[sessionId], cancellation)) {
        _activeTurns.remove(sessionId);
      }
      _emitSession(updated);
    }

    final agentClock = SessionAgentClock(
      clock: _clock,
      sessionId: sessionId,
      pendingInput: pendingInput,
    );
    final permissionMode = await _effectivePermission(session, definition);
    // Skills resolve against the worktree, so a branch carries the project
    // skills that were committed to it.
    final skills = await _skills.viewFor(worktree.path);
    final skillSummaries = skills.summaries();
    final tools = <AgentTool>[
      ..._toolsFactory(definition.toolIds, worktree.path, sessionId, turnId),
      CurrentTimeTool(clock: agentClock),
      SleepTool(clock: agentClock),
      GetContextRemainingTool(),
      NewContextTool(),
      AskUserTool(
        coordinator: _DatabaseUserQuestionCoordinator(
          timeline: _timeline,
          events: _events,
          pending: _pendingQuestions,
          ids: _ids,
          clock: _clock,
          sessionId: sessionId,
          turnId: turnId,
          reportStatus: reportStatus,
        ),
      ),
      if (skillSummaries.isNotEmpty) ...<AgentTool>[
        ListSkillsTool(skills),
        SkillTool(skills),
      ],
      if (definition.mode == AgentMode.primary &&
          definition.callableAgentIds.isNotEmpty)
        DelegateAgentTool(
          gateway: _SessionDelegationGateway(
            parentSession: session,
            parentDefinition: definition,
            service: this,
          ),
        ),
    ];

    final runner = AgentRunner(
      provider: resolvedModel.provider,
      tools: tools,
      approvals: _DatabaseApprovalCoordinator(
        timeline: _timeline,
        events: _events,
        pending: _pendingApprovals,
        ids: _ids,
        clock: _clock,
        sessionId: sessionId,
        turnId: turnId,
      ),
      onEvent: (type, data) async {
        await _appendEvent(
          sessionId: sessionId,
          turnId: turnId,
          type: type,
          data: data,
        );
        // The context meter rides the session stream, so every reported usage
        // updates the row the clients already watch.
        if (type == 'model.usage') {
          _emitSession(
            await _sessions.recordContextTokens(
              sessionId,
              ModelUsage.fromJson(data).contextTokens,
            ),
          );
        }
      },
      onStatus: reportStatus,
      onProviderItems: (items) =>
          _timeline.appendProviderItems(sessionId, items),
      // The runner emits `context.reset` itself; this only makes the discard
      // durable so a reconnect does not replay the retired window.
      contextResets: _DatabaseContextResetCoordinator(
        timeline: _timeline,
        sessions: _sessions,
        emitSession: _emitSession,
        sessionId: sessionId,
      ),
      // A shell the user allowed stays writable, so an interactive session
      // does not raise a dialog for every keystroke.
      policyFactory: (mode) => ExecSessionApprovalPolicy(
        DefaultApprovalPolicy(mode),
        _execHostFor(sessionId),
      ),
    );

    final turnAttachments = await _attachments.resolveAll(
      attachmentIds,
      hydrate: true,
    );
    final history = await _hydrateHistory(
      await _timeline.providerHistory(sessionId),
    );
    unawaited(
      _run(
        runner,
        AgentRunRequest(
          sessionId: sessionId,
          turnId: turnId,
          workspaceRoot: worktree.path,
          prompt: prompt,
          model: resolvedModel.modelId,
          reasoningEffort:
              session.reasoningEffort ?? definition.reasoningEffort,
          serviceTier: session.serviceTier,
          permissionMode: permissionMode,
          history: history,
          attachments: turnAttachments,
          safetyIdentifier: _safetyIdentifier,
          sessionMode: session.mode,
          customSystemPrompt: definition.promptEnabled
              ? definition.systemPrompt
              : null,
          skills: skillSummaries,
          contextWindowTokens: resolvedModel.limits?.context,
        ),
        cancellation,
      ),
    );
    return true;
  }

  Future<List<ConversationItem>> _hydrateHistory(
    List<ConversationItem> history,
  ) async => Future.wait(
    history.map((item) async {
      if (item is! UserConversationItem || item.attachments.isEmpty) {
        return item;
      }
      return UserConversationItem(
        item.text,
        attachments: await _attachments.resolveAll(
          item.attachments.map((attachment) => attachment.id).toList(),
          hydrate: true,
        ),
      );
    }),
  );

  Future<void> _run(
    AgentRunner runner,
    AgentRunRequest request,
    CancellationToken cancellation,
  ) async {
    try {
      final result = await runner.startTurn(request, cancellation);
      await _sessions.updateTurn(request.turnId, TurnStatus.completed);
      _completeTurn(request.turnId, result);
    } on AgentCancelledException {
      await _sessions.updateTurn(request.turnId, TurnStatus.cancelled);
      _failTurnCompletion(request.turnId, const AgentCancelledException());
    } on Exception catch (error) {
      await _markTurnFailed(request.turnId, error);
      _failTurnCompletion(request.turnId, error);
    } finally {
      if (identical(_activeTurns[request.sessionId], cancellation)) {
        _activeTurns.remove(request.sessionId);
      }
    }
  }

  Future<void> _markTurnFailed(String turnId, Object error) =>
      _sessions.updateTurn(turnId, TurnStatus.failed, error: '$error');

  /// The cancelTurn public API member.
  Future<void> cancelTurn(String sessionId) async =>
      _activeTurns[sessionId]?.cancel();

  /// Switches one session between planning and normal collaboration.
  ///
  /// Plan mode only changes the instructions handed to the model, so it can
  /// only be switched between turns.
  Future<SessionDto> setMode(String sessionId, SessionMode mode) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError('Cannot change the mode while a turn is running.');
    }
    final updated = await _sessions.updateMode(sessionId, mode);
    _emitSession(updated);
    return updated;
  }

  /// Sets or clears the reasoning effort override of one session.
  ///
  /// A null [reasoningEffort] restores inheritance from the agent definition.
  /// The effort is read when a turn starts, so it can only change between
  /// turns.
  Future<SessionDto> setReasoningEffort(
    String sessionId,
    String? reasoningEffort,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError(
        'Cannot change the reasoning effort while a turn is running.',
      );
    }
    final updated = await _sessions.updateReasoningEffort(
      sessionId,
      reasoningEffort,
    );
    _emitSession(updated);
    return updated;
  }

  /// Sets or clears the permission mode override of one session.
  ///
  /// A null [permissionMode] restores inheritance from the agent definition.
  /// Permissions are resolved when a turn starts, so they can only change
  /// between turns.
  Future<SessionDto> setPermissionMode(
    String sessionId,
    PermissionMode? permissionMode,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError(
        'Cannot change the permission mode while a turn is running.',
      );
    }
    final updated = await _sessions.updatePermissionMode(
      sessionId,
      permissionMode,
    );
    _emitSession(updated);
    return updated;
  }

  /// Sets or clears the provider service tier of one session.
  ///
  /// A null [serviceTier] restores the provider default tier. The tier is read
  /// when a turn starts, so it can only change between turns.
  Future<SessionDto> setServiceTier(
    String sessionId,
    String? serviceTier,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError(
        'Cannot change the service tier while a turn is running.',
      );
    }
    final updated = await _sessions.updateServiceTier(sessionId, serviceTier);
    _emitSession(updated);
    return updated;
  }

  /// Sets or clears the provider and model override of one session.
  ///
  /// A null [model] restores the fallback chain, which resolves at turn start.
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError('Cannot change the model while a turn is running.');
    }
    if (model != null) {
      await _providers.validateAgentModel(
        model.providerConnectionId,
        model.modelId,
      );
    }
    final updated = await _sessions.updateModel(sessionId, model);
    _emitSession(updated);
    return updated;
  }

  /// The resolveApproval public API member.
  Future<ApprovalRequestDto> resolveApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final status = approved ? ApprovalStatus.approved : ApprovalStatus.denied;
    final approval = await _timeline.resolveApproval(approvalId, status);
    if (approval == null) {
      throw StateError('Approval is not pending: $approvalId');
    }
    _pendingApprovals
        .remove(approvalId)
        ?.complete(
          approved ? ApprovalDecision.approved : ApprovalDecision.denied,
        );
    await _appendEvent(
      sessionId: approval.sessionId,
      turnId: approval.turnId,
      type: 'approval.resolved',
      data: <String, dynamic>{'approvalId': approval.id, 'status': status.name},
    );
    return approval;
  }

  /// Completes once the client queues input for [sessionId].
  ///
  /// Waiters share one completer, so a single notice wakes every sleeping
  /// tool in that session and a fresh completer takes its place.
  /// The notice is sticky: a client that queues something before the agent
  /// starts waiting would otherwise have its signal dropped, and the next
  /// sleep would run its full duration.
  Future<void> pendingInput(String sessionId) {
    if (_notedInput.remove(sessionId)) return Future<void>.value();
    return _pendingInput.putIfAbsent(sessionId, Completer<void>.new).future;
  }

  /// Reports that the client has something queued for [sessionId].
  ///
  /// Best-effort: it only shortens a wait, so a lost notice costs a longer
  /// sleep and nothing else.
  void notePendingInput(String sessionId) {
    _notedInput.add(sessionId);
    final waiting = _pendingInput.remove(sessionId);
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  /// Answers a pending agent question and lets its turn continue.
  Future<UserQuestionRequestDto> answerUserQuestion(
    String requestId,
    List<UserQuestionAnswerDto> answers,
  ) async {
    // Validate before writing: a rejected answer must leave the question
    // pending, or the blocked turn would never be answerable again.
    final pending = await _timeline.getUserQuestion(requestId);
    if (pending == null || pending.status != UserQuestionStatus.pending) {
      throw StateError('Question is not pending: $requestId');
    }
    final missing = pending.questions
        .map((question) => question.id)
        .toSet()
        .difference(answers.map((answer) => answer.questionId).toSet());
    if (missing.isNotEmpty) {
      throw StateError('Unanswered questions: ${missing.join(', ')}');
    }
    final request = await _timeline.answerUserQuestion(
      requestId,
      UserQuestionStatus.answered,
      answers,
    );
    if (request == null) {
      throw StateError('Question is not pending: $requestId');
    }
    _pendingQuestions.remove(requestId)?.complete(<UserAnswer>[
      for (final answer in answers)
        UserAnswer(
          questionId: answer.questionId,
          answer: answer.answer,
          isFreeForm: answer.isFreeForm,
        ),
    ]);
    await _appendEvent(
      sessionId: request.sessionId,
      turnId: request.turnId,
      type: 'userQuestion.answered',
      data: <String, dynamic>{
        'requestId': request.id,
        'answers': answers
            .map((answer) => answer.toJson())
            .toList(growable: false),
      },
    );
    return request;
  }

  Future<void> _appendEvent({
    required String sessionId,
    required String turnId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final event = await _timeline.append(
      sessionId: sessionId,
      turnId: turnId,
      type: type,
      data: data,
    );
    _events(
      WireEnvelope(
        type: RpcNotification.timelineEvent,
        payload: event.toJson(),
      ),
    );
  }

  void _emitSession(SessionDto? session) {
    if (session != null) {
      _events(
        WireEnvelope(
          type: RpcNotification.sessionUpdated,
          payload: session.toJson(),
        ),
      );
    }
  }

  Future<PermissionMode> _effectivePermission(
    SessionDto session,
    AgentDefinitionDto definition,
  ) async {
    final own = session.permissionMode ?? definition.permissionMode;
    final parentId = session.parentSessionId;
    if (parentId == null) return own;
    final parent = await _sessions.getById(parentId);
    if (parent == null) return PermissionMode.readOnly;
    final parentDefinition = await _definitions.resolve(
      parent.agentDefinitionId,
    );
    // A session override may narrow the parent's permissions but never widen
    // them, so a delegated agent cannot escalate past its caller.
    return _moreRestrictive(
      parent.permissionMode ?? parentDefinition.permissionMode,
      own,
    );
  }

  Future<ToolResult> _delegate({
    required SessionDto parentSession,
    required AgentDefinitionDto parentDefinition,
    required String agentDefinitionId,
    required String prompt,
    required CancellationToken cancellation,
  }) async {
    if (parentSession.parentSessionId != null ||
        !parentDefinition.callableAgentIds.contains(agentDefinitionId)) {
      throw StateError('Agent delegation is not allowed: $agentDefinitionId');
    }
    final childDefinition = await _definitions.get(agentDefinitionId);
    if (childDefinition.mode != AgentMode.subagent ||
        childDefinition.isArchived ||
        childDefinition.isStale) {
      throw StateError('Callable subagent is unavailable: $agentDefinitionId');
    }
    final now = _clock.nowUtc();
    final childModel = childDefinition.model.source == AgentModelSource.session
        ? await _effectiveSessionModel(parentSession, parentDefinition)
        : null;
    final child = await _sessions.create(
      SessionDto(
        id: _ids.generate(),
        worktreeId: parentSession.worktreeId,
        title: childDefinition.name,
        agentDefinitionId: childDefinition.id,
        parentSessionId: parentSession.id,
        origin: SessionOrigin.delegated,
        // A planning parent must not delegate work that mutates the workspace.
        mode: parentSession.mode,
        status: SessionStatus.idle,
        model: childModel,
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emitSession(child);
    final childTurnId = _ids.generate();
    await _sessions.updateStatus(
      parentSession.id,
      SessionStatus.waitingForSubagent,
    );
    _emitSession(await _sessions.getById(parentSession.id));
    try {
      if (!await startTurn(
        sessionId: child.id,
        turnId: childTurnId,
        prompt: prompt,
        trackCompletion: true,
      )) {
        throw StateError('Delegated turn ID already exists.');
      }
      cancellation.onCancel(() {
        unawaited(cancelTurn(child.id));
      });
      final completion = _turnCompletions[childTurnId];
      if (completion == null) {
        throw StateError('Delegated turn completion is unavailable.');
      }
      final result = await completion.future;
      final finalText = result.conversationItems
          .whereType<AssistantConversationItem>()
          .map((item) => item.text)
          .where((text) => text.isNotEmpty)
          .lastOrNull;
      return ToolResult(
        output:
            '{"childSessionId":"${child.id}",'
            '"status":"completed",'
            '"finalText":${jsonEncode(finalText ?? '')}}',
      );
    } finally {
      _turnCompletions.remove(childTurnId);
      if (!cancellation.isCancelled) {
        await _sessions.updateStatus(parentSession.id, SessionStatus.running);
        _emitSession(await _sessions.getById(parentSession.id));
      }
    }
  }

  /// Resolves the model a session runs on for inheritance by a subagent.
  ///
  /// Returns null when nothing resolves, which is safe: the child re-runs the
  /// full chain at turn start.
  Future<SessionModelSelectionDto?> _effectiveSessionModel(
    SessionDto session,
    AgentDefinitionDto definition,
  ) async {
    final selected = session.model;
    if (selected != null) return selected;
    final providerConnectionId = definition.model.providerConnectionId;
    final modelId = definition.model.modelId;
    if (definition.model.source == AgentModelSource.fixed &&
        providerConnectionId != null &&
        modelId != null) {
      return SessionModelSelectionDto(
        providerConnectionId: providerConnectionId,
        modelId: modelId,
      );
    }
    return _providers.fallbackModel();
  }

  void _completeTurn(String turnId, AgentRunResult result) {
    final completion = _turnCompletions[turnId];
    if (completion != null && !completion.isCompleted) {
      completion.complete(result);
    }
  }

  void _failTurnCompletion(String turnId, Object error) {
    final completion = _turnCompletions[turnId];
    if (completion != null && !completion.isCompleted) {
      completion.completeError(error);
    }
  }
}

PermissionMode _moreRestrictive(PermissionMode left, PermissionMode right) {
  const rank = <PermissionMode, int>{
    PermissionMode.readOnly: 0,
    PermissionMode.ask: 1,
    PermissionMode.workspaceWrite: 2,
  };
  return rank[left]! <= rank[right]! ? left : right;
}

/// Runs one delegated turn on behalf of a parent session.
///
/// A port rather than a direct call into [SessionService], so the tool's own
/// contract — argument validation, what it reports, how it fails — can be
/// exercised without standing up a database, a provider, and a turn loop.
abstract interface class AgentDelegationGateway {
  /// Starts the child turn and waits for its result.
  Future<ToolResult> delegate({
    required String agentDefinitionId,
    required String prompt,
    required CancellationToken cancellation,
  });
}

/// Delegates a bounded task to one allowed subagent.
final class DelegateAgentTool extends AgentTool {
  /// Creates a [DelegateAgentTool].
  DelegateAgentTool({required this._gateway});

  final AgentDelegationGateway _gateway;

  @override
  String get name => 'delegate_agent';

  @override
  String get description =>
      'Delegate a bounded task to one allowed subagent and wait for its '
      'result.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema => <String, dynamic>{
    'type': 'object',
    'properties': <String, dynamic>{
      'agentDefinitionId': <String, dynamic>{'type': 'string'},
      'prompt': <String, dynamic>{'type': 'string'},
    },
    'required': <String>['agentDefinitionId', 'prompt'],
    'additionalProperties': false,
  };

  @override
  Future<String?> preview(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final id = arguments['agentDefinitionId'];
    return id is String ? id : null;
  }

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final agentDefinitionId = arguments['agentDefinitionId'];
    final prompt = arguments['prompt'];
    if (agentDefinitionId is! String || agentDefinitionId.isEmpty) {
      return _reject('agentDefinitionId must be a non-empty string.');
    }
    if (prompt is! String || prompt.trim().isEmpty) {
      return _reject('prompt must be a non-empty string.');
    }
    return _gateway.delegate(
      agentDefinitionId: agentDefinitionId,
      prompt: prompt,
      cancellation: context.cancellation,
    );
  }

  static ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Binds one parent session to the service that runs its delegated turns.
final class _SessionDelegationGateway implements AgentDelegationGateway {
  const _SessionDelegationGateway({
    required this.parentSession,
    required this.parentDefinition,
    required this.service,
  });

  final SessionDto parentSession;
  final AgentDefinitionDto parentDefinition;
  final SessionService service;

  @override
  Future<ToolResult> delegate({
    required String agentDefinitionId,
    required String prompt,
    required CancellationToken cancellation,
  }) => service._delegate(
    parentSession: parentSession,
    parentDefinition: parentDefinition,
    agentDefinitionId: agentDefinitionId,
    prompt: prompt,
    cancellation: cancellation,
  );
}

/// Makes a `new_context` reset durable.
///
/// The runner has already trimmed its in-memory conversation; this retires the
/// stored window so a reconnect or a daemon restart replays exactly the same
/// items, and clears the token counter the meter reads.
class _DatabaseContextResetCoordinator implements ContextResetCoordinator {
  _DatabaseContextResetCoordinator({
    required this.timeline,
    required this.sessions,
    required this.emitSession,
    required this.sessionId,
  });

  final TimelineRepository timeline;
  final SessionRepository sessions;
  final void Function(SessionDto?) emitSession;
  final String sessionId;

  @override
  Future<void> reset(List<ConversationItem> retain) async {
    await timeline.resetContextWindow(sessionId, retain);
    emitSession(await sessions.getById(sessionId));
  }
}

class _DatabaseUserQuestionCoordinator implements UserQuestionCoordinator {
  _DatabaseUserQuestionCoordinator({
    required this.timeline,
    required this.events,
    required this.pending,
    required this.ids,
    required this.clock,
    required this.sessionId,
    required this.turnId,
    required this.reportStatus,
  });

  final TimelineRepository timeline;
  final DaemonEventSink events;
  final Map<String, Completer<List<UserAnswer>>> pending;
  final IdGenerator ids;
  final Clock clock;
  final String sessionId;
  final String turnId;
  final Future<void> Function(SessionStatus status) reportStatus;

  @override
  Future<List<UserAnswer>> ask(
    String callId,
    List<UserQuestion> questions,
    CancellationToken cancellation,
  ) async {
    final request = UserQuestionRequestDto(
      id: ids.generate(),
      sessionId: sessionId,
      turnId: turnId,
      toolCallId: callId,
      questions: <UserQuestionItemDto>[
        for (final question in questions)
          UserQuestionItemDto(
            id: question.id,
            header: question.header,
            question: question.question,
            options: <UserQuestionOptionDto>[
              for (final option in question.options)
                UserQuestionOptionDto(
                  label: option.label,
                  description: option.description,
                ),
            ],
          ),
      ],
      status: UserQuestionStatus.pending,
      createdAt: clock.nowUtc(),
    );
    final completer = Completer<List<UserAnswer>>();
    pending[request.id] = completer;
    await timeline.createUserQuestion(request);
    final timelineEvent = await timeline.append(
      sessionId: sessionId,
      turnId: turnId,
      type: 'userQuestion.requested',
      data: <String, dynamic>{'request': request.toJson()},
    );
    events(
      WireEnvelope(
        type: RpcNotification.timelineEvent,
        payload: timelineEvent.toJson(),
      ),
    );
    events(
      WireEnvelope(
        type: RpcNotification.userQuestionRequested,
        payload: request.toJson(),
      ),
    );
    // The runner does not know a tool is blocking, so the waiting state is set
    // here and cleared once an answer arrives.
    await reportStatus(SessionStatus.waitingForInput);
    cancellation.onCancel(() {
      final active = pending.remove(request.id);
      if (active != null && !active.isCompleted) {
        active.completeError(const AgentCancelledException());
      }
      unawaited(
        timeline.answerUserQuestion(
          request.id,
          UserQuestionStatus.cancelled,
          const <UserQuestionAnswerDto>[],
        ),
      );
    });
    try {
      return await completer.future;
    } finally {
      if (!cancellation.isCancelled) {
        await reportStatus(SessionStatus.running);
      }
    }
  }
}

class _DatabaseApprovalCoordinator implements ApprovalCoordinator {
  _DatabaseApprovalCoordinator({
    required this.timeline,
    required this.events,
    required this.pending,
    required this.ids,
    required this.clock,
    required this.sessionId,
    required this.turnId,
  });

  final TimelineRepository timeline;
  final DaemonEventSink events;
  final Map<String, Completer<ApprovalDecision>> pending;
  final IdGenerator ids;
  final Clock clock;
  final String sessionId;
  final String turnId;

  @override
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) async {
    final approval = ApprovalRequestDto(
      id: ids.generate(),
      sessionId: sessionId,
      turnId: turnId,
      toolCallId: invocation.callId,
      toolName: invocation.name,
      risk: invocation.risk,
      arguments: invocation.arguments,
      status: ApprovalStatus.pending,
      createdAt: clock.nowUtc(),
      preview: invocation.preview,
    );
    final completer = Completer<ApprovalDecision>();
    pending[approval.id] = completer;
    await timeline.createApproval(approval);
    final timelineEvent = await timeline.append(
      sessionId: sessionId,
      turnId: turnId,
      type: 'approval.requested',
      data: <String, dynamic>{'approval': approval.toJson()},
    );
    events(
      WireEnvelope(
        type: RpcNotification.timelineEvent,
        payload: timelineEvent.toJson(),
      ),
    );
    events(
      WireEnvelope(
        type: RpcNotification.approvalRequested,
        payload: approval.toJson(),
      ),
    );
    cancellation.onCancel(() {
      final active = pending.remove(approval.id);
      if (active != null && !active.isCompleted) {
        active.complete(ApprovalDecision.denied);
      }
      unawaited(
        timeline.resolveApproval(approval.id, ApprovalStatus.cancelled),
      );
    });
    return completer.future;
  }
}
