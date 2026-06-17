unit SourceLens.DelphiAnalyzer;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DelphiAST,
  DelphiAST.Consts,
  DelphiAST.Classes,
  SemanticTools.DelphiAstParser,
  SemanticTools.Utils,
  SourceLens.Metrics.CyclomaticComplexity,
  SourceLens.Metrics.MaxIndentation,
  SourceLens.Types;

type
  IDelphiAnalyzer = interface
    ['{F3D2E90A-4F7D-4C34-9B45-5B2DCE5D35E5}']
    function AnalyzeRepository(const AFileNames: TArray<string>): TAnalysisResult;
  end;

  TDelphiAnalyzer = class(TInterfacedObject, IDelphiAnalyzer)
  private
    FAstParser: IAstParser;
    function BuildMethodMetrics(
      const AMethodNode: TSyntaxNode;
      const AUnitName: string
      ): TMethodInfo;
  public
    constructor Create(const AAstParser: IAstParser);
    function AnalyzeRepository(const AFileNames: TArray<string>): TAnalysisResult;
  end;

implementation

constructor TDelphiAnalyzer.Create(const AAstParser: IAstParser);
begin
  inherited Create;
  FAstParser := AAstParser;
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

function TDelphiAnalyzer.BuildMethodMetrics(
  const AMethodNode: TSyntaxNode;
  const AUnitName: string
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
      'Node "%s" expected to be a method, but isn''t', [NodeName]);

  SplitFullMethodName(NodeName, ClassName, MethodName);

  QualifiedName := GetFullyQualifiedName(AUnitName, ClassName, MethodName);
  MethodLoc := CalculateBodyLines(AMethodNode as TCompoundSyntaxNode);

  Result.UnitName := AUnitName;
  Result.ClassName := ClassName;
  Result.MethodName := MethodName;
  Result.BodyLines := MethodLoc;
  Result.MaxIndentationLevel := TMethodIndentationCounter.CalculateMax(
    AMethodNode as TCompoundSyntaxNode
    );
  Result.CyclomaticComplexity := TMethodCyclomaticComplexity.Calculate(
    AMethodNode as TCompoundSyntaxNode
    );
end;

function TDelphiAnalyzer.AnalyzeRepository(
  const AFileNames: TArray<string>
  ): TAnalysisResult;
var
  MethodInfos: TList<TMethodInfo>;
  ParseFailures: TList<TParseFailure>;
  FileName: string;
  UnitSyntaxTree: TSyntaxNode;
  IsOk: boolean;
  UnitName: string;
  ParseFailure: TParseFailure;
  ImplementationNode: TSyntaxNode;
  Node: TSyntaxNode;
  MethodInfo: TMethodInfo;
begin
  MethodInfos := TList<TMethodInfo>.Create;
  ParseFailures := TList<TParseFailure>.Create;
  try
    for FileName in AFileNames do
    begin
      IsOk := FAstParser.TryParse(FileName, UnitSyntaxTree);
      if not IsOK then
      begin
        ParseFailure.FileName := FileName;
        ParseFailure.Message := FAstParser.GetFailureMessage();
        ParseFailures.Add(ParseFailure);
        Continue;
      end;

      UnitName := GetUnitName(FileName);

      ImplementationNode := UnitSyntaxTree.FindNode(ntImplementation);
      if ImplementationNode = nil then
        Continue;
        // Add support to scan method in DPR - no implementation node

      for Node in ImplementationNode.ChildNodes do
      begin
        if Node.Typ = ntMethod then
        begin
          MethodInfo := BuildMethodMetrics(Node, UnitName);
          MethodInfos.Add(MethodInfo);
        end;
      end;
    end;

    Result.MethodInfos := MethodInfos.ToArray;
    Result.ParseFailures := ParseFailures.ToArray;
  finally
    ParseFailures.Free;
    MethodInfos.Free;
  end;
end;

end.