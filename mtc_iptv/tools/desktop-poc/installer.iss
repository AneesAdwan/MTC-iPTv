; Inno Setup script - Phase 0 desktop PoC (ADR-11).
; Per-user install, no admin rights (PrivilegesRequired=lowest), as required by spec §18.2.
; Built by build_release.ps1:  iscc /DAppVersion=1.0.1 /DSourceDir=... installer.iss

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{B6F1C2A4-5D7E-4C1B-9E3A-7A0D2F1C9E11}
AppName=MTC-iPTv Desktop PoC
AppVersion={#AppVersion}
AppPublisher=MTC-Group
DefaultDirName={localappdata}\Programs\MTC-iPTv-PoC
DefaultGroupName=MTC-iPTv PoC
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=mtc-desktop-poc-{#AppVersion}-setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Close the running app before replacing files (update while running)
CloseApplications=force
RestartApplications=no
UninstallDisplayIcon={app}\mtc_desktop_poc.exe

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\MTC-iPTv PoC"; Filename: "{app}\mtc_desktop_poc.exe"
Name: "{autodesktop}\MTC-iPTv PoC"; Filename: "{app}\mtc_desktop_poc.exe"

[Run]
Filename: "{app}\mtc_desktop_poc.exe"; Description: "Launch"; Flags: nowait postinstall skipifsilent
