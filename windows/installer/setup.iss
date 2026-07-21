#define MyAppName "Flower Center Warehouse"
#define MyAppVersion "2.6.1"
#define MyAppPublisher "Flower Center"
#define MyAppURL "https://flowercenter.ae"
#define MyAppExeName "flowercenter_warehouse.exe"
#define MyAppSourceDir "..\..\build\windows\x64\runner\Release"

[Setup]
; Keep this AppId unchanged forever for upgrades/uninstall continuity
AppId={{B7C4D2E8-5F6A-4B7C-9D0E-1F2A3B4C5D6E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes

OutputDir=.\output
OutputBaseFilename=FlowerCenterWarehouse-Setup-{#MyAppVersion}

SetupIconFile=..\runner\resources\app_icon.ico

Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

CloseApplications=yes
CloseApplicationsFilter=*{#MyAppExeName}
 
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Copy the entire Flutter Windows Release output
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/F /IM {#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := True;
end;
