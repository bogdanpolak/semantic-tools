unit SourceLens.ReportPrinter;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  SourceLens.Types;

type
  TReportPrinter = class
  public
    class function BuildReport(
      const AnalysisResult: TAnalysisResult;
      const AFormat: TReportFormat
      ): string;
    class procedure Print(const AnalysisResult: TAnalysisResult); overload;
    class procedure Print(
      const AnalysisResult: TAnalysisResult;
      const AFormat: TReportFormat
      ); overload;
  end;

implementation

uses
  System.Classes;

type
  TReportSummary = record
    TotalMethods: integer;
    TotalLines: integer;
    ParseFailureCount: integer;
    AverageBodyLines: double;
    HasLargestMethod: boolean;
    LargestMethod: TMethodInfo;
  end;

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

function GetQualifiedMethodName(const MethodInfo: TMethodInfo): string;
begin
  if MethodInfo.ClassName <> '' then
    Result := MethodInfo.ClassName + '.' + MethodInfo.MethodName
  else
    Result := MethodInfo.MethodName;
end;

function GetSortedMethodInfos(
  const AnalysisResult: TAnalysisResult
  ): TArray<TMethodInfo>;
var
  Info: TMethodInfo;
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

    Result := SortedMethods.ToArray;
  finally
    SortedMethods.Free;
  end;
end;

function BuildSummary(const AnalysisResult: TAnalysisResult): TReportSummary;
var
  Info: TMethodInfo;
begin
  Result.TotalMethods := Length(AnalysisResult.MethodInfos);
  Result.TotalLines := 0;
  Result.ParseFailureCount := Length(AnalysisResult.ParseFailures);
  Result.AverageBodyLines := 0;
  Result.HasLargestMethod := False;

  for Info in AnalysisResult.MethodInfos do
  begin
    Result.TotalLines := Result.TotalLines + Info.BodyLines;

    if (not Result.HasLargestMethod)
      or (Info.BodyLines > Result.LargestMethod.BodyLines) then
    begin
      Result.HasLargestMethod := True;
      Result.LargestMethod := Info;
    end;
  end;

  if Result.TotalMethods > 0 then
    Result.AverageBodyLines := Result.TotalLines / Result.TotalMethods;
end;

