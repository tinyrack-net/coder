// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonCreating => 'Creating…';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonStop => 'Stop';

  @override
  String get commonName => 'Name';

  @override
  String get commonKind => 'Kind';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonRunning => 'Running';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonSaved => 'Saved.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionDaemon => 'Daemon';

  @override
  String get settingsDaemonSelectLabel => 'Daemon';

  @override
  String get settingsDaemonSelectEmpty => 'No daemons';

  @override
  String settingsDaemonOffline(String label) {
    return '$label is not connected.';
  }

  @override
  String get settingsCategoryGeneral => 'General';

  @override
  String get settingsCategoryProjects => 'Projects';

  @override
  String get settingsCategoryAgent => 'Agent';

  @override
  String get settingsCategoryProvider => 'Provider';

  @override
  String get settingsCategoryDaemon => 'Daemons';

  @override
  String get settingsCategoryAdvanced => 'Advanced';

  @override
  String get advancedResetSection => 'Reset';

  @override
  String get advancedResetTitle => 'Reset all data';

  @override
  String get advancedResetDescription =>
      'Deletes the embedded daemon\'s database, credentials, MCP and agent configuration, skills, and attachments, and clears every app setting and stored remote daemon token. Git checkouts under the worktrees folder stay on disk.';

  @override
  String get advancedResetDescriptionAppOnly =>
      'Clears every app setting and stored remote daemon token on this device. Remote daemons keep their own data.';

  @override
  String get advancedResetAction => 'Reset all data';

  @override
  String get advancedResetRunning => 'Resetting…';

  @override
  String get advancedResetConfirmTitle => 'Reset all data?';

  @override
  String get advancedResetConfirmBody =>
      'Every session, workspace registration, provider connection, agent, skill, and MCP server on the embedded daemon is deleted, together with every app setting and remote daemon profile and token. The daemon returns to its default port. Git checkouts stay on disk but have to be added again. This cannot be undone.';

  @override
  String get advancedResetConfirmAccept => 'Reset';

  @override
  String get advancedResetFailedTitle => 'Reset failed';

  @override
  String get advancedResetFailedDaemonRunning =>
      'Another Tinyrack Coder daemon is using the data directory. Quit it and try again. Nothing was deleted.';

  @override
  String advancedResetFailedFilesystem(String error) {
    return 'Some daemon files could not be deleted: $error';
  }

  @override
  String get advancedResetFailedIncomplete =>
      'Daemon data was removed but the app settings could not be cleared. Restart Tinyrack Coder.';

  @override
  String get settingsRequiresOnlineDaemon => 'Connect an online daemon first.';

  @override
  String get generalLanguageSection => 'Language';

  @override
  String get generalLanguageLabel => 'Display language';

  @override
  String get generalLanguageDescription =>
      'Applies to the whole app and takes effect immediately.';

  @override
  String get generalLanguageSystem => 'System default';

  @override
  String get generalStartupSection => 'Startup';

  @override
  String get generalStartupAtBootLabel => 'Start at login';

  @override
  String get generalStartupAtBootDescription =>
      'The operating system launches Tinyrack Coder after you sign in, so the embedded daemon keeps running.';

  @override
  String get generalStartupMinimizedLabel => 'Start minimized';

  @override
  String get generalStartupMinimizedDescription =>
      'A login-time launch goes straight to the tray without opening a window.';

  @override
  String get generalStartupCloseNotice =>
      'Closing the window keeps Tinyrack Coder running in the tray.';

  @override
  String get trayTooltip => 'Tinyrack Coder';

  @override
  String get trayShowWindow => 'Show window';

  @override
  String get trayHideWindow => 'Hide window';

  @override
  String get trayOpenSettings => 'Settings';

  @override
  String get trayQuit => 'Quit';

  @override
  String get desktopMenuFile => 'File';

  @override
  String get desktopMenuView => 'View';

  @override
  String get desktopMenuHelp => 'Help';

  @override
  String get desktopMenuAbout => 'About Tinyrack Coder';

  @override
  String get desktopWindowMinimize => 'Minimize';

  @override
  String get desktopWindowMaximize => 'Maximize';

  @override
  String get desktopWindowRestore => 'Restore';

  @override
  String get desktopWindowClose => 'Close to tray';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceSidebarExpand => 'Show sidebar';

  @override
  String get workspaceSidebarCollapse => 'Hide sidebar';

  @override
  String get workspaceNewSession => 'New session';

  @override
  String get workspaceNewTab => 'New tab';

  @override
  String get workspaceNewTerminal => 'New terminal';

  @override
  String get terminalCloseTitle => 'Terminate terminal?';

  @override
  String get terminalCloseConfirm =>
      'Closing this tab terminates its shell and child processes.';

  @override
  String get terminalTerminate => 'Terminate';

  @override
  String get terminalConnectionFailed => 'Terminal connection failed';

  @override
  String get terminalMenuCopy => 'Copy';

  @override
  String get terminalMenuPaste => 'Paste';

  @override
  String get terminalMenuSelectAll => 'Select all';

  @override
  String get terminalMenuClearSelection => 'Clear selection';

  @override
  String get terminalMenuClearScreen => 'Clear screen';

  @override
  String get projectSettingsShellHeading => 'Project terminal shell';

  @override
  String get projectSettingsShellHelp =>
      'Overrides the daemon host shell for terminals opened in this project. Leave the executable empty to inherit the host default.';

  @override
  String get projectSettingsShellExecutable => 'Shell executable';

  @override
  String get projectSettingsShellArguments => 'Shell arguments (one per line)';

  @override
  String get projectSettingsHostShellHeading => 'Daemon host default shell';

  @override
  String get projectSettingsHostShellHelp =>
      'Used by every project on this daemon host unless the project overrides it. Leave the executable empty to use the operating system default.';

  @override
  String get workspaceAllSessions => 'All sessions';

  @override
  String get workspaceCloseTab => 'Close tab';

  @override
  String get workspaceNewWorkspace => 'New workspace';

  @override
  String get workspaceWorktreeMenu => 'Worktree menu';

  @override
  String get workspaceProjectMenu => 'Project menu';

  @override
  String get workspaceUnregister => 'Remove project';

  @override
  String workspaceUnregisterTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get workspaceUnregisterBody =>
      'The project disappears from Coder, but its repository and files stay on disk.';

  @override
  String get workspaceArchive => 'Archive';

  @override
  String get workspaceArchiveBlockedTitle => 'Cannot archive';

  @override
  String workspaceArchiveBlockedBody(int count) {
    return 'Stop the $count running session(s) first.';
  }

  @override
  String workspaceArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String get workspaceArchiveDirty => 'It has uncommitted changes.\n';

  @override
  String workspaceArchiveUnpushed(int count) {
    return 'It has $count unpushed commit(s).\n';
  }

  @override
  String get workspaceArchiveRemovesDirectory =>
      'The checkout directory created by Coder will be removed.';

  @override
  String get workspaceArchiveKeepsDirectory =>
      'Only the registration is hidden; the checkout stays on disk.';

  @override
  String get workspaceArchiveRisky => 'Confirm the risks and archive';

  @override
  String get workspaceNoDaemons => 'No daemons are configured.';

  @override
  String get workspaceNoConnectedDaemons => 'No daemon is connected.';

  @override
  String get workspaceNoWorkspaces => 'No workspaces yet.';

  @override
  String get workspaceOpenDaemonSettings => 'Daemon settings';

  @override
  String get hostStatusOnline => 'Online';

  @override
  String get hostStatusConnecting => 'Connecting';

  @override
  String get hostStatusReconnecting => 'Reconnecting';

  @override
  String get hostStatusOffline => 'Offline';

  @override
  String get hostStatusError => 'Error';

  @override
  String get hostStatusConflict => 'Duplicate daemon';

  @override
  String get hostStatusIdle => 'Auto-connect off';

  @override
  String get hostStatusPending => 'Waiting';

  @override
  String get embeddedDaemonName => 'Embedded daemon';

  @override
  String get hostErrorMissingToken => 'Enter a bearer token.';

  @override
  String get hostErrorNoToken => 'No bearer token is stored.';

  @override
  String get hostErrorDuplicate => 'That daemon is already registered.';

  @override
  String get hostErrorUnauthorized => 'The daemon rejected the bearer token.';

  @override
  String get hostErrorEmbeddedPortInUse =>
      'The selected port is already in use.';

  @override
  String get appSettingsTitle => 'App settings';

  @override
  String get appSettingsLocalSection => 'Local execution';

  @override
  String get appSettingsEmbeddedSubtitle =>
      'Starts with the app and stops when it exits. A failed start does not block the app.';

  @override
  String get appSettingsExposure => 'Allow network access';

  @override
  String get appSettingsExposureSubtitle =>
      'Off accepts connections from this machine only; on accepts them on every IPv4 interface.';

  @override
  String get appSettingsEmbeddedPort => 'Port';

  @override
  String get appSettingsEmbeddedPortHelp =>
      'Choose a port from 1 to 65535. Applying restarts the embedded daemon when it is running.';

  @override
  String get appSettingsEmbeddedPortInvalid =>
      'Enter a whole number from 1 to 65535.';

  @override
  String get appSettingsEmbeddedPortApply => 'Apply';

  @override
  String get appSettingsEmbeddedFailureTitle =>
      'The embedded daemon could not start';

  @override
  String appSettingsEmbeddedPortConflict(int port) {
    return 'Port $port is being used by another process. Choose another port and apply it, or retry after the port becomes available.';
  }

  @override
  String get appSettingsRemoteSection => 'Remote daemons';

  @override
  String get appSettingsAddRemote => 'Add remote daemon';

  @override
  String get appSettingsNoRemotes => 'No remote daemons are saved.';

  @override
  String get appSettingsStopEmbeddedTitle => 'Stop the embedded daemon?';

  @override
  String get appSettingsStopEmbeddedBody =>
      'This stops only the daemon this app owns, along with its connection. Remote and standalone daemons are unaffected.';

  @override
  String get appSettingsEditConnection => 'Edit connection';

  @override
  String get appSettingsAutoConnect => 'Connect on app start';

  @override
  String get appSettingsReconnect => 'Reconnect';

  @override
  String get appSettingsProviderSettings => 'Provider settings';

  @override
  String get appSettingsAddRemoteTitle => 'Add remote daemon';

  @override
  String get appSettingsEditRemoteTitle => 'Edit remote daemon';

  @override
  String get appSettingsAddress => 'WebSocket address';

  @override
  String get appSettingsNewToken => 'New bearer token (only when changing it)';

  @override
  String appSettingsDeleteTitle(String label) {
    return 'Delete $label?';
  }

  @override
  String get appSettingsDeleteBody =>
      'The connection and the bearer token stored on this device are removed too.';

  @override
  String get projectSettingsHeading => 'Projects';

  @override
  String get projectSettingsNoProjects => 'No projects are registered.';

  @override
  String get projectSettingsSelectProject => 'Select a project.';

  @override
  String get projectSettingsProjectList => 'Project list';

  @override
  String projectSettingsCount(int count) {
    return '$count projects';
  }

  @override
  String get projectSettingsCopyPath => 'Copy file location';

  @override
  String get projectSettingsHookHelp =>
      'Write one command per line; they run in order in the daemon host\'s shell. The CODER_WORKTREE_PATH, CODER_PROJECT_PATH, and CODER_BRANCH environment variables are available.';

  @override
  String get projectSettingsSetup => 'Setup (after a worktree is created)';

  @override
  String get projectSettingsTeardown =>
      'Teardown (before a worktree is removed)';

  @override
  String get agentSettingsHeading => 'Agents';

  @override
  String get agentSettingsSelectAgent => 'Select an agent.';

  @override
  String agentSettingsCount(int count) {
    return '$count definitions';
  }

  @override
  String get agentSettingsAdd => 'Add agent';

  @override
  String get agentSettingsAddTitle => 'Add agent';

  @override
  String get agentSettingsList => 'Agent list';

  @override
  String get agentSettingsCopyPath => 'Copy file location';

  @override
  String get agentSettingsReset => 'Reset to defaults';

  @override
  String get agentSettingsCustomPrompt => 'Use a custom system prompt';

  @override
  String get agentSettingsSessionModel => 'Choose for each session';

  @override
  String get agentSettingsPinnedModel => 'Pinned provider/model';

  @override
  String get agentSettingsBuiltinTools => 'Built-in tools';

  @override
  String get agentSettingsSubagents => 'Callable subagents';

  @override
  String get agentSettingsNoSubagents => 'No subagents are registered.';

  @override
  String get agentSettingsSaveFailedTitle => 'Could not save the agent';

  @override
  String get agentSettingsReload => 'Reload';

  @override
  String get agentSettingsOverwrite => 'Overwrite';

  @override
  String get agentSettingsIdInvalid =>
      'Only lowercase letters, digits, -, and _ are allowed.';

  @override
  String get agentSettingsIdTaken => 'That agent ID already exists.';

  @override
  String get agentSettingsIdLabel => 'ID (file name)';

  @override
  String get agentSettingsNameRequired => 'Enter a name.';

  @override
  String get providerSettingsTitle => 'Provider settings';

  @override
  String get providerSettingsRequiresDaemon => 'Connect a daemon first.';

  @override
  String get providerSettingsRefreshCatalog => 'Refresh catalog';

  @override
  String get providerSettingsOpenAiTitle => 'OpenAI connection';

  @override
  String get providerSettingsOpenAiSubtitle =>
      'ChatGPT sign-in is experimental and relies on the public Codex auth flow.';

  @override
  String get providerSettingsExperimental => 'Experimental';

  @override
  String get providerSettingsDisconnectTitle => 'Disconnect provider';

  @override
  String providerSettingsDisconnectBody(String name) {
    return 'Disconnect $name? Existing agent history is kept.';
  }

  @override
  String get providerSettingsDisconnect => 'Disconnect';

  @override
  String get providerSettingsDeleteCustomTitle => 'Delete custom provider';

  @override
  String providerSettingsDeleteCustomBody(String name) {
    return 'Delete $name and its stored credentials? Existing session history is kept.';
  }

  @override
  String get providerSettingsConnected => 'Connected';

  @override
  String get providerSettingsNoConnections => 'No providers are connected.';

  @override
  String get providerSettingsEditAdvanced => 'Edit advanced settings';

  @override
  String get providerSettingsActions => 'Connection actions';

  @override
  String get providerSettingsAdd => 'Add provider';

  @override
  String get providerSettingsNoPresets => 'No presets are left to add.';

  @override
  String get providerSettingsCustomSubtitle =>
      'Advanced: connect your own endpoint';

  @override
  String get providerSettingsOAuthPending => 'Waiting for ChatGPT sign-in';

  @override
  String providerSettingsConnectTitle(String name) {
    return 'Connect $name';
  }

  @override
  String get providerSettingsConnect => 'Connect';

  @override
  String get providerSettingsCustomTitle => 'Custom provider advanced settings';

  @override
  String get providerSettingsApiFormat => 'API format';

  @override
  String get providerSettingsRequiresApiKey => 'Requires an API key';

  @override
  String get providerSettingsManualModels => 'Manual model IDs';

  @override
  String get providerSettingsModelLookupFailedTitle => 'Could not list models';

  @override
  String get providerSettingsModelLookupFailedBody =>
      'The provider did not return a model list. Enter the model IDs to use.';

  @override
  String get providerSettingsLater => 'Later';

  @override
  String get providerStatusConnecting => 'Connecting';

  @override
  String get providerStatusConnected => 'Connected';

  @override
  String get providerStatusDegraded => 'Limited connection';

  @override
  String get providerStatusError => 'Error';

  @override
  String get providerStatusReauthRequired => 'Sign in again';

  @override
  String get providerStatusDisconnected => 'Disconnected';

  @override
  String get providerAuthStored => 'Stored credential';

  @override
  String get providerAuthNone => 'No credential';

  @override
  String get modelPickerTitle => 'Select a model';

  @override
  String get modelPickerSearch => 'Search models';

  @override
  String get modelPickerNoResults => 'No results.';

  @override
  String get composerPlan => 'Plan';

  @override
  String get composerRun => 'Run';

  @override
  String get composerPlanTooltip => 'Only drafts a plan. Shift+Tab to switch';

  @override
  String get composerRunTooltip =>
      'Carries the request out directly. Shift+Tab to switch';

  @override
  String get composerSelectAgent => 'Select an agent';

  @override
  String get composerAgentLocked =>
      'The agent cannot be changed after the session starts.';

  @override
  String get composerModel => 'Model';

  @override
  String get composerSelectModel => 'Select a model';

  @override
  String get composerInheritModel => 'Use the agent default';

  @override
  String get composerStartHint => 'Start a new session with a coding request.';

  @override
  String get composerNoPrimaryAgent => 'No primary agent is available.';

  @override
  String get composerSelectModelFirst => 'Select a model first.';

  @override
  String get composerPlanBanner =>
      'Plan mode · drafts a plan without carrying it out';

  @override
  String get composerInputHint => 'Type a coding request…';

  @override
  String get composerReasoningEffort => 'Effort';

  @override
  String get composerSelectReasoningEffort => 'Select reasoning effort';

  @override
  String get composerInheritReasoningEffort => 'Agent default';

  @override
  String get composerPermissionMode => 'Permissions';

  @override
  String get composerSelectPermissionMode => 'Select permissions';

  @override
  String get composerInheritPermissionMode => 'Agent default';

  @override
  String get composerPermissionReadOnly => 'Read only';

  @override
  String get composerPermissionAsk => 'Ask';

  @override
  String get composerPermissionWorkspaceWrite => 'Write workspace';

  @override
  String get composerFastMode => 'Fast';

  @override
  String get composerFastModeTooltip =>
      'Faster responses at a higher credit rate';

  @override
  String get composerFastModeOnTooltip =>
      'Fast mode is on; tap to use the standard tier';

  @override
  String get composerSettingLocked => 'Settings change between turns';

  @override
  String get composerSendLabel => 'Send message';

  @override
  String get composerQueueLabel => 'Queue message';

  @override
  String get composerQueueTooltip => 'Sends when the current turn finishes';

  @override
  String get composerQueuedEdit => 'Edit queued message';

  @override
  String get composerQueuedSendNow => 'Send queued message now';

  @override
  String composerQueuedAttachments(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get composerAttachLabel => 'Attach files';

  @override
  String get composerMoreSettings => 'More settings';

  @override
  String get chatEmptyTitle => 'Type a coding request.';

  @override
  String get chatEmptyExample => 'e.g. Run the tests and fix what fails';

  @override
  String get chatNoticeCancelled => 'Stopped';

  @override
  String chatNoticeFailed(String message) {
    return 'Failed · $message';
  }

  @override
  String chatMoreLines(int count) {
    return '… $count more lines';
  }

  @override
  String chatApprovalRequired(String tool) {
    return 'Approval required · $tool';
  }

  @override
  String get chatApprovalDeny => 'Deny';

  @override
  String get chatApprovalAllow => 'Allow';

  @override
  String get chatPlanTitle => 'Plan';

  @override
  String toolExecRunning(int lines) {
    return 'running · $lines lines';
  }

  @override
  String toolImageLoaded(int bytes) {
    return '$bytes bytes viewed';
  }

  @override
  String get chatQuestionSubmit => 'Answer';

  @override
  String get chatQuestionOther => 'Other';

  @override
  String get chatQuestionOtherPlaceholder => 'Type your answer';

  @override
  String get chatPlanStepPending => 'not started';

  @override
  String get chatPlanStepInProgress => 'in progress';

  @override
  String get chatPlanStepCompleted => 'completed';

  @override
  String get chatPlanPrompt => 'Proceed with this plan?';

  @override
  String get chatPlanKeepPlanning => 'Keep planning';

  @override
  String get chatPlanRunInNewSession => 'Run in a new session';

  @override
  String get chatPlanRun => 'Run the plan';

  @override
  String get toolRejected => 'Rejected';

  @override
  String get toolFailed => 'Failed';

  @override
  String get toolEmptyFile => 'Empty file';

  @override
  String toolReadLines(int count) {
    return 'Read $count lines';
  }

  @override
  String toolListItems(int count) {
    return '$count items';
  }

  @override
  String toolListEntries(int directories, int files) {
    return '$directories directories · $files files';
  }

  @override
  String get toolNoMatches => 'No matches';

  @override
  String toolMatches(int matches, int files) {
    return '$matches matches in $files files';
  }

  @override
  String toolEditFiles(int count) {
    return 'Edit($count files)';
  }

  @override
  String toolPatchSummary(int added, int removed, int files) {
    return '+$added -$removed · $files files';
  }

  @override
  String toolCommandResult(int exitCode, int lines) {
    return 'exit $exitCode · $lines lines';
  }

  @override
  String get directoryBrowserTitle => 'Choose a folder on the daemon';

  @override
  String get directoryBrowserPath => 'Daemon path';

  @override
  String get directoryBrowserEmpty => 'No subfolders.';

  @override
  String get directoryBrowserSelect => 'Choose this folder';

  @override
  String get directoryBrowserHostTitle => 'Daemon to add the folder to';

  @override
  String hookFailureMessage(String phase, int exitCode, String command) {
    return '$phase failed (exit $exitCode): $command';
  }

  @override
  String hookFailureTitle(String phase) {
    return '$phase hook failed';
  }

  @override
  String get hookFailureNoOutput => '(no output)';

  @override
  String get settingsCategorySkill => 'Skill';

  @override
  String get skillSettingsHeading => 'Skills';

  @override
  String skillSettingsCount(int count) {
    return '$count skills';
  }

  @override
  String get skillSettingsSelectSkill => 'Select a skill.';

  @override
  String get skillSettingsList => 'Skill list';

  @override
  String get skillSettingsAdd => 'Add skill';

  @override
  String get skillSettingsAddTitle => 'Add skill';

  @override
  String get skillSettingsIdLabel => 'ID (directory name)';

  @override
  String get skillSettingsIdInvalid =>
      'Only lowercase letters, digits, -, and _ are allowed.';

  @override
  String get skillSettingsIdTaken => 'That skill ID already exists.';

  @override
  String get skillSettingsNameRequired => 'Enter a name.';

  @override
  String get skillSettingsCopyPath => 'Copy file location';

  @override
  String get skillSettingsDelete => 'Delete skill';

  @override
  String skillSettingsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get skillSettingsDeleteMessage =>
      'The skill directory moves to .archive next to it.';

  @override
  String get skillSettingsEnabled => 'Enabled';

  @override
  String get skillSettingsMandatory => 'This built-in skill is always enabled.';

  @override
  String get skillSettingsReadOnly =>
      'Built-in skills ship with the app and cannot be edited.';

  @override
  String get skillSettingsInstructions => 'Instructions (Markdown)';

  @override
  String get skillSettingsResources => 'Bundled files';

  @override
  String get skillSettingsNoResources =>
      'No files are bundled with this skill.';

  @override
  String get skillSettingsSaveFailedTitle => 'Could not save the skill';

  @override
  String get skillSettingsReload => 'Reload';

  @override
  String get skillSettingsOverwrite => 'Overwrite';

  @override
  String get skillSettingsShadowed => 'Another source overrides this skill.';

  @override
  String get skillSettingsStale =>
      'This file no longer parses; the last good version is shown.';

  @override
  String get skillSettingsSource => 'Source';

  @override
  String get skillSettingsSourceBuiltIn => 'Built-in';

  @override
  String get skillSettingsSourceUserHome => 'Global';

  @override
  String get skillSettingsSourceConfig => 'Settings';

  @override
  String get skillSettingsSourceProject => 'Project';

  @override
  String get skillSettingsProject => 'Project';

  @override
  String get skillSettingsProjectNone => 'Global skills only';

  @override
  String get skillSettingsProjectHint =>
      'Pick a project to see and edit the skills committed to it.';

  @override
  String get settingsCategoryMcp => 'MCP';

  @override
  String get mcpSettingsHeading => 'MCP servers';

  @override
  String get mcpSettingsAdd => 'Add MCP server';

  @override
  String get mcpSettingsEmpty => 'No MCP servers are configured.';

  @override
  String get mcpSettingsSelectServer => 'Select a server to edit it.';

  @override
  String get mcpSettingsScopeUser => 'Yours';

  @override
  String get mcpSettingsScopeProject => 'This project';

  @override
  String get mcpSettingsProjectReadOnly =>
      'Defined by this repository, so Coder does not edit it.';

  @override
  String get mcpSettingsShadowed => 'Hidden by your server of the same name';

  @override
  String mcpSettingsSource(String path) {
    return 'Defined in $path';
  }

  @override
  String get mcpSettingsServerId => 'ID';

  @override
  String get mcpSettingsServerIdInvalid =>
      'Use lower-case letters, digits, - and _.';

  @override
  String get mcpSettingsTransport => 'Transport';

  @override
  String get mcpSettingsTransportStdio => 'Command';

  @override
  String get mcpSettingsTransportHttp => 'HTTP';

  @override
  String get mcpSettingsCommand => 'Command';

  @override
  String get mcpSettingsArgs => 'Arguments (one per line)';

  @override
  String get mcpSettingsWorkingDirectory => 'Working directory (optional)';

  @override
  String get mcpSettingsUrl => 'URL';

  @override
  String get mcpSettingsEnvironment => 'Environment (KEY=value, one per line)';

  @override
  String get mcpSettingsHeaders => 'Headers (Name: value, one per line)';

  @override
  String get mcpSettingsEnabled => 'Enabled';

  @override
  String get mcpSettingsSecretHint =>
      'Never paste a secret here. Reference a stored secret or an environment variable instead:';

  @override
  String get mcpSettingsTest => 'Test connection';

  @override
  String mcpSettingsTestSucceeded(int count) {
    return 'Connected and found $count tools.';
  }

  @override
  String mcpSettingsTestFailed(String error) {
    return 'Could not connect: $error';
  }

  @override
  String get mcpSettingsDelete => 'Delete server';

  @override
  String mcpSettingsDeleteConfirm(String name) {
    return 'Delete $name? Agents using its tools will lose them.';
  }

  @override
  String get mcpSettingsStatusDisabled => 'Disabled';

  @override
  String get mcpSettingsStatusConnecting => 'Connecting';

  @override
  String get mcpSettingsStatusReady => 'Ready';

  @override
  String get mcpSettingsStatusFailed => 'Failed';

  @override
  String get mcpSettingsDiscoveredTools => 'Tools';

  @override
  String get mcpSettingsNoTools => 'This server publishes no tools.';

  @override
  String get mcpSettingsDiagnostics => 'Server output';

  @override
  String get mcpSettingsSecretSet => 'Store a secret';

  @override
  String get mcpSettingsSecretKey => 'Reference name';

  @override
  String get mcpSettingsSecretValue => 'Value';

  @override
  String get agentSettingsToolAlwaysOn => 'Always available';
}
