unit Monopoly.Rules.Landing;

interface

uses
  Monopoly.Types;

procedure LandingRules(Game: TGame); overload;
procedure LandingRules(
  Game: TGame;
  const Options: TRentOptions
  ); overload;
procedure HandleGoToJail(Game: TGame);
procedure HandlePayTax(Game: TGame);
procedure HandleBuyOrTrade(Game: TGame);

implementation

uses
  Monopoly.LandingHandlers;

procedure HandleBuyOrTrade(Game: TGame);
begin
  HandleLandingBuyOrTrade(Game);
end;

procedure HandleGoToJail(Game: TGame);
begin
  HandleLandingGoToJail(Game);
end;

procedure HandlePayTax(Game: TGame);
begin
  HandleLandingPayTax(Game);
end;

procedure LandingRules(Game: TGame);
begin
  ExecuteLandingRules(Game, TRentOptions.None);
end;

procedure LandingRules(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  ExecuteLandingRules(Game, Options);
end;

end.
