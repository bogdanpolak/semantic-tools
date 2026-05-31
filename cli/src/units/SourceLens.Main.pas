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
  SourceLens.FileScanner,
  SourceLens.DelphiAnalyzer,
  SourceLens.ReportPrinter;

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

    AnalysisResult := DelphiAnalyzer.AnalyzeUnits(Files);

    TReportPrinter.Print(AnalysisResult);
  except
    on E: Exception do
      WriteLn('Fatal error: ', E.ClassName, ': ', E.Message);
  end;
end;

end.
