program SourceLens;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SourceLens.Main in 'units\SourceLens.Main.pas',
  SemanticTools.FileScanner in 'units\SemanticTools.FileScanner.pas',
  SourceLens.Types in 'units\SourceLens.Types.pas',
  SourceLens.ReportPrinter in 'units\SourceLens.ReportPrinter.pas',
  SourceLens.DelphiAnalyzer in 'units\SourceLens.DelphiAnalyzer.pas',
  SemanticTools.Utils in 'units\SemanticTools.Utils.pas',
  SemanticTools.DelphiAstParser in 'units\SemanticTools.DelphiAstParser.pas',
  SourceLens.CliOptions in 'units\SourceLens.CliOptions.pas';

begin
  RunSourceLens();
end.
