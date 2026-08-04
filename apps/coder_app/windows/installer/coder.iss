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
PrivilegesRequiredOverridesAllowed=dialog
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
Filename: "{app}\{#AppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent

[Registry]
; The app registers itself to start at login by writing this Run value, so the
; uninstaller has to remove it or Windows keeps launching a deleted path. The
; entry is never created here, only cleaned up.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; \
  ValueName: "tinyrack-coder"; ValueType: none; Flags: uninsdeletevalue
