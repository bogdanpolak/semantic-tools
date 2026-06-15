unit Monopoly.Rules.Landing;

interface

uses
  System.SysUtils,
  Monopoly.Transactions,
  Monopoly.Types;

procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService
  ); overload;
procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService;
  const Options: TRentOptions
  ); overload;

implementation

procedure ExecuteLandingRules(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  ); forward;


procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService
  );
begin
  ExecuteLandingRules(
    Game,
    Transactions,
    TRentOptions.None
  );
end;

procedure LandingRules(
  Game: TGame;
  const Transactions: ITransactionService;
  const Options: TRentOptions
  );
begin
  ExecuteLandingRules(
    Game,
    Transactions,
    Options
  );
end;

{ ------------------------------------------------------------------------ }

procedure ApplyChanceCard(
  const ACard: TMonopolyCard;
  const AGame: TGame;
  const ATransactions: ITransactionService
  ); forward;

procedure ApplyCommunityChestCard(
  const ACard: TMonopolyCard;
  const AGame: TGame;
  const ATransactions: ITransactionService
  ); forward;

procedure HandlePayRent(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  ); forward;

{ ------------------------------------------------------------------------ }
{ ExecuteLandingRules}

procedure ExecuteLandingRules(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  );
var
  CurrentPlayer: TPlayer;
  Tile: TTile;
  Card: TMonopolyCard;
  AmountPaid: integer;
  Handled: boolean;
begin
  CurrentPlayer := Game.CurrentPlayer;
  Tile := Game.Board.TileAtPlayerPosition(CurrentPlayer);
  Handled := True;

  if Tile.TileType = ttGoToJail then
  begin
    Game.Log(Format('%s is sent to jail for landing on Go To Jail.', [CurrentPlayer.Name]));
    Game.SendCurrentPlayerToJail();
  end
  else if Tile.TileType = ttTax then
  begin
    AmountPaid := TransactionService.ChargePlayer(CurrentPlayer, Tile.Amount, Game.Board, Game.OnLog);
    Game.Log(Format('%s landed on %s and lost $%d', [CurrentPlayer.Name, Tile.Name, AmountPaid]));
  end
  else if Tile.TileType = ttChance then
  begin
    Card := Game.ChanceDeck.DrawCard;
    Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
    ApplyChanceCard(Card, Game, TransactionService);
  end
  else if Tile.TileType = ttCommunityChest then
  begin
    Card := Game.CommunityChestDeck.DrawCard;
    Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
    ApplyCommunityChestCard(Card, Game, TransactionService);
  end
  else if not Tile.IsOwned and (Tile.Price > 0) then
  begin
    Game.Log(Format('%s is available for $%d', [Tile.Name, Tile.Price]));
    if not CurrentPlayer.CanAfford(Tile.Price) then
    begin
      Game.Log(Format('%s does not have enough money to buy %s.', [CurrentPlayer.Name, Tile.Name]));
    end
    else
    begin
      Game.PayBank(CurrentPlayer, Tile.Price);
      CurrentPlayer.AcquireTile(Tile);
      Game.Log(Format('%s bought %s for $%d.', [CurrentPlayer.Name, Tile.Name, Tile.Price]));
    end;
  end
  else if Tile.IsOwned and not Tile.IsOwnedBy(CurrentPlayer) then
  begin
    HandlePayRent(Game, TransactionService, Options);
  end
  else
  begin
    Handled := False;
  end;

  if not Handled then
  begin
    Exit;
  end;

  if CurrentPlayer.Money < 0 then
  begin
    TransactionService.MarkPlayerBankrupt(CurrentPlayer, Game.Board, nil, Game.OnLog);
  end;
end;


{ --------------------------------------------------------------- }
{ Apply Cards }

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

procedure ApplyCard(
  const Card: TMonopolyCard;
  Deck: TDeck;
  Game: TGame;
  const TransactionService: ITransactionService
  );
var
  CurrentPlayer: TPlayer;
  OtherPlayer: TPlayer;
  OtherPlayers: TArray<TPlayer>;
  AmountCollected: integer;
  TargetPosition: integer;
  Tile: TTile;
  TotalCost: integer;
  TotalTransferred: integer;
  PerHouse: integer;
  PerHotel: integer;
  ReturnCardToDeck: boolean;
