unit Monopoly.Tests.Cards;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TCardRulesTests = class
  private
    FGame: TGame;
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
    procedure GiftFromPlayersSkipsBankruptPlayers;

    [Test]
    procedure GetOutOfJailCardStaysWithPlayerUntilUsed;

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
  Helpers.Monopoly;

procedure TCardRulesTests.AdvanceNearestRailroadCardPaysDoubledRent;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 7;
  FGame.Players[1].AddProperites(FGame.Board, [15, 25]);
  FGame.SetDecks(
    [ TMonopolyCard.Create( ctAdvanceNearestRailroad, 'n/a' ) ], []);

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.AreEqual(15, FGame.Players[0].Position);
  Assert.AreEqual(1400, FGame.Players[0].Money);
  Assert.AreEqual(1600, FGame.Players[1].Money);
end;

procedure TCardRulesTests.AdvanceNearestUtilityCardUsesTenTimesRoll;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 7;
  FGame.Players[1].AddProperites(FGame.Board, [12]);
  FGame.LastRoll := TDiceRoll.Create(3, 4);
  FGame.HasLastRoll := True;
  FGame.SetDecks(
    [ TMonopolyCard.Create(ctAdvanceNearestUtility,'n/a') ],
    []);

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.AreEqual(12, FGame.Players[0].Position);
  Assert.AreEqual(1430, FGame.Players[0].Money);
  Assert.AreEqual(1570, FGame.Players[1].Money);
end;

procedure TCardRulesTests.GiftFromPlayersSkipsBankruptPlayers;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob', 'Charlie']);
  FGame.Players[0].Position := 17;
  FGame.Players[2].IsBankrupt := True;
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGiftFromPlayers, 'n/a', 10)]);

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.AreEqual(1510, FGame.Players[0].Money);
  Assert.AreEqual(1490, FGame.Players[1].Money);
  Assert.AreEqual(1500, FGame.Players[2].Money);
end;

procedure TCardRulesTests.GetOutOfJailCardStaysWithPlayerUntilUsed;
var
  JailResult: TJailResult;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 17;
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGetOutJail, 'n/a')]
  );

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.AreEqual(1, FGame.Players[0].GetOutOfJailCards.Count);
  Assert.AreEqual(0, FGame.Decks.CommunityChest.DiscardedCount);

  FGame.Players[0].IsInJail := True;

  // Act
  JailResult := JailRules(FGame);

  // Assert
  Assert.IsTrue(JailResult.CanMove);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].GetOutOfJailCards.Count);
  Assert.AreEqual(1, FGame.Decks.CommunityChest.DiscardedCount);
  Assert.AreEqual(1500, FGame.Players[0].Money);
end;

procedure TCardRulesTests.GiftFromPlayersCanBankruptAnotherPlayerAndTransferAssets;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob', 'Charlie']);
  FGame.Players[0].Position := 17;
  FGame.Players[1].Money := 5;
  FGame.Players[1].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctGiftFromPlayers, 'n/a', 10)]);

  // Act
  LandingRules(FGame, TRentOptions.None);

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
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 36;
  FGame.SetDecks(
    [ TMonopolyCard.Create(ctGoBack3, 'n/a') ],
    [ TMonopolyCard.Create(ctCollect, 'n/a', 200) ]
  );

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.AreEqual(33, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.Decks.Chance.DiscardedCount);
  Assert.AreEqual(1, FGame.Decks.CommunityChest.DiscardedCount);
end;

procedure TCardRulesTests.PayCardCanBankruptCurrentPlayer;
begin
  // Arrange
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 17;
  FGame.Players[0].Money := 40;
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [TMonopolyCard.Create(ctPay, 'n/a', 50)]
  );

  // Act
  LandingRules(FGame, TRentOptions.None);

  // Assert
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TCardRulesTests.PayEachPlayerCanBankruptCurrentPlayerAndStopFurtherPayments;
begin
  // Arrange
  FGame.AddPlayers(['Alice', 'Bob', 'Charlie']);
  FGame.Players[0].Position := 17;
  FGame.Players[0].Money := 60;
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  FGame.SetDecks(
    [],
    [ TMonopolyCard.Create(ctPayEachPlayer, '', 50) ]
  );

  // Act
  LandingRules(FGame, TRentOptions.None);

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
  FGame := TGame.Create(nil, CreateBoard, nil);
end;

procedure TCardRulesTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TCardRulesTests);

end.
