# Formatting Rules

These rules describe the formatting style used in the current Delphi codebase for declaration-heavy units.

## General

- Keep formatting-only changes separate from logic changes whenever possible.
- Preserve existing indentation and line-ending style.
- Prefer small, local reflow over broad file-wide reformatting.
- Do not rename symbols or reorder declarations in a formatting-only change.

## Uses Clauses

- Put `uses` on its own line.
- Put each unit on its own following line, indented by two spaces.
- End each unit line with a comma except the last one.
- Keep short one-item `uses` clauses in the same multi-line form.
- In implementation sections, keep `System.*` units before project units when that matches the surrounding file style.
- Preserve the existing unit order unless there is a clear readability reason to regroup it.

Example:

```pascal
uses
  System.SysUtils,
  Monopoly.Rules.Jail,
  Monopoly.Utils;
```

## Procedure And Function Declarations

- Wnen function/procedure has more than one parameter, break parameters in into multiple lines.
- Place the opening parenthesis on the declaration line.
- Indent wrapped parameter lines by two spaces.
- Put the closing `);` or `): Type;` on its own line when the signature is wrapped.
- Keep `const`, `var`, and default values attached to the parameter they modify.

Example:

```pascal
procedure SetMockDecks(
  Game: TGame;
  const ChanceCards: array of TMonopolyCard;
  const CommunityChestCards: array of TMonopolyCard
  );
```

Single parameter exmaple:

```pascal
function CountActivePlayers(Game: TGame): boolean;
```

## Basic types lowercase

- Type basic types lower case: string, integer, double, float, boolean, etc.

Example:
```pascal
var
  Index: integer;
  Text: string;
  IsReady: boolean;
```

## Parameter Lists

- If multiple identifiers share the same type seprate them and place in separate lines.

Preferred:

```pascal
function SetPlayerMoney(
  Game: TGame;
  const PlayerIndex: integer;
  Money: integer
  ): TOperationResult;
```

Avoid:

```pascal
procedure SetPlayerPosition(
  Game: TGame; 
  PlayerIndex, Position: integer
  );
```

Use separete parameters types:

```pascal
procedure SetPlayerPosition(
  Game: TGame; 
  PlayerIndex: integer 
  Position: integer
  );
```

## Calls And Argument Lists

- Keep the callee and opening parenthesis together.
- Prefer breaking before later arguments, not inside short string literals.
- Keep closing `)` aligned with the wrapped call block.

Example:

```pascal
raise Exception.CreateFmt(
  'Duplicate property id assignment: %d',
  [PropertyId]
);
```

## Consistency

- Format declarations the same way in both interface and implementation sections.
- When reflowing one signature in a small cluster, reflow neighboring signatures only if they follow the same pattern and the result is more consistent.
- Do not introduce formatting patterns that are not already used in the repo unless they clearly improve readability.
