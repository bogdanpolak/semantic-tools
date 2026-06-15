unit Monopoly.Tests.Types;

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
    procedure AcquireTileAssignsOwnerAndTracksPropertyId;

    [Test]
    procedure AdjustPlayerMoneyAppliesPositiveAndNegativeChanges;

    [Test]
    procedure CanAffordReturnsFalseWhenAmountExceedsMoney;

    [Test]
    procedure CanAffordReturnsTrueWhenAmountFitsMoney;

    [Test]
    procedure CountActivePlayersIgnoresBankruptPlayers;

    [Test]
    procedure CountOwnedTilesOfTypeCountsOnlyMatchingOwnedTiles;

    [Test]
    procedure CountOwnedTilesOfTypeReturnsZeroForMissingOwner;

    [Test]
    procedure CountOwnedTilesOfTypeRaisesForUnsupportedTileType;

    [Test]
    procedure CurrentPlayerReturnsMatchingPlayer;

    [Test]
    procedure CurrentPlayerTileOwnerReturnsNilWhenTileIsUnowned;

    [Test]
    procedure CurrentPlayerTileOwnerReturnsOwnerWhenTileIsOwned;

    [Test]
    procedure NextActivePlayerStartsAtFirstActivePlayerWhenUnset;

    [Test]
    procedure NextActivePlayerSkipsBankruptPlayers;

    [Test]
    procedure TileAtPlayerPositionReturnsTileAtPlayerPosition;

    [Test]
    procedure OwnerOfTileReturnsOwnerForOwnedTile;

    [Test]
    procedure OwnerOfTileReturnsNilForUnownedTile;

    [Test]
    procedure TileOwnershipHelpersReflectOwnerState;

    [Test]
    procedure TransferTileToMovesOwnershipAndPropertyTracking;

    [Test]
    procedure TileAtPlayerPositionRaisesWhenPlayerIsMissing;

    [Test]
    procedure TileAtPlayerPositionRaisesWhenPositionIsInvalid;

    [Test]
    procedure RollDiceUsesInjectedDiceRoller;

    [Test]
    procedure DeckDrawReturnAndReshuffleRecycleDiscardedCards;

    [Test]
    procedure MovePlayerByWrapsAndReportsPassingStart;

    [Test]
    procedure MovePlayerToSetsExactPosition;
  end;

implementation

uses
  Monopoly.Factories,
  Monopoly.Tests.Helpers;

procedure TTypeTests.AcquireTileAssignsOwnerAndTracksPropertyId;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AcquireTile(FGame.Board[1]);

  Assert.AreEqual(FGame.Players[0].Id, fGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(1));
end;

procedure TTypeTests.AdjustPlayerMoneyAppliesPositiveAndNegativeChanges;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.PayBank(FGame.Players[0], 15);
  FGame.PayBank(FGame.Players[0], 10);

  Assert.AreEqual(1475, FGame.Players[0].Money);
end;

procedure TTypeTests.CanAffordReturnsFalseWhenAmountExceedsMoney;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Money := 50;

  Assert.IsFalse(FGame.Players[0].CanAfford(60));
end;

procedure TTypeTests.CanAffordReturnsTrueWhenAmountFitsMoney;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Money := 50;

  Assert.IsTrue(FGame.Players[0].CanAfford(50));
  Assert.IsTrue(FGame.Players[0].CanAfford(10));
end;

procedure TTypeTests.CountActivePlayersIgnoresBankruptPlayers;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;

  Assert.AreEqual(2, FGame.CountActivePlayers);
end;

procedure TTypeTests.CountOwnedTilesOfTypeCountsOnlyMatchingOwnedTiles;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [5, 15, 28]);

  Assert.AreEqual(2, FGame.CountOwnedTilesOfType(FGame.Players[0], ttRailroad));
  Assert.AreEqual(1, FGame.CountOwnedTilesOfType(FGame.Players[0], ttUtility));
end;

procedure TTypeTests.CountOwnedTilesOfTypeRaisesForUnsupportedTileType;
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

procedure TTypeTests.CountOwnedTilesOfTypeReturnsZeroForMissingOwner;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);

  Assert.AreEqual(0, FGame.CountOwnedTilesOfType(nil, ttRailroad));
end;

procedure TTypeTests.CurrentPlayerReturnsMatchingPlayer;
var
  Player: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.NextTurn;

  Player := FGame.CurrentPlayer;

  Assert.IsNotNull(Player);
  Assert.AreEqual('Bob', Player.Name);
end;

procedure TTypeTests.CurrentPlayerTileOwnerReturnsNilWhenTileIsUnowned;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
    FGame.Players[0].Position := 1;

  Assert.IsTrue(FGame.CurrentPlayerTileOwner = nil);
