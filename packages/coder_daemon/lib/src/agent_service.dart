import 'dart:async';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'provider_service.dart';

typedef DaemonEventSink = void Function(WireEnvelope event);

class AgentService {
  AgentService({
    required CoderDatabase database,
    required ProviderService providers,
    required DaemonEventSink events,
    required String safetyIdentifier,
  }) : _database = database,
       _providers = providers,
       _events = events,
       _safetyIdentifier = safetyIdentifier;

  final CoderDatabase _database;
  final ProviderService _providers;
  final DaemonEventSink _events;
  final String _safetyIdentifier;
  final Uuid _uuid = const Uuid();
  final Map<String, CancellationToken> _activeTurns =
      <String, CancellationToken>{};
  final Map<String, Completer<ApprovalDecision>> _pendingApprovals =
      <String, Completer<ApprovalDecision>>{};

  Future<bool> startTurn({
    required String agentId,
    required String turnId,
    required String prompt,
  }) async {
    final agent = await _database.getAgentDto(agentId);
    if (agent == null) throw StateError('Agent not found: $agentId');
    await _providers.validateAgentModel(agent.providerId, agent.model);
    if (_activeTurns.containsKey(agentId))
      throw StateError('Agent already has a running turn.');
    final workspace = await _database.getWorkspaceDto(agent.workspaceId);
    if (workspace == null)
      throw StateError('Workspace not found: ${agent.workspaceId}');
    final created = await _database.createTurn(
      id: turnId,
      agentId: agentId,
      prompt: prompt,
    );
    if (!created) return false;

    final cancellation = CancellationToken();
    _activeTurns[agentId] = cancellation;
    await _database.updateAgentStatus(
      agentId,
      AgentStatus.running,
      activeTurnId: turnId,
    );
    _emitAgent(await _database.getAgentDto(agentId));

    final runner = AgentRunner(
      provider: await _providers.resolve(
        agent.providerId,
        modelId: agent.model,
      ),
      tools: <AgentTool>[
        ListDirectoryTool(),
        ReadFileTool(),
        SearchTextTool(),
        ApplyPatchTool(),
        RunCommandTool(),
      ],
      approvals: _DatabaseApprovalCoordinator(
        database: _database,
        events: _events,
        pending: _pendingApprovals,
        uuid: _uuid,
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
        if (turnStatus != null) await _database.updateTurn(turnId, turnStatus);
        final updated = await _database.updateAgentStatus(
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
      onProviderItems: (items) => _database.appendProviderItems(agentId, items),
    );

    unawaited(
      _run(
        runner,
        AgentRunRequest(
          agentId: agentId,
          turnId: turnId,
          workspaceRoot: workspace.rootPath,
          prompt: prompt,
          model: agent.model,
          reasoningEffort: agent.reasoningEffort,
          permissionMode: agent.permissionMode,
          history: await _database.providerHistory(agentId),
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
      await _database.updateTurn(request.turnId, TurnStatus.completed);
    } on AgentCancelledException {
      await _database.updateTurn(request.turnId, TurnStatus.cancelled);
    } catch (error) {
      await _database.updateTurn(
        request.turnId,
        TurnStatus.failed,
        error: '$error',
      );
    } finally {
      if (identical(_activeTurns[request.agentId], cancellation)) {
        _activeTurns.remove(request.agentId);
      }
    }
  }

  Future<void> cancelTurn(String agentId) async =>
      _activeTurns[agentId]?.cancel();

  Future<ApprovalRequestDto> resolveApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final status = approved ? ApprovalStatus.approved : ApprovalStatus.denied;
    final approval = await _database.resolveApproval(approvalId, status);
    if (approval == null)
      throw StateError('Approval is not pending: $approvalId');
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
    final event = await _database.appendTimeline(
      agentId: agentId,
      turnId: turnId,
      type: type,
      data: data,
    );
    _events(
      WireEnvelope(type: MessageType.timelineEvent, payload: event.toJson()),
    );
  }

  void _emitAgent(AgentDto? agent) {
    if (agent != null) {
      _events(
        WireEnvelope(type: MessageType.agentUpdate, payload: agent.toJson()),
      );
    }
  }
}

class _DatabaseApprovalCoordinator implements ApprovalCoordinator {
  _DatabaseApprovalCoordinator({
    required this.database,
    required this.events,
    required this.pending,
    required this.uuid,
    required this.agentId,
    required this.turnId,
  });

  final CoderDatabase database;
  final DaemonEventSink events;
  final Map<String, Completer<ApprovalDecision>> pending;
  final Uuid uuid;
  final String agentId;
  final String turnId;

  @override
  Future<ApprovalDecision> request(
    ToolInvocation invocation,
    CancellationToken cancellation,
  ) async {
    final approval = ApprovalRequestDto(
      id: uuid.v4(),
      agentId: agentId,
      turnId: turnId,
      toolCallId: invocation.callId,
      toolName: invocation.name,
      risk: invocation.risk,
      arguments: invocation.arguments,
      status: ApprovalStatus.pending,
      createdAt: DateTime.now().toUtc(),
      preview: invocation.preview,
    );
    final completer = Completer<ApprovalDecision>();
    pending[approval.id] = completer;
    await database.createApproval(approval);
    final timeline = await database.appendTimeline(
      agentId: agentId,
      turnId: turnId,
      type: 'approval.requested',
      data: <String, dynamic>{'approval': approval.toJson()},
    );
    events(
      WireEnvelope(type: MessageType.timelineEvent, payload: timeline.toJson()),
    );
    events(
      WireEnvelope(
        type: MessageType.approvalRequest,
        payload: approval.toJson(),
      ),
    );
    cancellation.onCancel(() {
      final active = pending.remove(approval.id);
      if (active != null && !active.isCompleted)
        active.complete(ApprovalDecision.denied);
      unawaited(
        database.resolveApproval(approval.id, ApprovalStatus.cancelled),
      );
    });
    return completer.future;
  }
}
