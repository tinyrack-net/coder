import 'dart:async';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/multi_agent_tools.dart';
import 'package:daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:protocol/protocol.dart';

/// Catalog capability that turns on the six collaboration tools.
const String collaborationCapabilityId = 'collaboration';

/// Concurrent subagent turns allowed per collaboration tree.
const int maxConcurrentSubagentTurnsPerTree = 4;

/// Smallest accepted `wait_agent` timeout.
const int minWaitTimeoutMs = 10000;

/// `wait_agent` timeout used when the model passes none.
const int defaultWaitTimeoutMs = 30000;

/// Largest accepted `wait_agent` timeout.
const int maxWaitTimeoutMs = 3600000;

/// A collaboration request the calling agent can recover from.
///
/// Surfaces as an error tool result rather than failing the caller's turn.
final class CollaborationException implements Exception {
  /// Creates a [CollaborationException].
  const CollaborationException(this.message);

  /// User- and model-visible reason.
  final String message;

  @override
  String toString() => message;
}

/// How a collaboration wait ended.
enum WaitAgentOutcome {
  /// New inter-agent mail arrived for the waiting agent.
  mail,

  /// The user queued new input for the waiting session.
  steer,

  /// The deadline elapsed without any activity.
  timeout,
}

/// Canonical collaboration path rules, ported from Codex `AgentPath`.
abstract final class AgentPaths {
  /// Path of every tree root.
  static const String root = '/root';

  static final RegExp _taskName = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

  /// Whether [name] is a valid spawnable task segment.
  static bool isValidTaskName(String name) =>
      name != 'root' && _taskName.hasMatch(name);

  /// Joins a child segment onto a canonical path.
  static String childPath(String callerPath, String taskName) =>
      '$callerPath/$taskName';

  /// Resolves a relative or absolute [target] against [callerPath].
  ///
  /// Returns null when the target is not a well-formed path inside the
  /// caller's tree.
  static String? resolve(String callerPath, String target) {
    if (target.startsWith('/')) {
      if (target == root) return root;
      if (!target.startsWith('$root/')) return null;
      final segments = target.substring(root.length + 1).split('/');
      if (segments.any((segment) => !isValidTaskName(segment))) return null;
      return target;
    }
    final segments = target.split('/');
    if (segments.isEmpty ||
        segments.any((segment) => !isValidTaskName(segment))) {
      return null;
    }
    return segments.fold<String>(callerPath, childPath);
  }
}

/// Resolves one agent definition by ID.
typedef AgentDefinitionLookup = Future<AgentDefinitionDto> Function(String id);

/// Validates that a model exists on a provider connection.
typedef AgentModelValidator = Future<void> Function(String modelId);

/// Resolves the concrete daemon default model.
typedef AgentDefaultModelResolver = Future<ModelSelectionDto> Function();

/// Turn control the collaboration layer needs from the session service.
abstract interface class SessionTurnPort {
  /// Starts one turn; false when the turn ID already exists.
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    bool internal = false,
  });

  /// Cancels the running turn of one session, if any.
  Future<void> cancelTurn(String sessionId);

  /// Whether a turn is currently running for [sessionId].
  bool hasActiveTurn(String sessionId);

  /// Completes once the client queues input for [sessionId].
  Future<void> pendingInput(String sessionId);
}

/// Orchestrates Codex-style multi-agent collaboration between sessions.
///
/// Owns agent identity (paths and task names), the persistent inter-agent
/// mailbox, the per-tree execution limiter, wait watches, fork seeding, and
/// the subagent lifecycle. The session service calls back into this class at
/// turn boundaries; this class starts and cancels turns only through the
/// [SessionTurnPort] bound at composition time.
class MultiAgentService {
  /// Creates a [MultiAgentService].
  MultiAgentService({
    required this._sessions,
    required this._mailbox,
    required this._timeline,
    required this._getDefinition,
    required this._validateModel,
    required this._defaultModel,
    required this._events,
    required this._clock,
    required this._ids,
  });

  final SessionRepository _sessions;
  final AgentMailboxRepository _mailbox;
  final TimelineRepository _timeline;
  final AgentDefinitionLookup _getDefinition;
  final AgentModelValidator _validateModel;
  final AgentDefaultModelResolver _defaultModel;
  final void Function(OutboundNotification event) _events;
  final Clock _clock;
  final IdGenerator _ids;

