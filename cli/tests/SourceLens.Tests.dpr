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
  Tests.SourceLens.DelphiAnalyzer in 'Tests.SourceLens.DelphiAnalyzer.pas',
  Tests.SourceLens.Utils in 'Tests.SourceLens.Utils.pas',
  SourceLens.DelphiAnalyzer in '..\src\units\SourceLens.DelphiAnalyzer.pas',
  SourceLens.Extractor.PublicMethods in '..\src\units\SourceLens.Extractor.PublicMethods.pas',
  SourceLens.ParserEnvironment in '..\src\units\SourceLens.ParserEnvironment.pas',
  SourceLens.Types in '..\src\units\SourceLens.Types.pas',
  SourceLens.Utils in '..\src\units\SourceLens.Utils.pas';

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