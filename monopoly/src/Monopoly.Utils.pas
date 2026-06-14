unit Monopoly.Utils;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Monopoly.Types;

function JoinPlayerNames(const Players: TObjectList<TPlayer>): string;
function LeftPad(const S: string; Width: Integer): string;

implementation

function JoinPlayerNames(const Players: TObjectList<TPlayer>): string;
var
  Index: integer;
begin
  Result := '';
  for Index := 0 to Players.Count - 1 do
  begin
    if Index > 0 then
    begin
      Result := Result + ', ';
    end;
    Result := Result + Players[Index].Name;
  end;
end;

function LeftPad(const S: string; Width: Integer): string;
begin
  if Length(S) >= Width then
    Result := S
  else
    Result := StringOfChar(' ', Width - Length(S)) + S;
end;

end.
