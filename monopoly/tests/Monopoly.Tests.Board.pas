unit Monopoly.Tests.Board;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TBoardTests = class
  private
    FGame: TGame;
    FBoard: TBoard;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure CountPlayerBuildingsUsesOwnedPropertyIds;

    [Test]
    procedure CountOwnedTilesOfTypeCountsMatchingOwnedTiles;

    [Test]
    procedure CountOwnedTilesOfTypeRaisesForUnsupportedTileType;

    [Test]
    procedure ColorGroupQueriesReflectOwnershipAndDevelopment;

    [Test]
    procedure CurrentTileOwnerReturnsOwnerForPlayersPosition;

    [Test]
    procedure FindTilePositionByNameReturnsMatchingIndex;

    [Test]
    procedure GetPlayerTileReturnsTileAtPlayersPosition;

    [Test]
    procedure GetTileByIdReturnsMatchingTile;

    [Test]
    procedure HasMonopolyDetectsTwoPropertyColorSet;

    [Test]
    procedure OtherActivePlayersSkipsExcludedAndBankruptPlayers;
  end;

implementation

uses
  Monopoly.Tests.Helpers;

procedure TBoardTests.Setup;
begin
  FGame := TGame.Create();
  FBoard := FGame.Board;
end;

procedure TBoardTests.TearDown;
begin
  FreeAndNil(FGame);
end;

procedure TBoardTests.CountPlayerBuildingsUsesOwnedPropertyIds;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FBoard, [1, 3, 34]);
  FBoard[1].Houses := 2;
  FBoard[3].Houses := 1;
  FBoard[34].HasHotel := True;

  Assert.AreEqual(3, FBoard.CountHousesOwnedBy(FGame.Players[0]));
  Assert.AreEqual(1, FBoard.CountHotelsOwnedBy(FGame.Players[0]));
end;

procedure TBoardTests.CountOwnedTilesOfTypeCountsMatchingOwnedTiles;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FBoard, [5, 15, 28]);

  Assert.AreEqual(2, FBoard.CountOwnedTilesOfType(FGame.Players[0], ttRailroad));
  Assert.AreEqual(1, FBoard.CountOwnedTilesOfType(FGame.Players[0], ttUtility));
end;

procedure TBoardTests.CountOwnedTilesOfTypeRaisesForUnsupportedTileType;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);

  Assert.WillRaise(
    procedure
    begin
      FBoard.CountOwnedTilesOfType(FGame.Players[0], ttProperty);
    end,
    Exception
  );
end;

procedure TBoardTests.ColorGroupQueriesReflectOwnershipAndDevelopment;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FBoard, [1, 3]);

  Assert.AreEqual(2, FBoard.CountTilesInColorGroup(FBoard[1]));
  Assert.IsTrue(FBoard.AreColorGroupTilesOwnedBy(FBoard[1], FGame.Players[0]));
  Assert.IsFalse(FBoard.AreColorGroupTilesOwnedBy(FBoard[1], FGame.Players[1]));
  Assert.AreEqual(0, FBoard.LowestHouseCountInColorGroup(FBoard[1], FGame.Players[0]));
  Assert.IsFalse(FBoard.IsColorGroupFullyBuilt(FBoard[1], FGame.Players[0]));
  Assert.IsFalse(FBoard.HasBuildingsInColorGroup(FBoard[1], FGame.Players[0]));

  FBoard[1].Houses := 4;
  FBoard[3].Houses := 4;

  Assert.AreEqual(4, FBoard.LowestHouseCountInColorGroup(FBoard[1], FGame.Players[0]));
  Assert.IsTrue(FBoard.IsColorGroupFullyBuilt(FBoard[1], FGame.Players[0]));
  Assert.IsTrue(FBoard.HasBuildingsInColorGroup(FBoard[1], FGame.Players[0]));
end;

procedure TBoardTests.CurrentTileOwnerReturnsOwnerForPlayersPosition;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FBoard, [1]);

  Owner := FBoard.CurrentPlayerTileOwner;

  Assert.IsNotNull(Owner);
  Assert.AreEqual(FGame.Players[1].Id, Owner.Id);
end;

procedure TBoardTests.FindTilePositionByNameReturnsMatchingIndex;
begin
  Assert.AreEqual(12, FBoard.FindTilePositionByName('Electric Company'));
end;

procedure TBoardTests.GetPlayerTileReturnsTileAtPlayersPosition;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 39;

  Tile := FBoard.TileAtPlayerPosition(FGame.Players[0]);

  Assert.AreEqual('Boardwalk', Tile.Name);
  Assert.AreEqual(ttProperty, Tile.TileType);
end;

procedure TBoardTests.GetTileByIdReturnsMatchingTile;
var
  Tile: TTile;
begin
  Tile := FBoard.TileById(15);

  Assert.AreEqual('Pennsylvania Railroad', Tile.Name);
  Assert.AreEqual(ttRailroad, Tile.TileType);
end;

procedure TBoardTests.HasMonopolyDetectsTwoPropertyColorSet;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FBoard, [1, 3]);

  Assert.IsTrue(FBoard.HasPropertyMonopoly(FBoard[1], FGame.Players[0]));
end;

procedure TBoardTests.OtherActivePlayersSkipsExcludedAndBankruptPlayers;
var
  OtherPlayers: TArray<TPlayer>;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;

  OtherPlayers := FBoard.ActivePlayersExcept(FGame.Players[0]);

  Assert.AreEqual(1, Length(OtherPlayers));
  Assert.AreEqual('Charlie', OtherPlayers[0].Name);
end;

initialization
  TDUnitX.RegisterTestFixture(TBoardTests);

end.