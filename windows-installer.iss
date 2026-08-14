; ErisPulse-App Windows 安装器（Inno Setup 6）。
;
; 用法（CI）：
;   ISCC /DVersion=<版本> /DArch=<x64|arm64> windows-installer.iss
; 产出 out/ErisPulse-App-{Version}-windows-{Arch}-setup.exe

#ifndef Version
  #define Version "0.1.1"
#endif
#ifndef Arch
  #define Arch "x64"
#endif

#define AppName "ErisPulse App"
#define SrcDir "build\windows\" + Arch + "\runner\Release"

[Setup]
AppId={{6F3C9B2E-4A1D-4E7B-9C5F-2D8E4A0B1C3D}
AppName={#AppName}
AppVersion={#Version}
AppPublisher=ErisPulse
AppPublisherURL=https://github.com/ErisPulse/ErisPulse-App
DefaultDirName={autopf}\ErisPulse App
DefaultGroupName=ErisPulse App
UninstallDisplayIcon={app}\erispulse_app.exe
OutputDir=out
OutputBaseFilename=ErisPulse-App-{#Version}-windows-{#Arch}-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes

#if Arch == "arm64"
  ArchitecturesAllowed=arm64
  ArchitecturesInstallIn64BitMode=arm64
#else
  ArchitecturesAllowed=x64compatible
  ArchitecturesInstallIn64BitMode=x64compatible
#endif

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SrcDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\ErisPulse App"; Filename: "{app}\erispulse_app.exe"
Name: "{autodesktop}\ErisPulse App"; Filename: "{app}\erispulse_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\erispulse_app.exe"; Description: "{cm:LaunchProgram,ErisPulse App}"; Flags: nowait postinstall skipifsilent
