; Inno Setup script for the Coder desktop application.
;
; The Flutter release output is a directory, so the installer ships the whole
; tree and creates the shortcuts and uninstaller that a portable zip cannot.
;
; Build with:
;   iscc /DAppVersion=1.2.3 /DSourceDir=..\..\build\windows\x64\runner\Release \
;        /DOutputDir=..\..\dist /DAppArch=x64 coder.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif
#ifndef AppArch
  #define AppArch "x64"
#endif

#define AppName "Coder"
#define AppPublisher "Tinyrack"
#define AppUrl "https://github.com/tinyrack-net/coder"
#define AppExeName "coder.exe"

[Setup]
AppId={{9F4B3C21-6E58-4A7D-9C1E-0B2D5A8F3E14}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}
AppUpdatesURL={#AppUrl}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
OutputDir={#OutputDir}
OutputBaseFilename=Coder-setup-win-{#AppArch}
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Per-machine when elevated, per-user otherwise, so an unprivileged install
; still works.
PrivilegesRequiredOverridesAllowed=commandline dialog
; Closing the window only hides the app to the tray, so a running copy would
; otherwise survive the install, keep the exclusive lock on the daemon home,
; and make the freshly launched copy fail to start its daemon. The mutex name
; must match kMutexName in windows/runner/single_instance.cpp.
AppMutex=Local\tinyrack-coder-single-instance
CloseApplications=yes
; The app restores itself through its login item, and restarting it from here
; would run it with the installer's token.
RestartApplications=no
#if AppArch == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
  GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; \
  Tasks: desktopicon

[Run]
; runasoriginaluser, because a per-machine install runs elevated and would
; otherwise start the app with the administrator's token. The daemon home comes
; from %LOCALAPPDATA%, so an elevated launch reads a different profile than
; every later launch from the Start menu.
Filename: "{app}\{#AppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent runasoriginaluser

[Registry]
; The app registers itself to start at login by writing this Run value, so the
; uninstaller has to remove it or Windows keeps launching a deleted path. The
; entry is never created here, only cleaned up.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueName: "tinyrack-coder"; ValueType: none; Flags: uninsdeletevalue
