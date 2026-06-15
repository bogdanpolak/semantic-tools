unit Monopoly.Tests.Decisions;

interface

uses
  DUnitX.TestFramework,
  Monopoly.Types,
  Monopoly.Rules.Decisions;

type
  [TestFixture]
  TPropertyDevelopmentTests = class
  private
    FGame: TGame;
    FDecisionService: IPlayerDecisionService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure MortgageAndUnmortgageToggleTileState;

    [Test]
    procedure CanBuildHouseRequiresMonopolyAndEvenDevelopment;

    [Test]
    procedure CanBuildHotelRequiresFourHousesAcrossTheSet;
  end;

implementation

uses
  System.SysUtils,
  Monopoly.Tests.Helpers,
  Monopoly.Rules.Build,
  Monopoly.Factories;

procedure TPropertyDevelopmentTests.CanBuildHotelRequiresFourHousesAcrossTheSet;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Board := FGame.Board;
  Alice.AddProperites(FGame.Board, [1, 3]);
  Board[1].Houses := 4;
  Board[3].Houses := 4;

  var CanBuildOn1 := FDecisionService.CanBuildHotel(Board[1], Alice);
  var CanBuildOn3 := FDecisionService.CanBuildHotel(Board[3], Alice);
  var CanBuildOn6 := FDecisionService.CanBuildHotel(Board[6], Alice);

  Assert.AreEqual(True, CanBuildOn1);
  Assert.AreEqual(True, CanBuildOn3);
  Assert.AreEqual(False, CanBuildOn6);
end;

procedure TPropertyDevelopmentTests.CanBuildHouseRequiresMonopolyAndEvenDevelopment;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  Alice.AddProperites(FGame.Board, [1, 3]);
  FGame.Board[1].Houses := 1;

  var canBuildOn1 := FDecisionService.CanBuildHouse(FGame.Board[1], Alice);
  var canBuildOn3 := FDecisionService.CanBuildHouse(FGame.Board[3], Alice);

  Assert.AreEqual(False, canBuildOn1);
  Assert.AreEqual(True, canBuildOn3);
end;

procedure TPropertyDevelopmentTests.MortgageAndUnmortgageToggleTileState;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  var Alice := FGame.Players[0];
  var Board := FGame.Board;
  Alice.AddProperites(Board, [1]);

  var CanMortgage := FDecisionService.CanMortgage(Board[1], Alice);

  Assert.AreEqual(True, CanMortgage);
  Assert.AreEqual(30, Board[1].MortgageValue);

  Board[1].Mortgaged := True;
  var CanUnmortgage := FDecisionService.CanUnmortgage(Board[1], Alice);

  Assert.AreEqual(True, CanUnmortgage);
  Assert.AreEqual(33, Board[1].UnmortgageCost);
end;

procedure TPropertyDevelopmentTests.Setup;
begin
  FGame := TGame.Create();
  FDecisionService := CreatePlayerDecisionService(FGame);
end;

procedure TPropertyDevelopmentTests.TearDown;
begin
  FreeAndNil(FGame);
end;

initialization
  TDUnitX.RegisterTestFixture(TPropertyDevelopmentTests);

end.