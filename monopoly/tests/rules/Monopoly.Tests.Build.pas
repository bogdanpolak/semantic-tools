unit Monopoly.Tests.Build;

interface

uses
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TRulesBuildTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TryBuildHouse_CurrentPlayerBuildsHouse;

    [Test]
    procedure TryBuildHouse_RejectedWhenIneligibleTile;

    [Test]
    procedure TryBuildHouse_RejectedWhenNotEnoughMoneyReseve;

    [Test]
    procedure TryBuildHouse_RejectedWhenCannotAfford;
  end;

implementation

uses
  System.SysUtils,
  Monopoly.Tests.Helpers,
  Monopoly.Rules.Build,
  Monopoly.Factories,
  Monopoly.Rules.Decisions;

procedure TRulesBuildTests.TryBuildHouse_CurrentPlayerBuildsHouse;
var
  AmountPaid: integer;
  Msg: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  BuildResult := TryBuildHouse(FGame, AmountPaid, Msg);

  Assert.IsTrue(BuildResult = bhrBuilt);
  Assert.AreEqual(50, AmountPaid);
  Assert.AreEqual(1450, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.Board[1].Houses);
  Assert.IsTrue(Pos('bought a house on', Msg) > 0);
end;

procedure TRulesBuildTests.TryBuildHouse_RejectedWhenIneligibleTile;
var
  AmountPaid: integer;
  Msg: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1]);

  BuildResult := TryBuildHouse(FGame, AmountPaid, Msg);

  Assert.AreEqual(bhrNothingToBuild, BuildResult);
  Assert.AreEqual(0, AmountPaid);
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Board[1].Houses);
end;

procedure TRulesBuildTests.TryBuildHouse_RejectedWhenNotEnoughMoneyReseve;
var
  AmountPaid: integer;
  Msg: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);
  FGame.Players[0].Money := 499;  // 500 is minimal budget to buy a house

  BuildResult := TryBuildHouse(FGame, AmountPaid, Msg);

  Assert.AreEqual(bhrMoneyToLow, BuildResult);
  Assert.AreEqual(0, AmountPaid);
  Assert.AreEqual(499, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Board[1].Houses);
  Assert.AreEqual(
    'Alice can build on Mediterranean Avenue, but needs more money as a reserve.',
    Msg);
end;

procedure TRulesBuildTests.TryBuildHouse_RejectedWhenCannotAfford;
var
  AmountPaid: integer;
  Msg: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);
  FGame.Players[0].Money := 40;

  BuildResult := TryBuildHouse(FGame, AmountPaid, Msg);

  Assert.AreEqual(bhrCannotAfford, BuildResult);
  Assert.AreEqual(0, AmountPaid);
  Assert.AreEqual(40, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Board[1].Houses);
  Assert.IsTrue(Pos('does not have enough money', Msg) > 0);
end;

procedure TRulesBuildTests.Setup;
begin
  FGame := TGame.Create();
end;

procedure TRulesBuildTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TRulesBuildTests);

end.