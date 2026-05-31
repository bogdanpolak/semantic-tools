unit Monopoly.Tests.Utils;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TUtilsTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TransferMoneyTransfersPositiveAmount;

    [Test]
    procedure TransferMoneyIgnoresZeroAndNegativeAmounts;

    [Test]
    procedure TransferMoneyRaisesWhenFromPlayerIsMissing;

    [Test]
    procedure TransferMoneyRaisesWhenToPlayerIsMissing;

    [Test]
    procedure TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;

    [Test]
    procedure ChargePlayerDeductsAmount;

    [Test]
    procedure ChargePlayerIgnoresZeroAndNegativeAmounts;

    [Test]
    procedure ChargePlayerRaisesWhenPlayerIsMissing;

    [Test]
    procedure ChargePlayerBankruptsPlayerAndReleasesAssets;

    [Test]
    procedure MarkPlayerBankruptReleasesAssetsToBank;

    [Test]
    procedure MarkPlayerBankruptTransfersAssetsToCreditor;

    [Test]
    procedure GetOwnerReturnsOwnerForCurrentTile;

    [Test]
    procedure GetOwnerReturnsNilForUnownedTile;

    [Test]
    procedure GetOwnerReturnsNilForMissingOwnerId;
  end;

implementation

uses
  Helpers.Monopoly,
  Monopoly.Utils;

procedure TUtilsTests.Setup;
begin
  FGame := TGame.CreateTest();
end;

procedure TUtilsTests.TearDown;
begin
  FreeAndNil(FGame);
end;

procedure TUtilsTests.ChargePlayerBankruptsPlayerAndReleasesAssets;
var
  AmountCharged: integer;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 40;

  AmountCharged := ChargePlayer(FGame.Players[0], 50, FGame.Board);

  Assert.AreEqual(40, AmountCharged);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TUtilsTests.ChargePlayerDeductsAmount;
var
  AmountCharged: integer;
begin
  FGame.AddPlayers(['Alice']);
  AmountCharged := ChargePlayer(FGame.Players[0], 200, FGame.Board);

  Assert.AreEqual(200, AmountCharged);
  Assert.AreEqual(1300, FGame.Players[0].Money);
  Assert.IsFalse(FGame.Players[0].IsBankrupt);
end;

procedure TUtilsTests.ChargePlayerIgnoresZeroAndNegativeAmounts;
begin
  FGame.AddPlayers(['Alice']);
  Assert.AreEqual(0, ChargePlayer(FGame.Players[0], 0, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);

  Assert.AreEqual(0, ChargePlayer(FGame.Players[0], -10, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);
end;

procedure TUtilsTests.ChargePlayerRaisesWhenPlayerIsMissing;
begin
  FGame.AddPlayers(['Alice']);
  Assert.WillRaise(
    procedure
    begin
      ChargePlayer(nil, 50, FGame.Board);
    end,
    Exception
  );
end;

procedure TUtilsTests.GetOwnerReturnsNilForMissingOwnerId;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Board[1].OwnerId := 99;

  Assert.IsTrue(GetOwner(FGame) = nil);
end;

procedure TUtilsTests.GetOwnerReturnsNilForUnownedTile;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;

  Assert.IsTrue(GetOwner(FGame) = nil);
end;

procedure TUtilsTests.GetOwnerReturnsOwnerForCurrentTile;
var
  Owner: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FGame.Board, [1]);

  Owner := GetOwner(FGame);

  Assert.IsTrue(Owner <> nil);
  Assert.AreEqual(FGame.Players[1].Id, Owner.Id);
end;

procedure TUtilsTests.MarkPlayerBankruptReleasesAssetsToBank;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 25;

  MarkPlayerBankrupt(FGame.Players[0], FGame.Board);

  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TUtilsTests.MarkPlayerBankruptTransfersAssetsToCreditor;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 25;

  MarkPlayerBankrupt(FGame.Players[0], FGame.Board, FGame.Players[1]);

  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(1525, FGame.Players[1].Money);
  Assert.AreEqual(FGame.Players[1].Id, FGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[1].PropertyIds.Contains(1));
end;

procedure TUtilsTests.TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;
var
  AmountTransferred: integer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.Players[0].Money := 40;

  AmountTransferred := TransferMoney(
    FGame.Players[0],
    FGame.Players[1],
    50,
    FGame.Board
  );

  Assert.AreEqual(40, AmountTransferred);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(1540, FGame.Players[1].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(FGame.Players[1].Id, FGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[1].PropertyIds.Contains(1));
end;

procedure TUtilsTests.TransferMoneyIgnoresZeroAndNegativeAmounts;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  Assert.AreEqual(0, TransferMoney(FGame.Players[0], FGame.Players[1], 0, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(1500, FGame.Players[1].Money);

  Assert.AreEqual(0, TransferMoney(FGame.Players[0], FGame.Players[1], -50, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(1500, FGame.Players[1].Money);
end;

procedure TUtilsTests.TransferMoneyRaisesWhenFromPlayerIsMissing;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  Assert.WillRaise(
    procedure
    begin
      TransferMoney(nil, FGame.Players[1], 100, FGame.Board);
    end,
    Exception
  );
end;

procedure TUtilsTests.TransferMoneyRaisesWhenToPlayerIsMissing;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  Assert.WillRaise(
    procedure
    begin
      TransferMoney(FGame.Players[0], nil, 100, FGame.Board);
    end,
    Exception
  );
end;

procedure TUtilsTests.TransferMoneyTransfersPositiveAmount;
var
  AmountTransferred: integer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  AmountTransferred := TransferMoney(
    FGame.Players[0],
    FGame.Players[1],
    200,
    FGame.Board
  );

  Assert.AreEqual(200, AmountTransferred);
  Assert.AreEqual(1300, FGame.Players[0].Money);
  Assert.AreEqual(1700, FGame.Players[1].Money);
end;

initialization
  TDUnitX.RegisterTestFixture(TUtilsTests);

end.