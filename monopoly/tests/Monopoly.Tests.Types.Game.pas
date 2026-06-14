unit Monopoly.Tests.Types.Game;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TTypeTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure AcquireTile_AssignsOwnerAndTracksPropertyId;

    [Test]
    procedure PayBank_AppliesPositiveAndNegativeChanges;

    [Test]
    procedure CanAfford_FalseWhenAmountExceedsMoney;

    [Test]
    procedure CanAfford_TrueWhenAmountFitsMoney;

    [Test]
    procedure CountActivePlayers_IgnoresBankruptPlayers;

    [Test]
    procedure CountOwnedTilesOfType_Results;

    [Test]
    procedure CountOwnedTilesOfType_ZeroForMissingOwner;

    [Test]
    procedure CountOwnedTilesOfType_Raises;

    [Test]
    procedure CurrentPlayer_Results;

    [Test]
    procedure CurrentPlayerTileOwner_NilWhenTileIsUnowned;

    [Test]
    procedure CurrentPlayerTileOwner_Results;

    [Test]
    procedure NextTurn_BobWinsGame;

    [Test]
    procedure NextTurn_SkipsBankruptCharliePlayers;

    [Test]
    procedure TileAtPlayerPosition_Values;

    [Test]
    procedure TileAtPlayerPosition_RaisesWhenPlayerIsMissing;

    [Test]
    procedure TileAtPlayerPosition_RaisesWhenPositionIsInvalid;

    [Test]
    procedure OwnerOfTile_ReturnsNilForUnownedTile;

    [Test]
    procedure OwnerOfTile_ReturnsOwnerForOwnedTile;

    [Test]
    procedure IsOwnedBy_Results;

    [Test]
    procedure TransferTileTo_MovesOwnership;

    [Test]
    procedure RollDice_UsesInjectedDiceRoller;

    [Test]
    procedure MovePlayerBy_WrapsAndReportsPassingStart;

    [Test]
    procedure MovePlayerTo_SetsExactPosition;
  end;

implementation

uses
  Monopoly.Factories,
  Monopoly.Tests.Helpers;

procedure TTypeTests.AcquireTile_AssignsOwnerAndTracksPropertyId;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AcquireTile(FGame.Board[1]);

  Assert.AreEqual(FGame.Players[0].Id, fGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(1));
end;

procedure TTypeTests.PayBank_AppliesPositiveAndNegativeChanges;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.PayBank(FGame.Players[0], 15);
  FGame.PayBank(FGame.Players[0], 10);

  Assert.AreEqual(1475, FGame.Players[0].Money);
end;

procedure TTypeTests.CanAfford_FalseWhenAmountExceedsMoney;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Money := 50;

  Assert.IsFalse(FGame.Players[0].CanAfford(60));
end;

procedure TTypeTests.CanAfford_TrueWhenAmountFitsMoney;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Money := 50;

  Assert.IsTrue(FGame.Players[0].CanAfford(50));
  Assert.IsTrue(FGame.Players[0].CanAfford(10));
end;

procedure TTypeTests.CountActivePlayers_IgnoresBankruptPlayers;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;

  Assert.AreEqual(2, FGame.CountActivePlayers);
end;

procedure TTypeTests.CountOwnedTilesOfType_ZeroForMissingOwner;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);

  Assert.AreEqual(0, FGame.CountOwnedTilesOfType(nil, ttRailroad));
end;

procedure TTypeTests.CountOwnedTilesOfType_Results;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [5, 15, 28]);

  Assert.AreEqual(2, FGame.CountOwnedTilesOfType(FGame.Players[0], ttRailroad));
  Assert.AreEqual(1, FGame.CountOwnedTilesOfType(FGame.Players[0], ttUtility));
end;

procedure TTypeTests.CountOwnedTilesOfType_Raises;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  Assert.WillRaise(
    procedure
    begin
      FGame.CountOwnedTilesOfType( FGame.Players[0], ttProperty);
    end,
    Exception
  );
end;

procedure TTypeTests.CurrentPlayer_Results;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);

  FGame.NextTurn;
  Assert.AreEqual('Bob', FGame.CurrentPlayer().Name);

  FGame.NextTurn;
  Assert.AreEqual('Charlie', FGame.CurrentPlayer().Name);

  FGame.NextTurn;
  Assert.AreEqual('Alice', FGame.CurrentPlayer().Name);
end;

procedure TTypeTests.CurrentPlayerTileOwner_NilWhenTileIsUnowned;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
    FGame.Players[0].Position := 1;

  Assert.IsTrue(FGame.CurrentPlayerTileOwner = nil);
end;

