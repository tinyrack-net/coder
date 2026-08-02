import 'dart:convert';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/database.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:drift/drift.dart';

part 'daos.g.dart';

@DriftAccessor(tables: <Type>[Settings])
/// SettingsDao defines a public contract.
class SettingsDao extends DatabaseAccessor<CoderDatabase>
    with _$SettingsDaoMixin
    implements SettingsRepository {
  /// Creates a [SettingsDao].
  SettingsDao(super.attachedDatabase);

  @override
  Future<String?> getValue(String key) async => (await (select(
    settings,
  )..where((row) => row.key.equals(key))).getSingleOrNull())?.value;

  @override
  Future<void> setValue(String key, String value) => into(
    settings,
  ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}

@DriftAccessor(tables: <Type>[Workspaces])
/// WorkspaceDao defines a public contract.
class WorkspaceDao extends DatabaseAccessor<CoderDatabase>
    with _$WorkspaceDaoMixin
    implements WorkspaceRepository {
  /// Creates a [WorkspaceDao].
  WorkspaceDao(super.attachedDatabase);

  @override
  Future<List<WorkspaceDto>> list() async =>
      (await (select(workspaces)
                ..orderBy(<OrderClauseGenerator<$WorkspacesTable>>[
                  (row) => OrderingTerm.asc(row.name),
                ]))
              .get())
          .map(_toDto)
          .toList(growable: false);

  @override
  Future<WorkspaceDto?> getById(String id) async {
    final row = await (select(
      workspaces,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDto(row);
  }

  @override
  Future<WorkspaceDto> register(WorkspaceDto workspace) async {
    final existing = await getById(workspace.id);
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

  WorkspaceDto _toDto(Workspace row) => WorkspaceDto(
    id: row.id,
    name: row.name,
    rootPath: row.rootPath,
    createdAt: row.createdAt,
  );
}

@DriftAccessor(tables: <Type>[Agents, Turns])
/// AgentDao defines a public contract.
class AgentDao extends DatabaseAccessor<CoderDatabase>
    with _$AgentDaoMixin
    implements AgentRepository {
  /// Creates a [AgentDao].
  AgentDao(super.attachedDatabase);

  @override
  Future<List<AgentDto>> list({String? workspaceId}) async {
    final query = select(agents);
    if (workspaceId != null) {
      query.where((row) => row.workspaceId.equals(workspaceId));
    }
    query.orderBy(<OrderClauseGenerator<$AgentsTable>>[
      (row) => OrderingTerm.desc(row.updatedAt),
    ]);
    return (await query.get()).map(_toDto).toList(growable: false);
  }

  @override
  Future<AgentDto?> getById(String id) async {
    final row = await (select(
      agents,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDto(row);
  }

  @override
  Future<AgentDto> create(AgentDto agent) async {
    final existing = await getById(agent.id);
    if (existing != null) return existing;
    await into(agents).insert(
      AgentsCompanion.insert(
        id: agent.id,
        workspaceId: agent.workspaceId,
        title: agent.title,
        providerConnectionId: agent.providerConnectionId,
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

  @override
  Future<AgentDto> updateStatus(
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
        updatedAt: Value<DateTime>(attachedDatabase.clock.nowUtc()),
      ),
    );
    return (await getById(id))!;
  }

  /// The hasTurns public API member.
  Future<bool> hasTurns(String agentId) async {
    final count = turns.id.count();
    final query = selectOnly(turns)
      ..addColumns(<Expression<Object>>[count])
      ..where(turns.agentId.equals(agentId));
    return (await query.getSingle()).read(count)! > 0;
  }

  @override
  Future<AgentDto> updateConfiguration({
    required String id,
    required String providerConnectionId,
    required String model,
    required String reasoningEffort,
  }) async {
    if (await hasTurns(id)) {
      throw StateError(
        'Agent provider and model are locked after the first turn.',
      );
    }
    await (update(agents)..where((row) => row.id.equals(id))).write(
      AgentsCompanion(
        providerConnectionId: Value<String>(providerConnectionId),
        model: Value<String>(model),
        reasoningEffort: Value<String>(reasoningEffort),
        updatedAt: Value<DateTime>(attachedDatabase.clock.nowUtc()),
      ),
    );
    return (await getById(id))!;
  }

  @override
  Future<bool> createTurn({
    required String id,
    required String agentId,
    required String prompt,
  }) async {
    final exists = await (select(
      turns,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (exists != null) return false;
    final now = attachedDatabase.clock.nowUtc();
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

  @override
  Future<void> updateTurn(String id, TurnStatus status, {String? error}) =>
      (update(turns)..where((row) => row.id.equals(id))).write(
        TurnsCompanion(
          status: Value<String>(status.name),
          error: Value<String?>(error),
          updatedAt: Value<DateTime>(attachedDatabase.clock.nowUtc()),
        ),
      );

  AgentDto _toDto(Agent row) => AgentDto(
    id: row.id,
    workspaceId: row.workspaceId,
    title: row.title,
    providerConnectionId: row.providerConnectionId,
    model: row.model,
    reasoningEffort: row.reasoningEffort,
    status: AgentStatus.values.byName(row.status),
    permissionMode: PermissionMode.values.byName(row.permissionMode),
    activeTurnId: row.activeTurnId,
    lastError: row.lastError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

@DriftAccessor(tables: <Type>[TimelineEvents, ApprovalRequests, ProviderStates])
/// TimelineDao defines a public contract.
class TimelineDao extends DatabaseAccessor<CoderDatabase>
    with _$TimelineDaoMixin
    implements TimelineRepository {
  /// Creates a [TimelineDao].
  TimelineDao(super.attachedDatabase);

  @override
  Future<TimelineEventDto> append({
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
      createdAt: attachedDatabase.clock.nowUtc(),
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

  @override
  Future<List<TimelineEventDto>> after(String agentId, int sequence) async =>
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

  @override
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
            createdAt: attachedDatabase.clock.nowUtc(),
          ),
        );
      }
    });
  }

  @override
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

  @override
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

  @override
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
}

@DriftAccessor(tables: <Type>[ProviderConnections, ProviderModels, Agents])
/// ProviderDao defines a public contract.
class ProviderDao extends DatabaseAccessor<CoderDatabase>
    with _$ProviderDaoMixin
    implements ProviderRepository {
  /// Creates a [ProviderDao].
  ProviderDao(super.attachedDatabase);

  @override
  Future<List<ProviderConnectionDto>> listConnections() async =>
      (await (select(providerConnections)
                ..orderBy(<OrderClauseGenerator<$ProviderConnectionsTable>>[
                  (row) => OrderingTerm.asc(row.displayName),
                ]))
              .get())
          .map(_connectionToDto)
          .toList(growable: false);

  @override
  Future<ProviderConnectionDto?> getConnection(String id) async {
    final row = await (select(
      providerConnections,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _connectionToDto(row);
  }

  @override
  Future<ProviderConnectionDto> upsertConnection(
    ProviderConnectionDto connection,
  ) async {
    await into(providerConnections).insertOnConflictUpdate(
      ProviderConnectionsCompanion.insert(
        id: connection.id,
        definitionId: connection.definitionId,
        displayName: connection.displayName,
        status: connection.status.name,
        authKind: connection.authKind.name,
        credentialOrigin: connection.credentialOrigin.name,
        isDefault: Value<bool>(connection.isDefault),
        defaultModelId: Value<String?>(connection.defaultModelId),
        error: Value<String?>(connection.error),
        customConfigJson: Value<String?>(
          connection.customConfig == null
              ? null
              : jsonEncode(connection.customConfig!.toJson()),
        ),
        createdAt: connection.createdAt,
        updatedAt: connection.updatedAt,
      ),
    );
    return (await getConnection(connection.id))!;
  }

  @override
  Future<void> deleteConnection(String id) async {
    final count = agents.id.count();
    final query = selectOnly(agents)
      ..addColumns(<Expression<Object>>[count])
      ..where(agents.providerConnectionId.equals(id));
    if ((await query.getSingle()).read(count)! > 0) {
      throw StateError(
        'Provider connection is referenced by one or more agents.',
      );
    }
    await transaction(() async {
      await (delete(
        providerModels,
      )..where((row) => row.connectionId.equals(id))).go();
      await (delete(
        providerConnections,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  @override
  Future<void> setDefault(String id) => transaction(() async {
    await update(providerConnections).write(
      const ProviderConnectionsCompanion(isDefault: Value<bool>(false)),
    );
    await (update(
      providerConnections,
    )..where((row) => row.id.equals(id))).write(
      const ProviderConnectionsCompanion(
        isDefault: Value<bool>(true),
      ),
    );
  });

  @override
  Future<List<ProviderModelDto>> listModels(String connectionId) async =>
      (await (select(providerModels)
                ..where((row) => row.connectionId.equals(connectionId))
                ..orderBy(<OrderClauseGenerator<$ProviderModelsTable>>[
                  (row) => OrderingTerm.asc(row.label),
                ]))
              .get())
          .map(_modelToDto)
          .toList(growable: false);

  @override
  Future<ProviderModelDto?> getModel(
    String connectionId,
    String modelId,
  ) async {
    final row =
        await (select(providerModels)..where(
              (table) =>
                  table.connectionId.equals(connectionId) &
                  table.modelId.equals(modelId),
            ))
            .getSingleOrNull();
    return row == null ? null : _modelToDto(row);
  }

  @override
  Future<ProviderModelDto> upsertModel(ProviderModelDto model) async {
    await into(providerModels).insertOnConflictUpdate(
      ProviderModelsCompanion.insert(
        connectionId: model.connectionId,
        modelId: model.id,
        label: model.label,
        source: model.source.name,
        capabilitiesJson: jsonEncode(model.capabilities.toJson()),
        pricingJson: Value<String?>(
          model.pricing == null ? null : jsonEncode(model.pricing!.toJson()),
        ),
        limitsJson: Value<String?>(
          model.limits == null ? null : jsonEncode(model.limits!.toJson()),
        ),
        diagnosticStatus: Value<String>(model.diagnosticStatus.name),
        verifiedAt: Value<DateTime?>(model.verifiedAt),
        diagnosticError: Value<String?>(model.diagnosticError),
      ),
    );
    return (await getModel(model.connectionId, model.id))!;
  }

  @override
  Future<void> replaceModels(
    String connectionId,
    Iterable<ProviderModelDto> models,
  ) => transaction(() async {
    await (delete(
      providerModels,
    )..where((row) => row.connectionId.equals(connectionId))).go();
    for (final model in models) {
      if (model.connectionId != connectionId) {
        throw StateError('Replacement model belongs to another connection.');
      }
      await upsertModel(model);
    }
  });

  @override
  Future<void> deleteModel(String connectionId, String modelId) =>
      (delete(providerModels)..where(
            (row) =>
                row.connectionId.equals(connectionId) &
                row.modelId.equals(modelId),
          ))
          .go();

  ProviderConnectionDto _connectionToDto(ProviderConnection row) =>
      ProviderConnectionDto(
        id: row.id,
        definitionId: row.definitionId,
        displayName: row.displayName,
        status: ProviderConnectionStatus.values.byName(row.status),
        authKind: ProviderAuthKind.values.byName(row.authKind),
        credentialOrigin: ProviderCredentialOrigin.values.byName(
          row.credentialOrigin,
        ),
        isDefault: row.isDefault,
        defaultModelId: row.defaultModelId,
        error: row.error,
        customConfig: row.customConfigJson == null
            ? null
            : CustomProviderConfigDto.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(row.customConfigJson!) as Map<dynamic, dynamic>,
                ),
              ),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  ProviderModelDto _modelToDto(ProviderModel row) => ProviderModelDto(
    connectionId: row.connectionId,
    id: row.modelId,
    label: row.label,
    source: ProviderModelSource.values.byName(row.source),
    capabilities: ModelCapabilitiesDto.fromJson(
      Map<String, dynamic>.from(jsonDecode(row.capabilitiesJson) as Map),
    ),
    pricing: row.pricingJson == null
        ? null
        : ModelPricingDto.fromJson(
            Map<String, dynamic>.from(jsonDecode(row.pricingJson!) as Map),
          ),
    limits: row.limitsJson == null
        ? null
        : ModelLimitsDto.fromJson(
            Map<String, dynamic>.from(jsonDecode(row.limitsJson!) as Map),
          ),
    diagnosticStatus: DiagnosticStatus.values.byName(row.diagnosticStatus),
    verifiedAt: row.verifiedAt,
    diagnosticError: row.diagnosticError,
  );
}

@DriftAccessor(tables: <Type>[Agents, Turns, ApprovalRequests])
/// RuntimeDao defines a public contract.
class RuntimeDao extends DatabaseAccessor<CoderDatabase>
    with _$RuntimeDaoMixin
    implements RecoveryRepository {
  /// Creates a [RuntimeDao].
  RuntimeDao(super.attachedDatabase);

  @override
  Future<void> recoverInterruptedRuns() async {
    final now = attachedDatabase.clock.nowUtc();
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
}
