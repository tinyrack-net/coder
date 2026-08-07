import 'dart:async';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/agents/infrastructure/agent_definitions.dart';
import 'package:coder_daemon/src/features/attachments/infrastructure/attachment_service.dart';
import 'package:coder_daemon/src/features/prompts/infrastructure/skills.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/provider_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/agent_clock.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/goal_service.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/multi_agent.dart';
import 'package:coder_daemon/src/features/sessions/infrastructure/session_interactions.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:coder_daemon/src/shared/ports/agent_protocol_mapping.dart';
import 'package:coder_daemon/src/transport/rpc/binding.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by DaemonEventSink.
typedef DaemonEventSink = void Function(OutboundNotification event);

/// Resolves the tools published at runtime rather than compiled in.
///
/// MCP servers publish their tools as they connect, and a worktree's own
/// servers only exist for turns running in that worktree, so the lookup is
/// prepared per turn rather than held as a fixed map.
abstract interface class ExternalToolSource {
  /// Prepares [workspaceRoot] and returns the lookup this turn resolves with.
  AgentTool? Function(String id) lookupFor(String workspaceRoot);
}

/// Resolves the pseudo-terminals one coder session owns.
typedef ExecHostFactory = ExecSessionHost Function(String sessionId);

/// Coordinates model-turn execution and lifecycle for coder sessions.
class SessionTurnCoordinator implements SessionTurnPort {
  /// Creates a session turn coordinator.
  SessionTurnCoordinator({
    required this._sessions,
    required this._definitions,
    required this._worktrees,
    required this._timeline,
    required this._models,
    required this._events,
    required this._safetyIdentifier,
    required this._clock,
    required this._toolRegistry,
    required this._externalTools,
    required this._skills,
    required this._attachments,
    required this._execHostFor,
    required this._settings,
    required this._interactions,
  });

  final ExecHostFactory _execHostFor;
  final SessionRepository _sessions;
  final AgentDefinitionService _definitions;
  final WorktreeRepository _worktrees;
  final TimelineRepository _timeline;
  final ProviderModelResolver _models;
  final DaemonEventSink _events;
  final String _safetyIdentifier;
  final Clock _clock;
  final AgentToolRegistry _toolRegistry;
  final ExternalToolSource _externalTools;
  final SkillCatalogService _skills;
  final AttachmentService _attachments;
  final SettingsRepository _settings;
  final SessionInteractionCoordinator _interactions;
  final Map<String, CancellationToken> _activeTurns =
      <String, CancellationToken>{};
  final Map<String, Completer<AgentRunResult>> _turnCompletions =
      <String, Completer<AgentRunResult>>{};
  final Set<String> _startingTurns = <String>{};

  /// The collaboration layer, bound once from the composition root.
  MultiAgentService? multiAgent;

  /// Goal lifecycle bound once from the composition root.
  SessionGoalService? goals;

  @override
  bool hasActiveTurn(String sessionId) => _activeTurns.containsKey(sessionId);

