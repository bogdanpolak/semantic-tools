# Delphi Semantic Analysis and Tooling

## Overview

Delphi projects used as a testbed for command-line analysis tools and experiments. Experimenting with AST-driven analysis, metric extraction.

The included Monopoly game implementation is example code for tooling and demonstrations — it is not the primary product.

## Contents

- [cli/src/SourceLens.dpr](cli/src/SourceLens.dpr) — command-line analyzer that extracts method-level metrics from Delphi source (primary tooling example).
- [monopoly/src/MonopolyFmx.dpr](monopoly/src/MonopolyFmx.dpr) — sample FMX application implementing a Monopoly simulation (example/testbed).
- [monopoly/tests/Monopoly.Tests.dpr](monopoly/tests/Monopoly.Tests.dpr) — DUnitX tests for the sample code and helpers.

## Purpose

- Provide a compact Delphi codebase for experimenting with AST-driven analysis, metric extraction, and small CLI tooling.
- Serve as a demonstration/testbed for tooling prototypes and experiments (for example: `SourceLens`).

## SourceLens CLI

Build the CLI from the repository root:

```bat
dcc32 -E".\bin" -NU".\bin" -NS"System;Data;Winapi;System.Win;Data.Win" -U".\cli\src\units;.\cli\delphi-ast" -Q .\cli\src\SourceLens.dpr
```

Run it with optional flags:

```bat
.\bin\SourceLens.exe --working-dir .\monopoly\src --format txt
.\bin\SourceLens.exe -w .\monopoly\src -f md
.\bin\SourceLens.exe --working-dir .\monopoly\src --test-dir .\monopoly\tests --format json
.\bin\SourceLens.exe -w .\monopoly\src -f csv
.\bin\SourceLens.exe --help
```

Available flags:

- `--working-dir`, `-w` — katalog z plikami `.pas` do analizy. Domyślnie: `..\monopoly\src`.
- `--test-dir`, `-t` — katalog testów przyjmowany jako ustawienie CLI. Domyślnie: `..\monopoly\tests`.
- `--format`, `-f` — format wyjściowy: `txt`, `md`, `json`, `csv`. Domyślnie: `txt`.
- `--help`, `-h` — pokazuje pomoc.

For more details about the analyzer and available metrics, see `docs/SourceLens_Metrics.md`.

