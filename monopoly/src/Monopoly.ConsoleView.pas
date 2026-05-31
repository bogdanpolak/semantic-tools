unit Monopoly.ConsoleView;

interface

uses
  System.Math,
  System.Generics.Collections,
  Monopoly.Types;

procedure ShowIntro(const Players: TObjectList<TPlayer>);
procedure ShowSummary(const Players: TObjectList<TPlayer>);

implementation

uses
  System.Generics.Defaults,
  System.SysUtils;

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

procedure ShowIntro(const Players: TObjectList<TPlayer>);
begin
  Writeln('Players in the game: ' + JoinPlayerNames(Players));
  Writeln('=================================');
  Writeln('MONOPOLY GAME STARTED');
  Writeln('=================================');
  Writeln;
end;

procedure ShowSummary(const Players: TObjectList<TPlayer>);
var
  Player: TPlayer;
  MaxMoney: integer;
  SortedPlayers: TList<TPlayer>;
  PropertyList: string;
  PropertyId: integer;
  Prefix: string;
begin
  Writeln('=================================');
  Writeln('Game Summary');
  Writeln('=================================');
  Writeln;

  MaxMoney := Low(Integer);
  for Player in Players do
  begin
    if Player.Money > MaxMoney then
    begin
      MaxMoney := Player.Money;
    end;
  end;

  SortedPlayers := TList<TPlayer>.Create;
  try
    for Player in Players do
    begin
      SortedPlayers.Add(Player);
    end;

    SortedPlayers.Sort(
      TComparer<TPlayer>.Construct(
        function(const Left, Right: TPlayer): Integer
        begin
          Result := Right.Money - Left.Money;
        end
      )
    );

    var maxNameLength := 0;
    var maxMoneyLength := 0;
    for Player in Players do
    begin
      maxNameLength := Max(maxNameLength, Length(Player.Name));
      maxMoneyLength := Max(maxMoneyLength, Length(Player.Money.ToString));
    end;
    var colWidth := maxNameLength + maxMoneyLength + 2;

    for Player in SortedPlayers do
    begin
      if Player.Money < 0 then
      begin
        Prefix := '<<<';
      end
      else if Player.Money = MaxMoney then
      begin
        Prefix := '^^^';
      end
      else
      begin
        Prefix := '---';
      end;

      PropertyList := '';
      for PropertyId in Player.PropertyIds do
      begin
        if PropertyList <> '' then
        begin
          PropertyList := PropertyList + ', ';
        end;
        PropertyList := PropertyList + IntToStr(PropertyId);
      end;

      var money := LeftPad(
        Format('$%d',[Player.Money]),
        colWidth - Length(Player.Name)
        );

      Writeln(
        Format(
          '%s  %s: %s | properties (%d): [%s]',
          [Prefix, Player.Name, money, Player.PropertyIds.Count, PropertyList]
        )
      );
    end;
  finally
    SortedPlayers.Free;
  end;
end;

end.