  /// Session IDs with a running subagent turn, per tree root.
  final Map<String, Set<String>> _runningByRoot = <String, Set<String>>{};

  /// Sessions whose trigger mail is parked until a slot frees, per root.
  final Map<String, List<String>> _parkedTriggers = <String, List<String>>{};

  /// Tree root of every session holding a slot, so a slot can be released
  /// without first reading the session row back.
  final Map<String, String> _rootBySlotHolder = <String, String>{};

  /// Waiters blocked in `wait_agent`, per waiting session.
  final Map<String, List<Completer<void>>> _mailWaiters =
      <String, List<Completer<void>>>{};

  /// The turn runtime, bound once from the composition root.
  late SessionTurnPort runtime;

  /// Tree root session ID of [session].
  String rootIdOf(SessionDto session) => session.rootSessionId ?? session.id;

  /// Canonical collaboration path of [session].
  String pathOf(SessionDto session) => session.agentPath ?? AgentPaths.root;

  bool _collaborationEnabled(
    SessionDto session,
    AgentDefinitionDto definition,
  ) =>
      definition.toolIds.contains(collaborationCapabilityId) ||
      session.parentSessionId != null;

  /// The collaboration tools one turn of [session] may call.
  List<AgentTool> collaborationToolsFor(
    SessionDto session,
    AgentDefinitionDto definition,
    String turnId,
  ) {
    if (!_collaborationEnabled(session, definition)) {
      return const <AgentTool>[];
    }
    return <AgentTool>[
      SpawnAgentTool(this, session, definition, turnId),
      SendMessageTool(this, session),
      FollowupTaskTool(this, session),
      WaitAgentTool(this, session),
      InterruptAgentTool(this, session),
      ListAgentsTool(this, session),
    ];
  }

  /// System-prompt collaboration hint for one turn, or null when disabled.
  String? usageHintFor(SessionDto session, AgentDefinitionDto definition) {
    if (!_collaborationEnabled(session, definition)) return null;
    final path = pathOf(session);
    final isRoot = session.parentSessionId == null;
    final identity = isRoot
        ? 'You are the root agent at path `$path` of a collaboration tree.'
        : 'You are subagent `$path`. Your final response of each turn is '
              'delivered to your parent as a FINAL_ANSWER message; make it '
              'self-contained.';
    // Only the root is coached to delegate. Handing the orchestrator prompt to
    // a subagent tells every child to spawn grandchildren and wait on them, so
    // the tree expands and times out instead of terminating.
    final role = isRoot ? orchestratorPrompt : subagentPrompt;
    return '''
## Multi-agent collaboration
$identity
Inter-agent messages arrive wrapped in an envelope of the form
`Message Type / Task name / Sender / Payload`; NEW_TASK starts your work,
MESSAGE is mid-flight coordination, and FINAL_ANSWER carries a finished
subagent's result.
- `spawn_agent` creates a subagent and starts it asynchronously; it never
  blocks. Reference agents by relative (`task_1`) or canonical
  (`/root/task_1`) path.
- `send_message` only queues a message; `followup_task` also starts a turn on
  an idle agent.
- `wait_agent` blocks until new agent activity or user input; call it
  sparingly and prefer doing useful work first.
- All agents share one workspace and filesystem; coordinate edits so agents
  do not overwrite each other.
At most $maxConcurrentSubagentTurnsPerTree subagent turns run concurrently
per tree.

$role''';
  }

  /// The mailbox drain handed to the runner of one session's turns.
  TurnInputSource drainSourceFor(String sessionId) =>
      _MailboxTurnInputSource(this, sessionId);

  /// Marks a delegated session as running when its turn starts.
  Future<void> onTurnStarted(SessionDto session) async {
    if (session.parentSessionId == null) return;
    if (session.lifecycle == AgentLifecycle.running) return;
    _emitSession(
      await _sessions.updateLifecycle(session.id, AgentLifecycle.running),
    );
  }

