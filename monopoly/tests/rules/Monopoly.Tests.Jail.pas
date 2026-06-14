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
    procedure JailRulesPaysFineWhenPlayerCanAffordIt;

    [Test]
    procedure JailRulesKeepsPlayerInJailAfterFailedRoll;

    [Test]
    procedure JailRulesReleasesPlayerOnDoubles;

    [Test]
    procedure JailRulesMarksPlayerBankruptAfterThirdFailedRollWithoutCash;
  end;

implementation

uses
  Monopoly.Rules.Jail,
  Monopoly.Tests.Helpers;

procedure TJailRulesTests.JailRulesKeepsPlayerInJailAfterFailedRoll;
var
  ResultInfo: TJailResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;

  ResultInfo := JailRules(FGame, FTransations);

  Assert.IsFalse(ResultInfo.CanMove);
  Assert.IsTrue(ResultInfo.HasRoll);
  Assert.IsTrue(ResultInfo.UsedJailRoll);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.AreEqual(1, FGame.Players[0].FailedJailRolls);
  Assert.AreEqual(30, FGame.Players[0].Money);
end;

procedure TJailRulesTests.JailRulesMarksPlayerBankruptAfterThirdFailedRollWithoutCash;
var
  ResultInfo: TJailResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;
  FGame.Players[0].FailedJailRolls := 2;
  FGame.Players[0].AddProperites(FGame.Board, [1]);

  ResultInfo := JailRules(FGame, FTransations);

  Assert.IsFalse(ResultInfo.CanMove);
  Assert.IsFalse(ResultInfo.HasRoll);
  Assert.IsTrue(ResultInfo.UsedJailRoll);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
end;

procedure TJailRulesTests.JailRulesPaysFineWhenPlayerCanAffordIt;
var
  ResultInfo: TJailResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].IsInJail := True;

  ResultInfo := JailRules(FGame, FTransations);

  Assert.IsTrue(ResultInfo.CanMove);
  Assert.IsFalse(ResultInfo.HasRoll);
  Assert.IsFalse(ResultInfo.UsedJailRoll);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(1450, FGame.Players[0].Money);
end;

procedure TJailRulesTests.JailRulesReleasesPlayerOnDoubles;
var
  ResultInfo: TJailResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(4, 4)]);
  FGame.Players[0].IsInJail := True;
  FGame.Players[0].Money := 30;

  ResultInfo := JailRules(FGame, FTransations);

  Assert.IsTrue(ResultInfo.CanMove);
  Assert.IsTrue(ResultInfo.HasRoll);
  Assert.IsTrue(ResultInfo.UsedJailRoll);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].FailedJailRolls);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.AreEqual(8, ResultInfo.Roll.Total);
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