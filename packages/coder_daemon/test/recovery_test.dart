import 'dart:io';

import 'package:coder_daemon/src/database.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'restart interrupts running turns and cancels pending approvals',
    () async {
      final home = await Directory.systemTemp.createTemp('coder-recovery-');
      final databasePath = '${home.path}${Platform.pathSeparator}coder.sqlite';
      var database = CoderDatabase(databasePath);
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
          isCoderOwned: false,
          createdAt: now,
        ),
      );
      await database.sessionDao.create(
        SessionDto(
          id: 'agent',
          worktreeId: 'worktree',
          title: 'Agent',
          agentDefinitionId: 'coder',
          origin: SessionOrigin.manual,
          status: SessionStatus.running,
          activeTurnId: 'turn',
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
      await database.close();

      database = CoderDatabase(databasePath);
      await database.runtimeDao.recoverInterruptedRuns();
      final agent = await database.sessionDao.getById('agent');
      final turn = await (database.select(
        database.turns,
      )..where((row) => row.id.equals('turn'))).getSingle();
      final approval = await (database.select(
        database.approvalRequests,
      )..where((row) => row.id.equals('approval'))).getSingle();

      expect(agent!.status, SessionStatus.failed);
      expect(agent.activeTurnId, isNull);
      expect(turn.status, TurnStatus.interrupted.name);
      expect(approval.status, ApprovalStatus.cancelled.name);
      await database.close();
      await home.delete(recursive: true);
    },
  );
}
