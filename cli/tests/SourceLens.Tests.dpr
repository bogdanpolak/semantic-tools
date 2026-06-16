program SourceLensTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ELSE}
  DUnitX.Loggers.Console,
  {$ENDIF }
  DUnitX.TestFramework,
  Tests.SourceLens.CliOptions in 'Tests.SourceLens.CliOptions.pas',
  Tests.SourceLens.DelphiAnalyzer in 'Tests.SourceLens.DelphiAnalyzer.pas',
  Tests.SourceLens.ReportPrinter in 'Tests.SourceLens.ReportPrinter.pas',
  Tests.SourceLens.Utils in 'Tests.SourceLens.Utils.pas',
  SemanticTools.DelphiAstParser in '..\src\units\SemanticTools.DelphiAstParser.pas',
  SourceLens.CliOptions in '..\src\units\SourceLens.CliOptions.pas',
  SemanticTools.Utils in '..\src\units\SemanticTools.Utils.pas',
  SourceLens.DelphiAnalyzer in '..\src\units\SourceLens.DelphiAnalyzer.pas',
  SourceLens.ReportPrinter in '..\src\units\SourceLens.ReportPrinter.pas',
  SourceLens.Types in '..\src\units\SourceLens.Types.pas';

{$IFNDEF TESTINSIGHT}
var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
{$ENDIF}
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
{$ELSE}
  try
    TDUnitX.CheckCommandLine;

    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := False;

    logger := TDUnitXConsoleLogger.Create(
      TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
    runner.AddLogger(logger);

    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
{$ENDIF}
end.