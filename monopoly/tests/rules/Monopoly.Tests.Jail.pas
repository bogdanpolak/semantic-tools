unit Monopoly.Tests.Jail;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types,
  Monopoly.Transactions;

type
  [TestFixture]
  TJailRulesTests = class
  private
    FGame: TGame;
    FTransations : ITransactionService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TryGetOutJail_PaysFineWhenPlayerCanAffordIt;

    [Test]
    procedure TryGetOutJail_KeepsPlayerInJailAfterFailedRoll;

    [Test]
    procedure TryGetOutJail_ReleasesPlayerOnDoubles;

    [Test]
    procedure TryGetOutJail_BankruptAfterThirdFailedRollWithoutCash;

    [Test]
    procedure TryGetOutJail_GetOutOfJailWhenHavingCard;
  end;

implementation

uses
  Monopoly.Rules.Jail,
  Monopoly.Tests.Helpers;

procedure TJailRulesTests.TryGetOutJail_PaysFineWhenPlayerCanAffordIt;
var
  IsReleasedFromJail: boolean;
  JailRoll: TDiceRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].IsInJail := True;

  IsReleasedFromJail := TryGetOutJail(FGame, FTransations, JailRoll);

  Assert.IsTrue(IsReleasedFromJail);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(1450, FGame.Players[0].Money);
end;

procedure TJailRulesTests.TryGetOutJail_KeepsPlayerInJailAfterFailedRoll;
var
  IsReleasedFromJail: boolean;
  JailRoll: TDiceRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;

  IsReleasedFromJail := TryGetOutJail(FGame, FTransations, JailRoll);

  Assert.IsFalse(IsReleasedFromJail);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.AreEqual(1, FGame.Players[0].FailedJailRolls);
  Assert.AreEqual(30, FGame.Players[0].Money);
end;

procedure TJailRulesTests.TryGetOutJail_ReleasesPlayerOnDoubles;
var
  IsReleasedFromJail: boolean;
  JailRoll: TDiceRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(4, 4)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;

  IsReleasedFromJail := TryGetOutJail(FGame, FTransations, JailRoll);

  Assert.IsTrue(IsReleasedFromJail);
  Assert.AreEqual(False, FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].FailedJailRolls);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.AreEqual(8, JailRoll.Total);
end;

procedure TJailRulesTests.TryGetOutJail_BankruptAfterThirdFailedRollWithoutCash;
var
  JailRoll: TDiceRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;
  FGame.Players[0].FailedJailRolls := 2;
  FGame.Players[0].AddProperites(FGame.Board, [1]);

  TryGetOutJail(FGame, FTransations, JailRoll);

  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TJailRulesTests.TryGetOutJail_GetOutOfJailWhenHavingCard;
var
  IsReleasedFromJail: boolean;
  JailRoll: TDiceRoll;
begin
  // Arrange
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.SetDecks([], [], False);
  FGame.Players[0].Position := 10;
  FGame.Players[0].GetOutOfJailCards.Add(
    THeldJailCard.Create(
      TMonopolyCard.Create(ctGetOutJail, 'Get Out of Jail Free'),
      FGame.CommunityChestDeck));
  FGame.Players[0].IsInJail := True;

  // Act
  IsReleasedFromJail := TryGetOutJail(FGame, FTransations, JailRoll);

  // Assert
  Assert.AreEqual(True, IsReleasedFromJail);
  Assert.AreEqual(False, FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].GetOutOfJailCards.Count);
  Assert.AreEqual(1, FGame.CommunityChestDeck.DiscardedCount);
  Assert.AreEqual(1500, FGame.Players[0].Money);
end;

procedure TJailRulesTests.Setup;
begin
  FGame := TGame.Create();
  FTransations := CreateTransactions();
end;

procedure TJailRulesTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TJailRulesTests);

end.