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
    required String providerId,
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
        providerId: Value<String>(providerId),
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

@DriftAccessor(tables: <Type>[ApiProviders, ProviderModels, Agents])
/// ProviderDao defines a public contract.
class ProviderDao extends DatabaseAccessor<CoderDatabase>
    with _$ProviderDaoMixin
    implements ProviderRepository {
  /// Creates a [ProviderDao].
  ProviderDao(super.attachedDatabase);

  @override
  Future<List<ApiProviderDto>> listProviders() async =>
      (await (select(apiProviders)
                ..orderBy(<OrderClauseGenerator<$ApiProvidersTable>>[
                  (row) => OrderingTerm.asc(row.name),
                ]))
              .get())
          .map(_providerToDto)
          .toList(growable: false);

  @override
  Future<ApiProviderDto?> getProvider(String id) async {
    final row = await (select(
      apiProviders,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _providerToDto(row);
  }

  @override
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
    return (await getProvider(provider.id))!;
  }

  @override
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

  @override
  Future<List<ProviderModelDto>> listModels(String providerId) async =>
      (await (select(providerModels)
                ..where((row) => row.providerId.equals(providerId))
                ..orderBy(<OrderClauseGenerator<$ProviderModelsTable>>[
                  (row) => OrderingTerm.asc(row.label),
                ]))
              .get())
          .map(_modelToDto)
          .toList(growable: false);

  @override
  Future<ProviderModelDto?> getModel(String providerId, String modelId) async {
    final row =
        await (select(providerModels)..where(
              (table) =>
                  table.providerId.equals(providerId) &
                  table.modelId.equals(modelId),
            ))
            .getSingleOrNull();
    return row == null ? null : _modelToDto(row);
  }

  @override
  Future<ProviderModelDto> upsertModel(ProviderModelDto model) async {
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
    return (await getModel(model.providerId, model.id))!;
  }

  @override
  Future<void> replaceDiscoveredModels(
    String providerId,
    Iterable<ProviderModelDto> models,
  ) async {
    final existingModels = <String, ProviderModelDto>{
      for (final model in await listModels(providerId)) model.id: model,
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
        await upsertModel(
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

  @override
  Future<void> deleteModel(String providerId, String modelId) =>
      (delete(providerModels)..where(
            (row) =>
                row.providerId.equals(providerId) & row.modelId.equals(modelId),
          ))
          .go();

  ApiProviderDto _providerToDto(ApiProvider row) => ApiProviderDto(
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

  ProviderModelDto _modelToDto(ProviderModel row) => ProviderModelDto(
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
