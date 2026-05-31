unit SourceLens.DelphiAnalyzer;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.IOUtils,
  SourceLens.Types,
  SourceLens.ParserEnvironment,
  DelphiAST,
  DelphiAST.Consts,
  DelphiAST.Classes;

type
  IDelphiAnalyzer = interface
    ['{F3D2E90A-4F7D-4C34-9B45-5B2DCE5D35E5}']
    function AnalyzeUnits(const AFileNames: TArray<string>): TAnalysisResult;
  end;

  TDelphiAnalyzer = class(TInterfacedObject, IDelphiAnalyzer)
  private
    type
      TParsedUnit = record
        FileName: string;
        UnitName: string;
        SyntaxTree: TSyntaxNode;
      end;
  private
    FSourceFileProvider: ISourceFileProvider;
    FParserEnvironment: IDelphiParserEnvironment;
    function BuildMethodMetrics(
      const AMethodNode: TSyntaxNode;
      const AUnitName: string;
      APublicMethods: TStrings
      ): TMethodInfo;
    function BuildParsedUnits(
      const AFileNames: TArray<string>;
      AParseFailures: TList<TParseFailure>
      ): TList<TParsedUnit>;
    function BuildPublicMethodSet(
      const AParsedUnits: TList<TParsedUnit>
      ): TStringList;
    function GetUnitName(const AFileName: string): string;
  public
    constructor Create(
      const ASourceFileProvider: ISourceFileProvider;
      const AParserEnvironment: IDelphiParserEnvironment
      );
    function AnalyzeUnits(const AFileNames: TArray<string>): TAnalysisResult;
  end;

function CreateDelphiAnalyzer: IDelphiAnalyzer; overload;
function CreateDelphiAnalyzer(
  const ASourceFileProvider: ISourceFileProvider;
  const AParserEnvironment: IDelphiParserEnvironment
  ): IDelphiAnalyzer; overload;

implementation

uses
  SourceLens.Extractor.PublicMethods,
  SourceLens.Utils;

function CreateDelphiAnalyzer: IDelphiAnalyzer;
begin
  Result := TDelphiAnalyzer.Create(
    CreateFileSourceFileProvider,
    CreateDelphiParserEnvironment
    );
end;

function CreateDelphiAnalyzer(
  const ASourceFileProvider: ISourceFileProvider;
  const AParserEnvironment: IDelphiParserEnvironment
  ): IDelphiAnalyzer;
begin
  Result := TDelphiAnalyzer.Create(ASourceFileProvider, AParserEnvironment);
end;

procedure FreeParsedUnits(AParsedUnits: TList<TDelphiAnalyzer.TParsedUnit>);
var
  ParsedUnit: TDelphiAnalyzer.TParsedUnit;
begin
  if AParsedUnits = nil then
    Exit;

  for ParsedUnit in AParsedUnits do
    ParsedUnit.SyntaxTree.Free;
  AParsedUnits.Free;
end;

constructor TDelphiAnalyzer.Create(
  const ASourceFileProvider: ISourceFileProvider;
  const AParserEnvironment: IDelphiParserEnvironment
  );
begin
  inherited Create;
  if ASourceFileProvider = nil then
    FSourceFileProvider := CreateFileSourceFileProvider
  else
    FSourceFileProvider := ASourceFileProvider;

  if AParserEnvironment = nil then
    FParserEnvironment := CreateDelphiParserEnvironment
  else
    FParserEnvironment := AParserEnvironment;
end;

function TDelphiAnalyzer.GetUnitName(const AFileName: string): string;
begin
  Result := TPath.GetFileNameWithoutExtension(AFileName);
end;

function CalculateBodyLines(const AMethodNode: TCompoundSyntaxNode): integer;
var
  Statements: TCompoundSyntaxNode;
  BeginLine: integer;
  EndLine: integer;
begin
  Statements := AMethodNode.FindNode(ntStatements) as TCompoundSyntaxNode;
  if Statements = nil then
    Exit(-1);

  BeginLine := Statements.Line;
  EndLine := Statements.EndLine;

  Result := EndLine - BeginLine - 1;
  if Result < 0 then
    Result := 0;
end;

procedure SplitFullMethodName(
  const AFullMethodName: string;
  var AClassName: string;
  var AMethodName: string);
var
  SeparatorIndex: integer;
