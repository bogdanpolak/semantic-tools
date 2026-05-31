unit Monopoly.Transactions;

interface

uses
  System.Generics.Collections,
  Monopoly.Types;

type
  ITransactionService = interface
    ['{48D7872F-CC4A-4D43-90E7-B30D2B7C77C0}']
    function GetOwner(Game: TGame): TPlayer;
    function TransferMoney(
      FromPlayer: TPlayer;
      ToPlayer: TPlayer;
      Amount: integer;
      Board: TObjectList<TTile>;
      const Log: TLogProc = nil
      ): integer;
    function ChargePlayer(
      Player: TPlayer;
      Amount: integer;
      Board: TObjectList<TTile>;
      const Log: TLogProc = nil
      ): integer;
    procedure MarkPlayerBankrupt(
      Player: TPlayer;
      Board: TObjectList<TTile>;
      Creditor: TPlayer = nil;
      const Log: TLogProc = nil
      );
  end;

function CreateTransactionService: ITransactionService;

implementation

uses
  System.SysUtils;

type
  TDefaultTransactionService = class(TInterfacedObject, ITransactionService)
  private
    procedure ReleasePlayerProperties(
      Player: TPlayer;
      Board: TObjectList<TTile>
      );
    procedure TransferPlayerProperties(
      Player: TPlayer;
      Creditor: TPlayer;
      Board: TObjectList<TTile>
      );
  public
    function GetOwner(Game: TGame): TPlayer;
    function TransferMoney(
      FromPlayer: TPlayer;
      ToPlayer: TPlayer;
      Amount: integer;
      Board: TObjectList<TTile>;
      const Log: TLogProc = nil
      ): integer;
    function ChargePlayer(
      Player: TPlayer;
      Amount: integer;
      Board: TObjectList<TTile>;
      const Log: TLogProc = nil
      ): integer;
    procedure MarkPlayerBankrupt(
      Player: TPlayer;
      Board: TObjectList<TTile>;
      Creditor: TPlayer = nil;
      const Log: TLogProc = nil
      );
  end;

function CreateTransactionService: ITransactionService;
begin
  Result := TDefaultTransactionService.Create;
end;

function TDefaultTransactionService.ChargePlayer(
  Player: TPlayer;
  Amount: integer;
  Board: TObjectList<TTile>;
  const Log: TLogProc
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

function TDefaultTransactionService.GetOwner(Game: TGame): TPlayer;
begin
  Result := Game.CurrentTileOwner;
end;

procedure TDefaultTransactionService.MarkPlayerBankrupt(
  Player: TPlayer;
  Board: TObjectList<TTile>;
  Creditor: TPlayer;
  const Log: TLogProc
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
    if Assigned(Log) then
    begin
      Log(Format('%s is bankrupt and out of the game.', [Player.Name]));
    end;
    Exit;
  end;

  if Player.Money > 0 then
  begin
    Creditor.Money := Creditor.Money + Player.Money;
  end;

  Player.Money := 0;
  TransferPlayerProperties(Player, Creditor, Board);
  if Assigned(Log) then
  begin
    Log(Format('%s is bankrupt and transfers all assets to %s.', [Player.Name, Creditor.Name]));
  end;
end;

procedure TDefaultTransactionService.ReleasePlayerProperties(
  Player: TPlayer;
  Board: TObjectList<TTile>
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

function TDefaultTransactionService.TransferMoney(
  FromPlayer: TPlayer;
  ToPlayer: TPlayer;
  Amount: integer;
  Board: TObjectList<TTile>;
  const Log: TLogProc
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
    MarkPlayerBankrupt(FromPlayer, Board, ToPlayer, Log);
  end;
end;

procedure TDefaultTransactionService.TransferPlayerProperties(
  Player: TPlayer;
  Creditor: TPlayer;
  Board: TObjectList<TTile>
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