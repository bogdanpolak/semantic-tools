unit -;

interface

uses
  Monopoly.Types;

function CreateTestGame(
  const PlayerNames: array of string;
  ADiceRoller: TDiceRoller = nil;
  ARandomIndex: TRandomIndexFunc = nil
  ): TGame;
function CreateFixedDiceRoller(
  const Rolls: array of TDiceRoll
  ): TDiceRoller;
procedure SetCurrentPlayer(
  Game: TGame;
  PlayerIndex: integer
  );
procedure SetPlayerPosition(
  Game: TGame;
  PlayerIndex: integer;
  Position: integer
  );
procedure SetPlayerMoney(
  Game: TGame;
  PlayerIndex: integer;
  Money: integer
  );
procedure AssignPlayerProperties(
  Game: TGame;
  PlayerIndex: integer;
  const PropertyIds: array of Integer
  );
procedure SetMockDecks(
  Game: TGame;
  const ChanceCards: array of TMonopolyCard;
  const CommunityChestCards: array of TMonopolyCard
  );

implementation

uses
  System.SysUtils,
  Monopoly.Factories;

function CreateFixedDiceRoller(
  const Rolls: array of TDiceRoll
  ): TDiceRoller;
var
  Index, I: integer;
  aRolls: TArray<TDiceRoll>;
begin
  SetLength(aRolls, Length(Rolls));

  for I := 0 to High(Rolls) do
    aRolls[I] := Rolls[I];

  if Length(aRolls) = 0 then
    raise Exception.Create('CreateFixedDiceRoller requires at least one roll.');

  Index := 0;

  Result :=
    function: TDiceRoll
    begin
      if Index >= Length(aRolls) then
        Exit(aRolls[High(aRolls)]);

      Result := aRolls[Index];
      Inc(Index);
    end;
end;

function CreateTestGame(
  const PlayerNames: array of string;
  ADiceRoller: TDiceRoller = nil;
  ARandomIndex: TRandomIndexFunc = nil
  ): TGame;
begin
  Result := TGame.Create(
    CreatePlayers(PlayerNames),
    CreateBoard,
    CreateDecks(ARandomIndex),
    ADiceRoller
  );
  if Result.Players.Count > 0 then
  begin
    Result.CurrentPlayerId := Result.Players[0].Id;
  end;
end;

procedure AssignPlayerProperties(
  Game: TGame;
  PlayerIndex: integer;
  const PropertyIds: array of Integer
  );
var
  PropertyId: integer;
  Player: TPlayer;
  Tile: TTile;
  Candidate: TTile;
begin
  Player := Game.Players[PlayerIndex];
  Player.PropertyIds.Clear;

  for Candidate in Game.Board do
  begin
    if Candidate.OwnerId = Player.Id then
    begin
      Candidate.OwnerId := NO_OWNER_ID;
    end;
  end;

  for PropertyId in PropertyIds do
  begin
    Tile := nil;
    for Candidate in Game.Board do
    begin
      if Candidate.Id = PropertyId then
      begin
        Tile := Candidate;
        Break;
      end;
    end;

    if Tile = nil then
    begin
      raise Exception.CreateFmt('Unknown property id: %d', [PropertyId]);
    end;

    if not Tile.IsOwnable then
    begin
      raise Exception.CreateFmt('Tile %d is not ownable.', [PropertyId]);
    end;

    if Tile.OwnerId <> NO_OWNER_ID then
    begin
      raise Exception.CreateFmt('Duplicate property id assignment: %d',
        [PropertyId]);
    end;

    Tile.OwnerId := Player.Id;
    Player.PropertyIds.Add(PropertyId);
  end;
end;

procedure SetCurrentPlayer(
  Game: TGame;
  PlayerIndex: integer
  );
begin
  Game.CurrentPlayerId := Game.Players[PlayerIndex].Id;
end;

procedure SetMockDecks(
  Game: TGame;
  const ChanceCards: array of TMonopolyCard;
  const CommunityChestCards: array of TMonopolyCard
  );
begin
  Game.Decks.Free;
  Game.Decks := TDeckPair.Create(
    TDeck.Create(ChanceCards),
    TDeck.Create(CommunityChestCards)
    );
end;

procedure SetPlayerMoney(
  Game: TGame;
  PlayerIndex: integer;
  Money: integer
  );
begin
  Game.Players[PlayerIndex].Money := Money;
end;

procedure SetPlayerPosition(
  Game: TGame;
  PlayerIndex: integer;
  Position: integer
  );
begin
  Game.Players[PlayerIndex].Position := Position;
end;

end.

