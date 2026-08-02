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
          createdAt: now,
        ),
      );
      await database.agentDao.create(
        AgentDto(
          id: 'agent',
          workspaceId: 'workspace',
          title: 'Agent',
          providerConnectionId: 'openai',
          model: 'gpt-5.6-sol',
          status: AgentStatus.running,
          permissionMode: PermissionMode.ask,
          activeTurnId: 'turn',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.agentDao.createTurn(
        id: 'turn',
        agentId: 'agent',
        prompt: 'work',
      );
      await database.timelineDao.createApproval(
        ApprovalRequestDto(
          id: 'approval',
          agentId: 'agent',
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
      final agent = await database.agentDao.getById('agent');
      final turn = await (database.select(
        database.turns,
      )..where((row) => row.id.equals('turn'))).getSingle();
      final approval = await (database.select(
        database.approvalRequests,
      )..where((row) => row.id.equals('approval'))).getSingle();

      expect(agent!.status, AgentStatus.failed);
      expect(agent.activeTurnId, isNull);
      expect(turn.status, TurnStatus.interrupted.name);
      expect(approval.status, ApprovalStatus.cancelled.name);
      await database.close();
      await home.delete(recursive: true);
    },
  );
}
