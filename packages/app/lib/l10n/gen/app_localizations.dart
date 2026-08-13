import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// Dismisses a dialog without applying it.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Commits an edited form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Save button label while the write is in flight.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// Confirms a creation dialog.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// Create button label while the write is in flight.
  ///
  /// In en, this message translates to:
  /// **'Creating…'**
  String get commonCreating;

  /// Acknowledges an informational dialog.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonConfirm;

  /// Removes a stored record.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Runs a failed load again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Search field placeholder shared by Select controls.
  ///
  /// In en, this message translates to:
  /// **'Search options'**
  String get selectSearchPlaceholder;

  /// Empty result shown by searchable Select controls.
  ///
  /// In en, this message translates to:
  /// **'No matching options.'**
  String get selectNoResults;

  /// Closes a sheet or dialog.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// Copies content to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Halts a running operation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get commonStop;

  /// Text field label for a human-readable name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// Text field label for a record type.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get commonKind;

  /// Text field label for a free-form description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// Status shown while work is in progress.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get commonRunning;

  /// Status shown when work finished successfully.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Opens a fuller view of a summary.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// Confirmation shown after a successful write.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get commonSaved;

  /// Confirmation shown after a successful removal.
  ///
  /// In en, this message translates to:
  /// **'Deleted.'**
  String get commonDeleted;

  /// Confirmation shown after copying a value the screen does not otherwise change to show.
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard.'**
  String get commonCopied;

  /// Fallback title for an action that failed without a more specific message.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get commonActionFailed;

  /// Accessible name of the region that announces the result of an action.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get toastRegionLabel;

  /// Title of the settings shell.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Accessible status for a settings skeleton while data is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading settings'**
  String get settingsLoading;

  /// Non-blocking error shown when refreshing already visible settings fails.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh settings: {error}'**
  String settingsRefreshFailed(String error);

  /// Settings sidebar heading over the app-wide categories.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// Settings sidebar heading over the categories owned by one daemon.
  ///
  /// In en, this message translates to:
  /// **'Daemon'**
  String get settingsSectionDaemon;

  /// Label of the sidebar picker choosing which daemon to edit.
  ///
  /// In en, this message translates to:
  /// **'Daemon'**
  String get settingsDaemonSelectLabel;

  /// Placeholder in the daemon picker when no daemon is configured.
  ///
  /// In en, this message translates to:
  /// **'No daemons'**
  String get settingsDaemonSelectEmpty;

  /// Shown when the selected daemon cannot serve its settings.
  ///
  /// In en, this message translates to:
  /// **'{label} is not connected.'**
  String settingsDaemonOffline(String label);

  /// Settings sidebar entry for app-wide preferences.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsCategoryGeneral;

  /// Settings sidebar entry for per-project hooks.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get settingsCategoryProjects;

  /// Settings sidebar entry for agent definitions.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get settingsCategoryAgent;

  /// Settings sidebar entry for provider connections.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsCategoryProvider;

  /// Settings sidebar entry for the daemon default model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsCategoryModel;

  /// Settings sidebar entry for daemon permission defaults.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsCategoryPermission;

  /// Settings sidebar entry for daemon connections.
  ///
  /// In en, this message translates to:
  /// **'Daemons'**
  String get settingsCategoryDaemon;

  /// Settings sidebar entry for developer maintenance actions.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsCategoryAdvanced;

  /// Heading of the full reset card.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get advancedResetSection;

  /// Title of the full reset row.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get advancedResetTitle;

  /// Scope of a reset on a surface that owns an embedded daemon.
  ///
  /// In en, this message translates to:
  /// **'Deletes the embedded daemon\'s database, credentials, MCP and agent configuration, skills, and attachments, and clears every app setting and stored remote daemon token. Git checkouts under the worktrees folder stay on disk.'**
  String get advancedResetDescription;

  /// Scope of a reset on a surface without an embedded daemon.
  ///
  /// In en, this message translates to:
  /// **'Clears every app setting and stored remote daemon token on this device. Remote daemons keep their own data.'**
  String get advancedResetDescriptionAppOnly;

  /// Label of the button that starts a full reset.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get advancedResetAction;

  /// Label of the reset button while a reset runs.
  ///
  /// In en, this message translates to:
  /// **'Resetting…'**
  String get advancedResetRunning;

  /// Title of the full reset confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset all data?'**
  String get advancedResetConfirmTitle;

  /// Body of the full reset confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Every session, workspace registration, provider connection, agent, skill, and MCP server on the embedded daemon is deleted, together with every app setting and remote daemon profile and token. The daemon returns to its default port. Git checkouts stay on disk but have to be added again. This cannot be undone.'**
  String get advancedResetConfirmBody;

  /// Confirm action of the full reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get advancedResetConfirmAccept;

  /// Reported after a factory reset finishes and the app returns to the workspace.
  ///
  /// In en, this message translates to:
  /// **'Reset to factory defaults.'**
  String get advancedResetDone;

  /// Title of the alert shown when a reset fails.
  ///
  /// In en, this message translates to:
  /// **'Reset failed'**
  String get advancedResetFailedTitle;

  /// Reset failure caused by a daemon owning the data directory.
  ///
  /// In en, this message translates to:
  /// **'Another {appDisplayName} daemon is using the data directory. Quit it and try again. Nothing was deleted.'**
  String advancedResetFailedDaemonRunning(String appDisplayName);

  /// Reset failure reported by the operating system.
  ///
  /// In en, this message translates to:
  /// **'Some daemon files could not be deleted: {error}'**
  String advancedResetFailedFilesystem(String error);

  /// Reset failure that leaves device-local settings behind.
  ///
  /// In en, this message translates to:
  /// **'Daemon data was removed but the app settings could not be cleared. Restart {appDisplayName}.'**
  String advancedResetFailedIncomplete(String appDisplayName);

  /// Shown when a host-scoped settings page has no online daemon.
  ///
  /// In en, this message translates to:
  /// **'Connect an online daemon first.'**
  String get settingsRequiresOnlineDaemon;

  /// Heading of the appearance card on the General settings page.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get generalAppearanceSection;

  /// Dropdown label for the app theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get generalAppearanceLabel;

  /// Explains the scope of the theme setting.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole app and is remembered the next time you start it.'**
  String get generalAppearanceDescription;

  /// Theme option that follows the operating system brightness.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get generalAppearanceSystem;

  /// Theme option that always paints the light theme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get generalAppearanceLight;

  /// Theme option that always paints the dark theme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get generalAppearanceDark;

  /// Heading of the language card on the General settings page.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get generalLanguageSection;

  /// Dropdown label for the app UI language.
  ///
  /// In en, this message translates to:
  /// **'Display language'**
  String get generalLanguageLabel;

  /// Explains the scope of the language setting.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole app and takes effect immediately.'**
  String get generalLanguageDescription;

  /// Language option that follows the operating system locale.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get generalLanguageSystem;

  /// Heading of the startup card on the General settings page.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get generalStartupSection;

  /// Switch label for launching the app when the user logs in.
  ///
  /// In en, this message translates to:
  /// **'Start at login'**
  String get generalStartupAtBootLabel;

  /// Explains what the start-at-login switch registers with the operating system.
  ///
  /// In en, this message translates to:
  /// **'The operating system launches {appDisplayName} after you sign in, so the embedded daemon keeps running.'**
  String generalStartupAtBootDescription(String appDisplayName);

  /// Switch label for starting hidden in the tray at login.
  ///
  /// In en, this message translates to:
  /// **'Start minimized'**
  String get generalStartupMinimizedLabel;

  /// Explains that start-minimized applies only to login launches.
  ///
  /// In en, this message translates to:
  /// **'A login-time launch goes straight to the tray without opening a window.'**
  String get generalStartupMinimizedDescription;

  /// Reported when the chosen theme could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not change the appearance.'**
  String get generalAppearanceFailed;

  /// Reported when the chosen language could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not change the language.'**
  String get generalLanguageFailed;

  /// Reported when a login-item preference could not be applied.
  ///
  /// In en, this message translates to:
  /// **'Could not change the startup setting.'**
  String get generalStartupFailed;

  /// Explains that the window close button no longer quits the app.
  ///
  /// In en, this message translates to:
  /// **'Closing the window keeps {appDisplayName} running in the tray.'**
  String generalStartupCloseNotice(String appDisplayName);

  /// Hover text of the tray icon.
  ///
  /// In en, this message translates to:
  /// **'{appDisplayName}'**
  String trayTooltip(String appDisplayName);

  /// Tray menu row that reveals the hidden main window.
  ///
  /// In en, this message translates to:
  /// **'Show window'**
  String get trayShowWindow;

  /// Tray menu row that hides the main window into the tray.
  ///
  /// In en, this message translates to:
  /// **'Hide window'**
  String get trayHideWindow;

  /// Tray menu row that opens the General settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get trayOpenSettings;

  /// Tray menu row that stops the embedded daemon and exits the app.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// File menu in the custom desktop title bar.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get desktopMenuFile;

  /// View menu in the custom desktop title bar.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get desktopMenuView;

  /// Help menu in the custom desktop title bar.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get desktopMenuHelp;

  /// Opens application name and version information.
  ///
  /// In en, this message translates to:
  /// **'About {appDisplayName}'**
  String desktopMenuAbout(String appDisplayName);

  /// Tooltip for the custom window minimize button.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get desktopWindowMinimize;

  /// Tooltip for the custom window maximize button.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get desktopWindowMaximize;

  /// Tooltip for restoring a maximized window.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get desktopWindowRestore;

  /// Tooltip for hiding the resident app window to the tray.
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get desktopWindowClose;

  /// Title of the workspace shell.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspacesTitle;

  /// Tooltip that reveals the collapsed workspace sidebar.
  ///
  /// In en, this message translates to:
  /// **'Show sidebar'**
  String get workspaceSidebarExpand;

  /// Tooltip that collapses the workspace sidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide sidebar'**
  String get workspaceSidebarCollapse;

  /// Tooltip that starts an AI session in the open checkout.
  ///
  /// In en, this message translates to:
  /// **'New session'**
  String get workspaceNewSession;

  /// Session tab title used when a prompt carries no readable title text.
  ///
  /// In en, this message translates to:
  /// **'Coding session'**
  String get sessionDefaultTitle;

  /// No description provided for @workspaceNewTab.
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get workspaceNewTab;

  /// No description provided for @workspaceNewTerminal.
  ///
  /// In en, this message translates to:
  /// **'New terminal'**
  String get workspaceNewTerminal;

  /// Title of a newly created terminal tab, numbered within its worktree.
  ///
  /// In en, this message translates to:
  /// **'Terminal {number}'**
  String terminalTabTitle(int number);

  /// Announced once for the workspace pane skeleton shown while sessions and terminals load.
  ///
  /// In en, this message translates to:
  /// **'Loading workspace'**
  String get workspaceLoading;

  /// Announced once for the sidebar tree skeleton shown while daemon catalogs load.
  ///
  /// In en, this message translates to:
  /// **'Loading workspaces'**
  String get workspaceCatalogLoading;

  /// Progress label while the daemon checks out a new worktree and runs its hooks.
  ///
  /// In en, this message translates to:
  /// **'Creating worktree…'**
  String get workspaceCreatingWorktree;

  /// Progress label while the daemon creates the session for a submitted prompt.
  ///
  /// In en, this message translates to:
  /// **'Starting session…'**
  String get workspaceStartingSession;

  /// Label of a placeholder terminal tab while the daemon creates its shell.
  ///
  /// In en, this message translates to:
  /// **'Starting terminal'**
  String get workspaceTerminalStarting;

  /// Error shown after a placeholder terminal tab is rolled back.
  ///
  /// In en, this message translates to:
  /// **'Could not start terminal: {error}'**
  String workspaceTerminalStartFailed(String error);

  /// No description provided for @terminalCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Terminate terminal?'**
  String get terminalCloseTitle;

  /// No description provided for @terminalCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Closing this tab terminates its shell and child processes.'**
  String get terminalCloseConfirm;

  /// No description provided for @terminalTerminate.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminalTerminate;

  /// No description provided for @terminalConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Terminal connection failed'**
  String get terminalConnectionFailed;

  /// Overlay label shown while a terminal pane attaches to its daemon shell.
  ///
  /// In en, this message translates to:
  /// **'Connecting to terminal'**
  String get terminalConnecting;

  /// Announced once for the chat timeline skeleton shown while session history loads.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation'**
  String get conversationLoading;

  /// Announced once for the row skeletons shown while the first directory listing loads.
  ///
  /// In en, this message translates to:
  /// **'Loading directories'**
  String get directoryBrowserLoading;

  /// No description provided for @terminalCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create terminal'**
  String get terminalCreationFailed;

  /// No description provided for @terminalWorktreeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This worktree is no longer available. Choose another worktree.'**
  String get terminalWorktreeUnavailable;

  /// No description provided for @terminalShellStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The configured terminal shell couldn\'t be started. Check terminal settings and try again.'**
  String get terminalShellStartFailed;

  /// No description provided for @terminalMenuCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get terminalMenuCopy;

  /// No description provided for @terminalMenuPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get terminalMenuPaste;

  /// No description provided for @terminalMenuSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get terminalMenuSelectAll;

  /// No description provided for @terminalMenuClearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get terminalMenuClearSelection;

  /// No description provided for @terminalMenuClearScreen.
  ///
  /// In en, this message translates to:
  /// **'Clear screen'**
  String get terminalMenuClearScreen;

  /// Section heading for the per-project worktree hooks.
  ///
  /// In en, this message translates to:
  /// **'Worktree lifecycle hooks'**
  String get projectSettingsHookHeading;

  /// No description provided for @projectSettingsShellHeading.
  ///
  /// In en, this message translates to:
  /// **'Project terminal shell'**
  String get projectSettingsShellHeading;

  /// No description provided for @projectSettingsShellHelp.
  ///
  /// In en, this message translates to:
  /// **'Overrides the daemon host shell for terminals opened in this project. Leave the executable empty to inherit the host default.'**
  String get projectSettingsShellHelp;

  /// No description provided for @projectSettingsShellExecutable.
  ///
  /// In en, this message translates to:
  /// **'Shell executable'**
  String get projectSettingsShellExecutable;

  /// No description provided for @projectSettingsShellArguments.
  ///
  /// In en, this message translates to:
  /// **'Shell arguments (one per line)'**
  String get projectSettingsShellArguments;

  /// No description provided for @projectSettingsHostShellHeading.
  ///
  /// In en, this message translates to:
  /// **'Daemon host default shell'**
  String get projectSettingsHostShellHeading;

  /// No description provided for @projectSettingsHostShellHelp.
  ///
  /// In en, this message translates to:
  /// **'Used by every project on this daemon host unless the project overrides it. Leave the executable empty to use the operating system default.'**
  String get projectSettingsHostShellHelp;

  /// Tooltip that lists every session of the open checkout.
  ///
  /// In en, this message translates to:
  /// **'All sessions'**
  String get workspaceAllSessions;

  /// Splits a workspace pane with a new pane on the right.
  ///
  /// In en, this message translates to:
  /// **'Split right'**
  String get workspaceSplitRight;

  /// Splits a workspace pane with a new pane below.
  ///
  /// In en, this message translates to:
  /// **'Split down'**
  String get workspaceSplitDown;

  /// Accessible label for a draggable pane separator.
  ///
  /// In en, this message translates to:
  /// **'Resize panes'**
  String get workspaceResizePanes;

  /// Moves the active tab to another pane without dragging.
  ///
  /// In en, this message translates to:
  /// **'Move active tab to pane'**
  String get workspaceMoveTabToPane;

  /// Tooltip that closes one session tab.
  ///
  /// In en, this message translates to:
  /// **'Close tab'**
  String get workspaceCloseTab;

  /// Opens the new-workspace composer.
  ///
  /// In en, this message translates to:
  /// **'New workspace'**
  String get workspaceNewWorkspace;

  /// Tooltip of the per-worktree overflow menu.
  ///
  /// In en, this message translates to:
  /// **'Worktree menu'**
  String get workspaceWorktreeMenu;

  /// Accessible label for a registered project's action menu.
  ///
  /// In en, this message translates to:
  /// **'Project menu'**
  String get workspaceProjectMenu;

  /// Removes a project registration without deleting its files.
  ///
  /// In en, this message translates to:
  /// **'Remove project'**
  String get workspaceUnregister;

  /// Confirmation title for removing a project registration.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String workspaceUnregisterTitle(String name);

  /// Explains that unregistering a project is non-destructive.
  ///
  /// In en, this message translates to:
  /// **'The project disappears from {appName}, but its repository and files stay on disk.'**
  String workspaceUnregisterBody(String appName);

  /// Menu entry and button that archives a checkout.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get workspaceArchive;

  /// Dialog title when running sessions block an archive.
  ///
  /// In en, this message translates to:
  /// **'Cannot archive'**
  String get workspaceArchiveBlockedTitle;

  /// Explains that sessions must be stopped before archiving.
  ///
  /// In en, this message translates to:
  /// **'Stop the {count} running session(s) first.'**
  String workspaceArchiveBlockedBody(int count);

  /// Confirmation title for archiving one checkout.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String workspaceArchiveTitle(String name);

  /// Archive warning fragment for a dirty checkout.
  ///
  /// In en, this message translates to:
  /// **'It has uncommitted changes.\n'**
  String get workspaceArchiveDirty;

  /// Archive warning fragment for unpushed commits.
  ///
  /// In en, this message translates to:
  /// **'It has {count} unpushed commit(s).\n'**
  String workspaceArchiveUnpushed(int count);

  /// Archive effect for a removable checkout.
  ///
  /// In en, this message translates to:
  /// **'The checkout directory will be removed.'**
  String get workspaceArchiveRemovesDirectory;

  /// Archive confirmation label when the checkout has unsaved work.
  ///
  /// In en, this message translates to:
  /// **'Confirm the risks and archive'**
  String get workspaceArchiveRisky;

  /// Empty state of the workspace sidebar.
  ///
  /// In en, this message translates to:
  /// **'No daemons are configured.'**
  String get workspaceNoDaemons;

  /// Sidebar empty state when every configured daemon is offline.
  ///
  /// In en, this message translates to:
  /// **'No daemon is connected.'**
  String get workspaceNoConnectedDaemons;

  /// Sidebar empty state when connected daemons have no workspace.
  ///
  /// In en, this message translates to:
  /// **'No workspaces yet.'**
  String get workspaceNoWorkspaces;

  /// Sidebar section listing sessions that belong to no project.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get workspaceNoProjectSessions;

  /// Composer choice that starts a session in the user home.
  ///
  /// In en, this message translates to:
  /// **'No project (home folder)'**
  String get workspaceNoProjectOption;

  /// Label of the new-workspace project chip before a project is chosen.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get workspaceProjectChip;

  /// Tooltip of the new-workspace project chip.
  ///
  /// In en, this message translates to:
  /// **'Select a project'**
  String get workspaceProjectChipTooltip;

  /// Menu entry that registers another project from the new-workspace chip.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get workspaceProjectAdd;

  /// New-workspace worktree chip and menu entry that creates a fresh checkout.
  ///
  /// In en, this message translates to:
  /// **'New worktree'**
  String get workspaceWorktreeNew;

  /// Tooltip of the new-workspace worktree chip.
  ///
  /// In en, this message translates to:
  /// **'Select a worktree'**
  String get workspaceWorktreeChipTooltip;

  /// Label of the new-workspace base branch chip before a branch is chosen.
  ///
  /// In en, this message translates to:
  /// **'Base branch'**
  String get workspaceBaseBranchChip;

  /// Tooltip of the new-workspace base branch chip.
  ///
  /// In en, this message translates to:
  /// **'Select a base branch'**
  String get workspaceBaseBranchChipTooltip;

  /// Composer hint when no project is registered.
  ///
  /// In en, this message translates to:
  /// **'Add a project first.'**
  String get workspaceAddProjectFirst;

  /// Composer hint when no project is selected.
  ///
  /// In en, this message translates to:
  /// **'Select a project.'**
  String get workspaceSelectProject;

  /// Composer hint when a directory project has no checkout.
  ///
  /// In en, this message translates to:
  /// **'No project checkout was found.'**
  String get workspaceCheckoutMissing;

  /// Composer error when no daemon is connected.
  ///
  /// In en, this message translates to:
  /// **'A daemon connection is required.'**
  String get workspaceDaemonRequired;

  /// Button that opens daemon settings from the empty sidebar.
  ///
  /// In en, this message translates to:
  /// **'Daemon settings'**
  String get workspaceOpenDaemonSettings;

  /// Title of the failure alert on the new workspace screen.
  ///
  /// In en, this message translates to:
  /// **'The session could not be started'**
  String get workspaceStartFailedTitle;

  /// Composer hint when no provider model is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider and model first.'**
  String get composerSelectProviderModel;

  /// Daemon rejected a branch name that is already taken.
  ///
  /// In en, this message translates to:
  /// **'A branch with that name already exists. Choose another name.'**
  String get errorBranchAlreadyExists;

  /// Daemon rejected a worktree path that is already occupied.
  ///
  /// In en, this message translates to:
  /// **'Another checkout already uses that folder.'**
  String get errorWorktreePathInUse;

  /// Daemon rejected a branch name that is not a valid Git ref.
  ///
  /// In en, this message translates to:
  /// **'That name can\'t be used as a Git branch.'**
  String get errorInvalidBranchName;

  /// A Git invocation exited non-zero.
  ///
  /// In en, this message translates to:
  /// **'A Git command failed. The details below are Git\'s own output.'**
  String get errorGitCommandFailed;

  /// Daemon could not find the referenced workspace.
  ///
  /// In en, this message translates to:
  /// **'That project is no longer registered with the daemon.'**
  String get errorWorkspaceNotFound;

  /// Operation requires a Git repository.
  ///
  /// In en, this message translates to:
  /// **'That project is not a Git repository, so it has no worktrees.'**
  String get errorWorkspaceNotGit;

  /// Home workspace cannot be registered or removed.
  ///
  /// In en, this message translates to:
  /// **'The daemon owns that folder and manages it itself.'**
  String get errorWorkspaceProtected;

  /// Daemon could not find the referenced worktree.
  ///
  /// In en, this message translates to:
  /// **'That checkout is no longer registered with the daemon.'**
  String get errorWorktreeNotFound;

  /// Archive refused because of running sessions or local changes.
  ///
  /// In en, this message translates to:
  /// **'This checkout can\'t be archived right now.'**
  String get errorWorktreeArchiveBlocked;

  /// Referenced agent definition was deleted.
  ///
  /// In en, this message translates to:
  /// **'That agent no longer exists. Choose another agent.'**
  String get errorAgentDefinitionNotFound;

  /// Referenced agent definition exists but cannot start a session.
  ///
  /// In en, this message translates to:
  /// **'That agent can\'t start a session. Choose another agent.'**
  String get errorAgentDefinitionUnusable;

  /// The daemon rejected a request as unknown or malformed, which means version skew.
  ///
  /// In en, this message translates to:
  /// **'This app and the daemon speak different protocol versions. Update both to the same release.'**
  String get errorProtocolMismatch;

  /// A project settings file failed to parse.
  ///
  /// In en, this message translates to:
  /// **'The project\'s .tinest/config.json could not be read. Fix the file and try again.'**
  String get errorInvalidProjectSettings;

  /// A request exceeded the client deadline.
  ///
  /// In en, this message translates to:
  /// **'The daemon didn\'t respond in time. Try again.'**
  String get errorRequestTimeout;

  /// Unexpected daemon-side failure with a trace id in the details.
  ///
  /// In en, this message translates to:
  /// **'The daemon hit an unexpected problem. Copy the details below when reporting it.'**
  String get errorInternalDaemon;

  /// A session setting such as the mode or the model was changed while a turn was still streaming.
  ///
  /// In en, this message translates to:
  /// **'This session is running a turn. Wait for it to finish or stop it, then change the setting.'**
  String get errorSessionTurnActive;

  /// Fallback shown when a session setting change fails for a reason the daemon did not name.
  ///
  /// In en, this message translates to:
  /// **'The session setting could not be changed.'**
  String get errorSessionSettingFailed;

  /// Daemon runtime status.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get hostStatusOnline;

  /// Daemon runtime status.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get hostStatusConnecting;

  /// Daemon runtime status.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get hostStatusReconnecting;

  /// Daemon runtime status.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get hostStatusOffline;

  /// Daemon runtime status.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get hostStatusError;

  /// Daemon runtime status when two profiles reach the same daemon.
  ///
  /// In en, this message translates to:
  /// **'Duplicate daemon'**
  String get hostStatusConflict;

  /// Daemon runtime status when auto-connect is disabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect off'**
  String get hostStatusIdle;

  /// Daemon status before a runtime exists.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get hostStatusPending;

  /// Display name of the app-owned desktop daemon.
  ///
  /// In en, this message translates to:
  /// **'Embedded daemon'**
  String get embeddedDaemonName;

  /// Validation error when a remote profile has no token.
  ///
  /// In en, this message translates to:
  /// **'Enter a bearer token.'**
  String get hostErrorMissingToken;

  /// Connection failure when the stored token is missing.
  ///
  /// In en, this message translates to:
  /// **'No bearer token is stored.'**
  String get hostErrorNoToken;

  /// Connection failure when two profiles reach the same daemon.
  ///
  /// In en, this message translates to:
  /// **'That daemon is already registered.'**
  String get hostErrorDuplicate;

  /// Connection failure when the daemon returns 401.
  ///
  /// In en, this message translates to:
  /// **'The daemon rejected the bearer token.'**
  String get hostErrorUnauthorized;

  /// Embedded daemon startup failure when its listener port is occupied.
  ///
  /// In en, this message translates to:
  /// **'The selected port is already in use.'**
  String get hostErrorEmbeddedPortInUse;

  /// Embedded daemon startup failure when another process already holds the daemon home.
  ///
  /// In en, this message translates to:
  /// **'{appName} is already running on this computer and owns the local daemon. Open the running copy from the system tray, or quit it and retry.'**
  String hostErrorEmbeddedAlreadyRunning(String appName);

  /// Connection failure in a browser for a daemon on the local machine or network, where the browser does not report whether the daemon was down or the Local Network Access permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the daemon. Check that it is running, and that you allowed this site to access your local network.'**
  String get hostErrorLocalNetworkUnreachable;

  /// Connection failure when the running platform has no relay pairing support.
  ///
  /// In en, this message translates to:
  /// **'Relay pairing is not available on this platform.'**
  String get hostErrorRelayPairingUnavailable;

  /// Connection failure when an address now answers as a different daemon than the one saved under this profile.
  ///
  /// In en, this message translates to:
  /// **'That address now reaches a different daemon than the one saved here.'**
  String get hostErrorServerIdentityMismatch;

  /// Connection failure when the stored credential is of the wrong kind for the profile's connection path.
  ///
  /// In en, this message translates to:
  /// **'The stored credential does not match this connection path.'**
  String get hostErrorCredentialMismatch;

  /// Title of the standalone daemon settings page.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettingsTitle;

  /// Heading of the embedded daemon card.
  ///
  /// In en, this message translates to:
  /// **'Local execution'**
  String get appSettingsLocalSection;

  /// Explains the embedded daemon toggle.
  ///
  /// In en, this message translates to:
  /// **'Starts with the app and stops when it exits. A failed start does not block the app.'**
  String get appSettingsEmbeddedSubtitle;

  /// Toggle that binds the embedded daemon to every interface.
  ///
  /// In en, this message translates to:
  /// **'Allow network access'**
  String get appSettingsExposure;

  /// Explains the embedded daemon exposure toggle.
  ///
  /// In en, this message translates to:
  /// **'Off accepts connections from this machine only; on accepts them on every IPv4 interface.'**
  String get appSettingsExposureSubtitle;

  /// Numeric listener port for the embedded daemon.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get appSettingsEmbeddedPort;

  /// Explains the embedded daemon port setting.
  ///
  /// In en, this message translates to:
  /// **'Choose a port from 1 to 65535. Applying restarts the embedded daemon when it is running.'**
  String get appSettingsEmbeddedPortHelp;

  /// Validation message for an invalid embedded daemon port.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 65535.'**
  String get appSettingsEmbeddedPortInvalid;

  /// Saves the embedded daemon port and restarts it when active.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get appSettingsEmbeddedPortApply;

  /// Persistent alert title for an embedded daemon startup or connection failure.
  ///
  /// In en, this message translates to:
  /// **'The embedded daemon could not start'**
  String get appSettingsEmbeddedFailureTitle;

  /// Resolution guidance for an occupied embedded daemon port.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is being used by another process. Choose another port and apply it, or retry after the port becomes available.'**
  String appSettingsEmbeddedPortConflict(int port);

  /// Heading of the remote daemon list.
  ///
  /// In en, this message translates to:
  /// **'Remote daemons'**
  String get appSettingsRemoteSection;

  /// Opens the remote daemon form.
  ///
  /// In en, this message translates to:
  /// **'Add remote daemon'**
  String get appSettingsAddRemote;

  /// No description provided for @relayPairTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a device'**
  String get relayPairTitle;

  /// No description provided for @relayPairDeviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code or copy a link to connect your other device to this daemon.'**
  String get relayPairDeviceDescription;

  /// No description provided for @relayPairDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code on your other device, or copy the connection link below.'**
  String get relayPairDialogDescription;

  /// No description provided for @relayConnectDaemonTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect a daemon'**
  String get relayConnectDaemonTitle;

  /// No description provided for @relayConnectDaemonDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how to connect to a daemon. Relay links keep daemon traffic end-to-end encrypted.'**
  String get relayConnectDaemonDescription;

  /// No description provided for @relayConnectScanDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan the one-time QR code shown by the daemon.'**
  String get relayConnectScanDescription;

  /// No description provided for @relayConnectPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste connection link'**
  String get relayConnectPasteTitle;

  /// No description provided for @relayConnectPasteDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste the one-time link shown by the daemon.'**
  String get relayConnectPasteDescription;

  /// No description provided for @relayConnectDirectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect with a WebSocket address and bearer token.'**
  String get relayConnectDirectDescription;

  /// No description provided for @relayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Review daemon connection'**
  String get relayConfirmTitle;

  /// No description provided for @relayConfirmDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirm the daemon and relay before registering this device.'**
  String get relayConfirmDescription;

  /// No description provided for @relayConfirmDaemon.
  ///
  /// In en, this message translates to:
  /// **'Daemon ID'**
  String get relayConfirmDaemon;

  /// No description provided for @relayConfirmRelay.
  ///
  /// In en, this message translates to:
  /// **'Relay server'**
  String get relayConfirmRelay;

  /// No description provided for @relayConfirmExpires.
  ///
  /// In en, this message translates to:
  /// **'Link expires'**
  String get relayConfirmExpires;

  /// No description provided for @relayShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get relayShare;

  /// No description provided for @relayRefreshLink.
  ///
  /// In en, this message translates to:
  /// **'Create a new link'**
  String get relayRefreshLink;

  /// No description provided for @relayEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect this daemon through the relay'**
  String get relayEnableTitle;

  /// No description provided for @relayEnableDescription.
  ///
  /// In en, this message translates to:
  /// **'The daemon will open an outbound encrypted connection to the separate Tinyrack relay server so your other devices can reach it.'**
  String get relayEnableDescription;

  /// No description provided for @relayEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable relay connection'**
  String get relayEnableAction;

  /// No description provided for @settingsCategoryConnection.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get settingsCategoryConnection;

  /// No description provided for @relayPairDescription.
  ///
  /// In en, this message translates to:
  /// **'Paste the one-time link shown by the daemon. Its code and files stay end-to-end encrypted through the relay.'**
  String get relayPairDescription;

  /// No description provided for @relayPairLink.
  ///
  /// In en, this message translates to:
  /// **'Pairing link'**
  String get relayPairLink;

  /// No description provided for @relayPairDeviceName.
  ///
  /// In en, this message translates to:
  /// **'This device\'s name'**
  String get relayPairDeviceName;

  /// No description provided for @relayPairAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get relayPairAction;

  /// No description provided for @relayPairScan.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get relayPairScan;

  /// No description provided for @relayPairCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'QR scanning is available on Android and iOS. Paste the connection link on this device instead.'**
  String get relayPairCameraUnavailable;

  /// No description provided for @relayPairCameraError.
  ///
  /// In en, this message translates to:
  /// **'{appDisplayName} could not open the camera. Allow camera access in system settings, then try again.'**
  String relayPairCameraError(String appDisplayName);

  /// No description provided for @relayPairCameraRetry.
  ///
  /// In en, this message translates to:
  /// **'Try camera again'**
  String get relayPairCameraRetry;

  /// No description provided for @relayPairQrSemantics.
  ///
  /// In en, this message translates to:
  /// **'QR code for the one-time device connection link'**
  String get relayPairQrSemantics;

  /// No description provided for @relayPairInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {appDisplayName} pairing link.'**
  String relayPairInvalid(String appDisplayName);

  /// No description provided for @relayPairExpired.
  ///
  /// In en, this message translates to:
  /// **'This pairing link expired or was already used. Create a new link on the daemon.'**
  String get relayPairExpired;

  /// No description provided for @relayPairFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect this daemon. Create a new link on the daemon and try again.'**
  String get relayPairFailed;

  /// No description provided for @relayAdvancedDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct connection'**
  String get relayAdvancedDirect;

  /// No description provided for @relayAdvancedRelayEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Relay server address'**
  String get relayAdvancedRelayEndpoint;

  /// No description provided for @relayAdvancedRelayEndpointChange.
  ///
  /// In en, this message translates to:
  /// **'Change relay server address'**
  String get relayAdvancedRelayEndpointChange;

  /// No description provided for @relayAdvancedRelayEndpointHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the official relay by default, or enter a self-hosted WebSocket endpoint.'**
  String get relayAdvancedRelayEndpointHelp;

  /// No description provided for @relayDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get relayDevicesTitle;

  /// No description provided for @relayDevicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a ten-minute link for a new device or remove a device that should no longer connect.'**
  String get relayDevicesDescription;

  /// No description provided for @relayCreateLink.
  ///
  /// In en, this message translates to:
  /// **'Create connection link'**
  String get relayCreateLink;

  /// No description provided for @relayLinkExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {expiresAt}'**
  String relayLinkExpires(String expiresAt);

  /// No description provided for @relayNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices are approved.'**
  String get relayNoDevices;

  /// No description provided for @relayRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get relayRevoke;

  /// No description provided for @relayRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}?'**
  String relayRevokeTitle(String name);

  /// No description provided for @relayRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'The device\'s live relay connection ends immediately. A new pairing link is required to reconnect.'**
  String get relayRevokeBody;

  /// No description provided for @relayPathDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get relayPathDirect;

  /// No description provided for @relayPathRelay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get relayPathRelay;

  /// No description provided for @relayConnectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get relayConnectionDetails;

  /// No description provided for @relayApprovedDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get relayApprovedDevices;

  /// Empty state of the remote daemon list.
  ///
  /// In en, this message translates to:
  /// **'No remote daemons are saved.'**
  String get appSettingsNoRemotes;

  /// Confirmation title for disabling the embedded daemon.
  ///
  /// In en, this message translates to:
  /// **'Stop the embedded daemon?'**
  String get appSettingsStopEmbeddedTitle;

  /// Explains the blast radius of stopping the embedded daemon.
  ///
  /// In en, this message translates to:
  /// **'This stops only the daemon this app owns, along with its connection. Remote and standalone daemons are unaffected.'**
  String get appSettingsStopEmbeddedBody;

  /// Tooltip that opens the remote daemon form.
  ///
  /// In en, this message translates to:
  /// **'Edit connection'**
  String get appSettingsEditConnection;

  /// Toggle that reconnects a daemon at launch.
  ///
  /// In en, this message translates to:
  /// **'Connect on app start'**
  String get appSettingsAutoConnect;

  /// Retries a daemon connection.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get appSettingsReconnect;

  /// Opens provider settings for one daemon.
  ///
  /// In en, this message translates to:
  /// **'Provider settings'**
  String get appSettingsProviderSettings;

  /// Title of the remote daemon form when creating.
  ///
  /// In en, this message translates to:
  /// **'Add remote daemon'**
  String get appSettingsAddRemoteTitle;

  /// Title of the remote daemon form when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit remote daemon'**
  String get appSettingsEditRemoteTitle;

  /// Text field label for the daemon endpoint.
  ///
  /// In en, this message translates to:
  /// **'WebSocket address'**
  String get appSettingsAddress;

  /// Example name shown in the remote daemon name field.
  ///
  /// In en, this message translates to:
  /// **'Production daemon'**
  String get appSettingsLabelPlaceholder;

  /// Text field label for replacing a stored token.
  ///
  /// In en, this message translates to:
  /// **'New bearer token (only when changing it)'**
  String get appSettingsNewToken;

  /// Text field label for the token of a new remote daemon.
  ///
  /// In en, this message translates to:
  /// **'Bearer token'**
  String get appSettingsBearerToken;

  /// Section heading for a remote daemon's name and address.
  ///
  /// In en, this message translates to:
  /// **'Daemon'**
  String get appSettingsRemoteDetails;

  /// Section heading for how the app connects to a daemon.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get appSettingsConnectionBehaviour;

  /// Alert title shown when a remote daemon fails to save.
  ///
  /// In en, this message translates to:
  /// **'Could not save the connection'**
  String get appSettingsConnectionFailed;

  /// Confirmation title for removing a remote daemon profile.
  ///
  /// In en, this message translates to:
  /// **'Delete {label}?'**
  String appSettingsDeleteTitle(String label);

  /// Explains what deleting a remote daemon profile removes.
  ///
  /// In en, this message translates to:
  /// **'The connection and the bearer token stored on this device are removed too.'**
  String get appSettingsDeleteBody;

  /// Heading of the project list pane.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectSettingsHeading;

  /// Empty state of the project settings list.
  ///
  /// In en, this message translates to:
  /// **'No projects are registered.'**
  String get projectSettingsNoProjects;

  /// Placeholder shown before a project is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select a project.'**
  String get projectSettingsSelectProject;

  /// Tooltip that returns to the project list on narrow layouts.
  ///
  /// In en, this message translates to:
  /// **'Project list'**
  String get projectSettingsProjectList;

  /// Subtitle counting registered projects.
  ///
  /// In en, this message translates to:
  /// **'{count} projects'**
  String projectSettingsCount(int count);

  /// Tooltip that copies the .tinest/config.json path.
  ///
  /// In en, this message translates to:
  /// **'Copy file location'**
  String get projectSettingsCopyPath;

  /// Explains how worktree hook commands are executed.
  ///
  /// In en, this message translates to:
  /// **'Write one command per line; they run in order in the daemon host\'s shell. The CODER_WORKTREE_PATH, CODER_PROJECT_PATH, and CODER_BRANCH environment variables are available.'**
  String get projectSettingsHookHelp;

  /// Text field label for setup hooks.
  ///
  /// In en, this message translates to:
  /// **'Setup (after a worktree is created)'**
  String get projectSettingsSetup;

  /// Text field label for teardown hooks.
  ///
  /// In en, this message translates to:
  /// **'Teardown (before a worktree is removed)'**
  String get projectSettingsTeardown;

  /// Heading of the agent list pane.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agentSettingsHeading;

  /// Placeholder shown before an agent is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select an agent.'**
  String get agentSettingsSelectAgent;

  /// Empty state shown when the current daemon has no agent definitions.
  ///
  /// In en, this message translates to:
  /// **'No agents are configured.'**
  String get agentSettingsEmpty;

  /// Subtitle counting agent definitions.
  ///
  /// In en, this message translates to:
  /// **'{count} definitions'**
  String agentSettingsCount(int count);

  /// Subtitle of an agent whose definition file no longer parses, so the last good version is shown.
  ///
  /// In en, this message translates to:
  /// **'{mode} · stale'**
  String agentSettingsModeStale(String mode);

  /// Tooltip that opens the agent creation dialog.
  ///
  /// In en, this message translates to:
  /// **'Add agent'**
  String get agentSettingsAdd;

  /// Title of the agent creation dialog.
  ///
  /// In en, this message translates to:
  /// **'Add agent'**
  String get agentSettingsAddTitle;

  /// Tooltip that returns to the agent list on narrow layouts.
  ///
  /// In en, this message translates to:
  /// **'Agent list'**
  String get agentSettingsList;

  /// Tooltip that copies the definition file path.
  ///
  /// In en, this message translates to:
  /// **'Copy file location'**
  String get agentSettingsCopyPath;

  /// Tooltip that restores a built-in agent definition.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get agentSettingsReset;

  /// Toggle that overrides the built-in system prompt.
  ///
  /// In en, this message translates to:
  /// **'Use a custom system prompt'**
  String get agentSettingsCustomPrompt;

  /// Toggle that gives an agent its own concrete model.
  ///
  /// In en, this message translates to:
  /// **'Set a model for this agent'**
  String get agentSettingsUseModel;

  /// Explains the disabled state of the agent model toggle.
  ///
  /// In en, this message translates to:
  /// **'When off, this agent uses the daemon default model.'**
  String get agentSettingsUseModelDescription;

  /// Section heading for an agent's identity fields.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get agentSettingsDefinitionHeading;

  /// Section heading for the custom prompt toggle.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get agentSettingsPromptHeading;

  /// Text field label for an agent's system prompt.
  ///
  /// In en, this message translates to:
  /// **'System prompt (Markdown)'**
  String get agentSettingsSystemPrompt;

  /// Section heading for an agent's model choice.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get agentSettingsModelHeading;

  /// Text field label for a pinned provider connection.
  ///
  /// In en, this message translates to:
  /// **'Provider connection ID'**
  String get agentSettingsProviderConnectionId;

  /// Text field label for a pinned model.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get agentSettingsModelId;

  /// Section heading for reasoning and permission.
  ///
  /// In en, this message translates to:
  /// **'Behaviour'**
  String get agentSettingsBehaviourHeading;

  /// Row label for the reasoning effort select.
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort'**
  String get agentSettingsReasoning;

  /// Row label for the permission mode select.
  ///
  /// In en, this message translates to:
  /// **'Permission mode'**
  String get agentSettingsPermission;

  /// Heading of the tool permission list.
  ///
  /// In en, this message translates to:
  /// **'Built-in tools'**
  String get agentSettingsBuiltinTools;

  /// Tool group covering workspace search and reading.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get agentSettingsToolGroupFilesystem;

  /// Tool group covering workspace file changes.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get agentSettingsToolGroupEditing;

  /// Tool group covering shell and process execution.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get agentSettingsToolGroupExecution;

  /// Tool group covering conversation attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get agentSettingsToolGroupAttachments;

  /// Tool group covering MCP servers and their resources.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get agentSettingsToolGroupMcp;

  /// Tool group covering collaborating subagents.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get agentSettingsToolGroupCollaboration;

  /// Tool group covering plans, questions, and time.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get agentSettingsToolGroupSession;

  /// Subtitle counting the enabled tools in one group.
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} on'**
  String agentSettingsToolGroupSummary(int enabled, int total);

  /// Subtitle of a group whose tools every agent gets.
  ///
  /// In en, this message translates to:
  /// **'Always available'**
  String get agentSettingsToolGroupAlwaysOn;

  /// Heading of the subagent list.
  ///
  /// In en, this message translates to:
  /// **'Callable subagents'**
  String get agentSettingsSubagents;

  /// Empty state of the subagent list.
  ///
  /// In en, this message translates to:
  /// **'No subagents are registered.'**
  String get agentSettingsNoSubagents;

  /// Asks whether to archive an agent definition.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String agentSettingsArchiveTitle(String name);

  /// Explains what archiving an agent definition does before it happens.
  ///
  /// In en, this message translates to:
  /// **'Sessions already using this agent keep running. It stops being offered for new ones.'**
  String get agentSettingsArchiveBody;

  /// Asks whether to restore a built-in agent definition.
  ///
  /// In en, this message translates to:
  /// **'Reset {name} to defaults?'**
  String agentSettingsResetTitle(String name);

  /// Explains that resetting a built-in agent discards local edits.
  ///
  /// In en, this message translates to:
  /// **'Every edit made to this built-in agent is discarded and cannot be recovered.'**
  String get agentSettingsResetBody;

  /// Reported when an agent definition could not be archived.
  ///
  /// In en, this message translates to:
  /// **'Could not archive the agent.'**
  String get agentSettingsArchiveFailed;

  /// Reported when the built-in agent definition could not be restored.
  ///
  /// In en, this message translates to:
  /// **'Could not restore the built-in agent.'**
  String get agentSettingsResetFailed;

  /// Reported after an agent definition is archived and the editor closes.
  ///
  /// In en, this message translates to:
  /// **'Archived.'**
  String get agentSettingsArchived;

  /// Reported after the built-in agent definition is restored. Distinct from agentSettingsReset, which labels the button.
  ///
  /// In en, this message translates to:
  /// **'Restored the built-in agent.'**
  String get agentSettingsResetDone;

  /// Title of the save conflict dialog.
  ///
  /// In en, this message translates to:
  /// **'Could not save the agent'**
  String get agentSettingsSaveFailedTitle;

  /// Discards local edits and reloads the definition.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get agentSettingsReload;

  /// Writes local edits over the newer definition.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get agentSettingsOverwrite;

  /// Validation error for an agent ID.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, digits, -, and _ are allowed.'**
  String get agentSettingsIdInvalid;

  /// Validation error for a duplicate agent ID.
  ///
  /// In en, this message translates to:
  /// **'That agent ID already exists.'**
  String get agentSettingsIdTaken;

  /// Text field label for the agent ID.
  ///
  /// In en, this message translates to:
  /// **'ID (file name)'**
  String get agentSettingsIdLabel;

  /// Validation error for an empty agent name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get agentSettingsNameRequired;

  /// Title of the standalone provider settings page.
  ///
  /// In en, this message translates to:
  /// **'Provider settings'**
  String get providerSettingsTitle;

  /// Shown when provider settings has no daemon state.
  ///
  /// In en, this message translates to:
  /// **'Connect a daemon first.'**
  String get providerSettingsRequiresDaemon;

  /// Tooltip that reloads the provider catalog.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalog'**
  String get providerSettingsRefreshCatalog;

  /// No description provided for @providerSettingsCatalogStatus.
  ///
  /// In en, this message translates to:
  /// **'Catalog metadata'**
  String get providerSettingsCatalogStatus;

  /// No description provided for @providerSettingsCatalogBundled.
  ///
  /// In en, this message translates to:
  /// **'Bundled snapshot'**
  String get providerSettingsCatalogBundled;

  /// No description provided for @providerSettingsCatalogCached.
  ///
  /// In en, this message translates to:
  /// **'Last-known-good cache'**
  String get providerSettingsCatalogCached;

  /// No description provided for @providerSettingsCatalogFresh.
  ///
  /// In en, this message translates to:
  /// **'Recently refreshed'**
  String get providerSettingsCatalogFresh;

  /// No description provided for @providerSettingsCatalogStale.
  ///
  /// In en, this message translates to:
  /// **'Refresh due; local metadata remains available'**
  String get providerSettingsCatalogStale;

  /// Section title of the daemon-wide concrete model.
  ///
  /// In en, this message translates to:
  /// **'Daemon default model'**
  String get modelSettingsSection;

  /// Explains the daemon model priority.
  ///
  /// In en, this message translates to:
  /// **'New chats use this model when neither the chat nor its agent specifies one.'**
  String get modelSettingsSectionDescription;

  /// Warning title for a concrete model that cannot currently run.
  ///
  /// In en, this message translates to:
  /// **'Saved model unavailable'**
  String get modelSettingsUnavailableTitle;

  /// Warning for an unavailable saved model.
  ///
  /// In en, this message translates to:
  /// **'{modelId} cannot run. Choose another model before starting a chat.'**
  String modelSettingsUnavailableDescription(String modelId);

  /// Reported when the daemon default model could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not update the daemon default model'**
  String get modelSettingsSaveFailed;

  /// Title of the sheet choosing how to connect one provider.
  ///
  /// In en, this message translates to:
  /// **'{name} connection'**
  String providerSettingsAuthTitle(String name);

  /// Subtitle marking an experimental auth method.
  ///
  /// In en, this message translates to:
  /// **'Experimental'**
  String get providerSettingsExperimental;

  /// Title of the disconnect confirmation.
  ///
  /// In en, this message translates to:
  /// **'Disconnect provider'**
  String get providerSettingsDisconnectTitle;

  /// Explains what disconnecting a provider keeps.
  ///
  /// In en, this message translates to:
  /// **'Disconnect {name}? Existing agent history is kept.'**
  String providerSettingsDisconnectBody(String name);

  /// Confirms disconnecting a provider.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get providerSettingsDisconnect;

  /// Title of the custom provider deletion confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete custom provider'**
  String get providerSettingsDeleteCustomTitle;

  /// Explains what deleting a custom provider removes and keeps.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and its stored credentials? Existing session history is kept.'**
  String providerSettingsDeleteCustomBody(String name);

  /// Heading of the connected provider list.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get providerSettingsConnected;

  /// Empty state of the connected provider list.
  ///
  /// In en, this message translates to:
  /// **'No providers are connected.'**
  String get providerSettingsNoConnections;

  /// Empty detail pane shown before a provider is selected.
  ///
  /// In en, this message translates to:
  /// **'Select a provider to manage.'**
  String get providerSettingsSelectConnection;

  /// No description provided for @providerSettingsRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Name and Base URL are required.'**
  String get providerSettingsRequiredFields;

  /// No description provided for @providerSettingsApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'API key is required.'**
  String get providerSettingsApiKeyRequired;

  /// Menu entry that opens the custom provider form.
  ///
  /// In en, this message translates to:
  /// **'Edit advanced settings'**
  String get providerSettingsEditAdvanced;

  /// No description provided for @providerSettingsActions.
  ///
  /// In en, this message translates to:
  /// **'Connection actions'**
  String get providerSettingsActions;

  /// Heading of the provider catalog.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get providerSettingsAdd;

  /// Empty state of the provider catalog.
  ///
  /// In en, this message translates to:
  /// **'No presets are left to add.'**
  String get providerSettingsNoPresets;

  /// Subtitle of the custom provider catalog entry.
  ///
  /// In en, this message translates to:
  /// **'Advanced: connect your own endpoint'**
  String get providerSettingsCustomSubtitle;

  /// Title of the custom provider catalog entry.
  ///
  /// In en, this message translates to:
  /// **'Custom Provider'**
  String get providerSettingsCustomName;

  /// Alert title shown when the provider catalog fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh the catalog'**
  String get providerSettingsRefreshFailed;

  /// Title of the pending OAuth attempt bar.
  ///
  /// In en, this message translates to:
  /// **'Waiting for sign-in'**
  String get providerSettingsOAuthPending;

  /// Action that reopens a provider OAuth URL in the system browser.
  ///
  /// In en, this message translates to:
  /// **'Open browser'**
  String get providerSettingsOpenBrowser;

  /// Action that replaces credentials for an existing provider connection.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get providerSettingsReconnect;

  /// Label for the globally unique provider model prefix.
  ///
  /// In en, this message translates to:
  /// **'Model prefix'**
  String get providerSettingsModelPrefix;

  /// Help text explaining qualified model identifiers.
  ///
  /// In en, this message translates to:
  /// **'Used in model IDs such as openai/gpt-5.6-col.'**
  String get providerSettingsModelPrefixHelp;

  /// Validation message for an invalid model prefix.
  ///
  /// In en, this message translates to:
  /// **'Use 1–64 lowercase letters, numbers, hyphens, or underscores.'**
  String get providerSettingsModelPrefixInvalid;

  /// Inline error shown when the daemon rejects a duplicate model prefix.
  ///
  /// In en, this message translates to:
  /// **'That model prefix is already in use. Try the updated suggestion.'**
  String get providerSettingsModelPrefixConflict;

  /// Title of the API key dialog.
  ///
  /// In en, this message translates to:
  /// **'Connect {name}'**
  String providerSettingsConnectTitle(String name);

  /// Confirms the API key dialog.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get providerSettingsConnect;

  /// Text field label for a provider API key.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get providerSettingsApiKey;

  /// Text field label for a custom provider endpoint.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get providerSettingsBaseUrl;

  /// Fallback shown when a provider connection fails without naming a reason.
  ///
  /// In en, this message translates to:
  /// **'Provider connection failed.'**
  String get providerSettingsConnectionFailed;

  /// Reported when no browser could be launched for an OAuth sign-in.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the authorization page.'**
  String get providerSettingsAuthUrlFailed;

  /// Title of the custom provider dialog.
  ///
  /// In en, this message translates to:
  /// **'Custom provider advanced settings'**
  String get providerSettingsCustomTitle;

  /// Dropdown label for the provider wire format.
  ///
  /// In en, this message translates to:
  /// **'API format'**
  String get providerSettingsApiFormat;

  /// Toggle marking a custom provider as authenticated.
  ///
  /// In en, this message translates to:
  /// **'Requires an API key'**
  String get providerSettingsRequiresApiKey;

  /// Text field label for hand-entered model IDs.
  ///
  /// In en, this message translates to:
  /// **'Manual model IDs'**
  String get providerSettingsManualModels;

  /// Title of the manual model dialog.
  ///
  /// In en, this message translates to:
  /// **'Could not list models'**
  String get providerSettingsModelLookupFailedTitle;

  /// Explains why manual model IDs are needed.
  ///
  /// In en, this message translates to:
  /// **'The provider did not return a model list. Enter the model IDs to use.'**
  String get providerSettingsModelLookupFailedBody;

  /// Dismisses the manual model dialog without saving.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get providerSettingsLater;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get providerStatusConnecting;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get providerStatusConnected;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Limited connection'**
  String get providerStatusDegraded;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get providerStatusError;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get providerStatusReauthRequired;

  /// Provider connection status.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get providerStatusDisconnected;

  /// Origin of a provider credential.
  ///
  /// In en, this message translates to:
  /// **'Stored credential'**
  String get providerAuthStored;

  /// Credential label for a connection authorized over OAuth.
  ///
  /// In en, this message translates to:
  /// **'OAuth'**
  String get providerAuthOAuth;

  /// Origin of a provider credential.
  ///
  /// In en, this message translates to:
  /// **'No credential'**
  String get providerAuthNone;

  /// Title of the model picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Select a model'**
  String get modelPickerTitle;

  /// Search field label of the model picker.
  ///
  /// In en, this message translates to:
  /// **'Search models'**
  String get modelPickerSearch;

  /// Empty state of the model picker search.
  ///
  /// In en, this message translates to:
  /// **'No results.'**
  String get modelPickerNoResults;

  /// Composer mode that only drafts a plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get composerPlan;

  /// Composer mode that carries the request out.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get composerRun;

  /// Label of the composer collaboration mode setting.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get composerMode;

  /// Tooltip of the plan composer mode.
  ///
  /// In en, this message translates to:
  /// **'Only drafts a plan. Shift+Tab to switch'**
  String get composerPlanTooltip;

  /// Tooltip of the run composer mode.
  ///
  /// In en, this message translates to:
  /// **'Carries the request out directly. Shift+Tab to switch'**
  String get composerRunTooltip;

  /// Tooltip of the agent selector.
  ///
  /// In en, this message translates to:
  /// **'Select an agent'**
  String get composerSelectAgent;

  /// Label of the composer agent setting.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get composerAgent;

  /// Tooltip explaining why the agent selector is disabled.
  ///
  /// In en, this message translates to:
  /// **'The agent cannot be changed after the session starts.'**
  String get composerAgentLocked;

  /// Fallback label of the model selector.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get composerModel;

  /// Tooltip and title of the model selector.
  ///
  /// In en, this message translates to:
  /// **'Select a model'**
  String get composerSelectModel;

  /// Placeholder shown before the first session exists.
  ///
  /// In en, this message translates to:
  /// **'Start a new session with a coding request.'**
  String get composerStartHint;

  /// Explains why the composer is disabled.
  ///
  /// In en, this message translates to:
  /// **'No primary agent is available.'**
  String get composerNoPrimaryAgent;

  /// Explains why the composer is disabled.
  ///
  /// In en, this message translates to:
  /// **'Connect a provider first.'**
  String get composerConnectProviderFirst;

  /// Hint of the composer text field.
  ///
  /// In en, this message translates to:
  /// **'Type a coding request…'**
  String get composerInputHint;

  /// Label of the composer reasoning effort chip when inheriting.
  ///
  /// In en, this message translates to:
  /// **'Effort'**
  String get composerReasoningEffort;

  /// Tooltip of the composer reasoning effort chip.
  ///
  /// In en, this message translates to:
  /// **'Select reasoning effort'**
  String get composerSelectReasoningEffort;

  /// Menu entry restoring the agent definition reasoning effort.
  ///
  /// In en, this message translates to:
  /// **'Agent default'**
  String get composerInheritReasoningEffort;

  /// Label of the composer permission mode chip when inheriting.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get composerPermissionMode;

  /// Tooltip of the composer permission mode chip.
  ///
  /// In en, this message translates to:
  /// **'Select permissions'**
  String get composerSelectPermissionMode;

  /// Menu entry restoring the agent definition permission mode.
  ///
  /// In en, this message translates to:
  /// **'Agent default'**
  String get composerInheritPermissionMode;

  /// Permission mode allowing read-only tools.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get composerPermissionReadOnly;

  /// Permission mode asking before every mutation.
  ///
  /// In en, this message translates to:
  /// **'Ask before changes'**
  String get composerPermissionAsk;

  /// Permission mode allowing workspace writes without asking.
  ///
  /// In en, this message translates to:
  /// **'Workspace access'**
  String get composerPermissionWorkspaceWrite;

  /// No description provided for @composerPermissionFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full access'**
  String get composerPermissionFullAccess;

  /// No description provided for @permissionPickerDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose what the agent may do without asking.'**
  String get permissionPickerDescription;

  /// No description provided for @permissionDescriptionReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Can read files. File changes, commands, and write-capable external tools are blocked.'**
  String get permissionDescriptionReadOnly;

  /// No description provided for @permissionDescriptionAsk.
  ///
  /// In en, this message translates to:
  /// **'Reads without asking. Asks before file changes, commands, and write-capable external tools.'**
  String get permissionDescriptionAsk;

  /// No description provided for @permissionDescriptionWorkspaceWrite.
  ///
  /// In en, this message translates to:
  /// **'Can read and edit workspace files. Asks before commands and write-capable external tools.'**
  String get permissionDescriptionWorkspaceWrite;

  /// No description provided for @permissionDescriptionFullAccess.
  ///
  /// In en, this message translates to:
  /// **'Runs file changes, commands, and external tools without asking. Use only for trusted work.'**
  String get permissionDescriptionFullAccess;

  /// No description provided for @permissionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionSettingsTitle;

  /// No description provided for @permissionSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Default permissions'**
  String get permissionSettingsSection;

  /// No description provided for @permissionSettingsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Agents that do not choose their own permissions inherit this daemon default.'**
  String get permissionSettingsSectionDescription;

  /// No description provided for @permissionSettingsChange.
  ///
  /// In en, this message translates to:
  /// **'Change default permissions'**
  String get permissionSettingsChange;

  /// No description provided for @permissionSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update default permissions'**
  String get permissionSettingsSaveFailed;

  /// No description provided for @permissionChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change permissions'**
  String get permissionChangeFailed;

  /// No description provided for @permissionSettingsDaemonDefault.
  ///
  /// In en, this message translates to:
  /// **'Daemon default'**
  String get permissionSettingsDaemonDefault;

  /// Label of the composer fast mode toggle.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get composerFastMode;

  /// Tooltip of the composer fast mode toggle when it is off.
  ///
  /// In en, this message translates to:
  /// **'Faster responses at a higher credit rate'**
  String get composerFastModeTooltip;

  /// Tooltip of the composer fast mode toggle when it is on.
  ///
  /// In en, this message translates to:
  /// **'Fast mode is on; tap to use the standard tier'**
  String get composerFastModeOnTooltip;

  /// Tooltip shown when a composer setting cannot change mid-turn.
  ///
  /// In en, this message translates to:
  /// **'Settings change between turns'**
  String get composerSettingLocked;

  /// Accessible label for the composer send button.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get composerSendLabel;

  /// Accessible label for the send button while a turn runs.
  ///
  /// In en, this message translates to:
  /// **'Queue message'**
  String get composerQueueLabel;

  /// Tooltip of the send button while a turn runs.
  ///
  /// In en, this message translates to:
  /// **'Sends when the current turn finishes'**
  String get composerQueueTooltip;

  /// Action returning a queued message to the input.
  ///
  /// In en, this message translates to:
  /// **'Edit queued message'**
  String get composerQueuedEdit;

  /// Action stopping the current turn to send a queued message.
  ///
  /// In en, this message translates to:
  /// **'Send queued message now'**
  String get composerQueuedSendNow;

  /// Summary of the files attached to a queued message.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String composerQueuedAttachments(num count);

  /// Why a queued message stopped trying to send.
  ///
  /// In en, this message translates to:
  /// **'Not sent · {reason}'**
  String composerQueuedFailed(String reason);

  /// Accessible label for the composer attachment button.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get composerAttachLabel;

  /// Accessible label of the button removing one pending attachment.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String composerRemoveAttachment(String name);

  /// Reported when one chosen file is over the per-attachment size limit.
  ///
  /// In en, this message translates to:
  /// **'Each attachment must be under {limit} MB.'**
  String composerAttachmentTooLarge(int limit);

  /// Reported when a submission would hold more files than one turn accepts.
  ///
  /// In en, this message translates to:
  /// **'A turn accepts at most {limit} files.'**
  String composerAttachmentTooMany(int limit);

  /// Label and title of the compact composer settings sheet.
  ///
  /// In en, this message translates to:
  /// **'More settings'**
  String get composerMoreSettings;

  /// Choice that removes an explicit model-control override.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get composerUseDefault;

  /// Choice that enables a toggle model control.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get composerEnabled;

  /// Empty state of the chat timeline.
  ///
  /// In en, this message translates to:
  /// **'Type a coding request.'**
  String get chatEmptyTitle;

  /// Example request shown in the empty chat timeline.
  ///
  /// In en, this message translates to:
  /// **'e.g. Run the tests and fix what fails'**
  String get chatEmptyExample;

  /// Timeline notice for a cancelled turn.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get chatNoticeCancelled;

  /// Timeline notice for a failed turn.
  ///
  /// In en, this message translates to:
  /// **'Failed · {message}'**
  String chatNoticeFailed(String message);

  /// Copies an assistant response to the clipboard as Markdown.
  ///
  /// In en, this message translates to:
  /// **'Copy response'**
  String get chatCopyResponse;

  /// Marks the lines hidden by a collapsed code or diff block.
  ///
  /// In en, this message translates to:
  /// **'… {count} more lines'**
  String chatMoreLines(int count);

  /// Title of the tool approval card.
  ///
  /// In en, this message translates to:
  /// **'Approval required · {tool}'**
  String chatApprovalRequired(String tool);

  /// Rejects a tool call.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get chatApprovalDeny;

  /// Approves a tool call.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get chatApprovalAllow;

  /// Title of the plan card.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get chatPlanTitle;

  /// Prompt token count in the usage summary line.
  ///
  /// In en, this message translates to:
  /// **'in {tokens}'**
  String usageInput(int tokens);

  /// Prompt tokens with the cached portion called out.
  ///
  /// In en, this message translates to:
  /// **'in {tokens} ({cached} cached)'**
  String usageInputCached(int tokens, int cached);

  /// Completion token count in the usage summary line.
  ///
  /// In en, this message translates to:
  /// **'out {tokens}'**
  String usageOutput(int tokens);

  /// Completion tokens with the hidden reasoning portion called out.
  ///
  /// In en, this message translates to:
  /// **'out {tokens} ({reasoning} reasoning)'**
  String usageOutputReasoning(int tokens, int reasoning);

  /// Total token count in the usage summary line.
  ///
  /// In en, this message translates to:
  /// **'total {tokens}'**
  String usageTotal(int tokens);

  /// Output tokens per second, measured over the time the response streamed and excluding tool execution. The caller rounds the rate; decimalPattern only localizes the separators.
  ///
  /// In en, this message translates to:
  /// **'{rate} tok/s'**
  String usageThroughput(double rate);

  /// Result line while a pseudo-terminal session is still running.
  ///
  /// In en, this message translates to:
  /// **'running · {lines} lines'**
  String toolExecRunning(int lines);

  /// A free-form answer the user typed instead of choosing.
  ///
  /// In en, this message translates to:
  /// **'{answer} (typed)'**
  String chatAnswerTyped(String answer);

  /// Label of the sleep countdown card.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get chatSleepWaiting;

  /// Remaining time on the sleep countdown.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s left'**
  String chatSleepRemaining(int seconds);

  /// Shown once a sleep has finished.
  ///
  /// In en, this message translates to:
  /// **'Waited {seconds}s'**
  String chatSleepDone(int seconds);

  /// Result line of a tool_search call.
  ///
  /// In en, this message translates to:
  /// **'{found} loaded · {remaining} still hidden'**
  String toolSearchFound(int found, int remaining);

  /// Header of the collapsible subagent track.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subagent} other{{count} subagents}}'**
  String subagentTrackHeader(int count);

  /// Running-count badge on the subagent track header.
  ///
  /// In en, this message translates to:
  /// **'{count} running'**
  String subagentTrackRunning(int count);

  /// Semantics label of a running subagent.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get subagentStatusRunning;

  /// Semantics label of a completed subagent.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get subagentStatusCompleted;

  /// Semantics label of an interrupted subagent.
  ///
  /// In en, this message translates to:
  /// **'Interrupted'**
  String get subagentStatusInterrupted;

  /// Semantics label of a failed subagent.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get subagentStatusErrored;

  /// Semantics label of a subagent blocked on an approval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get subagentStatusWaitingForApproval;

  /// Subtitle notice on the read-only subagent pane.
  ///
  /// In en, this message translates to:
  /// **'Subagent conversation · read-only'**
  String get subagentReadOnlyNotice;

  /// Result line of a queued inter-agent message.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get chatToolSubagentQueued;

  /// Result line of the collaboration agent list.
  ///
  /// In en, this message translates to:
  /// **'{count} agents'**
  String chatToolSubagentCount(int count);

  /// Notice that some tools were not advertised up front.
  ///
  /// In en, this message translates to:
  /// **'{count} tools are available through search'**
  String chatDeferredTools(int count);

  /// Result line of a list_mcp_resources tool call.
  ///
  /// In en, this message translates to:
  /// **'{count} resources'**
  String toolMcpResources(int count);

  /// Result line of a list_mcp_resource_templates tool call.
  ///
  /// In en, this message translates to:
  /// **'{count} templates'**
  String toolMcpResourceTemplates(int count);

  /// Result line of a read_mcp_resource tool call.
  ///
  /// In en, this message translates to:
  /// **'{count} blocks'**
  String toolMcpResourceRead(int count);

  /// Result line of a view_image tool call.
  ///
  /// In en, this message translates to:
  /// **'{bytes} bytes viewed'**
  String toolImageLoaded(int bytes);

  /// Button that submits answers to the agent's questions.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get chatQuestionSubmit;

  /// Button that advances to the next agent question.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get chatQuestionNext;

  /// Screen-reader name of the agent question tab strip.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get chatQuestionNavigation;

  /// Screen-reader status while agent question answers are submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitting answers'**
  String get chatQuestionSubmitting;

  /// Choice that lets the user type a free-form answer.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatQuestionOther;

  /// Placeholder of the free-form answer field.
  ///
  /// In en, this message translates to:
  /// **'Type your answer'**
  String get chatQuestionOtherPlaceholder;

  /// Screen-reader status of a plan step that has not started.
  ///
  /// In en, this message translates to:
  /// **'not started'**
  String get chatPlanStepPending;

  /// Screen-reader status of the plan step being worked on.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get chatPlanStepInProgress;

  /// Screen-reader status of a finished plan step.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get chatPlanStepCompleted;

  /// Asks how to act on a proposed plan.
  ///
  /// In en, this message translates to:
  /// **'Proceed with this plan?'**
  String get chatPlanPrompt;

  /// Stays in plan mode.
  ///
  /// In en, this message translates to:
  /// **'Keep planning'**
  String get chatPlanKeepPlanning;

  /// Implements the plan in a fresh session.
  ///
  /// In en, this message translates to:
  /// **'Run in a new session'**
  String get chatPlanRunInNewSession;

  /// Implements the plan in the current session.
  ///
  /// In en, this message translates to:
  /// **'Run the plan'**
  String get chatPlanRun;

  /// Prompt sent to the agent when the user accepts a plan in place. Reaches the model rather than the screen, but is localized so the agent answers in the reader's language.
  ///
  /// In en, this message translates to:
  /// **'Carry out this plan.'**
  String get planImplementPrompt;

  /// Preamble prepended to a plan handed to a brand-new session. Reaches the model rather than the screen, but is localized so the agent answers in the reader's language.
  ///
  /// In en, this message translates to:
  /// **'A previous agent drafted the plan below for the user. Implement it in this fresh context. Treat the plan as the record of what the user wants, but read the files you need again, and carry the work through to implementation and verification.'**
  String get planFreshSessionPreamble;

  /// Result line of a denied tool call.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get toolRejected;

  /// Result line of a tool call with no error text.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get toolFailed;

  /// Read result for a file with no content.
  ///
  /// In en, this message translates to:
  /// **'Empty file'**
  String get toolEmptyFile;

  /// Read result summary.
  ///
  /// In en, this message translates to:
  /// **'Read {count} lines'**
  String toolReadLines(int count);

  /// Generic list result summary.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String toolListItems(int count);

  /// Directory listing result summary.
  ///
  /// In en, this message translates to:
  /// **'{directories} directories · {files} files'**
  String toolListEntries(int directories, int files);

  /// Search result with nothing found.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get toolNoMatches;

  /// Search result summary.
  ///
  /// In en, this message translates to:
  /// **'{matches} matches in {files} files'**
  String toolMatches(int matches, int files);

  /// Search result summary when the result cap was reached.
  ///
  /// In en, this message translates to:
  /// **'{matches}+ matches in {files} files'**
  String toolMatchesTruncated(int matches, int files);

  /// File-name search result with nothing found.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get toolNoPaths;

  /// File-name search result summary.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String toolPaths(int count);

  /// File-name search summary when the result cap was reached.
  ///
  /// In en, this message translates to:
  /// **'{count}+ files'**
  String toolPathsTruncated(int count);

  /// Result line after a workspace file is attached.
  ///
  /// In en, this message translates to:
  /// **'Attached {name}'**
  String toolAttached(String name);

  /// Result line after a skill's instructions are loaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded {name}'**
  String toolSkillLoaded(String name);

  /// Skill listing result summary.
  ///
  /// In en, this message translates to:
  /// **'{count} skills'**
  String toolSkills(int count);

  /// Skill listing summary when a page boundary was reached.
  ///
  /// In en, this message translates to:
  /// **'{count}+ skills'**
  String toolSkillsTruncated(int count);

  /// Edit call summary across several files.
  ///
  /// In en, this message translates to:
  /// **'Edit({count} files)'**
  String toolEditFiles(int count);

  /// Patch result summary.
  ///
  /// In en, this message translates to:
  /// **'+{added} -{removed} · {files} files'**
  String toolPatchSummary(int added, int removed, int files);

  /// Shell command result summary.
  ///
  /// In en, this message translates to:
  /// **'exit {exitCode} · {lines} lines'**
  String toolCommandResult(int exitCode, int lines);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get toolTitleEdit;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Edit({path})'**
  String toolTitleEditPath(String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Attach({path})'**
  String toolTitleAttach(String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Attachment({id})'**
  String toolTitleAttachment(String id);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Now()'**
  String get toolTitleNow;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Sleep({milliseconds}ms)'**
  String toolTitleSleep(int milliseconds);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Sleep()'**
  String get toolTitleSleepUnknown;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Spawn({task})'**
  String toolTitleSpawn(String task);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Send({target})'**
  String toolTitleSend(String target);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Followup({target})'**
  String toolTitleFollowup(String target);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Wait()'**
  String get toolTitleWait;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Interrupt({target})'**
  String toolTitleInterrupt(String target);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Agents()'**
  String get toolTitleAgents;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Context()'**
  String get toolTitleContext;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'NewContext()'**
  String get toolTitleNewContext;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Bash({command})'**
  String toolTitleBash(String command);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Stdin({session})'**
  String toolTitleStdin(String session);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Stdin({session} ← {chars})'**
  String toolTitleStdinChars(String session, String chars);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Glob({pattern})'**
  String toolTitleGlob(String pattern);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Glob({pattern} in {path})'**
  String toolTitleGlobIn(String pattern, String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'List({path})'**
  String toolTitleList(String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Resources({server})'**
  String toolTitleMcpResources(String server);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'ResourceTemplates({server})'**
  String toolTitleMcpResourceTemplates(String server);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Resource({server}: {uri})'**
  String toolTitleMcpResource(String server, String uri);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Read({path})'**
  String toolTitleRead(String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Read({path} @{offset}+{limit})'**
  String toolTitleReadRange(String path, String offset, String limit);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Ask({headers})'**
  String toolTitleAsk(String headers);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Search({query})'**
  String toolTitleSearch(String query);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Search({query} in {path})'**
  String toolTitleSearchIn(String query, String path);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Skills()'**
  String get toolTitleSkills;

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Skill({name})'**
  String toolTitleSkill(String name);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Skill({name}:{resource})'**
  String toolTitleSkillResource(String name, String resource);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Tools({query})'**
  String toolTitleToolSearch(String query);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'Plan({count})'**
  String toolTitlePlan(int count);

  /// Chat timeline title of a tool call. The verb is translated; the argument is the model's own text and stays verbatim.
  ///
  /// In en, this message translates to:
  /// **'View({path})'**
  String toolTitleView(String path);

  /// Stands in for the server argument of an MCP call that lists every server at once.
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get toolArgumentAllServers;

  /// Title of the remote directory browser.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder on the daemon'**
  String get directoryBrowserTitle;

  /// Text field label for the browsed path.
  ///
  /// In en, this message translates to:
  /// **'Daemon path'**
  String get directoryBrowserPath;

  /// Empty state of the directory listing.
  ///
  /// In en, this message translates to:
  /// **'No subfolders.'**
  String get directoryBrowserEmpty;

  /// Confirms the browsed folder.
  ///
  /// In en, this message translates to:
  /// **'Choose this folder'**
  String get directoryBrowserSelect;

  /// Title of the daemon picker shown before browsing.
  ///
  /// In en, this message translates to:
  /// **'Daemon to add the folder to'**
  String get directoryBrowserHostTitle;

  /// Line naming a worktree hook that failed, listed in the dialog that reports the failure.
  ///
  /// In en, this message translates to:
  /// **'{phase} failed (exit {exitCode}): {command}'**
  String hookFailureMessage(String phase, int exitCode, String command);

  /// Title of the hook failure detail dialog.
  ///
  /// In en, this message translates to:
  /// **'{phase} hook failed'**
  String hookFailureTitle(String phase);

  /// Stands in for a hook that produced no output.
  ///
  /// In en, this message translates to:
  /// **'(no output)'**
  String get hookFailureNoOutput;

  /// Sidebar label for the skill settings category.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get settingsCategorySkill;

  /// Heading above the skill list.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skillSettingsHeading;

  /// Number of skills visible in the current scope.
  ///
  /// In en, this message translates to:
  /// **'{count} skills'**
  String skillSettingsCount(int count);

  /// Placeholder shown before a skill is selected.
  ///
  /// In en, this message translates to:
  /// **'Select a skill.'**
  String get skillSettingsSelectSkill;

  /// Empty state shown when the current scope has no skills.
  ///
  /// In en, this message translates to:
  /// **'No skills are configured.'**
  String get skillSettingsEmpty;

  /// Tooltip for returning to the skill list on narrow layouts.
  ///
  /// In en, this message translates to:
  /// **'Skill list'**
  String get skillSettingsList;

  /// Tooltip for the add-skill button.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get skillSettingsAdd;

  /// Title of the add-skill dialog.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get skillSettingsAddTitle;

  /// Label for the skill ID field, which names the directory.
  ///
  /// In en, this message translates to:
  /// **'ID (directory name)'**
  String get skillSettingsIdLabel;

  /// Validation error for a malformed skill ID.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, digits, -, and _ are allowed.'**
  String get skillSettingsIdInvalid;

  /// Validation error for a skill ID already in use.
  ///
  /// In en, this message translates to:
  /// **'That skill ID already exists.'**
  String get skillSettingsIdTaken;

  /// Validation error for an empty skill name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get skillSettingsNameRequired;

  /// Tooltip for copying the skill file path.
  ///
  /// In en, this message translates to:
  /// **'Copy file location'**
  String get skillSettingsCopyPath;

  /// Tooltip for deleting a skill.
  ///
  /// In en, this message translates to:
  /// **'Delete skill'**
  String get skillSettingsDelete;

  /// Reported when a skill could not be removed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the skill.'**
  String get skillSettingsDeleteFailed;

  /// Reported when a skill's enabled state could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not change whether the skill is enabled.'**
  String get skillSettingsToggleFailed;

  /// Title of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String skillSettingsDeleteTitle(String name);

  /// Explains that deleting archives the directory.
  ///
  /// In en, this message translates to:
  /// **'The skill directory moves to .archive next to it.'**
  String get skillSettingsDeleteMessage;

  /// Label for the per-skill enable switch.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get skillSettingsEnabled;

  /// Tooltip explaining why a built-in skill cannot be turned off.
  ///
  /// In en, this message translates to:
  /// **'This built-in skill is always enabled.'**
  String get skillSettingsMandatory;

  /// Explains that built-in skills are read-only.
  ///
  /// In en, this message translates to:
  /// **'Built-in skills ship with the app and cannot be edited.'**
  String get skillSettingsReadOnly;

  /// Label for the skill body editor.
  ///
  /// In en, this message translates to:
  /// **'Instructions (Markdown)'**
  String get skillSettingsInstructions;

  /// Section heading for whether a skill is enabled.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get skillSettingsStateHeading;

  /// Section heading for a skill's editable fields.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get skillSettingsDefinitionHeading;

  /// Heading above the bundled file list.
  ///
  /// In en, this message translates to:
  /// **'Bundled files'**
  String get skillSettingsResources;

  /// Shown when a skill bundles no extra files.
  ///
  /// In en, this message translates to:
  /// **'No files are bundled with this skill.'**
  String get skillSettingsNoResources;

  /// Title of the save-conflict dialog.
  ///
  /// In en, this message translates to:
  /// **'Could not save the skill'**
  String get skillSettingsSaveFailedTitle;

  /// Discards the edit and reloads the file.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get skillSettingsReload;

  /// Saves over the external change.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get skillSettingsOverwrite;

  /// Explains that a higher-precedence source wins.
  ///
  /// In en, this message translates to:
  /// **'Another source overrides this skill.'**
  String get skillSettingsShadowed;

  /// Explains that the file failed to parse.
  ///
  /// In en, this message translates to:
  /// **'This file no longer parses; the last good version is shown.'**
  String get skillSettingsStale;

  /// Label for the source a skill was loaded from.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get skillSettingsSource;

  /// Source badge for skills shipped with the app.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get skillSettingsSourceBuiltIn;

  /// Source badge for skills in the shared user home tree.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get skillSettingsSourceUserHome;

  /// Source badge for skills in the daemon configuration directory.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get skillSettingsSourceConfig;

  /// Source badge for skills committed to a project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get skillSettingsSourceProject;

  /// Label for the project selector on the skill page.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get skillSettingsProject;

  /// Project selector entry that shows only global skills.
  ///
  /// In en, this message translates to:
  /// **'Global skills only'**
  String get skillSettingsProjectNone;

  /// Explains what picking a project adds to the list.
  ///
  /// In en, this message translates to:
  /// **'Pick a project to see and edit the skills committed to it.'**
  String get skillSettingsProjectHint;

  /// Placeholder for the filter field in the project selector.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get skillSettingsProjectSearch;

  /// Shown when the project filter matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching project'**
  String get skillSettingsProjectNoMatch;

  /// Sidebar label for the MCP server settings category.
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get settingsCategoryMcp;

  /// Heading of the MCP server list.
  ///
  /// In en, this message translates to:
  /// **'MCP servers'**
  String get mcpSettingsHeading;

  /// Tooltip of the add-server button.
  ///
  /// In en, this message translates to:
  /// **'Add MCP server'**
  String get mcpSettingsAdd;

  /// Shown when no server exists.
  ///
  /// In en, this message translates to:
  /// **'No MCP servers are configured.'**
  String get mcpSettingsEmpty;

  /// Placeholder in the detail pane.
  ///
  /// In en, this message translates to:
  /// **'Select a server to edit it.'**
  String get mcpSettingsSelectServer;

  /// Heading above servers the user configured.
  ///
  /// In en, this message translates to:
  /// **'Yours'**
  String get mcpSettingsScopeUser;

  /// Heading above servers the repository declares.
  ///
  /// In en, this message translates to:
  /// **'This project'**
  String get mcpSettingsScopeProject;

  /// Explains why a project server is read-only.
  ///
  /// In en, this message translates to:
  /// **'Defined by this repository, so {appName} does not edit it.'**
  String mcpSettingsProjectReadOnly(String appName);

  /// Badge on a project server a user server overrides.
  ///
  /// In en, this message translates to:
  /// **'Hidden by your server of the same name'**
  String get mcpSettingsShadowed;

  /// Shows which file declares a server.
  ///
  /// In en, this message translates to:
  /// **'Defined in {path}'**
  String mcpSettingsSource(String path);

  /// Label of the server id field.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get mcpSettingsServerId;

  /// Rejects an unusable server id.
  ///
  /// In en, this message translates to:
  /// **'Use lower-case letters, digits, - and _.'**
  String get mcpSettingsServerIdInvalid;

  /// Label of the transport selector.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get mcpSettingsTransport;

  /// Label of the stdio transport.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get mcpSettingsTransportStdio;

  /// Label of the Streamable HTTP transport.
  ///
  /// In en, this message translates to:
  /// **'HTTP'**
  String get mcpSettingsTransportHttp;

  /// Label of the executable field.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get mcpSettingsCommand;

  /// Label of the arguments field.
  ///
  /// In en, this message translates to:
  /// **'Arguments (one per line)'**
  String get mcpSettingsArgs;

  /// Label of the cwd field.
  ///
  /// In en, this message translates to:
  /// **'Working directory (optional)'**
  String get mcpSettingsWorkingDirectory;

  /// Label of the endpoint field.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get mcpSettingsUrl;

  /// Label of the env field.
  ///
  /// In en, this message translates to:
  /// **'Environment (KEY=value, one per line)'**
  String get mcpSettingsEnvironment;

  /// Label of the headers field.
  ///
  /// In en, this message translates to:
  /// **'Headers (Name: value, one per line)'**
  String get mcpSettingsHeaders;

  /// Section heading for an MCP server's transport fields.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get mcpSettingsConnectionHeading;

  /// Section heading for whether an MCP server is enabled.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get mcpSettingsStateHeading;

  /// Label of the enable switch.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get mcpSettingsEnabled;

  /// Explains the secret reference syntax.
  ///
  /// In en, this message translates to:
  /// **'Never paste a secret here. Reference a stored secret or an environment variable instead:'**
  String get mcpSettingsSecretHint;

  /// Label of the test button.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get mcpSettingsTest;

  /// Reports a successful test.
  ///
  /// In en, this message translates to:
  /// **'Connected and found {count} tools.'**
  String mcpSettingsTestSucceeded(int count);

  /// Reports a failed test.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {error}'**
  String mcpSettingsTestFailed(String error);

  /// Reported when a running terminal could not be terminated, so its tab stays open.
  ///
  /// In en, this message translates to:
  /// **'Could not stop the terminal.'**
  String get terminalTerminateFailed;

  /// Reported when a paired relay device could not be revoked.
  ///
  /// In en, this message translates to:
  /// **'Could not revoke the device.'**
  String get relayRevokeFailed;

  /// Reported when a daemon preference could not be stored or applied.
  ///
  /// In en, this message translates to:
  /// **'Could not change the daemon setting.'**
  String get appSettingsDaemonChangeFailed;

  /// Reported when a remote daemon profile could not be deleted.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the daemon.'**
  String get appSettingsDeleteFailed;

  /// Reported when a remote daemon could not be reconnected.
  ///
  /// In en, this message translates to:
  /// **'Could not reconnect.'**
  String get appSettingsReconnectFailed;

  /// Reported when a provider connection could not be removed.
  ///
  /// In en, this message translates to:
  /// **'Could not disconnect the provider.'**
  String get providerSettingsDisconnectFailed;

  /// Reported when a custom provider could not be deleted.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the provider.'**
  String get providerSettingsDeleteFailed;

  /// Reported after a provider connection is removed.
  ///
  /// In en, this message translates to:
  /// **'Disconnected.'**
  String get providerSettingsDisconnected;

  /// Reported when a worktree could not be archived.
  ///
  /// In en, this message translates to:
  /// **'Could not archive the worktree.'**
  String get workspaceArchiveFailed;

  /// Reported when a project could not be unregistered.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the project.'**
  String get workspaceUnregisterFailed;

  /// Reported when a project's hooks or shell could not be written.
  ///
  /// In en, this message translates to:
  /// **'Could not save the project settings.'**
  String get projectSettingsSaveFailed;

  /// Reported when an MCP server could not be added or updated.
  ///
  /// In en, this message translates to:
  /// **'Could not save the server.'**
  String get mcpSettingsSaveFailed;

  /// Reported when an MCP server could not be removed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the server.'**
  String get mcpSettingsDeleteFailed;

  /// Reported when an MCP secret could not be written.
  ///
  /// In en, this message translates to:
  /// **'Could not store the secret.'**
  String get mcpSettingsSecretFailed;

  /// Label of the delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete server'**
  String get mcpSettingsDelete;

  /// Confirms deleting a server.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? Agents using its tools will lose them.'**
  String mcpSettingsDeleteConfirm(String name);

  /// Server status label.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get mcpSettingsStatusDisabled;

  /// Server status label.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get mcpSettingsStatusConnecting;

  /// Accessible label of the spinner shown while an MCP server connects.
  ///
  /// In en, this message translates to:
  /// **'Connecting MCP server'**
  String get mcpSettingsConnecting;

  /// Server status label.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get mcpSettingsStatusReady;

  /// Server status label.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get mcpSettingsStatusFailed;

  /// Label for the resource count in the MCP server list row.
  ///
  /// In en, this message translates to:
  /// **'resources'**
  String get mcpSettingsDiscoveredResources;

  /// Heading of the collapsible MCP resource list.
  ///
  /// In en, this message translates to:
  /// **'Published resources'**
  String get mcpSettingsResources;

  /// Empty state of the MCP resource list.
  ///
  /// In en, this message translates to:
  /// **'This server publishes no resources.'**
  String get mcpSettingsNoResources;

  /// Heading of the collapsible MCP resource template list.
  ///
  /// In en, this message translates to:
  /// **'Resource templates'**
  String get mcpSettingsResourceTemplates;

  /// Empty state of the MCP resource template list.
  ///
  /// In en, this message translates to:
  /// **'This server publishes no resource templates.'**
  String get mcpSettingsNoResourceTemplates;

  /// Heading of the discovered tool list.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get mcpSettingsDiscoveredTools;

  /// Shown when a ready server has no tools.
  ///
  /// In en, this message translates to:
  /// **'This server publishes no tools.'**
  String get mcpSettingsNoTools;

  /// Heading of the retained server diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Server output'**
  String get mcpSettingsDiagnostics;

  /// Label of the secret dialog action.
  ///
  /// In en, this message translates to:
  /// **'Store a secret'**
  String get mcpSettingsSecretSet;

  /// Label of the secret key field.
  ///
  /// In en, this message translates to:
  /// **'Reference name'**
  String get mcpSettingsSecretKey;

  /// Label of the secret value field.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get mcpSettingsSecretValue;

  /// Subtitle marking a tool every agent gets.
  ///
  /// In en, this message translates to:
  /// **'Always available'**
  String get agentSettingsToolAlwaysOn;

  /// Result line of a get_context_remaining call.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {window} tokens left'**
  String toolContextRemaining(int remaining, int window);

  /// Result line when the provider never advertised a window.
  ///
  /// In en, this message translates to:
  /// **'{used} tokens used'**
  String toolContextRemainingUnknown(int used);

  /// Divider marking where the model's history was discarded.
  ///
  /// In en, this message translates to:
  /// **'New context window'**
  String get chatContextReset;

  /// Divider marking where the model's history was replaced by a summary.
  ///
  /// In en, this message translates to:
  /// **'Conversation summarized'**
  String get chatContextCompacted;

  /// Name of the composer command that summarizes the conversation.
  ///
  /// In en, this message translates to:
  /// **'compact'**
  String get composerCommandCompactLabel;

  /// Description of the compact command.
  ///
  /// In en, this message translates to:
  /// **'Summarize the conversation to free the context window.'**
  String get composerCommandCompactDescription;

  /// Label of the composer context budget meter.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get sessionContextMeter;

  /// Accessible value of the context budget meter.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of the context window used'**
  String sessionContextMeterValue(int percent);

  /// No description provided for @sessionContextDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Context usage'**
  String get sessionContextDetailsTitle;

  /// No description provided for @sessionContextPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String sessionContextPercent(int percent);

  /// No description provided for @sessionContextTokens.
  ///
  /// In en, this message translates to:
  /// **'{used} / {max} tokens'**
  String sessionContextTokens(String used, String max);

  /// No description provided for @sessionContextCost.
  ///
  /// In en, this message translates to:
  /// **'Session cost {cost}'**
  String sessionContextCost(String cost);

  /// No description provided for @sessionQuotaLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading provider usage'**
  String get sessionQuotaLoading;

  /// No description provided for @sessionQuotaError.
  ///
  /// In en, this message translates to:
  /// **'Provider usage is temporarily unavailable.'**
  String get sessionQuotaError;

  /// No description provided for @sessionQuotaProviderPlan.
  ///
  /// In en, this message translates to:
  /// **'{provider} · {plan}'**
  String sessionQuotaProviderPlan(String provider, String plan);

  /// No description provided for @sessionQuotaPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String sessionQuotaPercent(int percent);

  /// No description provided for @sessionQuotaResets.
  ///
  /// In en, this message translates to:
  /// **'Resets {time}'**
  String sessionQuotaResets(String time);

  /// No description provided for @sessionQuotaCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits {amount}'**
  String sessionQuotaCredits(String amount);

  /// No description provided for @sessionQuotaWindowSession.
  ///
  /// In en, this message translates to:
  /// **'Session limit'**
  String get sessionQuotaWindowSession;

  /// No description provided for @sessionQuotaWindowWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly limit'**
  String get sessionQuotaWindowWeekly;

  /// No description provided for @sessionQuotaWindowCodeReview.
  ///
  /// In en, this message translates to:
  /// **'Code review limit'**
  String get sessionQuotaWindowCodeReview;

  /// Error shown when a slash command is submitted with attachments.
  ///
  /// In en, this message translates to:
  /// **'Remove attachments to run a command.'**
  String get composerCommandNoAttachments;

  /// Empty state of the composer command list.
  ///
  /// In en, this message translates to:
  /// **'No commands'**
  String get composerCommandsEmpty;

  /// Empty state of the composer file mention list.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get composerFilesEmpty;

  /// Loading state of the composer file mention list.
  ///
  /// In en, this message translates to:
  /// **'Searching workspace'**
  String get composerFilesSearching;

  /// Error state of the composer command list.
  ///
  /// In en, this message translates to:
  /// **'Could not load commands'**
  String get composerCommandsError;

  /// Error state of the composer file mention list.
  ///
  /// In en, this message translates to:
  /// **'Could not search files'**
  String get composerFilesError;

  /// Badge marking an app-owned composer command.
  ///
  /// In en, this message translates to:
  /// **'app'**
  String get composerCommandSourceClient;

  /// Badge marking a Markdown-defined agent command.
  ///
  /// In en, this message translates to:
  /// **'command'**
  String get composerCommandSourceAgent;

  /// Badge marking a composer command that loads a skill.
  ///
  /// In en, this message translates to:
  /// **'skill'**
  String get composerCommandSourceSkill;

  /// Name of the composer command that clears the draft.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get composerCommandClearLabel;

  /// Description of the clear command.
  ///
  /// In en, this message translates to:
  /// **'Clear the composer.'**
  String get composerCommandClearDescription;

  /// Name of the composer command that starts a session.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get composerCommandNewLabel;

  /// Description of the new session command.
  ///
  /// In en, this message translates to:
  /// **'Start a new session.'**
  String get composerCommandNewDescription;

  /// Name of the composer command that switches mode.
  ///
  /// In en, this message translates to:
  /// **'mode'**
  String get composerCommandModeLabel;

  /// Description of the mode command.
  ///
  /// In en, this message translates to:
  /// **'Switch between planning and working.'**
  String get composerCommandModeDescription;

  /// Name of the composer command that opens agent settings.
  ///
  /// In en, this message translates to:
  /// **'agents'**
  String get composerCommandAgentsLabel;

  /// Description of the agents command.
  ///
  /// In en, this message translates to:
  /// **'Open agent settings.'**
  String get composerCommandAgentsDescription;

  /// Name of the composer command that opens skill settings.
  ///
  /// In en, this message translates to:
  /// **'skills'**
  String get composerCommandSkillsLabel;

  /// Description of the skills command.
  ///
  /// In en, this message translates to:
  /// **'Open skill settings.'**
  String get composerCommandSkillsDescription;

  /// Name of the composer command that lists commands.
  ///
  /// In en, this message translates to:
  /// **'help'**
  String get composerCommandHelpLabel;

  /// Description of the help command.
  ///
  /// In en, this message translates to:
  /// **'List the available commands.'**
  String get composerCommandHelpDescription;

  /// No description provided for @composerCommandGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'goal'**
  String get composerCommandGoalLabel;

  /// No description provided for @composerCommandGoalDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or manage persistent session work.'**
  String get composerCommandGoalDescription;

  /// No description provided for @goalStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalStatusActive;

  /// No description provided for @goalStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get goalStatusPaused;

  /// No description provided for @goalStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get goalStatusBlocked;

  /// No description provided for @goalStatusUsageLimited.
  ///
  /// In en, this message translates to:
  /// **'Usage limited'**
  String get goalStatusUsageLimited;

  /// No description provided for @goalStatusBudgetLimited.
  ///
  /// In en, this message translates to:
  /// **'Budget reached'**
  String get goalStatusBudgetLimited;

  /// No description provided for @goalStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get goalStatusComplete;

  /// No description provided for @goalPlanHold.
  ///
  /// In en, this message translates to:
  /// **'Resumes in Run mode'**
  String get goalPlanHold;

  /// No description provided for @goalElapsed.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s elapsed'**
  String goalElapsed(int seconds);

  /// No description provided for @goalTokenUsage.
  ///
  /// In en, this message translates to:
  /// **'{used} / {budget} tokens'**
  String goalTokenUsage(int used, int budget);

  /// No description provided for @goalPause.
  ///
  /// In en, this message translates to:
  /// **'Pause goal'**
  String get goalPause;

  /// No description provided for @goalResume.
  ///
  /// In en, this message translates to:
  /// **'Resume goal'**
  String get goalResume;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// No description provided for @goalClear.
  ///
  /// In en, this message translates to:
  /// **'Clear goal'**
  String get goalClear;

  /// No description provided for @goalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Session goal'**
  String get goalDialogTitle;

  /// No description provided for @goalObjectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get goalObjectiveLabel;

  /// No description provided for @goalObjectiveRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter 1–4,000 characters.'**
  String get goalObjectiveRequired;

  /// No description provided for @goalBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Token budget (optional)'**
  String get goalBudgetLabel;

  /// No description provided for @goalBudgetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive token budget.'**
  String get goalBudgetInvalid;

  /// No description provided for @goalStart.
  ///
  /// In en, this message translates to:
  /// **'Start goal'**
  String get goalStart;

  /// No description provided for @goalReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current goal?'**
  String get goalReplaceTitle;

  /// No description provided for @goalReplaceDescription.
  ///
  /// In en, this message translates to:
  /// **'This starts a new goal and resets recorded usage.'**
  String get goalReplaceDescription;

  /// No description provided for @goalReplaceAction.
  ///
  /// In en, this message translates to:
  /// **'Replace goal'**
  String get goalReplaceAction;

  /// Accessible name of the composer suggestion list.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get composerSuggestionsLabel;

  /// Instruction shown over a composer pane while files are dragged over it.
  ///
  /// In en, this message translates to:
  /// **'Drop files here'**
  String get composerDropFilesHere;

  /// No description provided for @chatToolActionRead.
  ///
  /// In en, this message translates to:
  /// **'Read file'**
  String get chatToolActionRead;

  /// No description provided for @chatToolActionList.
  ///
  /// In en, this message translates to:
  /// **'List files'**
  String get chatToolActionList;

  /// No description provided for @chatToolActionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get chatToolActionSearch;

  /// No description provided for @chatToolActionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit files'**
  String get chatToolActionEdit;

  /// No description provided for @chatToolActionRun.
  ///
  /// In en, this message translates to:
  /// **'Run command'**
  String get chatToolActionRun;

  /// No description provided for @chatToolActionDelegate.
  ///
  /// In en, this message translates to:
  /// **'Coordinate agents'**
  String get chatToolActionDelegate;

  /// No description provided for @chatToolActionPlan.
  ///
  /// In en, this message translates to:
  /// **'Update plan'**
  String get chatToolActionPlan;

  /// No description provided for @chatToolActionAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get chatToolActionAsk;

  /// No description provided for @chatToolActionResource.
  ///
  /// In en, this message translates to:
  /// **'Use resource'**
  String get chatToolActionResource;

  /// No description provided for @chatToolActionTools.
  ///
  /// In en, this message translates to:
  /// **'Find tools'**
  String get chatToolActionTools;

  /// No description provided for @chatToolActionClock.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get chatToolActionClock;

  /// No description provided for @chatToolActionContext.
  ///
  /// In en, this message translates to:
  /// **'Manage context'**
  String get chatToolActionContext;

  /// No description provided for @chatToolActionImage.
  ///
  /// In en, this message translates to:
  /// **'View image'**
  String get chatToolActionImage;

  /// No description provided for @chatToolActionGeneric.
  ///
  /// In en, this message translates to:
  /// **'Use tool'**
  String get chatToolActionGeneric;

  /// Label of a live expandable reasoning row.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get chatReasoningThinking;

  /// Label of a completed expandable reasoning row.
  ///
  /// In en, this message translates to:
  /// **'Thought'**
  String get chatReasoningThought;

  /// Placeholder inside reasoning opened before text arrives.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reasoning details…'**
  String get chatReasoningWaiting;

  /// No description provided for @chatToolStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get chatToolStatusFailed;

  /// No description provided for @chatToolStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get chatToolStatusDenied;

  /// No description provided for @chatToolDetailsTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get chatToolDetailsTool;

  /// No description provided for @chatToolDetailsRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get chatToolDetailsRequest;

  /// No description provided for @chatToolDetailsResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get chatToolDetailsResult;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
