unit Monopoly.Utils;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Monopoly.Types;

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

implementation

uses
  Monopoly.Transactions;

function TransactionService: ITransactionService;
begin
  Result := CreateTransactionService;
end;

function GetOwner(Game: TGame): TPlayer;
begin
  Result := Game.CurrentTileOwner;
end;

function TransferMoney(
  FromPlayer: TPlayer;
  ToPlayer: TPlayer;
  Amount: integer;
  Board: TObjectList<TTile>;
  const Log: TLogProc
  ): integer;
begin
  Result := TransactionService.TransferMoney(FromPlayer, ToPlayer, Amount, Board, Log);
end;

function ChargePlayer(
  Player: TPlayer;
  Amount: integer;
  Board: TObjectList<TTile>;
  const Log: TLogProc
  ): integer;
begin
  Result := TransactionService.ChargePlayer(Player, Amount, Board, Log);
end;

procedure MarkPlayerBankrupt(
  Player: TPlayer;
  Board: TObjectList<TTile>;
  Creditor: TPlayer;
  const Log: TLogProc
  );
begin
  TransactionService.MarkPlayerBankrupt(Player, Board, Creditor, Log);
end;

end.