begin
  SeparatorIndex := AFullMethodName.LastIndexOf('.');
  if SeparatorIndex >= 0 then
  begin
    AClassName := AFullMethodName.Substring(0, SeparatorIndex);
    AMethodName := AFullMethodName.Substring(SeparatorIndex + 1);
  end
  else
  begin
    AClassName := '';
    AMethodName := AFullMethodName;
  end;
end;

function TDelphiAnalyzer.BuildMethodMetrics(
  const AMethodNode: TSyntaxNode;
  const AUnitName: string;
  APublicMethods: TStrings
  ): TMethodInfo;
var
  NodeName: string;
  ClassName: string;
  MethodName: string;
  QualifiedName: string;
  MethodLoc: integer;
begin
  NodeName := AMethodNode.GetAttribute(anName);

  if AMethodNode.Typ <> ntMethod then
    raise Exception.CreateFmt(
      'Node %s expected to be method name, but isn''t', [NodeName]);

  SplitFullMethodName(NodeName, ClassName, MethodName);

  QualifiedName := GetFullyQualifiedName(AUnitName, ClassName, MethodName);
  MethodLoc := CalculateBodyLines(AMethodNode as TCompoundSyntaxNode);

  Result.UnitName := AUnitName;
  Result.ClassName := ClassName;
  Result.MethodName := MethodName;
  Result.IsPublic := APublicMethods.IndexOf(QualifiedName) >= 0;
  Result.BodyLines := MethodLoc;
end;

function TDelphiAnalyzer.BuildParsedUnits(
  const AFileNames: TArray<string>;
  AParseFailures: TList<TParseFailure>
  ): TList<TParsedUnit>;
var
  FileName: string;
  Tree: TSyntaxNode;
  ParsedUnit: TParsedUnit;
  ParseFailure: TParseFailure;
begin
  Result := TList<TParsedUnit>.Create;
  for FileName in AFileNames do
  begin
    try
      Tree := FParserEnvironment.ParseFile(FileName, FSourceFileProvider);
      ParsedUnit.FileName := FileName;
      ParsedUnit.UnitName := GetUnitName(FileName);
      ParsedUnit.SyntaxTree := Tree;
      Result.Add(ParsedUnit);
    except
      on E: Exception do
      begin
        ParseFailure.FileName := FileName;
        ParseFailure.Message := E.Message;
        AParseFailures.Add(ParseFailure);
      end;
    end;
  end;
end;

function TDelphiAnalyzer.BuildPublicMethodSet(
  const AParsedUnits: TList<TParsedUnit>
  ): TStringList;
var
  ParsedUnit: TParsedUnit;
  PublicMethods: TArray<string>;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;
  Result.Sorted := True;

  for ParsedUnit in AParsedUnits do
  begin
    PublicMethods := TPublicMethodExtractor.Extract(
      ParsedUnit.SyntaxTree,
      ParsedUnit.UnitName
      );
    Result.AddStrings(PublicMethods);
  end;
end;

function TDelphiAnalyzer.AnalyzeUnits(
  const AFileNames: TArray<string>
  ): TAnalysisResult;
var
  ParsedUnits: TList<TParsedUnit>;
  PublicMethods: TStringList;
  MethodInfos: TList<TMethodInfo>;
  ParseFailures: TList<TParseFailure>;
  ParsedUnit: TParsedUnit;
  ImplementationNode: TSyntaxNode;
  Node: TSyntaxNode;
  MethodInfo: TMethodInfo;
begin
  MethodInfos := TList<TMethodInfo>.Create;
  ParseFailures := TList<TParseFailure>.Create;
  ParsedUnits := nil;
  PublicMethods := nil;
  try
    ParsedUnits := BuildParsedUnits(AFileNames, ParseFailures);
    PublicMethods := BuildPublicMethodSet(ParsedUnits);

    for ParsedUnit in ParsedUnits do
    begin
      ImplementationNode := ParsedUnit.SyntaxTree.FindNode(ntImplementation);
      if ImplementationNode = nil then
        Continue;

      for Node in ImplementationNode.ChildNodes do
      begin
        if Node.Typ = ntMethod then
        begin
          MethodInfo := BuildMethodMetrics(
            Node,
            ParsedUnit.UnitName,
            PublicMethods
            );
          MethodInfos.Add(MethodInfo);
        end;
      end;
    end;

    Result.MethodInfos := MethodInfos.ToArray;
    Result.ParseFailures := ParseFailures.ToArray;
  finally
    PublicMethods.Free;
    FreeParsedUnits(ParsedUnits);
    ParseFailures.Free;
    MethodInfos.Free;
  end;
end;

end.