unit Tests.SourceLens.CliOptions;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TSourceLensCliOptionsTests = class
  public
    [Test]
    procedure Parse_NoArgs_UsesDefaults;
    [Test]
    procedure Parse_SupportsLongAndShortFlags;
    [Test]
    procedure HelpText_ListsFlagsAndDefaults;
    [Test]
    procedure Parse_InvalidFormat_RaisesCommandLineError;
  end;

implementation

uses
  System.SysUtils,
  SourceLens.CliOptions,
  SourceLens.Types;

procedure TSourceLensCliOptionsTests.HelpText_ListsFlagsAndDefaults;
var
  HelpText: string;
begin
  HelpText := TSourceLensCommandLine.GetHelpText();

  Assert.IsTrue(Pos('--working-dir, -w', HelpText) > 0);
  Assert.IsTrue(Pos('--test-dir, -t', HelpText) > 0);
  Assert.IsTrue(Pos('--format, -f <txt|md|json|csv>', HelpText) > 0);
  Assert.IsTrue(Pos('--help, -h', HelpText) > 0);
  Assert.IsTrue(Pos(DefaultWorkingDir, HelpText) > 0);
  Assert.IsTrue(Pos(DefaultTestDir, HelpText) > 0);
  Assert.IsTrue(Pos('Default: txt', HelpText) > 0);
end;

procedure TSourceLensCliOptionsTests.Parse_InvalidFormat_RaisesCommandLineError;
var
  Raised: boolean;
begin
  Raised := False;

  try
    TSourceLensCommandLine.Parse(['--format', 'xml']);
  except
    on E: ECommandLineError do
    begin
      Raised := True;
      Assert.IsTrue(Pos('Unsupported format', E.Message) > 0);
    end;
  end;

  Assert.IsTrue(Raised);
end;

procedure TSourceLensCliOptionsTests.Parse_NoArgs_UsesDefaults;
var
  Options: TSourceLensOptions;
begin
  Options := TSourceLensCommandLine.Parse([]);

  Assert.AreEqual(DefaultWorkingDir, Options.WorkingDir);
  Assert.AreEqual(DefaultTestDir, Options.TestDir);
  Assert.AreEqual(integer(rfText), integer(Options.ReportFormat));
  Assert.IsFalse(Options.ShowHelp);
end;

procedure TSourceLensCliOptionsTests.Parse_SupportsLongAndShortFlags;
var
  Options: TSourceLensOptions;
begin
  Options := TSourceLensCommandLine.Parse([
    '-w', 'C:\Src',
    '--test-dir=C:\Tests',
    '-f', 'json',
    '-h'
  ]);

  Assert.AreEqual('C:\Src', Options.WorkingDir);
  Assert.AreEqual('C:\Tests', Options.TestDir);
  Assert.AreEqual(integer(rfJson), integer(Options.ReportFormat));
  Assert.IsTrue(Options.ShowHelp);
end;

end.