import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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

  /// Title of the settings shell.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

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

  /// Title of the alert shown when a reset fails.
  ///
  /// In en, this message translates to:
  /// **'Reset failed'**
  String get advancedResetFailedTitle;

  /// Reset failure caused by a daemon owning the data directory.
  ///
  /// In en, this message translates to:
  /// **'Another Tinyrack Coder daemon is using the data directory. Quit it and try again. Nothing was deleted.'**
  String get advancedResetFailedDaemonRunning;

  /// Reset failure reported by the operating system.
  ///
  /// In en, this message translates to:
  /// **'Some daemon files could not be deleted: {error}'**
  String advancedResetFailedFilesystem(String error);

  /// Reset failure that leaves device-local settings behind.
  ///
  /// In en, this message translates to:
  /// **'Daemon data was removed but the app settings could not be cleared. Restart Tinyrack Coder.'**
  String get advancedResetFailedIncomplete;

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
  /// **'The operating system launches Tinyrack Coder after you sign in, so the embedded daemon keeps running.'**
  String get generalStartupAtBootDescription;

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

  /// Explains that the window close button no longer quits the app.
  ///
  /// In en, this message translates to:
  /// **'Closing the window keeps Tinyrack Coder running in the tray.'**
  String get generalStartupCloseNotice;

  /// Hover text of the tray icon.
  ///
  /// In en, this message translates to:
  /// **'Tinyrack Coder'**
  String get trayTooltip;

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
  /// **'About Tinyrack Coder'**
  String get desktopMenuAbout;

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
  /// **'The project disappears from Coder, but its repository and files stay on disk.'**
  String get workspaceUnregisterBody;

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

  /// Archive effect for a Coder-managed checkout.
  ///
  /// In en, this message translates to:
  /// **'The checkout directory created by Coder will be removed.'**
  String get workspaceArchiveRemovesDirectory;

  /// Archive effect for an externally created checkout.
  ///
  /// In en, this message translates to:
  /// **'Only the registration is hidden; the checkout stays on disk.'**
  String get workspaceArchiveKeepsDirectory;

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

  /// Button that opens daemon settings from the empty sidebar.
  ///
  /// In en, this message translates to:
  /// **'Daemon settings'**
  String get workspaceOpenDaemonSettings;

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

  /// Connection failure in a browser for a daemon on the local machine or network, where the browser does not report whether the daemon was down or the Local Network Access permission was refused.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the daemon. Check that it is running, and that you allowed this site to access your local network.'**
  String get hostErrorLocalNetworkUnreachable;

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

  /// Text field label for replacing a stored token.
  ///
  /// In en, this message translates to:
  /// **'New bearer token (only when changing it)'**
  String get appSettingsNewToken;

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

  /// Tooltip that copies the coder.json path.
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

  /// Subtitle counting agent definitions.
  ///
  /// In en, this message translates to:
  /// **'{count} definitions'**
  String agentSettingsCount(int count);

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

  /// Model mode that requires each session to select a provider and model.
  ///
  /// In en, this message translates to:
  /// **'Choose for each session'**
  String get agentSettingsSessionModel;

  /// Model mode that pins one provider and model.
  ///
  /// In en, this message translates to:
  /// **'Pinned provider/model'**
  String get agentSettingsPinnedModel;

  /// Heading of the tool permission list.
  ///
  /// In en, this message translates to:
  /// **'Built-in tools'**
  String get agentSettingsBuiltinTools;

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

  /// Title of the OpenAI auth method sheet.
  ///
  /// In en, this message translates to:
  /// **'OpenAI connection'**
  String get providerSettingsOpenAiTitle;

  /// Warns that ChatGPT sign-in is experimental.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT sign-in is experimental and relies on the public Codex auth flow.'**
  String get providerSettingsOpenAiSubtitle;

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

  /// Title of the pending OAuth attempt bar.
  ///
  /// In en, this message translates to:
  /// **'Waiting for ChatGPT sign-in'**
  String get providerSettingsOAuthPending;

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

  /// Model picker entry that inherits the agent default.
  ///
  /// In en, this message translates to:
  /// **'Use the agent default'**
  String get composerInheritModel;

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
  /// **'Select a model first.'**
  String get composerSelectModelFirst;

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
  /// **'Ask'**
  String get composerPermissionAsk;

  /// Permission mode allowing workspace writes without asking.
  ///
  /// In en, this message translates to:
  /// **'Write workspace'**
  String get composerPermissionWorkspaceWrite;

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

  /// Accessible label for the composer attachment button.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get composerAttachLabel;

  /// Label of the overflow menu holding the settings that do not fit.
  ///
  /// In en, this message translates to:
  /// **'More settings'**
  String get composerMoreSettings;

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

  /// Result line while a pseudo-terminal session is still running.
  ///
  /// In en, this message translates to:
  /// **'running · {lines} lines'**
  String toolExecRunning(int lines);

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

  /// Snackbar shown when a worktree hook fails.
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
  /// **'Defined by this repository, so Coder does not edit it.'**
  String get mcpSettingsProjectReadOnly;

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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
