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
  WorkspaceDaoManager get managers => WorkspaceDaoManager(this);
}

class WorkspaceDaoManager {
  final _$WorkspaceDaoMixin _db;
  WorkspaceDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
}

mixin _$AgentDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
  $TurnsTable get turns => attachedDatabase.turns;
  AgentDaoManager get managers => AgentDaoManager(this);
}

class AgentDaoManager {
  final _$AgentDaoMixin _db;
  AgentDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
}

mixin _$TimelineDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
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
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
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
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
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
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
}

mixin _$RuntimeDaoMixin on DatabaseAccessor<CoderDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $AgentsTable get agents => attachedDatabase.agents;
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
  $$AgentsTableTableManager get agents =>
      $$AgentsTableTableManager(_db.attachedDatabase, _db.agents);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
  $$ApprovalRequestsTableTableManager get approvalRequests =>
      $$ApprovalRequestsTableTableManager(
        _db.attachedDatabase,
        _db.approvalRequests,
      );
}
