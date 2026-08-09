import 'package:daemon/src/shared/infrastructure/persistence/database.dart';
import 'package:daemon/src/shared/ports/daemon_ports.dart';
import 'package:drift/native.dart';
import 'package:protocol/protocol.dart';
import 'package:test/test.dart';

void main() {
  test(
    'session cost accumulates exactly and stays unknown after unpriced usage',
    () async {
      final now = DateTime.utc(2026);
      final database = CoderDatabase.forTesting(
        NativeDatabase.memory(),
        clock: _Clock(now),
      );
      addTearDown(database.close);
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
          isCoderOwned: false,
          createdAt: now,
        ),
      );
      await database.sessionDao.create(
        SessionDto(
          id: 'session',
          worktreeId: 'worktree',
          title: 'Session',
          agentDefinitionId: 'coder',
          origin: SessionOrigin.manual,
          status: SessionStatus.idle,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final priced = await database.sessionDao.recordContextTokens(
        'session',
        100,
        usageCostUsd: 0.25,
      );
      expect(priced.totalCostUsd, 0.25);
      final unknown = await database.sessionDao.recordContextTokens(
        'session',
        200,
        usageCostUsd: null,
      );
      expect(unknown.totalCostUsd, isNull);
      final stillUnknown = await database.sessionDao.recordContextTokens(
        'session',
        300,
        usageCostUsd: 0.5,
      );
      expect(stillUnknown.totalCostUsd, isNull);
      expect(stillUnknown.contextTokens, 300);
    },
    tags: const <String>['feature_test__tool_context_budget__unit'],
  );
}

final class _Clock implements Clock {
  const _Clock(this.now);
  final DateTime now;

  @override
  DateTime nowUtc() => now;
}
