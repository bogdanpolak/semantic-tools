unit Monopoly.GameReport;

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

  IGameReportItem = interface
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

  TGameReportItems = TArray<IGameReportItem>;

  IGameReport = interface
    ['{66B21296-30F6-4CEB-B498-140A55E18A1B}']
    function CurrentPlayerName: string;
    function Status: TGameState;
    function Items: TGameReportItems;
    function Rounds: integer;
    function Turns: integer;
  end;

function GetGameReport(Game: TGame): IGameReport;

implementation

type
  TGameStatusItem = class(TInterfacedObject, IGameReportItem)
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

  TGameStatus = class(TInterfacedObject, IGameReport)
  private
    FItems: TGameReportItems;
    FTurnNumber: integer;
    FRoundNumber: integer;
    FMaxRounds: integer;
    FCurrentPlayerName: string;
    FStatus: TGameState;
    FPlayerMoneyComparer: IComparer<TPlayer>;
    FTileComparer: IComparer<TTile>;
    function BuildPropertyList(
      const Player: TPlayer;
      const ABoard: TBoard
      ): string;
    function BuildGameStatusItems(Game: TGame): TGameReportItems;
  public
    constructor Create(Game: TGame);
    function CurrentPlayerName: string;
    function Status: TGameState;
    function Items: TGameReportItems;
    function Rounds: integer;
    function Turns: integer;
  end;

function TGameStatus.BuildPropertyList(
  const Player: TPlayer;
  const ABoard: TBoard
  ): string;
var
  Id: integer;
  PlayerCards: TList<TTile>;
  PrevoiusCategory: string;
  TileCategory: string;
begin
  if (Player.PropertyIds.Count = 0) then
    Exit('');

  Result := '';
  PlayerCards := TList<TTile>.Create();
  try
    for Id in Player.PropertyIds do
    begin
      PlayerCards.Add(ABoard.TileById(Id));
    end;

    PlayerCards.Sort(FTileComparer);

    PrevoiusCategory := '';
    for var Tile in PlayerCards do
    begin
      if Tile.TileType = ttRailroad then
      begin
        TileCategory := 'Railroad'
      end
      else if Tile.TileType = ttUtility then
      begin
        TileCategory := 'Utility'
      end
      else
        TileCategory := Format('Property(%s)',[Tile.Color]);
      var Separator := IfThen(PrevoiusCategory<>TileCategory, ' | ', ', ');
      PrevoiusCategory := TileCategory;
      if Result <> '' then
      begin
        Result := Result + Separator;
      end;
      Result := Result + IntToStr(Tile.Id);
    end;

  finally
    PlayerCards.Free;
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

function TGameStatus.BuildGameStatusItems(Game: TGame): TGameReportItems;
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

    SortedPlayers.Sort(FPlayerMoneyComparer);

    SetLength(Result, SortedPlayers.Count);

    for Index := 0 to SortedPlayers.Count - 1 do
    begin
      Player := SortedPlayers[Index];
      if (Game.Status = gsFinished) and (Player.Money = MaxMoney) then
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
        BuildPropertyList(Player, Game.Board),
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
  FPlayerMoneyComparer := TComparer<TPlayer>.Construct(
      function(const Left, Right: TPlayer): Integer
      begin
        Result := Right.Money - Left.Money;
      end
    );
  FTileComparer := TComparer<TTile>.Construct(
      function(const Left, Right: TTile): Integer
      begin
        var LeftValue :=
          IfThen(Left.TileType = ttRailroad, Left.Id,
          IfThen(Left.TileType = ttUtility, 100+Left.Id,
            200+Left.id));
        var RightValue :=
          IfThen(Right.TileType = ttRailroad, Right.Id,
          IfThen(Right.TileType = ttUtility, 100+Right.Id,
            200+Right.id));
        Result := LeftValue - RightValue;
      end
    );

  Player := Game.CurrentPlayer;

  FItems := BuildGameStatusItems(Game);
  FTurnNumber := Game.TurnNumber;
  FRoundNumber := Game.RoundNumber;
  FMaxRounds := Game.MaxRounds;
  If Player <> nil then
  begin
    FCurrentPlayerName := Player.Name;
  end;
  FStatus := Game.Status;
end;

function TGameStatus.CurrentPlayerName: string;
begin
  Result := FCurrentPlayerName;
end;

function TGameStatus.Status: TGameState;
begin
  Result := FStatus;
end;

function TGameStatus.Items: TGameReportItems;
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

function GetGameReport(Game: TGame): IGameReport;
begin
  if Game = nil then
  begin
    raise Exception.Create('Uninitialized game object.');
  end;

  Result := TGameStatus.Create(Game);
end;

end.