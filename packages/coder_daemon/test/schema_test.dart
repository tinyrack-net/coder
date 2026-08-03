import 'package:coder_daemon/src/database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  test('all schema tables expose their declared primary keys and columns', () {
    final workspaces = Workspaces();
    _expectGeneratedDsl(<Object? Function()>[
      () => workspaces.id,
      () => workspaces.name,
      () => workspaces.rootPath,
      () => workspaces.kind,
      () => workspaces.createdAt,
      () => workspaces.primaryKey,
    ]);

    final worktrees = Worktrees();
    _expectGeneratedDsl(<Object? Function()>[
      () => worktrees.id,
      () => worktrees.workspaceId,
      () => worktrees.name,
      () => worktrees.path,
      () => worktrees.branch,
      () => worktrees.head,
      () => worktrees.kind,
      () => worktrees.isCoderOwned,
      () => worktrees.archivedAt,
      () => worktrees.createdAt,
      () => worktrees.primaryKey,
    ]);

    final sessions = Sessions();
    _expectGeneratedDsl(<Object? Function()>[
      () => sessions.id,
      () => sessions.worktreeId,
      () => sessions.title,
      () => sessions.agentDefinitionId,
      () => sessions.origin,
      () => sessions.parentSessionId,
      () => sessions.status,
      () => sessions.activeTurnId,
      () => sessions.lastError,
      () => sessions.createdAt,
      () => sessions.updatedAt,
      () => sessions.primaryKey,
    ]);

    final turns = Turns();
    _expectGeneratedDsl(<Object? Function()>[
      () => turns.id,
      () => turns.sessionId,
      () => turns.prompt,
      () => turns.status,
      () => turns.error,
      () => turns.createdAt,
      () => turns.updatedAt,
      () => turns.primaryKey,
    ]);

    final timeline = TimelineEvents();
    _expectGeneratedDsl(<Object? Function()>[
      () => timeline.sessionId,
      () => timeline.sequence,
      () => timeline.turnId,
      () => timeline.type,
      () => timeline.dataJson,
      () => timeline.createdAt,
      () => timeline.primaryKey,
    ]);

    final approvals = ApprovalRequests();
    _expectGeneratedDsl(<Object? Function()>[
      () => approvals.id,
      () => approvals.sessionId,
      () => approvals.turnId,
      () => approvals.toolCallId,
      () => approvals.toolName,
      () => approvals.risk,
      () => approvals.argumentsJson,
      () => approvals.preview,
      () => approvals.status,
      () => approvals.createdAt,
      () => approvals.primaryKey,
    ]);

    final states = ProviderStates();
    _expectGeneratedDsl(<Object? Function()>[
      () => states.sessionId,
      () => states.ordinal,
      () => states.itemJson,
      () => states.createdAt,
      () => states.primaryKey,
    ]);

    final settings = Settings();
    _expectGeneratedDsl(<Object? Function()>[
      () => settings.key,
      () => settings.value,
      () => settings.primaryKey,
    ]);

    final providers = ProviderConnections();
    _expectGeneratedDsl(<Object? Function()>[
      () => providers.id,
      () => providers.definitionId,
      () => providers.displayName,
      () => providers.status,
      () => providers.authKind,
      () => providers.credentialOrigin,
      () => providers.isDefault,
      () => providers.defaultModelId,
      () => providers.error,
      () => providers.customConfigJson,
      () => providers.createdAt,
      () => providers.updatedAt,
      () => providers.primaryKey,
    ]);

    final models = ProviderModels();
    _expectGeneratedDsl(<Object? Function()>[
      () => models.connectionId,
      () => models.modelId,
      () => models.label,
      () => models.source,
      () => models.capabilitiesJson,
      () => models.diagnosticStatus,
      () => models.verifiedAt,
      () => models.diagnosticError,
      () => models.primaryKey,
    ]);
  });

  test(
    'database testing constructor installs schema and foreign keys',
    () async {
      final database = CoderDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      expect(database.schemaVersion, 6);
      expect(database.migration, isNotNull);
      expect(
        await database.customSelect('PRAGMA foreign_keys').getSingle(),
        isNotNull,
      );
      expect(await database.workspaceDao.list(), isEmpty);
      expect(await database.worktreeDao.list(), isEmpty);
    },
  );
}

void _expectGeneratedDsl(Iterable<Object? Function()> declarations) {
  for (final declaration in declarations) {
    expect(declaration, throwsUnsupportedError);
  }
}
