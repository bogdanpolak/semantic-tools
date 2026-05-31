unit Monopoly.RentHandlers;

interface

uses
  Monopoly.Types;

type
  IRentHandler = interface
    ['{43F0A0B0-C0D3-4CC7-8A4A-6C95B1C5F1D0}']
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      );
  end;

function CreateRentHandlers: TArray<IRentHandler>;

implementation

uses
  System.SysUtils,
  Monopoly.Utils;

const
  RAILROAD_RENT: array[0..3] of integer = (25, 50, 100, 200);

type
  TBaseRentHandler = class(TInterfacedObject, IRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; virtual; abstract;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); virtual; abstract;
  end;

  TDoubledRailroadRentHandler = class(TBaseRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; override;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); override;
  end;

  TTenTimesUtilityRentHandler = class(TBaseRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; override;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); override;
  end;

  TRailroadRentHandler = class(TBaseRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; override;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); override;
  end;

  TUtilityRentHandler = class(TBaseRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; override;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); override;
  end;

  TPropertyRentHandler = class(TBaseRentHandler)
  public
    function CanHandle(
      Tile: TTile;
      const Options: TRentOptions
      ): boolean; override;
    procedure Handle(
      Game: TGame;
      Tile: TTile
      ); override;
  end;

function CheckIfHasMonopoly(
  Game: TGame;
  Tile: TTile;
  Owner: TPlayer
  ): boolean;
var
  OwnedTilesOfColor: integer;
  Candidate: TTile;
begin
  OwnedTilesOfColor := 0;
  for Candidate in Game.Board do
  begin
    if (Candidate.Color = Tile.Color) and Candidate.IsOwnedBy(Owner) then
    begin
      Inc(OwnedTilesOfColor);
    end;
  end;

  if (Tile.Color = 'dark-purple') or (Tile.Color = 'dark-blue') then
  begin
    Exit(OwnedTilesOfColor = 2);
  end;

  Result := OwnedTilesOfColor = 3;
end;

function ResolveRailroadRent(
  Game: TGame;
  Owner: TPlayer
  ): integer;
var
  RailroadsOwned: integer;
begin
  RailroadsOwned := Game.CountOwnedTilesOfType(Owner, ttRailroad);
  if (RailroadsOwned < 1) or (RailroadsOwned > 4) then
  begin
    raise Exception.CreateFmt(
      'Incorrect number of railroads owned by %s. Current: %d',
      [Game.CurrentPlayer.Name, RailroadsOwned]
    );
  end;

  Result := RAILROAD_RENT[RailroadsOwned - 1];
end;

function TDoubledRailroadRentHandler.CanHandle(
  Tile: TTile;
  const Options: TRentOptions
  ): boolean;
begin
  Result := (Tile.TileType = ttRailroad) and Options.IsRailroadRent2x;
end;

procedure TDoubledRailroadRentHandler.Handle(
  Game: TGame;
  Tile: TTile
  );
var
  Player: TPlayer;
  Owner: TPlayer;
  Rent: integer;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Owner := Game.GetTileOwner(Tile);
  Rent := ResolveRailroadRent(Game, Owner) * 2;
  AmountPaid := TransferMoney(Player, Owner, Rent, Game.Board, Game.OnLog);
  Game.Log(Format('%s pays %s $%d (doubled railroad rent).', [Player.Name, Owner.Name, AmountPaid]));
end;

function TTenTimesUtilityRentHandler.CanHandle(
  Tile: TTile;
  const Options: TRentOptions
  ): boolean;
begin
  Result := (Tile.TileType = ttUtility) and Options.IsUtilityRent10x;
end;

procedure TTenTimesUtilityRentHandler.Handle(
  Game: TGame;
  Tile: TTile
  );
var
  Player: TPlayer;
  Owner: TPlayer;
  Rent: integer;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Owner := Game.GetTileOwner(Tile);
  if not Game.HasLastRoll then
  begin
    Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
    Exit;
  end;

  Rent := Game.LastRoll.Total * 10;
  AmountPaid := TransferMoney(Player, Owner, Rent, Game.Board, Game.OnLog);
  Game.Log(Format('%s pays %s $%d (10x dice roll).', [Player.Name, Owner.Name, AmountPaid]));
end;

function TRailroadRentHandler.CanHandle(
  Tile: TTile;
  const Options: TRentOptions
  ): boolean;
begin
  Result := Tile.TileType = ttRailroad;
end;

procedure TRailroadRentHandler.Handle(
  Game: TGame;
  Tile: TTile
  );
var
  Player: TPlayer;
  Owner: TPlayer;
  RailroadsOwned: integer;
  Rent: integer;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Owner := Game.GetTileOwner(Tile);
  RailroadsOwned := Game.CountOwnedTilesOfType(Owner, ttRailroad);
  Rent := ResolveRailroadRent(Game, Owner);
  AmountPaid := TransferMoney(Player, Owner, Rent, Game.Board, Game.OnLog);
  Game.Log(
    Format(
      '%s pays %s $%d for landing on %s (%d railroad(s) owned).',
      [Player.Name, Owner.Name, AmountPaid, Tile.Name, RailroadsOwned]
    )
  );
end;

function TUtilityRentHandler.CanHandle(
  Tile: TTile;
  const Options: TRentOptions
  ): boolean;
begin
  Result := Tile.TileType = ttUtility;
end;

procedure TUtilityRentHandler.Handle(
  Game: TGame;
  Tile: TTile
  );
var
  Player: TPlayer;
  Owner: TPlayer;
  UtilitiesOwned: integer;
  Rent: integer;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Owner := Game.GetTileOwner(Tile);
  if not Game.HasLastRoll then
  begin
    Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
    Exit;
  end;

  UtilitiesOwned := Game.CountOwnedTilesOfType(Owner, ttUtility);
  if UtilitiesOwned = 2 then
  begin
    Rent := Game.LastRoll.Total * 10;
  end
  else
  begin
    Rent := Game.LastRoll.Total * 4;
  end;

  AmountPaid := TransferMoney(Player, Owner, Rent, Game.Board, Game.OnLog);
  Game.Log(
    Format(
      '%s pays %s $%d for landing on %s (%d utility/utilities owned).',
      [Player.Name, Owner.Name, AmountPaid, Tile.Name, UtilitiesOwned]
    )
  );
end;

function TPropertyRentHandler.CanHandle(
  Tile: TTile;
  const Options: TRentOptions
  ): boolean;
begin
  Result := Tile.TileType = ttProperty;
end;

procedure TPropertyRentHandler.Handle(
  Game: TGame;
  Tile: TTile
  );
var
  Player: TPlayer;
  Owner: TPlayer;
  Rent: integer;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Owner := Game.GetTileOwner(Tile);
  Rent := Tile.Rent;

  if CheckIfHasMonopoly(Game, Tile, Owner) and (Tile.Houses = 0) and not Tile.HasHotel then
  begin
    Rent := Rent * 2;
  end;

  AmountPaid := TransferMoney(Player, Owner, Rent, Game.Board, Game.OnLog);
  Game.Log(Format('%s pays $%d rent to %s', [Player.Name, AmountPaid, Owner.Name]));
end;

function CreateRentHandlers: TArray<IRentHandler>;
begin
  Result := [
    TDoubledRailroadRentHandler.Create,
    TTenTimesUtilityRentHandler.Create,
    TRailroadRentHandler.Create,
    TUtilityRentHandler.Create,
    TPropertyRentHandler.Create
  ];
end;

end.