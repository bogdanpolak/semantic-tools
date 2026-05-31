unit Monopoly.GameLoop;

interface

uses
  Monopoly.Types;

const
  MAX_ROUNDS = 40;

procedure MovePlayer(
  Game: TGame;
  Steps: integer
  );
procedure PlayTurn(
  Game: TGame
  );
procedure PlayGame(
  Game: TGame
  );

implementation

uses
  System.SysUtils,
  Monopoly.Rules.Jail,
  Monopoly.Rules.Landing;

procedure MovePlayer(
  Game: TGame;
  Steps: integer
  );
var
  Player: TPlayer;
  PassStart: boolean;
  CurrentSquare: TTile;
begin
  Player := Game.CurrentPlayer;
  PassStart := Game.MovePlayerBy(Player, Steps);

  CurrentSquare := Game.Board[Player.Position];
  Game.Log(Format('%s moves to %s', [Player.Name, CurrentSquare.Name]));
  if PassStart then
  begin
    Game.AdjustPlayerMoney(Player, 200);
    Game.Log(Format('%s passes Start and collects $200', [Player.Name]));
  end;
end;

procedure PlayGame(
  Game: TGame
  );
var
  RoundNumber: integer;
  ActivePlayerCount: integer;
  PreviousPlayerId: integer;
  Player: TPlayer;
begin
  if Game = nil then
  begin
    raise Exception.Create('Uninitialized game object.');
  end;

  RoundNumber := 1;
  ActivePlayerCount := Game.CountActivePlayers;

  while ActivePlayerCount > 1 do
  begin
    PreviousPlayerId := Game.CurrentPlayerId;
    Player := Game.NextActivePlayer;
    if (Player = nil) or Player.IsBankrupt then
    begin
      Continue;
    end;

    if (PreviousPlayerId <> 0) and (Game.CurrentPlayerId < PreviousPlayerId) then
    begin
      Inc(RoundNumber);
    end;

    if RoundNumber > MAX_ROUNDS then
    begin
      Game.Log(Format('Reached maximum number of rounds: %d. Ending game.', [MAX_ROUNDS]));
      Break;
    end;

    PlayTurn(Game);
    ActivePlayerCount := Game.CountActivePlayers;
  end;
end;

procedure PlayTurn(
  Game: TGame
  );
var
  DoublesCount: integer;
  HasDouble: boolean;
  Player: TPlayer;
  JailResult: TJailResult;
  Roll: TDiceRoll;
begin
  DoublesCount := 0;
  HasDouble := True;
  while HasDouble and (DoublesCount < 3) do
  begin
    Player := Game.CurrentPlayer;
    if (Player = nil) or Player.IsBankrupt then
    begin
      Exit;
    end;

    JailResult := JailRules(Game);
    if not JailResult.CanMove then
    begin
      Exit;
    end;

    if JailResult.HasRoll then
    begin
      Roll := JailResult.Roll;
    end
    else
    begin
      Roll := Game.RollDice;
    end;

    Game.LastRoll := Roll;
    Game.HasLastRoll := True;
    HasDouble := Roll.IsDouble and not JailResult.UsedJailRoll;
    if HasDouble then
    begin
      Inc(DoublesCount);
    end;

    if DoublesCount = 3 then
    begin
      Game.Log(Format('%s rolled doubles three times in a row and goes to jail!', [Player.Name]));
      SendCurrentPlayerToJail(Game);
      Exit;
    end;

    MovePlayer(Game, Roll.Total);
    LandingRules(Game, TRentOptions.None);

    if Player.IsBankrupt or Player.IsInJail then
    begin
      Exit;
    end;

    if HasDouble then
    begin
      Game.Log(Format('%s rolled doubles: %d & %d and gets another turn!', [Player.Name, Roll.Dice1, Roll.Dice2]));
    end;
  end;
end;

end.
