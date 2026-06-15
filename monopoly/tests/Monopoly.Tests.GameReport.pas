unit Monopoly.Tests.GameReport;

interface

uses
  DUnitX.TestFramework,
  Monopoly.GameReport,
  Monopoly.Types;

type
  [TestFixture]
  TGameStatusTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure GetGameStatusReturnsReportRowsAndMetadata;
  end;

implementation

uses
  System.SysUtils,
  Monopoly.Tests.Helpers;

procedure TGameStatusTests.GetGameStatusReturnsReportRowsAndMetadata;
var
  GameStatus: IGameReport;
  Items: TGameReportItems;
begin
  var MaxRounds := 4;
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MaxRounds, False);
  FGame.Players[0].Money := 900;
  FGame.Players[1].Money := 0;
  FGame.Players[1].IsBankrupt := True;
  FGame.Players[2].Money := 1500;
  FGame.Players[0].AddProperites(FGame.Board, [1, 3, 5]);
  FGame.Players[2].AddProperites(FGame.Board, [6]);
  FGame.Board[1].Houses := 4;
  FGame.Board[3].HasHotel := True;
  FGame.DiceRoller := CreateFixedDiceRoller([TDiceRoll.Create(1, 2)]);

  while (FGame.Status <> gsFinished) do
  begin
    FGame.NextTurn;
  end;

  GameStatus := GetGameReport(FGame);
  Items := GameStatus.Items;

  Assert.AreEqual(8, GameStatus.Turns);  // Ignoring Bon - bankrupt player 2x MaxRounds
  Assert.AreEqual(4, GameStatus.Rounds);
  Assert.AreEqual('Alice', GameStatus.CurrentPlayerName);

  Assert.AreEqual(3, Length(Items));

  Assert.AreEqual(psWinner, Items[0].PlayerStatus);
  Assert.AreEqual('Charlie', Items[0].PlayerName);
  Assert.AreEqual(1500, Items[0].Money);
  Assert.AreEqual(1, Items[0].PropertyCount);
  Assert.AreEqual('6', Items[0].PropertyList);
  Assert.AreEqual(0, Items[0].HouseCount);
  Assert.AreEqual(0, Items[0].HotelCount);

  Assert.AreEqual(psActive, Items[1].PlayerStatus);
  Assert.AreEqual('Alice', Items[1].PlayerName);
  Assert.AreEqual(900, Items[1].Money);
  Assert.AreEqual(3, Items[1].PropertyCount);
  Assert.AreEqual('5 | 1, 3', Items[1].PropertyList);
  Assert.AreEqual(4, Items[1].HouseCount);
  Assert.AreEqual(1, Items[1].HotelCount);

  Assert.AreEqual(psBankrupt, Items[2].PlayerStatus);
  Assert.AreEqual('Bob', Items[2].PlayerName);
  Assert.AreEqual(0, Items[2].Money);
  Assert.AreEqual(0, Items[2].PropertyCount);
  Assert.AreEqual('', Items[2].PropertyList);
  Assert.AreEqual(0, Items[2].HouseCount);
  Assert.AreEqual(0, Items[2].HotelCount);
end;

procedure TGameStatusTests.Setup;
begin
  FGame := TGame.Create();
end;

procedure TGameStatusTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TGameStatusTests);

end.