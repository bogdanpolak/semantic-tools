unit Monopoly.Rules.Cards;

interface

uses
  Monopoly.Transactions,
  Monopoly.Types;

procedure HandleChanceCard(
  Game: TGame;
  const TransactionService: ITransactionService
  );
procedure HandleCommunityChestCard(
  Game: TGame;
  const TransactionService: ITransactionService
  );

implementation

uses
  System.SysUtils,
  Monopoly.Rules.Jail,
  Monopoly.Rules.Landing;

const
  BOARD_SIZE = 40;

  RAILROAD_POSITIONS: array[0..3] of integer = (5, 15, 25, 35);
  UTILITY_POSITIONS: array[0..1] of integer = (12, 28);

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

procedure ExecuteCard(
  Game: TGame;
  const Card: TMonopolyCard;
  Deck: TDeck;
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
        SendCurrentPlayerToJail(Game);
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

procedure HandleChanceCard(
  Game: TGame;
  const TransactionService: ITransactionService
  );
var
  Card: TMonopolyCard;
begin
  Card := Game.ChanceDeck.DrawCard;
  Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
  ExecuteCard(Game, Card, Game.ChanceDeck, TransactionService);
end;

procedure HandleCommunityChestCard(
  Game: TGame;
  const TransactionService: ITransactionService
  );
var
  Card: TMonopolyCard;
begin
  if Game = nil then
  begin
    Exit;
  end;

  Card := Game.CommunityChestDeck.DrawCard;
  Game.Log(Format('%s draws card: %s', [Game.CurrentPlayer.Name, Card.Text]));
  ExecuteCard(Game, Card, Game.CommunityChestDeck, TransactionService);
end;

end.
