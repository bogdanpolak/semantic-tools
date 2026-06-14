unit Monopoly.Transactions;

interface

uses
  Monopoly.Types;

type
  ITransactionService = interface
    ['{48D7872F-CC4A-4D43-90E7-B30D2B7C77C0}']
    function CollectFromBank(
      Player: TPlayer;
      Amount: integer
      ): integer;
    function TransferMoney(
      FromPlayer: TPlayer;
      ToPlayer: TPlayer;
      Amount: integer;
      Board: TBoard;
      const OnLog: TLogEvent = nil
      ): integer;
    function ChargePlayer(
      Player: TPlayer;
      Amount: integer;
      Board: TBoard;
      const Log: TLogEvent
      ): integer;
    procedure MarkPlayerBankrupt(
      Player: TPlayer;
      Board: TBoard;
      Creditor: TPlayer = nil;
      const OnLog: TLogEvent = nil
      );
  end;

type
  TTransactionService = class(TInterfacedObject, ITransactionService)
  private
    procedure ReleasePlayerProperties(
      Player: TPlayer;
      Board: TBoard
      );
    procedure TransferPlayerProperties(
      Player: TPlayer;
      Creditor: TPlayer;
      Board: TBoard
      );
  public
    function CollectFromBank(
      Player: TPlayer;
      Amount: integer
      ): integer;
    function TransferMoney(
      FromPlayer: TPlayer;
      ToPlayer: TPlayer;
      Amount: integer;
      Board: TBoard;
      const OnLog: TLogEvent = nil
      ): integer;
    function ChargePlayer(
      Player: TPlayer;
      Amount: integer;
      Board: TBoard;
      const Log: TLogEvent = nil
      ): integer;
    procedure MarkPlayerBankrupt(
      Player: TPlayer;
      Board: TBoard;
      Creditor: TPlayer = nil;
      const OnLog: TLogEvent = nil
      );
  end;

implementation

uses
  System.SysUtils;


function TTransactionService.CollectFromBank(
  Player: TPlayer;
  Amount: integer
  ): integer;
begin
  if Amount <= 0 then
  begin
    Exit(0);
  end;

  if Player = nil then
  begin
    raise Exception.Create('Player must be a valid player object.');
  end;

  Player.Money := Player.Money + Amount;
  Result := Amount;
end;


function TTransactionService.ChargePlayer(
  Player: TPlayer;
  Amount: integer;
  Board: TBoard;
  const Log: TLogEvent = nil
  ): integer;
begin
  if Amount <= 0 then
  begin
    Exit(0);
  end;

  if Player = nil then
  begin
    raise Exception.Create('Player must be a valid player object.');
  end;

  Result := Amount;
  if Player.Money < Result then
  begin
    Result := Player.Money;
  end;

  if Result < 0 then
  begin
    Result := 0;
  end;

  Player.Money := Player.Money - Result;
  if Result < Amount then
  begin
    MarkPlayerBankrupt(Player, Board, nil, Log);
  end;
end;

procedure TTransactionService.MarkPlayerBankrupt(
  Player: TPlayer;
  Board: TBoard;
  Creditor: TPlayer;
  const OnLog: TLogEvent
  );
begin
  if (Player = nil) or Player.IsBankrupt then
  begin
    Exit;
  end;

  Player.IsBankrupt := True;
  if (Player.Money < 0) or (Creditor = nil) or Creditor.IsBankrupt or (Creditor.Id = Player.Id) then
  begin
    Player.Money := 0;
    ReleasePlayerProperties(Player, Board);
    if Assigned(OnLog) then
    begin
      OnLog(Format('%s is bankrupt and out of the game.', [Player.Name]));
    end;
    Exit;
  end;

  if Player.Money > 0 then
  begin
    Creditor.Money := Creditor.Money + Player.Money;
  end;

  Player.Money := 0;
  TransferPlayerProperties(Player, Creditor, Board);
  if Assigned(OnLog) then
  begin
    OnLog(Format('%s is bankrupt and transfers all assets to %s.', [Player.Name, Creditor.Name]));
  end;
end;

procedure TTransactionService.ReleasePlayerProperties(
  Player: TPlayer;
  Board: TBoard
  );
var
  Tile: TTile;
begin
  for Tile in Board do
  begin
    if Tile.IsOwnedBy(Player) then
    begin
      Player.ReleaseTile(Tile);
    end;
  end;
end;

function TTransactionService.TransferMoney(
  FromPlayer: TPlayer;
  ToPlayer: TPlayer;
  Amount: integer;
  Board: TBoard;
  const OnLog: TLogEvent
  ): integer;
begin
  if Amount <= 0 then
  begin
    Exit(0);
  end;

  if FromPlayer = nil then
  begin
    raise Exception.Create('FromPlayer must be a valid player object.');
  end;

  if ToPlayer = nil then
  begin
    raise Exception.Create('ToPlayer must be a valid player object.');
  end;

  Result := Amount;
  if FromPlayer.Money < Result then
  begin
    Result := FromPlayer.Money;
  end;

  if Result < 0 then
  begin
    Result := 0;
  end;

  FromPlayer.Money := FromPlayer.Money - Result;
  ToPlayer.Money := ToPlayer.Money + Result;

  if Result < Amount then
  begin
    MarkPlayerBankrupt(FromPlayer, Board, ToPlayer, OnLog);
  end;
end;

procedure TTransactionService.TransferPlayerProperties(
  Player: TPlayer;
  Creditor: TPlayer;
  Board: TBoard
  );
var
  Tile: TTile;
begin
  for Tile in Board do
  begin
    if Tile.IsOwnedBy(Player) then
    begin
      Player.TransferTileTo(Tile, Creditor);
    end;
  end;
end;

end.