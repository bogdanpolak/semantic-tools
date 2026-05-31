unit Monopoly.Rules.Rent;

interface

uses
  System.SysUtils,
  Monopoly.Types;

procedure HandlePayRent(
  Game: TGame;
  const Options: TRentOptions
  );

implementation

uses
  Monopoly.RentHandlers;

procedure HandlePayRent(
  Game: TGame;
  const Options: TRentOptions
  );
var
  Tile: TTile;
  Handler: IRentHandler;
begin
  Tile := Game.GetPlayerTile(Game.CurrentPlayer);

  for Handler in CreateRentHandlers do
  begin
    if Handler.CanHandle(Tile, Options) then
    begin
      Handler.Handle(Game, Tile);
      Exit;
    end;
  end;

  raise Exception.CreateFmt(
    'No rent strategy found for tile type "%s".',
    [TileTypeToText(Tile.TileType)]
  );
end;

end.