  /// The startTurn public API member.
  @override
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    List<String> attachmentIds = const <String>[],
    bool trackCompletion = false,
    bool internal = false,
  }) async {
    if (!_startingTurns.add(sessionId)) {
      throw StateError('Agent already has a turn starting.');
    }
    try {
      final session = await _sessions.getById(sessionId);
      if (session == null) throw StateError('Session not found: $sessionId');
      final definition = await _definitions.resolve(session.agentDefinitionId);
      final sessionModel = session.model;
      // A session override wins over the model of its agent definition.
      final resolvedModel = sessionModel == null
          ? await _models.resolveAgentModel(definition.model)
          : await _models.resolveExplicitModel(
              sessionModel.providerConnectionId,
              sessionModel.modelId,
            );
      final controls = sessionModel != null
          ? session.modelControls
          : definition.model.source == AgentModelSource.fixed
          ? definition.modelControls
          : const <String, ModelControlValueDto>{};
      await _models.validateModelControls(
        resolvedModel.connectionId,
        resolvedModel.modelId,
        controls,
      );
      if (_activeTurns.containsKey(sessionId)) {
        throw StateError('Agent already has a running turn.');
      }
      final worktree = await _worktrees.getById(session.worktreeId);
      if (worktree == null || worktree.archivedAt != null) {
        throw StateError('Worktree not found: ${session.worktreeId}');
      }
      // Subagent turns hold a per-tree concurrency slot from here on; the slot
      // is released by `onTurnFinished` once the launched run terminates, or in
      // the `finally` below when the turn never launches.
      multiAgent?.acquireTurnSlot(session);
      var launched = false;
      try {
        return await _startAcquiredTurn(
          session: session,
          definition: definition,
          resolvedModel: resolvedModel,
          modelControls: controls,
          worktree: worktree,
          sessionId: sessionId,
          turnId: turnId,
          prompt: prompt,
          attachmentIds: attachmentIds,
          trackCompletion: trackCompletion,
          internal: internal,
          onLaunched: () => launched = true,
        );
      } finally {
        if (!launched) multiAgent?.releaseTurnSlot(session);
      }
    } finally {
      _startingTurns.remove(sessionId);
    }
  }

  Future<bool> _startAcquiredTurn({
    required SessionDto session,
    required AgentDefinitionDto definition,
    required ResolvedAgentModel resolvedModel,
    required Map<String, ModelControlValueDto> modelControls,
    required WorktreeDto worktree,
    required String sessionId,
    required String turnId,
    required String prompt,
    required List<String> attachmentIds,
    required bool trackCompletion,
    required bool internal,
    required void Function() onLaunched,
  }) async {
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
    _interactions.beginTurn(sessionId);
    _activeTurns[sessionId] = cancellation;
    if (trackCompletion) {
      _turnCompletions[turnId] = Completer<AgentRunResult>();
    }
    await _sessions.updateStatus(
      sessionId,
      SessionStatus.running,
      activeTurnId: turnId,
    );
    await multiAgent?.onTurnStarted(session);
    await goals?.onTurnStarted(session, internal: internal);
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
      pendingInput: _interactions.pendingInput,
    );
    // Skills resolve against the worktree, so a branch carries the project
    // skills that were committed to it.
    final skills = await _skills.viewFor(worktree.path);
    final scope = AgentToolScope(
      session: AgentSessionContext(id: session.id, value: session),
      definition: AgentDefinitionContext(
        id: definition.id,
        value: definition,
      ),
      selectedToolIds: _toolRegistry.resolveIds(definition.toolIds).toSet(),
      workspaceRoot: worktree.path,
      turnId: turnId,
      attachmentPublisher: TurnAttachmentPublisher(_attachments, turnId),
      attachmentReader: SessionAttachmentReader(_attachments, sessionId),
      clock: agentClock,
      questions: _interactions.questionsFor(
        sessionId: sessionId,
        turnId: turnId,
        reportStatus: reportStatus,
      ),
      execHost: _execHostFor(sessionId),
      skills: skills,
    );
    final turnTools = _toolRegistry.build(
      scope,
      external: _externalTools.lookupFor(worktree.path),
    );

    final runner = AgentRunner(
      provider: resolvedModel.provider,
      tools: turnTools.tools,
      // The summary is written by the model that produced the work, so the
      // compactor rides the same provider the turn already resolved.
      compactor: ConversationCompactor(resolvedModel.provider),
      approvals: _interactions.approvalsFor(
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
          final usage = ModelUsage.fromJson(data);
          _emitSession(
            await _sessions.recordContextTokens(
              sessionId,
              usage.contextTokens,
            ),
          );
          await goals?.accountUsage(sessionId, usage);
        }
      },
      onStatus: (status, {error}) =>
          reportStatus(protocolSessionStatus(status), error: error),
      onProviderItems: (items) =>
          _timeline.appendProviderItems(sessionId, items),
      pendingTurnInput: multiAgent?.drainSourceFor(sessionId),
      permissions: _LivePermissionModeSource(
        () => _effectivePermissionForSession(sessionId),
      ),
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
      policyFactory: (mode) =>
          turnTools.decoratePolicy(DefaultApprovalPolicy(mode)),
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
          modelControls: agentModelControls(modelControls),
          history: history,
          attachments: turnAttachments,
          safetyIdentifier: _safetyIdentifier,
          sessionMode: agentSessionMode(session.mode),
          customSystemPrompt: _composeCustomPrompt(
            definition.promptEnabled ? definition.systemPrompt : null,
            multiAgent?.usageHintFor(session, definition),
          ),
          toolPrompts: turnTools.promptFragments,
          contextWindowTokens: resolvedModel.limits?.context,
          // What the live window already holds, so a turn that starts on a
          // full window compacts before it samples rather than failing.
          priorUsage: ModelUsage(totalTokens: session.contextTokens),
          internal: internal,
          internalInstructions: () async => goals?.instructionsFor(sessionId),
        ),
        cancellation,
      ),
    );
    onLaunched();
    return true;
  }

  String? _composeCustomPrompt(String? definitionPrompt, String? collabHint) {
    final trimmedDefinition =
        definitionPrompt != null && definitionPrompt.trim().isNotEmpty
        ? definitionPrompt
        : null;
    final parts = <String>[?trimmedDefinition, ?collabHint];
    return parts.isEmpty ? null : parts.join('\n\n');
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
    TurnStatus outcome;
    String? finalText;
    String? failure;
    try {
      final result = await runner.startTurn(request, cancellation);
      await _sessions.updateTurn(request.turnId, TurnStatus.completed);
      _completeTurn(request.turnId, result);
      outcome = TurnStatus.completed;
      finalText = result.conversationItems
          .whereType<AssistantConversationItem>()
          .map((item) => item.text)
          .where((text) => text.isNotEmpty)
          .lastOrNull;
    } on AgentCancelledException {
      await _sessions.updateTurn(request.turnId, TurnStatus.cancelled);
      _failTurnCompletion(request.turnId, const AgentCancelledException());
      outcome = TurnStatus.cancelled;
    } on Exception catch (error) {
      await _markTurnFailed(request.turnId, error);
      _failTurnCompletion(request.turnId, error);
      outcome = TurnStatus.failed;
      failure = '$error';
    } finally {
      if (identical(_activeTurns[request.sessionId], cancellation)) {
        _activeTurns.remove(request.sessionId);
      }
    }
    // Runs after the turn slot is free so collaboration follow-ups can start
    // the session's next turn immediately.
    try {
      await multiAgent?.onTurnFinished(
        sessionId: request.sessionId,
        outcome: outcome,
        finalText: finalText,
        error: failure,
      );
    } on Exception {
      // See the StateError clause below: this runner is detached, so an
      // escaping failure has no handler above it.
    }
    // The daemon closes its database while turns may still be settling, and
    // drift reports a query that outlives it as a StateError. Restart
    // recovery reconciles session state and queued mail is durable, so
    // there is nothing to salvage — but letting it escape a detached runner
    // would surface as an unhandled error.
    // ignore: avoid_catching_errors
    on StateError {
      // Nothing to salvage; see above.
    }
    try {
      await goals?.onTurnFinished(
        request.sessionId,
        outcome,
        error: failure,
      );
    } on Exception {
      // Restart recovery reconsiders durable active goals.
    }
    // A detached turn may finish after daemon shutdown has closed drift.
    // Durable active goals are reconsidered during restart recovery, so this
    // shutdown-only database StateError must not escape the runner.
    // ignore: avoid_catching_errors
    on StateError {
      // Nothing to salvage; see above.
    }
  }

  Future<void> _markTurnFailed(String turnId, Object error) =>
      _sessions.updateTurn(turnId, TurnStatus.failed, error: '$error');

  /// The cancelTurn public API member.
  @override
  Future<void> cancelTurn(String sessionId) async {
    await goals?.pauseForCancellation(sessionId);
    _activeTurns[sessionId]?.cancel();
  }

  /// Summarizes a session's context window on request and retires it.
  ///
  /// Only between turns: a running turn owns the live history, so rewriting it
  /// underneath would strand a tool call halfway through its round. The
  /// automatic trigger inside a turn goes through the runner instead.
  Future<void> compactSession(String sessionId) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) throw StateError('Session not found: $sessionId');
    if (_activeTurns.containsKey(sessionId)) {
      throw StateError('Cannot compact while a turn is running.');
    }
    final history = await _hydrateHistory(
      await _timeline.providerHistory(sessionId),
    );
    // Nothing to hand off, and a summary request on an empty history would
    // spend a model call to say so.
    if (history.isEmpty) return;

    final definition = await _definitions.resolve(session.agentDefinitionId);
    final sessionModel = session.model;
    final resolvedModel = sessionModel == null
        ? await _models.resolveAgentModel(definition.model)
        : await _models.resolveExplicitModel(
            sessionModel.providerConnectionId,
            sessionModel.modelId,
          );
    final modelControls = sessionModel != null
        ? session.modelControls
        : definition.model.source == AgentModelSource.fixed
        ? definition.modelControls
        : const <String, ModelControlValueDto>{};
    await _models.validateModelControls(
      resolvedModel.connectionId,
      resolvedModel.modelId,
      modelControls,
    );
    final compacted = await ConversationCompactor(resolvedModel.provider)
        .compact(
          history: history,
          target: CompactionTarget(
            model: resolvedModel.modelId,
            modelControls: agentModelControls(modelControls),
            safetyIdentifier: _safetyIdentifier,
          ),
          cancellation: CancellationToken(),
        );

    await _timeline.resetContextWindow(sessionId, compacted);
    await _appendEvent(
      sessionId: sessionId,
      turnId: session.activeTurnId,
      type: 'context.compacted',
      data: <String, dynamic>{
        'retained': compacted.length,
        'trigger': 'manual',
      },
    );
    _emitSession(await _sessions.getById(sessionId));
  }

  /// Completes once the client queues input for [sessionId].
  ///
  /// Waiters share one completer, so a single notice wakes every sleeping
  /// tool in that session and a fresh completer takes its place.
  /// The notice is sticky: a client that queues something before the agent
  /// starts waiting would otherwise have its signal dropped, and the next
  /// sleep would run its full duration.
  @override
  Future<void> pendingInput(String sessionId) {
    return _interactions.pendingInput(sessionId);
  }

  /// Reports that the client has something queued for [sessionId].
  ///
  /// Best-effort: it only shortens a wait, so a lost notice costs a longer
  /// sleep and nothing else.
  void notePendingInput(String sessionId) {
    _interactions.notePendingInput(sessionId);
  }

  Future<void> _appendEvent({
    required String sessionId,
    required String? turnId,
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
      OutboundNotification(sessionsTimelineEventNotification, event),
    );
  }

  void _emitSession(SessionDto? session) {
    if (session != null) {
      _events(
        OutboundNotification(sessionsUpdatedNotification, session),
      );
    }
  }

  Future<PermissionMode> _effectivePermissionForSession(
    String sessionId,
  ) async {
    final session = await _sessions.getById(sessionId);
    if (session == null) return PermissionMode.readOnly;
    final definition = await _definitions.resolve(session.agentDefinitionId);
    final storedDefault = await _settings.getValue('permission.defaultMode');
    final defaultMode = storedDefault == null || storedDefault.isEmpty
        ? PermissionMode.ask
        : PermissionMode.values.byName(storedDefault);
    // A session override may narrow an ancestor's permissions but never widen
    // them, so no agent in a nested tree can escalate past any ancestor.
    var mode =
        session.permissionMode ?? definition.permissionMode ?? defaultMode;
    var parentId = session.parentSessionId;
    final visited = <String>{session.id};
    while (parentId != null && visited.add(parentId)) {
      final parent = await _sessions.getById(parentId);
      if (parent == null) return PermissionMode.readOnly;
      final parentDefinition = await _definitions.resolve(
        parent.agentDefinitionId,
      );
      mode = _moreRestrictive(
        parent.permissionMode ?? parentDefinition.permissionMode ?? defaultMode,
        mode,
      );
      parentId = parent.parentSessionId;
    }
    return mode;
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
    PermissionMode.fullAccess: 3,
  };
  return rank[left]! <= rank[right]! ? left : right;
}

final class _LivePermissionModeSource implements PermissionModeSource {
  const _LivePermissionModeSource(this._read);

  final Future<PermissionMode> Function() _read;

  @override
  Future<AgentPermissionMode> currentMode() async =>
      agentPermission(await _read());
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