  /// Reserves a concurrency slot for a subagent turn.
  ///
  /// Root turns are free. Throws when the tree is at capacity.
  void acquireTurnSlot(SessionDto session) {
    if (session.agentPath == null) return;
    final rootId = rootIdOf(session);
    final running = _runningByRoot.putIfAbsent(rootId, () => <String>{});
    if (running.contains(session.id)) return;
    if (running.length >= maxConcurrentSubagentTurnsPerTree) {
      throw const CollaborationException(
        'Agent limit reached: $maxConcurrentSubagentTurnsPerTree concurrent '
        'subagent turns per tree.',
      );
    }
    running.add(session.id);
    _rootBySlotHolder[session.id] = rootId;
  }

  /// Releases a concurrency slot; safe to call twice.
  void releaseTurnSlot(SessionDto session) {
    if (session.agentPath == null) return;
    releaseTurnSlotOf(session.id);
  }

  /// Releases the slot held by [sessionId] without reading its session row.
  ///
  /// A slot outlives the row it was taken for: the session can be deleted, or
  /// the read that would recover its root can fail. Either way the slot has to
  /// come back, because a tree that leaks all of its slots refuses every
  /// further spawn.
  void releaseTurnSlotOf(String sessionId) {
    final rootId = _rootBySlotHolder.remove(sessionId);
    if (rootId == null) return;
    _runningByRoot[rootId]?.remove(sessionId);
  }

  /// Settles collaboration state after a turn of [sessionId] ended.
  Future<void> onTurnFinished({
    required String sessionId,
    required TurnStatus outcome,
    String? finalText,
    String? error,
  }) async {
    // The slot comes back before anything that can fail or return early.
    final slotRoot = _rootBySlotHolder[sessionId];
    releaseTurnSlotOf(sessionId);
    final session = await _sessions.getById(sessionId);
    if (session == null) {
      if (slotRoot != null) await _pumpParked(slotRoot);
      return;
    }
    if (session.parentSessionId != null) {
      final parent = await _sessions.getById(session.parentSessionId!);
      final wake = parent != null && _treeWentQuiet(session, parent);
      switch (outcome) {
        case TurnStatus.completed:
          _emitSession(
            await _sessions.updateLifecycle(
              session.id,
              AgentLifecycle.completed,
            ),
          );
          if (parent != null) {
            await enqueue(
              target: parent,
              type: InterAgentMessageType.finalAnswer,
              senderPath: pathOf(session),
              senderSessionId: session.id,
              payload: finalText ?? '',
              triggerTurn: wake,
            );
          }
        case TurnStatus.failed:
          _emitSession(
            await _sessions.updateLifecycle(session.id, AgentLifecycle.errored),
          );
          if (parent != null) {
            await enqueue(
              target: parent,
              type: InterAgentMessageType.finalAnswer,
              senderPath: pathOf(session),
              senderSessionId: session.id,
              payload: 'Status: errored\n${error ?? 'unknown error'}',
              triggerTurn: wake,
            );
          }
        // Interrupted is not final: no completion mail, the agent stays
        // messageable and resumable through `followup_task`.
        case TurnStatus.cancelled || TurnStatus.interrupted:
          _emitSession(
            await _sessions.updateLifecycle(
              session.id,
              AgentLifecycle.interrupted,
            ),
          );
        case TurnStatus.running ||
            TurnStatus.waitingForApproval ||
            TurnStatus.waitingForInput:
          break;
      }
    }
    // Trigger mail that arrived after the last drain boundary starts the
    // next turn now that the session is idle again. Only subagents receive
    // trigger mail, so plain sessions never touch the mailbox here.
    if (session.parentSessionId != null &&
        !runtime.hasActiveTurn(sessionId) &&
        await _mailbox.hasUndeliveredTrigger(sessionId)) {
      await _tryStartDeliveryTurn(sessionId);
    }
    await _pumpParked(rootIdOf(session));
  }

  /// Whether [finished]'s FINAL_ANSWER should start a turn on [parent].
  ///
  /// A parent that is mid-turn drains its mailbox at the next turn boundary on
  /// its own, and a parent with siblings still working would report on a
  /// half-finished tree. Only the last agent to go quiet wakes it, so N
  /// children finishing together produce one parent turn rather than N.
  bool _treeWentQuiet(SessionDto finished, SessionDto parent) {
    if (runtime.hasActiveTurn(parent.id)) return false;
    final rootId = rootIdOf(finished);
    final running = _runningByRoot[rootId];
    if (running != null && running.isNotEmpty) return false;
    final parked = _parkedTriggers[rootId];
    return parked == null || parked.isEmpty;
  }

