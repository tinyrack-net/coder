import 'dart:io';

import 'package:coder_daemon/src/daos.dart';
import 'package:coder_daemon/src/ports.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

/// Workspaces defines a public contract.
class Workspaces extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The name public API member.
  TextColumn get name => text()();

  /// The rootPath public API member.
  TextColumn get rootPath => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Agents defines a public contract.
class Agents extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The workspaceId public API member.
  TextColumn get workspaceId => text().references(Workspaces, #id)();

  /// The title public API member.
  TextColumn get title => text()();

  /// The providerId public API member.
  TextColumn get providerId => text()();

  /// The model public API member.
  TextColumn get model => text()();

  /// The reasoningEffort public API member.
  TextColumn get reasoningEffort =>
      text().withDefault(const Constant('medium'))();

  /// The status public API member.
  TextColumn get status => text()();

  /// The permissionMode public API member.
  TextColumn get permissionMode => text()();

  /// The activeTurnId public API member.
  TextColumn get activeTurnId => text().nullable()();

  /// The lastError public API member.
  TextColumn get lastError => text().nullable()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  /// The updatedAt public API member.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Turns defines a public contract.
class Turns extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The agentId public API member.
  TextColumn get agentId => text().references(Agents, #id)();

  /// The prompt public API member.
  TextColumn get prompt => text()();

  /// The status public API member.
  TextColumn get status => text()();

  /// The error public API member.
  TextColumn get error => text().nullable()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  /// The updatedAt public API member.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// TimelineEvents defines a public contract.
class TimelineEvents extends Table {
  /// The agentId public API member.
  TextColumn get agentId => text().references(Agents, #id)();

  /// The sequence public API member.
  IntColumn get sequence => integer()();

  /// The turnId public API member.
  TextColumn get turnId => text().nullable()();

  /// The type public API member.
  TextColumn get type => text()();

  /// The dataJson public API member.
  TextColumn get dataJson => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{agentId, sequence};
}

/// ApprovalRequests defines a public contract.
class ApprovalRequests extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The agentId public API member.
  TextColumn get agentId => text().references(Agents, #id)();

  /// The turnId public API member.
  TextColumn get turnId => text().references(Turns, #id)();

  /// The toolCallId public API member.
  TextColumn get toolCallId => text()();

  /// The toolName public API member.
  TextColumn get toolName => text()();

  /// The risk public API member.
  TextColumn get risk => text()();

  /// The argumentsJson public API member.
  TextColumn get argumentsJson => text()();

  /// The preview public API member.
  TextColumn get preview => text().nullable()();

  /// The status public API member.
  TextColumn get status => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// ProviderStates defines a public contract.
class ProviderStates extends Table {
  /// The agentId public API member.
  TextColumn get agentId => text().references(Agents, #id)();

  /// The ordinal public API member.
  IntColumn get ordinal => integer()();

  /// The itemJson public API member.
  TextColumn get itemJson => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{agentId, ordinal};
}

/// Settings defines a public contract.
class Settings extends Table {
  /// The key public API member.
  TextColumn get key => text()();

  /// The value public API member.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// ApiProviders defines a public contract.
class ApiProviders extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The name public API member.
  TextColumn get name => text()();

  /// The presetId public API member.
  TextColumn get presetId => text()();

  /// The baseUrl public API member.
  TextColumn get baseUrl => text()();

  /// The transport public API member.
  TextColumn get transport => text()();

  /// The credentialSource public API member.
  TextColumn get credentialSource => text()();

  /// The environmentVariable public API member.
  TextColumn get environmentVariable => text().nullable()();

  /// The enabled public API member.
  BoolColumn get enabled => boolean()();

  /// The strictToolSchema public API member.
  BoolColumn get strictToolSchema => boolean()();

  /// The defaultModelId public API member.
  TextColumn get defaultModelId => text().nullable()();

  /// The visibleModelIdsJson public API member.
  TextColumn get visibleModelIdsJson =>
      text().withDefault(const Constant('[]'))();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  /// The updatedAt public API member.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// ProviderModels defines a public contract.
class ProviderModels extends Table {
  /// The providerId public API member.
  TextColumn get providerId => text().references(ApiProviders, #id)();

  /// The modelId public API member.
  TextColumn get modelId => text()();

  /// The label public API member.
  TextColumn get label => text()();

  /// The source public API member.
  TextColumn get source => text()();

  /// The capabilitiesJson public API member.
  TextColumn get capabilitiesJson => text()();

  /// The diagnosticStatus public API member.
  TextColumn get diagnosticStatus =>
      text().withDefault(const Constant('unknown'))();

  /// The verifiedAt public API member.
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  /// The diagnosticError public API member.
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
  daos: <Type>[
    SettingsDao,
    WorkspaceDao,
    AgentDao,
    TimelineDao,
    ProviderDao,
    RuntimeDao,
  ],
)
/// CoderDatabase defines a public contract.
class CoderDatabase extends _$CoderDatabase {
  /// Creates a [CoderDatabase].
  CoderDatabase(String path, {this.clock = const SystemClock()})
    : super(NativeDatabase.createInBackground(File(path)));

  /// The CoderDatabaseforTesting public API member.
  CoderDatabase.forTesting(super.e, {this.clock = const SystemClock()});

  /// The clock public API member.
  final Clock clock;

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
}
