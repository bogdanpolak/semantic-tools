unit Monopoly.Tests.Transactions;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types,
  Monopoly.Transactions;

type
  [TestFixture]
  TTransactionServiceTests = class
  private
    FGame: TGame;
    FTransactionService: ITransactionService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure GetOwnerReturnsOwnerForCurrentTile;

    [Test]
    procedure ChargePlayerBankruptsPlayerAndReleasesAssets;

    [Test]
    procedure TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;

    [Test]
    procedure MarkPlayerBankruptTransfersAssetsToCreditor;
  end;

implementation

uses
  Helpers.Monopoly;

procedure TTransactionServiceTests.Setup;
begin
  FGame := TGame.CreateTest();
  FTransactionService := CreateTransactionService;
end;

procedure TTransactionServiceTests.TearDown;
begin
  FreeAndNil(FGame);
end;

procedure TTransactionServiceTests.ChargePlayerBankruptsPlayerAndReleasesAssets;
var
  AmountCharged: integer;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 40;

  AmountCharged := FTransactionService.ChargePlayer(
    FGame.Players[0],
    50,
    FGame.Board);

  Assert.AreEqual(40, AmountCharged);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TTransactionServiceTests.GetOwnerReturnsOwnerForCurrentTile;
var
  Owner: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FGame.Board, [1]);

  Owner := FTransactionService.GetOwner(FGame);

  Assert.IsNotNull(Owner);
  Assert.AreEqual(FGame.Players[1].Id, Owner.Id);
end;

procedure TTransactionServiceTests.MarkPlayerBankruptTransfersAssetsToCreditor;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  fGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 25;

  FTransactionService.MarkPlayerBankrupt(FGame.Players[0], FGame.Board, FGame.Players[1]);

  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(1525, FGame.Players[1].Money);
  Assert.AreEqual(FGame.Players[1].Id, FGame.Board[1].OwnerId);
end;

procedure TTransactionServiceTests.TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;
var
  AmountTransferred: integer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 40;

  AmountTransferred := FTransactionService.TransferMoney(
    FGame.Players[0],
    FGame.Players[1],
    50,
    FGame.Board
  );

  Assert.AreEqual(40, AmountTransferred);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(FGame.Players[1].Id, FGame.Board[1].OwnerId);
end;

initialization
  TDUnitX.RegisterTestFixture(TTransactionServiceTests);

end.