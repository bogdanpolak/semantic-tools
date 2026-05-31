unit Helpers.Monopoly;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Monopoly.Types;

type
  TGameHelper = class helper for TGame
    procedure AddPlayers(const PlayerNames: array of string);
    procedure FixedDiceRolls(const Rolls: array of TDiceRoll);
    procedure SetDecks(
      const ChanceCards: array of TMonopolyCard;
      const CommunityChestCards: array of TMonopolyCard
      );
    class function CreateTest(): TGame; static;
  end;
type
  TPlayerHelper = class helper for TPlayer
    procedure AddProperites(
      Board: TObjectList<TTile>;
      const PropertyIds: array of Integer
    );
  end;

implementation

uses
  Monopoly.Factories;

{ FixedDiceRoller }

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

{ TGameHelper }

procedure TGameHelper.AddPlayers(const PlayerNames: array of string);
begin
  self.Players := CreatePlayers(PlayerNames);
  if self.Players.Count > 0 then
  begin
    self.CurrentPlayerId := self.Players[0].Id;
  end;
end;

procedure TGameHelper.SetDecks(
  const ChanceCards: array of TMonopolyCard;
  const CommunityChestCards: array of TMonopolyCard
  );
begin
  if Assigned(self.Decks) then
  begin
    FreeAndNil(self.Decks);
  end;

  self.Decks := TDeckPair.Create(
    TDeck.Create(ChanceCards),
    TDeck.Create(CommunityChestCards)
    );
end;

class function TGameHelper.CreateTest: TGame;
begin
  Result := TGame.Create(
    CreatePlayers([]),
    CreateBoard,
    CreateDecks()
  );
end;

procedure TGameHelper.FixedDiceRolls(const Rolls: array of TDiceRoll);
begin
  self.FDiceRoller := CreateFixedDiceRoller(Rolls);
end;

{ TPlayerHelper }

procedure TPlayerHelper.AddProperites(
  Board: TObjectList<TTile>;
  const PropertyIds: array of Integer
  );
var
  PropertyId: integer;
  Tile: TTile;
  Candidate: TTile;
begin
  self.PropertyIds.Clear;

  for Candidate in Board do
  begin
    if Candidate.OwnerId = self.Id then
    begin
      Candidate.OwnerId := NO_OWNER_ID;
    end;
  end;

  for PropertyId in PropertyIds do
  begin
    Tile := nil;
    for Candidate in Board do
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

    Tile.OwnerId := self.Id;
    self.PropertyIds.Add(PropertyId);
  end;
end;

end.
