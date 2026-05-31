unit Monopoly.Types;

interface

uses
  System.Generics.Collections,
  System.SysUtils;

const
  NO_OWNER_ID = 0;

type
  TTile = class;

  TTileType = (
    ttStart,
    ttProperty,
    ttChance,
    ttTax,
    ttJail,
    ttRailroad,
    ttUtility,
    ttCommunityChest,
    ttFreeParking,
    ttGoToJail
  );

  TCardType = (
    ctAdvance,
    ctAdvanceNearestRailroad,
    ctAdvanceNearestUtility,
    ctCollect,
    ctGetOutJail,
    ctGoBack3,
    ctGoToJail,
    ctPropertyRepairs,
    ctPay,
    ctPayEachPlayer,
    ctGiftFromPlayers,
    ctStreetRepairs
  );

  TDiceRoll = record
    Dice1: integer;
    Dice2: integer;
    Total: integer;
    IsDouble: boolean;
    class function Create(
      ADice1: integer;
      ADice2: integer
      ): TDiceRoll; static;
  end;

  TDiceRoller = reference to function: TDiceRoll;
  TRandomIndexFunc = reference to function(MaxExclusive: integer): integer;
  TLogProc = reference to procedure(const Message: string);

  TRentOptions = record
    IsRailroadRent2x: boolean;
    IsUtilityRent10x: boolean;
    class function RailroadRent2x: TRentOptions; static;
    class function UtilityRent10x: TRentOptions; static;
    class function None: TRentOptions; static;
  end;

  TMonopolyCard = record
    CardType: TCardType;
    Location: string;
    Value: integer;
    Text: string;
    class function Create(
      ACardType: TCardType;
      const AText: string;
      AValue: integer = 0;
      const ALocation: string = ''
    ): TMonopolyCard; static;
  end;

  TDeck = class;

  THeldJailCard = record
    Card: TMonopolyCard;
    Deck: TDeck;
    class function Create(
      const ACard: TMonopolyCard;
      ADeck: TDeck
      ): THeldJailCard; static;
  end;

  TPlayer = class
  public
    Id: integer;
    Name: string;
    Position: integer;
    Money: integer;
    PropertyIds: TList<Integer>;
    IsBankrupt: boolean;
    IsInJail: boolean;
    FailedJailRolls: integer;
    GetOutOfJailCards: TList<THeldJailCard>;
    constructor Create(
      AId: integer;
      const AName: string
      );
    destructor Destroy; override;
    procedure AcquireTile(Tile: TTile);
    function CanAfford(Amount: integer): boolean;
    procedure ReleaseTile(Tile: TTile);
    procedure TransferTileTo(
      Tile: TTile;
      Recipient: TPlayer
      );
  end;

  TTile = class
  public
    Id: integer;
    Name: string;
    TileType: TTileType;
    Color: string;
    Price: integer;
    Rent: integer;
    Amount: integer;
    OwnerId: integer;
    Houses: integer;
    HasHotel: boolean;
    constructor Create(
      AId: integer;
      const AName: string;
      ATileType: TTileType
      );
    function IsOwned: boolean;
    function IsOwnedBy(const Player: TPlayer): boolean;
    function IsOwnable: boolean;
  end;

  TDeck = class
  private
    FCards: TList<TMonopolyCard>;
    FDiscardedCards: TList<TMonopolyCard>;
    FRandomIndex: TRandomIndexFunc;
    procedure ReshuffleDiscardedCards;
  public
    constructor Create(const Cards: array of TMonopolyCard; ARandomIndex: TRandomIndexFunc = nil);
    destructor Destroy; override;
    function DrawCard: TMonopolyCard;
    procedure ReturnCard(const Card: TMonopolyCard);
    procedure Shuffle;
    function RemainingCount: integer;
    function DiscardedCount: integer;
  end;

  TDeckPair = class
  public
    Chance: TDeck;
    CommunityChest: TDeck;
    constructor Create(
      AChance: TDeck;
      ACommunityChest: TDeck
      );
    destructor Destroy; override;
  end;

  TGame = class
  private
    function DefaultDiceRoll: TDiceRoll;
  public
    FDiceRoller: TDiceRoller;
    Players: TObjectList<TPlayer>;
    Board: TObjectList<TTile>;
    Decks: TDeckPair;
    CurrentPlayerId: integer;
    LastRoll: TDiceRoll;
    HasLastRoll: boolean;
    OnLog: TLogProc;
    constructor Create(
      APlayers: TObjectList<TPlayer>;
      ABoard: TObjectList<TTile>;
      ADecks: TDeckPair;
      ADiceRoller: TDiceRoller = nil
    );
    destructor Destroy; override;
    procedure AdjustPlayerMoney(
      Player: TPlayer;
      AmountDelta: integer
      );
    procedure Log(const Message: string);
    function MovePlayerBy(
      Player: TPlayer;
      Steps: integer
      ): boolean;
    procedure MovePlayerTo(
      Player: TPlayer;
      Position: integer
      );
    function RollDice: TDiceRoll;
    function CurrentPlayer: TPlayer;
    function CountActivePlayers: integer;
    function NextActivePlayer: TPlayer;
    function CountOwnedTilesOfType(
      const Owner: TPlayer;
      ATileType: TTileType
    ): integer;
    function CurrentTileOwner: TPlayer;
    function GetPlayerTile(APlayer: TPlayer): TTile;
    function GetTileOwner(Tile: TTile): TPlayer;
  end;

