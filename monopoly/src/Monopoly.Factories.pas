unit Monopoly.Factories;

interface

uses
  System.Generics.Collections,
  Monopoly.Types;

function CreateBoard: TObjectList<TTile>;
function CreatePlayers(const Names: array of string): TObjectList<TPlayer>;
function CreateDecks(ARandomIndex: TRandomIndexFunc = nil): TDeckPair;
function CreateGame(
  const PlayerNames: array of string;
  ADiceRoller: TDiceRoller = nil;
  ARandomIndex: TRandomIndexFunc = nil
  ): TGame;

implementation

function AddTile(
  Board: TObjectList<TTile>;
  AId: integer;
  const AName: string;
  ATileType: TTileType;
  const AColor: string = '';
  APrice: integer = 0;
  ARent: integer = 0;
  AAmount: integer = 0
  ): TTile;
begin
  Result := TTile.Create(AId, AName, ATileType);
  Result.Color := AColor;
  Result.Price := APrice;
  Result.Rent := ARent;
  Result.Amount := AAmount;
  Board.Add(Result);
end;

function BuildChanceCards: TArray<TMonopolyCard>;
begin
  Result := [
    TMonopolyCard.Create(ctAdvance, 'Advance to Boardwalk. If you pass Go, collect $200.', 0, 'Boardwalk'),
    TMonopolyCard.Create(ctAdvance, 'Advance to Go (Collect $200)', 0, 'Go'),
    TMonopolyCard.Create(ctAdvance, 'Advance to Illinois Avenue. If you pass Go, collect $200.', 0, 'Illinois Avenue'),
    TMonopolyCard.Create(ctAdvance, 'Advance to St. Charles Place. If you pass Go, collect $200.', 0, 'St. Charles Place'),
    TMonopolyCard.Create(ctAdvanceNearestRailroad, 'Advance to the nearest Railroad. If unowned, you may buy it from the Bank. If owned, pay twice the rental to which they are otherwise entitled.'),
    TMonopolyCard.Create(ctAdvanceNearestRailroad, 'Advance to the nearest Railroad. If unowned, you may buy it from the Bank. If owned, pay twice the rental to which they are otherwise entitled.'),
    TMonopolyCard.Create(ctAdvanceNearestUtility, 'Advance token to nearest Utility. If unowned, you may buy it from the Bank. If owned, throw dice and pay owner a total ten times amount thrown.'),
    TMonopolyCard.Create(ctCollect, 'Bank pays you dividend of $50.', 50),
    TMonopolyCard.Create(ctGetOutJail, 'Get Out of Jail Free'),
    TMonopolyCard.Create(ctGoBack3, 'Go Back 3 Spaces.'),
    TMonopolyCard.Create(ctGoToJail, 'Go to Jail. Go directly to Jail, do not pass Go, do not collect $200.'),
    TMonopolyCard.Create(ctPropertyRepairs, 'Make general repairs on all your property. For each house pay $25. For each hotel pay $100.'),
    TMonopolyCard.Create(ctPay, 'Speeding fine $15.', 15),
    TMonopolyCard.Create(ctAdvance, 'Take a trip to Reading Railroad. If you pass Go, collect $200.', 0, 'Reading Railroad'),
    TMonopolyCard.Create(ctPayEachPlayer, 'You have been elected Chairman of the Board. Pay each player $50.', 50),
    TMonopolyCard.Create(ctCollect, 'Your building loan matures. Collect $150', 150)
  ];
end;

function BuildCommunityChestCards: TArray<TMonopolyCard>;
begin
  Result := [
    TMonopolyCard.Create(ctAdvance, 'Advance to Go (Collect $200)', 0, 'Go'),
    TMonopolyCard.Create(ctCollect, 'Bank error in your favour. Collect $200', 200),
    TMonopolyCard.Create(ctPay, 'Doctor''s fee. Pay $50', 50),
    TMonopolyCard.Create(ctCollect, 'From sale of stock you get $50', 50),
    TMonopolyCard.Create(ctGetOutJail, 'Get Out of Jail Free'),
    TMonopolyCard.Create(ctGoToJail, 'Go to Jail. Go directly to Jail, do not pass Go, do not collect $200.'),
    TMonopolyCard.Create(ctCollect, 'Holiday fund matures. Receive $100', 100),
    TMonopolyCard.Create(ctCollect, 'Income tax refund. Collect $20', 20),
    TMonopolyCard.Create(ctGiftFromPlayers, 'It is your birthday. Collect $10 from every player', 10),
    TMonopolyCard.Create(ctCollect, 'Life insurance matures. Collect $100', 100),
    TMonopolyCard.Create(ctPay, 'Pay hospital fees of $100', 100),
    TMonopolyCard.Create(ctPay, 'Pay school fees of $50', 50),
    TMonopolyCard.Create(ctCollect, 'Receive $25 consultancy fee', 25),
    TMonopolyCard.Create(ctStreetRepairs, 'You are assessed for street repair. $40 per house. $115 per hotel'),
    TMonopolyCard.Create(ctCollect, 'You have won second prize in a beauty contest. Collect $10', 10),
    TMonopolyCard.Create(ctCollect, 'You inherit $100', 100)
  ];
