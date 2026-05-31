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
    procedure CurrentTileOwnerReturnsNilWhenTileIsUnowned;

    [Test]
    procedure CurrentTileOwnerReturnsOwnerWhenTileIsOwned;

    [Test]
    procedure CurrentPlayerReturnsNilForUnknownId;

    [Test]
    procedure NextActivePlayerStartsAtFirstActivePlayerWhenUnset;

    [Test]
    procedure NextActivePlayerSkipsBankruptPlayers;

    [Test]
    procedure NextActivePlayerReturnsNilWhenAllPlayersAreBankrupt;

    [Test]
    procedure GetPlayerTileReturnsTileAtPlayerPosition;

    [Test]
    procedure GetTileOwnerReturnsOwnerForOwnedTile;

    [Test]
    procedure GetTileOwnerReturnsNilForUnownedTile;

    [Test]
    procedure TileOwnershipHelpersReflectOwnerState;

    [Test]
    procedure TransferTileToMovesOwnershipAndPropertyTracking;

    [Test]
    procedure GetPlayerTileRaisesWhenPlayerIsMissing;

    [Test]
    procedure GetPlayerTileRaisesWhenPositionIsInvalid;

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
  Helpers.Monopoly;

procedure TTypeTests.AcquireTileAssignsOwnerAndTracksPropertyId;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].AcquireTile(FGame.Board[1]);

  Assert.AreEqual(FGame.Players[0].Id, fGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(1));
end;

procedure TTypeTests.AdjustPlayerMoneyAppliesPositiveAndNegativeChanges;
begin
  FGame.AddPlayers(['Alice']);
  FGame.AdjustPlayerMoney(FGame.Players[0], 25);
  FGame.AdjustPlayerMoney(FGame.Players[0], -10);

  Assert.AreEqual(1515, FGame.Players[0].Money);
end;

procedure TTypeTests.CanAffordReturnsFalseWhenAmountExceedsMoney;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Money := 50;

  Assert.IsFalse(FGame.Players[0].CanAfford(60));
end;

procedure TTypeTests.CanAffordReturnsTrueWhenAmountFitsMoney;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Money := 50;

  Assert.IsTrue(FGame.Players[0].CanAfford(50));
  Assert.IsTrue(FGame.Players[0].CanAfford(10));
end;

procedure TTypeTests.CountActivePlayersIgnoresBankruptPlayers;
begin
  FGame.AddPlayers(['Alice', 'Bob', 'Charlie']);
  FGame.Players[1].IsBankrupt := True;

  Assert.AreEqual(2, FGame.CountActivePlayers);
end;

procedure TTypeTests.CountOwnedTilesOfTypeCountsOnlyMatchingOwnedTiles;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].AddProperites(FGame.Board, [5, 15, 28]);

  Assert.AreEqual(2, FGame.CountOwnedTilesOfType(FGame.Players[0], ttRailroad));
  Assert.AreEqual(1, FGame.CountOwnedTilesOfType(FGame.Players[0], ttUtility));
end;

procedure TTypeTests.CountOwnedTilesOfTypeRaisesForUnsupportedTileType;
begin
  FGame.AddPlayers(['Alice']);
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
  FGame.AddPlayers(['Alice']);

  Assert.AreEqual(0, FGame.CountOwnedTilesOfType(nil, ttRailroad));
end;

procedure TTypeTests.CurrentPlayerReturnsMatchingPlayer;
var
  Player: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.CurrentPlayerId := 2;

  Player := FGame.CurrentPlayer;

  Assert.IsNotNull(Player);
  Assert.AreEqual('Bob', Player.Name);
end;

procedure TTypeTests.CurrentTileOwnerReturnsNilWhenTileIsUnowned;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
    FGame.Players[0].Position := 1;

  Assert.IsTrue( FGame.CurrentTileOwner = nil);
end;

procedure TTypeTests.CurrentTileOwnerReturnsOwnerWhenTileIsOwned;
var
  Owner: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AcquireTile( FGame.Board[1]);

  Owner := FGame.CurrentTileOwner;

  Assert.IsNotNull(Owner);
  Assert.AreEqual( FGame.Players[1].Id, Owner.Id);
end;

procedure TTypeTests.CurrentPlayerReturnsNilForUnknownId;
begin
  FGame.AddPlayers(['Alice']);
  FGame.CurrentPlayerId := 999;

  Assert.IsTrue( FGame.CurrentPlayer = nil);
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
    ],
    function(MaxExclusive: integer): integer
    begin
      Result := MaxExclusive - 1;
    end
  );
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

