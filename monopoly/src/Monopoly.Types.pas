unit Monopoly.Types;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

const
  NO_OWNER_ID = 0;

type
  TTile = class;
  TGame = class;

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
  TLogEvent = reference to procedure(const Message: string);

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
    Mortgaged: boolean;
    constructor Create(
      AId: integer;
      const AName: string;
      ATileType: TTileType
      );
    function IsOwned: boolean;
    function IsOwnedBy(const Player: TPlayer): boolean;
    function IsOwnable: boolean;
  end;

  TBoard = class(TObjectList<TTile>)
  private
    FGame: TGame;
    procedure RequireGameContext;
  public
    procedure AttachGame(AGame: TGame);
    function CountHotelsOwnedBy(const Player: TPlayer): integer;
    function CountHousesOwnedBy(const Player: TPlayer): integer;
    function CountOwnedTilesOfType(
      const Owner: TPlayer;
      ATileType: TTileType
      ): integer;
    function CountTilesInColorGroup(Tile: TTile): integer;
    function CurrentPlayerTileOwner: TPlayer;
    function FindTilePositionByName(const TileName: string): integer;
    function TileById(TileId: integer): TTile;
    function TileAtPlayerPosition(APlayer: TPlayer): TTile;
    function TileAtPosition(Position: integer): TTile;
    function OwnerOfTile(Tile: TTile): TPlayer;
    function AreColorGroupTilesOwnedBy(
      Tile: TTile;
      const Owner: TPlayer
      ): boolean;
    function HasBuildingsInColorGroup(
      Tile: TTile;
      const Owner: TPlayer
      ): boolean;
    function HasPropertyMonopoly(
      Tile: TTile;
      const Owner: TPlayer
      ): boolean;
    function LowestHouseCountInColorGroup(
      Tile: TTile;
      const Owner: TPlayer
      ): integer;
    function IsColorGroupFullyBuilt(
      Tile: TTile;
      const Owner: TPlayer
      ): boolean;
    function ActivePlayersExcept(const ExcludedPlayer: TPlayer): TArray<TPlayer>;
  end;

  TDeck = class
  private
    FShuffleCards: Boolean;
    FCards: TList<TMonopolyCard>;
    FDiscardedCards: TList<TMonopolyCard>;
    procedure ReshuffleDiscardedCards;
    procedure Shuffle;
  public
    constructor Create(
      const ACards: array of TMonopolyCard;
      const AShuffleCards: boolean = True
      );
    destructor Destroy; override;
    function DrawCard: TMonopolyCard;
    procedure ReturnCard(const Card: TMonopolyCard);
    function RemainingCount: integer;
    function DiscardedCount: integer;
  end;

  TGame = class
  private
    FDiceRoller: TDiceRoller;
    FPlayers: TObjectList<TPlayer>;
    FBoard: TBoard;
    FChanceDeck: TDeck;
    FCommunityChestDeck: TDeck;
    FCurrentPlayerId: integer;
    FLastRoll: TDiceRoll;
    FHasLastRoll: boolean;
    FTurnNumber: integer;
    FRoundNumber: integer;
    FMaxRounds: integer;
    FTermiantionReason: string;
    FIsGameActive: boolean;
    FOnLog: TLogEvent;
    function DefaultDiceRoll: TDiceRoll;
  public
    constructor Create();
    destructor Destroy; override;
    procedure StartGame(
      const APlayerNames: array of string;
      const AMaxRounds: integer;
      const AShuffleCards: boolean = true
      );
    procedure PayBank(
      const APlayer: TPlayer;
      const AAmount: integer
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
    function GetActivePlayerIds(): TArray<integer>;
    function NextTurn: boolean;
    function CountOwnedTilesOfType(
      const Owner: TPlayer;
      ATileType: TTileType
    ): integer;
    function GetPlayerById(const Id: integer): TPlayer;
    function CurrentPlayerTileOwner: TPlayer;
    function TileAtPlayerPosition(APlayer: TPlayer): TTile;
    function OwnerOfTile(const Tile: TTile): TPlayer;
    procedure ClearLastRoll();
    procedure SetLastRoll(const ARoll: TDiceRoll);
    procedure SetDecks(const AChanceCards,
      ACommunityChestCards: array of TMonopolyCard);
    // -
    property DiceRoller: TDiceRoller read FDiceRoller write FDiceRoller;
    property Players: TObjectList<TPlayer> read FPlayers write FPlayers;
    property Board: TBoard read FBoard;
    property ChanceDeck: TDeck read FChanceDeck;
    property CommunityChestDeck: TDeck read FCommunityChestDeck;
    property CurrentPlayerId: integer read FCurrentPlayerId;
    property HasLastRoll: boolean read FHasLastRoll;
    property LastRoll: TDiceRoll read FLastRoll;
    property TurnNumber: integer read FTurnNumber;
    property RoundNumber: integer read FRoundNumber;
    property MaxRounds: integer read FMaxRounds;
    property TermiantionReason: string read FTermiantionReason;
    property IsGameActive: boolean read FIsGameActive;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

function TileTypeToText(ATileType: TTileType): string;

implementation

uses
  Monopoly.Factories;

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
  Mortgaged := False;
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

{ TBoard }

procedure TBoard.AttachGame(AGame: TGame);
begin
  FGame := AGame;
end;

function TBoard.CountOwnedTilesOfType(
  const Owner: TPlayer;
  ATileType: TTileType
  ): integer;
var
  Tile: TTile;
begin
  if not (ATileType in [ttUtility, ttRailroad]) then
  begin
    raise Exception.CreateFmt(
      'Unsupported property type: %s',
      [TileTypeToText(ATileType)]
    );
  end;

  if Owner = nil then
  begin
    Exit(0);
  end;

  Result := 0;
  for Tile in Self do
  begin
    if (Tile.TileType = ATileType) and Tile.IsOwnedBy(Owner) then
    begin
      Inc(Result);
    end;
  end;
end;

function TBoard.CountTilesInColorGroup(Tile: TTile): integer;
var
  Candidate: TTile;
begin
  Result := 0;
  if (Tile = nil) or (Tile.Color = '') then
  begin
    Exit;
  end;

  for Candidate in Self do
  begin
    if Candidate.Color = Tile.Color then
    begin
      Inc(Result);
    end;
  end;
end;

function TBoard.CountHotelsOwnedBy(const Player: TPlayer): integer;
var
  PropertyId: integer;
  Tile: TTile;
begin
  Result := 0;
  if Player = nil then
  begin
    Exit;
  end;

  for PropertyId in Player.PropertyIds do
  begin
    Tile := TileById(PropertyId);
    if Tile.HasHotel then
    begin
      Inc(Result);
    end;
  end;
end;

function TBoard.CountHousesOwnedBy(const Player: TPlayer): integer;
var
  PropertyId: integer;
  Tile: TTile;
begin
  Result := 0;
  if Player = nil then
  begin
    Exit;
  end;

  for PropertyId in Player.PropertyIds do
  begin
    Tile := TileById(PropertyId);
    Inc(Result, Tile.Houses);
  end;
end;

function TBoard.CurrentPlayerTileOwner: TPlayer;
begin
  RequireGameContext;
  if FGame.CurrentPlayer = nil then
  begin
    Exit(nil);
  end;

  Result := OwnerOfTile(TileAtPlayerPosition(FGame.CurrentPlayer));
end;

function TBoard.FindTilePositionByName(const TileName: string): integer;
var
  Index: integer;
begin
  for Index := 0 to Count - 1 do
  begin
    if SameText(Items[Index].Name, TileName) then
    begin
      Exit(Index);
    end;
  end;

  raise Exception.CreateFmt('Unknown board location: %s', [TileName]);
end;

function TBoard.TileById(TileId: integer): TTile;
var
  Candidate: TTile;
begin
  if (TileId >= 0) and (TileId < Count) and (Items[TileId].Id = TileId) then
  begin
    Exit(Items[TileId]);
  end;

  for Candidate in Self do
  begin
    if Candidate.Id = TileId then
    begin
      Exit(Candidate);
    end;
  end;

  raise Exception.CreateFmt('Unknown tile id: %d', [TileId]);
end;

function TBoard.TileAtPlayerPosition(APlayer: TPlayer): TTile;
begin
  if APlayer = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  if (APlayer.Position < 0) or (APlayer.Position >= Count) then
  begin
    raise Exception.CreateFmt(
      'Player position has invalid value %d. Expected: [0..%d]',
      [APlayer.Position, Count - 1]
    );
  end;

  Result := Items[APlayer.Position];
end;

function TBoard.TileAtPosition(Position: integer): TTile;
begin
  if (Position < 0) or (Position >= Count) then
  begin
    raise Exception.CreateFmt('Invalid board position: %d', [Position]);
  end;

  Result := Items[Position];
end;

function TBoard.OwnerOfTile(Tile: TTile): TPlayer;
var
  Candidate: TPlayer;
begin
  RequireGameContext;
  if (Tile = nil) or not Tile.IsOwned then
  begin
    Exit(nil);
  end;

  Result := nil;
  for Candidate in FGame.Players do
  begin
    if Tile.IsOwnedBy(Candidate) then
    begin
      Exit(Candidate);
    end;
  end;
end;

function TBoard.AreColorGroupTilesOwnedBy(
  Tile: TTile;
  const Owner: TPlayer
  ): boolean;
var
  Candidate: TTile;
begin
  Result := False;
  if (Tile = nil) or (Owner = nil) or (Tile.Color = '') then
  begin
    Exit;
  end;

  for Candidate in Self do
  begin
    if Candidate.Color = Tile.Color then
    begin
      if not Candidate.IsOwnedBy(Owner) then
      begin
        Exit(False);
      end;
    end;
  end;

  Result := CountTilesInColorGroup(Tile) > 0;
end;

function TBoard.HasBuildingsInColorGroup(
  Tile: TTile;
  const Owner: TPlayer
  ): boolean;
var
  Candidate: TTile;
begin
  Result := False;
  if (Tile = nil) or (Owner = nil) or (Tile.Color = '') then
  begin
    Exit;
  end;

  for Candidate in Self do
  begin
    if (Candidate.Color = Tile.Color) and Candidate.IsOwnedBy(Owner) and ((Candidate.Houses > 0) or Candidate.HasHotel) then
    begin
      Exit(True);
    end;
  end;
end;

function TBoard.HasPropertyMonopoly(
  Tile: TTile;
  const Owner: TPlayer
  ): boolean;
begin
  Result := AreColorGroupTilesOwnedBy(Tile, Owner);
end;

function TBoard.LowestHouseCountInColorGroup(
  Tile: TTile;
  const Owner: TPlayer
  ): integer;
var
  Candidate: TTile;
  HasValue: boolean;
begin
  Result := 0;
  HasValue := False;
  if not AreColorGroupTilesOwnedBy(Tile, Owner) then
  begin
    Exit(-1);
  end;

  for Candidate in Self do
  begin
    if (Candidate.Color = Tile.Color) and Candidate.IsOwnedBy(Owner) then
    begin
      if not HasValue or (Candidate.Houses < Result) then
      begin
        Result := Candidate.Houses;
        HasValue := True;
      end;
    end;
  end;

  if not HasValue then
  begin
    Exit(-1);
  end;
end;

function TBoard.IsColorGroupFullyBuilt(
  Tile: TTile;
  const Owner: TPlayer
  ): boolean;
var
  Candidate: TTile;
begin
  Result := False;
  if not AreColorGroupTilesOwnedBy(Tile, Owner) then
  begin
    Exit;
  end;

  for Candidate in Self do
  begin
    if Candidate.Color = Tile.Color then
    begin
      if Candidate.Mortgaged or Candidate.HasHotel or (Candidate.Houses <> 4) then
      begin
        Exit(False);
      end;
    end;
  end;

  Result := True;
end;

function TBoard.ActivePlayersExcept(const ExcludedPlayer: TPlayer): TArray<TPlayer>;
var
  Player: TPlayer;
  Count: integer;
begin
  RequireGameContext;
  Count := 0;
  for Player in FGame.Players do
  begin
    if (Player <> nil) and not Player.IsBankrupt and ((ExcludedPlayer = nil) or (Player.Id <> ExcludedPlayer.Id)) then
    begin
      Inc(Count);
    end;
  end;

  SetLength(Result, Count);
  Count := 0;
  for Player in FGame.Players do
  begin
    if (Player <> nil) and not Player.IsBankrupt and ((ExcludedPlayer = nil) or (Player.Id <> ExcludedPlayer.Id)) then
    begin
      Result[Count] := Player;
      Inc(Count);
    end;
  end;
end;

procedure TBoard.RequireGameContext;
begin
  if FGame = nil then
  begin
    raise Exception.Create('Board must be attached to a game.');
  end;
end;

{ TDeck }

constructor TDeck.Create(
  const ACards: array of TMonopolyCard;
  const AShuffleCards: boolean = True
  );
begin
  FShuffleCards := AShuffleCards;
  inherited Create;
  FCards := TList<TMonopolyCard>.Create(ACards);
  FDiscardedCards := TList<TMonopolyCard>.Create;
  Shuffle;
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
  if (FDiscardedCards.Count = 0) then
    Exit;

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
  if not(FShuffleCards) then
    Exit;

  for Index := FCards.Count - 1 downto 1 do
  begin
    SwapIndex := Random(Index + 1);

    Temp := FCards[Index];
    FCards[Index] := FCards[SwapIndex];
    FCards[SwapIndex] := Temp;
  end;
end;

{ TGame }

constructor TGame.Create();
begin
  inherited Create;
  FBoard := CreateBoard;
  FChanceDeck := TDeck.Create(BuildChanceCards);
  FCommunityChestDeck := TDeck.Create(BuildCommunityChestCards);
  FPlayers := TObjectList<TPlayer>.Create;
  FBoard.AttachGame(Self);
  FDiceRoller := DefaultDiceRoll;
  FCurrentPlayerId := -1;
  FHasLastRoll := False;
  FTurnNumber := 0;
  FRoundNumber := 0;
  FIsGameActive := False;
end;

destructor TGame.Destroy;
begin
  FBoard.AttachGame(nil);

  FreeAndNil(FChanceDeck);
  FreeAndNil(FCommunityChestDeck);
  FreeAndNil(FBoard);
  FreeAndNil(FPlayers);

  inherited Destroy;
end;

procedure TGame.StartGame(
  const APlayerNames: array of string;
  const AMaxRounds: integer;
  const AShuffleCards: boolean = true
  );
var
  PlayerId: integer;
  Name: string;
begin
  FMaxRounds := AMaxRounds;
  FTurnNumber := 1;
  FRoundNumber := 1;
  FIsGameActive := True;

  if (AShuffleCards) then
  begin
    FChanceDeck.Shuffle;
    FCommunityChestDeck.Shuffle;
  end;

  FCurrentPlayerId := 1;
  PlayerId := 1;
  FPlayers.Clear;
  for Name in APlayerNames do
  begin
    FPlayers.Add(TPlayer.Create(PlayerId, Name));
    Inc(PlayerId);
  end;
end;

procedure TGame.PayBank(
  const APlayer: TPlayer;
  const AAmount: integer
  );
begin
  if APlayer = nil then
  begin
    raise Exception.Create('Missing player object.');
  end;

  if AAmount <= 0 then
  begin
    raise Exception.Create('Payment has to postive');
  end;

  APlayer.Money := APlayer.Money - AAmount;
end;

function TGame.CountActivePlayers: integer;
var
  Player: TPlayer;
begin
  Result := 0;
  for Player in FPlayers do
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
begin
  Result := FBoard.CountOwnedTilesOfType(Owner, ATileType);
end;

function TGame.CurrentPlayer: TPlayer;
var
  Player: TPlayer;
begin
  Result := nil;
  for Player in FPlayers do
  begin
    if Player.Id = FCurrentPlayerId then
    begin
      Exit(Player);
    end;
  end;
end;

function TGame.CurrentPlayerTileOwner: TPlayer;
begin
  Result := FBoard.CurrentPlayerTileOwner;
end;

function TGame.DefaultDiceRoll: TDiceRoll;
begin
  Result := TDiceRoll.Create(Random(6) + 1, Random(6) + 1);
end;

function TGame.TileAtPlayerPosition(APlayer: TPlayer): TTile;
begin
  Result := FBoard.TileAtPlayerPosition(APlayer);
end;

function TGame.OwnerOfTile(const Tile: TTile): TPlayer;
begin
  Result := FBoard.OwnerOfTile(Tile);
end;

procedure TGame.ClearLastRoll();
begin
  FHasLastRoll := False;
  FLastRoll := TDiceRoll.Create(0,0);
end;

procedure TGame.SetLastRoll(const ARoll: TDiceRoll);
begin
  FHasLastRoll := True;
  FLastRoll := ARoll;
end;

procedure TGame.SetDecks(
  const AChanceCards: array of TMonopolyCard;
  const ACommunityChestCards: array of TMonopolyCard
  );
begin
  FreeAndNil(FChanceDeck);
  FreeAndNil(FCommunityChestDeck);
  FChanceDeck := TDeck.Create(AChanceCards);
  FCommunityChestDeck := TDeck.Create(ACommunityChestCards);
end;

procedure TGame.Log(const Message: string);
begin
  if Assigned(FOnLog) then
  begin
    FOnLog(Message);
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

  Result := (Steps > 0) and ((Player.Position + Steps) >= FBoard.Count);
  NewPosition := (Player.Position + Steps) mod FBoard.Count;
  if NewPosition < 0 then
  begin
    NewPosition := NewPosition + FBoard.Count;
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

  if (Position < 0) or (Position >= FBoard.Count) then
  begin
    raise Exception.CreateFmt('Invalid board position: %d', [Position]);
  end;

  Player.Position := Position;
end;

function TGame.GetActivePlayerIds(): TArray<integer>;
var
  ActivePlayers: TList<integer>;
  Player: TPlayer;
begin
  ActivePlayers := TList<integer>.Create;
  try
    for Player in FPlayers do
    begin
      if not Player.IsBankrupt then
      begin
        ActivePlayers.Add(Player.Id);
      end;
    end;
    Result := ActivePlayers.ToArray;
  finally
    ActivePlayers.Free;
  end;
end;

function TGame.GetPlayerById(const Id: integer): TPlayer;
begin
  for var Player in Players do
    if Player.Id = Id then
      Exit(Player);
  Result := nil;
end;

function TGame.NextTurn: boolean;
var
  ActivePlayerIds: array of integer;
  Count: integer;
  // Idx: Integer;
  IsActive: boolean;
  IsActivePlayerLocated: boolean;
  NextPlayerId: integer;
begin
  if FRoundNumber >= FMaxRounds then
  begin
    FIsGameActive := False;
    FTermiantionReason := Format('Reached maximum number of rounds: %d. Ending game.', [MaxRounds]);
    Exit(False);
  end;

  ActivePlayerIds := GetActivePlayerIds();
  Count := Length(ActivePlayerIds);
  if Count = 0 then
  begin
    raise Exception.Create('All players are bankrupt');
  end;

  if Count = 1 then
  begin
    var Player := GetPlayerById(ActivePlayerIds[0]);
    FTermiantionReason := Format('%s wins the game.', [Player.Name]);
    FIsGameActive := False;
    Exit(False);
  end;

  // Find Next Active Player with wrap (increment round when wrapped)
  IsActivePlayerLocated := False;
  NextPlayerId := -1;
  for var Player in FPlayers do
  begin
    IsActive := TArray.Contains<Integer>(ActivePlayerIds, Player.Id);
    if Player.Id = FCurrentPlayerId then
    begin
      IsActivePlayerLocated := true;
    end
    else if IsActivePlayerLocated and IsActive then
    begin
      NextPlayerId := Player.Id;
      Break;
    end;
  end;
  if NextPlayerId = -1 then
  begin
    NextPlayerId := ActivePlayerIds[0];
    Inc(FRoundNumber);
  end;
  Inc(FTurnNumber);
  FCurrentPlayerId := NextPlayerId;
  Result := True;
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