end;

function CreateBoard: TObjectList<TTile>;
begin
  Result := TObjectList<TTile>.Create(True);
  AddTile(Result, 0, 'Start', ttStart);
  AddTile(Result, 1, 'Mediterranean Avenue', ttProperty, 'dark-purple', 60, 2);
  AddTile(Result, 2, 'Chance', ttChance);
  AddTile(Result, 3, 'Baltic Avenue', ttProperty, 'dark-purple', 60, 4);
  AddTile(Result, 4, 'Income Tax', ttTax, '', 0, 0, 200);
  AddTile(Result, 5, 'Reading Railroad', ttRailroad, '', 200, 25);
  AddTile(Result, 6, 'Oriental Avenue', ttProperty, 'light-blue', 100, 6);
  AddTile(Result, 7, 'Chance', ttChance);
  AddTile(Result, 8, 'Vermont Avenue', ttProperty, 'light-blue', 100, 6);
  AddTile(Result, 9, 'Connecticut Avenue', ttProperty, 'light-blue', 120, 8);
  AddTile(Result, 10, 'Jail', ttJail);
  AddTile(Result, 11, 'St. Charles Place', ttProperty, 'purple', 140, 10);
  AddTile(Result, 12, 'Electric Company', ttUtility, '', 150);
  AddTile(Result, 13, 'States Avenue', ttProperty, 'purple', 140, 10);
  AddTile(Result, 14, 'Virginia Avenue', ttProperty, 'purple', 160, 12);
  AddTile(Result, 15, 'Pennsylvania Railroad', ttRailroad, '', 200, 25);
  AddTile(Result, 16, 'St. James Place', ttProperty, 'orange', 180, 14);
  AddTile(Result, 17, 'Community Chest', ttCommunityChest);
  AddTile(Result, 18, 'Tennessee Avenue', ttProperty, 'orange', 180, 14);
  AddTile(Result, 19, 'New York Avenue', ttProperty, 'orange', 200, 16);
  AddTile(Result, 20, 'Free Parking', ttFreeParking);
  AddTile(Result, 21, 'Kentucky Avenue', ttProperty, 'red', 220, 18);
  AddTile(Result, 22, 'Chance', ttChance);
  AddTile(Result, 23, 'Indiana Avenue', ttProperty, 'red', 220, 18);
  AddTile(Result, 24, 'Illinois Avenue', ttProperty, 'red', 240, 20);
  AddTile(Result, 25, 'B & O Railroad', ttRailroad, '', 200, 25);
  AddTile(Result, 26, 'Atlantic Avenue', ttProperty, 'yellow', 260, 22);
  AddTile(Result, 27, 'Ventnor Avenue', ttProperty, 'yellow', 260, 22);
  AddTile(Result, 28, 'Waterworks', ttUtility, '', 150);
  AddTile(Result, 29, 'Marvin Gardens', ttProperty, 'yellow', 280, 24);
  AddTile(Result, 30, 'Go To Jail', ttGoToJail);
  AddTile(Result, 31, 'Pacific Avenue', ttProperty, 'green', 300, 26);
  AddTile(Result, 32, 'North Carolina Avenue', ttProperty, 'green', 300, 26);
  AddTile(Result, 33, 'Community Chest', ttCommunityChest);
  AddTile(Result, 34, 'Pennsylvania Avenue', ttProperty, 'green', 320, 28);
  AddTile(Result, 35, 'Short Line', ttRailroad, '', 200, 25);
  AddTile(Result, 36, 'Chance', ttChance);
  AddTile(Result, 37, 'Park Place', ttProperty, 'dark-blue', 350, 35);
  AddTile(Result, 38, 'Luxury Tax', ttTax, '', 0, 0, 100);
  AddTile(Result, 39, 'Boardwalk', ttProperty, 'dark-blue', 400, 50);
end;

function CreateDecks(ARandomIndex: TRandomIndexFunc): TDeckPair;
var
  Chance: TDeck;
  CommunityChest: TDeck;
begin
  Chance := TDeck.Create(BuildChanceCards, ARandomIndex);
  CommunityChest := TDeck.Create(BuildCommunityChestCards, ARandomIndex);
  Chance.Shuffle;
  CommunityChest.Shuffle;
  Result := TDeckPair.Create(Chance, CommunityChest);
end;

function CreateGame(
  const PlayerNames: array of string;
  ADiceRoller: TDiceRoller;
  ARandomIndex: TRandomIndexFunc
  ): TGame;
begin
  Result := TGame.Create(
    CreatePlayers(PlayerNames),
    CreateBoard,
    CreateDecks(ARandomIndex),
    ADiceRoller
  );
end;

function CreatePlayers(
  const Names: array of string
  ): TObjectList<TPlayer>;
var
  Index: integer;
begin
  Result := TObjectList<TPlayer>.Create(True);
  for Index := Low(Names) to High(Names) do
  begin
    Result.Add(TPlayer.Create(Index + 1, Names[Index]));
  end;
end;

end.