  /// Persists and routes one inter-agent message.
  Future<AgentMailboxMessageDto> enqueue({
    required SessionDto target,
    required InterAgentMessageType type,
    required String senderPath,
    required String payload,
    required bool triggerTurn,
    String? senderSessionId,
  }) async {
    final message = AgentMailboxMessageDto(
      id: _ids.generate(),
      sessionId: target.id,
      senderPath: senderPath,
      recipientPath: pathOf(target),
      type: type,
      payload: payload,
      createdAt: _clock.nowUtc(),
      senderSessionId: senderSessionId,
    );
    await _mailbox.enqueue(message, triggerTurn: triggerTurn);
    await _appendEvent(
      sessionId: target.id,
      type: 'agent.mail',
      data: <String, dynamic>{'mail': message.toJson()},
    );
    _pulseMailWaiters(target.id);
    if (triggerTurn && !runtime.hasActiveTurn(target.id)) {
      await _tryStartDeliveryTurn(target.id);
    }
    return message;
  }

  /// Renders the model-visible collaboration envelope of one message.
  static String renderEnvelope(AgentMailboxMessageDto mail) {
    final type = switch (mail.type) {
      InterAgentMessageType.message => 'MESSAGE',
      InterAgentMessageType.newTask => 'NEW_TASK',
      InterAgentMessageType.finalAnswer => 'FINAL_ANSWER',
    };
    return 'Message Type: $type\n'
        'Task name: ${mail.recipientPath}\n'
        'Sender: ${mail.senderPath}\n'
        'Payload:\n${mail.payload}';
  }

