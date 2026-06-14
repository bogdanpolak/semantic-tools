unit Monopoly.Rules.Rent;

interface

uses
  Monopoly.Transactions,
  Monopoly.Types;

procedure HandlePayRent(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  );

implementation

uses
  System.SysUtils;

const
  RAILROAD_RENT: array[0..3] of integer = (25, 50, 100, 200);

function ResolveRailroadRent(Game: TGame; Owner: TPlayer): integer;
var
  RailroadsOwned: integer;
begin
  RailroadsOwned := Game.Board.CountOwnedTilesOfType(Owner, ttRailroad);
  if (RailroadsOwned < 1) or (RailroadsOwned > 4) then
  begin
    raise Exception.CreateFmt(
      'Incorrect number of railroads owned by %s. Current: %d',
      [Game.CurrentPlayer.Name, RailroadsOwned]
    );
  end;

  Result := RAILROAD_RENT[RailroadsOwned - 1];
end;

procedure HandlePayRent(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  );
var
  CurrentPlayer: TPlayer;
  Owner: TPlayer;
  Tile: TTile;
  RailroadsOwned: integer;
  UtilitiesOwned: integer;
  Rent: integer;
  AmountPaid: integer;
begin
  CurrentPlayer := Game.CurrentPlayer;
  Tile := Game.Board.TileAtPlayerPosition(CurrentPlayer);

  if (Tile.TileType = ttRailroad) and Options.IsRailroadRent2x then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    Rent := ResolveRailroadRent(Game, Owner) * 2;
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays %s $%d (doubled railroad rent).', [CurrentPlayer.Name, Owner.Name, AmountPaid]));
    Exit;
  end;

  if (Tile.TileType = ttUtility) and Options.IsUtilityRent10x then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    if not Game.HasLastRoll then
    begin
      Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
      Exit;
    end;

    Rent := Game.LastRoll.Total * 10;
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays %s $%d (10x dice roll).', [CurrentPlayer.Name, Owner.Name, AmountPaid]));
    Exit;
  end;

  if Tile.TileType = ttRailroad then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    RailroadsOwned := Game.Board.CountOwnedTilesOfType(Owner, ttRailroad);
    Rent := ResolveRailroadRent(Game, Owner);
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(
      Format(
        '%s pays %s $%d for landing on %s (%d railroad(s) owned).',
        [CurrentPlayer.Name, Owner.Name, AmountPaid, Tile.Name, RailroadsOwned]
      )
    );
    Exit;
  end;

  if Tile.TileType = ttUtility then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    if not Game.HasLastRoll then
    begin
      Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
      Exit;
    end;

    UtilitiesOwned := Game.Board.CountOwnedTilesOfType(Owner, ttUtility);
    if UtilitiesOwned = 2 then
    begin
      Rent := Game.LastRoll.Total * 10;
    end
    else
    begin
      Rent := Game.LastRoll.Total * 4;
    end;

    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(
      Format(
        '%s pays %s $%d for landing on %s (%d utility/utilities owned).',
        [CurrentPlayer.Name, Owner.Name, AmountPaid, Tile.Name, UtilitiesOwned]
      )
    );
    Exit;
  end;

  if Tile.TileType = ttProperty then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    Rent := Tile.Rent;

    if Game.Board.HasPropertyMonopoly(Tile, Owner) and (Tile.Houses = 0) and not Tile.HasHotel then
    begin
      Rent := Rent * 2;
    end;

    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays $%d rent to %s', [CurrentPlayer.Name, AmountPaid, Owner.Name]));
    Exit;
  end;

  raise Exception.CreateFmt(
    'No rent strategy found for tile type "%s".',
    [TileTypeToText(Tile.TileType)]
  );
end;

end.
