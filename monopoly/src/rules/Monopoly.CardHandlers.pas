unit Monopoly.CardHandlers;

interface

uses
  Monopoly.Types;

type
  TLandingResolver = reference to procedure(Game: TGame; const Options: TRentOptions);

  ICardHandler = interface
    ['{C55F2BE5-9487-46A2-8C80-33167D301699}']
    function CanHandle(const Card: TMonopolyCard): boolean;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      );
  end;

function CreateCardHandlers: TArray<ICardHandler>;
procedure ExecuteCard(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver
  );

implementation

uses
  System.SysUtils,
  Monopoly.Rules.Jail,
  Monopoly.Utils;

const
  BOARD_SIZE = 40;

  RAILROAD_POSITIONS: array[0..3] of integer = (5, 15, 25, 35);
  UTILITY_POSITIONS: array[0..1] of integer = (12, 28);

type
  TBaseCardHandler = class(TInterfacedObject, ICardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; virtual; abstract;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); virtual; abstract;
  end;

  TCollectCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TPayCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TGiftFromPlayersCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TPayEachPlayerCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TGetOutOfJailCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TGoToJailCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TAdvanceCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TAdvanceNearestRailroadCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TAdvanceNearestUtilityCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TRepairsCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

  TGoBackThreeCardHandler = class(TBaseCardHandler)
  public
    function CanHandle(const Card: TMonopolyCard): boolean; override;
    procedure Execute(
      Game: TGame;
      const Card: TMonopolyCard;
      Deck: TDeck;
      LandingResolver: TLandingResolver;
      var ReturnCardToDeck: boolean
      ); override;
  end;

function PassesGo(
  FromPosition: integer;
  ToPosition: integer
  ): boolean;
begin
  Result := ToPosition < FromPosition;
end;

function FindNearestPosition(
  CurrentPosition: integer;
  const Positions: array of integer
  ): integer;
var
  Position: integer;
  Distance: integer;
  MinimumDistance: integer;
begin
  Result := -1;
  MinimumDistance := MaxInt;
  for Position in Positions do
  begin
    Distance := (Position - CurrentPosition + BOARD_SIZE) mod BOARD_SIZE;
    if (Distance > 0) and (Distance < MinimumDistance) then
    begin
      MinimumDistance := Distance;
      Result := Position;
    end;
  end;
end;

function FindTilePositionByName(
  Game: TGame;
  const TileName: string
  ): integer;
var
  Index: integer;
begin
  for Index := 0 to Game.Board.Count - 1 do
  begin
    if SameText(Game.Board[Index].Name, TileName) then
    begin
      Exit(Index);
    end;
  end;

  raise Exception.CreateFmt('Unknown board location: %s', [TileName]);
end;

function TCollectCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctCollect;
end;

procedure TCollectCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
begin
  Player := Game.CurrentPlayer;
  Game.AdjustPlayerMoney(Player, Card.Value);
  Game.Log(Format('%s collects $%d. %s', [Player.Name, Card.Value, Card.Text]));
end;

function TPayCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctPay;
end;

procedure TPayCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  TotalTransferred: integer;
begin
  Player := Game.CurrentPlayer;
  TotalTransferred := ChargePlayer(Player, Card.Value, Game.Board, Game.OnLog);
  Game.Log(Format('%s pays $%d. %s', [Player.Name, TotalTransferred, Card.Text]));
end;

function TGiftFromPlayersCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctGiftFromPlayers;
end;

procedure TGiftFromPlayersCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  Other: TPlayer;
  TotalTransferred: integer;
begin
  Player := Game.CurrentPlayer;
  TotalTransferred := 0;
  for Other in Game.Players do
  begin
    if (Other.Id <> Player.Id) and not Other.IsBankrupt then
    begin
      TotalTransferred := TotalTransferred + TransferMoney(Other, Player, Card.Value, Game.Board, Game.OnLog);
    end;
  end;

  Game.Log(Format('%s collects $%d total from other players. %s', [Player.Name, TotalTransferred, Card.Text]));
end;

function TPayEachPlayerCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctPayEachPlayer;
end;

procedure TPayEachPlayerCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  Other: TPlayer;
  TotalTransferred: integer;
begin
  Player := Game.CurrentPlayer;
  TotalTransferred := 0;
  for Other in Game.Players do
  begin
    if (Other.Id <> Player.Id) and not Other.IsBankrupt then
    begin
      TotalTransferred := TotalTransferred + TransferMoney(Player, Other, Card.Value, Game.Board, Game.OnLog);
      if Player.IsBankrupt then
      begin
        Break;
      end;
    end;
  end;

  Game.Log(Format('%s pays $%d total to other players. %s', [Player.Name, TotalTransferred, Card.Text]));
end;

function TGetOutOfJailCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctGetOutJail;
end;

procedure TGetOutOfJailCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
begin
  Player := Game.CurrentPlayer;
  Player.GetOutOfJailCards.Add(THeldJailCard.Create(Card, Deck));
  Game.Log(Format('%s receives a Get Out of Jail Free card.', [Player.Name]));
  ReturnCardToDeck := False;
end;

function TGoToJailCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctGoToJail;
end;

procedure TGoToJailCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
begin
  Game.Log(Format('%s goes to jail. %s', [Game.CurrentPlayer.Name, Card.Text]));
  SendCurrentPlayerToJail(Game);