  /// Spawns one subagent session and starts its first turn asynchronously.
  ///
  /// Returns the canonical path of the new agent.
  Future<String> spawn({
    required SessionDto caller,
    required AgentDefinitionDto callerDefinition,
    required String turnId,
    required String taskName,
    required String message,
    String? agentType,
    String forkTurns = 'none',
    String? model,
    String? reasoningEffort,
    String? serviceTier,
  }) async {
    if (!AgentPaths.isValidTaskName(taskName)) {
      throw const CollaborationException(
        'Invalid task_name: use lowercase letters, digits, and underscores, '
        'starting with a letter.',
      );
    }
    final int? forkLastN;
    var fullFork = false;
    switch (forkTurns) {
      case 'none':
        forkLastN = null;
      case 'all':
        fullFork = true;
        forkLastN = null;
      default:
        final parsed = int.tryParse(forkTurns);
        if (parsed == null || parsed <= 0) {
          throw const CollaborationException(
            'Invalid fork_turns: use "none", "all", or a positive integer.',
          );
        }
        forkLastN = parsed;
    }
    if (fullFork &&
        (agentType != null ||
            model != null ||
            reasoningEffort != null ||
            serviceTier != null)) {
      // A full-history fork continues the caller's own conversation, so it
      // cannot run as a different agent type or model.
      throw const CollaborationException(
        'agent_type, model, reasoning_effort, and service_tier cannot be '
        'overridden for a '
        'full-history fork.',
      );
    }
    final callerPath = pathOf(caller);
    final rootId = rootIdOf(caller);
    final childPath = AgentPaths.childPath(callerPath, taskName);
    if (await _sessions.getByAgentPath(rootId, childPath) != null) {
      throw CollaborationException('task_name already exists: $taskName');
    }
    final running = _runningByRoot[rootId];
    if (running != null &&
        running.length >= maxConcurrentSubagentTurnsPerTree) {
      throw const CollaborationException(
        'Agent limit reached: $maxConcurrentSubagentTurnsPerTree concurrent '
        'subagent turns per tree. Wait for a subagent to finish or solve the '
        'task yourself.',
      );
    }

    final AgentDefinitionDto childDefinition;
    if (agentType == null || agentType == callerDefinition.id) {
      childDefinition = callerDefinition;
    } else {
      if (!callerDefinition.callableAgentIds.contains(agentType)) {
        throw CollaborationException('Agent type is not allowed: $agentType');
      }
      childDefinition = await _getDefinition(agentType);
      if (childDefinition.mode != AgentMode.subagent ||
          childDefinition.isArchived ||
          childDefinition.isStale) {
        throw CollaborationException('Agent type is unavailable: $agentType');
      }
    }

    final ModelSelectionDto childModel;
    final Map<String, ModelControlValueDto> inheritedControls;
    if (fullFork) {
      childModel = caller.model;
      inheritedControls = caller.modelControls;
    } else if (model != null) {
      await _validateModel(model);
      childModel = ModelSelectionDto(modelId: model);
      inheritedControls = const <String, ModelControlValueDto>{};
    } else if (childDefinition.model case final agentModel?) {
      await _validateModel(agentModel.qualifiedModelId);
      childModel = agentModel;
      inheritedControls = childDefinition.modelControls;
    } else {
      childModel = await _defaultModel();
      inheritedControls = const <String, ModelControlValueDto>{};
    }

    final now = _clock.nowUtc();
    final child = await _sessions.create(
      SessionDto(
        id: _ids.generate(),
        worktreeId: caller.worktreeId,
        title: taskName,
        agentDefinitionId: childDefinition.id,
        parentSessionId: caller.id,
        taskName: taskName,
        agentPath: childPath,
        rootSessionId: rootId,
        lifecycle: AgentLifecycle.pendingInit,
        origin: SessionOrigin.delegated,
        // A planning parent must not spawn work that mutates the workspace.
        mode: caller.mode,
        status: SessionStatus.idle,
        model: childModel,
        modelControls: <String, ModelControlValueDto>{
          ...inheritedControls,
          if (reasoningEffort != null)
            'reasoning_effort': ModelControlValueDto.stringValue(
              value: reasoningEffort,
            ),
          if (serviceTier != null)
            'service_tier': ModelControlValueDto.stringValue(
              value: serviceTier,
            ),
        },
        createdAt: now,
        updatedAt: now,
      ),
    );
    _emitSession(child);
    await _appendEvent(
      sessionId: caller.id,
      turnId: turnId,
      type: 'agent.spawned',
      data: <String, dynamic>{
        'childSessionId': child.id,
        'taskName': taskName,
        'agentPath': childPath,
        'agentDefinitionId': childDefinition.id,
      },
    );
    if (fullFork || forkLastN != null) {
      await _seedFork(
        parentSessionId: caller.id,
        childSessionId: child.id,
        lastNTurns: forkLastN,
      );
    }
    await enqueue(
      target: child,
      type: InterAgentMessageType.newTask,
      senderPath: callerPath,
      senderSessionId: caller.id,
      payload: message,
      triggerTurn: true,
    );
    return childPath;
  }

  /// Resolves a tool `target` reference to a session in the caller's tree.
  Future<SessionDto> resolveTarget(SessionDto caller, String target) async {
    final path = AgentPaths.resolve(pathOf(caller), target);
    if (path == null) {
      throw CollaborationException('Invalid agent target: $target');
    }
    final session = await _sessions.getByAgentPath(rootIdOf(caller), path);
    if (session == null) {
      throw CollaborationException('Agent not found: $target');
    }
    return session;
  }

  /// Queues a message without starting a turn.
  Future<void> sendMessage({
    required SessionDto caller,
    required String target,
    required String message,
  }) async {
    final resolved = await resolveTarget(caller, target);
    await enqueue(
      target: resolved,
      type: InterAgentMessageType.message,
      senderPath: pathOf(caller),
      senderSessionId: caller.id,
      payload: message,
      triggerTurn: false,
    );
  }

  /// Queues a follow-up task; starts a turn when the target is idle.
  Future<bool> followupTask({
    required SessionDto caller,
    required String target,
    required String message,
  }) async {
    final resolved = await resolveTarget(caller, target);
    if (resolved.agentPath == null) {
      throw const CollaborationException(
        'followup_task cannot target the tree root; use send_message.',
      );
    }
    final wasIdle = !runtime.hasActiveTurn(resolved.id);
    await enqueue(
      target: resolved,
      type: InterAgentMessageType.message,
      senderPath: pathOf(caller),
      senderSessionId: caller.id,
      payload: message,
      triggerTurn: true,
    );
    return wasIdle;
  }

