unit SourceLens.Utils;

interface

function GetFullyQualifiedName(
  const AUnitName: string;
  const AClassName: string;
  const AMethodName: string
  ): string;

implementation

uses
  System.SysUtils,
  System.StrUtils;

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

end.
