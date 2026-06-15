unit Monopoly.Rules.Jail;

interface

uses
  Monopoly.Transactions,
  Monopoly.Types;

function TryGetOutJail(
  const AGame: TGame;
  const ATransactions: ITransactionService;
  out JailRoll: TDiceRoll
  ): boolean;

implementation

uses
  System.SysUtils;

procedure ReleasePlayerFromJail(Player: TPlayer);
begin
  Player.IsInJail := False;
  Player.FailedJailRolls := 0;
end;

function TryGetOutJail(
  const AGame: TGame;
  const ATransactions: ITransactionService;
  out JailRoll: TDiceRoll
  ): boolean;
var
  Player: TPlayer;
  JailCard: THeldJailCard;
  Roll: TDiceRoll;
begin
  Player := AGame.CurrentPlayer;

  if Player.GetOutOfJailCards.Count > 0 then
  begin
    JailCard := Player.GetOutOfJailCards[0];
    Player.GetOutOfJailCards.Delete(0);
    JailCard.Deck.ReturnCard(JailCard.Card);
    ReleasePlayerFromJail(Player);
    AGame.Log(Format('%s uses a Get Out of Jail Free card.', [Player.Name]));
    JailRoll := AGame.DiceRoller();
    Exit(True);
  end;

  if Player.Money >= JAIL_FINE then
  begin
    ReleasePlayerFromJail(Player);
    AGame.PayBank(Player, JAIL_FINE);
    AGame.Log(Format('%s pays $50 to get out of jail.', [Player.Name]));
    JailRoll := AGame.DiceRoller();
    Exit(True);
  end;

  Roll := AGame.RollDice;
  if Roll.IsDouble then
  begin
    ReleasePlayerFromJail(Player);
    AGame.Log(Format('%s rolls doubles and gets out of jail.', [Player.Name]));
    JailRoll := Roll;
    Exit(True);
  end;

  Inc(Player.FailedJailRolls);
  AGame.Log(Format('%s fails to roll doubles and remains in jail.', [Player.Name]));

  if Player.FailedJailRolls < MAX_FAILED_JAIL_ROLLS then
  begin
    Exit(False);
  end;

  ATransactions.MarkPlayerBankrupt(Player, AGame.Board, nil, AGame.OnLog);
  Exit(False);
end;

end.
