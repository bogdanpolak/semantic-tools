unit Monopoly.Rules.Cards;

interface

uses
  Monopoly.CardHandlers,
  Monopoly.Types;

procedure HandleChanceCard(
  Game: TGame;
  LandingResolver: TLandingResolver
  );
procedure HandleCommunityChestCard(
  Game: TGame;
  LandingResolver: TLandingResolver
  );

implementation

uses
  System.SysUtils;

procedure ResolveCard(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver
  );
begin
  ExecuteCard(Game, Card, Deck, LandingResolver);
end;

procedure HandleChanceCard(
  Game: TGame;
  LandingResolver: TLandingResolver
  );
var
  Card: TMonopolyCard;
begin
  if (Game.Decks = nil) or (Game.Decks.Chance = nil) then
  begin
    Exit;
  end;

  Card := Game.Decks.Chance.DrawCard;
  Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
  ResolveCard(Game, Card, Game.Decks.Chance, LandingResolver);
end;

procedure HandleCommunityChestCard(
  Game: TGame;
  LandingResolver: TLandingResolver
  );
var
  Card: TMonopolyCard;
begin
  if (Game.Decks = nil) or (Game.Decks.CommunityChest = nil) then
  begin
    Exit;
  end;

  Card := Game.Decks.CommunityChest.DrawCard;
  Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
  ResolveCard(Game, Card, Game.Decks.CommunityChest, LandingResolver);
end;

end.
