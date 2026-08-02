import 'dart:async';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:coder_daemon/src/provider_service.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Signature used by DaemonEventSink.
typedef DaemonEventSink = void Function(WireEnvelope event);

/// Signature used by AgentToolsFactory.
typedef AgentToolsFactory = Iterable<AgentTool> Function();

/// AgentService defines a public contract.
class AgentService {
  /// Creates a [AgentService].
  AgentService({
    required this._agents,
    required this._worktrees,
    required this._timeline,
    required this._providers,
    required this._events,
    required this._safetyIdentifier,
    required this._clock,
    required this._ids,
    required this._toolsFactory,
  });

  final AgentRepository _agents;
  final WorktreeRepository _worktrees;
  final TimelineRepository _timeline;
  final ProviderService _providers;
  final DaemonEventSink _events;
  final String _safetyIdentifier;
  final Clock _clock;
  final IdGenerator _ids;
  final AgentToolsFactory _toolsFactory;
  final Map<String, CancellationToken> _activeTurns =
      <String, CancellationToken>{};
  final Map<String, Completer<ApprovalDecision>> _pendingApprovals =
      <String, Completer<ApprovalDecision>>{};

  /// The startTurn public API member.
  Future<bool> startTurn({
    required String agentId,
    required String turnId,
    required String prompt,
  }) async {
    final agent = await _agents.getById(agentId);
    if (agent == null) throw StateError('Agent not found: $agentId');
    await _providers.validateAgentModel(
      agent.providerConnectionId,
      agent.model,
    );
    if (_activeTurns.containsKey(agentId)) {
      throw StateError('Agent already has a running turn.');
    }
    final worktree = await _worktrees.getById(agent.worktreeId);
    if (worktree == null || worktree.archivedAt != null) {
      throw StateError('Worktree not found: ${agent.worktreeId}');
    }
    final provider = await _providers.resolve(
      agent.providerConnectionId,
      modelId: agent.model,
    );
    final created = await _agents.createTurn(
      id: turnId,
      agentId: agentId,
      prompt: prompt,
    );
    if (!created) return false;

    final cancellation = CancellationToken();
    _activeTurns[agentId] = cancellation;
    await _agents.updateStatus(
      agentId,
      AgentStatus.running,
      activeTurnId: turnId,
    );
    _emitAgent(await _agents.getById(agentId));

    final runner = AgentRunner(
      provider: provider,
      tools: _toolsFactory(),
      approvals: _DatabaseApprovalCoordinator(
        timeline: _timeline,
        events: _events,
        pending: _pendingApprovals,
        ids: _ids,
        clock: _clock,
        agentId: agentId,
        turnId: turnId,
      ),
      onEvent: (type, data) => _appendEvent(
        agentId: agentId,
        turnId: turnId,
        type: type,
        data: data,
      ),
      onStatus: (status, {error}) async {
        final turnStatus = switch (status) {
          AgentStatus.waitingForApproval => TurnStatus.waitingForApproval,
          AgentStatus.running => TurnStatus.running,
          _ => null,
        };
        if (turnStatus != null) {
          await _agents.updateTurn(turnId, turnStatus);
        }
        final updated = await _agents.updateStatus(
          agentId,
          status,
          activeTurnId:
              status == AgentStatus.idle || status == AgentStatus.failed
              ? null
              : turnId,
          error: error,
        );
        _emitAgent(updated);
      },
      onProviderItems: (items) => _timeline.appendProviderItems(agentId, items),
    );

    unawaited(
      _run(
        runner,
        AgentRunRequest(
          agentId: agentId,
          turnId: turnId,
          workspaceRoot: worktree.path,
          prompt: prompt,
          model: agent.model,
          reasoningEffort: agent.reasoningEffort,
          permissionMode: agent.permissionMode,
          history: await _timeline.providerHistory(agentId),
          safetyIdentifier: _safetyIdentifier,
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
      await runner.startTurn(request, cancellation);
      await _agents.updateTurn(request.turnId, TurnStatus.completed);
    } on AgentCancelledException {
      await _agents.updateTurn(request.turnId, TurnStatus.cancelled);
    } on Exception catch (error) {
      await _markTurnFailed(request.turnId, error);
    } finally {
      if (identical(_activeTurns[request.agentId], cancellation)) {
        _activeTurns.remove(request.agentId);
      }
    }
  }

  Future<void> _markTurnFailed(String turnId, Object error) =>
      _agents.updateTurn(turnId, TurnStatus.failed, error: '$error');

  /// The cancelTurn public API member.
  Future<void> cancelTurn(String agentId) async =>
      _activeTurns[agentId]?.cancel();

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
      agentId: approval.agentId,
      turnId: approval.turnId,
      type: 'approval.resolved',
      data: <String, dynamic>{'approvalId': approval.id, 'status': status.name},
    );
    return approval;
  }

  Future<void> _appendEvent({
    required String agentId,
    required String turnId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final event = await _timeline.append(
      agentId: agentId,
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

  void _emitAgent(AgentDto? agent) {
    if (agent != null) {
      _events(
        WireEnvelope(
          type: RpcNotification.agentUpdated,
          payload: agent.toJson(),
        ),
      );
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
    required this.agentId,
    required this.turnId,
  });

  final TimelineRepository timeline;
  final DaemonEventSink events;
  final Map<String, Completer<ApprovalDecision>> pending;
  final IdGenerator ids;
  final Clock clock;
  final String agentId;
  final String turnId;

  @override
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) async {
    final approval = ApprovalRequestDto(
      id: ids.generate(),
      agentId: agentId,
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
      agentId: agentId,
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
