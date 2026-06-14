unit SourceLens.Main;

interface

uses
  System.SysUtils;

const
  ScanFolder = '..\monopoly\src';

procedure RunSourceLens();

implementation

uses
  SourceLens.Types,
  SemanticTools.FileScanner,
  SourceLens.ReportPrinter,
  SourceLens.DelphiAnalyzer,
  SemanticTools.DelphiAstParser;

function CreateDelphiAnalyzer(): IDelphiAnalyzer;
var
  AstParser: IAstParser;
begin
  AstParser := CreateAstParser();
  Result := TDelphiAnalyzer.Create(AstParser);
end;

procedure RunSourceLens();
var
  DelphiAnalyzer: IDelphiAnalyzer;
  AnalysisResult: TAnalysisResult;
  Files: TArray<string>;
begin
  try
    DelphiAnalyzer := CreateDelphiAnalyzer();
    WriteLn('SourceLens - Delphi code metrics analyzer');
    WriteLn('Current focus: method body size');
    WriteLn('Scan folder: ', ScanFolder);

    Files := TSourceFileScanner.CollectPasFiles(ScanFolder);
    WriteLn('Found .pas files: ', Length(Files));

    AnalysisResult := DelphiAnalyzer.AnalyzeRepository(Files);

    TReportPrinter.Print(AnalysisResult);
  except
    on E: Exception do
      WriteLn('Fatal error: ', E.ClassName, ': ', E.Message);
  end;
end;

end.
