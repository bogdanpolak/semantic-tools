program MonopolyFmx;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {Form1},
  Monopoly.BuildActions in 'Monopoly.BuildActions.pas',
  Monopoly.CompositionRoot in 'Monopoly.CompositionRoot.pas',
  Monopoly.Factories in 'Monopoly.Factories.pas',
  Monopoly.PropertyDevelopment in 'Monopoly.PropertyDevelopment.pas',
  Monopoly.System in 'Monopoly.System.pas',
  Monopoly.Transactions in 'Monopoly.Transactions.pas',
  Monopoly.Types in 'Monopoly.Types.pas',
  Monopoly.Utils in 'Monopoly.Utils.pas',
  Monopoly.Rules.Cards in 'rules\Monopoly.Rules.Cards.pas',
  Monopoly.Rules.Jail in 'rules\Monopoly.Rules.Jail.pas',
  Monopoly.Rules.Landing in 'rules\Monopoly.Rules.Landing.pas',
  Monopoly.Rules.Rent in 'rules\Monopoly.Rules.Rent.pas',
  Monopoly.GameStatus in 'Monopoly.GameStatus.pas',
  MainModule in 'MainModule.pas';

{$R *.res}

begin
  Application.Initialize;
  ContainerManager := TContainerManager.Create(Application);
  Application.CreateForm(TForm1, Form1);
  GameContainer := TGameContainer.Create(Form1);
  ContainerManager.RegisterAndInitilizeContainers([ GameContainer ]);
  Application.Run;
end.