function TileTypeToText(ATileType: TTileType): string;

implementation

{ TDiceRoll }

class function TDiceRoll.Create(
  ADice1: integer;
  ADice2: integer
  ): TDiceRoll;
begin
  Result.Dice1 := ADice1;
  Result.Dice2 := ADice2;
  Result.Total := ADice1 + ADice2;
  Result.IsDouble := ADice1 = ADice2;
end;

{ TRentOptions }

class function TRentOptions.None: TRentOptions;
begin
  Result.IsRailroadRent2x := False;
  Result.IsUtilityRent10x := False;
end;

class function TRentOptions.RailroadRent2x: TRentOptions;
begin
  Result.IsRailroadRent2x := true;
end;

class function TRentOptions.UtilityRent10x: TRentOptions;
begin
  Result.IsUtilityRent10x := true;
end;

{ TMonopolyCard }

class function TMonopolyCard.Create(
  ACardType: TCardType;
  const AText: string;
  AValue: integer;
  const ALocation: string
  ): TMonopolyCard;
begin
  Result.CardType := ACardType;
  Result.Text := AText;
  Result.Value := AValue;
  Result.Location := ALocation;
end;

{ THeldJailCard }

class function THeldJailCard.Create(
  const ACard: TMonopolyCard;
  ADeck: TDeck
  ): THeldJailCard;
begin
  Result.Card := ACard;
  Result.Deck := ADeck;
end;

{ TPlayer }

constructor TPlayer.Create(
  AId: integer;
  const AName: string
  );
begin
  inherited Create;
  Id := AId;
  Name := AName;
  Position := 0;
  Money := 1500;
  PropertyIds := TList<Integer>.Create;
  IsBankrupt := False;
  IsInJail := False;
  FailedJailRolls := 0;
  GetOutOfJailCards := TList<THeldJailCard>.Create;
end;

destructor TPlayer.Destroy;
begin
  GetOutOfJailCards.Free;
  PropertyIds.Free;
  inherited Destroy;
end;

procedure TPlayer.AcquireTile(Tile: TTile);
begin
  if Tile = nil then
  begin
    raise Exception.Create('Missing tile object.');
  end;

  Tile.OwnerId := Id;
  if not PropertyIds.Contains(Tile.Id) then
  begin
    PropertyIds.Add(Tile.Id);
  end;
end;

function TPlayer.CanAfford(Amount: integer): boolean;
begin
  Result := Money >= Amount;
end;

procedure TPlayer.ReleaseTile(Tile: TTile);
begin
  if Tile = nil then
  begin
    raise Exception.Create('Missing tile object.');
  end;

  if Tile.IsOwnedBy(Self) then
  begin
    Tile.OwnerId := NO_OWNER_ID;
  end;
  PropertyIds.Remove(Tile.Id);
end;

procedure TPlayer.TransferTileTo(
  Tile: TTile;
  Recipient: TPlayer
  );
begin
  if Recipient = nil then
  begin
    raise Exception.Create('Missing recipient player object.');
  end;

  if Recipient = Self then
  begin
    Exit;
  end;

  if Tile = nil then
  begin
    raise Exception.Create('Missing tile object.');
  end;

  if not Tile.IsOwnedBy(Self) then
  begin
    Exit;
  end;

  PropertyIds.Remove(Tile.Id);
  Recipient.AcquireTile(Tile);
end;

{ TTile }

constructor TTile.Create(
  AId: integer;
  const AName: string;
  ATileType: TTileType
  );
