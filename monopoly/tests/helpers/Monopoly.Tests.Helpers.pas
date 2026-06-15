unit Monopoly.Tests.Helpers;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Monopoly.CompositionRoot,
  Monopoly.Types,
  Monopoly.Transactions;

const
  MAX_ROUNDS = 5;

type
  TPlayerHelper = class helper for TPlayer
    procedure AddProperites(
      Board: TBoard;
      const PropertyIds: array of Integer
    );
  end;

function CreateTransactions :ITransactionService;
function CreateMonopolyServices : IMonopolyServices;
function CreateFixedDiceRoller(
  const Rolls: array of TDiceRoll
  ): TDiceRoller;

implementation

uses
  Monopoly.Factories;

function CreateTransactions :ITransactionService;
begin
  Result := TTransactionService.Create;
end;

function CreateMonopolyServices : IMonopolyServices;
begin
  Result := CreateMonopolyServices;
end;


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

{ TPlayerHelper }

procedure TPlayerHelper.AddProperites(
  Board: TBoard;
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
