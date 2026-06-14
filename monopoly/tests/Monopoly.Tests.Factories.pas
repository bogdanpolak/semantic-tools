unit Monopoly.Tests.Factories;

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections;

type
  [TestFixture]
  TCreateBoardTests = class
  public
    [Test]
    procedure CreatesFortyTilesWithExpectedSentinels;
  end;

implementation

uses
  Monopoly.Factories,
  Monopoly.Types;

procedure TCreateBoardTests.CreatesFortyTilesWithExpectedSentinels;
var
  Board: TBoard;
begin
  Board := CreateBoard;
  try
    Assert.AreEqual(40, Board.Count);
    Assert.AreEqual(39, Board.FindTilePositionByName('Boardwalk'));
    Assert.AreEqual('Start', Board[0].Name);
    Assert.AreEqual(ttJail, Board[10].TileType);
    Assert.AreEqual(ttGoToJail, Board[30].TileType);
    Assert.AreEqual(NO_OWNER_ID, Board[1].OwnerId);
    Assert.IsFalse(Board[1].HasHotel);
    Assert.AreEqual(0, Board[1].Houses);
  finally
    Board.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCreateBoardTests);

end.
