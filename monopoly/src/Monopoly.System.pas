unit Monopoly.System;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.TypInfo;

type
  TLifetime = (Transient, Singleton);

  // Dependency Info for the DI Container
  TRegistrationInfo = class
  public
    ImplementationClass: TClass;
    Lifetime: TLifetime;
    SingletonInstance: IInterface;
    constructor Create(AClass: TClass; ALifetime: TLifetime);
  end;

  TDependencyInjectionContainer = class
  private
    FRegistrations: TDictionary<TGUID, TRegistrationInfo>;
    FContext: TRttiContext;
    function CreateInstanceWithRTTI(AClass: TClass): TObject;
    function ResolveByGuid(const AGuid: TGUID): IInterface;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Register<TInterface: IInterface; TImplementation: class>(ALifetime: TLifetime = TLifetime.Transient);

    function Resolve<T: IInterface>: T; overload;
    function Resolve(AClass: TClass): TObject; overload;
  end;

type
 TContainerEvent = procedure(Sender: TObject) of object;

  TBaseContainer = class(TComponent)
  private
    FOnInitialize: TContainerEvent;
  protected
    procedure DoCreate; virtual;
    procedure DoDestroy; virtual;
    procedure DoInitialize; virtual;
  public
    procedure Initialize;
  published
    property OnInitialize: TContainerEvent read FOnInitialize write FOnInitialize;
  end;

  TContainerManager = class(TComponent)
  private
    FContainers: TObjectList<TBaseContainer>;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RegisterAndInitilizeContainers(const AContainers: array of TBaseContainer);
    property Containers: TObjectList<TBaseContainer> read FContainers;
  end;

var
  ContainerManager: TContainerManager;

implementation

{ TRegistrationInfo }

constructor TRegistrationInfo.Create(AClass: TClass; ALifetime: TLifetime);
begin
  ImplementationClass := AClass;
  Lifetime := ALifetime;
  SingletonInstance := nil;
end;

{ TDependencyInjectionContainer }

constructor TDependencyInjectionContainer.Create;
begin
  FRegistrations := TDictionary<TGUID, TRegistrationInfo>.Create;
  FContext := TRttiContext.Create;
end;

destructor TDependencyInjectionContainer.Destroy;
var
  RegInfo: TRegistrationInfo;
begin
  for RegInfo in FRegistrations.Values do
    RegInfo.Free;

  FRegistrations.Free;
  FContext.Free;
  inherited;
end;

procedure TDependencyInjectionContainer.Register<TInterface, TImplementation>(ALifetime: TLifetime);
var
  Guid: TGUID;
  RegInfo: TRegistrationInfo;
begin
  Guid := GetTypeData(TypeInfo(TInterface))^.Guid;

  // if the type was already registered - free current one
  if FRegistrations.TryGetValue(Guid, RegInfo) then
    RegInfo.Free;

  FRegistrations.AddOrSetValue(Guid, TRegistrationInfo.Create(TImplementation, ALifetime));
end;

function TDependencyInjectionContainer.Resolve<T>: T;
var
  Guid: TGUID;
begin
  Guid := GetTypeData(TypeInfo(T))^.Guid;
  Result := T(ResolveByGuid(Guid));
end;

function TDependencyInjectionContainer.Resolve(AClass: TClass): TObject;
begin
  Result := CreateInstanceWithRTTI(AClass);
end;

function TDependencyInjectionContainer.ResolveByGuid(const AGuid: TGUID): IInterface;
var
  RegInfo: TRegistrationInfo;
  NewObj: TObject;
begin
  if not FRegistrations.TryGetValue(AGuid, RegInfo) then
    raise Exception.Create('Required interface not registered in the container.');

  if RegInfo.Lifetime = TLifetime.Singleton then
  begin
    if RegInfo.SingletonInstance = nil then
    begin
      NewObj := CreateInstanceWithRTTI(RegInfo.ImplementationClass);
      if not Supports(NewObj, AGuid, RegInfo.SingletonInstance) then
        raise Exception.CreateFmt('Class %s does not implement the required interface.', [RegInfo.ImplementationClass.ClassName]);

      // decrease reference counter (trick TInterfacedObject in Delphi RTTI)
      NewObj.GetInterfaceEntry(AGuid);
    end;
    Exit(RegInfo.SingletonInstance);
  end;

  // Transient - always new instance
  NewObj := CreateInstanceWithRTTI(RegInfo.ImplementationClass);
  if not Supports(NewObj, AGuid, Result) then
    raise Exception.CreateFmt('Class %s does not implement the required interface.', [RegInfo.ImplementationClass.ClassName]);

  NewObj.GetInterfaceEntry(AGuid);
end;

function TDependencyInjectionContainer.CreateInstanceWithRTTI(AClass: TClass): TObject;
var
  RttiType: TRttiType;
  Method: TRttiMethod;
  Params: TArray<TRttiParameter>;
  Args: TArray<TValue>;
  I: Integer;
  ParamGuid: TGUID;
begin
  RttiType := FContext.GetType(AClass);
  Method := RttiType.GetMethod('Create');

  if Method = nil then
    raise Exception.CreateFmt('Constructor "Create" not found for class %s', [AClass.ClassName]);

  Params := Method.GetParameters;

  if Length(Params) = 0 then
  begin
    Result := Method.Invoke(AClass, []).AsObject;
    Exit;
  end;

  SetLength(Args, Length(Params));

  for I := 0 to High(Params) do
  begin
    if Params[I].ParamType.TypeKind = tkInterface then
    begin
      ParamGuid := TRttiInterfaceType(Params[I].ParamType).GUID;
      // Recursively fetch the dependency
      Args[I] := TValue.From<IInterface>(ResolveByGuid(ParamGuid));
    end
    else
    begin
      raise Exception.CreateFmt('Unsupported parameter "%s" of type %s in %s.',
        [Params[I].Name, Params[I].ParamType.Name, AClass.ClassName]);
    end;
  end;

  Result := Method.Invoke(AClass, Args).AsObject;
end;


{ TBaseContainer }

procedure TBaseContainer.DoCreate;
begin

end;

procedure TBaseContainer.DoDestroy;
begin

end;

procedure TBaseContainer.DoInitialize;
begin

end;

procedure TBaseContainer.Initialize;
begin
  DoInitialize;
  if Assigned(FOnInitialize) then
    FOnInitialize(Self);
end;

{ TContainerManager }

constructor TContainerManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FContainers := TObjectList<TBaseContainer>.Create(False);
end;

destructor TContainerManager.Destroy;
begin
  FContainers.Free;
  inherited Destroy;
end;

procedure TContainerManager.RegisterAndInitilizeContainers(const AContainers: array of TBaseContainer);
var
  Container: TBaseContainer;
begin
  FContainers.Clear;
  for Container in AContainers do
  begin
    if not FContainers.Contains(Container) then
    begin
      FContainers.Add(Container);
      Container.FreeNotification(Self);

      Container.DoCreate;
    end;
  end;
  for Container in FContainers do
  begin
    Container.Initialize;
  end;
end;

procedure TContainerManager.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent is TBaseContainer) then
  begin
    if Assigned(FContainers) then
      FContainers.Remove(TBaseContainer(AComponent));
    TBaseContainer(AComponent).DoDestroy;
  end;
end;

end.
