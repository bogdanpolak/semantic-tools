unit Monopoly.Rules.Decisions;

interface

uses
  System.Generics.Collections,
  Monopoly.Types;

type
  IPlayerDecisionService = interface
    ['{C7A3F7B3-6B1C-4B3F-B9D3-37B9A2A0C8E7}']
    function CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
    function CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
    function HasBudgetToBuild(Tile: TTile; const Owner: TPlayer): boolean;
    function CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
  end;

function CreatePlayerDecisionService(Game: TGame): IPlayerDecisionService;

implementation

uses
  System.SysUtils;

const MIN_MONEY_TO_BUILD = 500;

type
  TPlayerDecisionService = class(TInterfacedObject, IPlayerDecisionService)
  private
    FGame: TGame;
  public
    constructor Create(Game: TGame);
    function CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
    function CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
    function HasBudgetToBuild(Tile: TTile; const Owner: TPlayer): boolean;
    function CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
  end;

function CreatePlayerDecisionService(Game: TGame): IPlayerDecisionService;
begin
  Result := TPlayerDecisionService.Create(Game);
end;

constructor TPlayerDecisionService.Create(Game: TGame);
begin
  inherited Create;
  if Game = nil then
  begin
    raise Exception.Create('Game must be assigned.');
  end;

  FGame := Game;
end;

function TPlayerDecisionService.HasBudgetToBuild(Tile: TTile;
  const Owner: TPlayer): boolean;
begin
  var HouseCost := Tile.HouseCost();
  Result :=
    (Owner.Money - HouseCost  >= MIN_MONEY_TO_BUILD);
end;

function TPlayerDecisionService.CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
begin
  Result :=
    (Tile <> nil) and
    (Owner <> nil) and
    (Tile.TileType = ttProperty) and
    Tile.IsOwnedBy(Owner) and
    not Tile.Mortgaged and
    not Tile.HasHotel and
    (Tile.Houses = 4) and
    FGame.Board.IsColorGroupFullyBuilt(Tile, Owner);
end;

function TPlayerDecisionService.CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
begin
  Result :=
    (Tile <> nil) and
    (Owner <> nil) and
    (Tile.TileType = ttProperty) and
    Tile.IsOwnedBy(Owner) and
    not Tile.Mortgaged and
    not Tile.HasHotel and
    (Tile.Houses < 4) and
    FGame.Board.HasPropertyMonopoly(Tile, Owner) and
    (Tile.Houses = FGame.Board.LowestHouseCountInColorGroup(Tile, Owner));
end;

function TPlayerDecisionService.CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
begin
  Result :=
    (Tile <> nil) and
    (Owner <> nil) and
    Tile.IsOwnable and
    Tile.IsOwnedBy(Owner) and
    not Tile.Mortgaged;

  if not Result then
  begin
    Exit;
  end;

  if (Tile.TileType = ttProperty) then
  begin
    Result := not FGame.Board.HasBuildingsInColorGroup(Tile, Owner);
  end;
end;

function TPlayerDecisionService.CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
begin
  Result := (Tile <> nil) and (Owner <> nil) and Tile.IsOwnedBy(Owner) and Tile.Mortgaged;
end;

end.
