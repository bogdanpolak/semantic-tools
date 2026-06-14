unit Monopoly.Tests.PropertyDevelopment;

interface

uses
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TPropertyDevelopmentTests = class
  private
    FGame: TGame;
    FService: IInterface;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure TileStartsUnmortgaged;

    [Test]
    procedure MortgageAndUnmortgageToggleTileState;

    [Test]
    procedure CanBuildHouseRequiresMonopolyAndEvenDevelopment;

    [Test]
    procedure CanBuildHotelRequiresFourHousesAcrossTheSet;

    [Test]
    procedure BuildHouseAddsOneHouseAtColorBasedCost;

    [Test]
    procedure ExplicitBuildActionBuildsHouseForCurrentPlayer;

    [Test]
    procedure ExplicitBuildActionRejectsIneligibleTileWithoutSideEffects;

    [Test]
    procedure ExplicitBuildActionRejectsWhenPlayerCannotAfford;

    [Test]
    procedure CalculateRepairCostCountsHousesAndHotels;
  end;

implementation

uses
  System.SysUtils,
  Monopoly.Tests.Helpers,
  Monopoly.BuildActions,
  Monopoly.Factories,
  Monopoly.PropertyDevelopment;

procedure TPropertyDevelopmentTests.CalculateRepairCostCountsHousesAndHotels;
var
  Service: IPropertyDevelopmentService;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);
  FGame.Board[1].Houses := 2;
  FGame.Board[3].HasHotel := True;

  Service := CreatePropertyDevelopmentService(FGame);

  Assert.AreEqual(150, Service.CalculateRepairCost(FGame.Players[0], prkPropertyRepairs));
  Assert.AreEqual(195, Service.CalculateRepairCost(FGame.Players[0], prkStreetRepairs));
end;

procedure TPropertyDevelopmentTests.CanBuildHotelRequiresFourHousesAcrossTheSet;
var
  Service: IPropertyDevelopmentService;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);
  FGame.Board[1].Houses := 4;
  FGame.Board[3].Houses := 4;

  Service := CreatePropertyDevelopmentService(FGame);

  Assert.IsTrue(Service.CanBuildHotel(FGame.Board[1], FGame.Players[0]));
  Assert.IsTrue(Service.CanBuildHotel(FGame.Board[3], FGame.Players[0]));
end;

procedure TPropertyDevelopmentTests.BuildHouseAddsOneHouseAtColorBasedCost;
var
  Service: IPropertyDevelopmentService;
  HouseCost: integer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  Service := CreatePropertyDevelopmentService(FGame);

  Assert.AreEqual(50, Service.HouseCost(FGame.Board[1]));

  HouseCost := Service.BuildHouse(FGame.Board[1], FGame.Players[0]);
  Assert.AreEqual(50, HouseCost);
  Assert.AreEqual(1, FGame.Board[1].Houses);
end;

procedure TPropertyDevelopmentTests.ExplicitBuildActionBuildsHouseForCurrentPlayer;
var
  AmountPaid: integer;
  Message: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  BuildResult := TryBuildHouse(FGame, FGame.Board[1], AmountPaid, Message);

  Assert.IsTrue(BuildResult = bhrBuilt);
  Assert.AreEqual(50, AmountPaid);
  Assert.AreEqual(1450, FGame.Players[0].Money);
  Assert.AreEqual(1, FGame.Board[1].Houses);
  Assert.IsTrue(Pos('bought a house on', Message) > 0);
end;

procedure TPropertyDevelopmentTests.ExplicitBuildActionRejectsIneligibleTileWithoutSideEffects;
var
  AmountPaid: integer;
  Message: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1]);

  BuildResult := TryBuildHouse(FGame, FGame.Board[1], AmountPaid, Message);

  Assert.IsTrue(BuildResult = bhrCannotBuild);
  Assert.AreEqual(0, AmountPaid);
  Assert.AreEqual(1500, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Board[1].Houses);
  Assert.IsTrue(Pos('cannot build a house', Message) > 0);
end;

procedure TPropertyDevelopmentTests.ExplicitBuildActionRejectsWhenPlayerCannotAfford;
var
  AmountPaid: integer;
  Message: string;
  BuildResult: TBuildHouseResult;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);
  FGame.Players[0].Money := 40;

  BuildResult := TryBuildHouse(FGame, FGame.Board[1], AmountPaid, Message);

  Assert.IsTrue(BuildResult = bhrCannotAfford);
  Assert.AreEqual(0, AmountPaid);
  Assert.AreEqual(40, FGame.Players[0].Money);
  Assert.AreEqual(0, FGame.Board[1].Houses);
  Assert.IsTrue(Pos('does not have enough money', Message) > 0);
end;

procedure TPropertyDevelopmentTests.CanBuildHouseRequiresMonopolyAndEvenDevelopment;
var
  Service: IPropertyDevelopmentService;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1, 3]);

  Service := CreatePropertyDevelopmentService(FGame);

  Assert.IsTrue(Service.CanBuildHouse(FGame.Board[1], FGame.Players[0]));
  Assert.IsTrue(Service.CanBuildHouse(FGame.Board[3], FGame.Players[0]));

  FGame.Board[1].Houses := 1;
  Assert.IsFalse(Service.CanBuildHouse(FGame.Board[1], FGame.Players[0]));
  Assert.IsTrue(Service.CanBuildHouse(FGame.Board[3], FGame.Players[0]));
end;

procedure TPropertyDevelopmentTests.MortgageAndUnmortgageToggleTileState;
var
  Service: IPropertyDevelopmentService;
  MortgageValue: integer;
  UnmortgageCost: integer;
begin
  FGame.StartGame(['Alice'], MAX_ROUNDS);
  FGame.Players[0].AddProperites(FGame.Board, [1]);
  Service := CreatePropertyDevelopmentService(FGame);

  Assert.IsTrue(Service.CanMortgage(FGame.Board[1], FGame.Players[0]));
  MortgageValue := Service.Mortgage(FGame.Board[1], FGame.Players[0]);
  Assert.AreEqual(30, MortgageValue);
  Assert.IsTrue(Service.IsMortgaged(FGame.Board[1]));
  Assert.IsTrue(Service.CanUnmortgage(FGame.Board[1], FGame.Players[0]));

  UnmortgageCost := Service.Unmortgage(FGame.Board[1], FGame.Players[0]);
  Assert.AreEqual(33, UnmortgageCost);
  Assert.IsFalse(Service.IsMortgaged(FGame.Board[1]));
end;

procedure TPropertyDevelopmentTests.Setup;
begin
  FGame := TGame.Create();
  FService := nil;
end;

procedure TPropertyDevelopmentTests.TearDown;
begin
  FService := nil;
  FreeAndNil(FGame);
end;

procedure TPropertyDevelopmentTests.TileStartsUnmortgaged;
begin
  Assert.IsFalse(FGame.Board[1].Mortgaged);
end;

initialization
  TDUnitX.RegisterTestFixture(TPropertyDevelopmentTests);

end.