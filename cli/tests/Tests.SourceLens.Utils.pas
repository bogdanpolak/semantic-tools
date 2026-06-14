unit Tests.SourceLens.Utils;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.SysUtils,
  System.StrUtils,
  DUnitX.TestFramework,
  SemanticTools.DelphiAstParser,
  SourceLens.Types;

type
  TFakeFileRepository = class(TInterfacedObject, IFileRepository)
  private
    FFiles: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddStringsAsFile(
      const AFileName: string;
      const ALines: array of string
      );
    function OpenRead(const AFileName: string): TStream;
  end;

function GetFullMethodNames(const AAnalysisResult: TAnalysisResult): TArray<string>;


implementation

constructor TFakeFileRepository.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, string>.Create;
end;

destructor TFakeFileRepository.Destroy;
begin
  FFiles.Free;
  inherited;
end;

function NormalizeFileName(const AFileName: string): string;
begin
  Result := AnsiLowerCase(TPath.GetFullPath(AFileName));
end;

procedure TFakeFileRepository.AddStringsAsFile(
  const AFileName: string;
  const ALines: array of string
  );
var
  Txt: string;
begin
  Txt := string.Join(sLineBreak, ALines);
  FFiles.AddOrSetValue(NormalizeFileName(AFileName), Txt);
end;

function TFakeFileRepository.OpenRead(const AFileName: string): TStream;
var
  Content: string;
begin
  if not FFiles.TryGetValue(NormalizeFileName(AFileName), Content) then
    raise Exception.CreateFmt('File not found: %s', [AFileName]);

  Result := TStringStream.Create(Content);
end;

function GetFullMethodNames(const AAnalysisResult: TAnalysisResult): TArray<string>;
var
  Count: integer;
  Idx: integer;
  AInfo: TMethodInfo;
begin
  Count := Length(AAnalysisResult.MethodInfos);
  SetLength(Result, Count);
  for Idx := 0 to Count-1 do
  begin
    AInfo := AAnalysisResult.MethodInfos[Idx];
    if AInfo.ClassName = '' then
      Result[Idx] := Format('%s | %s',
        [AInfo.UnitName, AInfo.MethodName])
    else
      Result[Idx] := Format('%s | %s.%s',
        [AInfo.UnitName, AInfo.ClassName, AInfo.MethodName])
  end;
end;

end.
