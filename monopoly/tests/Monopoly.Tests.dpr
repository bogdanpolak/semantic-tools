program MonopolyTests;

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
  Monopoly.Tests.Factories in 'Monopoly.Tests.Factories.pas',
  Monopoly.Tests.GameLoop in 'Monopoly.Tests.GameLoop.pas',
  Monopoly.Tests.Transactions in 'Monopoly.Tests.Transactions.pas',
  Monopoly.Tests.Types in 'Monopoly.Tests.Types.pas',
  Monopoly.Tests.Utils in 'Monopoly.Tests.Utils.pas',
  Helpers.Monopoly in 'helpers\Helpers.Monopoly.pas',
  Monopoly.Tests.Jail in 'rules\Monopoly.Tests.Jail.pas',
  Monopoly.Tests.Landing in 'rules\Monopoly.Tests.Landing.pas',
  Monopoly.Tests.Cards in 'rules\Monopoly.Tests.Cards.pas',
  Monopoly.Factories in '..\src\Monopoly.Factories.pas',
  Monopoly.GameLoop in '..\src\Monopoly.GameLoop.pas',
  Monopoly.Types in '..\src\Monopoly.Types.pas',
  Monopoly.Utils in '..\src\Monopoly.Utils.pas',
  Monopoly.Transactions in '..\src\Monopoly.Transactions.pas',
  Monopoly.Rules.Cards in '..\src\rules\Monopoly.Rules.Cards.pas',
  Monopoly.Rules.Jail in '..\src\rules\Monopoly.Rules.Jail.pas',
  Monopoly.Rules.Landing in '..\src\rules\Monopoly.Rules.Landing.pas',
  Monopoly.Rules.Rent in '..\src\rules\Monopoly.Rules.Rent.pas',
  Monopoly.CardHandlers in '..\src\rules\Monopoly.CardHandlers.pas',
  Monopoly.LandingHandlers in '..\src\rules\Monopoly.LandingHandlers.pas',
  Monopoly.RentHandlers in '..\src\rules\Monopoly.RentHandlers.pas';

{ keep comment here to protect the following conditional from being removed by the IDE when adding a unit }
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
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //When true, Assertions must be made during tests;
    runner.FailsOnNoAsserts := False;

    logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
    runner.AddLogger(logger);

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
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

