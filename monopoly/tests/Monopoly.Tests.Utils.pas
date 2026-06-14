unit Monopoly.Tests.Utils;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TUtilsTests = class
  private
    FGame: TGame;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    [Test]
    procedure JoinPlayerNamesReturnsCommaSeparatedNames;

    [Test]
    procedure JoinPlayerNamesReturnsEmptyStringForNoPlayers;

    [Test]
    procedure LeftPadAddsLeadingSpaces;

    [Test]
    procedure LeftPadReturnsOriginalTextWhenAlreadyWideEnough;
  end;

implementation

uses
  Monopoly.Tests.Helpers,
  Monopoly.Utils;

procedure TUtilsTests.Setup;
begin
  FGame := TGame.Create();
end;

procedure TUtilsTests.TearDown;
begin
  FreeAndNil(FGame);
end;

procedure TUtilsTests.JoinPlayerNamesReturnsCommaSeparatedNames;
begin
  FGame.StartGame(['Alice', 'Bob', 'Charlie'], MAX_ROUNDS);

  Assert.AreEqual('Alice, Bob, Charlie', JoinPlayerNames(FGame.Players));
end;

procedure TUtilsTests.JoinPlayerNamesReturnsEmptyStringForNoPlayers;
begin
  Assert.AreEqual('', JoinPlayerNames(FGame.Players));
end;

procedure TUtilsTests.LeftPadAddsLeadingSpaces;
begin
  Assert.AreEqual('  $100', LeftPad('$100', 6));
end;

procedure TUtilsTests.LeftPadReturnsOriginalTextWhenAlreadyWideEnough;
begin
  Assert.AreEqual('$1500', LeftPad('$1500', 3));
end;

initialization
  TDUnitX.RegisterTestFixture(TUtilsTests);

end.