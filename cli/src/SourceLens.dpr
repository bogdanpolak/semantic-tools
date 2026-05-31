program SourceLens;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SourceLens.Main in 'units\SourceLens.Main.pas',
  SourceLens.FileScanner in 'units\SourceLens.FileScanner.pas',
  SourceLens.Types in 'units\SourceLens.Types.pas',
  SourceLens.Extractor.PublicMethods in 'units\SourceLens.Extractor.PublicMethods.pas',
  SourceLens.ReportPrinter in 'units\SourceLens.ReportPrinter.pas',
  SourceLens.DelphiAnalyzer in 'units\SourceLens.DelphiAnalyzer.pas',
  SourceLens.Utils in 'units\SourceLens.Utils.pas',
  SourceLens.ParserEnvironment in 'units\SourceLens.ParserEnvironment.pas';

begin
  RunSourceLens();
end.
