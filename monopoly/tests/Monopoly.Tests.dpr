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
  Monopoly.Tests.Board in 'Monopoly.Tests.Board.pas',
  Monopoly.Tests.Factories in 'Monopoly.Tests.Factories.pas',
  Monopoly.Tests.Decisions in 'rules\Monopoly.Tests.Decisions.pas',
  Monopoly.Tests.GameReport in 'Monopoly.Tests.GameReport.pas',
  Monopoly.Tests.PlayTurn in 'Monopoly.Tests.PlayTurn.pas',
  Monopoly.Tests.Transactions in 'Monopoly.Tests.Transactions.pas',
  Monopoly.Tests.Utils in 'Monopoly.Tests.Utils.pas',
  Monopoly.Tests.Helpers in 'helpers\Monopoly.Tests.Helpers.pas',
  Monopoly.Tests.Jail in 'rules\Monopoly.Tests.Jail.pas',
  Monopoly.Tests.Landing in 'rules\Monopoly.Tests.Landing.pas',
  Monopoly.Tests.Cards in 'rules\Monopoly.Tests.Cards.pas',
  Monopoly.Tests.Types.Deck in 'Monopoly.Tests.Types.Deck.pas',
  Monopoly.Tests.Types.Game in 'Monopoly.Tests.Types.Game.pas',
  Monopoly.Types in '..\src\Monopoly.Types.pas',
  Monopoly.Utils in '..\src\Monopoly.Utils.pas',
  Monopoly.Factories in '..\src\Monopoly.Factories.pas',
  Monopoly.GameReport in '..\src\Monopoly.GameReport.pas',
  Monopoly.CompositionRoot in '..\src\Monopoly.CompositionRoot.pas',
  Monopoly.Transactions in '..\src\Monopoly.Transactions.pas',
  Monopoly.Rules.Jail in '..\src\rules\Monopoly.Rules.Jail.pas',
  Monopoly.Rules.Landing in '..\src\rules\Monopoly.Rules.Landing.pas',
  Monopoly.Rules.Decisions in '..\src\rules\Monopoly.Rules.Decisions.pas',
  Container.Game in '..\src\Container.Game.pas',
  Monopoly.Tests.Build in 'rules\Monopoly.Tests.Build.pas';

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

