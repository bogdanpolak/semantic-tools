unit Monopoly.BuildActions;

interface

uses
  Monopoly.Types;

type
  TBuildHouseResult = (
    bhrBuilt,
    bhrCannotBuild,
    bhrCannotAfford
    );

function TryBuildHouse(
  Game: TGame;
  Tile: TTile;
  out AmountPaid: integer;
  out Message: string
  ): TBuildHouseResult;
function TryBuildFirstEligibleHouse(
  Game: TGame;
  out AmountPaid: integer;
  out Message: string
  ): boolean;

implementation

uses
  System.SysUtils,
  Monopoly.PropertyDevelopment;

function TryBuildHouse(
  Game: TGame;
  Tile: TTile;
  out AmountPaid: integer;
  out Message: string
  ): TBuildHouseResult;
var
  Player: TPlayer;
  PropertyDevelopmentService: IPropertyDevelopmentService;
begin
  if Game = nil then
  begin
    raise Exception.Create('Game must be assigned.');
  end;

  AmountPaid := 0;
  Message := '';
  Player := Game.CurrentPlayer;
  if Player = nil then
  begin
    Result := bhrCannotBuild;
    Message := 'Cannot build a house without a current player.';
    Exit;
  end;

  PropertyDevelopmentService := CreatePropertyDevelopmentService(Game);
  if not PropertyDevelopmentService.CanBuildHouse(Tile, Player) then
  begin
    Result := bhrCannotBuild;
    if Tile = nil then
    begin
      Message := Format('%s cannot build a house without a target tile.', [Player.Name]);
    end
    else
    begin
      Message := Format('%s cannot build a house on %s.', [Player.Name, Tile.Name]);
    end;

    Exit;
  end;

  AmountPaid := PropertyDevelopmentService.HouseCost(Tile);
  if not Player.CanAfford(AmountPaid) then
  begin
    Result := bhrCannotAfford;
    Message := Format('%s does not have enough money to build a house on %s.', [Player.Name, Tile.Name]);
    AmountPaid := 0;
    Exit;
  end;

  Game.PayBank(Player, AmountPaid);
  PropertyDevelopmentService.BuildHouse(Tile, Player);
  Message := Format('%s bought a house on %s for $%d.', [Player.Name, Tile.Name, AmountPaid]);
  Result := bhrBuilt;
end;

function TryBuildFirstEligibleHouse(
  Game: TGame;
  out AmountPaid: integer;
  out Message: string
  ): boolean;
var
  Player: TPlayer;
  PropertyId: integer;
  Tile: TTile;
  PropertyDevelopmentService: IPropertyDevelopmentService;
begin
  if Game = nil then
  begin
    raise Exception.Create('Game must be assigned.');
  end;

  AmountPaid := 0;
  Message := '';
  Player := Game.CurrentPlayer;
  if Player = nil then
  begin
    Exit(False);
  end;

  PropertyDevelopmentService := CreatePropertyDevelopmentService(Game);
  for PropertyId in Player.PropertyIds do
  begin
    Tile := Game.Board.TileById(PropertyId);
    if PropertyDevelopmentService.CanBuildHouse(Tile, Player) and Player.CanAfford(PropertyDevelopmentService.HouseCost(Tile)) then
    begin
      Result := TryBuildHouse(Game, Tile, AmountPaid, Message) = bhrBuilt;
      Exit;
    end;
  end;

  Result := False;
end;

end.