function EscapeJsonString(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

function EscapeMarkdown(const AValue: string): string;
begin
  Result := StringReplace(AValue, '|', '\|', [rfReplaceAll]);
end;

function EscapeCsv(const AValue: string): string;
begin
  Result := StringReplace(AValue, '"', '""', [rfReplaceAll]);
  if (Pos(',', Result) > 0)
    or (Pos('"', Result) > 0)
    or (Pos(#13, Result) > 0)
    or (Pos(#10, Result) > 0) then
    Result := '"' + Result + '"';
end;

function FormatAverage(const AValue: double): string;
var
  FormatSettings: TFormatSettings;
begin
  FormatSettings := TFormatSettings.Create;
  FormatSettings.DecimalSeparator := '.';
  Result := FormatFloat('0.0', AValue, FormatSettings);
end;

function FormatMethodInfo(const MethodInfo: TMethodInfo): string;
var
  QualifiedMethodName: string;
begin
  QualifiedMethodName := GetQualifiedMethodName(MethodInfo);

  Result := Format('  %-55s %-28s %5d %7d %10d',
    [
      QualifiedMethodName,
      MethodInfo.UnitName,
      MethodInfo.BodyLines,
      MethodInfo.MaxIndentationLevel,
      MethodInfo.CyclomaticComplexity
    ]);
end;

function BuildTextReport(const AnalysisResult: TAnalysisResult): string;
var
  Builder: TStringBuilder;
  Info: TMethodInfo;
  ParseFailure: TParseFailure;
  Summary: TReportSummary;
  SortedMethods: TArray<TMethodInfo>;
begin
  Builder := TStringBuilder.Create;
  try
    SortedMethods := GetSortedMethodInfos(AnalysisResult);
    Summary := BuildSummary(AnalysisResult);

    Builder.AppendLine('=== SourceLens Report ===');
    Builder.AppendLine;
    Builder.AppendLine(
      Format(
        '  %-55s %-28s %5s %7s %10s',
        ['Method name', 'Unit name', 'Size', 'Indent', 'Complexity']
        )
      );
    Builder.Append('  ');
    Builder.Append(StringOfChar('-', 55));
    Builder.Append(' ');
    Builder.Append(StringOfChar('-', 28));
    Builder.Append(' ');
    Builder.Append(StringOfChar('-', 5));
    Builder.Append(' ');
    Builder.Append(StringOfChar('-', 7));
    Builder.Append(' ');
    Builder.AppendLine(StringOfChar('-', 10));

    for Info in SortedMethods do
      Builder.AppendLine(FormatMethodInfo(Info));

    Builder.AppendLine;
    Builder.AppendLine('=== Summary ===');
    Builder.AppendLine(Format('  Total methods:      %d', [Summary.TotalMethods]));
    Builder.AppendLine(Format('  Total body lines:   %d', [Summary.TotalLines]));
    Builder.AppendLine(Format('  Parse failures:     %d', [Summary.ParseFailureCount]));
    if Summary.TotalMethods > 0 then
      Builder.AppendLine(
        Format('  Average body lines: %s', [FormatAverage(Summary.AverageBodyLines)])
        );
    if Summary.HasLargestMethod then
      Builder.AppendLine(
        Format(
          '  Largest method:     %s (%d lines)',
          [GetQualifiedMethodName(Summary.LargestMethod), Summary.LargestMethod.BodyLines]
          )
        );

    if Length(AnalysisResult.ParseFailures) > 0 then
    begin
      Builder.AppendLine;
      Builder.AppendLine('=== Parse Failures ===');
      for ParseFailure in AnalysisResult.ParseFailures do
        Builder.AppendLine(
          Format('  %s: %s', [ParseFailure.FileName, ParseFailure.Message])
          );
    end;

    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function BuildMarkdownReport(const AnalysisResult: TAnalysisResult): string;
var
  Builder: TStringBuilder;
  Info: TMethodInfo;
  ParseFailure: TParseFailure;
  Summary: TReportSummary;
  SortedMethods: TArray<TMethodInfo>;
begin
  Builder := TStringBuilder.Create;
  try
    SortedMethods := GetSortedMethodInfos(AnalysisResult);
    Summary := BuildSummary(AnalysisResult);

    Builder.AppendLine('# SourceLens Report');
    Builder.AppendLine;
    Builder.AppendLine('| Method name | Unit name | Body lines | Max indentation | Cyclomatic complexity |');
    Builder.AppendLine('| --- | --- | ---: | ---: | ---: |');
    for Info in SortedMethods do
      Builder.AppendLine(
        Format(
          '| %s | %s | %d | %d | %d |',
          [
            EscapeMarkdown(GetQualifiedMethodName(Info)),
            EscapeMarkdown(Info.UnitName),
            Info.BodyLines,
            Info.MaxIndentationLevel,
            Info.CyclomaticComplexity
          ]
          )
        );

    Builder.AppendLine;
    Builder.AppendLine('## Summary');
    Builder.AppendLine;
    Builder.AppendLine(Format('- Total methods: %d', [Summary.TotalMethods]));
    Builder.AppendLine(Format('- Total body lines: %d', [Summary.TotalLines]));
    Builder.AppendLine(Format('- Parse failures: %d', [Summary.ParseFailureCount]));
    if Summary.TotalMethods > 0 then
      Builder.AppendLine(
        Format('- Average body lines: %s', [FormatAverage(Summary.AverageBodyLines)])
        );
    if Summary.HasLargestMethod then
      Builder.AppendLine(
        Format(
          '- Largest method: %s (%d lines)',
          [GetQualifiedMethodName(Summary.LargestMethod), Summary.LargestMethod.BodyLines]
          )
        );

    if Length(AnalysisResult.ParseFailures) > 0 then
    begin
      Builder.AppendLine;
      Builder.AppendLine('## Parse Failures');
      Builder.AppendLine;
      for ParseFailure in AnalysisResult.ParseFailures do
        Builder.AppendLine(
          Format(
            '- %s: %s',
            [EscapeMarkdown(ParseFailure.FileName), EscapeMarkdown(ParseFailure.Message)]
            )
          );
    end;

    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function BuildJsonMethodInfo(const Info: TMethodInfo): string;
begin
  Result := Format(
    '    {"class_name":"%s","method_name":"%s","unit_name":"%s","body_lines":%d,"max_indentation_level":%d,"cyclomatic_complexity":%d}',
    [
      EscapeJsonString(Info.ClassName),
      EscapeJsonString(Info.MethodName),
      EscapeJsonString(Info.UnitName),
      Info.BodyLines,
      Info.MaxIndentationLevel,
      Info.CyclomaticComplexity
    ]
    );
end;

function BuildJsonParseFailure(const ParseFailure: TParseFailure): string;
begin
  Result := Format(
    '    {"file_name":"%s","message":"%s"}',
    [EscapeJsonString(ParseFailure.FileName), EscapeJsonString(ParseFailure.Message)]
    );
end;

function BuildJsonReport(const AnalysisResult: TAnalysisResult): string;
var
  Builder: TStringBuilder;
  Index: integer;
  Summary: TReportSummary;
  SortedMethods: TArray<TMethodInfo>;
begin
  Builder := TStringBuilder.Create;
  try
    SortedMethods := GetSortedMethodInfos(AnalysisResult);
    Summary := BuildSummary(AnalysisResult);

    Builder.AppendLine('{');
    Builder.AppendLine('  "method_infos": [');
    for Index := 0 to High(SortedMethods) do
    begin
      Builder.Append(BuildJsonMethodInfo(SortedMethods[Index]));
      if Index < High(SortedMethods) then
        Builder.AppendLine(',')
      else
        Builder.AppendLine;
    end;
    Builder.AppendLine('  ],');
    Builder.AppendLine('  "summary": {');
    Builder.AppendLine(Format('    "total_methods": %d,', [Summary.TotalMethods]));
    Builder.AppendLine(Format('    "total_body_lines": %d,', [Summary.TotalLines]));
    Builder.AppendLine(Format('    "parse_failures": %d,', [Summary.ParseFailureCount]));
    Builder.AppendLine(
      Format('    "average_body_lines": %s,', [FormatAverage(Summary.AverageBodyLines)])
      );
    Builder.Append('    "largest_method": ');
    if Summary.HasLargestMethod then
      Builder.AppendLine(
        Format(
          '{"class_name":"%s","method_name":"%s","unit_name":"%s","body_lines":%d,"max_indentation_level":%d,"cyclomatic_complexity":%d}',
          [
            EscapeJsonString(Summary.LargestMethod.ClassName),
            EscapeJsonString(Summary.LargestMethod.MethodName),
            EscapeJsonString(Summary.LargestMethod.UnitName),
            Summary.LargestMethod.BodyLines,
            Summary.LargestMethod.MaxIndentationLevel,
            Summary.LargestMethod.CyclomaticComplexity
          ]
          )
        )
    else
      Builder.AppendLine('null');
    Builder.AppendLine('  },');
    Builder.AppendLine('  "parse_failures": [');
    for Index := 0 to High(AnalysisResult.ParseFailures) do
    begin
      Builder.Append(BuildJsonParseFailure(AnalysisResult.ParseFailures[Index]));
      if Index < High(AnalysisResult.ParseFailures) then
        Builder.AppendLine(',')
      else
        Builder.AppendLine;
    end;
    Builder.AppendLine('  ]');
    Builder.Append('}');

    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

function BuildCsvReport(const AnalysisResult: TAnalysisResult): string;
var
  Builder: TStringBuilder;
  Info: TMethodInfo;
  SortedMethods: TArray<TMethodInfo>;
begin
  Builder := TStringBuilder.Create;
  try
    SortedMethods := GetSortedMethodInfos(AnalysisResult);
    Builder.AppendLine(
      'class_name,method_name,unit_name,body_lines,max_indentation_level,cyclomatic_complexity'
      );
    for Info in SortedMethods do
      Builder.AppendLine(
        Format(
          '%s,%s,%s,%d,%d,%d',
          [
            EscapeCsv(Info.ClassName),
            EscapeCsv(Info.MethodName),
            EscapeCsv(Info.UnitName),
            Info.BodyLines,
            Info.MaxIndentationLevel,
            Info.CyclomaticComplexity
          ]
          )
        );

    Result := Builder.ToString;
  finally
    Builder.Free;
  end;
end;

class function TReportPrinter.BuildReport(
  const AnalysisResult: TAnalysisResult;
  const AFormat: TReportFormat
  ): string;
begin
  case AFormat of
    rfText:
      Result := BuildTextReport(AnalysisResult);
    rfMarkdown:
      Result := BuildMarkdownReport(AnalysisResult);
    rfJson:
      Result := BuildJsonReport(AnalysisResult);
    rfCsv:
      Result := BuildCsvReport(AnalysisResult);
  else
    raise Exception.Create('Unsupported report format');
  end;
end;

class procedure TReportPrinter.Print(const AnalysisResult: TAnalysisResult);
begin
  Print(AnalysisResult, rfText);
end;

class procedure TReportPrinter.Print(
  const AnalysisResult: TAnalysisResult;
  const AFormat: TReportFormat
  );
begin
  Write(BuildReport(AnalysisResult, AFormat));
end;

end.