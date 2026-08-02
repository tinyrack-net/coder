import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get rootPath => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Agents extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId => text().references(Workspaces, #id)();
  TextColumn get title => text()();
  TextColumn get providerId => text()();
  TextColumn get model => text()();
  TextColumn get reasoningEffort =>
      text().withDefault(const Constant('medium'))();
  TextColumn get status => text()();
  TextColumn get permissionMode => text()();
  TextColumn get activeTurnId => text().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Turns extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text().references(Agents, #id)();
  TextColumn get prompt => text()();
  TextColumn get status => text()();
  TextColumn get error => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class TimelineEvents extends Table {
  TextColumn get agentId => text().references(Agents, #id)();
  IntColumn get sequence => integer()();
  TextColumn get turnId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{agentId, sequence};
}

class ApprovalRequests extends Table {
  TextColumn get id => text()();
  TextColumn get agentId => text().references(Agents, #id)();
  TextColumn get turnId => text().references(Turns, #id)();
  TextColumn get toolCallId => text()();
  TextColumn get toolName => text()();
  TextColumn get risk => text()();
  TextColumn get argumentsJson => text()();
  TextColumn get preview => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class ProviderStates extends Table {
  TextColumn get agentId => text().references(Agents, #id)();
  IntColumn get ordinal => integer()();
  TextColumn get itemJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{agentId, ordinal};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

class ApiProviders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get presetId => text()();
  TextColumn get baseUrl => text()();
  TextColumn get transport => text()();
  TextColumn get credentialSource => text()();
  TextColumn get environmentVariable => text().nullable()();
  BoolColumn get enabled => boolean()();
  BoolColumn get strictToolSchema => boolean()();
  TextColumn get defaultModelId => text().nullable()();
  TextColumn get visibleModelIdsJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class ProviderModels extends Table {
  TextColumn get providerId => text().references(ApiProviders, #id)();
  TextColumn get modelId => text()();
  TextColumn get label => text()();
  TextColumn get source => text()();
  TextColumn get capabilitiesJson => text()();
  TextColumn get diagnosticStatus =>
      text().withDefault(const Constant('unknown'))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  TextColumn get diagnosticError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{providerId, modelId};
}

@DriftDatabase(
  tables: <Type>[
    Workspaces,
    Agents,
    Turns,
    TimelineEvents,
    ApprovalRequests,
    ProviderStates,
    Settings,
    ApiProviders,
    ProviderModels,
  ],
)
class CoderDatabase extends _$CoderDatabase {
  CoderDatabase(String path)
    : super(NativeDatabase.createInBackground(File(path)));

  CoderDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        await migrator.addColumn(agents, agents.reasoningEffort);
        await migrator.createTable(apiProviders);
        await migrator.createTable(providerModels);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> recoverInterruptedRuns() async {
    final now = DateTime.now().toUtc();
    await transaction(() async {
      await (update(turns)..where(
            (row) => row.status.isIn(<String>[
              TurnStatus.running.name,
              TurnStatus.waitingForApproval.name,
            ]),
          ))
          .write(
            TurnsCompanion(
              status: Value<String>(TurnStatus.interrupted.name),
              error: const Value<String?>('Daemon restarted during the turn.'),
              updatedAt: Value<DateTime>(now),
            ),
          );
      await (update(agents)..where(
            (row) => row.status.isIn(<String>[
              AgentStatus.running.name,
              AgentStatus.waitingForApproval.name,
              AgentStatus.initializing.name,
            ]),
          ))
          .write(
            AgentsCompanion(
              status: Value<String>(AgentStatus.failed.name),
              activeTurnId: const Value<String?>(null),
              lastError: const Value<String?>(
                'Daemon restarted during the turn.',
              ),
              updatedAt: Value<DateTime>(now),
            ),
          );
      await (update(
        approvalRequests,
      )..where((row) => row.status.equals(ApprovalStatus.pending.name))).write(
        ApprovalRequestsCompanion(
          status: Value<String>(ApprovalStatus.cancelled.name),
        ),
      );
    });
  }

  Future<String?> getSetting(String key) async => (await (select(
    settings,
  )..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) => into(
    settings,
  ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  Future<List<WorkspaceDto>> listWorkspaceDtos() async =>
      (await (select(workspaces)
                ..orderBy(<OrderClauseGenerator<$WorkspacesTable>>[
                  (row) => OrderingTerm.asc(row.name),
                ]))
              .get())
          .map(_workspaceDto)
          .toList(growable: false);

  Future<WorkspaceDto?> getWorkspaceDto(String id) async {
    final row = await (select(
      workspaces,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _workspaceDto(row);
  }

  Future<WorkspaceDto> registerWorkspace(WorkspaceDto workspace) async {
    final existing = await getWorkspaceDto(workspace.id);
    if (existing != null) return existing;
    await into(workspaces).insert(
      WorkspacesCompanion.insert(
        id: workspace.id,
        name: workspace.name,
        rootPath: workspace.rootPath,
        createdAt: workspace.createdAt,
      ),
    );
    return workspace;
  }

  Future<List<AgentDto>> listAgentDtos({String? workspaceId}) async {
    final query = select(agents);
    if (workspaceId != null)
      query.where((row) => row.workspaceId.equals(workspaceId));
    query.orderBy(<OrderClauseGenerator<$AgentsTable>>[
      (row) => OrderingTerm.desc(row.updatedAt),
    ]);
    return (await query.get()).map(_agentDto).toList(growable: false);
  }

  Future<AgentDto?> getAgentDto(String id) async {
    final row = await (select(
      agents,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _agentDto(row);
  }

  Future<AgentDto> createAgent(AgentDto agent) async {
    final existing = await getAgentDto(agent.id);
    if (existing != null) return existing;
    await into(agents).insert(
      AgentsCompanion.insert(
        id: agent.id,
        workspaceId: agent.workspaceId,
        title: agent.title,
        providerId: agent.providerId,
        model: agent.model,
        reasoningEffort: Value<String>(agent.reasoningEffort),
        status: agent.status.name,
        permissionMode: agent.permissionMode.name,
        activeTurnId: Value<String?>(agent.activeTurnId),
        lastError: Value<String?>(agent.lastError),
        createdAt: agent.createdAt,
        updatedAt: agent.updatedAt,
      ),
    );
    return agent;
  }

  Future<AgentDto> updateAgentStatus(
    String id,
    AgentStatus status, {
    String? activeTurnId,
    String? error,
  }) async {
    await (update(agents)..where((row) => row.id.equals(id))).write(
      AgentsCompanion(
        status: Value<String>(status.name),
        activeTurnId: Value<String?>(activeTurnId),
        lastError: Value<String?>(error),
        updatedAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
    return (await getAgentDto(id))!;
  }

  Future<bool> agentHasTurns(String agentId) async {
    final count = turns.id.count();
    final query = selectOnly(turns)
      ..addColumns(<Expression<Object>>[count])
      ..where(turns.agentId.equals(agentId));
    return (await query.getSingle()).read(count)! > 0;
  }

  Future<AgentDto> updateAgentConfiguration({
    required String id,
    required String providerId,
    required String model,
    required String reasoningEffort,
  }) async {
    if (await agentHasTurns(id)) {
      throw StateError(
        'Agent provider and model are locked after the first turn.',
      );
    }
    await (update(agents)..where((row) => row.id.equals(id))).write(
      AgentsCompanion(
        providerId: Value<String>(providerId),
        model: Value<String>(model),
        reasoningEffort: Value<String>(reasoningEffort),
        updatedAt: Value<DateTime>(DateTime.now().toUtc()),
      ),
    );
    return (await getAgentDto(id))!;
  }

  Future<bool> createTurn({
    required String id,
    required String agentId,
    required String prompt,
  }) async {
    final exists = await (select(
      turns,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (exists != null) return false;
    final now = DateTime.now().toUtc();
    await into(turns).insert(
      TurnsCompanion.insert(
        id: id,
        agentId: agentId,
        prompt: prompt,
        status: TurnStatus.running.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return true;
  }

  Future<void> updateTurn(String id, TurnStatus status, {String? error}) =>
      (update(turns)..where((row) => row.id.equals(id))).write(
        TurnsCompanion(
          status: Value<String>(status.name),
          error: Value<String?>(error),
          updatedAt: Value<DateTime>(DateTime.now().toUtc()),
        ),
      );

  Future<TimelineEventDto> appendTimeline({
    required String agentId,
    required String type,
    required Map<String, dynamic> data,
    String? turnId,
  }) => transaction(() async {
    final maxSequence = timelineEvents.sequence.max();
    final query = selectOnly(timelineEvents)
      ..addColumns(<Expression<Object>>[maxSequence])
      ..where(timelineEvents.agentId.equals(agentId));
    final current = (await query.getSingle()).read(maxSequence) ?? 0;
    final event = TimelineEventDto(
      agentId: agentId,
      sequence: current + 1,
      turnId: turnId,
      type: type,
      data: data,
      createdAt: DateTime.now().toUtc(),
    );
    await into(timelineEvents).insert(
      TimelineEventsCompanion.insert(
        agentId: event.agentId,
        sequence: event.sequence,
        turnId: Value<String?>(event.turnId),
        type: event.type,
        dataJson: jsonEncode(event.data),
        createdAt: event.createdAt,
      ),
    );
    return event;
  });

  Future<List<TimelineEventDto>> timelineAfter(
    String agentId,
    int sequence,
  ) async =>
      (await (select(timelineEvents)
                ..where(
                  (row) =>
                      row.agentId.equals(agentId) &
                      row.sequence.isBiggerThanValue(sequence),
                )
                ..orderBy(<OrderClauseGenerator<$TimelineEventsTable>>[
                  (row) => OrderingTerm.asc(row.sequence),
                ]))
              .get())
          .map(
            (row) => TimelineEventDto(
              agentId: row.agentId,
              sequence: row.sequence,
              turnId: row.turnId,
              type: row.type,
              data: Map<String, dynamic>.from(jsonDecode(row.dataJson) as Map),
              createdAt: row.createdAt,
            ),
          )
          .toList(growable: false);

  Future<void> appendProviderItems(
    String agentId,
    List<ConversationItem> items,
  ) async {
    if (items.isEmpty) return;
    await transaction(() async {
      final maxOrdinal = providerStates.ordinal.max();
      final query = selectOnly(providerStates)
        ..addColumns(<Expression<Object>>[maxOrdinal])
        ..where(providerStates.agentId.equals(agentId));
      var ordinal = (await query.getSingle()).read(maxOrdinal) ?? 0;
      for (final item in items) {
        ordinal += 1;
        await into(providerStates).insert(
          ProviderStatesCompanion.insert(
            agentId: agentId,
            ordinal: ordinal,
            itemJson: jsonEncode(item.toJson()),
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
    });
  }

  Future<List<ConversationItem>> providerHistory(String agentId) async =>
      (await (select(providerStates)
                ..where((row) => row.agentId.equals(agentId))
                ..orderBy(<OrderClauseGenerator<$ProviderStatesTable>>[
                  (row) => OrderingTerm.asc(row.ordinal),
                ]))
              .get())
          .map(
            (row) => ConversationItem.fromJson(
              Map<String, dynamic>.from(jsonDecode(row.itemJson) as Map),
            ),
          )
          .toList(growable: false);

  Future<List<ApiProviderDto>> listProviderDtos() async =>
      (await (select(apiProviders)
                ..orderBy(<OrderClauseGenerator<$ApiProvidersTable>>[
                  (row) => OrderingTerm.asc(row.name),
                ]))
              .get())
          .map(_providerDto)
          .toList(growable: false);

  Future<ApiProviderDto?> getProviderDto(String id) async {
    final row = await (select(
      apiProviders,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _providerDto(row);
  }

  Future<ApiProviderDto> upsertProvider(ApiProviderDto provider) async {
    await into(apiProviders).insertOnConflictUpdate(
      ApiProvidersCompanion.insert(
        id: provider.id,
        name: provider.name,
        presetId: provider.presetId,
        baseUrl: provider.baseUrl,
        transport: provider.transport.name,
        credentialSource: provider.credentialSource.name,
        environmentVariable: Value<String?>(provider.environmentVariable),
        enabled: provider.enabled,
        strictToolSchema: provider.strictToolSchema,
        defaultModelId: Value<String?>(provider.defaultModelId),
        visibleModelIdsJson: Value<String>(
          jsonEncode(provider.visibleModelIds),
        ),
        createdAt: provider.createdAt,
        updatedAt: provider.updatedAt,
      ),
    );
    return (await getProviderDto(provider.id))!;
  }

  Future<void> deleteProvider(String id) async {
    final count = agents.id.count();
    final query = selectOnly(agents)
      ..addColumns(<Expression<Object>>[count])
      ..where(agents.providerId.equals(id));
    if ((await query.getSingle()).read(count)! > 0) {
      throw StateError('Provider is referenced by one or more agents.');
    }
    await transaction(() async {
      await (delete(
        providerModels,
      )..where((row) => row.providerId.equals(id))).go();
      await (delete(apiProviders)..where((row) => row.id.equals(id))).go();
    });
  }

  Future<List<ProviderModelDto>> listProviderModelDtos(
    String providerId,
  ) async =>
      (await (select(providerModels)
                ..where((row) => row.providerId.equals(providerId))
                ..orderBy(<OrderClauseGenerator<$ProviderModelsTable>>[
                  (row) => OrderingTerm.asc(row.label),
                ]))
              .get())
          .map(_providerModelDto)
          .toList(growable: false);

  Future<ProviderModelDto?> getProviderModelDto(
    String providerId,
    String modelId,
  ) async {
    final row =
        await (select(providerModels)..where(
              (table) =>
                  table.providerId.equals(providerId) &
                  table.modelId.equals(modelId),
            ))
            .getSingleOrNull();
    return row == null ? null : _providerModelDto(row);
  }

  Future<ProviderModelDto> upsertProviderModel(ProviderModelDto model) async {
    await into(providerModels).insertOnConflictUpdate(
      ProviderModelsCompanion.insert(
        providerId: model.providerId,
        modelId: model.id,
        label: model.label,
        source: model.source.name,
        capabilitiesJson: jsonEncode(model.capabilities.toJson()),
        diagnosticStatus: Value<String>(model.diagnosticStatus.name),
        verifiedAt: Value<DateTime?>(model.verifiedAt),
        diagnosticError: Value<String?>(model.diagnosticError),
      ),
    );
    return (await getProviderModelDto(model.providerId, model.id))!;
  }

  Future<void> replaceDiscoveredModels(
    String providerId,
    Iterable<ProviderModelDto> models,
  ) async {
    final existingModels = <String, ProviderModelDto>{
      for (final model in await listProviderModelDtos(providerId))
        model.id: model,
    };
    await transaction(() async {
      await (delete(providerModels)..where(
            (row) =>
                row.providerId.equals(providerId) &
                row.source.equals(ProviderModelSource.discovered.name),
          ))
          .go();
      for (final model in models) {
        final existing = existingModels[model.id];
        if (existing?.source == ProviderModelSource.manual ||
            existing?.source == ProviderModelSource.preset) {
          continue;
        }
        await upsertProviderModel(
          existing != null &&
                  existing.diagnosticStatus != DiagnosticStatus.unknown
              ? model.copyWith(
                  capabilities: existing.capabilities,
                  diagnosticStatus: existing.diagnosticStatus,
                  verifiedAt: existing.verifiedAt,
                  diagnosticError: existing.diagnosticError,
                )
              : model,
        );
      }
    });
  }

  Future<void> deleteProviderModel(String providerId, String modelId) =>
      (delete(providerModels)..where(
            (row) =>
                row.providerId.equals(providerId) & row.modelId.equals(modelId),
          ))
          .go();

  Future<void> createApproval(ApprovalRequestDto approval) =>
      into(approvalRequests).insert(
        ApprovalRequestsCompanion.insert(
          id: approval.id,
          agentId: approval.agentId,
          turnId: approval.turnId,
          toolCallId: approval.toolCallId,
          toolName: approval.toolName,
          risk: approval.risk.name,
          argumentsJson: jsonEncode(approval.arguments),
          preview: Value<String?>(approval.preview),
          status: approval.status.name,
          createdAt: approval.createdAt,
        ),
      );

  Future<ApprovalRequestDto?> resolveApproval(
    String id,
    ApprovalStatus status,
  ) async {
    final row = await (select(
      approvalRequests,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null || row.status != ApprovalStatus.pending.name) return null;
    await (update(approvalRequests)..where((table) => table.id.equals(id)))
        .write(ApprovalRequestsCompanion(status: Value<String>(status.name)));
    return ApprovalRequestDto(
      id: row.id,
      agentId: row.agentId,
      turnId: row.turnId,
      toolCallId: row.toolCallId,
      toolName: row.toolName,
      risk: ToolRisk.values.byName(row.risk),
      arguments: Map<String, dynamic>.from(
        jsonDecode(row.argumentsJson) as Map,
      ),
      status: status,
      createdAt: row.createdAt,
      preview: row.preview,
    );
  }

  WorkspaceDto _workspaceDto(Workspace row) => WorkspaceDto(
    id: row.id,
    name: row.name,
    rootPath: row.rootPath,
    createdAt: row.createdAt,
  );

  AgentDto _agentDto(Agent row) => AgentDto(
    id: row.id,
    workspaceId: row.workspaceId,
    title: row.title,
    providerId: row.providerId,
    model: row.model,
    reasoningEffort: row.reasoningEffort,
    status: AgentStatus.values.byName(row.status),
    permissionMode: PermissionMode.values.byName(row.permissionMode),
    activeTurnId: row.activeTurnId,
    lastError: row.lastError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ApiProviderDto _providerDto(ApiProvider row) => ApiProviderDto(
    id: row.id,
    name: row.name,
    presetId: row.presetId,
    baseUrl: row.baseUrl,
    transport: ApiTransport.values.byName(row.transport),
    credentialSource: CredentialSource.values.byName(row.credentialSource),
    credentialConfigured: false,
    enabled: row.enabled,
    strictToolSchema: row.strictToolSchema,
    environmentVariable: row.environmentVariable,
    defaultModelId: row.defaultModelId,
    visibleModelIds: (jsonDecode(row.visibleModelIdsJson) as List)
        .whereType<String>()
        .toList(growable: false),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ProviderModelDto _providerModelDto(ProviderModel row) => ProviderModelDto(
    providerId: row.providerId,
    id: row.modelId,
    label: row.label,
    source: ProviderModelSource.values.byName(row.source),
    capabilities: ModelCapabilitiesDto.fromJson(
      Map<String, dynamic>.from(jsonDecode(row.capabilitiesJson) as Map),
    ),
    diagnosticStatus: DiagnosticStatus.values.byName(row.diagnosticStatus),
    verifiedAt: row.verifiedAt,
    diagnosticError: row.diagnosticError,
  );
}
