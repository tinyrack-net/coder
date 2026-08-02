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
      await database.registerWorkspace(
        WorkspaceDto(
          id: 'workspace',
          name: 'Workspace',
          rootPath: home.path,
          createdAt: now,
        ),
      );
      await database.createAgent(
        AgentDto(
          id: 'agent',
          workspaceId: 'workspace',
          title: 'Agent',
          providerId: 'openai',
          model: 'gpt-5.6-sol',
          status: AgentStatus.running,
          permissionMode: PermissionMode.ask,
          activeTurnId: 'turn',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.createTurn(id: 'turn', agentId: 'agent', prompt: 'work');
      await database.createApproval(
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
      await database.recoverInterruptedRuns();
      final agent = await database.getAgentDto('agent');
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