  /// Blocks until agent activity, user input, or the deadline.
  Future<({WaitAgentOutcome outcome, bool timedOut})> waitAgent({
    required SessionDto caller,
    required CancellationToken cancellation,
    int? timeoutMs,
  }) async {
    final timeout = timeoutMs ?? defaultWaitTimeoutMs;
    if (timeout < minWaitTimeoutMs || timeout > maxWaitTimeoutMs) {
      throw const CollaborationException(
        'timeout_ms must be between $minWaitTimeoutMs and $maxWaitTimeoutMs.',
      );
    }
    // Sticky pre-check: mail that arrived before the wait must not be lost.
    if ((await _mailbox.undeliveredFor(caller.id)).isNotEmpty) {
      return (outcome: WaitAgentOutcome.mail, timedOut: false);
    }
    final mailArrived = Completer<void>();
    _mailWaiters
        .putIfAbsent(caller.id, () => <Completer<void>>[])
        .add(mailArrived);
    final elapsed = Completer<void>();
    final timer = Timer(Duration(milliseconds: timeout), () {
      if (!elapsed.isCompleted) elapsed.complete();
    });
    final stopped = Completer<void>();
    cancellation.onCancel(() {
      if (!stopped.isCompleted) stopped.complete();
    });
    try {
      final outcome = await Future.any(<Future<WaitAgentOutcome>>[
        mailArrived.future.then((_) => WaitAgentOutcome.mail),
        runtime.pendingInput(caller.id).then((_) => WaitAgentOutcome.steer),
        elapsed.future.then((_) => WaitAgentOutcome.timeout),
        stopped.future.then((_) => WaitAgentOutcome.timeout),
      ]);
      cancellation.throwIfCancelled();
      return (outcome: outcome, timedOut: outcome == WaitAgentOutcome.timeout);
    } finally {
      timer.cancel();
      _mailWaiters[caller.id]?.remove(mailArrived);
    }
  }

  /// Interrupts the running turn of one subagent.
  ///
  /// Returns the lifecycle before the interrupt. The agent stays alive and
  /// messageable.
  Future<AgentLifecycle> interruptAgent({
    required SessionDto caller,
    required String target,
  }) async {
    final resolved = await resolveTarget(caller, target);
    if (resolved.agentPath == null) {
      throw const CollaborationException(
        'interrupt_agent cannot target the tree root.',
      );
    }
    if (resolved.id == caller.id) {
      throw const CollaborationException('An agent cannot interrupt itself.');
    }
    final previous = _lifecycleOf(resolved);
    await runtime.cancelTurn(resolved.id);
    return previous;
  }

  /// Lists agents of the caller's tree, optionally under a path prefix.
  Future<List<({String agentName, AgentLifecycle agentStatus})>> listAgents({
    required SessionDto caller,
    String? pathPrefix,
  }) async {
    final tree = await _sessions.listByRoot(rootIdOf(caller));
    return <({String agentName, AgentLifecycle agentStatus})>[
      for (final session in tree)
        if (pathPrefix == null ||
            pathOf(session) == pathPrefix ||
            pathOf(session).startsWith('$pathPrefix/'))
          (agentName: pathOf(session), agentStatus: _lifecycleOf(session)),
    ];
  }

  AgentLifecycle _lifecycleOf(SessionDto session) =>
      session.lifecycle ??
      (runtime.hasActiveTurn(session.id)
          ? AgentLifecycle.running
          : AgentLifecycle.completed);

  Future<void> _tryStartDeliveryTurn(String sessionId) async {
    final session = await _sessions.getById(sessionId);
    if (session == null || runtime.hasActiveTurn(sessionId)) return;
    if (!await _mailbox.hasUndeliveredTrigger(sessionId)) return;
    if (session.agentPath != null) {
      final running = _runningByRoot[rootIdOf(session)];
      if (running != null &&
          !running.contains(sessionId) &&
          running.length >= maxConcurrentSubagentTurnsPerTree) {
        final parked = _parkedTriggers.putIfAbsent(
          rootIdOf(session),
          () => <String>[],
        );
        if (!parked.contains(sessionId)) parked.add(sessionId);
        return;
      }
    }
    try {
      // The mail itself rides the runner's first drain boundary; the prompt
      // only explains the turn in the transcript.
      await runtime.startTurn(
        sessionId: sessionId,
        turnId: _ids.generate(),
        prompt: 'Process the new inter-agent messages.',
      );
      // The session service signals "a turn is already running" with a
      // StateError; losing that benign race must not crash the daemon, and
      // the racing turn drains the mail instead.
      // ignore: avoid_catching_errors - benign same-isolate start race.
    } on StateError {
      // Intentionally ignored; see above.
    }
  }

