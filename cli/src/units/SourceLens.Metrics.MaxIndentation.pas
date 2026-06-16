unit SourceLens.Metrics.MaxIndentation;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  DelphiAST.Consts,
  DelphiAST.Classes;

type
  TMetricSyntaxNodeTypes = set of TSyntaxNodeType;

  TMethodIndentationCounter = class
    class function CalculateMax(
      const AMethodNode: TCompoundSyntaxNode
      ): integer;
  end;

implementation

const
  ExecutableMetricNodeTypes: TMetricSyntaxNodeTypes = [
    ntAssign,
    ntCase,
    ntCaseElse,
    ntCaseLabel,
    ntCall,
    ntElse,
    ntExcept,
    ntExceptionHandler,
    ntFinally,
    ntFor,
    ntGoto,
    ntIf,
    ntInherited,
    ntRaise,
    ntRepeat,
    ntTry,
    ntVariables,
    ntWhile,
    ntWith
  ];

  NestedMetricNodeTypes: TMetricSyntaxNodeTypes = [
    ntAnonymousMethod,
    ntCase,
    ntCaseElse,
    ntCaseLabel,
    ntElse,
    ntExcept,
    ntExceptionHandler,
    ntFinally,
    ntFor,
    ntIf,
    ntRepeat,
    ntStatements,
    ntThen,
    ntTry,
    ntWhile,
    ntWith
  ];

function NormalizeMetricFileName(const AFileName: string): string;
begin
  if AFileName = '' then
    Exit('');

  Result := AnsiLowerCase(TPath.GetFullPath(AFileName));
end;

function BuildMetricLineKey(const ANode: TSyntaxNode): string;
begin
  Result := NormalizeMetricFileName(ANode.FileName) + '|' +
    IntToStr(ANode.Line);
end;

function HasInlineVariableInitializer(const ANode: TSyntaxNode): boolean;
var
  ChildNode: TSyntaxNode;
begin
  if ANode.Typ <> ntVariables then
    Exit(False);

  for ChildNode in ANode.ChildNodes do
    if ChildNode.Typ = ntAssign then
      Exit(True);

  Result := False;
end;

function IsExecutableMetricNode(const ANode: TSyntaxNode): boolean;
begin
  if ANode.Typ = ntVariables then
    Exit(HasInlineVariableInitializer(ANode));

  Result := ANode.Typ in ExecutableMetricNodeTypes;
end;

function IsNestedMetricNode(const ANode: TSyntaxNode): boolean;
begin
  Result := ANode.Typ in NestedMetricNodeTypes;
end;

procedure TrackExecutableLineStart(
  const ANode: TSyntaxNode;
  ALineStarts: TDictionary<string, integer>
  );
var
  LineKey: string;
  ExistingColumn: integer;
  ColumnIndex: integer;
begin
  if not IsExecutableMetricNode(ANode) then
    Exit;

  if (ANode.Line <= 0) or (ANode.Col <= 0) then
    Exit;

  ColumnIndex := ANode.Col - 1;
  LineKey := BuildMetricLineKey(ANode);
  if ALineStarts.TryGetValue(LineKey, ExistingColumn) then
  begin
    if ColumnIndex < ExistingColumn then
      ALineStarts[LineKey] := ColumnIndex;
  end
  else
    ALineStarts.Add(LineKey, ColumnIndex);
end;

procedure CollectExecutableLineStarts(
  const ANode: TSyntaxNode;
  ALineStarts: TDictionary<string, integer>
  ); forward;

procedure CollectAnonymousMethodLineStarts(
  const ANode: TSyntaxNode;
  ALineStarts: TDictionary<string, integer>
  );
var
  ChildNode: TSyntaxNode;
  StatementsNode: TSyntaxNode;
begin
  if ANode.Typ = ntAnonymousMethod then
  begin
    StatementsNode := ANode.FindNode(ntStatements);
    if StatementsNode <> nil then
      CollectExecutableLineStarts(StatementsNode, ALineStarts);
    Exit;
  end;

  for ChildNode in ANode.ChildNodes do
    CollectAnonymousMethodLineStarts(ChildNode, ALineStarts);
end;

procedure CollectExecutableLineStarts(
  const ANode: TSyntaxNode;
  ALineStarts: TDictionary<string, integer>
  );
var
  ChildNode: TSyntaxNode;
begin
  TrackExecutableLineStart(ANode, ALineStarts);

  for ChildNode in ANode.ChildNodes do
  begin
    if ChildNode.Typ = ntMethod then
      Continue;

    if IsNestedMetricNode(ChildNode) or IsExecutableMetricNode(ChildNode) then
      CollectExecutableLineStarts(ChildNode, ALineStarts)
    else
      CollectAnonymousMethodLineStarts(ChildNode, ALineStarts);
  end;
end;

class function TMethodIndentationCounter.CalculateMax(
  const AMethodNode: TCompoundSyntaxNode
  ): integer;
var
  StatementsNode: TSyntaxNode;
  LineStarts: TDictionary<string, integer>;
  LineStart: TPair<string, integer>;
begin
  Result := 0;
  StatementsNode := AMethodNode.FindNode(ntStatements);
  if StatementsNode = nil then
    Exit;

  LineStarts := TDictionary<string, integer>.Create;
  try
    CollectExecutableLineStarts(StatementsNode, LineStarts);

    for LineStart in LineStarts do
      if LineStart.Value > Result then
        Result := LineStart.Value;
  finally
    LineStarts.Free;
  end;
end;

end.