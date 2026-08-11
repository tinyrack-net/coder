import 'dart:convert';

import 'package:agent/agent.dart';
import 'package:daemon/src/features/sessions/infrastructure/goal_service.dart';
import 'package:daemon/src/features/sessions/infrastructure/goal_tools.dart';
import 'package:daemon/src/features/sessions/infrastructure/multi_agent.dart';
import 'package:daemon/src/shared/infrastructure/persistence/database.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:daemon/src/transport/rpc/binding.dart';
import 'package:drift/native.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

final class _Clock implements Clock {
  _Clock(this.value);

  DateTime value;

  @override
  DateTime nowUtc() => value;
}

final class _Ids implements IdGenerator {
  int next = 0;

  @override
  String generate() => 'goal-${++next}';
}

final class _Runtime implements SessionTurnPort {
  final List<({String sessionId, String turnId, bool internal})> starts = [];

  @override
  Future<bool> startTurn({
    required String sessionId,
    required String turnId,
    required String prompt,
    bool internal = false,
  }) async {
    starts.add((sessionId: sessionId, turnId: turnId, internal: internal));
    return true;
  }

  @override
  Future<void> cancelTurn(String sessionId) async {}

  @override
  bool hasActiveTurn(String sessionId) => false;

  @override
  Future<void> pendingInput(String sessionId) async {}
}

void main() {
  final now = DateTime.utc(2026, 8, 8);
  late TinestDatabase database;
  late _Clock clock;
  late SessionGoalService service;
  late List<OutboundNotification> events;

  setUp(() async {
    clock = _Clock(now);
    database = TinestDatabase.forTesting(
      NativeDatabase.memory(),
      clock: clock,
    );
    events = <OutboundNotification>[];
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
    await database.sessionDao.create(
      SessionDto(
        id: 'root',
        worktreeId: 'worktree',
        title: 'Root',
        agentDefinitionId: 'tinest',
        origin: SessionOrigin.manual,
        status: SessionStatus.idle,
        createdAt: now,
        updatedAt: now,
      ),
    );
    service = SessionGoalService(
      goals: database.goalDao,
      sessions: database.sessionDao,
      ids: _Ids(),
      clock: clock,
      events: events.add,
      hasPendingInput: (_) => false,
    );
  });

  tearDown(() => database.close());

  test(
    'replace, CAS patch, usage boundary, and clear are atomic',
    () async {
      final first = await service.replace(
        sessionId: 'root',
        objective: '  finish <all> & verify  ',
        tokenBudget: 100,
      );
      expect(first.objective, 'finish <all> & verify');
      expect(first.goalId, 'goal-1');

      expect(
        await database.goalDao.updateGoal(
          'root',
          const GoalUpdateDto(
            expectedGoalId: 'stale',
            status: GoalStatus.paused,
          ),
        ),
        isNull,
      );
      await service.accountUsage(
        'root',
        const ModelUsage(
          inputTokens: 90,
          cachedInputTokens: 20,
          outputTokens: 30,
        ),
      );
      final limited = await service.get('root');
      expect(limited?.tokensUsed, 100);
      expect(limited?.status, GoalStatus.budgetLimited);
      expect(await service.clear('root'), isTrue);
      expect(await service.get('root'), isNull);
      expect(events.last.notification, sessionsGoalClearedNotification);
    },
    tags: const <String>['feature_test__session_goal__unit'],
  );

  test(
    'validation, terminal updates, XML escaping, and root eligibility hold',
    () async {
      expect(
        () => service.replace(sessionId: 'root', objective: ' '),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => service.replace(
          sessionId: 'root',
          objective: 'valid',
          tokenBudget: 0,
        ),
        throwsA(isA<FormatException>()),
      );
      final goal = await service.replace(
        sessionId: 'root',
        objective: '<ship> & test',
      );
      final instructions = await service.instructionsFor('root');
      expect(instructions, contains('&lt;ship&gt; &amp; test'));
      final complete = await service.updateFromAgent(
        sessionId: 'root',
        status: GoalStatus.complete,
      );
      expect(complete.goalId, goal.goalId);
      expect(complete.status, GoalStatus.complete);
    },
    tags: const <String>['feature_test__session_goal__unit'],
  );

  test(
    'agent tools reject replacement and premature blocked status',
    () async {
      final goal = await service.createFromAgent(
        sessionId: 'root',
        objective: 'Finish safely',
      );
      await expectLater(
        service.createFromAgent(
          sessionId: 'root',
          objective: 'Replace unfinished work',
        ),
        throwsA(isA<StateError>()),
      );
      final tool = UpdateGoalTool(service, 'root');
      final context = ToolExecutionContext(
        workspaceRoot: '/workspace',
        cancellation: CancellationToken(),
      );
      final early = await tool.execute(
        const <String, dynamic>{'status': 'blocked'},
        context,
      );
      expect(early.isError, isTrue);

      final session = (await database.sessionDao.getById('root'))!;
      for (var turn = 0; turn < 3; turn += 1) {
        await service.onTurnStarted(session, internal: true);
      }
      final blocked = await tool.execute(
        const <String, dynamic>{'status': 'blocked'},
        context,
      );
      expect(blocked.isError, isFalse);
      final decoded = jsonDecode(blocked.output) as Map<String, dynamic>;
      expect(
        (decoded['goal'] as Map<String, dynamic>)['status'],
        GoalStatus.blocked.name,
      );
      expect((await service.get('root'))?.goalId, goal.goalId);
    },
    tags: const <String>['feature_test__session_goal__unit'],
  );

  test(
    'budgeted completion returns the modern completion report',
    () async {
      await service.createFromAgent(
        sessionId: 'root',
        objective: 'Finish safely',
        tokenBudget: 1000,
      );
      final result = await UpdateGoalTool(service, 'root').execute(
        const <String, dynamic>{'status': 'complete'},
        ToolExecutionContext(
          workspaceRoot: '/workspace',
          cancellation: CancellationToken(),
        ),
      );
      final decoded = jsonDecode(result.output) as Map<String, dynamic>;
      expect(decoded['remainingTokens'], 1000);
      expect(decoded['completionBudgetReport'], contains('Goal achieved'));
    },
    tags: const <String>['feature_test__session_goal__unit'],
  );

  test(
    'continuation respects plan mode and queued user input',
    () async {
      var pending = true;
      final local = SessionGoalService(
        goals: database.goalDao,
        sessions: database.sessionDao,
        ids: _Ids(),
        clock: clock,
        events: events.add,
        hasPendingInput: (_) => pending,
      );
      final runtime = _Runtime();
      local.runtime = runtime;
      await local.replace(sessionId: 'root', objective: 'Continue');
      await Future<void>.delayed(Duration.zero);
      expect(runtime.starts, isEmpty);

      pending = false;
      await database.sessionDao.updateMode('root', SessionMode.plan);
      await local.reconsider('root');
      await Future<void>.delayed(Duration.zero);
      expect(runtime.starts, isEmpty);

      await database.sessionDao.updateMode('root', SessionMode.normal);
      await local.reconsider('root');
      await Future<void>.delayed(Duration.zero);
      expect(runtime.starts, hasLength(1));
      expect(runtime.starts.single.internal, isTrue);

      // A fresh goal can recover a session whose previous, unrelated turn
      // failed; startTurn transitions it back to running.
      await database.sessionDao.updateStatus(
        'root',
        SessionStatus.failed,
        error: 'previous turn failed',
      );
      await local.reconsider('root');
      await Future<void>.delayed(Duration.zero);
      expect(runtime.starts, hasLength(2));
    },
    tags: const <String>['feature_test__session_goal__unit'],
  );
}
