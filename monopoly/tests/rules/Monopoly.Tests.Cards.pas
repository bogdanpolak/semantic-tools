unit Monopoly.Tests.Cards;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Transactions,
  Monopoly.Types;

type
  [TestFixture]
  TCardRulesTests = class
  private
    FGame: TGame;
    FTransations: ITransactionService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure AdvanceNearestRailroadCardPaysDoubledRent;

    [Test]
    procedure AdvanceNearestUtilityCardUsesTenTimesRoll;

    [Test]
    procedure LandingOnChanceCollectCardAppliesEffect;

    [Test]
    procedure LandingOnCommunityChestCollectCardAppliesEffect;

    [Test]
    procedure GiftFromPlayersSkipsBankruptPlayers;

    [Test]
    procedure GetOutOfJailCard_StaysWithPlayer;

    [Test]
    procedure GoBack3CanTriggerRecursiveLanding;

    [Test]
    procedure GiftFromPlayersCanBankruptAnotherPlayerAndTransferAssets;

    [Test]
    procedure PayCardCanBankruptCurrentPlayer;

    [Test]
    procedure PayEachPlayerCanBankruptCurrentPlayerAndStopFurtherPayments;
  end;

implementation

uses
  Monopoly.Rules.Jail,
  Monopoly.Rules.Landing,
  Monopoly.Factories,
  Monopoly.Tests.Helpers;

procedure TCardRulesTests.AdvanceNearestRailroadCardPaysDoubledRent;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 7;
  FGame.Players[1].AddProperites(FGame.Board, [15, 25]);
  FGame.SetDecks(
    [ TMonopolyCard.Create( ctAdvanceNearestRailroad, 'n/a' ) ],
    [],
    False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(15, FGame.Players[0].Position);
  Assert.AreEqual(1400, FGame.Players[0].Money);
  Assert.AreEqual(1600, FGame.Players[1].Money);
end;

procedure TCardRulesTests.AdvanceNearestUtilityCardUsesTenTimesRoll;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 7;
  FGame.Players[1].AddProperites(FGame.Board, [12]);
  FGame.SetLastRoll(TDiceRoll.Create(3, 4));
  FGame.SetDecks(
    [ TMonopolyCard.Create(ctAdvanceNearestUtility,'n/a') ],
    [],
    False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(12, FGame.Players[0].Position);
  Assert.AreEqual(1430, FGame.Players[0].Money);
  Assert.AreEqual(1570, FGame.Players[1].Money);
end;

procedure TCardRulesTests.LandingOnChanceCollectCardAppliesEffect;
begin
  // Arrange
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 7;
  FGame.SetDecks(
    [ TMonopolyCard.Create(ctCollect, 'n/a', 200) ],
    [],
    False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(7, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.ChanceDeck.DiscardedCount);
end;

procedure TCardRulesTests.LandingOnCommunityChestCollectCardAppliesEffect;
begin
  // Arrange
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.SetDecks(
    [],
    [ TMonopolyCard.Create(ctCollect, 'n/a', 100) ],
    False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(17, FGame.Players[0].Position);
  Assert.AreEqual(1600, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.CommunityChestDeck.DiscardedCount);
end;

procedure TCardRulesTests.GiftFromPlayersSkipsBankruptPlayers;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.Players[2].IsBankrupt := True;
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGiftFromPlayers, 'n/a', 10)], False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(1510, FGame.Players[0].Money);
  Assert.AreEqual(1490, FGame.Players[1].Money);
  Assert.AreEqual(1500, FGame.Players[2].Money);
end;

procedure TCardRulesTests.GetOutOfJailCard_StaysWithPlayer;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGetOutJail, 'n/a')],
    False
  );

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(1, FGame.Players[0].GetOutOfJailCards.Count);
  Assert.AreEqual(0, FGame.CommunityChestDeck.DiscardedCount);
end;

procedure TCardRulesTests.GiftFromPlayersCanBankruptAnotherPlayerAndTransferAssets;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.Players[1].Money := 5;
  FGame.Players[1].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGiftFromPlayers, 'n/a', 10)],
    False);

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(1515, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[1].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[1].Money);
  Assert.AreEqual(1490, FGame.Players[2].Money);
  Assert.AreEqual(FGame.Players[0].Id, FGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(1));
end;

procedure TCardRulesTests.GoBack3CanTriggerRecursiveLanding;
begin
  // Arrange
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 36;
  FGame.SetDecks(
    [ TMonopolyCard.Create(ctGoBack3, 'n/a') ],
    [ TMonopolyCard.Create(ctCollect, 'n/a', 200) ],
    False
  );

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.AreEqual(33, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.ChanceDeck.DiscardedCount);
  Assert.AreEqual(1, FGame.CommunityChestDeck.DiscardedCount);
end;

procedure TCardRulesTests.PayCardCanBankruptCurrentPlayer;
begin
  // Arrange
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.Players[0].Money := 40;
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctPay, 'n/a', 50)],
    False
  );

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TCardRulesTests.PayEachPlayerCanBankruptCurrentPlayerAndStopFurtherPayments;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[0].Position := 17;
  FGame.Players[0].Money := 60;
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [ TMonopolyCard.Create(ctPayEachPlayer, '', 50) ],
    False
  );

  // Act
  LandingRules(FGame, FTransations, TRentOptions.None);

  // Assert
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(1550, FGame.Players[1].Money);
  Assert.AreEqual(1510, FGame.Players[2].Money);
  Assert.AreEqual(FGame.Players[2].Id, FGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[2].PropertyIds.Contains(1));
end;

procedure TCardRulesTests.Setup;
begin
  FGame := TGame.Create();
  FTransations := CreateTransactions;
end;

procedure TCardRulesTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TCardRulesTests);

end.
