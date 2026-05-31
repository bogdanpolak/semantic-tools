program MonopolyConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Monopoly.CardHandlers in 'rules\Monopoly.CardHandlers.pas',
  Monopoly.LandingHandlers in 'rules\Monopoly.LandingHandlers.pas',
  Monopoly.RentHandlers in 'rules\Monopoly.RentHandlers.pas',
  Monopoly.Rules.Cards in 'rules\Monopoly.Rules.Cards.pas',
  Monopoly.Rules.Jail in 'rules\Monopoly.Rules.Jail.pas',
  Monopoly.Rules.Landing in 'rules\Monopoly.Rules.Landing.pas',
  Monopoly.Rules.Rent in 'rules\Monopoly.Rules.Rent.pas',

  Monopoly.ConsoleView in 'Monopoly.ConsoleView.pas',
  Monopoly.Factories in 'Monopoly.Factories.pas',
  Monopoly.GameLoop in 'Monopoly.GameLoop.pas',
  Monopoly.Transactions in 'Monopoly.Transactions.pas',
  Monopoly.Types in 'Monopoly.Types.pas',
  Monopoly.Utils in 'Monopoly.Utils.pas';


var
  Game: TGame;
begin
  Randomize;
  Game := CreateGame(['Alice', 'Bob', 'Charlie', 'Diana']);
  try
    Game.OnLog :=
      procedure(const Message: string)
      begin
        Writeln(Message);
      end;

    ShowIntro(Game.Players);
    PlayGame(Game);
    ShowSummary(Game.Players);
  finally
    Game.Free;
  end;
end.