unit Monopoly.Tests.GameLoop;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TGameLoopTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure MovePlayerCompleteMoveAtStartGives200;

    [Test]
    procedure MovePlayerFromStartDoesNotCollect200;

    [Test]
    procedure MovePlayerLandsOnLastTileWithoutWrapping;

    [Test]
    procedure MovePlayerPassesStartAndCollects200;

    [Test]
    procedure PlayTurnLeavesJailedPlayerInPlaceAfterFailedRoll;

    [Test]
    procedure PlayTurnPlaysOneNormalNonDoubleTurn;

    [Test]
    procedure PlayTurnGrantsExtraRollAfterDoubles;

    [Test]
    procedure PlayTurnSkipsBankruptCurrentPlayer;

    [Test]
    procedure PlayTurnStopsExtraTurnsWhenPlayerBecomesBankruptAfterDouble;

    [Test]
    procedure PlayTurnSendsPlayerToJailAfterThreeConsecutiveDoubles;

    [Test]
    procedure PlayTurnUsesJailEscapeRollAndDoesNotGrantExtraTurn;
  end;

implementation

uses
  Monopoly.GameLoop,
  Helpers.Monopoly;

procedure TGameLoopTests.MovePlayerCompleteMoveAtStartGives200;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 31;

  MovePlayer(FGame, 9);

  Assert.AreEqual(0, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
end;

procedure TGameLoopTests.MovePlayerFromStartDoesNotCollect200;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 0;

  MovePlayer(FGame, 3);

  Assert.AreEqual(3, FGame.Players[0].Position);
  Assert.AreEqual(1500, FGame.Players[0].Money);
end;

procedure TGameLoopTests.MovePlayerLandsOnLastTileWithoutWrapping;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 37;

  MovePlayer(FGame, 2);

  Assert.AreEqual(39, FGame.Players[0].Position);
  Assert.AreEqual(1500, FGame.Players[0].Money);
end;

procedure TGameLoopTests.MovePlayerPassesStartAndCollects200;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 39;

  MovePlayer(FGame, 3);

  Assert.AreEqual(2, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
end;

procedure TGameLoopTests.PlayTurnLeavesJailedPlayerInPlaceAfterFailedRoll;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].Position := 10;
  FGame.Players[0].Money := 30;
  FGame.Players[0].IsInJail := True;

  PlayTurn(FGame);

  Assert.AreEqual(10, FGame.Players[0].Position);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.AreEqual(1, FGame.Players[0].FailedJailRolls);
end;

procedure TGameLoopTests.PlayTurnPlaysOneNormalNonDoubleTurn;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([TDiceRoll.Create(1, 2)]);
  FGame.Players[0].Position := 0;

  PlayTurn(FGame);

  Assert.AreEqual(3, FGame.Players[0].Position);
  Assert.AreEqual(1440, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(3));
end;

procedure TGameLoopTests.PlayTurnGrantsExtraRollAfterDoubles;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([
    TDiceRoll.Create(2, 2),
    TDiceRoll.Create(1, 2)
  ]);
  FGame.Players[0].Position := 19;

  PlayTurn(FGame);

  Assert.AreEqual(26, FGame.Players[0].Position);
  Assert.AreEqual(1020, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(23));
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(26));
end;

procedure TGameLoopTests.PlayTurnSkipsBankruptCurrentPlayer;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 5;
  FGame.Players[0].IsBankrupt := True;

  PlayTurn(FGame);

  Assert.AreEqual(5, FGame.Players[0].Position);
  Assert.IsFalse(FGame.HasLastRoll);
end;

procedure TGameLoopTests.PlayTurnStopsExtraTurnsWhenPlayerBecomesBankruptAfterDouble;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(6, 6)
  ]);
  FGame.Players[0].Position := 36;
  FGame.Players[0].Money := 50;

  PlayTurn(FGame);

  Assert.AreEqual(38, FGame.Players[0].Position);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
end;

procedure TGameLoopTests.PlayTurnSendsPlayerToJailAfterThreeConsecutiveDoubles;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(2, 2),
    TDiceRoll.Create(3, 3)
  ]);
  FGame.Players[0].Position := 8;

  PlayTurn(FGame);

  Assert.AreEqual(10, FGame.Players[0].Position);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.IsFalse(FGame.Players[0].IsBankrupt);
end;

procedure TGameLoopTests.PlayTurnUsesJailEscapeRollAndDoesNotGrantExtraTurn;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(6, 6)
  ]);
  FGame.Players[0].Position := 10;
  FGame.Players[0].Money := 30;
  FGame.Players[0].IsInJail := True;

  PlayTurn(FGame);

  Assert.AreEqual(12, FGame.Players[0].Position);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].FailedJailRolls);
end;

procedure TGameLoopTests.Setup;
begin
  FGame := TGame.CreateTest();
end;

procedure TGameLoopTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TGameLoopTests);

end.