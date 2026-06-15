unit Monopoly.Tests.PlayTurn;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.CompositionRoot,
  Monopoly.Types;

type
  TPlayTurnTests = class
  private
    FGame: TGame;
  public
    procedure Setup;
    procedure TearDown;

    procedure Move_CompletedAtStartGives200;
    procedure Move_FromStartDoesNotCollect200;
    procedure Move_LandsOnLastTileWithoutWrapping;
    procedure Move_PassesStartAndCollects200;
    procedure Move_GrantsExtraRollAfterDoubles;
    procedure Move_StopsDoubleMovesWhenPlayerBecomesBankrupt;
    procedure Builds_HouseWhenPlayerOwnsMonopoly;
    procedure Builds_HouseAfterLandingOnPlayerMonopoly;
    procedure Skips_BankruptCurrentPlayer;
    procedure Jail_LeavesJailedPlayerInPlaceAfterFailedRoll;
    procedure Jail_SendsPlayerToJailAfterThreeConsecutiveDoubles;
    procedure Jail_UsesJailEscapeRollAndDoesNotGrantExtraTurn;
    procedure PlayGame_TracksTurnAndRoundCounters;
  end;

implementation

uses
  Monopoly.Tests.Helpers;

procedure TPlayTurnTests.Move_CompletedAtStartGives200;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 31;
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(4, 5)  // Move 9
  ]);

  // PlayTurn();

  Assert.AreEqual(0, FGame.Players[0].Position);
  Assert.AreEqual(1700, FGame.Players[0].Money);
end;

procedure TPlayTurnTests.Move_PassesStartAndCollects200;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 39;
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 5)
  ]);

  // Move 6 to "Income Tax" collects $200 for Start and pays $200 income tax
  // PlayTurn();

  Assert.AreEqual(5, FGame.Players[0].Position);
  Assert.AreEqual(1500-200+200, FGame.Players[0].Money);
end;

procedure TPlayTurnTests.Move_FromStartDoesNotCollect200;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 0;
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 2)  // Move 3 and buy "Baltic Avenue" for $60
  ]);

  // PlayTurn();

  Assert.AreEqual(3, FGame.Players[0].Position);
  Assert.AreEqual(1500-60, FGame.Players[0].Money);
end;

procedure TPlayTurnTests.Move_LandsOnLastTileWithoutWrapping;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 36;
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 2)  // Move 3 and buys "Boardwalk" for $400
  ]);

  // PlayTurn();

  Assert.AreEqual(39, FGame.Players[0].Position);
  Assert.AreEqual(1500-400, FGame.Players[0].Money);
end;

procedure TPlayTurnTests.Move_GrantsExtraRollAfterDoubles;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(2, 2),
    TDiceRoll.Create(1, 2)
  ]);
  FGame.Players[0].Position := 19;

  // PlayTurn();

  Assert.AreEqual(26, FGame.Players[0].Position);
  Assert.AreEqual(1020, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(23));
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(26));
end;

procedure TPlayTurnTests.Move_StopsDoubleMovesWhenPlayerBecomesBankrupt;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(6, 6)
  ]);
  FGame.Players[0].Position := 36;
  FGame.Players[0].Money := 50;

  // PlayTurn();

  Assert.AreEqual(38, FGame.Players[0].Position);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
end;

procedure TPlayTurnTests.Builds_HouseWhenPlayerOwnsMonopoly;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(1, 2)]);
  FGame.Players[0].Position := 17;
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  // PlayTurn();

  Assert.AreEqual(20, FGame.Players[0].Position);
  Assert.AreEqual(1450, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.Board[1].Houses);
  Assert.AreEqual(0, FGame.Board[3].Houses);
end;

procedure TPlayTurnTests.Builds_HouseAfterLandingOnPlayerMonopoly;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(1, 2)]);
  FGame.Players[0].Position := 38;
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  // PlayTurn();

  Assert.AreEqual(1, FGame.Players[0].Position);
  Assert.AreEqual(1650, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.Board[1].Houses);
  Assert.AreEqual(0, FGame.Board[3].Houses);
end;

procedure TPlayTurnTests.Skips_BankruptCurrentPlayer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 5;
  FGame.Players[0].IsBankrupt := True;

  // PlayTurn();

  Assert.AreEqual(5, FGame.Players[0].Position);
  Assert.IsFalse(FGame.HasLastRoll);
end;

procedure TPlayTurnTests.Jail_LeavesJailedPlayerInPlaceAfterFailedRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(2, 3)]);
  FGame.Players[0].Position := 10;
  FGame.Players[0].Money := 30;
  FGame.Players[0].IsInJail := True;

  // PlayTurn();

  Assert.AreEqual(10, FGame.Players[0].Position);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.AreEqual(1, FGame.Players[0].FailedJailRolls);
end;

procedure TPlayTurnTests.Jail_SendsPlayerToJailAfterThreeConsecutiveDoubles;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(2, 2),
    TDiceRoll.Create(3, 3)
  ]);
  FGame.Players[0].Position := 8;

  // PlayTurn();

  Assert.AreEqual(10, FGame.Players[0].Position);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.IsFalse(FGame.Players[0].IsBankrupt);
end;

procedure TPlayTurnTests.Jail_UsesJailEscapeRollAndDoesNotGrantExtraTurn;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([
    TDiceRoll.Create(1, 1),
    TDiceRoll.Create(6, 6)
  ]);
  FGame.Players[0].Position := 10;
  FGame.Players[0].Money := 30;
  FGame.Players[0].IsInJail := True;

  // PlayTurn();

  Assert.AreEqual(12, FGame.Players[0].Position);
  Assert.AreEqual(30, FGame.Players[0].Money);
  Assert.IsFalse(FGame.Players[0].IsInJail);
  Assert.AreEqual(0, FGame.Players[0].FailedJailRolls);
end;

procedure TPlayTurnTests.PlayGame_TracksTurnAndRoundCounters;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(1, 2)]);
  FGame.Players[0].Position := 1;
  FGame.Players[0].Money := 100;

  // PlayGame();

  Assert.AreEqual(1, FGame.TurnNumber);
  Assert.AreEqual(1, FGame.RoundNumber);
  Assert.AreEqual(gsFinished, FGame.Status);
  Assert.IsTrue(FGame.Players[0].IsBankrupt);
end;

procedure TPlayTurnTests.Setup;
begin
  FGame := TGame.Create();
end;

procedure TPlayTurnTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TPlayTurnTests);

end.