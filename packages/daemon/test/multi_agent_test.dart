@Tags(<String>['feature_test__agent_collaboration__unit'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/multi_agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/multi_agent_tools.dart';
import 'package:daemon/src/shared/infrastructure/persistence/database.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:drift/native.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

final class _FixedClock implements Clock {
  const _FixedClock(this.now);

  final DateTime now;

  @override
  DateTime nowUtc() => now;
}

final class _SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String generate() => 'id-${_next++}';
}

final class _FakeRuntime implements SessionTurnPort {
  final Set<String> active = <String>{};
  final List<({String sessionId, String turnId, String prompt})> started =
      <({String sessionId, String turnId, String prompt})>[];
  final List<String> cancelled = <String>[];
  final Map<String, Completer<void>> steer = <String, Completer<void>>{};
  bool throwOnStart = false;

  @override
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    bool internal = false,
  }) async {
    if (throwOnStart) throw StateError('Agent already has a running turn.');
    started.add((sessionId: sessionId, turnId: turnId, prompt: prompt));
    return true;
  }

  @override
  Future<void> cancelTurn(String sessionId) async => cancelled.add(sessionId);

  @override
  bool hasActiveTurn(String sessionId) => active.contains(sessionId);

  @override
  Future<void> pendingInput(String sessionId) =>
      steer.putIfAbsent(sessionId, Completer<void>.new).future;
}

const AgentDefinitionDto _tinestDefinition = AgentDefinitionDto(
  id: 'tinest',
  name: 'Tinest',
  description: 'Primary agent.',
  mode: AgentMode.primary,
  promptEnabled: false,
  systemPrompt: '',
  model: AgentModelSelectionDto(source: AgentModelSource.session),
  modelControls: <String, ModelControlValueDto>{
    'reasoning_effort': ModelControlValueDto.stringValue(value: 'medium'),
  },
  permissionMode: PermissionMode.workspaceWrite,
  toolIds: <String>[collaborationCapabilityId],
  callableAgentIds: <String>['reviewer'],
  contentHash: 'hash',
  sourcePath: '/config/agents/tinest.md',
);

const AgentDefinitionDto _reviewerDefinition = AgentDefinitionDto(
  id: 'reviewer',
  name: 'Reviewer',
  description: 'Reviews code.',
  mode: AgentMode.subagent,
  promptEnabled: false,
  systemPrompt: '',
  model: AgentModelSelectionDto(source: AgentModelSource.session),
  modelControls: <String, ModelControlValueDto>{
    'reasoning_effort': ModelControlValueDto.stringValue(value: 'medium'),
  },
  permissionMode: PermissionMode.readOnly,
  toolIds: <String>[],
  callableAgentIds: <String>[],
  contentHash: 'hash',
  sourcePath: '/config/agents/reviewer.md',
);

