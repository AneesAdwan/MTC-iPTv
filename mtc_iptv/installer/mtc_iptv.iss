; MTC-iPTv - Windows installer (Inno Setup, ADR-11).
; Per-user install without admin rights (spec 18.2). Unsigned for now (D-07).
; Built by scripts/release.ps1:  iscc /DAppVersion=3.0.0-alpha.1 /DFileVersion=3.0.0.1 /DSourceDir=... installer\mtc_iptv.iss
; (ASCII only: Inno and Windows PowerShell 5 are happier that way.)

#ifndef AppVersion
  #define AppVersion "3.0.0"
#endif
#ifndef FileVersion
  #define FileVersion "3.0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

[Setup]
AppId={{7D3C5E1A-2B4F-4A8C-9E61-5F0B3D2A7C94}
AppName=MTC-iPTv
AppVersion={#AppVersion}
AppVerName=MTC-iPTv {#AppVersion}
VersionInfoVersion={#FileVersion}
AppPublisher=MTC-Group
AppPublisherURL=https://github.com/AneesAdwan/MTC-iPTv
AppCopyright=(C) MTC-Group. Developed by Anees Adwan
DefaultDirName={localappdata}\Programs\MTC-iPTv
DefaultGroupName=MTC-iPTv
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
DisableDirPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=MTC-iPTv-{#AppVersion}-windows-setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\mtc_iptv.exe
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19044
CloseApplications=force
RestartApplications=no
WizardStyle=modern

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MTC-iPTv"; Filename: "{app}\mtc_iptv.exe"
Name: "{autodesktop}\MTC-iPTv"; Filename: "{app}\mtc_iptv.exe"; Tasks: desktopicon

[Registry]
; Deep links mtciptv://watch/<id> (same scheme as the web site and the React Native app). Per-user (HKCU), no admin.
Root: HKCU; Subkey: "Software\Classes\mtciptv"; ValueType: string; ValueName: ""; ValueData: "URL:MTC-iPTv"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\mtciptv"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\mtciptv\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\mtc_iptv.exe"",0"
Root: HKCU; Subkey: "Software\Classes\mtciptv\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\mtc_iptv.exe"" ""%1"""

[Run]
Filename: "{app}\mtc_iptv.exe"; Description: "{cm:LaunchProgram,MTC-iPTv}"; Flags: nowait postinstall skipifsilent
