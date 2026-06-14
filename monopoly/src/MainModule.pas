unit MainModule;

interface

uses
  System.SysUtils,
  System.Classes,
  Monopoly.System,
  Monopoly.Types,
  Monopoly.CompositionRoot,
  Monopoly.Transactions,
  Monopoly.GameStatus;

const
  DEFUALT_MAX_ROUNDS = 60;

type
  TGameContainer = class(TBaseContainer)
  private
    FGame: TGame;
    FBoard: TBoard;
    FOnLog: TLogEvent;
    FMonopolyServices: IMonopolyServices;
    FTransactions: ITransactionService;
    procedure MovePlayer(Steps: integer);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartGame(
      const APlayerNames: array of string;
      const AOnLog: TLogEvent
      );
    procedure PlayGame();
    procedure PlayTurn();
    function GameStatus: IGameStatus;
    function PlayerNameList: string;
  end;

var
  GameContainer: TGameContainer;

implementation

uses
  Monopoly.Utils,
  Monopoly.Factories,
  Monopoly.Rules.Landing,
  Monopoly.Rules.Jail,
  Monopoly.BuildActions;

constructor TGameContainer.Create(AOwner: TComponent);
begin
  inherited;
  Randomize;
  FMonopolyServices := CreateMonoployServices();
  FTransactions:= FMonopolyServices.GetTransactionService();
  FBoard := CreateBoard();
  FGame := TGame.Create();
end;

destructor TGameContainer.Destroy;
begin
  FreeAndNil(FGame);
  inherited;
end;

function TGameContainer.GameStatus: IGameStatus;
begin
  Result := GetGameStatus(FGame);
end;

procedure TGameContainer.StartGame(
  const APlayerNames: array of string;
  const AOnLog: TLogEvent
  );
begin
  FGame.StartGame(APlayerNames, DEFUALT_MAX_ROUNDS, True);
  FGame.OnLog := AOnLog;
end;

procedure TGameContainer.MovePlayer(Steps: integer);
var
  Player: TPlayer;
  PassStart: boolean;
  CurrentSquare: TTile;
begin
  Player := FGame.CurrentPlayer;
  PassStart := FGame.MovePlayerBy(Player, Steps);

  CurrentSquare := FGame.Board.TileAtPlayerPosition(Player);
  FGame.Log(Format('%s moves to %s', [Player.Name, CurrentSquare.Name]));
  if PassStart then
  begin
    FTransactions.CollectFromBank(Player, 200);
    FGame.Log(Format('%s passes Start and collects $200', [Player.Name]));
  end;
end;

function TGameContainer.PlayerNameList: string;
begin
 result := JoinPlayerNames(FGame.Players);
end;

procedure TGameContainer.PlayGame();
begin
  while FGame.IsGameActive do
  begin
    PlayTurn();
    FGame.NextTurn();
  end;
  if FGame.TermiantionReason <> '' then
  begin
    FGame.Log(FGame.TermiantionReason);
  end;
end;

procedure TGameContainer.PlayTurn();
var
  DoublesCount: integer;
  HasDouble: boolean;
  Player: TPlayer;
  JailResult: TJailResult;
  Roll: TDiceRoll;
  BuildMessage: string;
  AmountPaid: integer;
  HouseCountBeforeLanding: integer;
begin
  FGame.ClearLastRoll();
  Player := FGame.CurrentPlayer;
  if Player = nil then Exit;

  DoublesCount := 0;
  HasDouble := True;
  while HasDouble and (DoublesCount < 3) and not(Player.IsBankrupt) do
  begin
    JailResult := JailRules(FGame, FTransactions);
    if not JailResult.CanMove then
    begin
      Exit;
    end;

    begin
      if JailResult.HasRoll then
      begin
        Roll := JailResult.Roll;
      end
      else
      begin
        Roll := FGame.RollDice;
      end;

      FGame.SetLastRoll(Roll);
      HasDouble := Roll.IsDouble and not JailResult.UsedJailRoll;
      if HasDouble then
      begin
        Inc(DoublesCount);
      end;

      if DoublesCount = 3 then
      begin
        FGame.Log(Format('%s rolled doubles three times in a row and goes to jail!', [Player.Name]));
        SendCurrentPlayerToJail(FGame);
        Exit;
      end;

      MovePlayer(Roll.Total);
      HouseCountBeforeLanding := FGame.Board.CountHousesOwnedBy(Player);
      LandingRules(FGame, FTransactions, TRentOptions.None);

      if Player.IsBankrupt or Player.IsInJail then
      begin
        Exit;
      end;

      if FGame.Board.CountHousesOwnedBy(Player) = HouseCountBeforeLanding then
      begin
        if TryBuildFirstEligibleHouse(FGame, AmountPaid, BuildMessage) then
        begin
          FGame.Log(BuildMessage);
        end;
      end;

      if HasDouble then
      begin
        FGame.Log(Format('%s rolled doubles: %d & %d and gets another turn!', [Player.Name, Roll.Dice1, Roll.Dice2]));
      end;
    end;
  end;
end;

end.
