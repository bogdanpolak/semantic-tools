unit SourceLens.CliOptions;

interface

uses
  System.SysUtils,
  SourceLens.Types;

const
  DefaultWorkingDir = '..\monopoly\src';
  DefaultTestDir = '..\monopoly\tests';

type
  ECommandLineError = class(Exception);

  TSourceLensOptions = record
    WorkingDir: string;
    TestDir: string;
    ReportFormat: TReportFormat;
    ShowHelp: boolean;
  end;

  TSourceLensCommandLine = class
  public
    class function DefaultOptions(): TSourceLensOptions;
    class function GetHelpText(): string;
    class function Parse(const AArgs: TArray<string>): TSourceLensOptions;
  end;

implementation

uses
  System.StrUtils;

function ReportFormatToString(const AFormat: TReportFormat): string;
begin
  case AFormat of
    rfText:
      Result := 'txt';
    rfMarkdown:
      Result := 'md';
    rfJson:
      Result := 'json';
    rfCsv:
      Result := 'csv';
  else
    raise ECommandLineError.Create('Unsupported report format value');
  end;
end;

function TryParseReportFormat(
  const AValue: string;
  out AFormat: TReportFormat
  ): boolean;
begin
  if SameText(AValue, 'txt') then
    AFormat := rfText
  else if SameText(AValue, 'md') then
    AFormat := rfMarkdown
  else if SameText(AValue, 'json') then
    AFormat := rfJson
  else if SameText(AValue, 'csv') then
    AFormat := rfCsv
  else
    Exit(False);

  Result := True;
end;

function TryMatchOption(
  const AArg: string;
  const ALongName: string;
  const AShortName: string;
  out AInlineValue: string;
  out AConsumesNext: boolean
  ): boolean;
var
  LongPrefix: string;
  ShortPrefix: string;
begin
  if SameText(AArg, ALongName) or SameText(AArg, AShortName) then
  begin
    AInlineValue := '';
    AConsumesNext := True;
    Exit(True);
  end;

  LongPrefix := ALongName + '=';
  if StartsText(LongPrefix, AArg) then
  begin
    AInlineValue := Copy(AArg, Length(LongPrefix) + 1, MaxInt);
    AConsumesNext := False;
    Exit(True);
  end;

  ShortPrefix := AShortName + '=';
  if StartsText(ShortPrefix, AArg) then
  begin
    AInlineValue := Copy(AArg, Length(ShortPrefix) + 1, MaxInt);
    AConsumesNext := False;
    Exit(True);
  end;

  Result := False;
end;

function ResolveOptionValue(
  const AArgs: TArray<string>;
  var AIndex: integer;
  const AArg: string;
  const AInlineValue: string;
  const AConsumesNext: boolean
  ): string;
begin
  if not AConsumesNext then
  begin
    Result := AInlineValue;
    if Result = '' then
      raise ECommandLineError.CreateFmt('Missing value for option %s', [AArg]);
    Exit;
  end;

  if AIndex >= High(AArgs) then
    raise ECommandLineError.CreateFmt('Missing value for option %s', [AArg]);

  Inc(AIndex);
  Result := AArgs[AIndex];
end;

class function TSourceLensCommandLine.DefaultOptions(): TSourceLensOptions;
begin
  Result.WorkingDir := DefaultWorkingDir;
  Result.TestDir := DefaultTestDir;
  Result.ReportFormat := rfText;
  Result.ShowHelp := False;
end;

class function TSourceLensCommandLine.GetHelpText(): string;
begin
  Result := string.Join(sLineBreak, [
    'SourceLens - Delphi code metrics analyzer',
    '',
    'Usage:',
    '  SourceLens [options]',
    '',
    'Options:',
    Format('  --working-dir, -w <path>            Working directory to scan. Default: %s',
      [DefaultWorkingDir]),
    Format('  --test-dir, -t <path>               Test directory setting. Default: %s',
      [DefaultTestDir]),
    '                                       Currently accepted for configuration only.',
    Format('  --format, -f <txt|md|json|csv>      Output format. Default: %s',
      [ReportFormatToString(rfText)]),
    '  --help, -h                          Show this help and exit.'
  ]);
end;

class function TSourceLensCommandLine.Parse(
  const AArgs: TArray<string>
  ): TSourceLensOptions;
var
  Index: integer;
  Arg: string;
  Value: string;
  InlineValue: string;
  ConsumesNext: boolean;
begin
  Result := DefaultOptions();

  Index := 0;
  while Index < Length(AArgs) do
  begin
    Arg := AArgs[Index];

    if SameText(Arg, '--help') or SameText(Arg, '-h') then
      Result.ShowHelp := True
    else if TryMatchOption(Arg, '--working-dir', '-w', InlineValue, ConsumesNext) then
      Result.WorkingDir := ResolveOptionValue(
        AArgs,
        Index,
        Arg,
        InlineValue,
        ConsumesNext
        )
    else if TryMatchOption(Arg, '--test-dir', '-t', InlineValue, ConsumesNext) then
      Result.TestDir := ResolveOptionValue(
        AArgs,
        Index,
        Arg,
        InlineValue,
        ConsumesNext
        )
    else if TryMatchOption(Arg, '--format', '-f', InlineValue, ConsumesNext) then
    begin
      Value := ResolveOptionValue(
        AArgs,
        Index,
        Arg,
        InlineValue,
        ConsumesNext
        );

      if not TryParseReportFormat(Value, Result.ReportFormat) then
        raise ECommandLineError.CreateFmt(
          'Unsupported format "%s". Allowed values: txt, md, json, csv',
          [Value]
          );
    end
    else
      raise ECommandLineError.CreateFmt('Unknown option: %s', [Arg]);

    Inc(Index);
  end;
end;

end.