  Future<void> _pumpParked(String rootId) async {
    final parked = _parkedTriggers[rootId];
    if (parked == null || parked.isEmpty) return;
    final next = parked.removeAt(0);
    await _tryStartDeliveryTurn(next);
  }

  void _pulseMailWaiters(String sessionId) {
    final waiters = _mailWaiters.remove(sessionId);
    if (waiters == null) return;
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  /// Copies the caller's history into a freshly spawned fork.
  ///
  /// Keeps user prompts and non-empty assistant text, drops tool calls, tool
  /// results, and opaque reasoning items: the child continues the visible
  /// conversation without inheriting provider-bound state. With [lastNTurns]
  /// only the trailing N user-prompt boundaries survive.
  Future<void> _seedFork({
    required String parentSessionId,
    required String childSessionId,
    required int? lastNTurns,
  }) async {
    final history = await _timeline.providerHistory(parentSessionId);
    final kept = <ConversationItem>[];
    for (final item in history) {
      if (item is UserConversationItem && item.text.trim().isNotEmpty) {
        kept.add(
          UserConversationItem(item.text, attachments: item.attachments),
        );
      } else if (item is AssistantConversationItem &&
          item.text.trim().isNotEmpty) {
        kept.add(AssistantConversationItem(text: item.text));
      }
    }
    var sliced = kept;
    if (lastNTurns != null) {
      final boundaries = <int>[
        for (var index = 0; index < kept.length; index += 1)
          if (kept[index] is UserConversationItem) index,
      ];
      if (boundaries.length > lastNTurns) {
        sliced = kept.sublist(boundaries[boundaries.length - lastNTurns]);
      }
    }
    if (sliced.isEmpty) return;
    await _timeline.appendProviderItems(childSessionId, sliced);
  }

  Future<void> _appendEvent({
    required String sessionId,
    required String type,
    required Map<String, dynamic> data,
    String? turnId,
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
}

final class _MailboxTurnInputSource implements TurnInputSource {
  _MailboxTurnInputSource(this._service, this._sessionId);

  final MultiAgentService _service;
  final String _sessionId;

  @override
  Future<List<ConversationItem>> drainPending() async {
    final queued = await _service._mailbox.undeliveredFor(_sessionId);
    if (queued.isEmpty) return const <ConversationItem>[];
    await _service._mailbox.markDelivered(
      queued.map((entry) => entry.message.id).toList(growable: false),
      _service._clock.nowUtc(),
    );
    return <ConversationItem>[
      for (final entry in queued)
        UserConversationItem(MultiAgentService.renderEnvelope(entry.message)),
    ];
  }
}

/// Registers the collaboration tools a turn may drive subagents with.
///
/// Selection is not by id alone: a subagent is handed the tools by its
/// parentage, because an agent that was spawned has to be able to answer the
/// agent that spawned it.
final class CollaborationToolProvider extends AgentToolProvider {
  /// Creates a provider reading the supervisor at turn time.
  ///
  /// The supervisor is wired after the session service it drives, so reading
  /// it per turn is what keeps the registry from capturing a null at boot.
  const CollaborationToolProvider(this._multiAgent);

  final MultiAgentService? Function() _multiAgent;

  @override
  String get id => collaborationCapabilityId;

  @override
  AgentToolDefinition get catalogEntry => const AgentToolDefinition(
    id: collaborationCapabilityId,
    name: collaborationCapabilityId,
    description:
        'Spawn, message, wait on, interrupt, and list collaborating '
        'subagents that share this workspace.',
    risk: AgentToolRisk.read,
    group: AgentToolGroup.collaboration,
  );

  @override
  List<AgentTool> create(AgentToolScope scope) =>
      _multiAgent()?.collaborationToolsFor(
        scope.session.value! as SessionDto,
        scope.definition.value! as AgentDefinitionDto,
        scope.turnId,
      ) ??
      const <AgentTool>[];
}
