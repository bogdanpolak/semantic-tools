unit Container.Game;

interface

uses
  System.SysUtils,
  System.Classes,
  Monopoly.System,
  Monopoly.Types,
  Monopoly.CompositionRoot,
  Monopoly.Transactions,
  Monopoly.GameReport;

type
  TGameContainer = class(TBaseContainer)
  private
    FGame: TGame;
    FBoard: TBoard;
    FMaxRrounds: integer;
    FMonopolyServices: IMonopolyServices;
    FTransactions: ITransactionService;
    procedure MovePlayer(Steps: integer);
    function GetGameState: TGameState;
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartGame(
      const APlayerNames: array of string;
      const AMaxRrounds: integer;
      const AOnLog: TLogEvent
      );
    procedure NextTurn();
    procedure PlayTurn();
    function GameReport: IGameReport;
    function PlayerNameList: string;
    function GetTurnCounter: integer;
    function GetRoundCounter: integer;
    property GameState: TGameState read GetGameState;
  end;

var
  GameContainer: TGameContainer;

implementation

uses
  Monopoly.Utils,
  Monopoly.Factories,
  Monopoly.Rules.Landing,
  Monopoly.Rules.Jail,
  Monopoly.Rules.Build;

constructor TGameContainer.Create(AOwner: TComponent);
begin
  inherited;
  Randomize;
  FMonopolyServices := CreateMonopolyServices();
  FTransactions:= FMonopolyServices.GetTransactionService();
  FBoard := CreateBoard();
  FGame := TGame.Create();
end;

destructor TGameContainer.Destroy;
begin
  FreeAndNil(FGame);
  inherited;
end;

function TGameContainer.GameReport: IGameReport;
begin
  Result := GetGameReport(FGame);
end;

function TGameContainer.GetGameState: TGameState;
begin
  Result :=
  FGame.Status;
end;

function TGameContainer.GetRoundCounter: integer;
begin
  Result := FGame.RoundNumber;
end;

function TGameContainer.GetTurnCounter: integer;
begin
  Result := FGame.TurnNumber;
end;

procedure TGameContainer.StartGame(
  const APlayerNames: array of string;
  const AMaxRrounds: integer;
  const AOnLog: TLogEvent
  );
begin
  FMaxRrounds := AMaxRrounds;
  FGame.StartGame(APlayerNames, FMaxRrounds, True);
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

procedure TGameContainer.NextTurn;
begin
  if FGame.Status = gsActive then
  begin
    FGame.NextTurn();
  end;
end;

procedure TGameContainer.PlayTurn();
var
  DoublesCount: integer;
  ContinueRolling: boolean;
  Player: TPlayer;
  IsRealased: boolean;
  JailRoll: TDiceRoll;
  Roll: TDiceRoll;
  BuildMessage: string;
  AmountPaid: integer;
begin
  FGame.ClearLastRoll();
  Player := FGame.CurrentPlayer;
  if Player = nil then Exit;

  DoublesCount := 0;
  ContinueRolling := True;
  while ContinueRolling and (DoublesCount < 3) and not(Player.IsBankrupt) do
  begin
    if Player.IsInJail then
    begin
      ContinueRolling := False;
      IsRealased := TryGetOutJail(FGame, FTransactions, JailRoll);
      if not IsRealased then
        Exit;

      Roll := JailRoll;
    end
    else
    begin
      ContinueRolling := Roll.IsDouble;
      Inc(DoublesCount);
      Roll := FGame.RollDice;
    end;

    FGame.SetLastRoll(Roll);

    if DoublesCount = 3 then
    begin
      FGame.Log(Format('%s rolled doubles three times in a row and goes to jail!', [Player.Name]));
      FGame.SendCurrentPlayerToJail();
      Exit;
    end;

    MovePlayer(Roll.Total);
    LandingRules(FGame, FTransactions, TRentOptions.None);

    if Player.IsBankrupt or Player.IsInJail then
    begin
      Exit;
    end;

    if TryBuildHouse(FGame, AmountPaid, BuildMessage) = bhrBuilt then
    begin
      FGame.Log(BuildMessage);
    end;

    if ContinueRolling then
    begin
      FGame.Log(Format('%s rolled doubles: %d & %d and gets another turn!', [Player.Name, Roll.Dice1, Roll.Dice2]));
    end;
  end;
  if FGame.TermiantionReason <> '' then

  begin
    FGame.Log(FGame.TermiantionReason);
  end;
end;

function TGameContainer.PlayerNameList: string;
begin
 result := JoinPlayerNames(FGame.Players);
end;

end.
