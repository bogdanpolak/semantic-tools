unit Tests.SourceLens.DelphiAnalyzer;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Tests.SourceLens.Utils,
  SemanticTools.DelphiAstParser,
  SourceLens.DelphiAnalyzer,
  SourceLens.Types;

type
  [TestFixture]
  TDelphiAnalyzerTests = class
  private
    SUT: IDelphiAnalyzer;
    FAstParser: IAstParser;
    FFakeFileRepository: TFakeFileRepository;
    AnalysisResult: TAnalysisResult;
    MetodDefs: TArray<string>;
    procedure GivenFile(
      const AFileName: string;
      const AFileContent: array of string);
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure Analyze_SingleMethod;
    [Test]
    procedure AnalyzeTwoUnits_Broken_Valid;
    [Test]
    procedure AnalyzeUnits_MainApp_WorkerUnit;
    [Test]
    procedure AnalyzeUnits_IsolatedPerCall;
    [Test]
    procedure AnalyzeUnits_SupportsIncludesAndConditionalDirectives;
    [Test]
    procedure MaxIndentationLevel_IgnoresContinuationLines;
    [Test]
    procedure MaxIndentationLevel_IncludedMethod;
  end;

implementation


procedure TDelphiAnalyzerTests.Analyze_SingleMethod;
begin
  GivenFile('C:\Abc\Unit1.pas', [
    'unit Unit1;',
    '',
    'interface',
    '',
    'procedure PublicProcedure;',
    '',
    'implementation',
    '',
    'procedure PublicProcedure;',
    'begin',
    'end;',
    '',
    'function CheckIfHasMonopoly(',
    '  Game: TGame;',
    '  Tile: TTile;',
    '  Owner: TPlayer',
    '  ): boolean;',
    'var',
    '  OwnedTilesOfColor: integer;',
    '  Candidate: TTile;',
    'begin',
    '  OwnedTilesOfColor := 0;',
    '  for Candidate in Game.Board do',
    '  begin',
    '    if (Candidate.Color = Tile.Color) and Candidate.IsOwnedBy(Owner) then',
    '    begin',
    '      Inc(OwnedTilesOfColor);',
    '    end;',
    '  end;',
    '',
    '  if (Tile.Color = ''dark-purple'') or (Tile.Color = ''dark-blue'') then',
    '  begin',
    '    Exit(OwnedTilesOfColor = 2);',
    '  end;',
    '',
    '  Result := OwnedTilesOfColor = 3;',
    'end;',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository(['C:\Abc\Unit1.pas']);

  MetodDefs := GetFullMethodNames(AnalysisResult);
  Assert.AreEqual(2, Length(MetodDefs));
  Assert.AreEqual('Unit1 | PublicProcedure', MetodDefs[0]);
  Assert.AreEqual('Unit1 | CheckIfHasMonopoly', MetodDefs[1]);
  Assert.AreEqual(15, AnalysisResult.MethodInfos[1].BodyLines);
  Assert.AreEqual(6, AnalysisResult.MethodInfos[1].MaxIndentationLevel);
end;

procedure TDelphiAnalyzerTests.AnalyzeTwoUnits_Broken_Valid;
begin
  GivenFile('C:\Sources\BrokenUnit.pas', [
    'unit BrokenUnit;',
    '',
    'interface',
    '',
    'implementation',
    '',
    'procedure BrokenUnitMethod;',
    'begin'
  ]);

  GivenFile('C:\Sources\ValidUnit.pas', [
    'unit ValidUnit;',
    '',
    'interface',
    '',
    'type',
    '  TWidget = class',
    '  public',
    '    procedure PublicMethod;',
    '  private',
    '    procedure PrivateMethod;',
    '  end;',
    '',
    'procedure PublicProc;',
    '',
    'implementation',
    '',
    'procedure PublicProc;',
    'begin',
    'end;',
    '',
    'procedure TWidget.PublicMethod;',
    'begin',
    'end;',
    '',
    'procedure TWidget.PrivateMethod;',
    'begin',
    'end;',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository(
    ['C:\Sources\BrokenUnit.pas', 'C:\Sources\ValidUnit.pas']);

  Assert.AreEqual(1, Length(AnalysisResult.ParseFailures));
  Assert.AreEqual('C:\Sources\BrokenUnit.pas', AnalysisResult.ParseFailures[0].FileName);
  Assert.IsTrue(AnalysisResult.ParseFailures[0].Message <> '');

  MetodDefs := GetFullMethodNames(AnalysisResult);
  Assert.AreEqual(3, Length(MetodDefs));
  Assert.AreEqual('ValidUnit | PublicProc', MetodDefs[0]);
  Assert.AreEqual('ValidUnit | TWidget.PublicMethod', MetodDefs[1]);
  Assert.AreEqual('ValidUnit | TWidget.PrivateMethod', MetodDefs[2]);
end;

procedure TDelphiAnalyzerTests.AnalyzeUnits_MainApp_WorkerUnit;
begin
  GivenFile('C:\Src\UtilityProgram.pas', [
    'program UtilityProgram;',
    '',
    'begin',
    'end.'
  ]);

  GivenFile('C:\Src\WorkerUnit.pas', [
    'unit WorkerUnit;',
    '',
    'interface',
    '',
    'type',
    '  TWorker = class',
    '  public',
    '    procedure Execute;',
    '  end;',
    '',
    'implementation',
    '',
    'procedure TWorker.Execute;',
    'begin',
    'end;',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository([
    'C:\Src\UtilityProgram.pas',
    'C:\Src\WorkerUnit.pas']);

  Assert.AreEqual(0, Length(AnalysisResult.ParseFailures));

  MetodDefs := GetFullMethodNames(AnalysisResult);
  Assert.AreEqual(1, Length(MetodDefs));
  Assert.AreEqual('WorkerUnit | TWorker.Execute', MetodDefs[0]);
end;

procedure TDelphiAnalyzerTests.AnalyzeUnits_IsolatedPerCall;
var
  AnalysisResult1: TAnalysisResult;
  AnalysisResult2: TAnalysisResult;
  Names1: TArray<string>;
  Names2: TArray<string>;
begin
  GivenFile('C:\src\Unit1.pas', [
    'unit Unit1;',
    '',
    'interface',
    '',
    'type',
    '  TFirstRun = class',
    '  public',
    '    procedure FirstOnly;',
    '  end;',
    '',
    'implementation',
    '',
    'procedure TFirstRun.FirstOnly;',
    'begin',
    'end;',
    '',
    'end.'
  ]);

  GivenFile('C:\src\Unit2.pas', [
    'unit SecondRunUnit;',
    '',
    'interface',
    '',
    'type',
    '  TSecondRun = class',
    '  public',
    '    procedure SecondOnly;',
    '  end;',
    '',
    'implementation',
    '',
    'procedure TSecondRun.SecondOnly;',
    'begin',
    'end;',
    '',
    'end.'
  ]);

  AnalysisResult1 := SUT.AnalyzeRepository(['C:\src\Unit1.pas']);
  AnalysisResult2 := SUT.AnalyzeRepository(['C:\src\Unit2.pas']);

  Names1 := GetFullMethodNames(AnalysisResult1);
  Names2 := GetFullMethodNames(AnalysisResult2);
  Assert.AreEqual(1, Length(Names1));
  Assert.AreEqual('Unit1 | TFirstRun.FirstOnly', Names1[0]);
  Assert.AreEqual(1, Length(Names2));
  Assert.AreEqual('Unit2 | TSecondRun.SecondOnly', Names2[0]);
end;

procedure TDelphiAnalyzerTests.AnalyzeUnits_SupportsIncludesAndConditionalDirectives;
begin
  GivenFile('C:\Src\shared\MethodDeclaration.inc', [
    'procedure IncludedMethod;'
  ]);

  GivenFile('C:\Src\shared\MethodImplementation.inc', [
    'procedure TBox.IncludedMethod;',
    'begin',
    'end;'
  ]);

  GivenFile('C:\Src\BaseUnit.pas', [
    'unit BaseUnit;',
    '',
    'interface',
    '',
    'type',
    '  TBox = class',
    '  public',
    '    {$I shared\MethodDeclaration.inc}',
    '    {$IFDEF MSWINDOWS}',
    '    procedure WindowsOnlyMethod;',
    '    {$ENDIF}',
    '  end;',
    '',
    'implementation',
    '',
    '{$I shared\MethodImplementation.inc}',
    '',
    '{$IFDEF MSWINDOWS}',
    'procedure TBox.WindowsOnlyMethod;',
    'begin',
    '',
    'end;',
    '{$ENDIF}',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository(['C:\Src\BaseUnit.pas']);

  Assert.AreEqual(0, Length(AnalysisResult.ParseFailures));
  Assert.AreEqual(2, Length(AnalysisResult.MethodInfos));
  MetodDefs := GetFullMethodNames(AnalysisResult);
  Assert.AreEqual('BaseUnit | TBox.IncludedMethod', MetodDefs[0]);
  Assert.AreEqual('BaseUnit | TBox.WindowsOnlyMethod', MetodDefs[1]);
  Assert.AreEqual(0, AnalysisResult.MethodInfos[0].MaxIndentationLevel);
  Assert.AreEqual(0, AnalysisResult.MethodInfos[1].MaxIndentationLevel);
end;

procedure TDelphiAnalyzerTests.MaxIndentationLevel_IgnoresContinuationLines;
begin
  GivenFile('C:\Src\ContinuationUnit.pas', [
    'unit ContinuationUnit;',
    '',
    'interface',
    '',
    'type',
    '  TBox = class',
    '  public',
    '    procedure Measure;',
    '  end;',
    '',
    'implementation',
    '',
    'procedure TBox.Measure;',
    'begin',
    '  ResultText := Format(',
    '    ''%s %d'',',
    '    [',
    '      FirstValue,',
    '      Length(SecondValue)',
    '    ]',
    '  );',
    'end;',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository(['C:\Src\ContinuationUnit.pas']);

  Assert.AreEqual(0, Length(AnalysisResult.ParseFailures));
  Assert.AreEqual(1, Length(AnalysisResult.MethodInfos));
  Assert.AreEqual(2, AnalysisResult.MethodInfos[0].MaxIndentationLevel);
end;

procedure TDelphiAnalyzerTests.MaxIndentationLevel_IncludedMethod;
begin
  GivenFile('C:\Src\shared\IndentedMethodImplementation.inc', [
    'procedure TBox.IncludedMethod;',
    'begin',
    '  if Ready then',
    '    begin',
    '      if Confirmed then',
    '      begin',
    '        RunFirst;',
    '      end;',
    '    end;',
    'end;'
  ]);

  GivenFile('C:\Src\IncludedIndentationUnit.pas', [
    'unit IncludedIndentationUnit;',
    '',
    'interface',
    '',
    'type',
    '  TBox = class',
    '  public',
    '    procedure IncludedMethod;',
    '  end;',
    '',
    'implementation',
    '',
    '{$I shared\IndentedMethodImplementation.inc}',
    '',
    'end.'
  ]);

  AnalysisResult := SUT.AnalyzeRepository(['C:\Src\IncludedIndentationUnit.pas']);

  Assert.AreEqual(0, Length(AnalysisResult.ParseFailures));
  Assert.AreEqual(1, Length(AnalysisResult.MethodInfos));
  Assert.AreEqual(8, AnalysisResult.MethodInfos[0].MaxIndentationLevel);
end;

procedure TDelphiAnalyzerTests.GivenFile(const AFileName: string;
  const AFileContent: array of string);
begin
  FFakeFileRepository.AddStringsAsFile(AFileName, AFileContent);
end;

procedure TDelphiAnalyzerTests.Setup;
begin
  FFakeFileRepository := TFakeFileRepository.Create;
  FAstParser := CreateAstParser(FFakeFileRepository);
  SUT := TDelphiAnalyzer.Create(FAstParser);
end;


initialization
  TDUnitX.RegisterTestFixture(TDelphiAnalyzerTests);

end.