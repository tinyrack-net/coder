import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('v4 exposes one genuinely typed procedure catalog', () {
    expect(coderProtocolMajor, 4);
    expect(coderProtocolRevision, 1);
    expect(rpcProcedures.map((procedure) => procedure.name), isNotEmpty);
    expect(
      rpcProcedures.map((procedure) => procedure.name).toSet(),
      hasLength(rpcProcedures.length),
    );
    expect(systemHelloProcedure.name, 'system.hello');
    expect(systemHelloProcedure.paramsType, HelloParamsDto);
    expect(systemHelloProcedure.resultType, ServerInfoDto);
    expect(
      systemHelloProcedure.decodeParams(
        const HelloParamsDto(
          clientId: 'client',
          clientKind: 'test',
          protocolMajor: 4,
          clientVersion: '1.0.0',
          capabilities: <String, bool>{},
        ).toJson(),
      ),
      isA<HelloParamsDto>(),
    );
    expect(
      rpcProcedures.where(
        (procedure) =>
            procedure.paramsType.toString().startsWith('Map<') ||
            procedure.resultType.toString().startsWith('Map<'),
      ),
      isEmpty,
    );
  });

  test('v4 notification names use plural feature namespaces', () {
    expect(
      rpcNotifications.map((notification) => notification.name),
      containsAll(<String>[
        'sessions.updated',
        'sessions.goalUpdated',
        'sessions.goalCleared',
        'terminals.output',
        'providers.authUpdated',
      ]),
    );
  });

  test(
    'session goal contract preserves nullable budgets and lifecycle values',
    () {
      final goal = GoalDto(
        sessionId: 'session-1',
        goalId: 'goal-1',
        objective: 'Ship the feature',
        status: GoalStatus.active,
        tokenBudget: 12000,
        tokensUsed: 345,
        timeUsedSeconds: 67,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      expect(GoalDto.fromJson(goal.toJson()), goal);
      expect(
        GoalUpdateDto.fromJson(
          const GoalUpdateDto(
            expectedGoalId: 'goal-1',
            hasTokenBudget: true,
          ).toJson(),
        ).hasTokenBudget,
        isTrue,
      );
      expect(sessionsGetGoalProcedure.name, 'sessions.getGoal');
      expect(sessionsReplaceGoalProcedure.name, 'sessions.replaceGoal');
      expect(sessionsUpdateGoalProcedure.name, 'sessions.updateGoal');
      expect(sessionsClearGoalProcedure.name, 'sessions.clearGoal');
    },
    tags: const <String>['feature_test__session_goal__contract'],
  );
}
