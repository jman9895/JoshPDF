; qpdf GUI - Inno Setup script
; One-step installer: installs the GUI and installs qpdf via winget.
; Build with build.cmd

#define AppName      "qpdf GUI"
#define AppVersion   "1.1.1"
#define AppPublisher "Echostor Technologies"
#define PSExe        "{sys}\WindowsPowerShell\v1.0\powershell.exe"

[Setup]
AppId={{12531081-7174-4770-9694-93BDADA4AE2B}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir=output
OutputBaseFilename=qpdf-gui-setup-{#AppVersion}
SetupIconFile=qpdf-gui.ico
UninstallDisplayIcon={app}\qpdf-gui.ico
UninstallDisplayName={#AppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "qpdf-gui.ps1";     DestDir: "{app}"; Flags: ignoreversion
Source: "qpdf-gui.ico";     DestDir: "{app}"; Flags: ignoreversion
Source: "install-qpdf.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
; Start Menu shortcut (all users)
Name: "{autoprograms}\{#AppName}"; Filename: "{#PSExe}"; Parameters: "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File ""{app}\qpdf-gui.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\qpdf-gui.ico"
Name: "{autodesktop}\{#AppName}";  Filename: "{#PSExe}"; Parameters: "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File ""{app}\qpdf-gui.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\qpdf-gui.ico"; Tasks: desktopicon

[Run]
Filename: "{#PSExe}"; Parameters: "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File ""{app}\qpdf-gui.ps1"""; WorkingDir: "{app}"; Description: "Launch {#AppName}"; Flags: postinstall nowait skipifsilent runhidden

[UninstallDelete]
Type: files; Name: "{app}\install-qpdf.log"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  RC: Integer;
  Params, LogFile, Msg: String;
begin
  if CurStep = ssPostInstall then
  begin
    LogFile := ExpandConstant('{app}\install-qpdf.log');
    WizardForm.StatusLabel.Caption := 'Installing qpdf with winget (this can take a minute)...';
    WizardForm.ProgressGauge.Style := npbstMarquee;
    Params := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{tmp}\install-qpdf.ps1') +
              '" -LogPath "' + LogFile + '"';
    if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'), Params, '',
                SW_HIDE, ewWaitUntilTerminated, RC) then
      RC := -1;
    WizardForm.ProgressGauge.Style := npbstNormal;

    if RC <> 0 then
    begin
      if RC = 10 then
        Msg := 'winget was not found on this computer, so qpdf could not be installed automatically.'
      else
        Msg := 'qpdf could not be installed automatically (code ' + IntToStr(RC) + ').';
      Msg := Msg + #13#10#13#10 + 'qpdf GUI is installed. To finish, install qpdf manually:' + #13#10 +
             '    winget install --id QPDF.QPDF -e' + #13#10 +
             '  or download it from github.com/qpdf/qpdf/releases' + #13#10#13#10 +
             'The GUI will find qpdf automatically once it is installed.' + #13#10 +
             'Details: ' + LogFile;
      SuppressibleMsgBox(Msg, mbError, MB_OK, IDOK);
    end;
  end;
end;