begin
  inherited Create;
  Id := AId;
  Name := AName;
  TileType := ATileType;
  OwnerId := NO_OWNER_ID;
  Houses := 0;
  HasHotel := False;
end;

function TTile.IsOwned: boolean;
begin
  Result := OwnerId <> NO_OWNER_ID;
end;

function TTile.IsOwnedBy(const Player: TPlayer): boolean;
begin
  Result := (Player <> nil) and (OwnerId = Player.Id);
end;

function TTile.IsOwnable: boolean;
begin
  Result := TileType in [ttProperty, ttRailroad, ttUtility];
end;

{ TDeck }

constructor TDeck.Create(
  const Cards: array of TMonopolyCard;
  ARandomIndex: TRandomIndexFunc
);
var
  Card: TMonopolyCard;
begin
  inherited Create;
  FCards := TList<TMonopolyCard>.Create;
  FDiscardedCards := TList<TMonopolyCard>.Create;
  FRandomIndex := ARandomIndex;

  for Card in Cards do
  begin
    FCards.Add(Card);
  end;
end;

destructor TDeck.Destroy;
begin
  FDiscardedCards.Free;
  FCards.Free;
  inherited Destroy;
end;

function TDeck.DiscardedCount: integer;
begin
  Result := FDiscardedCards.Count;
end;

function TDeck.DrawCard: TMonopolyCard;
begin
  if FCards.Count = 0 then
  begin
    ReshuffleDiscardedCards;
  end;

  if FCards.Count = 0 then
  begin
    raise Exception.Create('Deck is empty.');
  end;

  Result := FCards[0];
  FCards.Delete(0);
end;

function TDeck.RemainingCount: integer;
begin
  Result := FCards.Count;
end;

procedure TDeck.ReshuffleDiscardedCards;
var
  Card: TMonopolyCard;
begin
  if FDiscardedCards.Count = 0 then
  begin
    Exit;
  end;

  for Card in FDiscardedCards do
  begin
    FCards.Add(Card);
  end;
  FDiscardedCards.Clear;
  Shuffle;
end;

procedure TDeck.ReturnCard(const Card: TMonopolyCard);
begin
  FDiscardedCards.Add(Card);
end;

procedure TDeck.Shuffle;
var
  Index: integer;
  SwapIndex: integer;
  Temp: TMonopolyCard;
begin
  for Index := FCards.Count - 1 downto 1 do
  begin
    if Assigned(FRandomIndex) then
    begin
      SwapIndex := FRandomIndex(Index + 1);
    end
    else
    begin
      SwapIndex := Random(Index + 1);
    end;

    Temp := FCards[Index];
    FCards[Index] := FCards[SwapIndex];
    FCards[SwapIndex] := Temp;
  end;
end;

{ TDeckPair }

constructor TDeckPair.Create(
  AChance: TDeck;
  ACommunityChest: TDeck
  );
begin
  inherited Create;
  Chance := AChance;
  CommunityChest := ACommunityChest;
end;

destructor TDeckPair.Destroy;
begin
  CommunityChest.Free;
  Chance.Free;
  inherited Destroy;
end;

{ TGame }

constructor TGame.Create(
  APlayers: TObjectList<TPlayer>;
  ABoard: TObjectList<TTile>;
  ADecks: TDeckPair;
  ADiceRoller: TDiceRoller
);
begin
  inherited Create;
  Players := APlayers;
  Board := ABoard;
  Decks := ADecks;
  FDiceRoller := DefaultDiceRoll;
  CurrentPlayerId := 0;
  HasLastRoll := False;
end;

procedure TGame.AdjustPlayerMoney(
  Player: TPlayer;
  AmountDelta: integer
  );
begin
  if Player = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  Player.Money := Player.Money + AmountDelta;
end;

function TGame.CountActivePlayers: integer;
var
  Player: TPlayer;
begin
  Result := 0;
  for Player in Players do
  begin
    if not Player.IsBankrupt then
    begin
      Inc(Result);
    end;
  end;
end;

function TGame.CountOwnedTilesOfType(
  const Owner: TPlayer;
  ATileType: TTileType
): integer;
var
  Tile: TTile;
begin
  if not (ATileType in [ttUtility, ttRailroad]) then
  begin
    raise Exception.CreateFmt('Unsupported property type: %s', [TileTypeToText(ATileType)]);
  end;

  if Owner = nil then
  begin
    Exit(0);
  end;

  Result := 0;
  for Tile in Board do
  begin
    if (Tile.TileType = ATileType) and Tile.IsOwnedBy(Owner) then
    begin
      Inc(Result);
    end;
  end;
