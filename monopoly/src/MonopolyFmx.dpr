program MonopolyFmx;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {Form1},
  Monopoly.CompositionRoot in 'Monopoly.CompositionRoot.pas',
  Monopoly.Factories in 'Monopoly.Factories.pas',
  Monopoly.System in 'Monopoly.System.pas',
  Monopoly.Transactions in 'Monopoly.Transactions.pas',
  Monopoly.Types in 'Monopoly.Types.pas',
  Monopoly.Utils in 'Monopoly.Utils.pas',
  Monopoly.Rules.Jail in 'rules\Monopoly.Rules.Jail.pas',
  Monopoly.Rules.Landing in 'rules\Monopoly.Rules.Landing.pas',
  Monopoly.Rules.Decisions in 'rules\Monopoly.Rules.Decisions.pas',
  Monopoly.Rules.Build in 'rules\Monopoly.Rules.Build.pas',
  Monopoly.GameReport in 'Monopoly.GameReport.pas',
  Container.Game in 'Container.Game.pas';

{$R *.res}

begin
  Application.Initialize;
  ContainerManager := TContainerManager.Create(Application);
  Application.CreateForm(TForm1, Form1);
  GameContainer := TGameContainer.Create(Form1);
  ContainerManager.RegisterAndInitilizeContainers([ GameContainer ]);
  Application.Run;
end.
