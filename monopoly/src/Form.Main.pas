unit Form.Main;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  System.Rtti,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Grid.Style,
  FMX.Grid,
  FMX.TabControl,
  FMX.Objects,
  FMX.Edit,
  FMX.EditBox,
  FMX.SpinBox,
  Monopoly.Types,
  Monopoly.GameReport;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Memo1: TMemo;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    StringGrid1: TStringGrid;
    Panel2: TPanel;
    Label1: TLabel;
    lblTurns: TLabel;
    Label2: TLabel;
    lblRounds: TLabel;
    GroupBox1: TGroupBox;
    lblGameTurns: TLabel;
    lblGameRounds: TLabel;
    sbtnMaxTurns: TSpinBox;
    Rectangle1: TRectangle;
    btnPlayGame: TButton;
    GroupBox2: TGroupBox;
    btnPlayTurn: TButton;
    btnCompleteGame: TButton;
    btnClearLog: TButton;
    Rectangle2: TRectangle;
    procedure btnPlayTurnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnPlayGameClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnCompleteGameClick(Sender: TObject);
  private
    FGameOnLog: TLogEvent;

    procedure ShowSummaryFmx(
      const AGrid: TStringGrid;
      const AGameReport: IGameReport
      );
    procedure BuildStatusGrid(const AGrid: TStringGrid);
    procedure UpdateGameDisplay();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

uses
  Monopoly.Factories,
  Monopoly.CompositionRoot,
  Container.Game;

procedure TForm1.btnClearLogClick(Sender: TObject);
begin
  Memo1.Lines.Clear;
end;

procedure TForm1.btnCompleteGameClick(Sender: TObject);
begin
  while GameContainer.GameState = gsActive do
  begin
    GameContainer.PlayTurn();
    GameContainer.NextTurn();
  end;
  UpdateGameDisplay();
end;

procedure TForm1.btnPlayGameClick(Sender: TObject);
begin
  if GameContainer.GameState = gsActive then
  begin
    btnPlayGame.Enabled := False;
    Exit;
  end;
  Memo1.Lines.Clear;
  var MaxRounds := Round(sbtnMaxTurns.Value);
  GameContainer.StartGame(['Alice', 'Bob', 'Charlie', 'Diana'], MaxRounds, FGameOnLog);

  while GameContainer.GameState = gsActive do
  begin
    GameContainer.PlayTurn();
    GameContainer.NextTurn();
  end;

  UpdateGameDisplay();
end;

procedure TForm1.btnPlayTurnClick(Sender: TObject);
begin
  var IsGameStart := GameContainer.GameState <> gsActive;
  if IsGameStart then
  begin
    Memo1.Lines.Clear;
    var MaxRounds := Round(sbtnMaxTurns.Value);
    GameContainer.StartGame(['Alice', 'Bob', 'Charlie', 'Diana'], MaxRounds, FGameOnLog);
    btnPlayGame.Enabled := False;
    sbtnMaxTurns.Enabled := False;
    btnPlayTurn.Text := 'Play Turn';
  end;

  if not(IsGameStart) then
  begin
    GameContainer.NextTurn();
  end;
  GameContainer.PlayTurn();

  UpdateGameDisplay;

  if GameContainer.GameState = gsFinished then
  begin
    btnPlayGame.Enabled := True;
    sbtnMaxTurns.Enabled := True;
    btnPlayTurn.Text := 'Start Game';
  end;
end;

procedure TForm1.BuildStatusGrid(const AGrid: TStringGrid);
var
  ColumnStatus, ColumnPlayer, ColumnPropertyList: TStringColumn;
  ColumnMoney: TCurrencyColumn;
  ColumnProperties1, ColumnHouses, ColumnHotels: TIntegerColumn;
