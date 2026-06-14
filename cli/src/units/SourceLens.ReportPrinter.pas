unit SourceLens.ReportPrinter;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  SourceLens.Types;

type
  TReportPrinter = class
  public
    class procedure Print(const AnalysisResult: TAnalysisResult);
  end;

implementation

function CompareMethodInfo(const Left, Right: TMethodInfo): integer;
var
  LeftQualifiedName: string;
  RightQualifiedName: string;
begin
  if Left.BodyLines > Right.BodyLines then
    Exit(-1);

  if Left.BodyLines < Right.BodyLines then
    Exit(1);

  Result := CompareText(Left.UnitName, Right.UnitName);
  if Result <> 0 then
    Exit;

  if Left.ClassName <> '' then
    LeftQualifiedName := Left.ClassName + '.' + Left.MethodName
  else
    LeftQualifiedName := Left.MethodName;

  if Right.ClassName <> '' then
    RightQualifiedName := Right.ClassName + '.' + Right.MethodName
  else
    RightQualifiedName := Right.MethodName;

  Result := CompareText(LeftQualifiedName, RightQualifiedName);
end;

function FormatMethodInfo(const MethodInfo: TMethodInfo): string;
var
  QualifiedMethodName: string;
begin
  if MethodInfo.ClassName <> '' then
    QualifiedMethodName := MethodInfo.ClassName + '.' + MethodInfo.MethodName
  else
    QualifiedMethodName := MethodInfo.MethodName;

  Result := Format('  %-55s %-28s %5d',
    [QualifiedMethodName, MethodInfo.UnitName, MethodInfo.BodyLines]);
end;

class procedure TReportPrinter.Print(const AnalysisResult: TAnalysisResult);
var
  Info: TMethodInfo;
  ParseFailure: TParseFailure;
  Line: string;
  TotalMethods: integer;
  TotalLines: integer;
  MaxLines: integer;
  MaxMethodName: string;
  SortedMethods: TList<TMethodInfo>;
begin
  SortedMethods := TList<TMethodInfo>.Create;
  try
    for Info in AnalysisResult.MethodInfos do
      SortedMethods.Add(Info);

    SortedMethods.Sort(
      TComparer<TMethodInfo>.Construct(
        function(const Left, Right: TMethodInfo): Integer
        begin
          Result := CompareMethodInfo(Left, Right);
        end
      )
    );

    WriteLn;
    WriteLn('=== SourceLens Report ===');
    WriteLn;
    WriteLn(Format('  %-55s %-28s %5s', ['Method name', 'Unit name', 'Size']));
    WriteLn('  ', StringOfChar('-', 55), ' ', StringOfChar('-', 28),
      ' ', StringOfChar('-', 5));

    TotalMethods := SortedMethods.Count;
    TotalLines := 0;
    MaxLines := 0;
    MaxMethodName := '';

    for Info in SortedMethods do
    begin
      Line := FormatMethodInfo(Info);
      WriteLn(Line);

      TotalLines := TotalLines + Info.BodyLines;
      if Info.BodyLines > MaxLines then
      begin
        MaxLines := Info.BodyLines;
        if Info.ClassName <> '' then
          MaxMethodName := Info.ClassName + '.' + Info.MethodName
        else
          MaxMethodName := Info.MethodName;
      end;
    end;

    WriteLn;
    WriteLn('=== Summary ===');
    WriteLn(Format('  Total methods:      %d', [TotalMethods]));
    WriteLn(Format('  Total body lines:   %d', [TotalLines]));
    WriteLn(Format('  Parse failures:     %d',
      [Length(AnalysisResult.ParseFailures)]));
    if TotalMethods > 0 then
      WriteLn(Format('  Average body lines: %.1f',
        [TotalLines / TotalMethods]));
    if MaxLines > 0 then
      WriteLn(Format('  Largest method:     %s (%d lines)',
        [MaxMethodName, MaxLines]));
    WriteLn;

    if Length(AnalysisResult.ParseFailures) > 0 then
    begin
      WriteLn('=== Parse Failures ===');
      WriteLn;
      for ParseFailure in AnalysisResult.ParseFailures do
        WriteLn('  ', ParseFailure.FileName, ': ', ParseFailure.Message);
      WriteLn;
    end;
  finally
    SortedMethods.Free;
  end;
end;

end.