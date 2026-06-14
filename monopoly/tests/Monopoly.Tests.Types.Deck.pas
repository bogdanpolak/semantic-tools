unit Monopoly.Tests.Types.Deck;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Monopoly.Types;

type
  [TestFixture]
  TTypeTests = class
  private
    FDeck: TDeck;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DeckDrawReturnAndReshuffleRecycleDiscardedCards;
  end;

implementation

uses
  Monopoly.Factories,
  Monopoly.Tests.Helpers;

procedure TTypeTests.DeckDrawReturnAndReshuffleRecycleDiscardedCards;
var
  FirstCard: TMonopolyCard;
  SecondCard: TMonopolyCard;
  RecycledCard: TMonopolyCard;
begin
  FDeck := TDeck.Create(
    [
      TMonopolyCard.Create(ctCollect, 'Collect $50', 50),
      TMonopolyCard.Create(ctPay, 'Pay $15', 15),
      TMonopolyCard.Create(ctAdvance, 'Advance to Go (Collect $200)', 0, 'Go')
    ], False);

  FirstCard := FDeck.DrawCard;
  SecondCard := FDeck.DrawCard;

  Assert.AreEqual(1, FDeck.RemainingCount);
  Assert.AreEqual(0, FDeck.DiscardedCount);

  FDeck.ReturnCard(FirstCard);
  FDeck.ReturnCard(SecondCard);

  Assert.AreEqual(1, FDeck.RemainingCount);
  Assert.AreEqual(2, FDeck.DiscardedCount);

  FDeck.ReturnCard(FDeck.DrawCard);  // draw and return the last card
  RecycledCard := FDeck.DrawCard;

  Assert.AreEqual(2, FDeck.RemainingCount);
  Assert.AreEqual(0, FDeck.DiscardedCount);
  Assert.AreEqual(FirstCard.Text, RecycledCard.Text);
end;

procedure TTypeTests.TearDown;
begin
  if Assigned(FDeck) then
    FreeAndNil(FDeck)
end;

initialization
  TDUnitX.RegisterTestFixture(TTypeTests);

end.