procedure TTypeTests.CurrentPlayerTileOwner_Results;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Bob := FGame.Players[1];
  var Charlie := FGame.Players[2];
  Bob.AcquireTile( FGame.Board[1] );
  Charlie.AcquireTile( FGame.Board[3] );

  Alice.Position := 1;
  Owner := FGame.CurrentPlayerTileOwner;
  Assert.AreEqual( Bob.Id, Owner.Id);

  FGame.NextTurn;

  Bob.Position := 3;
  Owner := FGame.CurrentPlayerTileOwner;
  Assert.AreEqual( Charlie.Id, Owner.Id);
end;

procedure TTypeTests.NextTurn_BobWinsGame;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].IsBankrupt := True;

  var IsOK := FGame.NextTurn;

  Assert.IsFalse(IsOK);
  Assert.AreEqual('Bob wins the game.', FGame.TermiantionReason);
  Assert.AreEqual('Bob', FGame.Players[1].Name);
  Assert.isFalse( FGame.IsGameActive);
end;

procedure TTypeTests.NextTurn_SkipsBankruptCharliePlayers;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie', 'Dylan'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;  // Bob is bankrupt
  FGame.Players[2].IsBankrupt := True;  // Bob is bankrupt

  FGame.NextTurn;

  Assert.AreEqual( 4, FGame.CurrentPlayerId);
end;

procedure TTypeTests.TileAtPlayerPosition_Values;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Bob := FGame.Players[1];
  Alice.Position := 12;
  Bob.Position := 39;

  Assert.AreEqual('Electric Company', FGame.TileAtPlayerPosition(Alice).Name);
  Assert.AreEqual('Boardwalk', FGame.TileAtPlayerPosition(Bob).Name);
end;

procedure TTypeTests.TileAtPlayerPosition_RaisesWhenPlayerIsMissing;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  Assert.WillRaise(
    procedure
    begin
      FGame.TileAtPlayerPosition(nil);
    end,
    Exception
  );
end;

procedure TTypeTests.TileAtPlayerPosition_RaisesWhenPositionIsInvalid;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := FGame.Board.Count;

  Assert.WillRaise(
    procedure
    begin
      FGame.TileAtPlayerPosition(FGame.Players[0]);
    end,
    Exception
  );
end;

procedure TTypeTests.OwnerOfTile_ReturnsNilForUnownedTile;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Assert.IsTrue(FGame.OwnerOfTile(FGame.Board[1]) = nil);
end;

procedure TTypeTests.OwnerOfTile_ReturnsOwnerForOwnedTile;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[1].AcquireTile( FGame.Board[1]);

  Owner := FGame.OwnerOfTile(FGame.Board[1]);

  Assert.IsNotNull(Owner);
  Assert.AreEqual( FGame.Players[1].Id, Owner.Id);
end;

procedure TTypeTests.IsOwnedBy_Results;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Tile := FGame.Board[1];
  Assert.IsFalse(Tile.IsOwned);
  Assert.IsFalse(Tile.IsOwnedBy( FGame.Players[0]));
  FGame.Players[1].AcquireTile(Tile);

  Assert.IsTrue(Tile.IsOwnedBy(FGame.Players[1]));
  Assert.IsFalse(Tile.IsOwnedBy(FGame.Players[0]));
end;

procedure TTypeTests.TransferTileTo_MovesOwnership;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Tile := FGame.Board[1];
  FGame.Players[0].AcquireTile(Tile);

  FGame.Players[0].TransferTileTo(Tile, FGame.Players[1]);

  Assert.IsFalse( FGame.Players[0].PropertyIds.Contains(Tile.Id));
  Assert.IsTrue( FGame.Players[1].PropertyIds.Contains(Tile.Id));
  Assert.AreEqual( FGame.Players[1].Id, Tile.OwnerId);
end;

procedure TTypeTests.RollDice_UsesInjectedDiceRoller;
var
  Roll: TDiceRoll;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(4, 5)]);
  Roll := FGame.RollDice;

  Assert.AreEqual(4, Roll.Dice1);
  Assert.AreEqual(5, Roll.Dice2);
  Assert.AreEqual(9, Roll.Total);
  Assert.IsFalse(Roll.IsDouble);
end;

procedure TTypeTests.MovePlayerBy_WrapsAndReportsPassingStart;
var
  PassedStart: boolean;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 39;

  PassedStart := FGame.MovePlayerBy( FGame.Players[0], 3);

  Assert.IsTrue(PassedStart);
  Assert.AreEqual(2, FGame.Players[0].Position);
end;

procedure TTypeTests.MovePlayerTo_SetsExactPosition;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.MovePlayerTo( FGame.Players[0], 12);

  Assert.AreEqual(12, FGame.Players[0].Position);
end;

procedure TTypeTests.Setup;
begin
  FGame := TGame.Create();
end;

procedure TTypeTests.TearDown;
begin
  FreeAndNil(FGame)
end;

initialization
  TDUnitX.RegisterTestFixture(TTypeTests);

end.