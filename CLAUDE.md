## Projects

- Delphi Applications: 
    - `cli/src/SourceLens.dpr` - CLI code analyzer for Delphi - code metrics.
    - `cli/tests/SourceLens.Tests.dpr` - DUnitX test suite for SourceLens.
    - `monopoly/src/MonopolyConsole.dpr` - Monopoly CLI the Monopoly simulation.
    - `monopoly/tests/Monopoly.Tests.dpr` - DUnitX Monopoly Test for Monoploy CLI.

## Monopoly FMX

- A simple FireMonkey application simulating a Monopoly game.
- Used as a testbed for tooling and demonstrations (for example: `SourceLens`).

Compile it from the repo root folder with:

```bat
dcc32 -E".\bin" -NU".\bin" -U".\monopoly\src;.\monopoly\src\rules" -Q .\monopoly\src\MonopolyFmx.dpr
```

This will produce `.\bin\MonopolyFmx.exe` This is an interactive FireMonkey Windows desktop application with limited ability  to control by AI agents. It is used to demonstrate the SourceLens analyzer and other tools.

## Monopoly Test workflow

Run it from the repo root folder

```bat
 dcc32 -E".\bin" -NU".\bin" -U".\monopoly\src;.\monopoly\src\rules;.\monopoly\tests\helpers;.\monopoly\tests;.\monopoly\tests\helpers\;.\monopoly\tests\rules" -Q .\monopoly\tests\Monopoly.Tests.dpr
```

Run:

```bat
.\bin\Monopoly.Tests.exe
```

To validate tests analyze Monopoly.Tests.exe stdout output

## SourceLens workflow

Run it from the repo root folder

```bat
dcc32 -E".\bin" -NU".\bin" -NS"System;Data;Winapi;System.Win;Data.Win" -U".\cli\src\units;.\cli\delphi-ast" -Q .\cli\src\SourceLens.dpr
```

Run the SourceLens analyzer with:

```bat
.\bin\SourceLens.exe
```

To validate the analyzer run inspect SourceLens.exe stdout output

## SourceLens Test workflow

Run it from the repo root folder

```bat
dcc32 -E".\bin" -NU".\bin" -NS"System;Data;Winapi;System.Win;Data.Win" -U".\cli\tests;.\cli\src\units;.\cli\delphi-ast" -Q .\cli\tests\SourceLens.Tests.dpr
```

Run the SourceLens test suite with:

```bat
.\bin\SourceLens.Tests.exe
```

To validate tests analyze SourceLens.Tests.exe stdout output

- SourceLens is an evolving Delphi code metrics tool.
- Current first step: measure method body size.
- Next steps: add unit and class measures, then expand method measures with complexity and number of tests.

## Pascal formatting rules

- When agent generates pascal/delphi code use following rules:
@docs/formatting-rules.md