procedure TTypeTests.GetPlayerTileRaisesWhenPlayerIsMissing;
begin
  FGame.AddPlayers(['Alice']);
  Assert.WillRaise(
    procedure
    begin
      FGame.GetPlayerTile(nil);
    end,
    Exception
  );
end;

procedure TTypeTests.GetPlayerTileRaisesWhenPositionIsInvalid;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := FGame.Board.Count;

  Assert.WillRaise(
    procedure
    begin
      FGame.GetPlayerTile( FGame.Players[0]);
    end,
    Exception
  );
end;

procedure TTypeTests.GetPlayerTileReturnsTileAtPlayerPosition;
var
  Tile: TTile;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 12;

  Tile := FGame.GetPlayerTile( FGame.Players[0]);

  Assert.AreEqual('Electric Company', Tile.Name);
  Assert.AreEqual(ttUtility, Tile.TileType);
end;

procedure TTypeTests.MovePlayerByWrapsAndReportsPassingStart;
var
  PassedStart: boolean;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 39;

  PassedStart := FGame.MovePlayerBy( FGame.Players[0], 3);

  Assert.IsTrue(PassedStart);
  Assert.AreEqual(2, FGame.Players[0].Position);
end;

procedure TTypeTests.MovePlayerToSetsExactPosition;
begin
  FGame.AddPlayers(['Alice']);
  FGame.MovePlayerTo( FGame.Players[0], 12);

  Assert.AreEqual(12, FGame.Players[0].Position);
end;

procedure TTypeTests.GetTileOwnerReturnsNilForUnownedTile;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  Assert.IsTrue( FGame.GetTileOwner( FGame.Board[1]) = nil);
end;

procedure TTypeTests.GetTileOwnerReturnsOwnerForOwnedTile;
var
  Owner: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[1].AcquireTile( FGame.Board[1]);

  Owner := FGame.GetTileOwner( FGame.Board[1]);

  Assert.IsNotNull(Owner);
  Assert.AreEqual( FGame.Players[1].Id, Owner.Id);
end;

procedure TTypeTests.TileOwnershipHelpersReflectOwnerState;
var
  Tile: TTile;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
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
  FGame.AddPlayers(['Alice', 'Bob']);
  Tile := FGame.Board[1];
  FGame.Players[0].AcquireTile(Tile);

  FGame.Players[0].TransferTileTo(Tile, FGame.Players[1]);

  Assert.IsFalse( FGame.Players[0].PropertyIds.Contains(Tile.Id));
  Assert.IsTrue( FGame.Players[1].PropertyIds.Contains(Tile.Id));
  Assert.AreEqual( FGame.Players[1].Id, Tile.OwnerId);
end;

procedure TTypeTests.NextActivePlayerReturnsNilWhenAllPlayersAreBankrupt;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].IsBankrupt := True;
  FGame.Players[1].IsBankrupt := True;

  Assert.IsTrue( FGame.NextActivePlayer = nil);
  Assert.AreEqual(0, FGame.CurrentPlayerId);
end;

procedure TTypeTests.NextActivePlayerSkipsBankruptPlayers;
var
  NextPlayer: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob', 'Charlie']);
  FGame.Players[1].IsBankrupt := True;

  NextPlayer := FGame.NextActivePlayer;

  Assert.IsNotNull(NextPlayer);
  Assert.AreEqual('Charlie', NextPlayer.Name);
  Assert.AreEqual( FGame.Players[2].Id, FGame.CurrentPlayerId);
end;

procedure TTypeTests.NextActivePlayerStartsAtFirstActivePlayerWhenUnset;
var
  NextPlayer: TPlayer;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.CurrentPlayerId := 0;
  FGame.Players[0].IsBankrupt := True;

  NextPlayer := FGame.NextActivePlayer;

  Assert.IsNotNull(NextPlayer);
  Assert.AreEqual('Bob', NextPlayer.Name);
  Assert.AreEqual( FGame.Players[1].Id, FGame.CurrentPlayerId);
end;

procedure TTypeTests.RollDiceUsesInjectedDiceRoller;
var
  Roll: TDiceRoll;
begin
  FGame.AddPlayers(['Alice']);
  FGame.FixedDiceRolls([TDiceRoll.Create(4, 5)]);
  Roll := FGame.RollDice;

  Assert.AreEqual(4, Roll.Dice1);
  Assert.AreEqual(5, Roll.Dice2);
  Assert.AreEqual(9, Roll.Total);
  Assert.IsFalse(Roll.IsDouble);
end;

procedure TTypeTests.Setup;
begin
  FGame := TGame.CreateTest();
end;

procedure TTypeTests.TearDown;
begin
  FreeAndNil(FGame)
end;

initialization
  TDUnitX.RegisterTestFixture(TTypeTests);

end.