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

  /// Provider connection selected for this agent.
  TextColumn get providerConnectionId => text()();

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

/// User-owned provider connections.
class ProviderConnections extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// Built-in definition identifier, or `custom`.
  TextColumn get definitionId => text()();

  /// Human-readable connection name.
  TextColumn get displayName => text()();

  /// Current connection state.
  TextColumn get status => text()();

  /// Active authentication kind.
  TextColumn get authKind => text()();

  /// Non-secret credential origin.
  TextColumn get credentialOrigin => text()();

  /// Whether this is the daemon-wide default connection.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// The defaultModelId public API member.
  TextColumn get defaultModelId => text().nullable()();

  /// Last user-safe connection error.
  TextColumn get error => text().nullable()();

  /// Advanced custom configuration, never used by built-in definitions.
  TextColumn get customConfigJson => text().nullable()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  /// The updatedAt public API member.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// ProviderModels defines a public contract.
class ProviderModels extends Table {
  /// Owning provider connection.
  TextColumn get connectionId => text().references(ProviderConnections, #id)();

  /// The modelId public API member.
  TextColumn get modelId => text()();

  /// The label public API member.
  TextColumn get label => text()();

  /// The source public API member.
  TextColumn get source => text()();

  /// The capabilitiesJson public API member.
  TextColumn get capabilitiesJson => text()();

  /// Optional model pricing metadata.
  TextColumn get pricingJson => text().nullable()();

  /// Optional model token-limit metadata.
  TextColumn get limitsJson => text().nullable()();

  /// The diagnosticStatus public API member.
  TextColumn get diagnosticStatus =>
      text().withDefault(const Constant('unknown'))();

  /// The verifiedAt public API member.
  DateTimeColumn get verifiedAt => dateTime().nullable()();

  /// The diagnosticError public API member.
  TextColumn get diagnosticError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{connectionId, modelId};
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
    ProviderConnections,
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
    : databasePath = path,
      super(NativeDatabase.createInBackground(File(path)));

  /// The CoderDatabaseforTesting public API member.
  CoderDatabase.forTesting(super.e, {this.clock = const SystemClock()})
    : databasePath = '<memory>';

  /// The clock public API member.
  final Clock clock;

  /// SQLite path included in explicit incompatible-schema guidance.
  final String databasePath;

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) => throw StateError(
      'incompatible_database: schema $from cannot be opened as schema $to. '
      'Stop the daemon and explicitly remove $databasePath to reset '
      'development data.',
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
