unit Monopoly.Rules.Jail;

interface

uses
  Monopoly.Transactions,
  Monopoly.Types;

const
  JAIL_FINE = 50;
  JAIL_TILE_ID = 10;
  MAX_FAILED_JAIL_ROLLS = 3;

type
  TJailResult = record
    CanMove: boolean;
    Roll: TDiceRoll;
    HasRoll: boolean;
    UsedJailRoll: boolean;
    class function Create(
      ACanMove: boolean;
      const ARoll: TDiceRoll;
      AHasRoll: boolean;
      AUsedJailRoll: boolean
    ): TJailResult; static;
  end;

function JailRules(
  const AGame: TGame;
  const ATransactions: ITransactionService
  ): TJailResult;
procedure SendCurrentPlayerToJail(Game: TGame);

implementation

uses
  System.SysUtils;

procedure ReleasePlayerFromJail(Player: TPlayer);
begin
  Player.IsInJail := False;
  Player.FailedJailRolls := 0;
end;

function JailRules(
  const AGame: TGame;
  const ATransactions: ITransactionService
  ): TJailResult;
var
  Player: TPlayer;
  JailCard: THeldJailCard;
  Roll: TDiceRoll;
begin
  Player := AGame.CurrentPlayer;
  if (Player = nil) or Player.IsBankrupt or not Player.IsInJail then
  begin
    Exit(TJailResult.Create(True, Default(TDiceRoll), False, False));
  end;

  if Player.GetOutOfJailCards.Count > 0 then
  begin
    JailCard := Player.GetOutOfJailCards[0];
    Player.GetOutOfJailCards.Delete(0);
    JailCard.Deck.ReturnCard(JailCard.Card);
    ReleasePlayerFromJail(Player);
    AGame.Log(Format('%s uses a Get Out of Jail Free card.', [Player.Name]));
    Exit(TJailResult.Create(True, Default(TDiceRoll), False, False));
  end;

  if Player.Money >= JAIL_FINE then
  begin
    ReleasePlayerFromJail(Player);
    AGame.PayBank(Player, JAIL_FINE);
    AGame.Log(Format('%s pays $50 to get out of jail.', [Player.Name]));
    Exit(TJailResult.Create(True, Default(TDiceRoll), False, False));
  end;

  Roll := AGame.RollDice;
  if Roll.IsDouble then
  begin
    ReleasePlayerFromJail(Player);
    AGame.Log(Format('%s rolls doubles and gets out of jail.', [Player.Name]));
    Exit(TJailResult.Create(True, Roll, True, True));
  end;

  Inc(Player.FailedJailRolls);
  AGame.Log(Format('%s fails to roll doubles and remains in jail.', [Player.Name]));

  if Player.FailedJailRolls < MAX_FAILED_JAIL_ROLLS then
  begin
    Exit(TJailResult.Create(False, Roll, True, True));
  end;

  ReleasePlayerFromJail(Player);
  if Player.Money < JAIL_FINE then
  begin
    ATransactions.MarkPlayerBankrupt(Player, AGame.Board, nil, AGame.OnLog);
    Exit(TJailResult.Create(False, Default(TDiceRoll), False, True));
  end;

  AGame.PayBank(Player, JAIL_FINE);
  AGame.Log(Format('%s pays $50 to get out of jail.', [Player.Name]));
  Result := TJailResult.Create(True, Roll, True, True);
end;

procedure SendCurrentPlayerToJail(Game: TGame);
var
  Player: TPlayer;
begin
  Player := Game.CurrentPlayer;
  if Player = nil then
  begin
    Exit;
  end;

  Game.MovePlayerTo(Player, JAIL_TILE_ID);
  Player.IsInJail := True;
  Player.FailedJailRolls := 0;
end;

{ TJailResult }

class function TJailResult.Create(
  ACanMove: boolean;
  const ARoll: TDiceRoll;
  AHasRoll: boolean;
  AUsedJailRoll: boolean
  ): TJailResult;
begin
  Result.CanMove := ACanMove;
  Result.Roll := ARoll;
  Result.HasRoll := AHasRoll;
  Result.UsedJailRoll := AUsedJailRoll;
end;

end.
