// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<CoderDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db.attachedDatabase, _db.settings);
}

mixin _$WorkspaceDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  WorkspaceDaoManager get managers => WorkspaceDaoManager(this);
}

class WorkspaceDaoManager {
  final _$WorkspaceDaoMixin _db;
  WorkspaceDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
}

mixin _$WorktreeDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  WorktreeDaoManager get managers => WorktreeDaoManager(this);
}

class WorktreeDaoManager {
  final _$WorktreeDaoMixin _db;
  WorktreeDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
}

mixin _$SessionDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TurnsTable get turns => attachedDatabase.turns;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
}

mixin _$TimelineDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TimelineEventsTable get timelineEvents => attachedDatabase.timelineEvents;
  $TurnsTable get turns => attachedDatabase.turns;
  $ApprovalRequestsTable get approvalRequests =>
      attachedDatabase.approvalRequests;
  $ProviderStatesTable get providerStates => attachedDatabase.providerStates;
  TimelineDaoManager get managers => TimelineDaoManager(this);
}

class TimelineDaoManager {
  final _$TimelineDaoMixin _db;
  TimelineDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$TimelineEventsTableTableManager get timelineEvents =>
      $$TimelineEventsTableTableManager(
        _db.attachedDatabase,
        _db.timelineEvents,
      );
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
  $$ApprovalRequestsTableTableManager get approvalRequests =>
      $$ApprovalRequestsTableTableManager(
        _db.attachedDatabase,
        _db.approvalRequests,
      );
  $$ProviderStatesTableTableManager get providerStates =>
      $$ProviderStatesTableTableManager(
        _db.attachedDatabase,
        _db.providerStates,
      );
}

mixin _$ProviderDaoMixin on DatabaseAccessor<CoderDatabase> {
  $ProviderConnectionsTable get providerConnections =>
      attachedDatabase.providerConnections;
  $ProviderModelsTable get providerModels => attachedDatabase.providerModels;
  ProviderDaoManager get managers => ProviderDaoManager(this);
}

class ProviderDaoManager {
  final _$ProviderDaoMixin _db;
  ProviderDaoManager(this._db);
  $$ProviderConnectionsTableTableManager get providerConnections =>
      $$ProviderConnectionsTableTableManager(
        _db.attachedDatabase,
        _db.providerConnections,
      );
  $$ProviderModelsTableTableManager get providerModels =>
      $$ProviderModelsTableTableManager(
        _db.attachedDatabase,
        _db.providerModels,
      );
}

mixin _$RuntimeDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TurnsTable get turns => attachedDatabase.turns;
  $ApprovalRequestsTable get approvalRequests =>
      attachedDatabase.approvalRequests;
  RuntimeDaoManager get managers => RuntimeDaoManager(this);
}

class RuntimeDaoManager {
  final _$RuntimeDaoMixin _db;
  RuntimeDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
  $$ApprovalRequestsTableTableManager get approvalRequests =>
      $$ApprovalRequestsTableTableManager(
        _db.attachedDatabase,
        _db.approvalRequests,
      );
}
