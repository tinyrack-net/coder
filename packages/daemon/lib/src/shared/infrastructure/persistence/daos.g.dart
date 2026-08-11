// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$SettingsDaoMixin on DatabaseAccessor<TinestDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db.attachedDatabase, _db.settings);
}

mixin _$WorkspaceDaoMixin on DatabaseAccessor<TinestDatabase> {
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

mixin _$WorktreeDaoMixin on DatabaseAccessor<TinestDatabase> {
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

mixin _$SessionDaoMixin on DatabaseAccessor<TinestDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TurnsTable get turns => attachedDatabase.turns;
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  $TurnAttachmentsTable get turnAttachments => attachedDatabase.turnAttachments;
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
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
  $$TurnAttachmentsTableTableManager get turnAttachments =>
      $$TurnAttachmentsTableTableManager(
        _db.attachedDatabase,
        _db.turnAttachments,
      );
}

mixin _$GoalDaoMixin on DatabaseAccessor<TinestDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $GoalsTable get goals => attachedDatabase.goals;
  GoalDaoManager get managers => GoalDaoManager(this);
}

class GoalDaoManager {
  final _$GoalDaoMixin _db;
  GoalDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
}

mixin _$AgentMailboxDaoMixin on DatabaseAccessor<TinestDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $AgentMailboxMessagesTable get agentMailboxMessages =>
      attachedDatabase.agentMailboxMessages;
  AgentMailboxDaoManager get managers => AgentMailboxDaoManager(this);
}

class AgentMailboxDaoManager {
  final _$AgentMailboxDaoMixin _db;
  AgentMailboxDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$AgentMailboxMessagesTableTableManager get agentMailboxMessages =>
      $$AgentMailboxMessagesTableTableManager(
        _db.attachedDatabase,
        _db.agentMailboxMessages,
      );
}

mixin _$AttachmentDaoMixin on DatabaseAccessor<TinestDatabase> {
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TurnsTable get turns => attachedDatabase.turns;
  $TurnAttachmentsTable get turnAttachments => attachedDatabase.turnAttachments;
  AttachmentDaoManager get managers => AttachmentDaoManager(this);
}

class AttachmentDaoManager {
  final _$AttachmentDaoMixin _db;
  AttachmentDaoManager(this._db);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$WorktreesTableTableManager get worktrees =>
      $$WorktreesTableTableManager(_db.attachedDatabase, _db.worktrees);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$TurnsTableTableManager get turns =>
      $$TurnsTableTableManager(_db.attachedDatabase, _db.turns);
  $$TurnAttachmentsTableTableManager get turnAttachments =>
      $$TurnAttachmentsTableTableManager(
        _db.attachedDatabase,
        _db.turnAttachments,
      );
}

mixin _$TimelineDaoMixin on DatabaseAccessor<TinestDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TimelineEventsTable get timelineEvents => attachedDatabase.timelineEvents;
  $TurnsTable get turns => attachedDatabase.turns;
  $ApprovalRequestsTable get approvalRequests =>
      attachedDatabase.approvalRequests;
  $UserQuestionsTable get userQuestions => attachedDatabase.userQuestions;
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
  $$UserQuestionsTableTableManager get userQuestions =>
      $$UserQuestionsTableTableManager(_db.attachedDatabase, _db.userQuestions);
  $$ProviderStatesTableTableManager get providerStates =>
      $$ProviderStatesTableTableManager(
        _db.attachedDatabase,
        _db.providerStates,
      );
}

mixin _$ProviderDaoMixin on DatabaseAccessor<TinestDatabase> {
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

mixin _$RuntimeDaoMixin on DatabaseAccessor<TinestDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $WorktreesTable get worktrees => attachedDatabase.worktrees;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TurnsTable get turns => attachedDatabase.turns;
  $ApprovalRequestsTable get approvalRequests =>
      attachedDatabase.approvalRequests;
  $UserQuestionsTable get userQuestions => attachedDatabase.userQuestions;
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
  $$UserQuestionsTableTableManager get userQuestions =>
      $$UserQuestionsTableTableManager(_db.attachedDatabase, _db.userQuestions);
}
