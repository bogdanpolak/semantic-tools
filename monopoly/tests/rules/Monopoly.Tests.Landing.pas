unit Monopoly.Tests.Landing;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TLandingRulesTests = class
  private
    FGame: TGame;

  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure LandingOnGoToJailSendsPlayerToJail;

    [Test]
    procedure LandingOnTaxDeductsTileAmount;

    [Test]
    procedure LandingOnUnownedPropertyBuysWhenAffordable;

    [Test]
    procedure LandingOnUnownedPropertyLeavesTileUnownedWhenUnaffordable;

    [Test]
    procedure LandingOnOwnedPropertyPaysBaseRent;

    [Test]
    procedure LandingOnOwnedPropertyCanBankruptCurrentPlayerAndTransferAssetsToOwner;

    [Test]
    procedure LandingOnTwoPropertyMonopolyDoublesBaseRent;

    [Test]
    procedure LandingOnThreePropertyMonopolyDoublesBaseRent;

    [Test]
    procedure LandingOnOwnedRailroadPaysScaledRent;

    [Test]
    procedure LandingOnOwnedUtilityUsesLastRoll;
  end;

implementation

uses
  Monopoly.Rules.Landing,
  Helpers.Monopoly;

procedure TLandingRulesTests.Setup;
begin
  FGame := TGame.CreateTest();
end;

procedure TLandingRulesTests.TearDown;
begin
  FreeAndNil(FGame);
end;



procedure TLandingRulesTests.LandingOnGoToJailSendsPlayerToJail;
begin
  // Arrage
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 30;

  // Act
  LandingRules(FGame);

  // Assert
  Assert.AreEqual(10, FGame.Players[0].Position);
  Assert.IsTrue(FGame.Players[0].IsInJail);
  Assert.IsFalse(FGame.Players[0].IsBankrupt);
end;

procedure TLandingRulesTests.LandingOnOwnedPropertyPaysBaseRent;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FGame.Board, [1]);

  LandingRules(FGame);

  Assert.AreEqual(1498, FGame.Players[0].Money);
  Assert.AreEqual(1502, FGame.Players[1].Money);
end;

procedure TLandingRulesTests.LandingOnOwnedPropertyCanBankruptCurrentPlayerAndTransferAssetsToOwner;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[0].Money := 1;
  FGame.Players[0].AddProperites(FGame.Board, [3]);
  FGame.Players[1].AddProperites(FGame.Board, [1]);

  LandingRules(FGame);

  Assert.IsTrue(FGame.Players[0].IsBankrupt);
  Assert.AreEqual(0, FGame.Players[0].Money);
  Assert.AreEqual(1501, FGame.Players[1].Money);
  Assert.AreEqual(FGame.Players[1].Id, FGame.Board[3].OwnerId);
  Assert.IsTrue(FGame.Players[1].PropertyIds.Contains(3));
end;

procedure TLandingRulesTests.LandingOnOwnedRailroadPaysScaledRent;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 5;
  FGame.Players[1].AddProperites(FGame.Board, [5, 15, 25]);

  LandingRules(FGame);

  Assert.AreEqual(1400, FGame.Players[0].Money);
  Assert.AreEqual(1600, FGame.Players[1].Money);
end;

procedure TLandingRulesTests.LandingOnUnownedPropertyBuysWhenAffordable;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 1;

  LandingRules(FGame);

  Assert.AreEqual(1440, FGame.Players[0].Money);
  Assert.AreEqual(FGame.Players[0].Id, FGame.Board[1].OwnerId);
  Assert.IsTrue(FGame.Players[0].PropertyIds.Contains(1));
end;

procedure TLandingRulesTests.LandingOnUnownedPropertyLeavesTileUnownedWhenUnaffordable;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 1;
  FGame.Players[0].Money := 50;

  LandingRules(FGame);

  Assert.AreEqual(50, FGame.Players[0].Money);
  Assert.AreEqual(NO_OWNER_ID, FGame.Board[1].OwnerId);
  Assert.AreEqual(0, FGame.Players[0].PropertyIds.Count);
end;

procedure TLandingRulesTests.LandingOnOwnedUtilityUsesLastRoll;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 12;
  FGame.Players[1].AddProperites(FGame.Board, [12, 28]);
  FGame.LastRoll := TDiceRoll.Create(3, 4);
  FGame.HasLastRoll := True;

  LandingRules(FGame);

  Assert.AreEqual(1430, FGame.Players[0].Money);
  Assert.AreEqual(1570, FGame.Players[1].Money);
end;

procedure TLandingRulesTests.LandingOnTaxDeductsTileAmount;
begin
  FGame.AddPlayers(['Alice']);
  FGame.Players[0].Position := 4;

  LandingRules(FGame);

  Assert.AreEqual(1300, FGame.Players[0].Money);
end;

procedure TLandingRulesTests.LandingOnThreePropertyMonopolyDoublesBaseRent;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 6;
  FGame.Players[1].AddProperites(FGame.Board, [6, 8, 9]);

  LandingRules(FGame);

  Assert.AreEqual(1488, FGame.Players[0].Money);
  Assert.AreEqual(1512, FGame.Players[1].Money);
end;

procedure TLandingRulesTests.LandingOnTwoPropertyMonopolyDoublesBaseRent;
begin
  FGame.AddPlayers(['Alice', 'Bob']);
  FGame.Players[0].Position := 1;
  FGame.Players[1].AddProperites(FGame.Board, [1, 3]);

  LandingRules(FGame);

  Assert.AreEqual(1496, FGame.Players[0].Money);
  Assert.AreEqual(1504, FGame.Players[1].Money);
end;

initialization
  TDUnitX.RegisterTestFixture(TLandingRulesTests);

end.