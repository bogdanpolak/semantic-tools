unit SemanticTools.Utils;

interface

function GetUnitName(const AFileName: string): string;

function GetFullyQualifiedName(
  const AUnitName: string;
  const AClassName: string;
  const AMethodName: string
  ): string;

procedure SplitFullMethodName(
  const AFullMethodName: string;
  var AClassName: string;
  var AMethodName: string);

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils;

function GetUnitName(const AFileName: string): string;
begin
  Result := TPath.GetFileNameWithoutExtension(AFileName);
end;

function GetFullyQualifiedName(
  const AUnitName: string;
  const AClassName: string;
  const AMethodName: string
  ): string;
var
  FullMethod: string;
begin
  FullMethod := IfThen(AClassName <> '',
    AClassName + '.' + AMethodName,
    AMethodName);
  Result := Format('%s | %s', [AUnitName, FullMethod]).ToLower;
end;

procedure SplitFullMethodName(
  const AFullMethodName: string;
  var AClassName: string;
  var AMethodName: string);
var
  SeparatorIndex: integer;
begin
  SeparatorIndex := AFullMethodName.LastIndexOf('.');
  if SeparatorIndex >= 0 then
  begin
    AClassName := AFullMethodName.Substring(0, SeparatorIndex);
    AMethodName := AFullMethodName.Substring(SeparatorIndex + 1);
  end
  else
  begin
    AClassName := '';
    AMethodName := AFullMethodName;
  end;
end;

end.
