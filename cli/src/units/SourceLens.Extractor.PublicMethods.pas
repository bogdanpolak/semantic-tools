unit SourceLens.Extractor.PublicMethods;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiAST,
  DelphiAST.Consts,
  DelphiAST.Classes;

type
  TPublicMethodExtractor = class
  private
    class procedure ScanTypeDeclaration(
      const ATypeNode: TSyntaxNode;
      APublicMethods: TDictionary<string, string>
      ); static;
    class procedure ScanVisibilitySection(
      const ASectionNode: TSyntaxNode;
      const AClassName: string;
      APublicMethods: TDictionary<string, string>
      );
  public
    class function Extract(
      const ASyntaxTree: TSyntaxNode;
      const AUnitName: string
      ): TArray<string>; static;
  end;

implementation

uses
  SourceLens.Utils;

class function TPublicMethodExtractor.Extract(
    const ASyntaxTree: TSyntaxNode;
  const AUnitName: string
  ): TArray<string>;
var
  InterfaceNode: TSyntaxNode;
  Node: TSyntaxNode;
  MethodName: string;
  ClassName: string;
  MethodDictionary: TDictionary<string, string>;
  Idx: integer;
  Methods :TArray<TPair<string, string>>;
begin
  InterfaceNode := ASyntaxTree.FindNode(ntInterface);
  if InterfaceNode = nil then
    Exit;

  MethodDictionary := TDictionary<string, string>.Create;
  try
    for Node in InterfaceNode.ChildNodes do
    begin
      if Node.Typ = ntMethod then
      begin
        MethodName := Node.GetAttribute(anName);
        MethodDictionary.AddOrSetValue(MethodName.ToLower, '');
      end
      else if Node.Typ = ntTypeSection then
        ScanTypeDeclaration(Node, MethodDictionary);
    end;

    SetLength(Result, MethodDictionary.Count);
    Methods := MethodDictionary.ToArray;
    for Idx := 0 to MethodDictionary.Count-1 do
    begin
      ClassName := Methods[Idx].Value;
      MethodName := Methods[Idx].Key;
      Result[Idx] := GetFullyQualifiedName(AUnitName, ClassName, MethodName);
    end;
  finally
    MethodDictionary.Free;
  end;
end;

class procedure TPublicMethodExtractor.ScanTypeDeclaration(
  const ATypeNode: TSyntaxNode; APublicMethods: TDictionary<string, string>);
var
  Child: TSyntaxNode;
  SectionChild: TSyntaxNode;
  TypeChild: TSyntaxNode;
  ClassName: string;
  MethodName: string;
  QualifiedName: string;
begin
  for TypeChild in ATypeNode.ChildNodes do
  begin
    if TypeChild.Typ = ntTypeDecl then
    begin
      ClassName := TypeChild.GetAttribute(anName);
      for Child in TypeChild.ChildNodes do
      begin
        if Child.Typ = ntType then
        begin
          for SectionChild in Child.ChildNodes do
          begin
            if SectionChild.Typ = ntPublic then
            begin
              ScanVisibilitySection(SectionChild, ClassName, APublicMethods);
            end
            else if SectionChild.Typ = ntPublished then
            begin
              ScanVisibilitySection(SectionChild, ClassName, APublicMethods);
            end
            else if SectionChild.Typ = ntMethod then
            begin
              MethodName := SectionChild.GetAttribute(anName);
              QualifiedName := ClassName + '.' + MethodName;
              APublicMethods.AddOrSetValue(QualifiedName.ToLower, ClassName);
            end;
          end;
        end;
      end;
    end;
  end;
end;

class procedure TPublicMethodExtractor.ScanVisibilitySection(
  const ASectionNode: TSyntaxNode;
  const AClassName: string;
  APublicMethods: TDictionary<string, string>
  );
var
  Child: TSyntaxNode;
  MethodName: string;
  QualifiedName: string;
begin
  for Child in ASectionNode.ChildNodes do
  begin
    if Child.Typ = ntMethod then
    begin
      MethodName := Child.GetAttribute(anName);
      if AClassName <> '' then
        QualifiedName := AClassName + '.' + MethodName
      else
        QualifiedName := MethodName;

      APublicMethods.AddOrSetValue(QualifiedName.ToLower, AClassName);
    end;
  end;
end;

end.