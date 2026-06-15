unit Monopoly.CompositionRoot;

interface

uses
  System.SysUtils,
  Monopoly.System,
  Monopoly.Transactions;

type
  IMonopolyServices = interface
    ['{F2522624-CED5-423E-97E4-56EA15CA3B8D}']
    function GetTransactionService: ITransactionService;
  end;

function CreateMonopolyServices: IMonopolyServices;

implementation

type
  TMonopolyServices = class(TInterfacedObject, IMonopolyServices)
  private
    FContainer: TDependencyInjectionContainer;
  public
    constructor Create();
    destructor Destroy; override;
    function GetTransactionService: ITransactionService;
  end;

function CreateMonopolyServices: IMonopolyServices;
begin
  Result := TMonopolyServices.Create()
end;

constructor TMonopolyServices.Create();
begin
  FContainer := TDependencyInjectionContainer.Create;
  FContainer.Register<ITransactionService, TTransactionService>();
end;

destructor TMonopolyServices.Destroy;
begin
  FContainer.Free;
  inherited;
end;

function TMonopolyServices.GetTransactionService: ITransactionService;
begin
  Result := FContainer.Resolve<ITransactionService>;
end;

end.