begin
  ReturnCardToDeck := True;
  CurrentPlayer := Game.CurrentPlayer;

  case Card.CardType of
    ctCollect:
      begin
        AmountCollected := TransactionService.CollectFromBank(CurrentPlayer, Card.Value);
        Game.Log(Format('%s collects $%d. %s', [CurrentPlayer.Name, AmountCollected, Card.Text]));
      end;

    ctPay:
      begin
        TotalTransferred := TransactionService.ChargePlayer(CurrentPlayer, Card.Value, Game.Board, Game.OnLog);
        Game.Log(Format('%s pays $%d. %s', [CurrentPlayer.Name, TotalTransferred, Card.Text]));
      end;

    ctGiftFromPlayers:
      begin
        TotalTransferred := 0;
        OtherPlayers := Game.Board.ActivePlayersExcept(CurrentPlayer);
        for OtherPlayer in OtherPlayers do
        begin
          TotalTransferred := TotalTransferred + TransactionService.TransferMoney(OtherPlayer, CurrentPlayer, Card.Value, Game.Board, Game.OnLog);
        end;

        Game.Log(Format('%s collects $%d total from other players. %s', [CurrentPlayer.Name, TotalTransferred, Card.Text]));
      end;

    ctPayEachPlayer:
      begin
        TotalTransferred := 0;
        OtherPlayers := Game.Board.ActivePlayersExcept(CurrentPlayer);
        for OtherPlayer in OtherPlayers do
        begin
          TotalTransferred := TotalTransferred + TransactionService.TransferMoney(CurrentPlayer, OtherPlayer, Card.Value, Game.Board, Game.OnLog);
          if CurrentPlayer.IsBankrupt then
          begin
            Break;
          end;
        end;

        Game.Log(Format('%s pays $%d total to other players. %s', [CurrentPlayer.Name, TotalTransferred, Card.Text]));
      end;

    ctGetOutJail:
      begin
        CurrentPlayer.GetOutOfJailCards.Add(THeldJailCard.Create(Card, Deck));
        Game.Log(Format('%s receives a Get Out of Jail Free card.', [CurrentPlayer.Name]));
        ReturnCardToDeck := False;
      end;

    ctGoToJail:
      begin
        Game.Log(Format('%s goes to jail. %s', [CurrentPlayer.Name, Card.Text]));
        Game.SendCurrentPlayerToJail();
      end;

    ctAdvance:
      begin
        if SameText(Card.Location, 'Go') then
        begin
          TargetPosition := Game.Board.FindTilePositionByName('Start');
        end
        else
        begin
          TargetPosition := Game.Board.FindTilePositionByName(Card.Location);
        end;

        if PassesGo(CurrentPlayer.Position, TargetPosition) then
        begin
          TransactionService.CollectFromBank(CurrentPlayer, 200);
          Game.Log(Format('%s passes Start and collects $200.', [CurrentPlayer.Name]));
        end;

        Game.MovePlayerTo(CurrentPlayer, TargetPosition);
        Game.Log(Format('%s advances to %s.', [CurrentPlayer.Name, Card.Location]));
        LandingRules(Game, TransactionService, TRentOptions.None);
      end;

    ctAdvanceNearestRailroad:
      begin
        TargetPosition := FindNearestPosition(CurrentPlayer.Position, RAILROAD_POSITIONS);
        if PassesGo(CurrentPlayer.Position, TargetPosition) then
        begin
          TransactionService.CollectFromBank(CurrentPlayer, 200);
          Game.Log(Format('%s passes Start and collects $200.', [CurrentPlayer.Name]));
        end;

        Game.MovePlayerTo(CurrentPlayer, TargetPosition);
        Game.Log(Format('%s advances to nearest railroad: %s.', [CurrentPlayer.Name, Game.Board.TileAtPosition(TargetPosition).Name]));
        LandingRules(Game, TransactionService, TRentOptions.RailroadRent2x);
      end;

    ctAdvanceNearestUtility:
      begin
        TargetPosition := FindNearestPosition(CurrentPlayer.Position, UTILITY_POSITIONS);
        if PassesGo(CurrentPlayer.Position, TargetPosition) then
        begin
          TransactionService.CollectFromBank(CurrentPlayer, 200);
          Game.Log(Format('%s passes Start and collects $200.', [CurrentPlayer.Name]));
        end;

        Game.MovePlayerTo(CurrentPlayer, TargetPosition);
        Game.Log(Format('%s advances to nearest utility: %s.', [CurrentPlayer.Name, Game.Board.TileAtPosition(TargetPosition).Name]));
        LandingRules(Game, TransactionService, TRentOptions.UtilityRent10x);
      end;

    ctPropertyRepairs, ctStreetRepairs:
      begin
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
          if Tile.IsOwnedBy(CurrentPlayer) then
          begin
            TotalCost := TotalCost + (Tile.Houses * PerHouse);
            if Tile.HasHotel then
            begin
              TotalCost := TotalCost + PerHotel;
            end;
          end;
        end;

        TotalTransferred := TransactionService.ChargePlayer(CurrentPlayer, TotalCost, Game.Board, Game.OnLog);
        Game.Log(Format('%s pays $%d for repairs. %s', [CurrentPlayer.Name, TotalTransferred, Card.Text]));
      end;

    ctGoBack3:
      begin
        Game.MovePlayerTo(CurrentPlayer, (CurrentPlayer.Position - 3 + BOARD_SIZE) mod BOARD_SIZE);
        Game.Log(Format('%s goes back 3 spaces to %s.', [CurrentPlayer.Name, Game.Board.TileAtPosition(CurrentPlayer.Position).Name]));
        LandingRules(Game, TransactionService, TRentOptions.None);
      end;

  else
    raise Exception.Create('Unknown card type.');
  end;

  if ReturnCardToDeck then
  begin
    Deck.ReturnCard(Card);
  end;
