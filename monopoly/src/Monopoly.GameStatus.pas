unit Monopoly.GameStatus;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  Monopoly.Types;

type
  TPlayerStatus = (psWinner, psActive, psBankrupt);

  IGameStatusItem = interface
    ['{4EFB1C51-36B0-4A2E-8B7A-74F8C2BDB60D}']
    function PlayerStatus: TPlayerStatus;
    function PlayerName: string;
    function Money: integer;
    function FormattedMoney: string;
    function HotelCount: integer;
    function HouseCount: integer;
    function PropertyCount: integer;
    function PropertyList: string;
  end;

  TGameStatusItems = TArray<IGameStatusItem>;

  IGameStatus = interface
    ['{66B21296-30F6-4CEB-B498-140A55E18A1B}']
    function CurrentPlayerName: string;
    function IsGameActive: boolean;
    function Items: TGameStatusItems;
    function Rounds: integer;
    function Turns: integer;
  end;

function GetGameStatus(Game: TGame): IGameStatus;

implementation

type
  TGameStatusItem = class(TInterfacedObject, IGameStatusItem)
  private
    FPlayerStatus: TPlayerStatus;
    FPlayerName: string;
    FMoney: integer;
    FPropertyCount: integer;
    FPropertyList: string;
    FHouseCount: integer;
    FHotelCount: integer;
    FFormatSetings: TFormatSettings;
  public
    constructor Create(
      const APlayerStatus: TPlayerStatus;
      const APlayerName: string;
      const AMoney: integer;
      const APropertyCount: integer;
      const APropertyList: string;
      AHouseCount: integer;
      AHotelCount: integer
      );
    function PlayerStatus: TPlayerStatus;
    function PlayerName: string;
    function Money: integer;
    function FormattedMoney: string;
    function HotelCount: integer;
    function HouseCount: integer;
    function PropertyCount: integer;
    function PropertyList: string;
  end;

  TGameStatus = class(TInterfacedObject, IGameStatus)
  private
    FItems: TGameStatusItems;
    FTurnNumber: integer;
    FRoundNumber: integer;
    FMaxRounds: integer;
    FCurrentPlayerName: string;
    FIsGameActive: boolean;
  public
    constructor Create(Game: TGame);
    function CurrentPlayerName: string;
    function IsGameActive: boolean;
    function Items: TGameStatusItems;
    function Rounds: integer;
    function Turns: integer;
  end;

function BuildPropertyList(const Player: TPlayer): string;
var
  PropertyId: integer;
begin
  Result := '';
  for PropertyId in Player.PropertyIds do
  begin
    if Result <> '' then
    begin
      Result := Result + ', ';
    end;
    Result := Result + IntToStr(PropertyId);
  end;
end;

constructor TGameStatusItem.Create(
  const APlayerStatus: TPlayerStatus;
  const APlayerName: string;
  const AMoney: integer;
  const APropertyCount: integer;
  const APropertyList: string;
  AHouseCount: integer;
  AHotelCount: integer
  );
begin
  inherited Create;
  FPlayerStatus := APlayerStatus;
  FPlayerName := APlayerName;
  FMoney := AMoney;
  FPropertyCount := APropertyCount;
  FPropertyList := APropertyList;
  FHouseCount := AHouseCount;
  FHotelCount := AHotelCount;
  FFormatSetings := TFormatSettings.Create;
end;

function TGameStatusItem.HotelCount: integer;
begin
  Result := FHotelCount;
end;

function TGameStatusItem.HouseCount: integer;
begin
  Result := FHouseCount;
end;

function TGameStatusItem.Money: integer;
begin
  Result := FMoney;
end;

function TGameStatusItem.FormattedMoney: string;
begin
  Result := Format('$%.0n', [FMoney*1.0], FFormatSetings)
end;

function TGameStatusItem.PlayerName: string;
begin
  Result := FPlayerName;
end;

function TGameStatusItem.PlayerStatus: TPlayerStatus;
begin
  Result := FPlayerStatus;
end;

function TGameStatusItem.PropertyCount: integer;
begin
  Result := FPropertyCount;
end;

function TGameStatusItem.PropertyList: string;
begin
  Result := FPropertyList;
end;

function CreateGameStatusItems(Game: TGame): TGameStatusItems;
var
  Player: TPlayer;
  MaxMoney: integer;
  SortedPlayers: TList<TPlayer>;
  Index: integer;
  PlayerStatus: TPlayerStatus;
begin
  MaxMoney := Low(Integer);
  for Player in Game.Players do
  begin
    if Player.Money > MaxMoney then
    begin
      MaxMoney := Player.Money;
    end;
  end;

  SortedPlayers := TList<TPlayer>.Create;
  try
    for Player in Game.Players do
    begin
      SortedPlayers.Add(Player);
    end;

    SortedPlayers.Sort(
      TComparer<TPlayer>.Construct(
        function(const Left, Right: TPlayer): Integer
        begin
          Result := Right.Money - Left.Money;
        end
      )
    );

    SetLength(Result, SortedPlayers.Count);

    for Index := 0 to SortedPlayers.Count - 1 do
    begin
      Player := SortedPlayers[Index];
      if Player.Money = MaxMoney then
        PlayerStatus := psWinner
      else if Player.IsBankrupt then
        PlayerStatus := psBankrupt
      else
        PlayerStatus :=  psActive;

      Result[Index] := TGameStatusItem.Create(
        PlayerStatus,
        Player.Name,
        Player.Money,
        Player.PropertyIds.Count,
        BuildPropertyList(Player),
        Game.Board.CountHousesOwnedBy(Player),
        Game.Board.CountHotelsOwnedBy(Player)
      );
    end;
  finally
    SortedPlayers.Free;
  end;
end;

constructor TGameStatus.Create(Game: TGame);
var
  Player: TPlayer;
begin
  inherited Create;
  Player := Game.CurrentPlayer;

  FItems := CreateGameStatusItems(Game);
  FTurnNumber := Game.TurnNumber;
  FRoundNumber := Game.RoundNumber;
  FMaxRounds := Game.MaxRounds;
  If Player <> nil then
  begin
    FCurrentPlayerName := Player.Name;
  end;
  FIsGameActive := Game.IsGameActive;
end;

function TGameStatus.CurrentPlayerName: string;
begin
  Result := FCurrentPlayerName;
end;

function TGameStatus.IsGameActive: boolean;
begin
  Result := FIsGameActive;
end;

function TGameStatus.Items: TGameStatusItems;
begin
  Result := FItems;
end;

function TGameStatus.Rounds: integer;
begin
  Result := FRoundNumber;
end;

function TGameStatus.Turns: integer;
begin
  Result := FTurnNumber;
end;

function GetGameStatus(Game: TGame): IGameStatus;
begin
  if Game = nil then
  begin
    raise Exception.Create('Uninitialized game object.');
  end;

  Result := TGameStatus.Create(Game);
end;

end.