end;

function TGame.CurrentPlayer: TPlayer;
var
  Player: TPlayer;
begin
  Result := nil;
  for Player in Players do
  begin
    if Player.Id = CurrentPlayerId then
    begin
      Exit(Player);
    end;
  end;
end;

function TGame.CurrentTileOwner: TPlayer;
var
  Player: TPlayer;
begin
  Player := CurrentPlayer;
  if Player = nil then
  begin
    Exit(nil);
  end;

  Result := GetTileOwner(GetPlayerTile(Player));
end;

function TGame.DefaultDiceRoll: TDiceRoll;
begin
  Result := TDiceRoll.Create(Random(6) + 1, Random(6) + 1);
end;

destructor TGame.Destroy;
begin
  Decks.Free;
  Board.Free;
  Players.Free;
  inherited Destroy;
end;

function TGame.GetPlayerTile(APlayer: TPlayer): TTile;
begin
  if APlayer = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  if (APlayer.Position < 0) or (APlayer.Position >= Board.Count) then
  begin
    raise Exception.CreateFmt(
      'Player position has invalid value %d. Expected: [0..%d]',
      [APlayer.Position, Board.Count - 1]
    );
  end;

  Result := Board[APlayer.Position];
end;

function TGame.GetTileOwner(Tile: TTile): TPlayer;
var
  Candidate: TPlayer;
begin
  if (Tile = nil) or not Tile.IsOwned then
  begin
    Exit(nil);
  end;

  Result := nil;
  for Candidate in Players do
  begin
    if Tile.IsOwnedBy(Candidate) then
    begin
      Exit(Candidate);
    end;
  end;
end;

procedure TGame.Log(const Message: string);
begin
  if Assigned(OnLog) then
  begin
    OnLog(Message);
  end;
end;

function TGame.MovePlayerBy(
  Player: TPlayer;
  Steps: integer
  ): boolean;
var
  NewPosition: integer;
begin
  if Player = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  Result := (Steps > 0) and ((Player.Position + Steps) >= Board.Count);
  NewPosition := (Player.Position + Steps) mod Board.Count;
  if NewPosition < 0 then
  begin
    NewPosition := NewPosition + Board.Count;
  end;

  MovePlayerTo(Player, NewPosition);
end;

procedure TGame.MovePlayerTo(
  Player: TPlayer;
  Position: integer
  );
begin
  if Player = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  if (Position < 0) or (Position >= Board.Count) then
  begin
    raise Exception.CreateFmt('Invalid board position: %d', [Position]);
  end;

  Player.Position := Position;
end;

function TGame.NextActivePlayer: TPlayer;
var
  ActivePlayers: TList<TPlayer>;
  Player: TPlayer;
  CurrentIndex: integer;
  NextIndex: integer;
begin
  ActivePlayers := TList<TPlayer>.Create;
  try
    for Player in Players do
    begin
      if not Player.IsBankrupt then
      begin
        ActivePlayers.Add(Player);
      end;
    end;

    if ActivePlayers.Count = 0 then
    begin
      CurrentPlayerId := 0;
      Exit(nil);
    end;

    Result := CurrentPlayer;
    if Result = nil then
    begin
      CurrentPlayerId := ActivePlayers[0].Id;
      Exit(CurrentPlayer);
    end;

    CurrentIndex := ActivePlayers.IndexOf(Result);
    NextIndex := (CurrentIndex + 1) mod ActivePlayers.Count;
    CurrentPlayerId := ActivePlayers[NextIndex].Id;
    Result := CurrentPlayer;
  finally
    ActivePlayers.Free;
  end;
end;

function TGame.RollDice: TDiceRoll;
begin
  if Assigned(FDiceRoller) then
  begin
    Result := FDiceRoller();
  end
  else
  begin
    Result := DefaultDiceRoll();
  end;
end;

function TileTypeToText(ATileType: TTileType): string;
begin
  case ATileType of
    ttStart:
      Result := 'start';
    ttProperty:
      Result := 'property';
    ttChance:
      Result := 'chance';
    ttTax:
      Result := 'tax';
    ttJail:
      Result := 'jail';
    ttRailroad:
      Result := 'railroad';
    ttUtility:
      Result := 'utility';
    ttCommunityChest:
      Result := 'community-chest';
    ttFreeParking:
      Result := 'free-parking';
    ttGoToJail:
      Result := 'go-to-jail';
  else
    Result := 'unknown';
  end;
end;

end.
