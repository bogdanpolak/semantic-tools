unit SemanticTools.FileScanner;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils;

type
  TSourceFileScanner = class
  public
    class function CollectPasFiles(
      const AScanFolder: string
      ): TArray<string>;
  end;

implementation

{ Utils }

function GetFolderFullPath(const ScanFolder: string): string;
var
  ExeRelativeFolder: string;
  CurrentDirRelativeFolder: string;
begin
  CurrentDirRelativeFolder := TPath.GetFullPath(ScanFolder);
  if TDirectory.Exists(CurrentDirRelativeFolder) then
    Exit(CurrentDirRelativeFolder);

  ExeRelativeFolder := TPath.GetFullPath(
    TPath.Combine(ExtractFilePath(ParamStr(0)), ScanFolder)
    );
  if TDirectory.Exists(ExeRelativeFolder) then
    Exit(ExeRelativeFolder);

  raise Exception.CreateFmt(
    'Scan folder not found: %s. The Full path has to be one of: ["%s", "%s"]',
    [ScanFolder, ExeRelativeFolder, CurrentDirRelativeFolder]);
end;

{ TSourceFileScanner }

class function TSourceFileScanner.CollectPasFiles(
  const AScanFolder: string
  ): TArray<string>;
var
  Files: TStringList;
  FileName: string;
  RootFolder: string;
begin
  RootFolder := GetFolderFullPath(AScanFolder);

  Files := TStringList.Create;
  try
    for FileName in TDirectory.GetFiles(
      RootFolder,
      '*.pas',
      TSearchOption.soAllDirectories
      ) do
      Files.Add(FileName);

    Files.Sort;
    Result := Files.ToStringArray;
  finally
    Files.Free;
  end;
end;

end.