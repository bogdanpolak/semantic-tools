unit Monopoly.LandingHandlers;

interface

uses
  Monopoly.Types;

type
  ILandingRule = interface
    ['{D5A9E93E-7A05-4BCE-90B0-A7B3F661A5B5}']
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      );
  end;

function CreateLandingRules: TArray<ILandingRule>;
procedure ExecuteLandingRules(
  Game: TGame;
  const Options: TRentOptions
  );
procedure HandleLandingGoToJail(Game: TGame);
procedure HandleLandingPayTax(Game: TGame);
procedure HandleLandingBuyOrTrade(Game: TGame);

implementation

uses
  System.SysUtils,
  Monopoly.Rules.Cards,
  Monopoly.Rules.Jail,
  Monopoly.Rules.Rent,
  Monopoly.Utils;

type
  TBaseLandingRule = class(TInterfacedObject, ILandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; virtual; abstract;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); virtual; abstract;
  end;

  TGoToJailLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

  TTaxLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

  TBuyPropertyLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

  TPayRentLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

  TChanceLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

  TCommunityChestLandingRule = class(TBaseLandingRule)
  public
    function AppliesTo(
      Tile: TTile;
      Player: TPlayer
      ): boolean; override;
    procedure Execute(
      Game: TGame;
      const Options: TRentOptions
      ); override;
  end;

procedure HandleLandingBuyOrTrade(Game: TGame);
var
  Player: TPlayer;
  Tile: TTile;
begin
  Player := Game.CurrentPlayer;
  Tile := Game.GetPlayerTile(Player);

  Game.Log(Format('%s is available for $%d', [Tile.Name, Tile.Price]));
  if not Player.CanAfford(Tile.Price) then
  begin
    Game.Log(Format('%s does not have enough money to buy %s.', [Player.Name, Tile.Name]));
    Exit;
  end;

  Game.AdjustPlayerMoney(Player, -Tile.Price);
  Player.AcquireTile(Tile);
  Game.Log(Format('%s bought %s for $%d.', [Player.Name, Tile.Name, Tile.Price]));
end;

procedure HandleLandingGoToJail(Game: TGame);
var
  Player: TPlayer;
  Tile: TTile;
begin
  Player := Game.CurrentPlayer;
  Tile := Game.GetPlayerTile(Player);
  if Tile.TileType <> ttGoToJail then
  begin
    Exit;
  end;

  Game.Log(Format('%s is sent to jail for landing on Go To Jail.', [Player.Name]));
  SendCurrentPlayerToJail(Game);
end;

procedure HandleLandingPayTax(Game: TGame);
var
  Player: TPlayer;
  Tile: TTile;
  AmountPaid: integer;
begin
  Player := Game.CurrentPlayer;
  Tile := Game.GetPlayerTile(Player);
  AmountPaid := ChargePlayer(Player, Tile.Amount, Game.Board, Game.OnLog);
  Game.Log(Format('%s landed on %s and lost $%d', [Player.Name, Tile.Name, AmountPaid]));
end;

function TGoToJailLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := Tile.TileType = ttGoToJail;
end;

procedure TGoToJailLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandleLandingGoToJail(Game);
end;

function TTaxLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := Tile.TileType = ttTax;
end;

procedure TTaxLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandleLandingPayTax(Game);
end;

function TBuyPropertyLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := not Tile.IsOwned and (Tile.Price > 0);
end;

procedure TBuyPropertyLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandleLandingBuyOrTrade(Game);
end;

function TPayRentLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := Tile.IsOwned and not Tile.IsOwnedBy(Player);
end;

procedure TPayRentLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandlePayRent(Game, Options);
end;

function TChanceLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := Tile.TileType = ttChance;
end;

procedure TChanceLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandleChanceCard(Game,
    procedure(RecursiveGame: TGame; const RecursiveOptions: TRentOptions)
    begin
      ExecuteLandingRules(RecursiveGame, RecursiveOptions);
    end);
end;

function TCommunityChestLandingRule.AppliesTo(
  Tile: TTile;
  Player: TPlayer
  ): boolean;
begin
  Result := Tile.TileType = ttCommunityChest;
end;

procedure TCommunityChestLandingRule.Execute(
  Game: TGame;
  const Options: TRentOptions
  );
begin
  HandleCommunityChestCard(Game,
    procedure(RecursiveGame: TGame; const RecursiveOptions: TRentOptions)
    begin
      ExecuteLandingRules(RecursiveGame, RecursiveOptions);
    end);
end;

function CreateLandingRules: TArray<ILandingRule>;
begin
  Result := [
    TGoToJailLandingRule.Create,
    TTaxLandingRule.Create,
    TBuyPropertyLandingRule.Create,
    TPayRentLandingRule.Create,
    TChanceLandingRule.Create,
    TCommunityChestLandingRule.Create
  ];
end;

procedure ExecuteLandingRules(
  Game: TGame;
  const Options: TRentOptions
  );
var
  CurrentPlayer: TPlayer;
  Tile: TTile;
  Rule: ILandingRule;
begin
  for Rule in CreateLandingRules do
  begin
    CurrentPlayer := Game.CurrentPlayer;
    Tile := Game.GetPlayerTile(CurrentPlayer);
    if Rule.AppliesTo(Tile, CurrentPlayer) then
    begin
      Rule.Execute(Game, Options);

      if CurrentPlayer.Money < 0 then
      begin
        MarkPlayerBankrupt(CurrentPlayer, Game.Board, nil, Game.OnLog);
      end;

      if CurrentPlayer.IsInJail or CurrentPlayer.IsBankrupt then
      begin
        Exit;
      end;

      if Tile.TileType in [ttChance, ttCommunityChest] then
      begin
        Exit;
      end;
    end;
  end;
end;

end.