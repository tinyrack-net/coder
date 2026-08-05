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

  /// Whether this workspace represents a Git repository or a directory.
  TextColumn get kind => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// A concrete checkout belonging to a repository workspace.
class Worktrees extends Table {
  /// Stable worktree identifier.
  TextColumn get id => text()();

  /// Owning workspace identifier.
  TextColumn get workspaceId => text().references(Workspaces, #id)();

  /// Human-readable checkout name.
  TextColumn get name => text()();

  /// Canonical checkout path.
  TextColumn get path => text()();

  /// Checked-out branch, when this is a Git worktree.
  TextColumn get branch => text().nullable()();

  /// Current commit, when this is a Git worktree.
  TextColumn get head => text().nullable()();

  /// Worktree ownership and lifecycle kind.
  TextColumn get kind => text()();

  /// Whether Coder created and may remove the checkout directory.
  BoolColumn get isCoderOwned => boolean()();

  /// Archive instant; null while visible in the workspace catalog.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Creation instant.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Persisted AI coding sessions.
class Sessions extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The worktreeId public API member.
  TextColumn get worktreeId => text().references(Worktrees, #id)();

  /// The title public API member.
  TextColumn get title => text()();

  /// Markdown agent definition resolved for each turn.
  TextColumn get agentDefinitionId => text()();

  /// Whether this session was created directly or by delegation.
  TextColumn get origin => text()();

  /// Parent session for delegated subagents.
  TextColumn get parentSessionId =>
      text().nullable().references(Sessions, #id)();

  /// The status public API member.
  TextColumn get status => text()();

  /// The activeTurnId public API member.
  TextColumn get activeTurnId => text().nullable()();

  /// The lastError public API member.
  TextColumn get lastError => text().nullable()();

  /// Collaboration mode: `plan` proposes work, `normal` performs it.
  TextColumn get mode => text().withDefault(const Constant('normal'))();

  /// Provider connection pinned for this session; null inherits the agent.
  TextColumn get modelConnectionId => text().nullable()();

  /// Model pinned for this session; null inherits the agent definition.
  TextColumn get modelId => text().nullable()();

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

  /// The sessionId public API member.
  TextColumn get sessionId => text().references(Sessions, #id)();

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

/// Immutable attachment metadata; payload bytes live in the attachment store.
class Attachments extends Table {
  /// Stable opaque identifier used as the storage key.
  TextColumn get id => text()();

  /// Original display name, never used to construct a storage path.
  TextColumn get fileName => text()();

  /// Validated media type.
  TextColumn get mimeType => text()();

  /// Exact payload length.
  IntColumn get byteSize => integer()();

  /// Broad preview category.
  TextColumn get kind => text()();

  /// Lower-case SHA-256 digest.
  TextColumn get sha256 => text()();

  /// Upload completion time.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Ordered attachment relationship for inbound and outbound turn files.
class TurnAttachments extends Table {
  /// Owning turn.
  TextColumn get turnId => text().references(Turns, #id)();

  /// Attached immutable payload.
  TextColumn get attachmentId => text().references(Attachments, #id)();

  /// `user` or `assistant`.
  TextColumn get direction => text()();

  /// Stable order within the direction.
  IntColumn get ordinal => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    turnId,
    direction,
    ordinal,
  };
}

/// TimelineEvents defines a public contract.
class TimelineEvents extends Table {
  /// The sessionId public API member.
  TextColumn get sessionId => text().references(Sessions, #id)();

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
  Set<Column<Object>> get primaryKey => <Column<Object>>{sessionId, sequence};
}

/// ApprovalRequests defines a public contract.
class ApprovalRequests extends Table {
  /// The id public API member.
  TextColumn get id => text()();

  /// The sessionId public API member.
  TextColumn get sessionId => text().references(Sessions, #id)();

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
  /// The sessionId public API member.
  TextColumn get sessionId => text().references(Sessions, #id)();

  /// The ordinal public API member.
  IntColumn get ordinal => integer()();

  /// The itemJson public API member.
  TextColumn get itemJson => text()();

  /// The createdAt public API member.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{sessionId, ordinal};
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
    Worktrees,
    Sessions,
    Turns,
    Attachments,
    TurnAttachments,
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
    WorktreeDao,
    SessionDao,
    AttachmentDao,
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
  int get schemaVersion => 10;

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
