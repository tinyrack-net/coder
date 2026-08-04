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
  String get settingsCategoryGeneral => 'General';

  @override
  String get settingsCategoryProjects => 'Projects';

  @override
  String get settingsCategoryAgent => 'Agent';

  @override
  String get settingsCategoryProvider => 'Provider';

  @override
  String get settingsCategoryDaemon => 'Daemon';

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
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceSidebarExpand => 'Show sidebar';

  @override
  String get workspaceSidebarCollapse => 'Hide sidebar';

  @override
  String get workspaceNewSession => 'New session';

  @override
  String get workspaceAllSessions => 'All sessions';

  @override
  String get workspaceCloseTab => 'Close tab';

  @override
  String get workspaceNewWorkspace => 'New workspace';

  @override
  String get workspaceWorktreeMenu => 'Worktree menu';

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
  String get agentSettingsDaemonDefaultModel => 'Daemon default provider/model';

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
  String get providerSettingsConnected => 'Connected';

  @override
  String get providerSettingsNoConnections => 'No providers are connected.';

  @override
  String get providerSettingsDefaultChip => 'Default';

  @override
  String get providerSettingsMakeDefault => 'Make default provider';

  @override
  String get providerSettingsEditAdvanced => 'Edit advanced settings';

  @override
  String get providerSettingsModelsLoading => 'Loading models…';

  @override
  String get providerSettingsNoModels => 'No models are available.';

  @override
  String get providerSettingsSelectModel => 'Select a model';

  @override
  String get providerSettingsDefaultModel => 'Default model';

  @override
  String get providerSettingsModelMissing => 'Not in the catalog';

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
  String get modelPickerTitle => 'Select the default model';

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
  String get composerSelectProvider => 'Select a provider';

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
  String get composerSelectProviderFirst =>
      'Select a provider and model first.';

  @override
  String get composerPlanBanner =>
      'Plan mode · drafts a plan without carrying it out';

  @override
  String get composerInputHint => 'Type a coding request…';

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
  String get chatPlanTitle => 'Proposed plan';

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
}
