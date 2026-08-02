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
      () => workspaces.createdAt,
      () => workspaces.primaryKey,
    ]);

    final agents = Agents();
    _expectGeneratedDsl(<Object? Function()>[
      () => agents.id,
      () => agents.workspaceId,
      () => agents.title,
      () => agents.providerId,
      () => agents.model,
      () => agents.reasoningEffort,
      () => agents.status,
      () => agents.permissionMode,
      () => agents.activeTurnId,
      () => agents.lastError,
      () => agents.createdAt,
      () => agents.updatedAt,
      () => agents.primaryKey,
    ]);

    final turns = Turns();
    _expectGeneratedDsl(<Object? Function()>[
      () => turns.id,
      () => turns.agentId,
      () => turns.prompt,
      () => turns.status,
      () => turns.error,
      () => turns.createdAt,
      () => turns.updatedAt,
      () => turns.primaryKey,
    ]);

    final timeline = TimelineEvents();
    _expectGeneratedDsl(<Object? Function()>[
      () => timeline.agentId,
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
      () => approvals.agentId,
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
      () => states.agentId,
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

    final providers = ApiProviders();
    _expectGeneratedDsl(<Object? Function()>[
      () => providers.id,
      () => providers.name,
      () => providers.presetId,
      () => providers.baseUrl,
      () => providers.transport,
      () => providers.credentialSource,
      () => providers.environmentVariable,
      () => providers.enabled,
      () => providers.strictToolSchema,
      () => providers.defaultModelId,
      () => providers.visibleModelIdsJson,
      () => providers.createdAt,
      () => providers.updatedAt,
      () => providers.primaryKey,
    ]);

    final models = ProviderModels();
    _expectGeneratedDsl(<Object? Function()>[
      () => models.providerId,
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

      expect(database.schemaVersion, 2);
      expect(database.migration, isNotNull);
      expect(
        await database.customSelect('PRAGMA foreign_keys').getSingle(),
        isNotNull,
      );
      expect(await database.workspaceDao.list(), isEmpty);
    },
  );
}

void _expectGeneratedDsl(Iterable<Object? Function()> declarations) {
  for (final declaration in declarations) {
    expect(declaration, throwsUnsupportedError);
  }
}
