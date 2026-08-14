import 'dart:io';

import 'package:daemon/src/shared/infrastructure/persistence/database.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'restart interrupts running turns and cancels pending approvals',
    () async {
      final home = await Directory.systemTemp.createTemp('tinest-recovery-');
      final databasePath = '${home.path}${Platform.pathSeparator}tinest.sqlite';
      var database = TinestDatabase(databasePath);
      final now = DateTime.now().toUtc();
      await database.workspaceDao.register(
        WorkspaceDto(
          id: 'workspace',
          name: 'Workspace',
          rootPath: home.path,
          kind: WorkspaceKind.directory,
          createdAt: now,
        ),
      );
      await database.worktreeDao.upsert(
        WorktreeDto(
          id: 'worktree',
          workspaceId: 'workspace',
          name: 'Workspace',
          path: home.path,
          kind: WorktreeKind.directory,
          isTinestOwned: false,
          createdAt: now,
        ),
      );
      await database.sessionDao.create(
        SessionDto(
          id: 'agent',
          worktreeId: 'worktree',
          title: 'Agent',
          agentDefinitionId: 'tinest',
          origin: SessionOrigin.manual,
          status: SessionStatus.running,
          activeTurnId: 'turn',
          model: const ModelSelectionDto(modelId: 'local-test/test-model'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.sessionDao.createTurn(
        id: 'turn',
        sessionId: 'agent',
        prompt: 'work',
      );
      await database.timelineDao.createApproval(
        ApprovalRequestDto(
          id: 'approval',
          sessionId: 'agent',
          turnId: 'turn',
          toolCallId: 'call',
          toolName: 'run_command',
          risk: ToolRisk.command,
          arguments: const <String, dynamic>{'command': 'true'},
          status: ApprovalStatus.pending,
          createdAt: now,
        ),
      );
      await database.timelineDao.createUserQuestion(
        UserQuestionRequestDto(
          id: 'question',
          sessionId: 'agent',
          turnId: 'turn',
          toolCallId: 'ask-call',
          questions: const <UserQuestionItemDto>[
            UserQuestionItemDto(
              id: 'q1',
              header: 'Storage',
              question: 'Which store?',
              options: <UserQuestionOptionDto>[
                UserQuestionOptionDto(label: 'SQLite', description: 'Durable.'),
                UserQuestionOptionDto(label: 'Memory', description: 'Fast.'),
              ],
            ),
          ],
          status: UserQuestionStatus.pending,
          createdAt: now,
        ),
      );
      await database.close();

      database = TinestDatabase(databasePath);
      await database.runtimeDao.recoverInterruptedRuns();
      final agent = await database.sessionDao.getById('agent');
      final turn = await (database.select(
        database.turns,
      )..where((row) => row.id.equals('turn'))).getSingle();
      final approval = await (database.select(
        database.approvalRequests,
      )..where((row) => row.id.equals('approval'))).getSingle();
      final question = await (database.select(
        database.userQuestions,
      )..where((row) => row.id.equals('question'))).getSingle();

      expect(agent!.status, SessionStatus.failed);
      expect(agent.activeTurnId, isNull);
      expect(turn.status, TurnStatus.interrupted.name);
      expect(approval.status, ApprovalStatus.cancelled.name);
      // A restart never replays a tool, so an unanswered question dies with the
      // turn rather than reappearing against a session that moved on.
      expect(question.status, UserQuestionStatus.cancelled.name);
      await database.close();
      await home.delete(recursive: true);
    },
  );

  test('a question is answered once and only while it is pending', () async {
    final home = await Directory.systemTemp.createTemp('tinest-question-');
    addTearDown(() => home.delete(recursive: true));
    final database = TinestDatabase(
      '${home.path}${Platform.pathSeparator}tinest.sqlite',
    );
    addTearDown(database.close);
    final now = DateTime.now().toUtc();
    await database.workspaceDao.register(
      WorkspaceDto(
        id: 'workspace',
        name: 'Workspace',
        rootPath: home.path,
        kind: WorkspaceKind.directory,
        createdAt: now,
      ),
    );
    await database.worktreeDao.upsert(
      WorktreeDto(
        id: 'worktree',
        workspaceId: 'workspace',
        name: 'Workspace',
        path: home.path,
        kind: WorktreeKind.directory,
        isTinestOwned: false,
        createdAt: now,
      ),
    );
    await database.sessionDao.create(
      SessionDto(
        id: 'agent',
        worktreeId: 'worktree',
        title: 'Agent',
        agentDefinitionId: 'tinest',
        origin: SessionOrigin.manual,
        status: SessionStatus.running,
        activeTurnId: 'turn',
        model: const ModelSelectionDto(modelId: 'local-test/test-model'),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.sessionDao.createTurn(
      id: 'turn',
      sessionId: 'agent',
      prompt: 'work',
    );
    await database.timelineDao.createUserQuestion(
      UserQuestionRequestDto(
        id: 'question',
        sessionId: 'agent',
        turnId: 'turn',
        toolCallId: 'ask-call',
        questions: const <UserQuestionItemDto>[
          UserQuestionItemDto(
            id: 'q1',
            header: 'Storage',
            question: 'Which store?',
            options: <UserQuestionOptionDto>[
              UserQuestionOptionDto(label: 'SQLite', description: 'Durable.'),
              UserQuestionOptionDto(label: 'Memory', description: 'Fast.'),
            ],
          ),
        ],
        status: UserQuestionStatus.pending,
        createdAt: now,
      ),
    );

    const answers = <UserQuestionAnswerDto>[
      UserQuestionAnswerDto(
        questionId: 'q1',
        answer: 'Postgres',
        isFreeForm: true,
      ),
    ];
    final resolved = await database.timelineDao.answerUserQuestion(
      'question',
      UserQuestionStatus.answered,
      answers,
    );
    expect(resolved, isNotNull);
    expect(resolved!.status, UserQuestionStatus.answered);
    expect(resolved.answers, answers);
    expect(resolved.questions.single.options, hasLength(2));

    // A second answer for the same question must not overwrite the first.
    expect(
      await database.timelineDao.answerUserQuestion(
        'question',
        UserQuestionStatus.answered,
        const <UserQuestionAnswerDto>[],
      ),
      isNull,
    );
    expect(
      await database.timelineDao.answerUserQuestion(
        'missing',
        UserQuestionStatus.cancelled,
        const <UserQuestionAnswerDto>[],
      ),
      isNull,
    );
  });
}