end;

procedure ApplyChanceCard(
  const ACard: TMonopolyCard;
  const AGame: TGame;
  const ATransactions: ITransactionService
  );
begin
  ApplyCard(ACard, AGame.ChanceDeck, AGame, ATransactions);
end;

procedure ApplyCommunityChestCard(
  const ACard: TMonopolyCard;
  const AGame: TGame;
  const ATransactions: ITransactionService
  );
begin
  ApplyCard(ACard, AGame.CommunityChestDeck, AGame, ATransactions);
end;

{ --------------------------------------------------------------- }
{ Apply Rent }

function ResolveRailroadRent(Game: TGame; Owner: TPlayer): integer;
var
  RailroadsOwned: integer;
begin
  RailroadsOwned := Game.Board.CountOwnedTilesOfType(Owner, ttRailroad);
  if (RailroadsOwned < 1) or (RailroadsOwned > 4) then
  begin
    raise Exception.CreateFmt(
      'Incorrect number of railroads owned by %s. Current: %d',
      [Game.CurrentPlayer.Name, RailroadsOwned]
    );
  end;

  Result := RAILROAD_RENT[RailroadsOwned - 1];
end;

procedure HandlePayRent(
  Game: TGame;
  const TransactionService: ITransactionService;
  const Options: TRentOptions
  );
var
  CurrentPlayer: TPlayer;
  Owner: TPlayer;
  Tile: TTile;
  RailroadsOwned: integer;
  UtilitiesOwned: integer;
  Rent: integer;
  AmountPaid: integer;
begin
  CurrentPlayer := Game.CurrentPlayer;
  Tile := Game.Board.TileAtPlayerPosition(CurrentPlayer);

  if (Tile.TileType = ttRailroad) and Options.IsRailroadRent2x then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    Rent := ResolveRailroadRent(Game, Owner) * 2;
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays %s $%d (doubled railroad rent).', [CurrentPlayer.Name, Owner.Name, AmountPaid]));
    Exit;
  end;

  if (Tile.TileType = ttUtility) and Options.IsUtilityRent10x then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    if not Game.HasLastRoll then
    begin
      Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
      Exit;
    end;

    Rent := Game.LastRoll.Total * 10;
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays %s $%d (10x dice roll).', [CurrentPlayer.Name, Owner.Name, AmountPaid]));
    Exit;
  end;

  if Tile.TileType = ttRailroad then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    RailroadsOwned := Game.Board.CountOwnedTilesOfType(Owner, ttRailroad);
    Rent := ResolveRailroadRent(Game, Owner);
    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(
      Format(
        '%s pays %s $%d for landing on %s (%d railroad(s) owned).',
        [CurrentPlayer.Name, Owner.Name, AmountPaid, Tile.Name, RailroadsOwned]
      )
    );
    Exit;
  end;

  if Tile.TileType = ttUtility then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    if not Game.HasLastRoll then
    begin
      Game.Log(Format('Cannot calculate utility rent on %s because last roll total is unavailable.', [Tile.Name]));
      Exit;
    end;

    UtilitiesOwned := Game.Board.CountOwnedTilesOfType(Owner, ttUtility);
    if UtilitiesOwned = 2 then
    begin
      Rent := Game.LastRoll.Total * 10;
    end
    else
    begin
      Rent := Game.LastRoll.Total * 4;
    end;

    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(
      Format(
        '%s pays %s $%d for landing on %s (%d utility/utilities owned).',
        [CurrentPlayer.Name, Owner.Name, AmountPaid, Tile.Name, UtilitiesOwned]
      )
    );
    Exit;
  end;

  if Tile.TileType = ttProperty then
  begin
    Owner := Game.Board.OwnerOfTile(Tile);
    Rent := Tile.Rent;

    if Game.Board.HasPropertyMonopoly(Tile, Owner) and (Tile.Houses = 0) and not Tile.HasHotel then
    begin
      Rent := Rent * 2;
    end;

    AmountPaid := TransactionService.TransferMoney(CurrentPlayer, Owner, Rent, Game.Board, Game.OnLog);
    Game.Log(Format('%s pays $%d rent to %s', [CurrentPlayer.Name, AmountPaid, Owner.Name]));
    Exit;
  end;

  raise Exception.CreateFmt(
    'No rent strategy found for tile type "%s".',
    [TileTypeToText(Tile.TileType)]
  );
end;

end.