void main() {
  final now = DateTime.utc(2026, 8, 6);
  late TinestDatabase database;
  late _FakeRuntime fakeRuntime;
  late MultiAgentService service;
  late List<OutboundNotification> emitted;
  late List<(String, String)> validatedModels;

  SessionDto session(
    String id, {
    String? parentSessionId,
    String? taskName,
    String? agentPath,
    String? rootSessionId,
    AgentLifecycle? lifecycle,
    SessionModelSelectionDto? model,
    String agentDefinitionId = 'tinest',
  }) => SessionDto(
    id: id,
    worktreeId: 'worktree',
    title: id,
    agentDefinitionId: agentDefinitionId,
    origin: parentSessionId == null
        ? SessionOrigin.manual
        : SessionOrigin.delegated,
    status: SessionStatus.idle,
    parentSessionId: parentSessionId,
    taskName: taskName,
    agentPath: agentPath,
    rootSessionId: rootSessionId,
    lifecycle: lifecycle,
    model:
        model ??
        const SessionModelSelectionDto(
          modelId: 'openai/gpt-test',
        ),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    database = TinestDatabase.forTesting(
      NativeDatabase.memory(),
      clock: _FixedClock(now),
    );
    await database.workspaceDao.register(
      WorkspaceDto(
        id: 'workspace',
        name: 'Workspace',
        rootPath: '/workspace',
        kind: WorkspaceKind.directory,
        createdAt: now,
      ),
    );
    await database.worktreeDao.upsert(
      WorktreeDto(
        id: 'worktree',
        workspaceId: 'workspace',
        name: 'Workspace',
        path: '/workspace',
        kind: WorktreeKind.directory,
        isTinestOwned: false,
        createdAt: now,
      ),
    );
    fakeRuntime = _FakeRuntime();
    emitted = <OutboundNotification>[];
    validatedModels = <(String, String)>[];
    service = MultiAgentService(
      sessions: database.sessionDao,
      mailbox: database.agentMailboxDao,
      timeline: database.timelineDao,
      getDefinition: (id) async => switch (id) {
        'tinest' => _tinestDefinition,
        'reviewer' => _reviewerDefinition,
        _ => throw const FormatException('Unknown agent definition.'),
      },
      fallbackModel: () async => null,
      validateModel: (modelId) async {
        validatedModels.add(('', modelId));
        if (modelId == 'missing-model') {
          throw const CollaborationException('Unknown model.');
        }
      },
      events: emitted.add,
      clock: _FixedClock(now),
      ids: _SequentialIds(),
    )..runtime = fakeRuntime;
  });

  tearDown(() => database.close());

  group('AgentPaths', () {
    test('validates task names', () {
      expect(AgentPaths.isValidTaskName('task_1'), isTrue);
      expect(AgentPaths.isValidTaskName('a'), isTrue);
      expect(AgentPaths.isValidTaskName('root'), isFalse);
      expect(AgentPaths.isValidTaskName('Task'), isFalse);
      expect(AgentPaths.isValidTaskName('1task'), isFalse);
      expect(AgentPaths.isValidTaskName(''), isFalse);
      expect(AgentPaths.isValidTaskName('has-dash'), isFalse);
      expect(AgentPaths.isValidTaskName('x' * 65), isFalse);
    });

    test('resolves relative and absolute targets', () {
      expect(AgentPaths.resolve('/root', 'task_1'), '/root/task_1');
      expect(
        AgentPaths.resolve('/root/task_1', 'task_2'),
        '/root/task_1/task_2',
      );
      expect(AgentPaths.resolve('/root', 'a/b'), '/root/a/b');
      expect(AgentPaths.resolve('/root/task_1', '/root'), '/root');
      expect(AgentPaths.resolve('/root', '/root/task_1'), '/root/task_1');
      expect(AgentPaths.resolve('/root', '/other/task_1'), isNull);
      expect(AgentPaths.resolve('/root', '/root/BAD'), isNull);
      expect(AgentPaths.resolve('/root', '..'), isNull);
      expect(AgentPaths.resolve('/root', 'root'), isNull);
    });
  });

  group('spawn', () {
    test('creates an identified child and triggers its first turn', () async {
      final root = await database.sessionDao.create(session('root'));
      final path = await service.spawn(
        caller: root,
        callerDefinition: _tinestDefinition,
        turnId: 'turn-1',
        taskName: 'review_task',
        message: 'Review the code.',
        agentType: 'reviewer',
      );
      expect(path, '/root/review_task');

      final child = (await database.sessionDao.getByAgentPath(
        'root',
        '/root/review_task',
      ))!;
      expect(child.parentSessionId, 'root');
      expect(child.rootSessionId, 'root');
      expect(child.taskName, 'review_task');
      expect(child.lifecycle, AgentLifecycle.pendingInit);
      expect(child.agentDefinitionId, 'reviewer');
      expect(child.model, root.model);
      expect(child.origin, SessionOrigin.delegated);

      // NEW_TASK mail is queued for the child and its delivery turn started.
      final queued = await database.agentMailboxDao.undeliveredFor(child.id);
      expect(queued.single.message.type, InterAgentMessageType.newTask);
      expect(queued.single.message.payload, 'Review the code.');
      expect(queued.single.triggerTurn, isTrue);
      expect(fakeRuntime.started.single.sessionId, child.id);

      // The parent timeline records the spawn.
      final events = await database.timelineDao.after('root', 0);
      expect(
        events
            .where((event) => event.type == 'agent.spawned')
            .single
            .data['agentPath'],
        '/root/review_task',
      );
    });

    test('rejects invalid names, duplicates, and bad fork values', () async {
      final root = await database.sessionDao.create(session('root'));
      Future<String> spawn(String name, {String fork = 'none'}) =>
          service.spawn(
            caller: root,
            callerDefinition: _tinestDefinition,
            turnId: 'turn-1',
            taskName: name,
            message: 'Work.',
            forkTurns: fork,
          );

      await expectLater(
        spawn('Bad-Name'),
        throwsA(isA<CollaborationException>()),
      );
      await expectLater(
        spawn('ok', fork: 'seven'),
        throwsA(isA<CollaborationException>()),
      );
      await expectLater(
        spawn('ok', fork: '0'),
        throwsA(isA<CollaborationException>()),
      );
      await spawn('taken');
      await expectLater(
        spawn('taken'),
        throwsA(
          isA<CollaborationException>().having(
            (error) => error.message,
            'message',
            contains('already exists'),
          ),
        ),
      );
    });

    test('rejects overrides for a full-history fork', () async {
      final root = await database.sessionDao.create(session('root'));
      await expectLater(
        service.spawn(
          caller: root,
          callerDefinition: _tinestDefinition,
          turnId: 'turn-1',
          taskName: 'forked',
          message: 'Continue.',
          forkTurns: 'all',
          agentType: 'reviewer',
        ),
        throwsA(isA<CollaborationException>()),
      );
    });

    test('persists explicit model controls on a non-full fork', () async {
      final root = await database.sessionDao.create(session('root'));
      await service.spawn(
        caller: root,
        callerDefinition: _tinestDefinition,
        turnId: 'turn-1',
        taskName: 'controlled',
        message: 'Work.',
        reasoningEffort: 'high',
        serviceTier: 'priority',
      );
      final child = (await database.sessionDao.getByAgentPath(
        'root',
        '/root/controlled',
      ))!;
      expect(
        child.modelControls,
        <String, ModelControlValueDto>{
          'reasoning_effort': const ModelControlValueDto.stringValue(
            value: 'high',
          ),
          'service_tier': const ModelControlValueDto.stringValue(
            value: 'priority',
          ),
        },
      );
    });

    test('rejects agent types outside the caller allowlist', () async {
      final root = await database.sessionDao.create(session('root'));
      await expectLater(
        service.spawn(
          caller: root,
          callerDefinition: _tinestDefinition,
          turnId: 'turn-1',
          taskName: 'stranger_task',
          message: 'Work.',
          agentType: 'stranger',
        ),
        throwsA(
          isA<CollaborationException>().having(
            (error) => error.message,
            'message',
            contains('not allowed'),
          ),
        ),
      );
    });

    test('validates model overrides against the caller connection', () async {
      final root = await database.sessionDao.create(session('root'));
      await service.spawn(
        caller: root,
        callerDefinition: _tinestDefinition,
        turnId: 'turn-1',
        taskName: 'fast_task',
        message: 'Work.',
        model: 'openai/gpt-cheap',
      );
      expect(validatedModels.single, ('', 'openai/gpt-cheap'));
      final child = (await database.sessionDao.getByAgentPath(
        'root',
        '/root/fast_task',
      ))!;
      expect(child.model?.modelId, 'openai/gpt-cheap');
      await expectLater(
        service.spawn(
          caller: root,
          callerDefinition: _tinestDefinition,
          turnId: 'turn-1',
          taskName: 'bad_model',
          message: 'Work.',
          model: 'missing-model',
        ),
        throwsA(isA<CollaborationException>()),
      );
    });

    test('rejects a spawn when the tree is at capacity', () async {
      final root = await database.sessionDao.create(session('root'));
      for (
        var index = 0;
        index < maxConcurrentSubagentTurnsPerTree;
        index += 1
      ) {
        service.acquireTurnSlot(
          session(
            'busy-$index',
            parentSessionId: 'root',
            taskName: 'busy_$index',
            agentPath: '/root/busy_$index',
            rootSessionId: 'root',
          ),
        );
      }
      await expectLater(
        service.spawn(
          caller: root,
          callerDefinition: _tinestDefinition,
          turnId: 'turn-1',
          taskName: 'one_too_many',
          message: 'Work.',
        ),
        throwsA(
          isA<CollaborationException>().having(
            (error) => error.message,
            'message',
            contains('Agent limit reached'),
          ),
        ),
      );
    });
  });

  group('limiter', () {
    test('caps concurrent subagent turns per tree and frees slots', () {
      final subagents = List<SessionDto>.generate(
        maxConcurrentSubagentTurnsPerTree + 1,
        (index) => session(
          'sub-$index',
          parentSessionId: 'root',
          taskName: 'task_$index',
          agentPath: '/root/task_$index',
          rootSessionId: 'root',
        ),
      );
      subagents
          .take(maxConcurrentSubagentTurnsPerTree)
          .forEach(service.acquireTurnSlot);
      expect(
        () => service.acquireTurnSlot(subagents.last),
        throwsA(isA<CollaborationException>()),
      );
      // Re-acquiring a held slot and root sessions are both free.
      service
        ..acquireTurnSlot(subagents.first)
        ..acquireTurnSlot(session('root'))
        ..releaseTurnSlot(subagents.first)
        ..acquireTurnSlot(subagents.last);
    });
  });

  group('mailbox', () {
    test('queue-only mail never starts a turn', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      await service.sendMessage(
        caller: root,
        target: 'task_a',
        message: 'Ping.',
      );
      expect(fakeRuntime.started, isEmpty);
      final queued = await database.agentMailboxDao.undeliveredFor(child.id);
      expect(queued.single.triggerTurn, isFalse);
    });

    test('followup starts a turn on an idle target only', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      expect(
        await service.followupTask(
          caller: root,
          target: 'task_a',
          message: 'More work.',
        ),
        isTrue,
      );
      expect(fakeRuntime.started.single.sessionId, child.id);

      fakeRuntime.active.add(child.id);
      expect(
        await service.followupTask(
          caller: root,
          target: 'task_a',
          message: 'Even more.',
        ),
        isFalse,
      );
      expect(fakeRuntime.started, hasLength(1));
    });

    test('followup rejects the tree root and unknown targets', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      await expectLater(
        service.followupTask(
          caller: child,
          target: '/root',
          message: 'Hi parent.',
        ),
        throwsA(isA<CollaborationException>()),
      );
      await expectLater(
        service.followupTask(
          caller: root,
          target: 'missing',
          message: 'Anyone?',
        ),
        throwsA(isA<CollaborationException>()),
      );
    });

    test('drain renders envelopes once and marks delivery', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      await service.sendMessage(
        caller: child,
        target: '/root',
        message: 'Progress update.',
      );
      final source = service.drainSourceFor(root.id);
      final drained = await source.drainPending();
      final text = (drained.single as UserConversationItem).text;
      expect(
        text,
        'Message Type: MESSAGE\n'
        'Task name: /root\n'
        'Sender: /root/task_a\n'
        'Payload:\nProgress update.',
      );
      expect(await source.drainPending(), isEmpty);
    });
  });

  group('onTurnFinished', () {
    late SessionDto root;
    late SessionDto child;

    setUp(() async {
      root = await database.sessionDao.create(session('root'));
      child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
          lifecycle: AgentLifecycle.running,
        ),
      );
    });

    test('completion mails a FINAL_ANSWER to the parent', () async {
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.completed,
        finalText: 'All done.',
      );
      expect(
        (await database.sessionDao.getById(child.id))!.lifecycle,
        AgentLifecycle.completed,
      );
      final mail = await database.agentMailboxDao.undeliveredFor(root.id);
      expect(mail.single.message.type, InterAgentMessageType.finalAnswer);
      expect(mail.single.message.payload, 'All done.');
    });

    test('the last child to finish wakes an idle parent', () async {
      // Without this the parent's mailbox holds an undelivered FINAL_ANSWER
      // forever whenever its own turn ended before the child's did, and the
      // tree only resumes when the user types.
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.completed,
        finalText: 'All done.',
      );
      final mail = await database.agentMailboxDao.undeliveredFor(root.id);
      expect(mail.single.triggerTurn, isTrue);
      expect(fakeRuntime.started.single.sessionId, root.id);
    });

    test('a failing child also wakes an idle parent', () async {
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.failed,
        error: 'provider exploded',
      );
      expect(fakeRuntime.started.single.sessionId, root.id);
    });

    test('a parent mid-turn is left alone', () async {
      fakeRuntime.active.add(root.id);
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.completed,
        finalText: 'All done.',
      );
      // The running parent drains the mailbox at its next turn boundary.
      expect(fakeRuntime.started, isEmpty);
    });

    test('a parent with a sibling still running is left alone', () async {
      final sibling = await database.sessionDao.create(
        session(
          'sibling',
          parentSessionId: 'root',
          taskName: 'task_b',
          agentPath: '/root/task_b',
          rootSessionId: 'root',
          lifecycle: AgentLifecycle.running,
        ),
      );
      service.acquireTurnSlot(sibling);
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.completed,
        finalText: 'First one done.',
      );
      // Waking now would make the parent report on a half-finished tree; the
      // sibling's own completion wakes it instead.
      expect(fakeRuntime.started, isEmpty);
      await service.onTurnFinished(
        sessionId: sibling.id,
        outcome: TurnStatus.completed,
        finalText: 'Second one done.',
      );
      expect(fakeRuntime.started.single.sessionId, root.id);
    });

    test('a vanished session still releases its turn slot', () async {
      final ghost = session(
        'ghost',
        parentSessionId: 'root',
        taskName: 'task_ghost',
        agentPath: '/root/task_ghost',
        rootSessionId: 'root',
      );
      service.acquireTurnSlot(ghost);
      // The row is gone, so onTurnFinished returns early. Releasing the slot
      // only after that read leaks it, and four leaks wedge the whole tree.
      await service.onTurnFinished(
        sessionId: ghost.id,
        outcome: TurnStatus.completed,
        finalText: 'Never recorded.',
      );
      for (var index = 0; index < maxConcurrentSubagentTurnsPerTree; index++) {
        service.acquireTurnSlot(
          session(
            'filler-$index',
            parentSessionId: 'root',
            taskName: 'filler_$index',
            agentPath: '/root/filler_$index',
            rootSessionId: 'root',
          ),
        );
      }
    });

    test('failure mails an errored FINAL_ANSWER', () async {
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.failed,
        error: 'provider exploded',
      );
      expect(
        (await database.sessionDao.getById(child.id))!.lifecycle,
        AgentLifecycle.errored,
      );
      final mail = await database.agentMailboxDao.undeliveredFor(root.id);
      expect(mail.single.message.payload, 'Status: errored\nprovider exploded');
    });

    test(
      'interruption is not final: no mail, agent stays messageable',
      () async {
        await service.onTurnFinished(
          sessionId: child.id,
          outcome: TurnStatus.cancelled,
        );
        expect(
          (await database.sessionDao.getById(child.id))!.lifecycle,
          AgentLifecycle.interrupted,
        );
        expect(await database.agentMailboxDao.undeliveredFor(root.id), isEmpty);
      },
    );

    test('a finished turn delivers trigger mail queued during it', () async {
      fakeRuntime.active.add(child.id);
      await service.followupTask(
        caller: root,
        target: 'task_a',
        message: 'Queued mid-turn.',
      );
      expect(fakeRuntime.started, isEmpty);
      fakeRuntime.active.remove(child.id);
      await service.onTurnFinished(
        sessionId: child.id,
        outcome: TurnStatus.completed,
        finalText: 'First answer.',
      );
      expect(
        fakeRuntime.started.map((call) => call.sessionId),
        contains(child.id),
      );
    });

    test('a freed slot pumps a parked trigger', () async {
      final blockers = List<SessionDto>.generate(
        maxConcurrentSubagentTurnsPerTree,
        (index) => session(
          'busy-$index',
          parentSessionId: 'root',
          taskName: 'busy_$index',
          agentPath: '/root/busy_$index',
          rootSessionId: 'root',
        ),
      )..forEach(service.acquireTurnSlot);
      // The follow-up cannot start while the tree is saturated: it parks.
      await service.followupTask(
        caller: root,
        target: 'task_a',
        message: 'Wait your turn.',
      );
      expect(fakeRuntime.started, isEmpty);
      await database.sessionDao.create(blockers.first);
      await service.onTurnFinished(
        sessionId: blockers.first.id,
        outcome: TurnStatus.completed,
        finalText: 'Done.',
      );
      expect(
        fakeRuntime.started.map((call) => call.sessionId),
        contains(child.id),
      );
    });
  });

  group('waitAgent', () {
    test('returns immediately when mail is already queued', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      await service.sendMessage(caller: child, target: '/root', message: 'x');
      final result = await service.waitAgent(
        caller: root,
        cancellation: CancellationToken(),
      );
      expect(result.outcome, WaitAgentOutcome.mail);
      expect(result.timedOut, isFalse);
    });

    test('wakes on mail arriving mid-wait', () async {
      final root = await database.sessionDao.create(session('root'));
      final child = await database.sessionDao.create(
        session(
          'child',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
        ),
      );
      final wait = service.waitAgent(
        caller: root,
        cancellation: CancellationToken(),
        timeoutMs: maxWaitTimeoutMs,
      );
      await Future<void>.delayed(Duration.zero);
      await service.sendMessage(
        caller: child,
        target: '/root',
        message: 'Wake up.',
      );
      final result = await wait;
      expect(result.outcome, WaitAgentOutcome.mail);
    });

    test('wakes on user steering input', () async {
      final root = await database.sessionDao.create(session('root'));
      final wait = service.waitAgent(
        caller: root,
        cancellation: CancellationToken(),
        timeoutMs: maxWaitTimeoutMs,
      );
      await Future<void>.delayed(Duration.zero);
      fakeRuntime.steer[root.id]?.complete();
      final result = await wait;
      expect(result.outcome, WaitAgentOutcome.steer);
      expect(result.timedOut, isFalse);
    });

    test('times out and validates the timeout range', () async {
      final root = await database.sessionDao.create(session('root'));
      final result = await service.waitAgent(
        caller: root,
        cancellation: CancellationToken(),
        timeoutMs: minWaitTimeoutMs,
      );
      expect(result.outcome, WaitAgentOutcome.timeout);
      expect(result.timedOut, isTrue);
      await expectLater(
        service.waitAgent(
          caller: root,
          cancellation: CancellationToken(),
          timeoutMs: minWaitTimeoutMs - 1,
        ),
        throwsA(isA<CollaborationException>()),
      );
      await expectLater(
        service.waitAgent(
          caller: root,
          cancellation: CancellationToken(),
          timeoutMs: maxWaitTimeoutMs + 1,
        ),
        throwsA(isA<CollaborationException>()),
      );
    });
  });

  group('interrupt and list', () {
    test(
      'interrupt cancels the target turn and reports prior status',
      () async {
        final root = await database.sessionDao.create(session('root'));
        final child = await database.sessionDao.create(
          session(
            'child',
            parentSessionId: 'root',
            taskName: 'task_a',
            agentPath: '/root/task_a',
            rootSessionId: 'root',
            lifecycle: AgentLifecycle.running,
          ),
        );
        final previous = await service.interruptAgent(
          caller: root,
          target: 'task_a',
        );
        expect(previous, AgentLifecycle.running);
        expect(fakeRuntime.cancelled.single, child.id);
        await expectLater(
          service.interruptAgent(caller: root, target: '/root'),
          throwsA(isA<CollaborationException>()),
        );
        await expectLater(
          service.interruptAgent(caller: child, target: '/root/task_a'),
          throwsA(isA<CollaborationException>()),
        );
      },
    );

    test('list returns the tree with statuses and honours a prefix', () async {
      final root = await database.sessionDao.create(session('root'));
      await database.sessionDao.create(
        session(
          'child-a',
          parentSessionId: 'root',
          taskName: 'task_a',
          agentPath: '/root/task_a',
          rootSessionId: 'root',
          lifecycle: AgentLifecycle.running,
        ),
      );
      await database.sessionDao.create(
        session(
          'grandchild',
          parentSessionId: 'child-a',
          taskName: 'task_b',
          agentPath: '/root/task_a/task_b',
          rootSessionId: 'root',
          lifecycle: AgentLifecycle.completed,
        ),
      );
      final all = await service.listAgents(caller: root);
      expect(all.map((agent) => agent.agentName), <String>[
        '/root',
        '/root/task_a',
        '/root/task_a/task_b',
      ]);
      expect(all.first.agentStatus, AgentLifecycle.completed);
      expect(all[1].agentStatus, AgentLifecycle.running);
      final scoped = await service.listAgents(
        caller: root,
        pathPrefix: '/root/task_a',
      );
      expect(scoped.map((agent) => agent.agentName), <String>[
        '/root/task_a',
        '/root/task_a/task_b',
      ]);
    });
  });

  group('fork seeding', () {
    Future<SessionDto> spawnFork(String fork) async {
      final root = await database.sessionDao.create(session('root'));
      await database.timelineDao.appendProviderItems(
        root.id,
        const <ConversationItem>[
          UserConversationItem('First prompt'),
          AssistantConversationItem(
            text: 'First answer',
            toolCalls: <ConversationToolCall>[
              ConversationToolCall.function(
                callId: 'call',
                name: 'read_file',
                arguments: <String, dynamic>{'path': 'a'},
              ),
            ],
            opaqueItems: <Map<String, dynamic>>[
              <String, dynamic>{'type': 'reasoning', 'encrypted': 'secret'},
            ],
          ),
          ToolResultConversationItem(
            callId: 'call',
            output: 'contents',
            toolKind: ModelToolKind.function,
          ),
          UserConversationItem('Second prompt'),
          AssistantConversationItem(text: ''),
          AssistantConversationItem(text: 'Second answer'),
        ],
      );
      final path = await service.spawn(
        caller: root,
        callerDefinition: _tinestDefinition,
        turnId: 'turn-1',
        taskName: 'fork_task',
        message: 'Continue.',
        forkTurns: fork,
      );
      return (await database.sessionDao.getByAgentPath('root', path))!;
    }

    test('a full fork keeps prompts and answers, drops tool state', () async {
      final child = await spawnFork('all');
      final history = await database.timelineDao.providerHistory(child.id);
      expect(history.map((item) => item.runtimeType.toString()), <String>[
        'UserConversationItem',
        'AssistantConversationItem',
        'UserConversationItem',
        'AssistantConversationItem',
      ]);
      final assistant = history[1] as AssistantConversationItem;
      expect(assistant.text, 'First answer');
      expect(assistant.toolCalls, isEmpty);
      expect(assistant.opaqueItems, isEmpty);
    });

    test('a numbered fork keeps only the trailing turns', () async {
      final child = await spawnFork('1');
      final history = await database.timelineDao.providerHistory(child.id);
      expect((history.first as UserConversationItem).text, 'Second prompt');
      expect(history, hasLength(2));
    });

    test('fork none seeds nothing', () async {
      final child = await spawnFork('none');
      expect(await database.timelineDao.providerHistory(child.id), isEmpty);
    });
  });

  group('tools', () {
    test('v2 schemas require only canonical mandatory fields', () async {
      final root = await database.sessionDao.create(session('root'));
      final spawn = SpawnAgentTool(service, root, _tinestDefinition, 'turn-1');
      expect(spawn.strictJsonSchema['required'], <String>[
        'task_name',
        'message',
      ]);
      expect(
        (spawn.strictJsonSchema['properties'] as Map<String, dynamic>).keys,
        containsAll(<String>[
          'fork_turns',
          'model',
          'reasoning_effort',
          'service_tier',
        ]),
      );
      expect(
        WaitAgentTool(service, root).strictJsonSchema['required'],
        isEmpty,
      );
      expect(
        ListAgentsTool(service, root).strictJsonSchema['required'],
        isEmpty,
      );

      final tools = <AgentTool>[
        spawn,
        SendMessageTool(service, root),
        FollowupTaskTool(service, root),
        WaitAgentTool(service, root),
        InterruptAgentTool(service, root),
        ListAgentsTool(service, root),
      ];
      for (final tool in tools) {
        expect(tool.name, isNotEmpty);
        expect(tool.description, isNotEmpty, reason: tool.name);
        expect(tool.risk, AgentToolRisk.read, reason: tool.name);
        expect(tool.strictJsonSchema['type'], 'object', reason: tool.name);
        expect(
          tool.strictJsonSchema['additionalProperties'],
          isFalse,
          reason: tool.name,
        );
      }
    });

    test('surface collaboration failures as error results', () async {
      final root = await database.sessionDao.create(session('root'));
      final tool = SpawnAgentTool(service, root, _tinestDefinition, 'turn-1');
      final context = ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
        callId: 'call',
      );
      final result = await tool.execute(<String, dynamic>{
        'task_name': 'BAD NAME',
        'message': 'x',
        'agent_type': null,
        'fork_turns': null,
        'model': null,
        'reasoning_effort': null,
      }, context);
      expect(result.isError, isTrue);
      expect(
        jsonDecode(result.output),
        containsPair('error', contains('task_name')),
      );
    });

    test('only sessions with the capability or a parent get tools', () {
      final root = session('root');
      expect(
        service
            .collaborationToolsFor(root, _tinestDefinition, 'turn')
            .map((tool) => tool.name),
        <String>[
          'spawn_agent',
          'send_message',
          'followup_task',
          'wait_agent',
          'interrupt_agent',
          'list_agents',
        ],
      );
      expect(
        service.collaborationToolsFor(root, _reviewerDefinition, 'turn'),
        isEmpty,
      );
      final child = session(
        'child',
        parentSessionId: 'root',
        taskName: 'task_a',
        agentPath: '/root/task_a',
        rootSessionId: 'root',
      );
      expect(
        service.collaborationToolsFor(child, _reviewerDefinition, 'turn'),
        isNotEmpty,
      );
    });

    test('usage hints identify root and subagent roles', () {
      final root = session('root');
      expect(
        service.usageHintFor(root, _tinestDefinition),
        contains('root agent at path `/root`'),
      );
      expect(service.usageHintFor(root, _reviewerDefinition), isNull);
      final child = session(
        'child',
        parentSessionId: 'root',
        taskName: 'task_a',
        agentPath: '/root/task_a',
        rootSessionId: 'root',
      );
      expect(
        service.usageHintFor(child, _reviewerDefinition),
        contains('subagent `/root/task_a`'),
      );
    });

    test('only the root is coached to orchestrate', () {
      final root = session('root');
      final child = session(
        'child',
        parentSessionId: 'root',
        taskName: 'task_a',
        agentPath: '/root/task_a',
        rootSessionId: 'root',
      );
      final rootHint = service.usageHintFor(root, _tinestDefinition)!;
      final childHint = service.usageHintFor(child, _reviewerDefinition)!;
      // The orchestrator prompt tells its reader to delegate rather than work.
      // Handing it to a subagent makes every child spawn grandchildren and
      // wait on them, so the tree expands instead of terminating.
      expect(rootHint, contains(orchestratorPrompt));
      expect(childHint, isNot(contains(orchestratorPrompt)));
      expect(childHint, contains(subagentPrompt));
      expect(rootHint, isNot(contains(subagentPrompt)));
    });

    test('lifecycle wire names are stable', () {
      expect(AgentLifecycle.values.map(agentLifecycleWireName), <String>[
        'pending_init',
        'running',
        'interrupted',
        'completed',
        'errored',
      ]);
      expect(emitted, isNotNull);
    });
  });
}
