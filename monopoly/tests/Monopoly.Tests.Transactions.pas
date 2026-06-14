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
    FBoard: TBoard;
    SUT: TTransactionService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    { CollectFromBank }

    [Test]
    procedure CollectFromBankCreditsAmount;

    [Test]
    procedure CollectFromBankIgnoresZeroAndNegativeAmounts;

    [Test]
    procedure CollectFromBankRaisesWhenPlayerIsMissing;

    { ChargePlayer }

    [Test]
    procedure ChargePlayerBankruptsPlayerAndReleasesAssets;

    [Test]
    procedure ChargePlayerDeductsAmount;

    [Test]
    procedure ChargePlayerIgnoresZeroAndNegativeAmounts;

    { MarkPlayerBankrupt }

    [Test]
    procedure MarkPlayerBankruptTransfersAssetsToCreditor;

    [Test]
    procedure MarkPlayerBankruptReleasesAssetsToBank;

    { TransferMoney }

    [Test]
    procedure TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;

    [Test]
    procedure TransferMoneyTransfersPositiveAmount;

    [Test]
    procedure TransferMoneyIgnoresZeroAndNegativeAmounts;

    [Test]
    procedure TransferMoneyRaisesWhenFromPlayerIsMissing;

    [Test]
    procedure TransferMoneyRaisesWhenToPlayerIsMissing;
  end;

implementation

uses
  Monopoly.Tests.Helpers;

procedure TTransactionServiceTests.Setup;
begin
  FGame := TGame.Create();
  FBoard := FGame.Board;
  SUT := TTransactionService.Create;
end;

procedure TTransactionServiceTests.TearDown;
begin
  FreeAndNil(FGame);
  FreeAndNil(SUT);
end;

procedure TTransactionServiceTests.CollectFromBankCreditsAmount;
var
  AmountCollected: integer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var Player := FGame.Players[0];

  AmountCollected := SUT.CollectFromBank(Player, 200);

  Assert.AreEqual(200, AmountCollected);
  Assert.AreEqual(1700, Player.Money);
  Assert.IsFalse(Player.IsBankrupt);
end;

procedure TTransactionServiceTests.CollectFromBankIgnoresZeroAndNegativeAmounts;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var Player := FGame.Players[0];

  Assert.AreEqual(0, SUT.CollectFromBank(Player, 0));
  Assert.AreEqual(1500, Player.Money);

  Assert.AreEqual(0, SUT.CollectFromBank(Player, -10));
  Assert.AreEqual(1500, Player.Money);
end;

procedure TTransactionServiceTests.CollectFromBankRaisesWhenPlayerIsMissing;
begin
  Assert.WillRaise(
    procedure
    begin
      SUT.CollectFromBank(nil, 100);
    end,
    Exception
  );
end;

procedure TTransactionServiceTests.ChargePlayerBankruptsPlayerAndReleasesAssets;
var
  AmountCharged: integer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var player := FGame.Players[0];
  player.AddProperites(FBoard, [1]);
  player.Money := 40;

  AmountCharged := SUT.ChargePlayer(player, 50, FBoard);

  Assert.AreEqual(40, AmountCharged);
  Assert.AreEqual(0, player.Money);
  Assert.IsTrue(player.IsBankrupt);
  Assert.AreEqual(NO_OWNER_ID, FBoard[1].OwnerId);
end;

procedure TTransactionServiceTests.ChargePlayerDeductsAmount;
var
  AmountCharged: integer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var player := FGame.Players[0];

  AmountCharged := SUT.ChargePlayer(player, 200, FBoard);

  Assert.AreEqual(200, AmountCharged);
  Assert.AreEqual(1300, player.Money);
  Assert.IsFalse(player.IsBankrupt);
end;

procedure TTransactionServiceTests.ChargePlayerIgnoresZeroAndNegativeAmounts;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var player := FGame.Players[0];

  Assert.AreEqual(0, SUT.ChargePlayer(player, 0, FBoard));
  Assert.AreEqual(1500, player.Money);

  Assert.AreEqual(0, SUT.ChargePlayer(player, -10, FBoard));
  Assert.AreEqual(1500, player.Money);
end;

{ MarkPlayerBankrupt }

procedure TTransactionServiceTests.MarkPlayerBankruptTransfersAssetsToCreditor;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Bob :=  FGame.Players[1];
  Alice.AddProperites(FGame.Board, [1]);
  Alice.Money := 25;

  SUT.MarkPlayerBankrupt(Alice, FBoard, Bob);

  Assert.IsTrue(Alice.IsBankrupt);
  Assert.AreEqual(1525, Bob.Money);
  Assert.AreEqual(Bob.Id, FBoard[1].OwnerId);
end;

procedure TTransactionServiceTests.MarkPlayerBankruptReleasesAssetsToBank;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  Alice.AddProperites(FBoard, [1]);
  Alice.Money := 25;

  SUT.MarkPlayerBankrupt(Alice, FGame.Board);

  Assert.IsTrue(Alice.IsBankrupt);
  Assert.AreEqual(0, Alice.Money);
  Assert.AreEqual(0, Alice.PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FBoard[1].OwnerId);
end;

{ TransferMoney }

procedure TTransactionServiceTests.TransferMoneyBankruptsPayerAndTransfersAssetsToCreditor;
var
  AmountTransferred: integer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Bob :=  FGame.Players[1];
  Alice.AddProperites(FGame.Board, [1]);
  Alice.Money := 40;

  AmountTransferred := SUT.TransferMoney(Alice, Bob, 50, FBoard );

  Assert.AreEqual(40, AmountTransferred);
  Assert.AreEqual(0, Alice.Money);
  Assert.AreEqual(1540, Bob.Money);
  Assert.IsTrue(Alice.IsBankrupt);
  Assert.AreEqual(Bob.Id, FBoard[1].OwnerId);
  Assert.AreEqual(1, Bob.PropertyIds[0]);
end;

procedure TTransactionServiceTests.TransferMoneyIgnoresZeroAndNegativeAmounts;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Assert.AreEqual(0, SUT.TransferMoney(FGame.Players[0], FGame.Players[1], 0, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(1500, FGame.Players[1].Money);

  Assert.AreEqual(0, SUT.TransferMoney(FGame.Players[0], FGame.Players[1], -50, FGame.Board));
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(1500, FGame.Players[1].Money);
end;

procedure TTransactionServiceTests.TransferMoneyRaisesWhenFromPlayerIsMissing;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Assert.WillRaise(
    procedure
    begin
      SUT.TransferMoney(nil, FGame.Players[1], 100, FBoard);
    end,
    Exception
  );
end;

procedure TTransactionServiceTests.TransferMoneyRaisesWhenToPlayerIsMissing;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Assert.WillRaise(
    procedure
    begin
      SUT.TransferMoney(FGame.Players[0], nil, 100, FBoard);
    end,
    Exception
  );
end;

procedure TTransactionServiceTests.TransferMoneyTransfersPositiveAmount;
var
  AmountTransferred: integer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Bob :=  FGame.Players[1];

  AmountTransferred := SUT.TransferMoney(Alice, Bob, 200, FBoard);

  Assert.AreEqual(200, AmountTransferred);
  Assert.AreEqual(1300, Alice.Money);
  Assert.AreEqual(1700, Bob.Money);
end;

initialization
  TDUnitX.RegisterTestFixture(TTransactionServiceTests);

end.