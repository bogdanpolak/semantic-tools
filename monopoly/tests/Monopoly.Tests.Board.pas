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
end;

procedure TBoardTests.TearDown;
begin
  FreeAndNil(FGame);
end;

procedure TBoardTests.CountPlayerBuildingsUsesOwnedPropertyIds;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3, 34]);
  FGame.Board[1].Houses := 2;
  FGame.Board[3].Houses := 1;
  FGame.Board[34].HasHotel := True;

  Assert.AreEqual(3, FGame.Board.CountHousesOwnedBy(FGame.Players[0]));
  Assert.AreEqual(1, FGame.Board.CountHotelsOwnedBy(FGame.Players[0]));
end;

procedure TBoardTests.CountOwnedTilesOfTypeCountsMatchingOwnedTiles;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Board := FGame.Board;
  FGame.Players[0].AddProperites(Board, [5, 15, 28]);

  Assert.AreEqual(2, Board.CountOwnedTilesOfType(FGame.Players[0], ttRailroad));
  Assert.AreEqual(1, Board.CountOwnedTilesOfType(FGame.Players[0], ttUtility));
end;

procedure TBoardTests.CountOwnedTilesOfTypeRaisesForUnsupportedTileType;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);

  Assert.WillRaise(
    procedure
    begin
      FGame.Board.CountOwnedTilesOfType(FGame.Players[0], ttProperty);
    end,
    Exception
  );
end;

procedure TBoardTests.ColorGroupQueriesReflectOwnershipAndDevelopment;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  var Board := FGame.Board;
  var Alice := FGame.Players[0];
  FGame.Players[0].AddProperites(Board, [1, 3]);

  Assert.AreEqual(2, Board.CountTilesInColorGroup(Board[1]));
  Assert.AreEqual(True, Board.AreColorGroupTilesOwnedBy(Board[1], Alice));
  Assert.AreEqual(False, Board.AreColorGroupTilesOwnedBy(Board[1], FGame.Players[1]));
  Assert.AreEqual(0, Board.LowestHouseCountInColorGroup(Board[1], Alice));
  Assert.AreEqual(False, Board.IsColorGroupFullyBuilt(Board[1], Alice));
  Assert.AreEqual(False, Board.HasBuildingsInColorGroup(Board[1], Alice));

  FGame.Board[1].Houses := 4;
  FGame.Board[3].Houses := 4;

  Assert.AreEqual(4, FGame.Board.LowestHouseCountInColorGroup(Board[1], Alice));
  Assert.AreEqual(True, Board.IsColorGroupFullyBuilt(Board[1], Alice));
  Assert.AreEqual(True, Board.HasBuildingsInColorGroup(Board[1], Alice));
end;

procedure TBoardTests.CurrentTileOwnerReturnsOwnerForPlayersPosition;
var
  Owner: TPlayer;
begin
  FGame.StartGame(['Alice', 'Bob'], MAX_ROUNDS);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FGame.Board, [1]);

  Owner := FGame.Board.CurrentPlayerTileOwner;

  Assert.IsNotNull(Owner);
  Assert.AreEqual(FGame.Players[1].Id, Owner.Id);
end;

procedure TBoardTests.FindTilePositionByNameReturnsMatchingIndex;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  Assert.AreEqual(12, FGame.Board.FindTilePositionByName('Electric Company'));
end;

procedure TBoardTests.GetPlayerTileReturnsTileAtPlayersPosition;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].Position := 39;

  Tile := FGame.Board.TileAtPlayerPosition(FGame.Players[0]);

  Assert.AreEqual('Boardwalk', Tile.Name);
  Assert.AreEqual(ttProperty, Tile.TileType);
end;

procedure TBoardTests.GetTileByIdReturnsMatchingTile;
var
  Tile: TTile;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);

  Tile := FGame.Board.TileById(15);

  Assert.AreEqual('Pennsylvania Railroad', Tile.Name);
  Assert.AreEqual(ttRailroad, Tile.TileType);
end;

procedure TBoardTests.HasMonopolyDetectsTwoPropertyColorSet;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  Assert.IsTrue(FGame.Board.HasPropertyMonopoly(FGame.Board[1], FGame.Players[0]));
end;

procedure TBoardTests.OtherActivePlayersSkipsExcludedAndBankruptPlayers;
var
  OtherPlayers: TArray<TPlayer>;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);
  FGame.Players[1].IsBankrupt := True;

  OtherPlayers := FGame.Board.ActivePlayersExcept(FGame.Players[0]);

  Assert.AreEqual(1, Length(OtherPlayers));
  Assert.AreEqual('Charlie', OtherPlayers[0].Name);
end;

initialization
  TDUnitX.RegisterTestFixture(TBoardTests);

end.