end;

function TAdvanceCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctAdvance;
end;

procedure TAdvanceCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  TargetPosition: integer;
begin
  Player := Game.CurrentPlayer;
  if SameText(Card.Location, 'Go') then
  begin
    TargetPosition := FindTilePositionByName(Game, 'Start');
  end
  else
  begin
    TargetPosition := FindTilePositionByName(Game, Card.Location);
  end;

  if PassesGo(Player.Position, TargetPosition) then
  begin
    Game.AdjustPlayerMoney(Player, 200);
    Game.Log(Format('%s passes Start and collects $200.', [Player.Name]));
  end;

  Game.MovePlayerTo(Player, TargetPosition);
  Game.Log(Format('%s advances to %s.', [Player.Name, Card.Location]));
  LandingResolver(Game, TRentOptions.None);
end;

function TAdvanceNearestRailroadCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctAdvanceNearestRailroad;
end;

procedure TAdvanceNearestRailroadCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  TargetPosition: integer;
begin
  Player := Game.CurrentPlayer;
  TargetPosition := FindNearestPosition(Player.Position, RAILROAD_POSITIONS);
  if PassesGo(Player.Position, TargetPosition) then
  begin
    Game.AdjustPlayerMoney(Player, 200);
    Game.Log(Format('%s passes Start and collects $200.', [Player.Name]));
  end;

  Game.MovePlayerTo(Player, TargetPosition);
  Game.Log(Format('%s advances to nearest railroad: %s.', [Player.Name, Game.Board[TargetPosition].Name]));
  LandingResolver(Game, TRentOptions.RailroadRent2x);
end;

function TAdvanceNearestUtilityCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctAdvanceNearestUtility;
end;

procedure TAdvanceNearestUtilityCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  TargetPosition: integer;
begin
  Player := Game.CurrentPlayer;
  TargetPosition := FindNearestPosition(Player.Position, UTILITY_POSITIONS);
  if PassesGo(Player.Position, TargetPosition) then
  begin
    Game.AdjustPlayerMoney(Player, 200);
    Game.Log(Format('%s passes Start and collects $200.', [Player.Name]));
  end;

  Game.MovePlayerTo(Player, TargetPosition);
  Game.Log(Format('%s advances to nearest utility: %s.', [Player.Name, Game.Board[TargetPosition].Name]));
  LandingResolver(Game, TRentOptions.UtilityRent10x);
end;

function TRepairsCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType in [ctPropertyRepairs, ctStreetRepairs];
end;

procedure TRepairsCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
  Tile: TTile;
  TotalCost: integer;
  TotalTransferred: integer;
  PerHouse: integer;
  PerHotel: integer;
begin
  Player := Game.CurrentPlayer;
  if Card.CardType = ctPropertyRepairs then
  begin
    PerHouse := 25;
    PerHotel := 100;
  end
  else
  begin
    PerHouse := 40;
    PerHotel := 115;
  end;

  TotalCost := 0;
  for Tile in Game.Board do
  begin
    if Tile.IsOwnedBy(Player) then
    begin
      TotalCost := TotalCost + (Tile.Houses * PerHouse);
      if Tile.HasHotel then
      begin
        TotalCost := TotalCost + PerHotel;
      end;
    end;
  end;

  TotalTransferred := ChargePlayer(Player, TotalCost, Game.Board, Game.OnLog);
  Game.Log(Format('%s pays $%d for repairs. %s', [Player.Name, TotalTransferred, Card.Text]));
end;

function TGoBackThreeCardHandler.CanHandle(const Card: TMonopolyCard): boolean;
begin
  Result := Card.CardType = ctGoBack3;
end;

procedure TGoBackThreeCardHandler.Execute(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver;
  var ReturnCardToDeck: boolean
  );
var
  Player: TPlayer;
begin
  Player := Game.CurrentPlayer;
  Game.MovePlayerTo(Player, (Player.Position - 3 + BOARD_SIZE) mod BOARD_SIZE);
  Game.Log(Format('%s goes back 3 spaces to %s.', [Player.Name, Game.Board[Player.Position].Name]));
  LandingResolver(Game, TRentOptions.None);
end;

function CreateCardHandlers: TArray<ICardHandler>;
begin
  Result := [
    TCollectCardHandler.Create,
    TPayCardHandler.Create,
    TGiftFromPlayersCardHandler.Create,
    TPayEachPlayerCardHandler.Create,
    TGetOutOfJailCardHandler.Create,
    TGoToJailCardHandler.Create,
    TAdvanceCardHandler.Create,
    TAdvanceNearestRailroadCardHandler.Create,
    TAdvanceNearestUtilityCardHandler.Create,
    TRepairsCardHandler.Create,
    TGoBackThreeCardHandler.Create
  ];
end;

procedure ExecuteCard(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
  LandingResolver: TLandingResolver
  );
var
  Handler: ICardHandler;
  ReturnCardToDeck: boolean;
begin
  ReturnCardToDeck := True;
  for Handler in CreateCardHandlers do
  begin
    if Handler.CanHandle(Card) then
    begin
      Handler.Execute(Game, Card, Deck, LandingResolver, ReturnCardToDeck);
      if ReturnCardToDeck then
      begin
        Deck.ReturnCard(Card);
      end;
      Exit;
    end;
  end;

  raise Exception.Create('Unknown card type.');
end;

end.