end;

procedure TTypeTests.CurrentPlayerTileOwnerReturnsOwnerWhenTileIsOwned;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AcquireTile( FGame.Board[1]);

  Owner := FGame.CurrentPlayerTileOwner;

  Assert.IsNotNull(Owner);
  Assert.AreEqual( FGame.Players[1].Id, Owner.Id);
end;

procedure TTypeTests.DeckDrawReturnAndReshuffleRecycleDiscardedCards;
var
  Deck: TDeck;
  FirstCard: TMonopolyCard;
  SecondCard: TMonopolyCard;
  RecycledCard: TMonopolyCard;
begin
  Deck := TDeck.Create(
    [
      TMonopolyCard.Create(ctCollect, 'Collect $50', 50),
      TMonopolyCard.Create(ctPay, 'Pay $15', 15)
    ]);
  try
    FirstCard := Deck.DrawCard;
    SecondCard := Deck.DrawCard;

    Assert.AreEqual(0, Deck.RemainingCount);
    Assert.AreEqual(0, Deck.DiscardedCount);

    Deck.ReturnCard(FirstCard);
    Deck.ReturnCard(SecondCard);

    Assert.AreEqual(0, Deck.RemainingCount);
    Assert.AreEqual(2, Deck.DiscardedCount);

    RecycledCard := Deck.DrawCard;

    Assert.AreEqual(1, Deck.RemainingCount);
    Assert.AreEqual(0, Deck.DiscardedCount);
    Assert.AreEqual(FirstCard.Text, RecycledCard.Text);
  finally
    Deck.Free;
  end;
end;

procedure TTypeTests.TileAtPlayerPositionRaisesWhenPlayerIsMissing;
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

procedure TTypeTests.TileAtPlayerPositionRaisesWhenPositionIsInvalid;
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

procedure TTypeTests.TileAtPlayerPositionReturnsTileAtPlayerPosition;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 12;

  Tile := FGame.TileAtPlayerPosition(FGame.Players[0]);

  Assert.AreEqual('Electric Company', Tile.Name);
  Assert.AreEqual(ttUtility, Tile.TileType);
end;

procedure TTypeTests.MovePlayerByWrapsAndReportsPassingStart;
var
  PassedStart: boolean;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 39;

  PassedStart := FGame.MovePlayerBy( FGame.Players[0], 3);

  Assert.IsTrue(PassedStart);
  Assert.AreEqual(2, FGame.Players[0].Position);
end;

procedure TTypeTests.MovePlayerToSetsExactPosition;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.MovePlayerTo( FGame.Players[0], 12);

  Assert.AreEqual(12, FGame.Players[0].Position);
end;

procedure TTypeTests.OwnerOfTileReturnsNilForUnownedTile;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Assert.IsTrue(FGame.OwnerOfTile(FGame.Board[1]) = nil);
end;

procedure TTypeTests.OwnerOfTileReturnsOwnerForOwnedTile;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[1].AcquireTile( FGame.Board[1]);

  Owner := FGame.OwnerOfTile(FGame.Board[1]);

  Assert.IsNotNull(Owner);
  Assert.AreEqual( FGame.Players[1].Id, Owner.Id);
end;

procedure TTypeTests.TileOwnershipHelpersReflectOwnerState;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  Tile := FGame.Board[1];
  Assert.IsFalse(Tile.IsOwned);
  Assert.IsFalse(Tile.IsOwnedBy( FGame.Players[0]));

  FGame.Players[1].AcquireTile(Tile);

  Assert.IsTrue(Tile.IsOwned);
  Assert.IsTrue(Tile.IsOwnedBy( FGame.Players[1]));
  Assert.IsFalse(Tile.IsOwnedBy( FGame.Players[0]));
end;

procedure TTypeTests.TransferTileToMovesOwnershipAndPropertyTracking;
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

procedure TTypeTests.NextActivePlayerSkipsBankruptPlayers;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;

  FGame.NextTurn;

  var Player := FGame.CurrentPlayer;
  Assert.AreEqual('Charlie', Player.Name);
  Assert.AreEqual( FGame.Players[2].Id, FGame.CurrentPlayerId);
end;

procedure TTypeTests.NextActivePlayerStartsAtFirstActivePlayerWhenUnset;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].IsBankrupt := True;

  var IsOK := FGame.NextTurn;

  Assert.IsFalse(IsOK);
  Assert.AreEqual('Bob wins the game.', FGame.TermiantionReason);
  Assert.AreEqual('Bob', FGame.Players[1].Name);
  Assert.AreEqual(gsFinished, FGame.Status);
end;

procedure TTypeTests.RollDiceUsesInjectedDiceRoller;
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