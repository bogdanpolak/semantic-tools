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

For more details about the analyzer and available metrics, see `docs/SourceLens_Metrics.md`.

