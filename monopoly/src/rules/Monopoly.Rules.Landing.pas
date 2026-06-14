unit Monopoly.Rules.Landing;

interface

uses
  System.SysUtils,
  Monopoly.Transactions,
  Monopoly.Types;

procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService
  ); overload;
procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService;
  const Options: TRentOptions
  ); overload;

implementation

uses
  Monopoly.Rules.Jail,
  Monopoly.Rules.Cards,
  Monopoly.Rules.Rent;

procedure ExecuteLandingRules(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  ); forward;


procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService
  );
begin
  ExecuteLandingRules(
    Game,
    Transactions,
    TRentOptions.None
  );
end;

procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService;
  const Options: TRentOptions
  );
begin
  ExecuteLandingRules(
    Game,
    Transactions,
    Options
  );
end;

{ ------------------------------------------------------------------------ }
{ ExecuteLandingRules}

procedure ExecuteLandingRules(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  );
var
  CurrentPlayer: TPlayer;
  Tile: TTile;
  AmountPaid: integer;
  Handled: boolean;
begin
  CurrentPlayer := Game.CurrentPlayer;
  Tile := Game.Board.TileAtPlayerPosition(CurrentPlayer);
  Handled := True;

  if Tile.TileType = ttGoToJail then
  begin
    Game.Log(Format('%s is sent to jail for landing on Go To Jail.', [CurrentPlayer.Name]));
    SendCurrentPlayerToJail(Game);
  end
  else if Tile.TileType = ttTax then
  begin
    AmountPaid := TransactionService.ChargePlayer(CurrentPlayer, Tile.Amount, Game.Board, Game.OnLog);
    Game.Log(Format('%s landed on %s and lost $%d', [CurrentPlayer.Name, Tile.Name, AmountPaid]));
  end
  else if Tile.TileType = ttChance then
  begin
    HandleChanceCard(Game, TransactionService);
  end
  else if Tile.TileType = ttCommunityChest then
  begin
    HandleCommunityChestCard(Game, TransactionService);
  end
  else if not Tile.IsOwned and (Tile.Price > 0) then
  begin
    Game.Log(Format('%s is available for $%d', [Tile.Name, Tile.Price]));
    if not CurrentPlayer.CanAfford(Tile.Price) then
    begin
      Game.Log(Format('%s does not have enough money to buy %s.', [CurrentPlayer.Name, Tile.Name]));
    end
    else
    begin
      Game.PayBank(CurrentPlayer, Tile.Price);
      CurrentPlayer.AcquireTile(Tile);
      Game.Log(Format('%s bought %s for $%d.', [CurrentPlayer.Name, Tile.Name, Tile.Price]));
    end;
  end
  else if Tile.IsOwned and not Tile.IsOwnedBy(CurrentPlayer) then
  begin
    HandlePayRent(Game, TransactionService, Options);
  end
  else
  begin
    Handled := False;
  end;

  if not Handled then
  begin
    Exit;
  end;

  if CurrentPlayer.Money < 0 then
  begin
    TransactionService.MarkPlayerBankrupt(CurrentPlayer, Game.Board, nil, Game.OnLog);
  end;
end;

end.
