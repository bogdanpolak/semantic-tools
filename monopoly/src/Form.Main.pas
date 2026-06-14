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
  Monopoly.GameStatus;

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
    btnPlayTurn: TButton;
    lblGameTurns: TLabel;
    lblGameRounds: TLabel;
    sbtnMaxTurns: TSpinBox;
    Rectangle1: TRectangle;
    btnPlayGame: TButton;
    procedure btnPlayTurnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ShowSummaryFmx(const AGrid: TStringGrid);
    procedure BuildStatusGrid(const AGrid: TStringGrid);
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
  MainModule;

procedure TForm1.btnPlayTurnClick(Sender: TObject);
var
  GameOnLog: TLogEvent;
begin
  Memo1.Lines.Clear;
  GameOnLog :=
    procedure(const Message: string)
    begin
      Memo1.Lines.Add(Message)
    end;

  GameContainer.StartGame(['Alice', 'Bob', 'Charlie', 'Diana'], GameOnLog);
  GameContainer.PlayGame();
  ShowSummaryFmx(StringGrid1);
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

procedure TForm1.ShowSummaryFmx(const AGrid: TStringGrid);
var
  GameStatus: IGameStatus;
  Item: IGameStatusItem;
  Prefix: string;
begin
  GameStatus := GameContainer.GameStatus;

  AGrid.RowCount := Length(GameStatus.Items);
  AGrid.BeginUpdate;
  try
    var Row := 0;
    for Item in GameStatus.Items do
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

procedure TForm1.FormCreate(Sender: TObject);
begin
  TabControl1.Align := TAlignLayout.Client;
  Memo1.Align := TAlignLayout.Client;
  StringGrid1.Align := TAlignLayout.Client;
  BuildStatusGrid(StringGrid1);
end;

end.
