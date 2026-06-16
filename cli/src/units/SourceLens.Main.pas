unit SourceLens.Main;

interface

uses
  System.SysUtils;

procedure RunSourceLens();

implementation

uses
  SourceLens.CliOptions,
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

function GetCommandLineArgs(): TArray<string>;
var
  Index: integer;
begin
  SetLength(Result, ParamCount);
  for Index := 1 to ParamCount do
    Result[Index - 1] := ParamStr(Index);
end;

procedure RunSourceLens();
var
  Options: TSourceLensOptions;
  DelphiAnalyzer: IDelphiAnalyzer;
  AnalysisResult: TAnalysisResult;
  Files: TArray<string>;
begin
  try
    Options := TSourceLensCommandLine.Parse(GetCommandLineArgs());
    if Options.ShowHelp then
    begin
      WriteLn(TSourceLensCommandLine.GetHelpText());
      Exit;
    end;

    DelphiAnalyzer := CreateDelphiAnalyzer();
    Files := TSourceFileScanner.CollectPasFiles(Options.WorkingDir);

    AnalysisResult := DelphiAnalyzer.AnalyzeRepository(Files);

    TReportPrinter.Print(AnalysisResult, Options.ReportFormat);
  except
    on E: ECommandLineError do
    begin
      WriteLn(E.Message);
      WriteLn;
      WriteLn(TSourceLensCommandLine.GetHelpText());
      ExitCode := 1;
    end;
    on E: Exception do
    begin
      WriteLn('Fatal error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

end.
