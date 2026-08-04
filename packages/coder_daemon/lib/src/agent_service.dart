import 'dart:async';
import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/agent_definitions.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_daemon/src/skills.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by DaemonEventSink.
typedef DaemonEventSink = void Function(WireEnvelope event);

/// Signature used by AgentToolsFactory.
typedef AgentToolsFactory =
    Iterable<AgentTool> Function(Iterable<String> ids, String workspaceRoot);

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
  });

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
  final Map<String, CancellationToken> _activeTurns =
      <String, CancellationToken>{};
  final Map<String, Completer<ApprovalDecision>> _pendingApprovals =
      <String, Completer<ApprovalDecision>>{};
  final Map<String, Completer<AgentRunResult>> _turnCompletions =
      <String, Completer<AgentRunResult>>{};

  /// The startTurn public API member.
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
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
    );
    if (!created) return false;

    final cancellation = CancellationToken();
    _activeTurns[sessionId] = cancellation;
    if (trackCompletion) {
      _turnCompletions[turnId] = Completer<AgentRunResult>();
    }
    await _sessions.updateStatus(
      sessionId,
      SessionStatus.running,
      activeTurnId: turnId,
    );
    _emitSession(await _sessions.getById(sessionId));

    final permissionMode = await _effectivePermission(session, definition);
    // Skills resolve against the worktree, so a branch carries the project
    // skills that were committed to it.
    final skills = await _skills.viewFor(worktree.path);
    final skillSummaries = skills.summaries();
    final tools = <AgentTool>[
      ..._toolsFactory(definition.toolIds, worktree.path),
      if (skillSummaries.isNotEmpty) SkillTool(skills),
      if (definition.mode == AgentMode.primary &&
          definition.callableAgentIds.isNotEmpty)
        _DelegateAgentTool(
          parentSession: session,
          parentDefinition: definition,
          service: this,
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
      onEvent: (type, data) => _appendEvent(
        sessionId: sessionId,
        turnId: turnId,
        type: type,
        data: data,
      ),
      onStatus: (status, {error}) async {
        final turnStatus = switch (status) {
          SessionStatus.waitingForApproval => TurnStatus.waitingForApproval,
          SessionStatus.running => TurnStatus.running,
          _ => null,
        };
        if (turnStatus != null) {
          await _sessions.updateTurn(turnId, turnStatus);
        }
        final updated = await _sessions.updateStatus(
          sessionId,
          status,
          activeTurnId:
              status == SessionStatus.idle || status == SessionStatus.failed
              ? null
              : turnId,
          error: error,
        );
        _emitSession(updated);
      },
      onProviderItems: (items) =>
          _timeline.appendProviderItems(sessionId, items),
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
          reasoningEffort: definition.reasoningEffort,
          permissionMode: permissionMode,
          history: await _timeline.providerHistory(sessionId),
          safetyIdentifier: _safetyIdentifier,
          sessionMode: session.mode,
          customSystemPrompt: definition.promptEnabled
              ? definition.systemPrompt
              : null,
          skills: skillSummaries,
        ),
        cancellation,
      ),
    );
    return true;
  }

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

  /// Sets or clears the provider and model override of one session.
  ///
  /// A null [model] restores inheritance from the agent definition.
  Future<SessionDto> setModel(
    String sessionId,
    SessionModelSelectionDto? model,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError('Cannot change the model while a turn is running.');
    }
    final definition = await _definitions.resolve(session.agentDefinitionId);
    if (model == null && definition.model.source == AgentModelSource.session) {
      throw StateError('This agent requires an explicit session model.');
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
    final parentId = session.parentSessionId;
    if (parentId == null) return definition.permissionMode;
    final parent = await _sessions.getById(parentId);
    if (parent == null) return PermissionMode.readOnly;
    final parentDefinition = await _definitions.resolve(
      parent.agentDefinitionId,
    );
    return _moreRestrictive(
      parentDefinition.permissionMode,
      definition.permissionMode,
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
        ? _effectiveSessionModel(parentSession, parentDefinition)
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

  SessionModelSelectionDto _effectiveSessionModel(
    SessionDto session,
    AgentDefinitionDto definition,
  ) {
    final selected = session.model;
    if (selected != null) return selected;
    final providerConnectionId = definition.model.providerConnectionId;
    final modelId = definition.model.modelId;
    if (definition.model.source != AgentModelSource.fixed ||
        providerConnectionId == null ||
        modelId == null) {
      throw StateError('Parent session has no executable model.');
    }
    return SessionModelSelectionDto(
      providerConnectionId: providerConnectionId,
      modelId: modelId,
    );
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

final class _DelegateAgentTool extends AgentTool {
  _DelegateAgentTool({
    required this.parentSession,
    required this.parentDefinition,
    required this.service,
  });

  final SessionDto parentSession;
  final AgentDefinitionDto parentDefinition;
  final SessionService service;

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
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) => service._delegate(
    parentSession: parentSession,
    parentDefinition: parentDefinition,
    agentDefinitionId: arguments['agentDefinitionId'] as String,
    prompt: arguments['prompt'] as String,
    cancellation: context.cancellation,
  );
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
