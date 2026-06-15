unit Monopoly.Rules.Build;

interface

uses
  Monopoly.Types;

type
  TBuildHouseResult = (
    bhrBuilt,
    bhrMoneyToLow,
    bhrCannotBuild,
    bhrCannotAfford,
    bhrNothingToBuild
    );

function TryBuildHouse(
  const AGame: TGame;
  out AAmountPaid: integer;
  out AMessage: string
  ): TBuildHouseResult;

implementation

uses
  System.SysUtils,
  Monopoly.Rules.Decisions;

function TryBuildHouseOnTile(
  const AGame: TGame;
  const ATile: TTile;
  out AAmountPaid: integer;
  out AMessage: string
  ): TBuildHouseResult;
var
  Player: TPlayer;
  PlayerDecisionService: IPlayerDecisionService;
begin
  AAmountPaid := 0;
  AMessage := '';

  if AGame = nil then
    raise Exception.Create('Game must be assigned.');

  if ATile = nil then
    raise Exception.Create('Tile must be assigned.');

  Player := AGame.CurrentPlayer;
  if Player = nil then
    raise Exception.Create('Player must be assigned.');

  var HouseCost := ATile.HouseCost;
  
  if not Player.CanAfford(HouseCost) then
  begin
    Result := bhrCannotAfford;
    AMessage := Format(
      '%s does not have enough money to build a house on %s.', 
      [Player.Name, ATile.Name]);
    AAmountPaid := 0;
    Exit;
  end;

  PlayerDecisionService := CreatePlayerDecisionService(AGame);
  if not PlayerDecisionService.CanBuildHouse(ATile, Player) then
  begin
    Result := bhrCannotBuild;
    AMessage := Format('%s cannot build a house on %s.', [Player.Name, ATile.Name]);
    Exit;
  end;

  if not PlayerDecisionService.HasBudgetToBuild(ATile, Player) then
  begin
    Result := bhrMoneyToLow;
    AMessage := Format(
      '%s can build on %s, but needs more money as a reserve.', 
      [Player.Name, ATile.Name]);
    Exit;
  end;

  AAmountPaid := HouseCost;
  AGame.PayBank(Player, AAmountPaid);
  Inc(ATile.Houses);
  AMessage := Format(
    '%s bought a house on %s for $%d.', 
    [Player.Name, ATile.Name, AAmountPaid]);
  Result := bhrBuilt;
end;

function TryBuildHouse(
  const AGame: TGame;
  out AAmountPaid: integer;
  out AMessage: string
  ): TBuildHouseResult;
var
  Player: TPlayer;
  PropertyId: integer;
  Tile: TTile;
  BuildResult: TBuildHouseResult;
begin
  if AGame = nil then
    raise Exception.Create('Game must be assigned.');

  Player := AGame.CurrentPlayer;
  if Player = nil then
    raise Exception.Create('Player must be assigned.');

  for PropertyId in Player.PropertyIds do
  begin
    Tile := AGame.Board.TileById(PropertyId);
    if Tile.TileType = ttProperty then
    begin
      BuildResult := TryBuildHouseOnTile(AGame, Tile, AAmountPaid, AMessage);
      if (BuildResult = bhrBuilt) or
         (BuildResult = bhrMoneyToLow) or
         (BuildResult = bhrCannotAfford) then
        Exit(BuildResult);
    end;
  end;

  Result := bhrNothingToBuild;
end;

end.
