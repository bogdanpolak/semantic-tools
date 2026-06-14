unit Monopoly.PropertyDevelopment;

interface

uses
  System.Generics.Collections,
  Monopoly.Types;

type
  TPropertyRepairKind = (
    prkPropertyRepairs,
    prkStreetRepairs
    );

  IPropertyDevelopmentService = interface
    ['{C7A3F7B3-6B1C-4B3F-B9D3-37B9A2A0C8E7}']
    function CalculateRepairCost(
      const Player: TPlayer;
      RepairKind: TPropertyRepairKind
      ): integer;
    function BuildHouse(Tile: TTile; const Owner: TPlayer): integer;
    function CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
    function CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
    function CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function IsMortgaged(Tile: TTile): boolean;
    function HouseCost(Tile: TTile): integer;
    function Mortgage(Tile: TTile; const Owner: TPlayer): integer;
    function MortgageValue(Tile: TTile): integer;
    function Unmortgage(Tile: TTile; const Owner: TPlayer): integer;
    function UnmortgageCost(Tile: TTile): integer;
  end;

function CreatePropertyDevelopmentService(Game: TGame): IPropertyDevelopmentService;

implementation

uses
  System.SysUtils;

type
  TPropertyDevelopmentService = class(TInterfacedObject, IPropertyDevelopmentService)
  private
    FGame: TGame;
  public
    constructor Create(Game: TGame);
    function CalculateRepairCost(
      const Player: TPlayer;
      RepairKind: TPropertyRepairKind
      ): integer;
    function BuildHouse(Tile: TTile; const Owner: TPlayer): integer;
    function CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
    function CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
    function CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
    function IsMortgaged(Tile: TTile): boolean;
    function HouseCost(Tile: TTile): integer;
    function Mortgage(Tile: TTile; const Owner: TPlayer): integer;
    function MortgageValue(Tile: TTile): integer;
    function Unmortgage(Tile: TTile; const Owner: TPlayer): integer;
    function UnmortgageCost(Tile: TTile): integer;
  end;

function CreatePropertyDevelopmentService(Game: TGame): IPropertyDevelopmentService;
begin
  Result := TPropertyDevelopmentService.Create(Game);
end;

constructor TPropertyDevelopmentService.Create(Game: TGame);
begin
  inherited Create;
  if Game = nil then
  begin
    raise Exception.Create('Game must be assigned.');
  end;

  FGame := Game;
end;

function TPropertyDevelopmentService.CalculateRepairCost(
  const Player: TPlayer;
  RepairKind: TPropertyRepairKind
  ): integer;
var
  PerHouse: integer;
  PerHotel: integer;
begin
  if Player = nil then
  begin
    raise Exception.Create('Player must be assigned.');
  end;

  case RepairKind of
    prkPropertyRepairs:
      begin
        PerHouse := 25;
        PerHotel := 100;
      end;
    prkStreetRepairs:
      begin
        PerHouse := 40;
        PerHotel := 115;
      end;
  else
    raise Exception.Create('Unsupported repair kind.');
  end;

  Result :=
    (FGame.Board.CountHousesOwnedBy(Player) * PerHouse) +
    (FGame.Board.CountHotelsOwnedBy(Player) * PerHotel);
end;

function TPropertyDevelopmentService.BuildHouse(
  Tile: TTile;
  const Owner: TPlayer
  ): integer;
begin
  if not CanBuildHouse(Tile, Owner) then
  begin
    if Tile = nil then
    begin
      raise Exception.Create('Cannot build a house on a nil tile.');
    end;

    raise Exception.CreateFmt('Cannot build a house on %s.', [Tile.Name]);
  end;

  Result := HouseCost(Tile);
  Inc(Tile.Houses);
end;

function TPropertyDevelopmentService.CanBuildHotel(Tile: TTile; const Owner: TPlayer): boolean;
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

function TPropertyDevelopmentService.CanBuildHouse(Tile: TTile; const Owner: TPlayer): boolean;
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

function TPropertyDevelopmentService.CanMortgage(Tile: TTile; const Owner: TPlayer): boolean;
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

function TPropertyDevelopmentService.CanUnmortgage(Tile: TTile; const Owner: TPlayer): boolean;
begin
  Result := (Tile <> nil) and (Owner <> nil) and Tile.IsOwnedBy(Owner) and Tile.Mortgaged;
end;

function TPropertyDevelopmentService.IsMortgaged(Tile: TTile): boolean;
begin
  Result := (Tile <> nil) and Tile.Mortgaged;
end;

function TPropertyDevelopmentService.HouseCost(Tile: TTile): integer;
begin
  if Tile = nil then
  begin
    Exit(0);
  end;

  if SameText(Tile.Color, 'dark-purple') or SameText(Tile.Color, 'light-blue') then
  begin
    Exit(50);
  end;

  if SameText(Tile.Color, 'purple') or SameText(Tile.Color, 'orange') then
  begin
    Exit(100);
  end;

  if SameText(Tile.Color, 'red') or SameText(Tile.Color, 'yellow') then
  begin
    Exit(150);
  end;

  if SameText(Tile.Color, 'green') or SameText(Tile.Color, 'dark-blue') then
  begin
    Exit(200);
  end;

  raise Exception.CreateFmt('Unsupported house cost for tile color %s.', [Tile.Color]);
end;

function TPropertyDevelopmentService.Mortgage(Tile: TTile; const Owner: TPlayer): integer;
var
  TileName: string;
begin
  if not CanMortgage(Tile, Owner) then
  begin
    if Tile = nil then
    begin
      TileName := '<nil>';
    end
    else
    begin
      TileName := Tile.Name;
    end;

    raise Exception.CreateFmt('Cannot mortgage %s.', [TileName]);
  end;

  Result := MortgageValue(Tile);
  Tile.Mortgaged := True;
end;

function TPropertyDevelopmentService.MortgageValue(Tile: TTile): integer;
begin
  if (Tile = nil) or not Tile.IsOwnable then
  begin
    Exit(0);
  end;

  Result := Tile.Price div 2;
end;

function TPropertyDevelopmentService.Unmortgage(Tile: TTile; const Owner: TPlayer): integer;
var
  TileName: string;
begin
  if not CanUnmortgage(Tile, Owner) then
  begin
    if Tile = nil then
    begin
      TileName := '<nil>';
    end
    else
    begin
      TileName := Tile.Name;
    end;

    raise Exception.CreateFmt('Cannot unmortgage %s.', [TileName]);
  end;

  Result := UnmortgageCost(Tile);
  Tile.Mortgaged := False;
end;

function TPropertyDevelopmentService.UnmortgageCost(Tile: TTile): integer;
begin
  Result := (MortgageValue(Tile) * 11 + 9) div 10;
end;

end.