unit Tests.SourceLens.ReportPrinter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSourceLensReportPrinterTests = class
  public
    [Test]
    procedure BuildReport_Csv_UsesLimitedColumnsOnly;
    [Test]
    procedure BuildReport_Json_ContainsStructuredPayload;
    [Test]
    procedure BuildReport_Markdown_ContainsTable;
  end;

implementation

uses
  SourceLens.ReportPrinter,
  SourceLens.Types;

function BuildSampleAnalysisResult(): TAnalysisResult;
begin
  SetLength(Result.MethodInfos, 2);
  Result.MethodInfos[0].UnitName := 'UnitA';
  Result.MethodInfos[0].ClassName := '';
  Result.MethodInfos[0].MethodName := 'ShortMethod';
  Result.MethodInfos[0].BodyLines := 1;

  Result.MethodInfos[1].UnitName := 'UnitB';
  Result.MethodInfos[1].ClassName := 'TWidget';
  Result.MethodInfos[1].MethodName := 'LongMethod';
  Result.MethodInfos[1].BodyLines := 7;

  SetLength(Result.ParseFailures, 1);
  Result.ParseFailures[0].FileName := 'C:\Broken.pas';
  Result.ParseFailures[0].Message := 'Unexpected token';
end;

procedure TSourceLensReportPrinterTests.BuildReport_Csv_UsesLimitedColumnsOnly;
var
  Report: string;
  LongerMethodPos: integer;
  ShortMethodPos: integer;
begin
  Report := TReportPrinter.BuildReport(BuildSampleAnalysisResult(), rfCsv);

  Assert.IsTrue(Pos('class_name,method_name,unit_name,body_lines', Report) = 1);
  Assert.IsTrue(Pos('parse_failures', Report) = 0);
  Assert.IsTrue(Pos('Total methods', Report) = 0);

  LongerMethodPos := Pos('TWidget,LongMethod,UnitB,7', Report);
  ShortMethodPos := Pos(',ShortMethod,UnitA,1', Report);
  Assert.IsTrue(LongerMethodPos > 0);
  Assert.IsTrue(ShortMethodPos > 0);
  Assert.IsTrue(LongerMethodPos < ShortMethodPos);
end;

procedure TSourceLensReportPrinterTests.BuildReport_Json_ContainsStructuredPayload;
var
  Report: string;
begin
  Report := TReportPrinter.BuildReport(BuildSampleAnalysisResult(), rfJson);

  Assert.IsTrue(Pos('"method_infos"', Report) > 0);
  Assert.IsTrue(Pos('"summary"', Report) > 0);
  Assert.IsTrue(Pos('"parse_failures"', Report) > 0);
  Assert.IsTrue(Pos('"class_name":"TWidget"', Report) > 0);
  Assert.IsTrue(Pos('"body_lines":7', Report) > 0);
end;

procedure TSourceLensReportPrinterTests.BuildReport_Markdown_ContainsTable;
var
  Report: string;
begin
  Report := TReportPrinter.BuildReport(BuildSampleAnalysisResult(), rfMarkdown);

  Assert.IsTrue(Pos('# SourceLens Report', Report) > 0);
  Assert.IsTrue(Pos('| Method name | Unit name | Body lines |', Report) > 0);
  Assert.IsTrue(Pos('| TWidget.LongMethod | UnitB | 7 |', Report) > 0);
  Assert.IsTrue(Pos('## Summary', Report) > 0);
end;

end.