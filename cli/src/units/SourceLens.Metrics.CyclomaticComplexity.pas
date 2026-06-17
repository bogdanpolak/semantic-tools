unit SourceLens.Metrics.CyclomaticComplexity;

interface

uses
  DelphiAST.Consts,
  DelphiAST.Classes;

type
  TDecisionSyntaxNodeTypes = set of TSyntaxNodeType;

  TMethodCyclomaticComplexity = class
    class function Calculate(
      const AMethodNode: TCompoundSyntaxNode
      ): integer;
  end;

implementation

const
  DecisionNodeTypes: TDecisionSyntaxNodeTypes = [
    ntCaseElse,
    ntCaseLabel,
    ntExceptionHandler,
    ntFor,
    ntIf,
    ntRepeat,
    ntWhile
  ];

function CountDecisionPoints(const ANode: TSyntaxNode): integer;
var
  ChildNode: TSyntaxNode;
  HasExceptionHandlers: boolean;
begin
  if (ANode = nil)
    or (ANode.Typ = ntMethod)
    or (ANode.Typ = ntAnonymousMethod) then
    Exit(0);

  Result := 0;

  if ANode.Typ in DecisionNodeTypes then
    Inc(Result);

  if ANode.Typ = ntExcept then
  begin
    HasExceptionHandlers := False;
    for ChildNode in ANode.ChildNodes do
      if ChildNode.Typ = ntExceptionHandler then
      begin
        HasExceptionHandlers := True;
        Break;
      end;

    if not HasExceptionHandlers then
      Inc(Result);
  end;

  for ChildNode in ANode.ChildNodes do
    Inc(Result, CountDecisionPoints(ChildNode));
end;

class function TMethodCyclomaticComplexity.Calculate(
  const AMethodNode: TCompoundSyntaxNode
  ): integer;
var
  StatementsNode: TSyntaxNode;
begin
  Result := 1;
  StatementsNode := AMethodNode.FindNode(ntStatements);
  if StatementsNode = nil then
    Exit;

  Inc(Result, CountDecisionPoints(StatementsNode));
end;

end.