begin
  AGrid.ClearColumns;
  AGrid.RowCount := 0;

  ColumnStatus := TStringColumn.Create(AGrid);
  ColumnStatus.Header := 'Status';
  ColumnStatus.Width := 60;
  AGrid.AddObject(ColumnStatus);

  ColumnPlayer := TStringColumn.Create(AGrid);
  ColumnPlayer.Header := 'Player';
  ColumnPlayer.Width := 80;
  AGrid.AddObject(ColumnPlayer);

  ColumnMoney := TCurrencyColumn.Create(AGrid);
  with ColumnMoney do
  begin
    Header := 'Money';
    Width := 60;
    HeaderSettings.TextSettings.HorzAlign := TTextAlign.Center;
    HorzAlign := TTextAlign.Trailing;
  end;
  AGrid.AddObject(ColumnMoney);

  ColumnProperties1 := TIntegerColumn.Create(AGrid);
  with ColumnProperties1 do
  begin
    Header := 'Cards';
    Width := 50;
    HeaderSettings.TextSettings.HorzAlign := TTextAlign.Center;
    HorzAlign := TTextAlign.Center;
  end;
  AGrid.AddObject(ColumnProperties1);

  ColumnHouses := TIntegerColumn.Create(AGrid);
  with ColumnHouses do
  begin
    Header := 'Houses';
    Width := 50;
    HeaderSettings.TextSettings.HorzAlign := TTextAlign.Center;
    HorzAlign := TTextAlign.Center;
  end;
  AGrid.AddObject(ColumnHouses);

  ColumnHotels := TIntegerColumn.Create(AGrid);
  with ColumnHotels do
  begin
    Header := 'Hotels';
    Width := 50;
    HeaderSettings.TextSettings.HorzAlign := TTextAlign.Center;
    HorzAlign := TTextAlign.Center;
  end;
  AGrid.AddObject(ColumnHotels);

  ColumnPropertyList := TStringColumn.Create(AGrid);
  with ColumnPropertyList do
  begin
    Header := 'Property List';
    Width := 400;
  end;
  AGrid.AddObject(ColumnPropertyList);
end;

procedure TForm1.ShowSummaryFmx(
  const AGrid: TStringGrid;
  const AGameReport: IGameReport
  );
var
  Item: IGameReportItem;
  Prefix: string;
begin
  AGrid.RowCount := Length(AGameReport.Items);
  AGrid.BeginUpdate;
  try
    var Row := 0;
    for Item in AGameReport.Items do
    begin
      Prefix := IfThen(Item.PlayerStatus = psWinner, 'Winner',
                IfThen(Item.PlayerStatus = psBankrupt, 'Out', ''));
      AGrid.Cells[0, Row] := Prefix;
      AGrid.Cells[1, Row] := Item.PlayerName;
      AGrid.Cells[2, Row] := Item.FormattedMoney;
      AGrid.Cells[3, Row] := Item.PropertyCount.ToString;
      AGrid.Cells[4, Row] := IfThen(Item.HouseCount > 0, Item.HouseCount.ToString, '');
      AGrid.Cells[5, Row] := IfThen(Item.HotelCount > 0, Item.HotelCount.ToString, '');
      AGrid.Cells[6, Row] := Item.PropertyList;
      Row := Row + 1;
    end;
  finally
    AGrid.EndUpdate;
  end;
end;

procedure TForm1.UpdateGameDisplay;
var
  GameReport: IGameReport;
begin
  GameReport := GameContainer.GameReport;
  ShowSummaryFmx(StringGrid1, GameReport);
  lblGameTurns.Text := Format('Turns: %d',[GameContainer.GetTurnCounter]);
  lblGameRounds.Text := Format('Rounds: %d',[GameContainer.GetRoundCounter]);
  lblTurns.Text := GameContainer.GetTurnCounter.ToString;
  lblRounds.Text := GameContainer.GetRoundCounter.ToString;

  btnPlayGame.Enabled := GameContainer.GameState <> gsActive;
  sbtnMaxTurns.Enabled := GameContainer.GameState <> gsActive;
  btnCompleteGame.Enabled := GameContainer.GameState = gsActive;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TabControl1.Align := TAlignLayout.Client;
  Memo1.Align := TAlignLayout.Client;
  StringGrid1.Align := TAlignLayout.Client;

  lblGameTurns.Text := 'Click on Play Game ..';
  lblGameRounds. Text := 'Click on Start Game';
  BuildStatusGrid(StringGrid1);
  btnPlayTurn.Text := 'Start Game';

  FGameOnLog :=
    procedure(const Message: string)
    begin
      Memo1.Lines.Add(Message)
    end;
end;

end.
